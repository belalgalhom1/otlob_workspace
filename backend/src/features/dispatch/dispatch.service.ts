import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import {
  QUEUES,
  ORDER_JOBS,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { Queue } from 'bullmq';
import { v4 as uuidv4 } from 'uuid';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  OrderDispatchSentEvent,
  OrderDispatchCancelledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { DeliveryGroupStatus, OrderStatus, DriverStatus } from '@prisma/client';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../orders/orders.constants';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { LocationRepository } from '../../infrastructure/location/location.repository';
import { OrderStatusChangedEvent } from 'src/common/events';

import { OrderErrors } from 'src/common/constants/response.constants';

export interface DispatchAttemptPayload {
  orderId: string;
  orderNumber: string;
  attempt: number;
  excludeDriverIds?: string[];
  /**
   * Which delivery this offer is for. Set for multi-vendor orders split into
   * delivery groups; omitted for legacy single-vendor orders and for
   * CUSTOM_DELIVERY/RIDE, where the order itself is the only delivery.
   */
  deliveryGroupId?: string | null;
}

// Dispatch outcome contract. The processor relies on this to decide whether a
// next attempt should be scheduled: only 'no_drivers' warrants a retry, while
// 'in_flight' must never schedule another broadcast for the same order.
export type DispatchOutcome =
  'dispatched' | 'no_drivers' | 'in_flight' | 'invalid';

// Hard cap per broadcast round. The location repository already pre-cuts its
// candidate list to this figure, so a larger value is dead weight — it would
// only advertise unbounded fan-out in the admin surface.
export const MAX_DISPATCH_BATCH_SIZE = 20;

// Driver statuses that still permit accepting a dispatch. Mirrors the
// candidate filter in findNearbyDrivers (ONLINE) plus BUSY (clocked in but
// momentarily engaged, app-set). Deliberately excludes OFFLINE and ON_BREAK,
// so a driver who clocked out or paused mid-window cannot take an order.
const DRIVER_ASSIGNABLE_STATUSES: DriverStatus[] = [
  DriverStatus.ONLINE,
  DriverStatus.BUSY,
];

@Injectable()
export class DispatchService {
  private readonly logger = new Logger(DispatchService.name);

  constructor(
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly locationRepository: LocationRepository,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  // ─── Core dispatch logic ──────────────────────────────────────────────────

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

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        status: true,
        vendorId: true,
        type: true,
        deliveryFee: true,
        customer: { select: { user: { select: { name: true } } } },
        vendor: { select: { storeName: true, storeNameAr: true } },
      },
    });

    // A grouped delivery is dispatched and gated independently of its order:
    // once one group is on the road the others still need their own driver.
    const group = deliveryGroupId
      ? await this.prisma.orderDeliveryGroup.findUnique({
          where: { id: deliveryGroupId },
          select: {
            id: true,
            orderId: true,
            sequence: true,
            status: true,
            deliveryFee: true,
            distanceKm: true,
            primaryDriverId: true,
          },
        })
      : null;

    if (deliveryGroupId && (!group || group.orderId !== orderId)) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: delivery group ${deliveryGroupId} not found`,
      );
      return 'invalid';
    }

    // The fee this delivery actually earns. A group is priced separately, so
    // using the order total here would over-state a split delivery's earnings.
    const dispatchDeliveryFee = group
      ? group.deliveryFee
      : (order?.deliveryFee ?? 0);

    const dispatchableStatuses: OrderStatus[] = [
      OrderStatus.LOOKING_FOR_DRIVER,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];

    // Group-level gates: a group may already be looking for a driver, or may still
    // be waiting on its vendors, so the order's own status is not sufficient.
    const dispatchableGroupStatuses: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.PENDING,
      DeliveryGroupStatus.ACCEPTED,
      DeliveryGroupStatus.LOOKING_FOR_DRIVER,
      DeliveryGroupStatus.READY_FOR_PICKUP,
    ];

    const orderDispatchable =
      !!order && dispatchableStatuses.includes(order.status);
    const isOrderTerminal =
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED;
    const groupDispatchable =
      !group || dispatchableGroupStatuses.includes(group.status);
    const alreadyAssigned = !!group?.primaryDriverId;

    if (isOrderTerminal || alreadyAssigned || !groupDispatchable) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: status ${order?.status ?? 'not found'}` +
          (group ? `, group #${group.sequence} status ${group.status}` : '') +
          (alreadyAssigned ? ' (group already has a driver)' : ''),
      );
      return 'invalid';
    }

    // Legacy single-vendor behaviour is preserved exactly: those orders only
    // dispatch while the ORDER is in a dispatchable state.
    if (!group && !orderDispatchable) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: status is ${order?.status}`,
      );
      return 'invalid';
    }

    // Pickup differs per group: the group's first branch, not the order's
    // single vendor branch. The drop-off is always the order's delivery point.
    const dispatchContext =
      await this.locationRepository.getOrderLocationContext(orderId);
    if (!dispatchContext) {
      this.logger.error(
        `No dispatch context (location) found for order ${orderNumber}`,
      );
      return 'invalid';
    }

    if (group) {
      const pickup =
        await this.locationRepository.getDeliveryGroupPickupLocation(group.id);
      if (!pickup) {
        this.logger.error(
          `No pickup branch found for delivery group ${group.id} on order ${orderNumber}`,
        );
        return 'invalid';
      }
      dispatchContext.lng = pickup.lng;
      dispatchContext.lat = pickup.lat;
    }

    const settings = await this.platformSettings.getSettings();

    // Dynamic Radius Expansion
    let radiusKm =
      settings.driverSearchRadiusKm +
      settings.driverSearchRadiusStepKm * (attempt - 1);
    if (radiusKm > settings.driverSearchRadiusMaxKm) {
      radiusKm = settings.driverSearchRadiusMaxKm;
    }

    const timeoutSecs = settings.driverAcceptTimeoutSecs;
    // Clamp the configured batch size to the hard cap so a stale admin value
    // (schema default was 300) can never inflate a single broadcast round.
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

    let allowedVehicleTypes: string[] = [];
    if (dispatchContext.requestedVehicleType) {
      const v = dispatchContext.requestedVehicleType;
      const isAllowed =
        (v === 'BICYCLE' && settings.allowBicycle) ||
        (v === 'MOTORCYCLE' && settings.allowMotorcycle) ||
        (v === 'CAR' && settings.allowCar) ||
        (v === 'VAN' && settings.allowVan) ||
        (v === 'TRUCK' && settings.allowTruck) ||
        (v === 'MOTOR_TRICYCLE' && settings.allowMotorTricycle);
      if (isAllowed) allowedVehicleTypes = [v];
    } else {
      // STANDARD or CUSTOM_DELIVERY without explicit vehicle choice:
      if (settings.allowMotorcycle) allowedVehicleTypes.push('MOTORCYCLE');
      if (
        settings.allowBicycle &&
        orderDistanceKm <= (settings.maxKmForBicycle ?? 5.0)
      ) {
        allowedVehicleTypes.push('BICYCLE');
      }
      if (settings.allowCar) allowedVehicleTypes.push('CAR');
      if (settings.allowVan) allowedVehicleTypes.push('VAN');
      if (settings.allowTruck) allowedVehicleTypes.push('TRUCK');
      if (settings.allowMotorTricycle)
        allowedVehicleTypes.push('MOTOR_TRICYCLE');
    }

    const requireActiveShift =
      settings.driverShiftsEnabled && order.type === 'STANDARD';

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

    const nearbyDrivers = await this.locationRepository.findNearbyDrivers(
      dispatchContext.lng,
      dispatchContext.lat,
      radiusKm,
      excludeDriverIds,
      allowedVehicleTypes,
      requireActiveShift,
      dropoffLocation,
    );

    if (nearbyDrivers.length === 0) {
      this.logger.warn(
        `No available drivers within ${radiusKm}km for order ${orderNumber} (attempt ${attempt})`,
      );
      return 'no_drivers';
    }

    const selectedDrivers = nearbyDrivers.slice(0, batchSize);

    let perKmOverride: number | null = null;
    if (dispatchContext.requestedVehicleType) {
      perKmOverride = await this.platformSettings.getVehiclePerKm(
        dispatchContext.requestedVehicleType,
      );
    }

    const dispatchId = uuidv4();
    const expiresAt = new Date(Date.now() + timeoutSecs * 1000);

    const candidates = await Promise.all(
      selectedDrivers.map(async (candidate) => {
        const totalDistanceKm = candidate.distanceKm + orderDistanceKm;
        const isCandidateStacked = Boolean(candidate.isOnDelivery);
        const estimatedEarnings = await this.calculateEstimatedEarnings(
          totalDistanceKm,
          perKmOverride,
          settings,
          order.type === 'STANDARD',
          dispatchContext.requestedVehicleType,
          isCandidateStacked,
        );

        // A grouped delivery is priced on its own fee, so the driver sees what
        // that specific delivery earns rather than the whole order's fee.
        const advertisedEarnings = group
          ? this.earningsForGroupFee(dispatchDeliveryFee, settings, isCandidateStacked)
          : estimatedEarnings;

        const pickupLocationName = group
          ? `Delivery ${group.sequence}`
          : (order.vendor?.storeName ?? order.vendor?.storeNameAr ?? 'Vendor');
        const dropoffLocationName = order.customer?.user?.name ?? 'Customer';

        return {
          driverId: candidate.id,
          userId: candidate.userId,
          driverShiftId: candidate.activeShiftId,
          // Carried through the Redis offer so the accepted/expired/rejected
          // rows can all be attributed to the right delivery group.
          deliveryGroupId: group?.id ?? null,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: advertisedEarnings,
          pickupLocationName,
          dropoffLocationName,
          isStacked: isCandidateStacked,
        };
      }),
    );

    const dispatchData = {
      dispatchId,
      orderId,
      type: order.type,
      candidates,
      expiresAt: expiresAt.toISOString(),
      pickupLocationName: candidates[0]?.pickupLocationName,
      dropoffLocationName: candidates[0]?.dropoffLocationName,
    };

    // Store in Redis with extended TTL to outlive BullMQ delay
    const redisTtl = timeoutSecs + 300; // 5 extra minutes

    // Write the dispatch payload BEFORE claiming the active slot. The payload
    // is keyed by a fresh UUID so a concurrent duplicate simply overwrites its
    // own orphan — there is no window where the active key points at a payload
    // that does not exist yet.
    await this.redis.set(
      `otlobegy:dispatch:${dispatchId}`,
      JSON.stringify(dispatchData),
      redisTtl,
    );

    // Atomically claim this order's active dispatch slot. SET NX guarantees
    // only one dispatch round can be in flight for an order at a time, even
    // across concurrent workers/retries. If another round already holds the
    // slot we must not broadcast a duplicate.
    // Scope the single-flight claim to the DELIVERY, not the order. A grouped
    // order needs several drivers in flight at once, one per group; keying this
    // by orderId alone would make every group after the first return 'in_flight'
    // and silently never get a driver.
    const dispatchScope = group?.id ?? orderId;
    const activeKey = `otlobegy:order-dispatch-active:${dispatchScope}`;
    const claimed = await this.redis.setNX(activeKey, dispatchId, redisTtl);
    if (!claimed) {
      // Clean up our own (non-winning) payload — the winner owns this order.
      await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
      this.logger.warn(
        `Dispatch for ${orderNumber} skipped — another dispatch is already active`,
      );
      return 'in_flight';
    }

    try {
      // Persist the attempt progress so corrective flows (stuck-order monitor,
      // crash recovery) can resume from the last attempt instead of resetting
      // the counter to 1 and silently defeating driverSearchMaxAttempts.
      await this.redis.set(
        `otlobegy:dispatch-state:${dispatchScope}`,
        JSON.stringify({ attempt, excludeDriverIds }),
        timeoutSecs * 60,
      );

      // Prepare exclude list for next attempt if this one expires
      const newExcludeDriverIds = [
        ...excludeDriverIds,
        ...candidates.map((c) => c.driverId),
      ];

      // Schedule the expiry watchdog
      await this.dispatchQueue.add(
        ORDER_JOBS.DISPATCH_EXPIRE,
        {
          dispatchId,
          orderId,
          orderNumber,
          attempt,
          excludeDriverIds: newExcludeDriverIds,
        },
        {
          delay: timeoutSecs * 1000,
          jobId: `dispatch-expire-${dispatchId}`,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        },
      );

      // Register the dispatch on every candidate's pending set in parallel.
      // Only after all candidates are registered do we fan out notifications.
      await Promise.all(
        candidates.map(async (candidate) => {
          const pendingKey = `otlobegy:driver-pending-dispatches:${candidate.driverId}`;
          await this.redis.sadd(pendingKey, dispatchId);
          await this.redis.expire(pendingKey, redisTtl);
        }),
      );
    } catch (err) {
      // Release the claim so the order can be retried rather than being stuck
      // behind a half-written dispatch.
      await this.redis.del(activeKey);
      await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
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
          order.type,
          candidate.estimatedEarnings,
          candidate.distanceKm,
          expiresAt,
          candidate.pickupLocationName,
          candidate.dropoffLocationName,
          candidate.isStacked,
        ),
      );
    }

    this.logger.log(
      `Broadcast sent to ${candidates.length} drivers for order ${orderNumber} ` +
        `(radius: ${radiusKm}km, attempt ${attempt})`,
    );

    return 'dispatched';
  }

  // ─── Handle dispatch expiry ───────────────────────────────────────────────

  async handleExpiry(payload: {
    dispatchId: string;
    orderId: string;
    orderNumber: string;
    attempt: number;
    excludeDriverIds: string[];
  }): Promise<void> {
    const { dispatchId, orderId, orderNumber, attempt, excludeDriverIds } =
      payload;

    // Check if the dispatch is still active in Redis
    const active = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!active) {
      // It was already responded to (accepted or rejected)
      return;
    }

    // Parse the payload FIRST: the cleanup keys below are scoped by the
    // delivery this round owns, which only the payload knows.
    const dispatchData = JSON.parse(active);

    // Bail out if the order (or this delivery group) was cancelled while the
    // dispatch was in flight �?" re-enqueueing would resurrect a dead delivery.
    const expiryScope = dispatchData.deliveryGroupId ?? orderId;
    const orderRow = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (orderRow?.status === 'CANCELLED') {
      await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
      await this.redis.del(`otlobegy:order-dispatch-active:${expiryScope}`);
      await this.redis.del(`otlobegy:dispatch-state:${expiryScope}`);
      return;
    }
    if (dispatchData.deliveryGroupId) {
      const groupRow = await this.prisma.orderDeliveryGroup.findUnique({
        where: { id: dispatchData.deliveryGroupId },
        select: { status: true },
      });
      if (groupRow?.status === 'CANCELLED') {
        await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
        await this.redis.del(`otlobegy:order-dispatch-active:${expiryScope}`);
        await this.redis.del(`otlobegy:dispatch-state:${expiryScope}`);
        return;
      }
    }

    // It is truly expired. Clean up Redis.
    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${expiryScope}`);
    await this.redis.del(`otlobegy:dispatch-state:${expiryScope}`);
    const rejectedKey = `otlobegy:dispatch:${dispatchId}:rejected`;
    // Read the rejected set BEFORE deleting it — every consumer below needs it.
    const rejectedBy: string[] = await this.redis.smembers(rejectedKey);
    await this.redis.del(rejectedKey);

    // Persist terminal state to Postgres for anyone who didn't reject
    const candidates = dispatchData.candidates || [];

    await Promise.all(
      candidates.map((candidate: any) =>
        this.redis.srem(
          `otlobegy:driver-pending-dispatches:${candidate.driverId}`,
          dispatchId,
        ),
      ),
    );

    const unresponded = candidates.filter(
      (c: any) => !rejectedBy.includes(c.driverId),
    );

    if (unresponded.length > 0) {
      await this.prisma.orderDispatch.createMany({
        data: unresponded.map((candidate: any) => ({
          id: uuidv4(),
          orderId,
          driverId: candidate.driverId,
          driverShiftId: candidate.driverShiftId,
          deliveryGroupId: candidate.deliveryGroupId ?? null,
          type: dispatchData.type,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: candidate.estimatedEarnings,
          status: 'EXPIRED',
          expiresAt: new Date(dispatchData.expiresAt),
        })),
      });

      // Increment expired dispatches count on driver shifts
      const shiftIds = unresponded
        .map((c: any) => c.driverShiftId)
        .filter((id: any) => id != null);
      if (shiftIds.length > 0) {
        await this.prisma.driverShift.updateMany({
          where: { id: { in: shiftIds } },
          data: { expiredDispatches: { increment: 1 } },
        });
      }

      // Notify unresponded drivers that the dispatch has expired/cancelled
      for (const candidate of unresponded) {
        this.eventEmitter.emit(
          EVENTS.ORDER_DISPATCH_CANCELLED,
          new OrderDispatchCancelledEvent(
            dispatchId,
            orderId,
            candidate.userId,
          ),
        );
      }
    }

    this.logger.log(
      `Dispatch ${dispatchId} expired — retrying for order ${orderId} (attempt ${attempt + 1})`,
    );

    // Refresh persisted attempt state so corrective flows (stuck-order monitor)
    // resume from the true next attempt instead of falling back to 1.
    const settings = await this.platformSettings.getSettings();
    await this.redis.set(
      `otlobegy:dispatch-state:${dispatchData.deliveryGroupId ?? orderId}`,
      JSON.stringify({
        attempt: attempt + 1,
        excludeDriverIds,
      }),
      (settings.driverAcceptTimeoutSecs ?? 30) * 60,
    );

    // Add back to queue for next attempt
    await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
      orderId,
      orderNumber,
      attempt: attempt + 1,
      excludeDriverIds,
      deliveryGroupId: dispatchData.deliveryGroupId ?? null,
    });
  }

  // ─── Handle acceptance ────────────────────────────────────────────────────

  // Returns true only when the driver actually won and was assigned. Every
  // early-exit path signals the dispatch is no longer valid for this driver so
  // the caller can surface ALREADY_ASSIGNED_OR_CANCELLED instead of a false
  // success response.
  async handleAcceptance(
    dispatchId: string,
    driverId: string,
  ): Promise<boolean> {
    const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!raw) {
      this.logger.warn(
        `Driver ${driverId} attempted to accept expired dispatch ${dispatchId}`,
      );
      return false;
    }

    const dispatchData = JSON.parse(raw);

    // Strict timestamp validation since Redis TTL outlives the dispatch window
    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      this.logger.warn(
        `Driver ${driverId} attempted to accept dispatch ${dispatchId} but it is past expiresAt timestamp`,
      );
      return false;
    }

    const orderId = dispatchData.orderId;
    const candidate = (dispatchData.candidates || []).find(
      (c: any) => c.driverId === driverId,
    );

    if (!candidate) {
      this.logger.warn(
        `Driver ${driverId} not found in dispatch ${dispatchId}`,
      );
      return false;
    }

    const rejectedKey = `otlobegy:dispatch:${dispatchId}:rejected`;
    const rejectedBy = await this.redis.smembers(rejectedKey);

    if (rejectedBy.includes(driverId)) {
      this.logger.warn(
        `Driver ${driverId} already rejected dispatch ${dispatchId} but tried to accept.`,
      );
      throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        customer: { select: { userId: true } },
        vendor: { select: { members: { select: { userId: true } } } },
      },
    });

    const dispatchableStatuses: OrderStatus[] = [
      OrderStatus.LOOKING_FOR_DRIVER,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];

    const isGroupedAccept = Boolean(
      candidate.deliveryGroupId ?? dispatchData.deliveryGroupId,
    );
    if (
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED ||
      (!isGroupedAccept && !dispatchableStatuses.includes(order.status))
    ) {
      return false;
    }

    const dispatchContext =
      await this.locationRepository.getOrderLocationContext(order.id);
    if (!dispatchContext) return false;

    const orderDistanceKm = await this.locationRepository.getDistanceKm(
      dispatchContext.lng,
      dispatchContext.lat,
      dispatchContext.deliveryLng,
      dispatchContext.deliveryLat,
    );

    const totalDistanceKm = Number(candidate.distanceKm) + orderDistanceKm;

    let nextStatus: OrderStatus;
    if (
      (order.paymentMethod === 'MOBILE_WALLET' || Number(order.upfrontAmount ?? 0) > 0) &&
      order.paymentStatus !== 'COMPLETED'
    ) {
      nextStatus = OrderStatus.PENDING_PAYMENT;
    } else {
      // Preserve preparation progress if vendor already advanced it
      if (order.status === OrderStatus.READY_FOR_PICKUP) {
        nextStatus = OrderStatus.READY_FOR_PICKUP;
      } else if (order.status === OrderStatus.PREPARING) {
        nextStatus = OrderStatus.PREPARING;
      } else {
        nextStatus = OrderStatus.DRIVER_ASSIGNED;
      }
    }

    const losingCandidates = (dispatchData.candidates || []).filter(
      (c: any) => c.driverId !== driverId && !rejectedBy.includes(c.driverId),
    );

    const acceptScope = dispatchData.deliveryGroupId ?? orderId;
    const activeKey = `otlobegy:order-dispatch-active:${acceptScope}`;

    try {
      await this.prisma.$transaction(async (tx) => {
      // Serialize concurrent acceptances for the SAME driver. Two different
      // orders dispatch different payloads (separate Redis claims), so the
      // per-order SET NX cannot serialize them — lock the driver row instead.
      await tx.$queryRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      const settings = await this.platformSettings.getSettings();
      const maxActive = settings.maxActiveOrdersPerDriver ?? 1;

      // A driver already carrying maxActive live units of work cannot take
      // this one. Work is counted per delivery group (primary or assistant)
      // plus legacy orders that have no groups; counting order rows alone
      // misses a second group on the same order and double-counts the mirrored
      // order-level driver.
      const [activeGroupCount, activeLegacyOrderCount] = await Promise.all([
        tx.orderDeliveryGroup.count({
          where: {
            status: {
              notIn: [DeliveryGroupStatus.CANCELLED, DeliveryGroupStatus.DELIVERED],
            },
            OR: [{ primaryDriverId: driverId }, { assistDriverId: driverId }],
          },
        }),
        tx.order.count({
          where: {
            driverId,
            status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
            deliveryGroups: { none: {} },
          },
        }),
      ]);
      if (activeGroupCount + activeLegacyOrderCount >= maxActive) {
        throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
      }
      const isStackedOrder = (activeGroupCount + activeLegacyOrderCount) > 0;

      // A driver whose shift ended between dispatch and accept must not take
      // the order �?" the shift filter only applies at dispatch time.
      if (candidate.driverShiftId) {
        const shift = await tx.driverShift.findUnique({
          where: { id: candidate.driverShiftId },
          select: { status: true },
        });
        if (!shift || shift.status !== 'ACTIVE') {
          throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
        }
      }

      // 1. Create the permanent accepted record
      await tx.orderDispatch.create({
        data: {
          id: dispatchId, // Keep original dispatchId for the accepted one
          orderId,
          driverId,
          driverShiftId: candidate.driverShiftId,
          deliveryGroupId: candidate.deliveryGroupId ?? null,
          type: dispatchData.type,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: candidate.estimatedEarnings,
          status: 'ACCEPTED',
          expiresAt: new Date(dispatchData.expiresAt),
        },
      });

      // 2. Assign the delivery, then mirror onto the order for back-compat.
      // For a grouped order the GROUP is the authoritative assignment: each
      // group gets its own driver and may be accepted concurrently with the
      // others. The order row is updated lazily: the FIRST accepted group sets
      // the collector (driverId/driverShiftId) and advances the aggregate
      // status, while later groups must NOT be blocked by the order no longer
      // being in a dispatchable status (which is exactly why the old
      // order-status gate stranded every group after the first).
      const groupId = candidate.deliveryGroupId ?? null;

      if (groupId) {
        const groupClaimed = await tx.orderDeliveryGroup.updateMany({
          where: {
            id: groupId,
            primaryDriverId: null,
            status: {
              notIn: [
                DeliveryGroupStatus.CANCELLED,
                DeliveryGroupStatus.DELIVERED,
              ],
            },
          },
          data: {
            primaryDriverId: driverId,
            primaryDriverShiftId: candidate.driverShiftId,
            isStacked: isStackedOrder,
            status:
              nextStatus === OrderStatus.PENDING_PAYMENT
                ? DeliveryGroupStatus.PENDING_PAYMENT
                : DeliveryGroupStatus.DRIVER_ASSIGNED,
            assignedByUserId: 'system',
            assignedAt: new Date(),
          },
        });
        if (groupClaimed.count === 0) {
          // Another admin/dispatch already took this delivery.
          throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
        }

        // Only the first assigned group becomes the order-level collector.
        await tx.order.updateMany({
          where: { id: order.id, driverId: null },
          data: {
            driverId,
            driverShiftId: candidate.driverShiftId,
            isStacked: isStackedOrder,
            driverAssignedAt: new Date(),
          },
        });

        // Move the aggregate status forward only while it is still awaiting a
        // driver; never walk back PREPARING/READY_FOR_PICKUP.
        await tx.order.updateMany({
          where: {
            id: order.id,
            status: {
              in: [
                OrderStatus.PENDING,
                OrderStatus.ACCEPTED,
                OrderStatus.LOOKING_FOR_DRIVER,
              ],
            },
          },
          data: { status: nextStatus },
        });

        await tx.orderStatusEvent.create({
          data: {
            orderId: order.id,
            status: nextStatus,
            note: `Driver assigned to a delivery. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
            createdBy: 'system',
          },
        });
      } else {
        const updated = await tx.order.updateMany({
          where: { id: order.id, status: { in: dispatchableStatuses } },
          data: {
            driverId,
            driverShiftId: candidate.driverShiftId,
            isStacked: isStackedOrder,
            status: nextStatus,
            driverAssignedAt: new Date(),
            distanceKm: totalDistanceKm,
          },
        });

        if (updated.count === 0) {
          throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
        }

        await tx.orderStatusEvent.create({
          data: {
            orderId: order.id,
            status: nextStatus,
            note: `Driver assigned. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
            createdBy: 'system',
          },
        });
      }

      // 2b. Mark the driver busy. When maxActive > 1, ON_DELIVERY drivers can
      // accept additional orders up to the cap.
      const assignableStatuses: DriverStatus[] = [
        DriverStatus.ONLINE,
        DriverStatus.BUSY,
      ];
      if (maxActive > 1) {
        assignableStatuses.push(DriverStatus.ON_DELIVERY);
      }
      const flipped = await tx.driver.updateMany({
        where: {
          id: driverId,
          status: { in: assignableStatuses },
        },
        data: { status: DriverStatus.ON_DELIVERY },
      });
      if (flipped.count === 0) {
        throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
      }

      // 3. Log CANCELLED for the remaining "losing" candidates
      if (losingCandidates.length > 0) {
        await tx.orderDispatch.createMany({
          data: losingCandidates.map((c: any) => ({
            id: uuidv4(),
            orderId,
            driverId: c.driverId,
            driverShiftId: c.driverShiftId,
            deliveryGroupId: c.deliveryGroupId ?? null,
            type: dispatchData.type,
            distanceKm: c.distanceKm,
            estimatedEarnings: c.estimatedEarnings,
            status: 'CANCELLED',
            expiresAt: new Date(dispatchData.expiresAt),
          })),
        });
      }
    });
    } catch (err) {
      // Release the active slot ONLY if we still own it, so a failed accept
      // doesn't block future dispatches for this delivery until TTL expiry.
      try {
        const current = await this.redis.get(activeKey);
        if (current === dispatchId) {
          await this.redis.del(activeKey);
        }
        await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
      } catch {
        // best-effort cleanup
      }
      // Convert a unique-constraint violation (concurrent accept race) into a
      // clean, client-facing error instead of a raw Prisma P2002.
      if (
        err &&
        typeof err === 'object' &&
        (err as { code?: string }).code === 'P2002'
      ) {
        throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
      }
      throw err;
    }

    // Cleanup Redis (success path)
    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${acceptScope}`);
    await this.redis.del(`otlobegy:dispatch-state:${acceptScope}`);

    await this.redis.del(rejectedKey);

    await Promise.all(
      (dispatchData.candidates || []).map((c: any) =>
        this.redis.srem(
          `otlobegy:driver-pending-dispatches:${c.driverId}`,
          dispatchId,
        ),
      ),
    );

    this.logger.log(
      `Driver ${driverId} accepted dispatch ${dispatchId} for order ${order.orderNumber}`,
    );

    // Notify unresponded losing drivers that dispatch has ended
    for (const c of losingCandidates) {
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_CANCELLED,
        new OrderDispatchCancelledEvent(dispatchId, orderId, c.userId),
      );
    }

    // Notify every participating vendor. A multi-vendor order has no
    // order-level vendor, so its vendor set comes from the portions.
    const vendorIds = order.vendorId
      ? [order.vendorId]
      : Array.from(
          new Set(
            (
              await this.prisma.orderVendorFulfillment.findMany({
                where: { orderId: order.id },
                select: { vendorId: true },
              })
            ).map((p) => p.vendorId),
          ),
        );
    const vendorUserIds = vendorIds.length
      ? (
          await this.prisma.vendorMember.findMany({
            where: { vendorId: { in: vendorIds } },
            select: { userId: true },
          })
        ).map((m) => m.userId)
      : [];

    // Durable: enqueue directly to the events queue instead of an in-process
    // emit, so a process crash between commit and fan-out cannot lose the
    // status change (conversation, customer push, dispatch handoff).
    await this.eventsQueue.add(
      EVENT_JOBS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        order.status,
        nextStatus,
        order.customerId,
        order.customer?.userId || order.customerId,
        order.vendorId,
        vendorUserIds,
        driverId,
        candidate.userId,
        'system',
        'Driver found and auto-assigned.',
      ),
      { attempts: 3, backoff: { type: 'exponential', delay: 2_000 } },
    );

    return true;
  }

  // ─── Handle rejection ─────────────────────────────────────────────────────

  async handleRejection(dispatchId: string, driverId: string): Promise<void> {
    const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!raw) return;

    const dispatchData = JSON.parse(raw);

    // Strict timestamp validation since Redis TTL outlives the dispatch window
    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      this.logger.warn(
        `Driver ${driverId} attempted to reject dispatch ${dispatchId} but it is past expiresAt timestamp`,
      );
      return;
    }

    const orderId = dispatchData.orderId;
    const candidate = (dispatchData.candidates || []).find(
      (c: any) => c.driverId === driverId,
    );

    if (!candidate) return;

    // Atomic addition to a Redis Set
    const rejectedKey = `otlobegy:dispatch:${dispatchId}:rejected`;
    const added = await this.redis.sadd(rejectedKey, driverId);
    if (added === 0) return; // Already rejected

    // Remove from driver's pending dispatches set
    await this.redis.srem(
      `otlobegy:driver-pending-dispatches:${driverId}`,
      dispatchId,
    );

    // Set TTL for the rejected set to automatically cleanup
    const ttl = Math.max(
      1,
      Math.floor(
        (new Date(dispatchData.expiresAt).getTime() - Date.now()) / 1000,
      ) + 60,
    );
    await this.redis.expire(rejectedKey, ttl);

    // Persist terminal state to Postgres for this specific rejection
    await this.prisma.orderDispatch.create({
      data: {
        id: uuidv4(),
        orderId,
        driverId,
        driverShiftId: candidate.driverShiftId,
        deliveryGroupId: candidate.deliveryGroupId ?? null,
        type: dispatchData.type,
        distanceKm: candidate.distanceKm,
        estimatedEarnings: candidate.estimatedEarnings,
        status: 'REJECTED',
        expiresAt: new Date(dispatchData.expiresAt),
      },
    });

    if (candidate.driverShiftId) {
      await this.prisma.driverShift.update({
        where: { id: candidate.driverShiftId },
        data: { rejectedDispatches: { increment: 1 } },
      });
    }

    this.logger.log(
      `Driver ${driverId} rejected dispatch ${dispatchId} for order ${orderId}`,
    );

    const totalRejected = await this.redis.scard(rejectedKey);

    // If all candidates rejected it, expire early and retry
    if (totalRejected >= dispatchData.candidates.length) {
      // Read the full rejected list BEFORE deleting the key — the retry below
      // needs it to keep excluding drivers who already said no.
      const rejectedList = await this.redis.smembers(rejectedKey);

      await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
      const rejectScope = dispatchData.deliveryGroupId ?? orderId;
      await this.redis.del(`otlobegy:order-dispatch-active:${rejectScope}`);
      await this.redis.del(rejectedKey);

      await Promise.all(
        (dispatchData.candidates || []).map((c: any) =>
          this.redis.srem(
            `otlobegy:driver-pending-dispatches:${c.driverId}`,
            dispatchId,
          ),
        ),
      );

      const expiryJob = await this.dispatchQueue.getJob(
        `dispatch-expire-${dispatchId}`,
      );

      if (expiryJob) {
        // We delete the pending expiry job because we are handling it immediately
        await expiryJob.remove();

        // Keep the dispatch-state in sync with the re-queued attempt so the
        // stuck-order monitor resumes from the true counter, never attempt 1.
        const branchSettings = await this.platformSettings.getSettings();
        await this.redis.set(
          `otlobegy:dispatch-state:${rejectScope}`,
          JSON.stringify({
            attempt: expiryJob.data.attempt + 1,
            excludeDriverIds: expiryJob.data.excludeDriverIds,
          }),
          (branchSettings.driverAcceptTimeoutSecs ?? 30) * 60,
        );

        await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
          orderId,
          orderNumber: expiryJob.data.orderNumber,
          attempt: expiryJob.data.attempt + 1,
          excludeDriverIds: expiryJob.data.excludeDriverIds,
          deliveryGroupId: dispatchData.deliveryGroupId ?? null,
        });
      } else {
        const order = await this.prisma.order.findUnique({
          where: { id: orderId },
        });
        if (order) {
          // Resume from the persisted attempt counter instead of resetting to 1
          // (which would silently defeat radius expansion).
          const stateRaw = await this.redis.get(
            `otlobegy:dispatch-state:${rejectScope}`,
          );
          const state = stateRaw ? JSON.parse(stateRaw) : null;
          const nextAttempt = (state?.attempt ?? 1) + 1;
          await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
            orderId,
            orderNumber: order.orderNumber,
            attempt: nextAttempt,
            excludeDriverIds: rejectedList,
            deliveryGroupId: dispatchData.deliveryGroupId ?? null,
          });
        }
      }
    }
  }

  // ─── Verify pending dispatch (for API endpoints) ──────────────────────────

  async verifyPendingDispatch(
    dispatchId: string,
    driverId: string,
  ): Promise<string | null> {
    const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!raw) return null;

    const dispatchData = JSON.parse(raw);

    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      return null;
    }

    const candidate = dispatchData.candidates.find(
      (c: any) => c.driverId === driverId,
    );

    if (!candidate) return null;
    const isRejected = await this.redis.sismember(
      `otlobegy:dispatch:${dispatchId}:rejected`,
      driverId,
    );
    if (isRejected) return null;

    return dispatchData.orderId;
  }

  // ─── Get pending dispatches for driver ────────────────────────────────────

  async getPendingForDriver(driverUserId: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: driverUserId },
      select: { id: true },
    });
    if (!driver) return [];

    const dispatchIds: string[] = await this.redis.smembers(
      `otlobegy:driver-pending-dispatches:${driver.id}`,
    );

    // Resolve the payloads concurrently — these are independent Redis reads
    // and a single driver can realistically sit on several pending dispatches.
    const results = await Promise.all(
      dispatchIds.map(async (dispatchId) => {
        const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
        if (!raw) {
          await this.redis.srem(
            `otlobegy:driver-pending-dispatches:${driver.id}`,
            dispatchId,
          );
          return null;
        }

        const dispatchData = JSON.parse(raw);
        if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
          await this.redis.srem(
            `otlobegy:driver-pending-dispatches:${driver.id}`,
            dispatchId,
          );
          return null;
        }

        const rejectedBy = await this.redis.sismember(
          `otlobegy:dispatch:${dispatchId}:rejected`,
          driver.id,
        );
        if (rejectedBy) {
          await this.redis.srem(
            `otlobegy:driver-pending-dispatches:${driver.id}`,
            dispatchId,
          );
          return null;
        }

        const candidate = (dispatchData.candidates || []).find(
          (c: any) => c.driverId === driver.id,
        );
        if (!candidate) {
          await this.redis.srem(
            `otlobegy:driver-pending-dispatches:${driver.id}`,
            dispatchId,
          );
          return null;
        }

        return {
          id: dispatchId,
          dispatchId,
          orderId: dispatchData.orderId,
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

    const pendingDispatches = results.filter(
      (r): r is NonNullable<typeof r> => r !== null,
    );

    if (pendingDispatches.length > 0) {
      return pendingDispatches;
    }

    // Fallback to PostgreSQL if any pending exist
    return this.prisma.orderDispatch.findMany({
      where: {
        driverId: driver.id,
        status: 'PENDING',
        expiresAt: { gt: new Date() },
      },
      include: {
        order: true,
      },
    });
  }

  // ─── Cancel active dispatch (e.g. order cancelled) ────────────────────────

  async cancelActiveDispatch(orderId: string): Promise<void> {
    // A grouped order can have one active round PER DELIVERY, each keyed by its
    // own scope. When the whole order is cancelled, cancel every scope so no
    // orphaned broadcast keeps hunting for a driver. When triggered by an event
    // like DRIVER_ASSIGNED on a multi-delivery order, only cancel scopes that
    // already have a driver assigned (or are cancelled) so sibling delivery
    // groups still searching for a driver are not prematurely killed.
    const [order, groups] = await Promise.all([
      this.prisma.order.findUnique({
        where: { id: orderId },
        select: { status: true, driverId: true },
      }),
      this.prisma.orderDeliveryGroup.findMany({
        where: { orderId },
        select: { id: true, primaryDriverId: true, status: true },
      }),
    ]);

    const isOrderTerminal =
      !order ||
      order.status === 'CANCELLED' ||
      order.status === 'DELIVERED';

    let scopes: string[];
    if (isOrderTerminal || groups.length === 0) {
      scopes = [orderId, ...groups.map((g) => g.id)];
    } else {
      scopes = groups
        .filter(
          (g) =>
            g.primaryDriverId != null ||
            g.status === 'CANCELLED' ||
            g.status === 'DELIVERED',
        )
        .map((g) => g.id);
    }

    if (scopes.length === 0) return;

    const activeDispatchIds = (
      await Promise.all(
        scopes.map((scope) =>
          this.redis.get(`otlobegy:order-dispatch-active:${scope}`),
        ),
      )
    ).filter((id): id is string => !!id);

    for (const id of activeDispatchIds) {
      await this.cancelDispatchById(id, orderId);
    }

    // Always clear the per-scope keys even if a payload had already expired,
    // so a later round is not permanently blocked by a stale claim.
    for (const scope of scopes) {
      await this.redis.del(`otlobegy:order-dispatch-active:${scope}`);
      await this.redis.del(`otlobegy:dispatch-state:${scope}`);
    }
  }

  /** Cancel one dispatch round and persist terminal states for the losers. */
  private async cancelDispatchById(
    dispatchId: string,
    orderId: string,
  ): Promise<void> {
    const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!raw) return;

    const dispatchData = JSON.parse(raw);
    const scope = dispatchData.deliveryGroupId ?? orderId;

    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${scope}`);
    await this.redis.del(`otlobegy:dispatch-state:${scope}`);
    const rejectedKey = `otlobegy:dispatch:${dispatchId}:rejected`;
    // Read BEFORE deleting — the persisted terminal states below need it.
    const rejectedBy: string[] = await this.redis.smembers(rejectedKey);
    await this.redis.del(rejectedKey);

    await Promise.all(
      (dispatchData.candidates || []).map((c: any) =>
        this.redis.srem(
          `otlobegy:driver-pending-dispatches:${c.driverId}`,
          dispatchId,
        ),
      ),
    );

    // Persist terminal state to Postgres
    const candidates = dispatchData.candidates || [];

    const unresponded = candidates.filter(
      (c: any) => !rejectedBy.includes(c.driverId),
    );

    if (unresponded.length > 0) {
      await this.prisma.orderDispatch.createMany({
        data: unresponded.map((candidate: any) => ({
          id: uuidv4(),
          orderId,
          driverId: candidate.driverId,
          driverShiftId: candidate.driverShiftId,
          deliveryGroupId: candidate.deliveryGroupId ?? null,
          type: dispatchData.type,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: candidate.estimatedEarnings,
          status: 'CANCELLED',
          expiresAt: new Date(dispatchData.expiresAt),
        })),
      });

      for (const candidate of unresponded) {
        this.eventEmitter.emit(
          EVENTS.ORDER_DISPATCH_CANCELLED,
          new OrderDispatchCancelledEvent(
            dispatchId,
            orderId,
            candidate.userId,
          ),
        );
      }
    }

    this.logger.log(
      `Active dispatch ${dispatchId} cancelled for order ${orderId}`,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  private async calculateEstimatedEarnings(
    distanceKm: number,
    perKmOverride?: number | null,
    prefetchedSettings?: any,
    isStandardOrder: boolean = true,
    vehicleType?: string | null,
    isStacked: boolean = false,
  ): Promise<number> {
    const deliveryFee = await this.platformSettings.calculateDeliveryFee(
      distanceKm,
      null,
      perKmOverride,
      isStandardOrder,
      prefetchedSettings,
      vehicleType,
    );
    const settings =
      prefetchedSettings ?? (await this.platformSettings.getSettings());
    const driverShare = isStacked
      ? (settings.stackedOrderDriverPercentage ?? 50) / 100
      : 1 - (settings.deliveryCommissionRate ?? 20) / 100;

    return Math.round(deliveryFee * driverShare);
  }
  /**
   * Net driver earnings for one already-priced delivery group.
   * Mirrors calculateEstimatedEarnings but takes the group's stored fee instead
   * of re-deriving from distance, so the figure shown to the driver matches the
   * money settlement will actually pay for that specific delivery.
   */
  private earningsForGroupFee(
    groupDeliveryFee: number,
    settings: { deliveryCommissionRate?: number | null; stackedOrderDriverPercentage?: number | null },
    isStacked: boolean = false,
  ): number {
    const share = isStacked
      ? (settings.stackedOrderDriverPercentage ?? 50) / 100
      : 1 - Number(settings?.deliveryCommissionRate ?? 20) / 100;
    return Math.max(0, Math.round(groupDeliveryFee * share));
  }
}
