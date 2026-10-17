import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2, OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { StatisticsRepository } from './statistics.repository';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrderSettledEvent, DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { Prisma, StatisticPeriod, DriverStatus } from '@prisma/client';
import {
  QUEUES,
  STATS_JOBS,
} from '../../infrastructure/queue/queues.constants';
import type { StatPeriodRange } from './statistics.repository';

export interface SettleOrderPayload {
  orderId: string;
  orderNumber: string;
  orderType: string;
  vendorId: string | null;
  driverId: string;
  driverShiftId: string | null;
  grandTotal: number;
  upfrontAmount: number;
  distanceKm: number;
  driverTier: string;
  deliveryFee: number;
  driverBonusFee: number;
  subtotal: number;
  serviceFee: number;
  tax: number;
  commissionRate: number;
  deliveryCommissionRate: number;
  isContracted: boolean;
  paymentMethod: string;
  customerId: string;
  coinsEarned: number;
  coinsUsed: number;
  discount: number;
}

@Injectable()
export class StatisticsService {
  private readonly logger = new Logger(StatisticsService.name);

  constructor(
    private readonly statsRepository: StatisticsRepository,
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly socketService: SocketService,
    private readonly redisService: RedisService,
    @InjectQueue(QUEUES.STATS) private readonly statsQueue: Queue,
  ) {}

  /** Tracks driver online-session start timestamps for onlineHours accrual. */

  // ─── Settle a delivered order ─────────────────────────────────────────────

  async settleOrder(payload: SettleOrderPayload): Promise<void> {
    const {
      orderId,
      orderNumber,
      vendorId,
      driverId,
      driverShiftId,
      orderType,
      grandTotal,
      deliveryFee,
      driverBonusFee,
      subtotal,
      serviceFee,
      tax,
      commissionRate,
      deliveryCommissionRate,
      isContracted,
      paymentMethod,
      customerId,
      coinsEarned,
      coinsUsed,
      discount,
      distanceKm,
      driverTier,
    } = payload;

    // Business rules for revenue split:
    // If the vendor is contracted: commission is paid by the vendor.
    // If NOT contracted: customer pays commission as a service fee, so the vendor receives the full subtotal.
    const commission = Math.round(subtotal * (commissionRate / 100));

    const vendorRevenue = subtotal;

    // Recalculate driver delivery fee based on tier
    // Customer paid based on Gold tier. We subtract the difference if the driver is not Gold.
    const settings = await this.platformSettings.getSettings();
    const goldBonus = Number(settings.goldTierBonusPerKm ?? 0);
    const silverBonus = Number(settings.silverTierBonusPerKm ?? 0);
    const bronzeBonus = Number(settings.bronzeTierBonusPerKm ?? 0);

    let driverActualBonus = goldBonus;
    if (driverTier === 'SILVER') driverActualBonus = silverBonus;
    if (driverTier === 'BRONZE') driverActualBonus = bronzeBonus;

    const tierDifferencePerKm = goldBonus - driverActualBonus;
    const driverDeliveryFee =
      settings.driverShiftsEnabled &&
      orderType === 'STANDARD' &&
      tierDifferencePerKm > 0
        ? Math.max(0, deliveryFee - tierDifferencePerKm * distanceKm)
        : deliveryFee;

    const driverShare = 1 - deliveryCommissionRate / 100;
    const driverEarnings = Math.round(driverDeliveryFee * driverShare);
    const applicationDeliveryCut = deliveryFee - driverEarnings;

    // Sequentially process driver and vendor wallets to prevent DB row deadlocks
    const platformFee = isContracted ? commission : (serviceFee ?? commission);
    let platformRevenue = platformFee + applicationDeliveryCut;

    // If the platform pays the driver bonus fee (not paid by customer), deduct from net platform revenue
    if (!settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      platformRevenue -= driverBonusFee;
    }

    const isDriverCollected =
      paymentMethod === 'CASH_ON_DELIVERY' || paymentMethod === 'MOBILE_WALLET';

    // Emission effects collected inside the transaction and replayed after
    // commit (socket/events must not run inside the DB transaction).
    const statusEffects: {
      kind: 'LOCKED' | 'SETTLEMENT';
      driver: { id: string; userId: string; status: DriverStatus };
      prevStatus: DriverStatus;
    }[] = [];

    // The entire settlement is atomic and idempotent:
    //  - We take a row lock on the ORDER so concurrent SETTLE jobs for the same
    //    order (retry + unsettled-order monitor) serialize instead of double-running.
    //  - If a DELIVERY_FEE wallet transaction already exists for this order, the
    //    order was already settled — we skip all side effects (wallet credits,
    //    counters, stats) so nothing can be applied twice.
    //  - Stats are written asynchronously via the stats queue AFTER commit, so
    //    the settlement transaction stays short (money only) and the stat
    //    workers scale independently.
    const now = new Date();
    const periods = this.statsRepository.getPeriodsForDate(now);
    let applied = false;

    await this.prisma.$transaction(async (client) => {
      await client.$executeRaw`SELECT id FROM orders WHERE id = ${orderId} FOR UPDATE`;

      const alreadySettled = await client.driverWalletTransaction.findFirst({
        where: { orderId, type: 'DELIVERY_FEE' },
      });
      if (alreadySettled) {
        this.logger.warn(
          `Order ${orderNumber} already settled — skipping duplicate settlement.`,
        );
        return;
      }
      applied = true;

      // Serialize concurrent settlements exactly once per affected row. The
      // order guard above already serializes duplicate jobs for THIS order;
      // locking the driver and vendor guards here (fixed order: order → driver
      // → vendor) prevents two settlements of different orders for the same
      // driver/vendor from corrupting each other's balance. Wallet helpers are
      // then told to skip re-locking (they would otherwise re-acquire it up to
      // 4× per settlement).
      await client.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      if (vendorId && isContracted) {
        // Vendor revenue + commission are applied below; lock the vendor once
        // here (after the driver guard, matching acquisition order everywhere)
        // so the two wallet writes don't each re-acquire the same row lock.
        await client.$executeRaw`SELECT id FROM vendors WHERE id = ${vendorId} FOR UPDATE`;
      }

      if (isDriverCollected) {
        // For contracted vendors, the driver collects grandTotal (food + delivery + fees).
        // For uncontracted vendors, the driver paid food subtotal cash at pickup out of pocket,
        // so net cash collected on behalf of the platform is grandTotal - subtotal.
        const collectedAmount = isContracted
          ? grandTotal
          : Math.max(0, grandTotal - subtotal);

        await this.creditDriverWallet(
          client,
          driverId,
          -collectedAmount,
          orderId,
          driverShiftId,
          `Collected payment (COD/Mobile Wallet) for order ${orderNumber}`,
          'CASH_COLLECTED',
          { skipLock: true },
        );
      }

      await this.creditDriverWallet(
        client,
        driverId,
        driverEarnings,
        orderId,
        driverShiftId,
        `Delivery fee for order ${orderNumber}`,
        'DELIVERY_FEE',
        { skipLock: true },
      );

      if (driverBonusFee > 0) {
        await this.creditDriverWallet(
          client,
          driverId,
          driverBonusFee,
          orderId,
          driverShiftId,
          `Time-based bonus for order ${orderNumber}`,
          'BONUS',
          { skipLock: true },
        );
      }

      // NOTE: no upfront reimbursement here. The upfront slice is part of
      // grandTotal, which the driver already collected in cash/mobile-wallet
      // (see the CASH_COLLECTED debit above) — crediting it again would pay
      // the driver the upfront twice. A reimbursement would only apply if the
      // platform itself ever collected the upfront online, which no current
      // payment method does.

      // Fetch updated wallet balance after transactions
      const driverSnapshot = await client.driver.findUnique({
        where: { id: driverId },
        select: {
          id: true,
          userId: true,
          status: true,
          walletBalance: true,
          ordersSinceSettlement: true,
        },
      });

      const currentBalance = driverSnapshot?.walletBalance ?? 0;
      const maxNegative = Number(
        (settings as any).maxNegativeDriverBalance ?? 500,
      );
      const shouldLock = currentBalance < -maxNegative;

      // Periodic settlement: after `driverSettlementOrderThreshold` delivered orders
      // (default 10), a driver who owes the platform any money is blocked from new
      // dispatches until they transfer it to the platform wallet via a top-up.
      const settlementThreshold = Number(
        settings.driverSettlementOrderThreshold ?? 10,
      );
      const nextSettlementCount =
        (driverSnapshot?.ordersSinceSettlement ?? 0) + 1;
      const settlementDue =
        !shouldLock &&
        settlementThreshold > 0 &&
        nextSettlementCount >= settlementThreshold &&
        currentBalance < 0;

      const driver = await client.driver.update({
        where: { id: driverId },
        data: {
          totalOrders: { increment: 1 },
          ordersSinceSettlement: { increment: 1 },
          // Self-healing: a driver whose balance recovered through earnings
          // (e.g. a manually assigned order) must not stay blocked forever
          // waiting for a top-up approval. Only the flag is cleared here —
          // SUSPENDED status still requires the top-up flow to lift.
          hasUnpaidCommission:
            shouldLock || settlementDue || currentBalance < 0 ? true : false,
          status: shouldLock ? DriverStatus.SUSPENDED : undefined,
        },
        select: { id: true, userId: true, status: true },
      });

      if (shouldLock) {
        statusEffects.push({
          kind: 'LOCKED',
          driver,
          prevStatus: driverSnapshot?.status ?? DriverStatus.ONLINE,
        });
      } else if (settlementDue) {
        statusEffects.push({
          kind: 'SETTLEMENT',
          driver,
          prevStatus: driverSnapshot?.status ?? DriverStatus.ONLINE,
        });
      }

      if (coinsEarned > 0) {
        const existing = await client.customerCoinTransaction.findFirst({
          where: { orderId, type: 'EARNED' },
        });
        if (!existing) {
          const customer = await client.customer.update({
            where: { id: customerId },
            data: { coinBalance: { increment: coinsEarned } },
            select: { coinBalance: true },
          });

          await client.customerCoinTransaction.create({
            data: {
              customerId,
              orderId,
              type: 'EARNED',
              amount: coinsEarned,
              balanceAfter: customer.coinBalance,
              description: `Earned coins from order ${orderNumber}`,
            },
          });
        }
      }

      if (vendorId && isContracted) {
        // Vendor wallet: credit revenue (subtotal) and debit commission ONLY if they are contracted
        await this.statsRepository.creditVendorWallet(
          vendorId,
          vendorRevenue,
          'ORDER_REVENUE',
          orderId,
          `Order ${orderNumber} revenue`,
          client,
          { skipLock: true },
        );

        await this.statsRepository.debitVendorWallet(
          vendorId,
          commission,
          'COMMISSION_DEDUCTION',
          orderId,
          `Commission for order ${orderNumber}`,
          client,
          { skipLock: true },
        );
      }
    });

    // ─── Stats are applied via the queue after commit ───────────────────────
    // The worker upserts the event-time DAILY bucket; coarser buckets are
    // re-bucketed from DAILY on read (see statistics.repository).
    // Exactly-once is enforced by the processing-marker claim inside the same
    // transaction as the increment (see statistics.processor), not by job
    // attempts — retries are therefore safe. Jobs carry an explicit payload.
    if (applied) {
      const statsJobs: Array<Promise<void>> = [
        this.enqueueStatsJob({
          name: STATS_JOBS.UPDATE_DRIVER,
          sourceKey: `settle:${orderId}:${STATS_JOBS.UPDATE_DRIVER}`,
          data: {
            driverId,
            increment: {
              totalOrders: 1,
              totalEarnings: driverEarnings,
              completedOrders: 1,
            },
          },
          periods,
        }),
        this.enqueueStatsJob({
          name: STATS_JOBS.UPDATE_APP,
          sourceKey: `settle:${orderId}:${STATS_JOBS.UPDATE_APP}`,
          data: {
            increment: {
              totalOrders: 1,
              totalAdminRevenue: platformRevenue,
              totalDeliveryFees: deliveryFee,
            },
          },
          periods,
        }),
      ];

      if (vendorId) {
        statsJobs.push(
          this.enqueueStatsJob({
            name: STATS_JOBS.UPDATE_VENDOR,
            sourceKey: `settle:${orderId}:${STATS_JOBS.UPDATE_VENDOR}`,
            data: {
              vendorId,
              increment: {
                totalOrders: 1,
                totalRevenue: vendorRevenue,
                totalCommission: isContracted ? commission : 0,
                totalTax: tax,
                completedOrders: 1,
              },
            },
            periods,
          }),
        );
      }

      await Promise.all(
        statsJobs.map((job) =>
          job.catch((err: unknown) =>
            this.logger.error(
              `Failed to enqueue stats for order ${orderNumber}: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
        ),
      );
    }

    // Emit events after a successful commit only
    for (const effect of statusEffects) {
      if (effect.kind === 'LOCKED') {
        this.logger.warn(
          `Driver ${driverId} locked out due to unpaid commission on driver-collected order ${orderNumber}.`,
        );

        this.socketService.disconnectUser(effect.driver.userId);

        this.eventEmitter.emit(
          EVENTS.DRIVER_STATUS_CHANGED,
          new DriverStatusChangedEvent(
            effect.driver.id,
            effect.driver.userId,
            effect.prevStatus,
            DriverStatus.SUSPENDED,
            'UNPAID_COMMISSION',
          ),
        );
      } else {
        this.logger.warn(
          `Driver ${driverId} reached settlement milestone (${effect.driver.status}) with negative balance — blocked from new orders until settled.`,
        );

        this.eventEmitter.emit(
          EVENTS.DRIVER_STATUS_CHANGED,
          new DriverStatusChangedEvent(
            effect.driver.id,
            effect.driver.userId,
            effect.prevStatus,
            effect.driver.status,
            'SETTLEMENT_REQUIRED',
          ),
        );
      }
    }

    // Emit settled event — listeners can send receipts etc.
    this.eventEmitter.emit(
      EVENTS.ORDER_SETTLED,
      new OrderSettledEvent(
        orderId,
        orderNumber,
        vendorId,
        driverId,
        driverShiftId,
        grandTotal,
        deliveryFee,
        commissionRate,
        0, // taxRate not stored on payload; pass 0 or extend payload if needed
      ),
    );

    this.logger.log(
      `Order ${orderNumber} settled — ` +
        `vendor: +${vendorRevenue} -${commission} commission, ` +
        `driver: +${driverEarnings}, platform: +${platformRevenue}`,
    );
  }

  // ─── Record cancelled order ───────────────────────────────────────────────

  async recordCancellation(
    orderId: string,
    vendorId: string | null,
    driverId: string | null,
  ): Promise<void> {
    const periods = this.statsRepository.getPeriodsForDate(new Date());

    await Promise.all([
      this.enqueueStatsJob({
        name: STATS_JOBS.UPDATE_APP,
        sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_APP}`,
        data: { increment: { totalOrders: 1 } },
        periods,
      }),
      ...(vendorId
        ? [
            this.enqueueStatsJob({
              name: STATS_JOBS.UPDATE_VENDOR,
              sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_VENDOR}`,
              data: {
                vendorId,
                increment: { totalOrders: 1, cancelledOrders: 1 },
              },
              periods,
            }),
          ]
        : []),
      ...(driverId
        ? [
            this.enqueueStatsJob({
              name: STATS_JOBS.UPDATE_DRIVER,
              sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_DRIVER}`,
              data: {
                driverId,
                increment: { totalOrders: 1, cancelledOrders: 1 },
              },
              periods,
            }),
          ]
        : []),
    ]).catch((err: unknown) =>
      this.logger.error(
        `Failed to record cancellation stats: ${err instanceof Error ? err.message : String(err)}`,
      ),
    );
  }

  // ─── Dispatch counters ────────────────────────────────────────────────────

  async recordDispatchSent(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await this.enqueueStatsJob({
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-sent:${dispatchId}`,
      data: { driverId, increment: { totalDispatchesReceived: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchAccepted(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await this.enqueueStatsJob({
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-accepted:${dispatchId}`,
      data: { driverId, increment: { dispatchesAccepted: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchRejected(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await this.enqueueStatsJob({
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-rejected:${dispatchId}`,
      data: { driverId, increment: { dispatchesRejected: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchExpired(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await this.enqueueStatsJob({
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-expired:${dispatchId}`,
      data: { driverId, increment: { dispatchesExpired: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  // ─── Queue helpers ────────────────────────────────────────────────────────

  /**
   * Enqueue a stats update job to the stats queue. `sourceKey` is the DB
   * idempotency key: it must be deterministic for the underlying event
   * (e.g. `settle:<orderId>:UPDATE_DRIVER`) so a re-delivered job is skipped by
   * the worker instead of re-applying the `+=` upserts. It is safe for the job
   * system to retry (the claim is made in the same transaction as the
   * increment), so enqueues deliberately use the queue's default attempts.
   */
  private async enqueueStatsJob(params: {
    name: string;
    sourceKey: string;
    data: Record<string, unknown>;
    periods: StatPeriodRange[];
  }) {
    await this.statsQueue.add(params.name, {
      ...params.data,
      sourceKey: params.sourceKey,
      // Serialize as ISO strings: BullMQ round-trips job.data through JSON
      // and the worker rehydrates them into Dates.
      periods: params.periods.map((p) => ({
        period: p.period,
        startDate: p.startDate.toISOString(),
        endDate: p.endDate.toISOString(),
      })),
    });
  }

  // ─── Online hours ─────────────────────────────────────────────────────────

  // Statuses that count as "on the clock".
  private static readonly ONLINE_STATUSES = new Set<DriverStatus>([
    DriverStatus.ONLINE,
    DriverStatus.BUSY,
    DriverStatus.ON_DELIVERY,
  ]);

  // Online-session start key lives in Redis so the tracker is accurate even
  // with multiple API/worker instances (PM2 cluster mode) sharing one store.
  private static readonly ONLINE_SINCE_KEY_PREFIX = 'stats:onlineSince:';
  // Safety TTL: a stale key (e.g. missed offline event or process restart)
  // self-cleans, while a real shift far exceeds this duration anyway.
  private static readonly ONLINE_SINCE_TTL_SECONDS = 7 * 24 * 60 * 60;

  @OnEvent(EVENTS.DRIVER_STATUS_CHANGED)
  async handleDriverStatusChanged(event: DriverStatusChangedEvent) {
    const wasOnline = StatisticsService.ONLINE_STATUSES.has(
      event.oldStatus as DriverStatus,
    );
    const isOnline = StatisticsService.ONLINE_STATUSES.has(
      event.newStatus as DriverStatus,
    );

    const key = `${StatisticsService.ONLINE_SINCE_KEY_PREFIX}${event.driverId}`;

    if (!wasOnline && isOnline) {
      // Session start — remember when the driver went on the clock.
      await this.redisService
        .set(
          key,
          String(Date.now()),
          StatisticsService.ONLINE_SINCE_TTL_SECONDS,
        )
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record online-session start for driver ${event.driverId}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
      return;
    }

    if (wasOnline && !isOnline) {
      // Session end — atomically claim + clear the start so every instance
      // accrues the elapsed time exactly once.
      const startedAtMs = await this.redisService.getdel(key);
      if (!startedAtMs) {
        this.logger.warn(
          `Online-session start missing for driver ${event.driverId} (${event.oldStatus} → ${event.newStatus}); skipping onlineHours accrual.`,
        );
        return;
      }

      const hours = Math.max(0, (Date.now() - Number(startedAtMs)) / 3_600_000);
      if (hours <= 0) return;

      const periods = this.statsRepository.getPeriodsForDate(
        new Date(Number(startedAtMs)),
      );
      await this.enqueueStatsJob({
        name: STATS_JOBS.UPDATE_DRIVER,
        // Session identity (driverId + start epoch) makes this deterministic:
        // the same closed session can never be re-enqueued with a different key.
        sourceKey: `online:${event.driverId}:${startedAtMs}`,
        data: {
          driverId: event.driverId,
          increment: { onlineHours: Math.round(hours * 100) / 100 },
        },
        periods,
      }).catch((err: unknown) =>
        this.logger.error(
          `Failed to record online hours for driver ${event.driverId}: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
    }
  }

  // ─── Read stats ───────────────────────────────────────────────────────────

  async getVendorStats(
    vendorId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    return this.statsRepository.getVendorStats(
      vendorId,
      period,
      limit,
      from,
      to,
    );
  }

  async getDriverStats(
    driverId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    return this.statsRepository.getDriverStats(
      driverId,
      period,
      limit,
      from,
      to,
    );
  }

  async getMyDriverStats(
    userId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!driver) return [];
    return this.statsRepository.getDriverStats(
      driver.id,
      period,
      limit,
      from,
      to,
    );
  }

  async getAppStats(
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    return this.statsRepository.getAppStats(period, limit, from, to);
  }

  async getMostOrderedProduct(vendorId: string) {
    // Tiebreaker: 1. Higher quantity sold (totalOrders), 2. More recent activity (lastOrderedAt), 3. Lower productId
    const result = await this.prisma.$queryRaw<
      Array<{ productId: string; totalOrders: number; lastOrderedAt: Date }>
    >`
      SELECT 
        oi."productId" as "productId", 
        SUM(oi.quantity)::int as "totalOrders",
        MAX(o."createdAt") as "lastOrderedAt"
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      WHERE o."vendorId" = ${vendorId} AND o.status = 'DELIVERED' AND oi."productId" IS NOT NULL
      GROUP BY oi."productId"
      ORDER BY "totalOrders" DESC, "lastOrderedAt" DESC, oi."productId" ASC
      LIMIT 1
    `;

    if (!result || result.length === 0) {
      return null;
    }

    const stats = result[0];
    const product = await this.prisma.product.findUnique({
      where: { id: stats.productId },
      select: {
        id: true,
        name: true,
        nameAr: true,
        imageUrl: true,
      },
    });

    if (!product) {
      return null;
    }

    return {
      vendorId,
      productId: stats.productId,
      totalOrders: stats.totalOrders,
      productName: product.name,
      productNameAr: product.nameAr,
      productImage: product.imageUrl,
    };
  }

  // ─── Analytics Leaderboards ───────────────────────────────────────────────

  async getTopDrivers(limit: number, from?: string, to?: string) {
    return this.statsRepository.getTopDrivers(limit, from, to);
  }

  async getTopCustomers(limit: number, from?: string, to?: string) {
    return this.statsRepository.getTopCustomers(limit, from, to);
  }

  async getTopVendors(limit: number, from?: string, to?: string) {
    return this.statsRepository.getTopVendors(limit, from, to);
  }

  async getTopProducts(limit: number, from?: string, to?: string) {
    return this.statsRepository.getTopProducts(limit, from, to);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  private async creditDriverWallet(
    client: Prisma.TransactionClient,
    driverId: string,
    amount: number,
    orderId: string,
    driverShiftId: string | null,
    description: string,
    type:
      | 'DELIVERY_FEE'
      | 'BONUS'
      | 'ADJUSTMENT'
      | 'PENALTY'
      | 'PAYOUT'
      | 'CASH_COLLECTED'
      | 'CASH_HANDED_TO_VENDOR' = 'DELIVERY_FEE',
    options: { skipLock?: boolean } = {},
  ): Promise<void> {
    // Unlike settleOrder, this method does not take a row lock by default so
    // standalone use remains safe. settleOrder acquires the driver lock once at
    // the top of its transaction and passes skipLock: true here.
    if (!options.skipLock) {
      await client.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;
    }

    const existing = await client.driverWalletTransaction.findFirst({
      where: { orderId, type },
    });
    if (existing) return;

    const driver = await client.driver.update({
      where: { id: driverId },
      data: { walletBalance: { increment: amount } },
      select: { walletBalance: true },
    });

    await client.driverWalletTransaction.create({
      data: {
        driverId,
        orderId,
        driverShiftId,
        type,
        amount,
        balanceAfter: driver.walletBalance,
        description,
      },
    });
  }
}
