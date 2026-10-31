import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue, UnrecoverableError } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { OrdersStateService } from './orders-state.service';
import { StatisticsService } from '../statistics/statistics.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  QUEUES,
  ORDER_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';
import {
  OrderStatus,
  PaymentMethod,
  DeliveryGroupStatus,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

// Orders jobs hit Postgres (status transitions, settlement, coins/wallet
// ledgers). BullMQ concurrency above the shared DB pool just queues waits, so
// align to a worker's pool of 10 instead of issuing 25 parallel transactions.
@Processor(QUEUES.ORDERS, { concurrency: 10 })
export class OrdersProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(OrdersProcessor.name);

  constructor(
    private readonly stateService: OrdersStateService,
    private readonly statisticsService: StatisticsService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    @InjectQueue(QUEUES.ORDERS) private readonly queue: Queue,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling Orders domain cron jobs...');
    await this.queue.add(
      CRON_JOBS.AUTO_CANCEL_PENDING,
      {},
      {
        repeat: { pattern: '* * * * *' },
        jobId: CRON_JOBS.AUTO_CANCEL_PENDING,
      },
    );
    await this.queue.add(
      CRON_JOBS.STUCK_ORDER_MONITOR,
      {},
      {
        repeat: { pattern: '*/2 * * * *' },
        jobId: CRON_JOBS.STUCK_ORDER_MONITOR,
      },
    );
    await this.queue.add(
      CRON_JOBS.UNSETTLED_ORDER_MONITOR,
      {},
      {
        repeat: { pattern: '*/5 * * * *' },
        jobId: CRON_JOBS.UNSETTLED_ORDER_MONITOR,
      },
    );
  }

  async process(job: Job): Promise<any> {
    this.logger.debug(`Processing job [${job.name}] id=${job.id}`);

    switch (job.name) {
      case ORDER_JOBS.SETTLE:
        return this.handleSettle(job);
      case ORDER_JOBS.DELIVERY_WATCHDOG:
        return this.handleDeliveryWatchdog(job);
      case CRON_JOBS.AUTO_CANCEL_PENDING:
        return this.handleAutoCancelPendingOrders();
      case CRON_JOBS.STUCK_ORDER_MONITOR:
        return this.handleStuckOrderMonitor();
      case CRON_JOBS.UNSETTLED_ORDER_MONITOR:
        return this.handleUnsettledOrderMonitor();
      default:
        this.logger.warn(`Unknown job name: ${job.name}`);
        return { ignored: true, reason: 'unknown_job_name' };
    }
  }

  // ─── Settle a delivered order ─────────────────────────────────────────────

  private async handleSettle(
    job: Job<{ orderId: string; orderNumber: string }>,
  ) {
    const { orderId, orderNumber } = job.data;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        type: true,
        status: true,
        vendorId: true,
        driverId: true,
        driverShiftId: true,
        zoneId: true,
        grandTotal: true,
        upfrontAmount: true,
        distanceKm: true,
        deliveryFee: true,
        driverBonusFee: true,
        serviceFee: true,
        subtotal: true,
        tax: true,
        paymentMethod: true,
        customerId: true,
        coinsEarned: true,
        coinsUsed: true,
        discount: true,
        vendor: { select: { commissionRate: true, isContracted: true } },
        vendorBranch: { select: { isContracted: true, commissionRate: true } },
        driver: { select: { tier: true } },
      },
    });

    if (!order) {
      throw new UnrecoverableError(`Order ${orderNumber} not found`);
    }

    if (order.status !== OrderStatus.DELIVERED) {
      this.logger.warn(
        `Settlement skipped for ${orderNumber}: status is ${order.status}`,
      );
      return { skipped: true };
    }

    if (!order.driverId) {
      // Delivery-grouped orders keep the collector in Order.driverId, but if
      // that was never mirrored we still settle from a delivered group so the
      // per-group drivers are paid instead of throwing the whole order away.
      const group = await this.prisma.orderDeliveryGroup.findFirst({
        where: {
          orderId,
          status: 'DELIVERED',
          primaryDriverId: { not: null },
        },
        select: { primaryDriverId: true, primaryDriverShiftId: true },
        orderBy: { sequence: 'asc' },
      });
      if (!group?.primaryDriverId) {
        throw new UnrecoverableError(
          `Order ${orderNumber} has no driver assigned`,
        );
      }
      order.driverId = group.primaryDriverId;
      order.driverShiftId = group.primaryDriverShiftId;
    }

    const settings = await this.platformSettings.getSettings();
    const deliveryCommissionRate = settings.deliveryCommissionRate ?? 20;

    await this.statisticsService.settleOrder({
      orderId,
      orderNumber,
      orderType: order.type,
      vendorId: order.vendorId,
      driverId: order.driverId,
      driverShiftId: order.driverShiftId,
      zoneId: order.zoneId,
      grandTotal: Number(order.grandTotal),
      upfrontAmount: Number(order.upfrontAmount),
      distanceKm: Number(order.distanceKm ?? 0),
      driverTier: order.driver?.tier ?? 'GOLD',
      deliveryFee: Number(order.deliveryFee),
      driverBonusFee: Number(order.driverBonusFee),
      subtotal: Number(order.subtotal),
      serviceFee: Number(order.serviceFee ?? 0),
      tax: Number(order.tax),
      paymentMethod: order.paymentMethod,
      customerId: order.customerId,
      coinsEarned: Number(order.coinsEarned),
      coinsUsed: Number(order.coinsUsed),
      discount: Number(order.discount),
      commissionRate:
        order.vendorBranch?.commissionRate != null
          ? Number(order.vendorBranch.commissionRate)
          : (order.vendor ? Number(order.vendor.commissionRate) : 0),
      deliveryCommissionRate,
      isStacked: (order as any).isStacked ?? false,
      isContracted:
        order.vendorBranch?.isContracted != null
          ? order.vendorBranch.isContracted
          : (order.vendor ? order.vendor.isContracted : false),
    });

    this.logger.log(`Order ${orderNumber} settled`);
    return { settled: true };
  }

  // ─── Detect stuck in-progress orders ─────────────────────────────────────

  private async handleDeliveryWatchdog(
    job: Job<{ orderId: string; orderNumber: string }>,
  ) {
    const { orderId, orderNumber } = job.data;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, status: true, pickedUpAt: true },
    });

    if (
      !order ||
      order.status === OrderStatus.DELIVERED ||
      order.status === OrderStatus.CANCELLED
    ) {
      return { skipped: true };
    }

    if (order.pickedUpAt) {
      const hoursElapsed =
        (Date.now() - order.pickedUpAt.getTime()) / (1000 * 60 * 60);
      if (hoursElapsed > 3) {
        this.logger.error(
          `⚠️  WATCHDOG: Order ${orderNumber} picked up ${hoursElapsed.toFixed(1)}h ago — not delivered`,
        );
        // TODO: emit admin alert event
      }
    }

    return { checked: true };
  }

  // ─── CRON Jobs ────────────────────────────────────────────────────────────

  private async handleAutoCancelPendingOrders(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.autoCancelPendingMins * 60 * 1000,
      );

      // Bound the batch so a sudden backlog of stale PENDING orders cannot
      // fan out an unbounded Promise.allSettled onto the shared DB pool.
      const BATCH_LIMIT = 50;
      const staleOrders = await this.prisma.order.findMany({
        where: {
          status: OrderStatus.PENDING,
          deletedAt: null,
          createdAt: { lt: cutoff },
        },
        select: { id: true, orderNumber: true },
        take: BATCH_LIMIT,
      });

      if (staleOrders.length === 0) return;

      const cancelPromises = staleOrders.map((order) =>
        this.stateService.cancelOrder(
          null, // system actor
          order.id,
          `Auto-cancelled: pending for more than ${settings.autoCancelPendingMins} minutes`,
        ),
      );

      await Promise.allSettled(cancelPromises);

      this.logger.log(`⏰ Auto-cancelled ${staleOrders.length} pending orders`);
    } catch (error) {
      this.logger.error(
        'Failed to auto-cancel pending orders',
        (error as Error).stack,
      );
    }
  }

  // ─── Stuck Order Monitor ──────────────────────────────────────────────────
  private async handleStuckOrderMonitor() {
    this.logger.debug('Running stuck order monitor...');

    // Find orders stuck in LOOKING_FOR_DRIVER or ACCEPTED for more than 5 minutes
    const cutoff = new Date(Date.now() - 5 * 60 * 1000);

    const stuckOrders = await this.prisma.order.findMany({
      where: {
        updatedAt: { lt: cutoff },
        OR: [
          {
            status: {
              in: [OrderStatus.LOOKING_FOR_DRIVER, OrderStatus.ACCEPTED],
            },
          },
          // A delivery-grouped order can already be PREPARING / READY_FOR_PICKUP
          // because one vendor started while another delivery still waits for
          // its own driver. Match those through the driverless group, otherwise
          // that delivery is never retried again.
          {
            status: {
              in: [OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP],
            },
            deliveryGroups: {
              some: {
                primaryDriverId: null,
                status: {
                  in: [
                    DeliveryGroupStatus.PENDING,
                    DeliveryGroupStatus.ACCEPTED,
                    DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                    DeliveryGroupStatus.READY_FOR_PICKUP,
                  ],
                },
              },
            },
          },
        ],
      },
      select: { id: true, orderNumber: true, vendorId: true, type: true },
      take: 100, // Chunked for scalability
    });

    if (stuckOrders.length === 0) return { count: 0 };

    this.logger.warn(
      `Found ${stuckOrders.length} stuck orders. Re-queueing dispatch...`,
    );

    let recovered = 0;
    for (const order of stuckOrders) {
      // A grouped order has per-delivery state; re-queue one DISPATCH per
      // dispatchable group using the GROUP-scoped state key. Falling back to a
      // single order-level job would reset the attempt counter and re-broadcast
      // the wrong (order-total) fee for a delivery-grouped order.
      const groups = await this.prisma.orderDeliveryGroup.findMany({
        where: {
          orderId: order.id,
          status: {
            in: [
              DeliveryGroupStatus.PENDING,
              DeliveryGroupStatus.ACCEPTED,
              DeliveryGroupStatus.LOOKING_FOR_DRIVER,
              DeliveryGroupStatus.READY_FOR_PICKUP,
            ],
          },
          primaryDriverId: null,
        },
        select: { id: true },
      });

      if (groups.length > 0) {
        for (const group of groups) {
          await this.clearStaleDispatchClaim(group.id);
          const state = await this.readDispatchState(group.id);
          await this.dispatchQueue.add(
            ORDER_JOBS.DISPATCH,
            {
              orderId: order.id,
              orderNumber: order.orderNumber,
              attempt: state.attempt,
              excludeDriverIds: state.excludeDriverIds,
              deliveryGroupId: group.id,
            },
            { removeOnComplete: true, removeOnFail: 100 },
          );
          recovered++;
        }
        continue;
      }

      await this.clearStaleDispatchClaim(order.id);
      const state = await this.readDispatchState(order.id);
      await this.dispatchQueue.add(
        ORDER_JOBS.DISPATCH,
        {
          orderId: order.id,
          orderNumber: order.orderNumber,
          attempt: state.attempt,
          excludeDriverIds: state.excludeDriverIds,
        },
        { removeOnComplete: true, removeOnFail: 100 },
      );
      recovered++;
    }

    const settings = await this.platformSettings.getSettings();

    // Find orders stuck in PENDING_PAYMENT for more than configured minutes (Customer didn't pay via Mobile Wallet)
    const paymentCutoff = new Date(
      Date.now() - settings.mobileWalletTimeoutMins * 60 * 1000,
    );
    const stuckPaymentOrders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.PENDING_PAYMENT,
        paymentMethod: PaymentMethod.MOBILE_WALLET,
        updatedAt: { lt: paymentCutoff },
      },
      select: { id: true, orderNumber: true },
      take: 100,
    });

    if (stuckPaymentOrders.length > 0) {
      this.logger.warn(
        `Found ${stuckPaymentOrders.length} stuck PENDING_PAYMENT orders. Auto-cancelling to free drivers...`,
      );
      for (const order of stuckPaymentOrders) {
        try {
          await this.stateService.cancelOrder(
            null, // system actor
            order.id,
            'Auto-cancelled: Customer did not complete mobile wallet payment in time.',
          );
          recovered++;
        } catch (err) {
          this.logger.error(
            `Failed to auto-cancel stuck payment order ${order.orderNumber}`,
            (err as Error).stack,
          );
        }
      }
    }

    return { recovered };
  }

  // Resume from the last persisted dispatch attempt instead of resetting to 1.
  // Resetting defeats driverSearchMaxAttempts and re-broadcasts to drivers who
  // already rejected the delivery. Works for both the order scope and a
  // delivery-group scope.
  private async readDispatchState(
    scopeId: string,
  ): Promise<{ attempt: number; excludeDriverIds: string[] }> {
    try {
      const stateRaw = await this.redis.get(
        `otlobegy:dispatch-state:${scopeId}`,
      );
      if (!stateRaw) return { attempt: 1, excludeDriverIds: [] };
      const state: { attempt?: number; excludeDriverIds?: string[] } =
        JSON.parse(stateRaw);
      return {
        attempt: Number(state.attempt) || 1,
        excludeDriverIds: Array.isArray(state.excludeDriverIds)
          ? state.excludeDriverIds
          : [],
      };
    } catch {
      // Malformed state — fall back to a fresh attempt.
      return { attempt: 1, excludeDriverIds: [] };
    }
  }

  // An order here with a stale in-flight claim may still be running a live
  // round; attemptDispatch's SET NX will answer 'in_flight' and that's fine.
  // Only clear the claim when its payload is gone or already past expiresAt,
  // which the DISPATCH_EXPIRE watchdog could only have reached if it either
  // already ran (then the claim would be gone) or was lost in a crash (the
  // worker died between claiming and scheduling the watchdog). Dropping the
  // stale claim lets the re-queued job grab a fresh slot immediately instead
  // of bouncing on 'in_flight' until the Redis TTL expires.
  private async clearStaleDispatchClaim(orderId: string): Promise<void> {
    try {
      const activeKey = `otlobegy:order-dispatch-active:${orderId}`;
      const activeDispatchId = await this.redis.get(activeKey);
      if (!activeDispatchId) return;

      const raw = await this.redis.get(`otlobegy:dispatch:${activeDispatchId}`);
      let stale = false;
      if (!raw) {
        stale = true;
      } else {
        try {
          const payload: { expiresAt?: string } = JSON.parse(raw);
          stale =
            !payload.expiresAt ||
            Date.now() > new Date(payload.expiresAt).getTime();
        } catch {
          stale = true;
        }
      }

      if (stale) {
        await this.redis.del(activeKey);
        this.logger.warn(`Cleared stale dispatch claim for order ${orderId}`);
      }
    } catch (err) {
      this.logger.warn(
        `Failed to clear stale dispatch claim for order ${orderId}: ${(err as Error).message}`,
      );
    }
  }

  private async handleUnsettledOrderMonitor() {
    this.logger.debug('Running unsettled order monitor...');

    // Find orders stuck in DELIVERED without driver/vendor settlement for more than 5 minutes
    const cutoff = new Date(Date.now() - 5 * 60 * 1000);

    // We query orders that are DELIVERED, and check if they have any driverWalletTransactions.
    // To do this efficiently, we query orders that are DELIVERED and updated before cutoff.
    const deliveredOrders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        updatedAt: { lt: cutoff },
      },
      select: {
        id: true,
        orderNumber: true,
        vendorId: true,
        driverId: true,
        deliveryGroups: {
          select: { primaryDriverId: true },
        },
      },
      take: 100,
    });

    if (deliveredOrders.length === 0) return { count: 0 };

    const hasAssignedDriver = (o: (typeof deliveredOrders)[number]) =>
      Boolean(
        o.driverId || o.deliveryGroups.some((g) => g.primaryDriverId != null),
      );

    // One batched query for the whole batch instead of a findFirst per order
    // (kills the N+1 that used to issue up to 100 round-trips every 5 minutes).
    const deliveredOrderIds = deliveredOrders
      .filter(hasAssignedDriver)
      .map((o) => o.id);

    const settledRows = await this.prisma.driverWalletTransaction.findMany({
      where: {
        orderId: { in: deliveredOrderIds },
        type: 'DELIVERY_FEE',
      },
      select: { orderId: true },
      distinct: ['orderId'],
    });
    const settledOrderIds = new Set(settledRows.map((r) => r.orderId));

    let recovered = 0;
    for (const order of deliveredOrders) {
      if (!hasAssignedDriver(order)) continue; // Requires driver for driver settlement logic

      if (!settledOrderIds.has(order.id)) {
        this.logger.warn(
          `Found unsettled delivered order ${order.orderNumber}. Re-queueing SETTLE...`,
        );
        await this.queue.add(
          ORDER_JOBS.SETTLE,
          { orderId: order.id, orderNumber: order.orderNumber },
          { attempts: 3, backoff: { type: 'exponential', delay: 5_000 } },
        );
        recovered++;
      }
    }

    return { recovered };
  }
}
