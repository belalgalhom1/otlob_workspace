import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DispatchStatus,
  OrderStatus,
  OrderType,
  Role,
  VehicleType,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  DriverGeoSearchService,
  resolveAllowedVehicleTypes,
} from '../location/driver-geo-search.service';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { LocationRepository } from '../location/location.repository';
import { DispatchRepository } from '../dispatch/dispatch.repository';
import { DispatchSearchTracker } from '../dispatch/dispatch-search-tracker.service';
import {
  DriverSearchPhase,
  SearchTerminalReason,
} from '../dispatch/dispatch-search.types';
import { OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderActivePolicyHelper } from './helpers/order-active-policy.helper';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { EVENTS } from '../../common/events/event-names';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import { OrderStatusChangedEvent } from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
} from './helpers/order-actor.helper';
import {
  CustomerErrors,
  OrderErrors,
} from '../../common/constants/response.constants';
import {
  NearbyDriverPreviewDto,
  NearbyDriversResponseDto,
  OrderSearchStatusDto,
  QueryNearbyDriversDto,
  RetrySearchResponseDto,
} from './dto/order-search.dto';

const SEARCH_ACTIVE_STATUSES: readonly OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.ACCEPTED,
  OrderStatus.LOOKING_FOR_DRIVER,
];

const DRIVER_MATCHED_STATUSES: readonly OrderStatus[] = [
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
  OrderStatus.DELIVERED,
];

const ACTIVE_TRIP_TRACKING_STATUSES: readonly OrderStatus[] = [
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
];

const MAX_PREVIEW_DRIVERS = 15;

/**
 * Owns customer-facing live driver search state queries, anonymized nearby
 * driver availability previews, and idempotent search retry workflows for
 * custom delivery & ride orders.
 */
@Injectable()
export class OrderSearchService {
  private readonly logger = new Logger(OrderSearchService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly driverGeoSearch: DriverGeoSearchService,
    private readonly driverTracking: DriverTrackingService,
    private readonly locationRepository: LocationRepository,
    private readonly dispatchRepository: DispatchRepository,
    private readonly ordersRepository: OrdersRepository,
    private readonly ordersService: OrdersService,
    private readonly authHelper: OrderAuthorizationHelper,
    private readonly activePolicy: OrderActivePolicyHelper,
    private readonly outbox: OutboxService,
    private readonly eventEmitter: EventEmitter2,
    @Optional() private readonly searchTracker?: DispatchSearchTracker,
  ) {}

  async getNearbyDriversPreview(
    query: QueryNearbyDriversDto,
  ): Promise<NearbyDriversResponseDto> {
    const settings = await this.platformSettings.getSettings();
    const radiusKm = Number(settings.driverSearchRadiusKm ?? 5);
    const effectiveVehicleType =
      query.type === OrderType.RIDE && !query.vehicleType
        ? VehicleType.CAR
        : query.vehicleType;

    const drivers = await this.fetchAnonymizedNearbyDrivers({
      lng: query.lng,
      lat: query.lat,
      radiusKm,
      requestedVehicleType: effectiveVehicleType ?? null,
      orderDistanceKm: 0,
      requireActiveShift: false,
      settings,
    });

    return {
      radiusKm,
      count: drivers.length,
      drivers,
      fetchedAt: new Date().toISOString(),
    };
  }

  async getOrderSearchStatus(
    actor: JwtAccessPayload,
    orderId: string,
  ): Promise<OrderSearchStatusDto> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        orderNumber: true,
        type: true,
        status: true,
        revision: true,
        distanceKm: true,
        requestedVehicleType: true,
        cancelReason: true,
        cancelledByRole: true,
        cancelledByUserId: true,
        createdAt: true,
        updatedAt: true,
        customer: { select: { id: true, userId: true } },
        deliveryGroups: {
          orderBy: { sequence: 'asc' },
          select: {
            id: true,
            status: true,
            primaryDriverId: true,
            sequence: true,
          },
        },
      },
    });
    if (!order) {
      throw new NotFoundException(OrderErrors.NOT_FOUND);
    }

    const canManage = await this.authHelper.canManageOrders(
      actor.sub,
      actor.role,
    );
    if (!canManage && order.customer?.userId !== actor.sub) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    }

    const [settings, snapshot, locationCtx] = await Promise.all([
      this.platformSettings.getSettings(),
      this.dispatchRepository.getSearchSnapshot(orderId),
      this.locationRepository.getOrderLocationContext(orderId),
    ]);

    const maxAttempts =
      snapshot?.maxAttempts ?? Number(settings.driverSearchMaxAttempts ?? 5);
    const maxRadiusKm =
      snapshot?.maxRadiusKm ?? Number(settings.driverSearchRadiusMaxKm ?? 15);
    const searchTimeoutSecs =
      snapshot?.searchTimeoutSecs ??
      Number(settings.driverAcceptTimeoutSecs ?? 30);

    const activeGroup =
      order.deliveryGroups.find(
        (g) => g.status !== DeliveryGroupStatus.CANCELLED,
      ) ?? order.deliveryGroups[0];
    const scope = activeGroup?.id ?? order.id;
    const assignedDriverId =
      order.deliveryGroups.find((g) => g.primaryDriverId)?.primaryDriverId ??
      null;
    const hasAssignedDriver = assignedDriverId != null;

    let attempt = snapshot?.attempt ?? 1;
    let contactedCount = snapshot?.contactedCount ?? 0;
    let totalContactedCount = snapshot?.totalContactedDriverIds.length ?? 0;
    let rejectedCount = snapshot?.rejectedDriverIds.length ?? 0;
    let waveExpiresAt = snapshot?.waveExpiresAt ?? null;
    let radiusKm =
      snapshot?.radiusKm ??
      Math.min(
        Number(settings.driverSearchRadiusKm ?? 3) +
          Number(settings.driverSearchRadiusStepKm ?? 3) *
            Math.max(0, attempt - 1),
        maxRadiusKm,
      );

    // Reconstruct stats from DB + live Redis broadcast if the search snapshot
    // key expired or the worker has just picked up/restarted dispatch.
    if (!snapshot && SEARCH_ACTIVE_STATUSES.includes(order.status)) {
      const [dispatchState, activeDispatchId, dispatchRows] = await Promise.all([
        this.dispatchRepository.readDispatchState(scope),
        this.dispatchRepository.getActiveClaim(scope),
        this.prisma.orderDispatch.findMany({
          where: { orderId },
          select: { driverId: true, status: true },
        }),
      ]);
      attempt = Math.max(attempt, dispatchState.attempt);
      radiusKm = Math.min(
        Number(settings.driverSearchRadiusKm ?? 3) +
          Number(settings.driverSearchRadiusStepKm ?? 3) *
            Math.max(0, attempt - 1),
        maxRadiusKm,
      );
      const uniqueContacted = new Set(dispatchRows.map((r) => r.driverId));
      const uniqueRejected = new Set(
        dispatchRows
          .filter((r) => r.status === DispatchStatus.REJECTED)
          .map((r) => r.driverId),
      );
      if (activeDispatchId) {
        const broadcast =
          await this.dispatchRepository.getBroadcast(activeDispatchId);
        if (broadcast) {
          contactedCount = broadcast.candidates.length;
          waveExpiresAt = broadcast.expiresAt;
          for (const c of broadcast.candidates) {
            uniqueContacted.add(c.driverId);
          }
        }
      }
      totalContactedCount = uniqueContacted.size;
      rejectedCount = uniqueRejected.size;
    }

    let phase = snapshot?.phase ?? DriverSearchPhase.QUEUED;
    let terminalReason = snapshot?.terminalReason ?? SearchTerminalReason.NONE;
    let nearbyDrivers: NearbyDriverPreviewDto[] = [];
    let driverLocation: { latitude: number; longitude: number } | null = null;
    let driverDistanceKm: number | null = null;
    let driverEtaMinutes: number | null = null;

    if (DRIVER_MATCHED_STATUSES.includes(order.status) || hasAssignedDriver) {
      phase = DriverSearchPhase.DRIVER_FOUND;
      terminalReason = SearchTerminalReason.NONE;
      waveExpiresAt = null;

      if (
        assignedDriverId &&
        ACTIVE_TRIP_TRACKING_STATUSES.includes(order.status)
      ) {
        const liveLoc = await this.driverTracking.getDriverLocationWithState(
          assignedDriverId,
          actor.role === Role.CUSTOMER,
        );
        if (liveLoc) {
          driverLocation = {
            latitude: liveLoc.lat,
            longitude: liveLoc.lng,
          };
          if (locationCtx) {
            const km = await this.locationRepository.getDistanceKm(
              liveLoc.lng,
              liveLoc.lat,
              locationCtx.lng,
              locationCtx.lat,
            );
            driverDistanceKm = Number(km.toFixed(2));
          }
        }
      }
    } else if (order.status === OrderStatus.CANCELLED) {
      waveExpiresAt = null;
      contactedCount = 0;
      const resolvedTerminal = this.resolveCancelledSearchState(
        order,
        snapshot?.phase ?? null,
        snapshot?.terminalReason ?? null,
      );
      phase = resolvedTerminal.phase;
      terminalReason = resolvedTerminal.terminalReason;
    } else {
      terminalReason = SearchTerminalReason.NONE;
      if (!snapshot) {
        phase =
          contactedCount > 0
            ? DriverSearchPhase.CONTACTING_DRIVERS
            : DriverSearchPhase.QUEUED;
      } else if (
        phase === DriverSearchPhase.CONTACTING_DRIVERS &&
        waveExpiresAt &&
        Date.now() < new Date(waveExpiresAt).getTime() &&
        rejectedCount > 0
      ) {
        phase = DriverSearchPhase.WAITING_DRIVER_RESPONSE;
      }

      if (locationCtx) {
        nearbyDrivers = await this.fetchAnonymizedNearbyDrivers({
          lng: locationCtx.lng,
          lat: locationCtx.lat,
          radiusKm,
          requestedVehicleType: order.requestedVehicleType ?? null,
          orderDistanceKm: Number(order.distanceKm ?? 0),
          requireActiveShift:
            Boolean(settings.driverShiftsEnabled) &&
            order.type === OrderType.STANDARD,
          settings,
        });
      }
    }

    const canRetry =
      order.status === OrderStatus.CANCELLED &&
      (order.type === OrderType.CUSTOM_DELIVERY ||
        order.type === OrderType.RIDE) &&
      !hasAssignedDriver;

    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      orderType: order.type,
      orderStatus: order.status,
      revision: order.revision,
      phase,
      attempt,
      maxAttempts,
      radiusKm,
      maxRadiusKm,
      contactedCount,
      totalContactedCount,
      rejectedCount,
      nearbyAvailableCount: nearbyDrivers.length,
      nearbyDrivers,
      waveExpiresAt,
      searchTimeoutSecs,
      searchStartedAt:
        snapshot?.searchStartedAt ??
        order.createdAt?.toISOString() ??
        new Date().toISOString(),
      updatedAt:
        snapshot?.updatedAt ??
        order.updatedAt?.toISOString() ??
        new Date().toISOString(),
      terminalReason,
      canRetry,
      driverLocation,
      driverDistanceKm,
      driverEtaMinutes,
    };
  }

  async retryCustomOrderSearch(
    actor: JwtAccessPayload,
    orderId: string,
  ): Promise<RetrySearchResponseDto> {
    let transitionMeta: {
      retried: boolean;
      alreadySearching: boolean;
      alreadyAssigned: boolean;
      orderNumber: string;
      orderType: OrderType;
      customerUserId: string;
      newRevision: number;
      scopes: string[];
    } | null = null;

    await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM orders WHERE id = ${orderId} FOR UPDATE`;

      const order = await tx.order.findUnique({
        where: { id: orderId },
        select: {
          id: true,
          orderNumber: true,
          type: true,
          status: true,
          revision: true,
          coinsUsed: true,
          customerId: true,
          customer: { select: { userId: true } },
          deliveryGroups: {
            select: {
              id: true,
              status: true,
              primaryDriverId: true,
            },
          },
        },
      });
      if (!order) {
        throw new NotFoundException(OrderErrors.NOT_FOUND);
      }
      if (
        actor.role !== Role.SUPER_ADMIN &&
        order.customer.userId !== actor.sub
      ) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
      }
      if (
        order.type !== OrderType.CUSTOM_DELIVERY &&
        order.type !== OrderType.RIDE
      ) {
        throw new BadRequestException(OrderErrors.CANNOT_RETRY_ORDER);
      }

      if (SEARCH_ACTIVE_STATUSES.includes(order.status)) {
        transitionMeta = {
          retried: false,
          alreadySearching: true,
          alreadyAssigned: false,
          orderNumber: order.orderNumber,
          orderType: order.type,
          customerUserId: order.customer.userId,
          newRevision: order.revision,
          scopes: [order.id, ...order.deliveryGroups.map((g) => g.id)],
        };
        return;
      }

      if (
        DRIVER_MATCHED_STATUSES.includes(order.status) &&
        order.status !== OrderStatus.DELIVERED
      ) {
        transitionMeta = {
          retried: false,
          alreadySearching: false,
          alreadyAssigned: true,
          orderNumber: order.orderNumber,
          orderType: order.type,
          customerUserId: order.customer.userId,
          newRevision: order.revision,
          scopes: [order.id, ...order.deliveryGroups.map((g) => g.id)],
        };
        return;
      }

      const hasAssignedDriver = order.deliveryGroups.some(
        (g) => g.primaryDriverId != null,
      );
      if (order.status !== OrderStatus.CANCELLED || hasAssignedDriver) {
        throw new BadRequestException(OrderErrors.CANNOT_RETRY_ORDER);
      }

      // Lock customer row before checking active order limit and re-deducting
      // any refunded coins so concurrent placeOrder/retry calls serialize cleanly.
      const lockedCustomers = await tx.$queryRaw<
        Array<{ id: string; coinBalance: number }>
      >`SELECT id, "coinBalance" FROM customers WHERE id = ${order.customerId} FOR UPDATE`;
      const lockedCustomer = lockedCustomers[0];
      if (!lockedCustomer) {
        throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
      }

      const policy = await this.activePolicy.validateActiveOrderLimit(
        order.customerId,
      );
      const activeCount = await tx.order.count({
        where: {
          customerId: order.customerId,
          status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
        },
      });
      if (activeCount >= policy.maxActive) {
        throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
      }

      // If previous cancellation refunded coinsUsed into the single unique
      // (orderId, 'REFUNDED') ledger row, re-deduct those coins atomically and
      // remove the REFUNDED row so a future cancellation refunds them properly.
      if (order.coinsUsed > 0) {
        const refundedTx = await tx.customerCoinTransaction.findUnique({
          where: { orderId_type: { orderId, type: 'REFUNDED' } },
          select: { id: true, amount: true },
        });
        const refundedAmt = Number(refundedTx?.amount ?? 0);
        if (refundedTx && refundedAmt > 0) {
          if (Number(lockedCustomer.coinBalance) < refundedAmt) {
            throw new BadRequestException(
              CustomerErrors.INSUFFICIENT_COIN_BALANCE,
            );
          }
          await tx.customer.update({
            where: { id: order.customerId },
            data: { coinBalance: { decrement: refundedAmt } },
          });
          await tx.customerCoinTransaction.delete({
            where: { id: refundedTx.id },
          });
        }
      }

      await tx.orderDeliveryGroup.updateMany({
        where: { orderId, primaryDriverId: null },
        data: { status: DeliveryGroupStatus.LOOKING_FOR_DRIVER },
      });

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.LOOKING_FOR_DRIVER,
          revision: { increment: 1 },
          cancelledByUserId: null,
          cancelledByRole: null,
          cancelledByName: null,
          cancelledByNameAr: null,
          cancelledByAvatar: null,
          cancelReason: null,
          cancelledAt: null,
        },
        select: { revision: true },
      });

      const actorSnapshot = await resolveOrderActorSnapshot(
        this.prisma,
        actor.sub,
        { fallbackRole: actor.role, orderId },
      );

      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        eventKey: `order_retry_search:${orderId}:rev_${updatedOrder.revision}`,
        status: OrderStatus.LOOKING_FOR_DRIVER,
        note: 'Retried driver search',
        createdBy: actor.sub,
        actor: actorSnapshot,
      });

      await this.outbox.record(tx, {
        aggregateType: 'ORDER',
        aggregateId: orderId,
        version: updatedOrder.revision,
        eventType: EVENTS.ORDER_STATUS_CHANGED,
        jobName: EVENT_JOBS.ORDER_STATUS_CHANGED,
        dedupeKey: `notify:order_status:${orderId}:${updatedOrder.revision}`,
        payload: {
          orderId,
          orderNumber: order.orderNumber,
          oldStatus: OrderStatus.CANCELLED,
          newStatus: OrderStatus.LOOKING_FOR_DRIVER,
          status: OrderStatus.LOOKING_FOR_DRIVER,
          note: 'Retried driver search',
          actorUserId: actor.sub,
          revision: updatedOrder.revision,
        },
      });

      transitionMeta = {
        retried: true,
        alreadySearching: false,
        alreadyAssigned: false,
        orderNumber: order.orderNumber,
        orderType: order.type,
        customerUserId: order.customer.userId,
        newRevision: updatedOrder.revision,
        scopes: [order.id, ...order.deliveryGroups.map((g) => g.id)],
      };
    });

    const meta = transitionMeta!;
    if (meta.retried) {
      await this.dispatchRepository.clearForRetry(orderId, meta.scopes);
      await this.searchTracker?.publishPhase({
        orderId,
        orderNumber: meta.orderNumber,
        orderType: meta.orderType,
        orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
        revision: meta.newRevision,
        customerUserId: meta.customerUserId,
        phase: DriverSearchPhase.QUEUED,
        attempt: 1,
        contactedCount: 0,
        waveExpiresAt: null,
        terminalReason: SearchTerminalReason.NONE,
        resetHistory: true,
      });

      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          orderId,
          meta.orderNumber,
          OrderStatus.CANCELLED,
          OrderStatus.LOOKING_FOR_DRIVER,
          meta.customerUserId,
          meta.customerUserId,
          null,
          [],
          null,
          null,
          actor.sub,
          'Retried driver search',
          meta.newRevision,
        ),
      );

      this.logger.log(
        `Custom order ${meta.orderNumber} search retried by user ${actor.sub} (rev ${meta.newRevision})`,
      );
    }

    const [fullOrder, searchStatus] = await Promise.all([
      this.ordersRepository.findById(orderId),
      this.getOrderSearchStatus(actor, orderId),
    ]);
    const projected = await this.ordersService.projectOrderForRole(
      fullOrder,
      actor,
    );

    return {
      order: projected,
      retried: meta.retried,
      alreadySearching: meta.alreadySearching,
      alreadyAssigned: meta.alreadyAssigned,
      searchStatus,
    };
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  private async fetchAnonymizedNearbyDrivers(params: {
    lng: number;
    lat: number;
    radiusKm: number;
    requestedVehicleType: string | null;
    orderDistanceKm: number;
    requireActiveShift: boolean;
    settings: Awaited<ReturnType<PlatformSettingsService['getSettings']>>;
  }): Promise<NearbyDriverPreviewDto[]> {
    const allowedVehicleTypes = resolveAllowedVehicleTypes(
      params.requestedVehicleType,
      params.orderDistanceKm,
      params.settings,
    );
    if (allowedVehicleTypes.length === 0) return [];

    const matches = await this.driverGeoSearch.findNearbyDrivers(
      params.lng,
      params.lat,
      params.radiusKm,
      [],
      allowedVehicleTypes,
      params.requireActiveShift,
      null,
    );
    if (matches.length === 0) return [];

    const capped = matches.slice(0, MAX_PREVIEW_DRIVERS);
    const locationsMap = await this.locationRepository.getLiveDriverLocations(
      capped.map((m) => m.id),
    );

    const previews: NearbyDriverPreviewDto[] = [];
    for (const match of capped) {
      const loc = locationsMap.get(match.id);
      if (!loc || !loc.isFresh) continue;
      previews.push({
        latitude: loc.lat,
        longitude: loc.lng,
        vehicleType: (match.vehicleType as VehicleType) ?? VehicleType.MOTORCYCLE,
        distanceKm: Number(match.distanceKm.toFixed(2)),
      });
    }
    return previews;
  }

  private resolveCancelledSearchState(
    order: {
      cancelReason: string | null;
      cancelledByRole: string | null;
      cancelledByUserId: string | null;
    },
    snapshotPhase: DriverSearchPhase | null,
    snapshotReason: SearchTerminalReason | null,
  ): { phase: DriverSearchPhase; terminalReason: SearchTerminalReason } {
    if (
      snapshotReason &&
      snapshotReason !== SearchTerminalReason.NONE &&
      snapshotPhase &&
      (snapshotPhase === DriverSearchPhase.SEARCH_TIMEOUT ||
        snapshotPhase === DriverSearchPhase.NO_DRIVERS_AVAILABLE ||
        snapshotPhase === DriverSearchPhase.CANCELLED)
    ) {
      return { phase: snapshotPhase, terminalReason: snapshotReason };
    }

    const reasonText = (order.cancelReason ?? '').toLowerCase();
    if (reasonText.includes('no available drivers')) {
      return {
        phase: DriverSearchPhase.NO_DRIVERS_AVAILABLE,
        terminalReason: SearchTerminalReason.NO_DRIVERS_AVAILABLE,
      };
    }
    if (
      reasonText.includes('no drivers accepted') ||
      reasonText.includes('maximum attempts')
    ) {
      return {
        phase: DriverSearchPhase.SEARCH_TIMEOUT,
        terminalReason: SearchTerminalReason.SEARCH_TIMEOUT,
      };
    }
    if (order.cancelledByRole === Role.CUSTOMER) {
      return {
        phase: DriverSearchPhase.CANCELLED,
        terminalReason: SearchTerminalReason.CANCELLED_BY_CUSTOMER,
      };
    }
    if (order.cancelledByUserId || order.cancelledByRole) {
      return {
        phase: DriverSearchPhase.CANCELLED,
        terminalReason: SearchTerminalReason.CANCELLED_BY_ADMIN,
      };
    }
    return {
      phase: DriverSearchPhase.CANCELLED,
      terminalReason: SearchTerminalReason.CANCELLED_BY_SYSTEM,
    };
  }
}
