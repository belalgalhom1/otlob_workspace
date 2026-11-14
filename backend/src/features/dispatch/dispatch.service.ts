import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { v4 as uuidv4 } from 'uuid';
import { DeliveryGroupStatus, OrderStatus, OrderType } from '@prisma/client';
import { QUEUES, ORDER_JOBS } from '../../infrastructure/queue/queues.constants';
import { EVENTS } from '../../common/events/event-names';
import { OrderDispatchSentEvent } from '../../common/events';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from '../location/location.repository';
import { DriverGeoSearchService } from '../location/driver-geo-search.service';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { DispatchPort } from '../../common/orders/order-dispatch.ports';
import {
  DispatchBroadcastPayload,
  DispatchCandidateOffer,
  DispatchRepository,
} from './dispatch.repository';
import { DispatchLifecycleService } from './dispatch-lifecycle.service';

export interface DispatchAttemptPayload {
  orderId: string;
  orderNumber: string;
  attempt: number;
  excludeDriverIds?: string[];
  deliveryGroupId?: string | null;
}

export type DispatchOutcome =
  | 'dispatched'
  | 'no_drivers'
  | 'in_flight'
  | 'invalid';

export const MAX_DISPATCH_BATCH_SIZE = 20;

const DISPATCHABLE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.LOOKING_FOR_DRIVER,
  OrderStatus.ACCEPTED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
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

    const { order, group, dispatchContext, dispatchDeliveryFee } = target;
    const settings = await this.platformSettings.getSettings();

    const radiusKm = Math.min(
      settings.driverSearchRadiusKm +
        settings.driverSearchRadiusStepKm * (attempt - 1),
      settings.driverSearchRadiusMaxKm,
    );
    const timeoutSecs = settings.driverAcceptTimeoutSecs;
    const batchSize = Math.min(
      settings.maxDispatchBatchSize || MAX_DISPATCH_BATCH_SIZE,
      MAX_DISPATCH_BATCH_SIZE,
    );

    const orderDistanceKm = await this.locationRepository.getDistanceKm(
      dispatchContext.lng,
      dispatchContext.lat,
      dispatchContext.deliveryLng,
      dispatchContext.deliveryLat,
    );

    const allowedVehicleTypes = this.resolveAllowedVehicleTypes(
      dispatchContext.requestedVehicleType,
      orderDistanceKm,
      settings,
    );
    if (allowedVehicleTypes.length === 0) {
      this.logger.warn(
        `No allowed vehicle types for order ${orderNumber}. Dispatch aborted.`,
      );
      return 'invalid';
    }

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
      settings.driverShiftsEnabled && order.type === 'STANDARD',
      dropoffLocation,
    );

    if (nearbyDrivers.length === 0) {
      this.logger.warn(
        `No available drivers within ${radiusKm}km for order ${orderNumber} (attempt ${attempt})`,
      );
      return 'no_drivers';
    }

    const selectedDrivers = nearbyDrivers.slice(0, batchSize);
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

    if (await this.dispatchRepository.isCandidateRejected(dispatchId, driverId)) {
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

    const dispatchIds =
      await this.dispatchRepository.getDriverPendingIds(driver.id);

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
          isStacked: Boolean(candidate.isStacked),
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
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        status: true,
        type: true,
        pickupAddress: true,
        deliveryFee: true,
        customer: { select: { user: { select: { name: true } } } },
      },
    });

    const groupSelect = {
      id: true,
      orderId: true,
      sequence: true,
      status: true,
      deliveryFee: true,
      distanceKm: true,
      primaryDriverId: true,
      fulfillments: {
        where: { status: { notIn: ['CANCELLED', 'REJECTED'] as any[] } },
        orderBy: { stopSequence: 'asc' as const },
        select: {
          vendorBranch: {
            select: { name: true, nameAr: true, address: true },
          },
          vendor: {
            select: { storeName: true, storeNameAr: true },
          },
        },
      },
    };

    const group = deliveryGroupId
      ? await this.prisma.orderDeliveryGroup.findUnique({
          where: { id: deliveryGroupId },
          select: groupSelect,
        })
      : await this.prisma.orderDeliveryGroup.findFirst({
          where: {
            orderId,
            primaryDriverId: null,
            status: { in: DISPATCHABLE_GROUP_STATUSES },
          },
          orderBy: { sequence: 'asc' },
          select: groupSelect,
        });

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
    const groupDispatchable = DISPATCHABLE_GROUP_STATUSES.includes(group.status);
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
      const pickup = await this.locationRepository.getDeliveryGroupPickupLocation(
        group.id,
      );
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
      dispatchContext,
      dispatchDeliveryFee: Number(group.deliveryFee ?? order.deliveryFee ?? 0),
    };
  }

  private resolveAllowedVehicleTypes(
    requestedVehicleType: string | null,
    orderDistanceKm: number,
    settings: {
      allowBicycle: boolean;
      allowMotorcycle: boolean;
      allowCar: boolean;
      allowVan: boolean;
      allowTruck: boolean;
      allowMotorTricycle: boolean;
      maxKmForBicycle?: number | null;
    },
  ): string[] {
    if (requestedVehicleType) {
      const v = requestedVehicleType;
      const isAllowed =
        (v === 'BICYCLE' && settings.allowBicycle) ||
        (v === 'MOTORCYCLE' && settings.allowMotorcycle) ||
        (v === 'CAR' && settings.allowCar) ||
        (v === 'VAN' && settings.allowVan) ||
        (v === 'TRUCK' && settings.allowTruck) ||
        (v === 'MOTOR_TRICYCLE' && settings.allowMotorTricycle);
      return isAllowed ? [v] : [];
    }

    const allowed: string[] = [];
    if (settings.allowMotorcycle) allowed.push('MOTORCYCLE');
    if (
      settings.allowBicycle &&
      orderDistanceKm <= (settings.maxKmForBicycle ?? 5.0)
    ) {
      allowed.push('BICYCLE');
    }
    if (settings.allowCar) allowed.push('CAR');
    if (settings.allowVan) allowed.push('VAN');
    if (settings.allowTruck) allowed.push('TRUCK');
    if (settings.allowMotorTricycle) allowed.push('MOTOR_TRICYCLE');
    return allowed;
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
      customer: { user: { name: string } | null } | null;
    };
    group: {
      id: string;
      sequence: number;
      fulfillments: Array<{
        vendorBranch: { name: string; nameAr: string | null; address: string } | null;
        vendor: { storeName: string; storeNameAr: string | null };
      }>;
    };
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
      dispatchContext,
      orderDistanceKm,
      dispatchDeliveryFee,
      perKmOverride,
      settings,
    } = params;

    const totalGroupsCount = await this.prisma.orderDeliveryGroup.count({
      where: {
        orderId: (
          await this.prisma.orderDeliveryGroup.findUnique({
            where: { id: group.id },
            select: { orderId: true },
          })
        )?.orderId,
        status: { not: DeliveryGroupStatus.CANCELLED },
      },
    });

    const pickupNames = Array.from(
      new Set(
        group.fulfillments
          .map((f) => {
            const store = f.vendor.storeName || f.vendor.storeNameAr;
            const branch = f.vendorBranch?.name || f.vendorBranch?.nameAr;
            return branch && store ? `${store} (${branch})` : store || branch;
          })
          .filter((v): v is string => Boolean(v)),
      ),
    );
    const resolvedPickupName =
      pickupNames.length > 0
        ? pickupNames.join(' • ')
        : order.pickupAddress || `Delivery ${group.sequence}`;

    return Promise.all(
      selectedDrivers.map(async (candidate) => {
        const totalDistanceKm = candidate.distanceKm + orderDistanceKm;
        const isCandidateStacked = Boolean(candidate.isOnDelivery);
        const isCandidateMultiVendor = totalGroupsCount > 1 || group.fulfillments.length > 1;

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
                },
              )
            : estimatedEarnings;

        return {
          driverId: candidate.id,
          userId: candidate.userId,
          driverShiftId: candidate.activeShiftId,
          deliveryGroupId: group.id,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: advertisedEarnings,
          pickupLocationName: resolvedPickupName,
          dropoffLocationName: order.customer?.user?.name ?? 'Customer',
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
      candidates,
      expiresAt: expiresAt.toISOString(),
      pickupLocationName: candidates[0]?.pickupLocationName,
      dropoffLocationName: candidates[0]?.dropoffLocationName,
    };

    await this.dispatchRepository.saveBroadcast(dispatchId, dispatchData, redisTtl);

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
      await this.dispatchRepository.releaseActiveClaim(dispatchScope, dispatchId);
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
        ),
      );
    }

    return 'dispatched';
  }
}
