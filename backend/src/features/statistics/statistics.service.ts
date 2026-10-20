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
import {
  Prisma,
  StatisticPeriod,
  DriverStatus,
  DeliveryGroupStatus,
} from '@prisma/client';
import {
  QUEUES,
  STATS_JOBS,
} from '../../infrastructure/queue/queues.constants';
import type {
  StatPeriodRange,
  VendorProductSalesOptions,
} from './statistics.repository';

export interface SettleOrderPayload {
  orderId: string;
  orderNumber: string;
  orderType: string;
  vendorId: string | null;
  driverId: string;
  driverShiftId: string | null;
  zoneId: string | null;
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
      zoneId,
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
      distanceKm,
      driverTier,
      discount,
    } = payload;

    // Idempotency guard: never settle the same order twice. BullMQ retries
    // after a partial failure used to re-run the stat upserts and double-count
    // (wallet writes were already idempotent via orderId+type+driverId).
    const orderRow = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { settledAt: true },
    });
    if (orderRow?.settledAt) {
      this.logger.log(`Order ${orderNumber} already settled; skipping.`);
      return;
    }

    // Business rules for revenue split:
    // If the vendor is contracted: commission is paid by the vendor.
    // If NOT contracted: customer pays commission as a service fee, so the vendor receives the full subtotal.
    const commission = Math.round(subtotal * (commissionRate / 100));

    const vendorRevenue = subtotal;

    // Recalculate driver delivery fees by tier. The customer paid based on the
    // Gold tier; each driver is adjusted down by their own tier difference.
    const settings = await this.platformSettings.getSettings();
    const goldBonus = Number(settings.goldTierBonusPerKm ?? 0);
    const silverBonus = Number(settings.silverTierBonusPerKm ?? 0);
    const bronzeBonus = Number(settings.bronzeTierBonusPerKm ?? 0);

    const tierBonusPerKm = (tier: string): number =>
      tier === 'SILVER'
        ? silverBonus
        : tier === 'BRONZE'
          ? bronzeBonus
          : goldBonus;

    const driverShare = 1 - deliveryCommissionRate / 100;

    interface DriverPayout {
      driverId: string;
      driverShiftId: string | null;
      amount: number;
    }

    // A delivery-grouped (multi-vendor) order has one primary driver per
    // delivery; EACH one is paid their own tier-adjusted fee (and any assistant
    // their own full fee). Without this only the mirrored order.driverId (the
    // first group) was ever paid, silently stiffing every other driver.
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        orderId,
        status: DeliveryGroupStatus.DELIVERED,
        primaryDriverId: { not: null },
      },
      select: {
        id: true,
        sequence: true,
        deliveryFee: true,
        distanceKm: true,
        primaryDriverId: true,
        primaryDriverShiftId: true,
        assistDriverId: true,
        assistDriverShiftId: true,
        assistCustomerApproved: true,
      },
      orderBy: { sequence: 'asc' },
    });

    const primaryPayouts: DriverPayout[] = [];
    const assistPayouts: DriverPayout[] = [];
    const assistApprovedFlags: boolean[] = [];
    const bronzeDriverIds = new Set<string>();

    const primaryFeeFor = (
      fee: number,
      routeKm: number,
      primaryTier: string,
    ): number => {
      const tierDifferencePerKm = goldBonus - tierBonusPerKm(primaryTier);
      let result =
        settings.driverShiftsEnabled &&
        orderType === 'STANDARD' &&
        tierDifferencePerKm > 0
          ? Math.max(0, fee - tierDifferencePerKm * routeKm)
          : fee;
      // Bronze drivers take 2 less than the standard delivery fee.
      if (primaryTier === 'BRONZE') {
        result = Math.max(0, result - 2);
      }
      return result;
    };

    // 100% rule: the assistant keeps their own FULL fee, mirroring the primary's
    // tier adjustment — never a percentage of the primary's pot.
    const assistFeeFor = (
      primaryTier: string,
      assistTier: string,
      fee: number,
      routeKm: number,
    ): number => {
      const tierDiffPerKm =
        tierBonusPerKm(primaryTier) - tierBonusPerKm(assistTier);
      const base = settings.driverShiftsEnabled
        ? Math.max(0, fee - Math.max(0, tierDiffPerKm) * routeKm)
        : fee;
      let amount = Math.max(0, Math.round(base * driverShare));
      // Bronze assistants also take 2 less than their standard share.
      if (assistTier === 'BRONZE') {
        amount = Math.max(0, amount - 2);
      }
      return amount;
    };

    if (groups.length > 0) {
      const primaryIds = Array.from(
        new Set(groups.map((g) => g.primaryDriverId!).filter(Boolean)),
      );
      const assistIds = Array.from(
        new Set(
          groups
            .map((g) => g.assistDriverId)
            .filter((id): id is string => !!id),
        ),
      );
      const tierRows = await this.prisma.driver.findMany({
        where: { id: { in: [...primaryIds, ...assistIds] } },
        select: { id: true, tier: true },
      });
      const tierById = new Map(tierRows.map((d) => [d.id, d.tier as string]));

      for (const g of groups) {
        const primaryId = g.primaryDriverId!;
        const primaryTier = tierById.get(primaryId) ?? driverTier;
        if (primaryTier === 'BRONZE') bronzeDriverIds.add(primaryId);
        const routeKm = g.distanceKm ?? distanceKm;
        const primaryFee = primaryFeeFor(g.deliveryFee, routeKm, primaryTier);
        const earnings = Math.max(0, Math.round(primaryFee * driverShare));

        primaryPayouts.push({
          driverId: primaryId,
          driverShiftId: g.primaryDriverShiftId ?? null,
          amount: earnings,
        });

        if (g.assistDriverId) {
          const assistTier = tierById.get(g.assistDriverId) ?? 'GOLD';
          if (assistTier === 'BRONZE') bronzeDriverIds.add(g.assistDriverId!);
          const assistAmount = assistFeeFor(
            primaryTier,
            assistTier,
            primaryFee,
            routeKm,
          );
          if (assistAmount > 0) {
            assistPayouts.push({
              driverId: g.assistDriverId,
              driverShiftId: g.assistDriverShiftId ?? null,
              amount: assistAmount,
            });
            assistApprovedFlags.push(g.assistCustomerApproved === true);
          }
        }
      }
    } else {
      // Legacy single-delivery path (single-vendor order).
      const primaryFee = primaryFeeFor(deliveryFee, distanceKm, driverTier);
      if (driverTier === 'BRONZE') bronzeDriverIds.add(driverId);
      const earnings = Math.round(primaryFee * driverShare);
      primaryPayouts.push({
        driverId,
        driverShiftId,
        amount: earnings,
      });

      // Assisted delivery (single-vendor): the assistant earns their own full
      // fee when the customer approved it (customer-funded, not platform).
      const orderAssist = await this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
          assistDriverId: true,
          assistDriverShiftId: true,
          assistFee: true,
          assistCustomerApproved: true,
        },
      });
      if (
        orderAssist?.assistDriverId &&
        orderAssist.assistCustomerApproved === true
      ) {
        const assistTierRow = await this.prisma.driver.findUnique({
          where: { id: orderAssist.assistDriverId },
          select: { tier: true },
        });
        const assistTier = assistTierRow?.tier ?? 'GOLD';
        if (assistTier === 'BRONZE' && orderAssist.assistDriverId) {
          bronzeDriverIds.add(orderAssist.assistDriverId);
        }
        const assistAmount = assistFeeFor(
          driverTier,
          assistTier,
          primaryFee,
          distanceKm,
        );
        if (assistAmount > 0) {
          assistPayouts.push({
            driverId: orderAssist.assistDriverId,
            driverShiftId: orderAssist.assistDriverShiftId ?? null,
            amount: assistAmount,
          });
        }
      }
    }

    const totalPrimaryEarnings = primaryPayouts.reduce(
      (sum, p) => sum + p.amount,
      0,
    );
    const totalAssistEarnings = assistPayouts.reduce(
      (sum, p) => sum + p.amount,
      0,
    );
    const driverEarnings = totalPrimaryEarnings;
    const applicationDeliveryCut = deliveryFee - totalPrimaryEarnings;
    const paidDriverIds = Array.from(
      new Set(
        [
          driverId,
          ...primaryPayouts.map((p) => p.driverId),
          ...assistPayouts.map((p) => p.driverId),
        ].filter(Boolean),
      ),
    );

    // Sequentially process driver and vendor wallets to prevent DB row deadlocks
    const platformFee = isContracted ? commission : (serviceFee ?? commission);
    let platformRevenue = platformFee + applicationDeliveryCut;

    // If the platform pays the driver bonus fee (not paid by customer), deduct from net platform revenue
    if (!settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      platformRevenue -= driverBonusFee;
    }

    // Assisting drivers that the customer approved are paid from the customer's
    // charge (already added to the order), so the platform does NOT absorb them.
    // Only legacy/unapproved assists (assistCustomerApproved !== true) are
    // absorbed by the platform's revenue.
    const platformAbsorbedAssist = assistPayouts.reduce(
      (sum, p, i) => sum + (assistApprovedFlags[i] ? 0 : p.amount),
      0,
    );
    platformRevenue -= platformAbsorbedAssist;

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
    const manager = zoneId
      ? await this.prisma.driverManager.findFirst({
          where: { zoneId },
          select: { id: true },
        })
      : null;
    const managerShareRate = 0.1;
    const managerShare = manager
      ? Math.round(deliveryFee * managerShareRate)
      : 0;
    const managerPenalty = manager ? 2 * bronzeDriverIds.size : 0;
    const managerAmount = Math.max(0, managerShare - managerPenalty);

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
      // 4× per settlement). Every driver paid by this settlement is locked, not
      // just the order-level collector, so multi-vendor deliveries are safe.
      for (const paidDriverId of [...paidDriverIds].sort()) {
        await client.$executeRaw`SELECT id FROM drivers WHERE id = ${paidDriverId} FOR UPDATE`;
      }

      // Lock every vendor that will be paid (single vendor + all portions).
      const portionVendorIds = await client.orderVendorFulfillment.findMany({
        where: { orderId },
        select: { vendorId: true },
      });
      const vendorLockIds = Array.from(
        new Set([
          ...(vendorId ? [vendorId] : []),
          ...portionVendorIds.map((p) => p.vendorId),
        ]),
      ).sort();
      for (const vendorLockId of vendorLockIds) {
        await client.$executeRaw`SELECT id FROM vendors WHERE id = ${vendorLockId} FOR UPDATE`;
      }

      if (isDriverCollected) {
        // For contracted vendors, the driver collects grandTotal (food + delivery + fees).
        // For uncontracted vendors, the driver paid food subtotal cash at pickup out of pocket,
        // so net cash collected on behalf of the platform is grandTotal - subtotal.
        //
        // A multi-vendor order has one driver PER delivery, so the cash is split
        // across the delivered groups — debiting it all to the mirrored first
        // driver left every other delivery's driver owing nothing while still
        // being paid their delivery fee.
        if (groups.length > 0) {
          const collections = await this.splitCollectedCash(client, {
            groups,
            subtotal,
            deliveryFee,
            serviceFee,
            tax,
            driverBonusFee,
            discount,
          });
          for (const collected of collections) {
            if (collected.amount === 0) continue;
            await this.creditDriverWallet(
              client,
              collected.driverId,
              -collected.amount,
              orderId,
              collected.driverShiftId,
              `Collected payment (COD/Mobile Wallet) for order ${orderNumber}`,
              'CASH_COLLECTED',
              { skipLock: true },
            );
          }
        } else {
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
      }

      // Pay EACH delivery's primary driver their own tier-adjusted fee. For a
      // single-delivery order there is exactly one entry (unchanged behaviour);
      // a delivery-grouped order has one entry per delivered group.
      for (const payout of primaryPayouts) {
        if (payout.amount <= 0) continue;
        await this.creditDriverWallet(
          client,
          payout.driverId,
          payout.amount,
          orderId,
          payout.driverShiftId,
          `Delivery fee for order ${orderNumber}`,
          'DELIVERY_FEE',
          { skipLock: true },
        );
      }

      // Each assisting driver earns their own FULL fee. Cash collection stays
      // with the primary driver — two drivers collecting the customer's money
      // would risk double-collection and unreconciled float, so assistants are
      // paid purely from the fee pot (absorbed by platform revenue above).
      for (const payout of assistPayouts) {
        if (payout.amount <= 0) continue;
        await this.creditDriverWallet(
          client,
          payout.driverId,
          payout.amount,
          orderId,
          payout.driverShiftId,
          `Assisting delivery fee for order ${orderNumber}`,
          'DELIVERY_FEE',
          { skipLock: true },
        );
      }

      if (manager && (managerShare > 0 || managerPenalty > 0)) {
        await client.$executeRaw`SELECT id FROM driver_managers WHERE id = ${manager.id} FOR UPDATE`;

        const alreadyManagerSettled =
          await client.driverManagerWalletTransaction.findFirst({
            where: {
              orderId,
              type: 'DELIVERY_SHARE',
              managerId: manager.id,
            },
          });

        if (!alreadyManagerSettled) {
          const managerRow = await client.driverManager.findUnique({
            where: { id: manager.id },
            select: { walletBalance: true },
          });
          let balance = managerRow?.walletBalance ?? 0;

          if (managerShare > 0) {
            balance += managerShare;
            await client.driverManager.update({
              where: { id: manager.id },
              data: { walletBalance: balance },
            });
            await client.driverManagerWalletTransaction.create({
              data: {
                managerId: manager.id,
                orderId,
                type: 'DELIVERY_SHARE',
                amount: managerShare,
                balanceAfter: balance,
                description: `Delivery manager share for order ${orderNumber}`,
                idempotencyKey: `${orderId}:DELIVERY_SHARE:${manager.id}`,
              },
            });
          }

          if (managerPenalty > 0) {
            balance -= managerPenalty;
            await client.driverManager.update({
              where: { id: manager.id },
              data: { walletBalance: balance },
            });
            await client.driverManagerWalletTransaction.create({
              data: {
                managerId: manager.id,
                orderId,
                type: 'BRONZE_PENALTY',
                amount: -managerPenalty,
                balanceAfter: balance,
                description: `Bronze driver penalty for order ${orderNumber}`,
                idempotencyKey: `${orderId}:BRONZE_PENALTY:${manager.id}`,
              },
            });
          }
        }
      }

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

      const maxNegative = Number(
        (settings as any).maxNegativeDriverBalance ?? 500,
      );
      // Periodic settlement: after `driverSettlementOrderThreshold` delivered
      // orders (default 10), a driver who owes the platform any money is blocked
      // from new dispatches until they top up. Applied to EVERY driver paid by
      // this settlement so each one's counters/limits stay accurate.
      const settlementThreshold = Number(
        settings.driverSettlementOrderThreshold ?? 10,
      );

      for (const paidDriverId of paidDriverIds) {
        const driverSnapshot = await client.driver.findUnique({
          where: { id: paidDriverId },
          select: {
            id: true,
            userId: true,
            status: true,
            walletBalance: true,
            ordersSinceSettlement: true,
          },
        });

        const currentBalance = driverSnapshot?.walletBalance ?? 0;
        const shouldLock = currentBalance < -maxNegative;

        const nextSettlementCount =
          (driverSnapshot?.ordersSinceSettlement ?? 0) + 1;
        const settlementDue =
          !shouldLock &&
          settlementThreshold > 0 &&
          nextSettlementCount >= settlementThreshold &&
          currentBalance < 0;

        const driver = await client.driver.update({
          where: { id: paidDriverId },
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
      }

      if (coinsEarned > 0) {
        // Serialize coin credits for the same customer. The order row lock
        // above already serializes retries of THIS order; the customer lock
        // additionally orders credits from different orders of the same
        // customer. The findFirst guard + unique ledger key make retries
        // idempotent (mirrors the REFUNDED path in cancelOrder).
        await client.$executeRaw`SELECT id FROM customers WHERE id = ${customerId} FOR UPDATE`;
        const existing = await client.customerCoinTransaction.findFirst({
          where: { orderId, type: 'EARNED' },
        });
        if (!existing) {
          const customer = await client.customer.update({
            where: { id: customerId },
            data: { coinBalance: { increment: coinsEarned } },
            select: { coinBalance: true },
          });

          try {
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
          } catch (e: any) {
            if (e?.code !== 'P2002') throw e;
          }
        }
      }

      // ─── Vendor payouts ────────────────────────────────────────────────────────
      // Single-vendor orders pay out exactly as before. Multi-vendor orders pay
      // out once per ACCEPTED vendor portion, using each portion's own subtotal
      // and the commission rate captured at checkout (so a later rate change
      // cannot alter an already-delivered order). Rejected/cancelled portions
      // are never dispatched and never paid.
      const portions = await client.orderVendorFulfillment.findMany({
        where: { orderId, status: 'ACCEPTED' },
        select: { vendorId: true, subtotal: true, commissionRate: true },
      });

      const payables: Array<{
        vendorId: string;
        revenue: number;
        commission: number;
        description: string;
      }> =
        portions.length > 0
          ? await Promise.all(
              portions.map(async (p) => {
                const contracted = await client.vendor.findUnique({
                  where: { id: p.vendorId },
                  select: { isContracted: true },
                });
                if (!contracted?.isContracted) return null;
                const rate = Number(p.commissionRate ?? 0);
                return {
                  vendorId: p.vendorId,
                  revenue: p.subtotal,
                  commission: Math.round(p.subtotal * (rate / 100)),
                  description: `Order ${orderNumber} revenue`,
                };
              }),
            ).then((rows) =>
              rows.filter((r): r is NonNullable<typeof r> => !!r),
            )
          : // Legacy single-vendor path: unchanged behaviour.
            vendorId && isContracted
            ? [
                {
                  vendorId,
                  revenue: vendorRevenue,
                  commission,
                  description: `Order ${orderNumber} revenue`,
                },
              ]
            : [];

      for (const payable of payables) {
        await this.statsRepository.creditVendorWallet(
          payable.vendorId,
          payable.revenue,
          'ORDER_REVENUE',
          orderId,
          payable.description,
          client,
          { skipLock: true },
        );

        await this.statsRepository.debitVendorWallet(
          payable.vendorId,
          payable.commission,
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
      const driverEarningsByDriver = new Map<string, number>();
      for (const payout of [...primaryPayouts, ...assistPayouts]) {
        driverEarningsByDriver.set(
          payout.driverId,
          (driverEarningsByDriver.get(payout.driverId) ?? 0) + payout.amount,
        );
      }

      const statsJobs: Array<Promise<void>> = [
        ...Array.from(driverEarningsByDriver.entries()).map(([dId, amount]) =>
          this.enqueueStatsJob({
            name: STATS_JOBS.UPDATE_DRIVER,
            sourceKey: `settle:${orderId}:driver:${dId}`,
            data: {
              driverId: dId,
              increment: {
                totalOrders: 1,
                totalEarnings: amount,
                completedOrders: 1,
              },
            },
            periods,
          }),
        ),
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
      } else {
        // Multi-vendor: one vendor-stats increment per accepted portion, keyed
        // by vendor so several vendors of the same order each accrue once.
        const portions = await this.prisma.orderVendorFulfillment.findMany({
          where: { orderId, status: 'ACCEPTED' },
          select: {
            vendorId: true,
            subtotal: true,
            commissionRate: true,
            vendor: { select: { isContracted: true } },
          },
        });
        for (const portion of portions) {
          statsJobs.push(
            this.enqueueStatsJob({
              name: STATS_JOBS.UPDATE_VENDOR,
              sourceKey: `settle:${orderId}:vendor:${portion.vendorId}`,
              data: {
                vendorId: portion.vendorId,
                increment: {
                  totalOrders: 1,
                  totalRevenue: portion.subtotal,
                  totalCommission: portion.vendor?.isContracted
                    ? Math.round(
                        portion.subtotal *
                          (Number(portion.commissionRate) / 100),
                      )
                    : 0,
                  completedOrders: 1,
                },
              },
              periods,
            }),
          );
        }
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
          `Driver ${effect.driver.id} locked out due to unpaid commission on driver-collected order ${orderNumber}.`,
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
          `Driver ${effect.driver.id} reached settlement milestone (${effect.driver.status}) with negative balance — blocked from new orders until settled.`,
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
        `drivers: +${driverEarnings} across ${primaryPayouts.length} deliver(s)` +
        (totalAssistEarnings > 0
          ? ` (+${totalAssistEarnings} assisting)`
          : '') +
        `, platform: +${platformRevenue}`,
    );

    await this.prisma.order.update({
      where: { id: orderId },
      data: { settledAt: new Date() },
    });
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

  async getVendorProductSales(
    vendorId: string,
    opts: VendorProductSalesOptions = {},
  ) {
    return this.statsRepository.getVendorProductSales(vendorId, opts);
  }

  async getMostOrderedProduct(vendorId: string) {
    // Tiebreaker: 1. Higher quantity sold (totalOrders), 2. More recent activity (lastOrderedAt), 3. Lower productId
    const result = await this.prisma.$queryRaw<
      Array<{ productId: string; totalOrders: number; lastOrderedAt: Date }>
    >`
      WITH vendor_items AS (
        SELECT oi."productId", oi.quantity, o."createdAt"
        FROM order_items oi
        JOIN orders o ON o.id = oi."orderId"
        WHERE o."vendorId" = ${vendorId}
          AND o.status = 'DELIVERED'
          AND o."deletedAt" IS NULL
          AND oi."fulfillmentId" IS NULL
          AND oi."rejectedAt" IS NULL
          AND oi."productId" IS NOT NULL

        UNION ALL

        SELECT oi."productId", oi.quantity, o."createdAt"
        FROM order_items oi
        JOIN order_vendor_fulfillments f ON f.id = oi."fulfillmentId"
        JOIN orders o ON o.id = f."orderId"
        WHERE f."vendorId" = ${vendorId}
          AND f.status = 'ACCEPTED'
          AND o.status = 'DELIVERED'
          AND o."deletedAt" IS NULL
          AND oi."rejectedAt" IS NULL
          AND oi."productId" IS NOT NULL
      )
      SELECT
        "productId" AS "productId",
        SUM("quantity")::int AS "totalOrders",
        MAX("createdAt") AS "lastOrderedAt"
      FROM vendor_items
      GROUP BY "productId"
      ORDER BY "totalOrders" DESC, "lastOrderedAt" DESC, "productId" ASC
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

  /**
   * Split the cash a multi-vendor order's drivers collect at the door.
   *
   * The customer pays the whole `grandTotal` in cash, but each delivery has its
   * own driver. Every driver collects for their own delivery: that delivery's
   * goods subtotal plus its own delivery fee, plus a proportional share of the
   * order-level extras (service fee + tax + driver bonus − discount). Whatever
   * the driver paid an UNCONTRACTED vendor in cash at pickup is then subtracted,
   * because only the difference is owed back to the platform. Amounts are
   * merged per driver so a single wallet debit is written per driver.
   *
   * With one group this reduces exactly to the single-delivery rule
   * (`grandTotal`, or `grandTotal − subtotal` when uncontracted).
   */
  private async splitCollectedCash(
    client: Prisma.TransactionClient,
    params: {
      groups: Array<{
        id: string;
        deliveryFee: number;
        primaryDriverId: string | null;
        primaryDriverShiftId: string | null;
      }>;
      subtotal: number;
      deliveryFee: number;
      serviceFee: number;
      tax: number;
      driverBonusFee: number;
      discount: number;
    },
  ): Promise<
    Array<{ driverId: string; driverShiftId: string | null; amount: number }>
  > {
    const items = await client.orderDeliveryGroupItem.findMany({
      where: { deliveryGroupId: { in: params.groups.map((g) => g.id) } },
      select: {
        deliveryGroupId: true,
        fulfillment: {
          select: {
            subtotal: true,
            vendor: { select: { isContracted: true } },
          },
        },
      },
    });

    const goodsByGroup = new Map<string, number>();
    const cashPaidByGroup = new Map<string, number>();
    for (const item of items) {
      const f = item.fulfillment;
      goodsByGroup.set(
        item.deliveryGroupId,
        (goodsByGroup.get(item.deliveryGroupId) ?? 0) + f.subtotal,
      );
      if (!f.vendor?.isContracted) {
        cashPaidByGroup.set(
          item.deliveryGroupId,
          (cashPaidByGroup.get(item.deliveryGroupId) ?? 0) + f.subtotal,
        );
      }
    }

    const extras =
      params.serviceFee + params.tax + params.driverBonusFee - params.discount;
    const totalGross = params.subtotal + params.deliveryFee + extras;

    const base = params.groups.map(
      (g) => (goodsByGroup.get(g.id) ?? 0) + g.deliveryFee,
    );
    const baseTotal = base.reduce((s, b) => s + b, 0);

    // Merge per driver so a driver who somehow holds two groups gets one debit
    // (the wallet writer is idempotent per orderId+type+driverId).
    const byDriver = new Map<
      string,
      { driverId: string; driverShiftId: string | null; amount: number }
    >();
    let allocated = 0;
    params.groups.forEach((g, i) => {
      if (!g.primaryDriverId) return;
      const isLast = i === params.groups.length - 1;
      const gross = isLast
        ? totalGross - allocated
        : baseTotal > 0
          ? Math.round((base[i] / baseTotal) * totalGross)
          : 0;
      allocated += gross;

      const cashPaid = cashPaidByGroup.get(g.id) ?? 0;
      const amount = Math.max(0, gross - cashPaid);
      if (amount === 0) return;

      const existing = byDriver.get(g.primaryDriverId);
      if (existing) {
        existing.amount += amount;
      } else {
        byDriver.set(g.primaryDriverId, {
          driverId: g.primaryDriverId,
          driverShiftId: g.primaryDriverShiftId,
          amount,
        });
      }
    });

    return [...byDriver.values()];
  }

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

    // Scoped by driverId: an order with an assisting driver has one DELIVERY_FEE
    // row PER DRIVER, so an orderId+type-only guard would treat the assistant's
    // payout as a duplicate and silently skip it.
    const existing = await client.driverWalletTransaction.findFirst({
      where: { orderId, type, driverId },
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
