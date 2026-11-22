import { Injectable, Logger, Optional } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { v4 as uuidv4 } from 'uuid';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderType,
  OrderVendorFulfillmentStatus,
  Prisma,
} from '@prisma/client';
import {
  QUEUES,
  ORDER_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { EVENTS } from '../../common/events/event-names';
import { OrderDispatchSentEvent } from '../../common/events';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from '../location/location.repository';
import {
  DriverGeoSearchService,
  isDriverVehicleEligibleForOrder,
  isVehicleTypeAllowedForOrderType,
  resolveAllowedVehicleTypes,
} from '../location/driver-geo-search.service';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { requiresActiveShiftForOrderType } from '../../common/orders/money.helper';
import { DispatchPort } from '../../common/orders/order-dispatch.ports';
import { computeSearchWaveRadiusKm } from '../orders/helpers/order-pricing.helper';
import {
  DispatchBroadcastPayload,
  DispatchCandidateOffer,
  DispatchRepository,
} from './dispatch.repository';
import { DispatchLifecycleService } from './dispatch-lifecycle.service';
import { DispatchSearchTracker } from './dispatch-search-tracker.service';
import { DriverSearchPhase } from './dispatch-search.types';

export interface DispatchAttemptPayload {
  orderId: string;
  orderNumber: string;
  attempt: number;
  excludeDriverIds?: string[];
  deliveryGroupId?: string | null;
}

export type DispatchOutcome =
  'dispatched' | 'no_drivers' | 'in_flight' | 'invalid';

export const MAX_DISPATCH_BATCH_SIZE = 20;

const DISPATCHABLE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.LOOKING_FOR_DRIVER,
  OrderStatus.ACCEPTED,
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
];

const DISPATCHABLE_GROUP_STATUSES: DeliveryGroupStatus[] = [
  DeliveryGroupStatus.PENDING,
  DeliveryGroupStatus.ACCEPTED,
  DeliveryGroupStatus.LOOKING_FOR_DRIVER,
  DeliveryGroupStatus.PREPARING,
  DeliveryGroupStatus.READY_FOR_PICKUP,
];

/**
 * Coordinates driver candidate matching, offer broadcast, and pending offer
 * lookups while delegating acceptance/rejection/expiry/cancellation lifecycle
 * transitions to `DispatchLifecycleService`.
 */
@Injectable()
export class DispatchService implements DispatchPort {
  private readonly logger = new Logger(DispatchService.name);

  constructor(
    private readonly dispatchRepository: DispatchRepository,
    private readonly lifecycle: DispatchLifecycleService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly locationRepository: LocationRepository,
    private readonly driverGeoSearch: DriverGeoSearchService,
    private readonly earnings: OrderEarningsCalculator,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @Optional() private readonly searchTracker?: DispatchSearchTracker,
  ) {}

  // ─── Core dispatch broadcast ──────────────────────────────────────────────

  async attemptDispatch(
    payload: DispatchAttemptPayload,
  ): Promise<DispatchOutcome> {
    const {
      orderId,
      orderNumber,
      attempt,
      excludeDriverIds = [],
      deliveryGroupId = null,
    } = payload;

    const target = await this.resolveDispatchTarget(
      orderId,
      orderNumber,
      deliveryGroupId,
    );
    if (!target) return 'invalid';

    const {
      order,
      group,
      totalGroupsCount,
      dispatchContext,
      dispatchDeliveryFee,
    } = target;
    const settings = await this.platformSettings.getSettings();

    const radiusKm = computeSearchWaveRadiusKm(
      settings.driverSearchRadiusKm,
      settings.driverSearchRadiusStepKm,
      settings.driverSearchRadiusMaxKm,
      attempt,
    );
    const timeoutSecs = settings.driverAcceptTimeoutSecs;
    const batchSize = Math.min(
      settings.maxDispatchBatchSize || MAX_DISPATCH_BATCH_SIZE,
      MAX_DISPATCH_BATCH_SIZE,
    );

    const orderDistanceKm =
      group.distanceKm != null && Number(group.distanceKm) > 0
        ? Number(group.distanceKm)
        : await this.locationRepository.getDistanceKm(
            dispatchContext.lng,
            dispatchContext.lat,
            dispatchContext.deliveryLng,
            dispatchContext.deliveryLat,
          );

    const allowedVehicleTypes = resolveAllowedVehicleTypes(
      dispatchContext.requestedVehicleType,
      orderDistanceKm,
      settings,
      order.type,
    );
    if (allowedVehicleTypes.length === 0) {
      this.logger.warn(
        `No allowed vehicle types for order ${orderNumber} (type=${order.type}, requestedVehicleType=${dispatchContext.requestedVehicleType ?? 'none'}, distanceKm=${orderDistanceKm}).`,
      );
      if (
        order.type !== OrderType.STANDARD &&
        dispatchContext.requestedVehicleType &&
        !isVehicleTypeAllowedForOrderType(
          order.type,
          dispatchContext.requestedVehicleType,
        )
      ) {
        return 'invalid';
      }
      return 'no_drivers';
    }

    await this.searchTracker?.publishPhase({
      orderId,
      orderNumber,
      orderType: order.type,
      orderStatus: order.status,
      customerUserId: (order as { customer?: { userId?: string } }).customer
        ?.userId,
      phase: DriverSearchPhase.FINDING_DRIVERS,
      attempt,
      maxAttempts: Number(settings.driverSearchMaxAttempts ?? 5),
      radiusKm,
      maxRadiusKm: Number(settings.driverSearchRadiusMaxKm ?? radiusKm),
      contactedCount: 0,
      waveExpiresAt: null,
      searchTimeoutSecs: timeoutSecs,
    });

    const dropoffLocation =
      dispatchContext.deliveryLng != null && dispatchContext.deliveryLat != null
        ? { lng: dispatchContext.deliveryLng, lat: dispatchContext.deliveryLat }
        : null;

    const nearbyDrivers = await this.driverGeoSearch.findNearbyDrivers(
      dispatchContext.lng,
      dispatchContext.lat,
      radiusKm,
      excludeDriverIds,
      allowedVehicleTypes,
      requiresActiveShiftForOrderType(settings.driverShiftsEnabled, order.type),
      dropoffLocation,
      order.type !== OrderType.RIDE,
    );

    const eligibleDrivers = nearbyDrivers.filter((candidate) =>
      isDriverVehicleEligibleForOrder({
        orderType: order.type,
        requestedVehicleType: dispatchContext.requestedVehicleType,
        driverVehicleType: candidate.vehicleType,
        orderDistanceKm,
        settings,
      }),
    );

    if (eligibleDrivers.length === 0) {
      this.logger.warn(
        `No eligible available drivers (${allowedVehicleTypes.join(', ')}) within ${radiusKm}km for order ${orderNumber} (attempt ${attempt})`,
      );
      return 'no_drivers';
    }

    const selectedDrivers = eligibleDrivers.slice(0, batchSize);
    const perKmOverride = dispatchContext.requestedVehicleType
      ? await this.platformSettings.getVehiclePerKm(
          dispatchContext.requestedVehicleType,
        )
      : null;

    const dispatchId = uuidv4();
    const expiresAt = new Date(Date.now() + timeoutSecs * 1000);
    const candidates = await this.buildCandidateOffers({
      selectedDrivers,
      order,
      group,
      totalGroupsCount,
      dispatchContext,
      orderDistanceKm,
      dispatchDeliveryFee,
      perKmOverride,
      settings,
    });

    const outcome = await this.broadcastOffers({
      dispatchId,
      orderId,
      orderNumber,
      orderType: order.type,
      requestedVehicleType: dispatchContext.requestedVehicleType ?? null,
      group,
      candidates,
      attempt,
      excludeDriverIds,
      timeoutSecs,
      expiresAt,
      dispatchDeliveryFee,
    });

    if (outcome === 'dispatched') {
      this.logger.log(
        `Broadcast sent to ${candidates.length} drivers for order ${orderNumber} ` +
          `(radius: ${radiusKm}km, attempt ${attempt})`,
      );
      await this.searchTracker?.publishPhase({
        orderId,
        orderNumber,
        orderType: order.type,
        orderStatus: order.status,
        customerUserId: (order as { customer?: { userId?: string } }).customer
          ?.userId,
        phase: DriverSearchPhase.CONTACTING_DRIVERS,
        attempt,
        maxAttempts: Number(settings.driverSearchMaxAttempts ?? 5),
        radiusKm,
        maxRadiusKm: Number(settings.driverSearchRadiusMaxKm ?? radiusKm),
        contactedCount: candidates.length,
        contactedDriverIds: candidates.map((c) => c.driverId),
        waveExpiresAt: expiresAt.toISOString(),
        searchTimeoutSecs: timeoutSecs,
      });
    }
    return outcome;
  }

  // ─── Lifecycle delegations (preserving public / DISPATCH_PORT surface) ─────

  handleExpiry(payload: {
    dispatchId: string;
    orderId: string;
    orderNumber: string;
    attempt: number;
    excludeDriverIds: string[];
    deliveryGroupId?: string | null;
  }): Promise<void> {
    return this.lifecycle.handleExpiry(payload);
  }

  handleAcceptance(dispatchId: string, driverId: string): Promise<boolean> {
    return this.lifecycle.handleAcceptance(dispatchId, driverId);
  }

  handleRejection(dispatchId: string, driverId: string): Promise<void> {
    return this.lifecycle.handleRejection(dispatchId, driverId);
  }

  cancelActiveDispatch(orderId: string): Promise<void> {
    return this.lifecycle.cancelActiveDispatch(orderId);
  }

  // ─── Pending dispatch queries / verification ──────────────────────────────

  async verifyPendingDispatch(
    dispatchId: string,
    driverId: string,
  ): Promise<string | null> {
    const dispatchData = await this.dispatchRepository.getBroadcast(dispatchId);
    if (!dispatchData) return null;

    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      return null;
    }

    const candidate = dispatchData.candidates.find(
      (c) => c.driverId === driverId,
    );
    if (!candidate) return null;

    if (
      await this.dispatchRepository.isCandidateRejected(dispatchId, driverId)
    ) {
      return null;
    }

    return dispatchData.orderId;
  }

  async getPendingForDriver(driverUserId: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: driverUserId },
      select: { id: true },
    });
    if (!driver) return [];

    const dispatchIds = await this.dispatchRepository.getDriverPendingIds(
      driver.id,
    );

    const results = await Promise.all(
      dispatchIds.map(async (dispatchId) => {
        const dispatchData =
          await this.dispatchRepository.getBroadcast(dispatchId);
        if (
          !dispatchData ||
          Date.now() > new Date(dispatchData.expiresAt).getTime() ||
          (await this.dispatchRepository.isCandidateRejected(
            dispatchId,
            driver.id,
          ))
        ) {
          await this.dispatchRepository.removeDriverPending(
            driver.id,
            dispatchId,
          );
          return null;
        }

        const candidate = (dispatchData.candidates || []).find(
          (c) => c.driverId === driver.id,
        );
        if (!candidate) {
          await this.dispatchRepository.removeDriverPending(
            driver.id,
            dispatchId,
          );
          return null;
        }

        return {
          id: dispatchId,
          dispatchId,
          orderId: dispatchData.orderId,
          deliveryGroupId: dispatchData.deliveryGroupId,
          type: dispatchData.type,
          estimatedEarnings: candidate.estimatedEarnings,
          distanceKm: candidate.distanceKm,
          expiresAt: dispatchData.expiresAt,
          pickupLocationName:
            candidate.pickupLocationName ?? dispatchData.pickupLocationName,
          dropoffLocationName:
            candidate.dropoffLocationName ?? dispatchData.dropoffLocationName,
          pickupLocationLogo:
            candidate.pickupLocationLogo ??
            dispatchData.pickupLocationLogo ??
            null,
          dropoffCustomerAvatar:
            candidate.dropoffCustomerAvatar ??
            dispatchData.dropoffCustomerAvatar ??
            null,
          isStacked: Boolean(candidate.isStacked),
          requestedVehicleType: dispatchData.requestedVehicleType ?? null,
        };
      }),
    );

    return results.filter((r): r is NonNullable<typeof r> => r !== null);
  }

  // ─── Private broadcast helpers ────────────────────────────────────────────

  private async resolveDispatchTarget(
    orderId: string,
    orderNumber: string,
    deliveryGroupId: string | null,
  ) {
    const groupSelect = {
      id: true,
      orderId: true,
      sequence: true,
      status: true,
      deliveryFee: true,
      goldSurchargeAmount: true,
      distanceKm: true,
      primaryDriverId: true,
      items: {
        where: {
          fulfillment: {
            status: {
              notIn: [
                OrderVendorFulfillmentStatus.CANCELLED,
                OrderVendorFulfillmentStatus.REJECTED,
              ],
            },
          },
        },
        orderBy: { sequence: 'asc' },
        select: {
          sequence: true,
          fulfillment: {
            select: {
              id: true,
              vendorBranch: {
                select: { name: true, nameAr: true, address: true },
              },
              vendor: {
                select: { storeName: true, storeNameAr: true, logo: true },
              },
            },
          },
        },
      },
    } satisfies Prisma.OrderDeliveryGroupSelect;

    const [order, totalGroupsCount, group] = await Promise.all([
      this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
          id: true,
          status: true,
          type: true,
          pickupAddress: true,
          deliveryAddress: true,
          deliveryFee: true,
          customer: {
            select: { userId: true, user: { select: { name: true, avatar: true } } },
          },
        },
      }),
      this.prisma.orderDeliveryGroup.count({
        where: {
          orderId,
          status: { not: DeliveryGroupStatus.CANCELLED },
        },
      }),
      deliveryGroupId
        ? this.prisma.orderDeliveryGroup.findUnique({
            where: { id: deliveryGroupId },
            select: groupSelect,
          })
        : this.prisma.orderDeliveryGroup.findFirst({
            where: {
              orderId,
              primaryDriverId: null,
              status: { in: DISPATCHABLE_GROUP_STATUSES },
            },
            orderBy: { sequence: 'asc' },
            select: groupSelect,
          }),
    ]);

    if (!group || group.orderId !== orderId) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: delivery group ${deliveryGroupId ?? 'auto'} not found`,
      );
      return null;
    }

    const orderDispatchable =
      !!order && DISPATCHABLE_ORDER_STATUSES.includes(order.status);
    const isOrderTerminal =
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED;
    const groupDispatchable = DISPATCHABLE_GROUP_STATUSES.includes(
      group.status,
    );
    const alreadyAssigned = Boolean(group.primaryDriverId);

    if (
      isOrderTerminal ||
      alreadyAssigned ||
      !groupDispatchable ||
      !orderDispatchable
    ) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: status ${order?.status ?? 'not found'}` +
          `, group #${group.sequence} status ${group.status}` +
          (alreadyAssigned ? ' (group already has a driver)' : ''),
      );
      return null;
    }

    const dispatchContext =
      await this.locationRepository.getOrderLocationContext(orderId);
    if (!dispatchContext) {
      this.logger.error(
        `No dispatch context (location) found for order ${orderNumber}`,
      );
      return null;
    }

    if (order.type === 'STANDARD') {
      const pickup =
        await this.locationRepository.getDeliveryGroupPickupLocation(group.id);
      if (!pickup) {
        this.logger.error(
          `No pickup branch found for delivery group ${group.id} on order ${orderNumber}`,
        );
        return null;
      }
      dispatchContext.lng = pickup.lng;
      dispatchContext.lat = pickup.lat;
    }

    return {
      order,
      group,
      totalGroupsCount,
      dispatchContext,
      dispatchDeliveryFee: Number(group.deliveryFee ?? order.deliveryFee ?? 0),
    };
  }

  private async buildCandidateOffers(params: {
    selectedDrivers: Array<{
      id: string;
      userId: string;
      activeShiftId: string | null;
      distanceKm: number;
      tier?: string | null;
      isOnDelivery?: boolean;
    }>;
    order: {
      type: string;
      pickupAddress: string | null;
      deliveryAddress?: string | null;
      customer: {
        user: { name: string; avatar?: string | null } | null;
      } | null;
    };
    group: {
      id: string;
      sequence: number;
      goldSurchargeAmount?: number | null;
      items: Array<{
        sequence: number;
        fulfillment: {
          id: string;
          vendorBranch: {
            name: string;
            nameAr: string | null;
            address: string;
          } | null;
          vendor: {
            storeName: string;
            storeNameAr: string | null;
            logo?: string | null;
          };
        };
      }>;
    };
    totalGroupsCount: number;
    dispatchContext: { requestedVehicleType: string | null };
    orderDistanceKm: number;
    dispatchDeliveryFee: number;
    perKmOverride: number | null;
    settings: any;
  }): Promise<DispatchCandidateOffer[]> {
    const {
      selectedDrivers,
      order,
      group,
      totalGroupsCount,
      dispatchContext,
      orderDistanceKm,
      dispatchDeliveryFee,
      perKmOverride,
      settings,
    } = params;

    const pickupNames = Array.from(
      new Set(
        group.items
          .map(({ fulfillment: f }) => {
            const store = f.vendor.storeName || f.vendor.storeNameAr;
            const branch = f.vendorBranch?.name || f.vendorBranch?.nameAr;
            return branch && store ? `${store} (${branch})` : store || branch;
          })
          .filter((v): v is string => Boolean(v)),
      ),
    );
    const fallbackPickup =
      order.type === OrderType.RIDE
        ? order.customer?.user?.name || 'Customer Pickup'
        : `Delivery ${group.sequence}`;
    const resolvedPickupName =
      pickupNames.length > 0
        ? pickupNames.join(' • ')
        : order.pickupAddress || fallbackPickup;
    const resolvedPickupLogo =
      group.items
        .map(({ fulfillment: f }) => f.vendor?.logo)
        .find((l): l is string => Boolean(l && l.trim())) ?? null;
    const resolvedCustomerAvatar = order.customer?.user?.avatar ?? null;

    return Promise.all(
      selectedDrivers.map(async (candidate) => {
        const totalDistanceKm = candidate.distanceKm + orderDistanceKm;
        const isCandidateStacked = Boolean(candidate.isOnDelivery);
        const isCandidateMultiVendor =
          totalGroupsCount > 1 || group.items.length > 1;

        const groupGoldSurcharge = Math.max(
          0,
          Math.round(Number(group.goldSurchargeAmount ?? 0)),
        );

        const estimatedEarnings =
          await this.earnings.calculateEstimatedEarningsFromDistance({
            distanceKm: totalDistanceKm,
            perKmOverride,
            prefetchedSettings: settings,
            isStandardOrder: order.type === 'STANDARD',
            vehicleType: dispatchContext.requestedVehicleType,
            isStacked: isCandidateStacked,
            isMultiVendor: isCandidateMultiVendor,
            driverTier: candidate.tier,
            goldSurcharge: groupGoldSurcharge,
          });

        const advertisedEarnings =
          dispatchDeliveryFee > 0
            ? this.earnings.calculateDriverEarningsForFee(
                dispatchDeliveryFee,
                settings,
                {
                  isStacked: isCandidateStacked,
                  isMultiVendor: isCandidateMultiVendor,
                  driverTier: candidate.tier,
                  distanceKm: orderDistanceKm,
                  isStandardOrder: order.type === 'STANDARD',
                  goldSurcharge: groupGoldSurcharge,
                },
              )
            : estimatedEarnings;

        const resolvedDropoffName =
          order.type === OrderType.RIDE ||
          order.type === OrderType.CUSTOM_DELIVERY
            ? order.deliveryAddress?.trim() ||
              order.customer?.user?.name ||
              'Customer'
            : (order.customer?.user?.name ?? 'Customer');

        return {
          driverId: candidate.id,
          userId: candidate.userId,
          driverShiftId: candidate.activeShiftId,
          deliveryGroupId: group.id,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: advertisedEarnings,
          pickupLocationName: resolvedPickupName,
          dropoffLocationName: resolvedDropoffName,
          pickupLocationLogo: resolvedPickupLogo,
          dropoffCustomerAvatar: resolvedCustomerAvatar,
          isStacked: isCandidateStacked,
        };
      }),
    );
  }

  private async broadcastOffers(params: {
    dispatchId: string;
    orderId: string;
    orderNumber: string;
    orderType: OrderType;
    requestedVehicleType?: string | null;
    group: { id: string };
    candidates: DispatchCandidateOffer[];
    attempt: number;
    excludeDriverIds: string[];
    timeoutSecs: number;
    expiresAt: Date;
    dispatchDeliveryFee: number;
  }): Promise<'dispatched' | 'in_flight'> {
    const {
      dispatchId,
      orderId,
      orderNumber,
      orderType,
      requestedVehicleType = null,
      group,
      candidates,
      attempt,
      excludeDriverIds,
      timeoutSecs,
      expiresAt,
      dispatchDeliveryFee,
    } = params;

    const redisTtl = timeoutSecs + 300;
    const dispatchScope = group.id;

    const dispatchData: DispatchBroadcastPayload = {
      dispatchId,
      orderId,
      deliveryGroupId: group.id,
      type: orderType,
      requestedVehicleType,
      candidates,
      expiresAt: expiresAt.toISOString(),
      pickupLocationName: candidates[0]?.pickupLocationName,
      dropoffLocationName: candidates[0]?.dropoffLocationName,
      pickupLocationLogo: candidates[0]?.pickupLocationLogo ?? null,
      dropoffCustomerAvatar: candidates[0]?.dropoffCustomerAvatar ?? null,
    };

    await this.dispatchRepository.saveBroadcast(
      dispatchId,
      dispatchData,
      redisTtl,
    );

    const claimed = await this.dispatchRepository.acquireActiveClaim(
      dispatchScope,
      dispatchId,
      redisTtl,
    );
    if (!claimed) {
      await this.dispatchRepository.deleteBroadcast(dispatchId);
      this.logger.warn(
        `Dispatch for ${orderNumber} skipped — another dispatch is already active`,
      );
      return 'in_flight';
    }

    try {
      await this.dispatchRepository.saveDispatchState(
        dispatchScope,
        { attempt, excludeDriverIds },
        timeoutSecs * 60,
      );

      await this.dispatchQueue.add(
        ORDER_JOBS.DISPATCH_EXPIRE,
        {
          dispatchId,
          orderId,
          orderNumber,
          attempt,
          excludeDriverIds: [
            ...excludeDriverIds,
            ...candidates.map((c) => c.driverId),
          ],
          deliveryGroupId: group.id,
        },
        {
          delay: timeoutSecs * 1000,
          jobId: `dispatch-expire-${dispatchId}`,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        },
      );

      await Promise.all(
        candidates.map((c) =>
          this.dispatchRepository.addDriverPending(
            c.driverId,
            dispatchId,
            redisTtl,
          ),
        ),
      );
    } catch (err) {
      await this.dispatchRepository.releaseActiveClaim(
        dispatchScope,
        dispatchId,
      );
      await this.dispatchRepository.deleteBroadcast(dispatchId);
      throw err;
    }

    for (const candidate of candidates) {
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_SENT,
        new OrderDispatchSentEvent(
          dispatchId,
          orderId,
          orderNumber,
          candidate.driverId,
          candidate.userId,
          orderType,
          candidate.estimatedEarnings,
          candidate.distanceKm,
          expiresAt,
          candidate.pickupLocationName,
          candidate.dropoffLocationName,
          candidate.isStacked,
          dispatchDeliveryFee,
          candidate.pickupLocationLogo ?? null,
          candidate.dropoffCustomerAvatar ?? null,
          requestedVehicleType ?? null,
        ),
      );
    }

    return 'dispatched';
  }
}
