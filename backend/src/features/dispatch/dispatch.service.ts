import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import {
  QUEUES,
  ORDER_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { Queue } from 'bullmq';
import { v4 as uuidv4 } from 'uuid';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  OrderDispatchSentEvent,
  OrderDispatchCancelledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { OrderStatus, DriverStatus } from '@prisma/client';
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
  ) {}

  // ─── Core dispatch logic ──────────────────────────────────────────────────

  async attemptDispatch(
    payload: DispatchAttemptPayload,
  ): Promise<DispatchOutcome> {
    const { orderId, orderNumber, attempt, excludeDriverIds = [] } = payload;

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

    const dispatchableStatuses: OrderStatus[] = [
      OrderStatus.LOOKING_FOR_DRIVER,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];

    if (!order || !dispatchableStatuses.includes(order.status)) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: status is ${order?.status ?? 'not found'}`,
      );
      return 'invalid';
    }

    const dispatchContext =
      await this.locationRepository.getOrderLocationContext(orderId);
    if (!dispatchContext) {
      this.logger.error(
        `No dispatch context (location) found for order ${orderNumber}`,
      );
      return 'invalid';
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

    const nearbyDrivers = await this.locationRepository.findNearbyDrivers(
      dispatchContext.lng,
      dispatchContext.lat,
      radiusKm,
      excludeDriverIds,
      allowedVehicleTypes,
      requireActiveShift,
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
        const estimatedEarnings = await this.calculateEstimatedEarnings(
          totalDistanceKm,
          perKmOverride,
          settings,
          order.type === 'STANDARD',
          dispatchContext.requestedVehicleType,
        );

        const pickupLocationName =
          order.vendor?.storeName ?? order.vendor?.storeNameAr ?? 'Vendor';
        const dropoffLocationName = order.customer?.user?.name ?? 'Customer';

        return {
          driverId: candidate.id,
          userId: candidate.userId,
          driverShiftId: candidate.activeShiftId,
          distanceKm: candidate.distanceKm,
          estimatedEarnings,
          pickupLocationName,
          dropoffLocationName,
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
    const activeKey = `otlobegy:order-dispatch-active:${orderId}`;
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
        `otlobegy:dispatch-state:${orderId}`,
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
        { delay: timeoutSecs * 1000, jobId: `dispatch-expire-${dispatchId}` },
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

    // It is truly expired. Clean up Redis.
    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${orderId}`);
    const rejectedKey = `otlobegy:dispatch:${dispatchId}:rejected`;
    // Read the rejected set BEFORE deleting it — every consumer below needs it.
    const rejectedBy: string[] = await this.redis.smembers(rejectedKey);
    await this.redis.del(rejectedKey);

    // Persist terminal state to Postgres for anyone who didn't reject
    const dispatchData = JSON.parse(active);
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
      `otlobegy:dispatch-state:${orderId}`,
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

    if (!order || !dispatchableStatuses.includes(order.status)) return false;

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
    if (order.paymentMethod === 'MOBILE_WALLET') {
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

    await this.prisma.$transaction(async (tx) => {
      // Serialize concurrent acceptances for the SAME driver. Two different
      // orders dispatch different payloads (separate Redis claims), so the
      // per-order SET NX cannot serialize them — lock the driver row instead.
      await tx.$queryRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      // A driver already carrying another live order cannot take this one.
      const activeOrder = await tx.order.findFirst({
        where: {
          driverId,
          status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
        },
        select: { id: true },
      });
      if (activeOrder) {
        throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
      }

      // 1. Create the permanent accepted record
      await tx.orderDispatch.create({
        data: {
          id: dispatchId, // Keep original dispatchId for the accepted one
          orderId,
          driverId,
          driverShiftId: candidate.driverShiftId,
          type: dispatchData.type,
          distanceKm: candidate.distanceKm,
          estimatedEarnings: candidate.estimatedEarnings,
          status: 'ACCEPTED',
          expiresAt: new Date(dispatchData.expiresAt),
        },
      });

      // 2. Assign the order safely to prevent race conditions
      const updated = await tx.order.updateMany({
        where: { id: order.id, status: { in: dispatchableStatuses } },
        data: {
          driverId,
          driverShiftId: candidate.driverShiftId,
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

      // 2b. Mark the driver busy. The guarded UPDATE is the hard backstop: if
      // the driver is already ON_DELIVERY (or suspended), nothing changes and
      // the acceptance fails instead of creating a second active order.
      const flipped = await tx.driver.updateMany({
        where: {
          id: driverId,
          status: { in: DRIVER_ASSIGNABLE_STATUSES },
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
            type: dispatchData.type,
            distanceKm: c.distanceKm,
            estimatedEarnings: c.estimatedEarnings,
            status: 'CANCELLED',
            expiresAt: new Date(dispatchData.expiresAt),
          })),
        });
      }
    });

    // Cleanup Redis
    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${orderId}`);
    await this.redis.del(`otlobegy:dispatch-state:${orderId}`);
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

    const members = order.vendorId
      ? await this.prisma.vendorMember.findMany({
          where: { vendorId: order.vendorId },
          select: { userId: true },
        })
      : [];
    const vendorUserIds = members.map((m) => m.userId);

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        order.status,
        nextStatus,
        order.customerId,
        order.customer?.userId || order.customerId, // Using customer.userId if loaded
        order.vendorId,
        vendorUserIds,
        driverId,
        candidate.userId,
        'system',
        'Driver found and auto-assigned.',
      ),
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
      await this.redis.del(`otlobegy:order-dispatch-active:${orderId}`);
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
          `otlobegy:dispatch-state:${orderId}`,
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
        });
      } else {
        const order = await this.prisma.order.findUnique({
          where: { id: orderId },
        });
        if (order) {
          await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
            orderId,
            orderNumber: order.orderNumber,
            attempt: 1,
            excludeDriverIds: rejectedList,
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
    const dispatchId = await this.redis.get(
      `otlobegy:order-dispatch-active:${orderId}`,
    );
    if (!dispatchId) return;

    const raw = await this.redis.get(`otlobegy:dispatch:${dispatchId}`);
    if (!raw) return;

    const dispatchData = JSON.parse(raw);

    // Cleanup Redis
    await this.redis.del(`otlobegy:dispatch:${dispatchId}`);
    await this.redis.del(`otlobegy:order-dispatch-active:${orderId}`);
    await this.redis.del(`otlobegy:dispatch-state:${orderId}`);
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
    const driverCommissionRate = settings.deliveryCommissionRate ?? 20;
    const driverShare = 1 - driverCommissionRate / 100;

    return Math.round(deliveryFee * driverShare);
  }
}
