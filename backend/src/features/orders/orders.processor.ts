import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue, UnrecoverableError } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { NON_CANCELLABLE } from './transitions/order-state.constants';
import { OrderSettlementService } from './order-settlement.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  QUEUES,
  ORDER_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { OrderStatus, DeliveryGroupStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { DispatchRepository } from '../dispatch/dispatch.repository';

// Orders jobs hit Postgres (status transitions, settlement, coins/wallet
// ledgers). BullMQ concurrency above the shared DB pool just queues waits, so
// align to a worker's pool of 10 instead of issuing 25 parallel transactions.
@Processor(QUEUES.ORDERS, { concurrency: 10 })
export class OrdersProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(OrdersProcessor.name);

  constructor(
    private readonly cancellationService: OrderCancellationService,
    private readonly vendorDecisionService: OrderVendorDecisionService,
    private readonly orderSettlementService: OrderSettlementService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly prisma: PrismaService,
    private readonly dispatchRepository: DispatchRepository,
    @InjectQueue(QUEUES.ORDERS) private readonly queue: Queue,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    private readonly outboxService: OutboxService,
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
    await this.queue.add(
      ORDER_JOBS.OUTBOX_SWEEP,
      {},
      {
        repeat: { every: 3000 },
        jobId: 'orders.outbox_sweep',
      },
    );
  }

  async process(job: Job): Promise<any> {
    if (job.name !== ORDER_JOBS.OUTBOX_SWEEP) {
      this.logger.debug(`Processing job [${job.name}] id=${job.id}`);
    }

    switch (job.name) {
      case ORDER_JOBS.SETTLE:
        return this.handleSettle(job);
      case ORDER_JOBS.DELIVERY_WATCHDOG:
        return this.handleDeliveryWatchdog(job);
      case ORDER_JOBS.CANCEL_ORDER:
        return this.handleCancelOrder(job);
      case ORDER_JOBS.OUTBOX_SWEEP:
        return this.outboxService.relayPending();
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
        customer: { select: { userId: true } },
        coinsEarned: true,
        coinsUsed: true,
        discount: true,
        deliveryGroups: {
          where: {
            status: DeliveryGroupStatus.DELIVERED,
            primaryDriverId: { not: null },
          },
          orderBy: [{ isPaymentCollector: 'desc' }, { sequence: 'asc' }],
          select: {
            id: true,
            primaryDriverId: true,
            primaryDriverShiftId: true,
            isStacked: true,
            isPaymentCollector: true,
            primaryDriver: { select: { tier: true } },
          },
        },
        vendorFulfillments: {
          where: { status: { notIn: ['PENDING', 'REJECTED', 'CANCELLED'] } },
          select: {
            id: true,
            vendorId: true,
            subtotal: true,
            commissionRate: true,
            isContracted: true,
            vendor: { select: { commissionRate: true, isContracted: true } },
            vendorBranch: {
              select: { name: true, isContracted: true, commissionRate: true },
            },
          },
        },
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

    const collectorGroup =
      order.deliveryGroups.find((g) => g.isPaymentCollector) ??
      order.deliveryGroups[0];
    if (!collectorGroup?.primaryDriverId) {
      throw new UnrecoverableError(
        `Order ${orderNumber} has no driver assigned`,
      );
    }

    const distinctVendorIds = new Set(
      order.vendorFulfillments.map((f) => f.vendorId),
    );
    const singleVendorId =
      distinctVendorIds.size === 1
        ? (order.vendorFulfillments[0]?.vendorId ?? null)
        : null;
    const singleFulfillment =
      order.vendorFulfillments.length === 1
        ? order.vendorFulfillments[0]
        : null;

    const settings = await this.platformSettings.getSettings();
    const deliveryCommissionRate = settings.deliveryCommissionRate ?? 20;

    await this.orderSettlementService.settleOrder({
      orderId,
      orderNumber,
      orderType: order.type,
      vendorId: singleVendorId,
      branchName: singleFulfillment?.vendorBranch?.name ?? null,
      driverId: collectorGroup.primaryDriverId,
      driverShiftId: collectorGroup.primaryDriverShiftId ?? null,
      zoneId: order.zoneId,
      grandTotal: Number(order.grandTotal),
      upfrontAmount: Number(order.upfrontAmount),
      distanceKm: Number(order.distanceKm ?? 0),
      driverTier: collectorGroup.primaryDriver?.tier ?? 'SILVER',
      deliveryFee: Number(order.deliveryFee),
      driverBonusFee: Number(order.driverBonusFee),
      subtotal: Number(order.subtotal),
      serviceFee: Number(order.serviceFee ?? 0),
      tax: Number(order.tax),
      paymentMethod: order.paymentMethod,
      customerId: order.customerId,
      customerUserId: order.customer?.userId ?? null,
      coinsEarned: Number(order.coinsEarned),
      coinsUsed: Number(order.coinsUsed),
      discount: Number(order.discount),
      commissionRate: singleFulfillment
        ? Number(
            singleFulfillment.commissionRate ??
              singleFulfillment.vendorBranch?.commissionRate ??
              singleFulfillment.vendor?.commissionRate ??
              0,
          )
        : 0,
      deliveryCommissionRate,
      isStacked: order.deliveryGroups.some((g) => Boolean(g.isStacked)),
      isContracted: singleFulfillment
        ? (singleFulfillment.isContracted ??
          singleFulfillment.vendorBranch?.isContracted ??
          singleFulfillment.vendor?.isContracted ??
          false)
        : false,
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
      select: {
        id: true,
        status: true,
        deliveryGroups: {
          where: { pickedUpAt: { not: null } },
          select: { pickedUpAt: true },
          orderBy: { pickedUpAt: 'asc' },
          take: 1,
        },
      },
    });

    if (
      !order ||
      order.status === OrderStatus.DELIVERED ||
      order.status === OrderStatus.CANCELLED
    ) {
      return { skipped: true };
    }

    const firstPickedUpAt = order.deliveryGroups[0]?.pickedUpAt;
    if (firstPickedUpAt) {
      const hoursElapsed =
        (Date.now() - firstPickedUpAt.getTime()) / (1000 * 60 * 60);
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
      const reason = `Auto-cancelled: pending for more than ${settings.autoCancelPendingMins} minutes`;

      // 1. Multi-vendor orders: time out individual PENDING portions so an
      // unresponsive vendor does not kill sibling vendors who already accepted
      // (if all portions end up rejected, OrderVendorDecisionService.reject cancels
      // the whole order automatically).
      const stalePortions = await this.prisma.orderVendorFulfillment.findMany({
        where: {
          status: 'PENDING',
          createdAt: { lt: cutoff },
          order: {
            deletedAt: null,
            status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
          },
        },
        select: { id: true, orderId: true },
        take: BATCH_LIMIT,
      });

      for (const portion of stalePortions) {
        try {
          await this.vendorDecisionService.reject(null, portion.id, {
            code: 'AUTO_TIMEOUT',
            reason,
          });
        } catch (err) {
          this.logger.warn(
            `Failed to auto-timeout fulfillment ${portion.id}: ${(err as Error).message}`,
          );
        }
      }

      // 2. Single-vendor orders (no fulfillments): cancel the order directly.
      const staleOrders = await this.prisma.order.findMany({
        where: {
          status: OrderStatus.PENDING,
          deletedAt: null,
          createdAt: { lt: cutoff },
          vendorFulfillments: { none: {} },
        },
        select: { id: true, orderNumber: true },
        take: BATCH_LIMIT,
      });

      if (staleOrders.length === 0 && stalePortions.length === 0) return;

      const cancelPromises = staleOrders.map((order) =>
        this.cancellationService.cancelOrder(
          null, // system actor
          order.id,
          reason,
        ),
      );

      if (cancelPromises.length > 0) {
        await Promise.allSettled(cancelPromises);
      }

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
              in: [
                OrderStatus.DRIVER_ASSIGNED,
                OrderStatus.PENDING_PAYMENT,
                OrderStatus.PREPARING,
                OrderStatus.READY_FOR_PICKUP,
                OrderStatus.PARTIALLY_PICKED_UP,
                OrderStatus.PICKED_UP,
              ],
            },
            deliveryGroups: {
              some: {
                primaryDriverId: null,
                status: {
                  in: [
                    DeliveryGroupStatus.PENDING,
                    DeliveryGroupStatus.ACCEPTED,
                    DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                    DeliveryGroupStatus.PREPARING,
                    DeliveryGroupStatus.READY_FOR_PICKUP,
                  ],
                },
              },
            },
          },
        ],
      },
      select: { id: true, orderNumber: true, type: true },
      take: 100, // Chunked for scalability
    });

    let recovered = 0;
    if (stuckOrders.length > 0) {
      this.logger.warn(
        `Found ${stuckOrders.length} stuck orders. Re-queueing dispatch...`,
      );

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
                DeliveryGroupStatus.PREPARING,
                DeliveryGroupStatus.READY_FOR_PICKUP,
              ],
            },
            primaryDriverId: null,
          },
          select: { id: true },
        });

        if (groups.length > 0) {
          for (const group of groups) {
            await this.dispatchRepository.clearStaleDispatchClaim(group.id);
            const state = await this.dispatchRepository.readDispatchState(
              group.id,
            );
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

        await this.dispatchRepository.clearStaleDispatchClaim(order.id);
        const state = await this.dispatchRepository.readDispatchState(order.id);
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
    }

    const settings = await this.platformSettings.getSettings();

    // Find orders stuck in PENDING_PAYMENT for more than configured minutes (Customer didn't pay via Mobile Wallet)
    const paymentCutoff = new Date(
      Date.now() - settings.mobileWalletTimeoutMins * 60 * 1000,
    );
    const stuckPaymentOrders = await this.prisma.order.findMany({
      where: {
        updatedAt: { lt: paymentCutoff },
        paymentStatus: 'PENDING',
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
        OR: [
          { status: OrderStatus.PENDING_PAYMENT },
          {
            deliveryGroups: {
              some: { status: DeliveryGroupStatus.PENDING_PAYMENT },
            },
          },
        ],
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
          await this.cancellationService.cancelOrder(
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

  private async handleUnsettledOrderMonitor() {
    this.logger.debug('Running unsettled order monitor...');

    // Find orders stuck in DELIVERED without driver/vendor settlement for more than 5 minutes
    const cutoff = new Date(Date.now() - 5 * 60 * 1000);

    // We query orders that are DELIVERED, and check if they have any driverWalletTransactions.
    // To do this efficiently, we query orders that are DELIVERED and updated before cutoff.
    const deliveredOrders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        settledAt: null,
        updatedAt: { lt: cutoff },
      },
      select: {
        id: true,
        orderNumber: true,
        deliveryGroups: {
          select: { primaryDriverId: true },
        },
      },
      take: 100,
    });

    if (deliveredOrders.length === 0) return { count: 0 };

    const hasAssignedDriver = (o: (typeof deliveredOrders)[number]) =>
      o.deliveryGroups.some((g) => g.primaryDriverId != null);

    // One batched query for the whole batch instead of a findFirst per order
    // (kills the N+1 that used to issue up to 100 round-trips every 5 minutes).
    const deliveredOrderIds = deliveredOrders
      .filter(hasAssignedDriver)
      .map((o) => o.id);

    const settledRows =
      deliveredOrderIds.length > 0
        ? await this.prisma.driverWalletTransaction.findMany({
            where: {
              orderId: { in: deliveredOrderIds },
              idempotencyKey: { startsWith: 'settle:' },
            },
            select: { orderId: true },
            distinct: ['orderId'],
          })
        : [];
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

  private async handleCancelOrder(
    job: Job<{ orderId: string; reason: string }>,
  ) {
    const { orderId, reason } = job.data;
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (!order || NON_CANCELLABLE.includes(order.status)) {
      return { skipped: true, reason: order?.status ?? 'not_found' };
    }
    await this.cancellationService.cancelOrder(null, orderId, reason);
    return { cancelled: true, orderId };
  }
}
