import { Injectable, Logger, Optional } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  DeliveryGroupStatus,
  DriverStatus,
  Prisma,
  VendorTransactionType,
} from '@prisma/client';
import { OrderSettledEvent, DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { QUEUES, STATS_JOBS } from '../../infrastructure/queue/queues.constants';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  enqueueStatsJob,
  getStatsPeriodsForDate,
  type StatPeriodRange,
} from '../../common/queues/stats-queue.helper';

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
  customerUserId?: string | null;
  coinsEarned: number;
  coinsUsed: number;
  discount: number;
  isStacked?: boolean;
}

interface DriverPayout {
  driverId: string;
  driverShiftId: string | null;
  amount: number;
}

interface DeliveredGroupRow {
  id: string;
  sequence: number;
  deliveryFee: number;
  distanceKm: number | null;
  primaryDriverId: string | null;
  primaryDriverShiftId: string | null;
  assistDriverId: string | null;
  assistDriverShiftId: string | null;
  assistCustomerApproved: boolean | null;
  isStacked?: boolean | null;
}

interface SettlementPlan {
  commission: number;
  vendorRevenue: number;
  groups: DeliveredGroupRow[];
  primaryPayouts: DriverPayout[];
  assistPayouts: DriverPayout[];
  paidDriverIds: string[];
  driverEarnings: number;
  totalAssistEarnings: number;
  platformRevenue: number;
  managerPayouts: Map<string, number>;
  isDriverCollected: boolean;
  maxNegative: number;
  settlementThreshold: number;
  defaultTaxRate: number;
}

interface DriverStatusEffect {
  kind: 'LOCKED' | 'SETTLEMENT';
  driver: { id: string; userId: string; status: DriverStatus };
  prevStatus: DriverStatus;
}

type DriverWalletTxType =
  | 'DELIVERY_FEE'
  | 'BONUS'
  | 'ADJUSTMENT'
  | 'PENALTY'
  | 'PAYOUT'
  | 'CASH_COLLECTED'
  | 'CASH_HANDED_TO_VENDOR';

/**
 * Owns post-delivery financial settlement:
 * - Multi-vendor & single-vendor driver payout calculation (including Bronze/Silver/Gold + assist rules)
 * - Transactional wallet ledger updates with strict lock ordering (`order -> drivers -> vendors -> managers`)
 * - Asynchronous stat queue fan-out and post-commit socket/event notifications.
 */
@Injectable()
export class OrderSettlementService {
  private readonly logger = new Logger(OrderSettlementService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    @InjectQueue(QUEUES.STATS) private readonly statsQueue: Queue,
    @Optional() private readonly earningsCalculator?: OrderEarningsCalculator,
  ) {}

  private get earnings(): OrderEarningsCalculator {
    return (
      this.earningsCalculator ??
      new OrderEarningsCalculator(this.platformSettings)
    );
  }

  async settleOrder(payload: SettleOrderPayload): Promise<void> {
    // Fast-path idempotency guard before loading settlement inputs.
    const orderRow = await this.prisma.order.findUnique({
      where: { id: payload.orderId },
      select: { settledAt: true },
    });
    if (orderRow?.settledAt) {
      this.logger.log(`Order ${payload.orderNumber} already settled; skipping.`);
      return;
    }

    const plan = await this.buildSettlementPlan(payload);
    const now = new Date();
    const periods = getStatsPeriodsForDate(now);

    const { applied, statusEffects } = await this.executeSettlementTransaction(
      payload,
      plan,
      now,
    );

    if (!applied) {
      return;
    }

    await this.enqueueSettlementStats(payload, plan, periods);
    this.emitPostCommitEffects(payload, plan, statusEffects);
  }

  private async buildSettlementPlan(
    payload: SettleOrderPayload,
  ): Promise<SettlementPlan> {
    const {
      orderId,
      orderType,
      driverId,
      driverShiftId,
      zoneId,
      deliveryFee,
      driverBonusFee,
      subtotal,
      serviceFee,
      commissionRate,
      deliveryCommissionRate,
      isContracted,
      paymentMethod,
      distanceKm,
      driverTier,
    } = payload;

    const commission = Math.round(subtotal * (commissionRate / 100));
    const vendorRevenue = subtotal;
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

    const effectiveEarningsSettings = {
      ...settings,
      deliveryCommissionRate:
        deliveryCommissionRate ?? settings.deliveryCommissionRate ?? 20,
    };
    const driverShare = this.earnings.computeDriverShare(effectiveEarningsSettings);
    const stackedDriverShare = this.earnings.computeDriverShare(
      effectiveEarningsSettings,
      { isStacked: true },
    );
    const multiVendorDriverShare = this.earnings.computeDriverShare(
      effectiveEarningsSettings,
      { isMultiVendor: true },
    );

    const supervisorCommissionRate =
      (settings.driverManagerCommissionRate ?? 10) / 100;
    const multiVendorSupervisorRate =
      (settings.multiVendorDriverManagerCommissionRate ??
        settings.driverManagerCommissionRate ??
        10) / 100;
    const batchedSupervisorRate =
      (settings.batchedDriverManagerCommissionRate ??
        settings.driverManagerCommissionRate ??
        10) / 100;

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

    // 100% rule: assisting driver keeps their own full fee based on their own tier.
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
      if (assistTier === 'BRONZE') {
        amount = Math.max(0, amount - 2);
      }
      return amount;
    };

    const groups = (await this.prisma.orderDeliveryGroup.findMany({
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
        isStacked: true,
      },
      orderBy: { sequence: 'asc' },
    })) as DeliveredGroupRow[];

    const primaryPayouts: DriverPayout[] = [];
    const assistPayouts: DriverPayout[] = [];
    const assistApprovedFlags: boolean[] = [];

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
        const routeKm = g.distanceKm ?? distanceKm;
        const primaryFee = primaryFeeFor(g.deliveryFee, routeKm, primaryTier);
        const isGroupStacked = g.isStacked === true;
        const groupShare = isGroupStacked
          ? stackedDriverShare
          : multiVendorDriverShare;
        const amount = Math.max(0, Math.round(primaryFee * groupShare));

        primaryPayouts.push({
          driverId: primaryId,
          driverShiftId: g.primaryDriverShiftId ?? null,
          amount,
        });

        if (g.assistDriverId) {
          const assistTier = tierById.get(g.assistDriverId) ?? 'GOLD';
          const assistAmount = assistFeeFor(
            primaryTier,
            assistTier,
            g.deliveryFee,
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
      const primaryFee = primaryFeeFor(deliveryFee, distanceKm, driverTier);
      const orderShare =
        payload.isStacked === true ? stackedDriverShare : driverShare;
      primaryPayouts.push({
        driverId,
        driverShiftId,
        amount: Math.round(primaryFee * orderShare),
      });

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
        const assistAmount = assistFeeFor(
          driverTier,
          assistTier,
          deliveryFee,
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

    const driverEarnings = primaryPayouts.reduce((sum, p) => sum + p.amount, 0);
    const totalAssistEarnings = assistPayouts.reduce(
      (sum, p) => sum + p.amount,
      0,
    );
    const paidDriverIds = Array.from(
      new Set(
        [
          driverId,
          ...primaryPayouts.map((p) => p.driverId),
          ...assistPayouts.map((p) => p.driverId),
        ].filter(Boolean),
      ),
    );

    const platformFee = isContracted ? commission : (serviceFee ?? commission);
    const applicationDeliveryCut = deliveryFee - driverEarnings;
    let platformRevenue = platformFee + applicationDeliveryCut;

    if (!settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      platformRevenue -= driverBonusFee;
    }

    const platformAbsorbedAssist = assistPayouts.reduce(
      (sum, p, i) => sum + (assistApprovedFlags[i] ? 0 : p.amount),
      0,
    );
    platformRevenue -= platformAbsorbedAssist;

    const managerPayouts = new Map<string, number>();
    if (groups.length > 0) {
      for (const g of groups) {
        if (!g.primaryDriverId) continue;
        const gManager = await this.resolveDriverManager(
          g.primaryDriverId,
          zoneId,
        );
        if (gManager) {
          const rate =
            g.isStacked === true
              ? batchedSupervisorRate
              : multiVendorSupervisorRate;
          const share = Math.round(g.deliveryFee * rate);
          if (share > 0) {
            managerPayouts.set(
              gManager.id,
              (managerPayouts.get(gManager.id) ?? 0) + share,
            );
          }
        }
      }
    } else if (driverId) {
      const manager = await this.resolveDriverManager(driverId, zoneId);
      if (manager) {
        const rate =
          payload.isStacked === true
            ? batchedSupervisorRate
            : supervisorCommissionRate;
        const share = Math.round(deliveryFee * rate);
        if (share > 0) {
          managerPayouts.set(manager.id, share);
        }
      }
    }

    const totalManagerShare = Array.from(managerPayouts.values()).reduce(
      (sum, s) => sum + s,
      0,
    );
    platformRevenue -= totalManagerShare;

    return {
      commission,
      vendorRevenue,
      groups,
      primaryPayouts,
      assistPayouts,
      paidDriverIds,
      driverEarnings,
      totalAssistEarnings,
      platformRevenue,
      managerPayouts,
      isDriverCollected: paymentMethod === 'CASH_ON_DELIVERY',
      maxNegative: Number(
        (settings as { maxNegativeDriverBalance?: number })
          .maxNegativeDriverBalance ?? 500,
      ),
      settlementThreshold: Number(settings.driverSettlementOrderThreshold ?? 10),
      defaultTaxRate: Number(settings.defaultTaxRate ?? 0),
    };
  }

  private async executeSettlementTransaction(
    payload: SettleOrderPayload,
    plan: SettlementPlan,
    now: Date,
  ): Promise<{ applied: boolean; statusEffects: DriverStatusEffect[] }> {
    const { orderId, orderNumber, vendorId } = payload;
    const statusEffects: DriverStatusEffect[] = [];
    let applied = false;

    await this.prisma.$transaction(async (client) => {
      // Lock order first, then drivers (sorted), then vendors (sorted) to avoid deadlocks.
      await client.$executeRaw`SELECT id FROM orders WHERE id = ${orderId} FOR UPDATE`;

      const [lockedOrder, alreadySettled] = await Promise.all([
        client.order.findUnique({
          where: { id: orderId },
          select: { settledAt: true },
        }),
        client.driverWalletTransaction.findFirst({
          where: { orderId, type: 'DELIVERY_FEE' },
        }),
      ]);
      if (lockedOrder?.settledAt || alreadySettled) {
        this.logger.warn(
          `Order ${orderNumber} already settled — skipping duplicate settlement.`,
        );
        return;
      }
      applied = true;

      for (const paidDriverId of [...plan.paidDriverIds].sort()) {
        await client.$executeRaw`SELECT id FROM drivers WHERE id = ${paidDriverId} FOR UPDATE`;
      }

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

      if (plan.isDriverCollected) {
        await this.applyDriverStoreReimbursement(client, payload, plan);
        await this.applyDriverCashCollection(client, payload, plan);
      }

      await this.applyDriverDeliveryPayouts(client, payload, plan);
      await this.applyManagerPayouts(client, payload, plan.managerPayouts);

      if (payload.driverBonusFee > 0) {
        await this.creditDriverWallet(
          client,
          payload.driverId,
          payload.driverBonusFee,
          orderId,
          payload.driverShiftId,
          `Time-based bonus for order ${orderNumber}`,
          'BONUS',
          { skipLock: true },
        );
      }

      const effects = await this.updateDriverSettlementCounters(client, plan);
      statusEffects.push(...effects);

      await this.awardCustomerCoins(client, payload);
      await this.applyVendorPayables(client, payload, plan);

      await client.order.update({
        where: { id: orderId },
        data: { settledAt: now },
      });
    });

    return { applied, statusEffects };
  }

  private async applyDriverStoreReimbursement(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    plan: SettlementPlan,
  ): Promise<void> {
    const { orderId, orderNumber, driverId, driverShiftId, subtotal, isContracted } =
      payload;

    if (plan.groups.length > 0) {
      const items = await client.orderDeliveryGroupItem.findMany({
        where: { deliveryGroupId: { in: plan.groups.map((g) => g.id) } },
        select: {
          deliveryGroupId: true,
          fulfillment: {
            select: {
              subtotal: true,
              commissionRate: true,
              vendor: { select: { isContracted: true } },
              vendorBranch: { select: { isContracted: true } },
            },
          },
        },
      });
      const cashPaidByGroup = new Map<string, number>();
      for (const item of items) {
        const f = item.fulfillment;
        const branchOrVendorContracted =
          f.vendorBranch?.isContracted != null
            ? f.vendorBranch.isContracted
            : (f.vendor?.isContracted ?? false);
        const commRate = Number(f.commissionRate ?? 10) / 100;
        const itemComm = branchOrVendorContracted
          ? Math.round(f.subtotal * commRate)
          : 0;
        const paidToStore = Math.max(0, f.subtotal - itemComm);
        cashPaidByGroup.set(
          item.deliveryGroupId,
          (cashPaidByGroup.get(item.deliveryGroupId) ?? 0) + paidToStore,
        );
      }
      const storeReimbursementByDriver = new Map<
        string,
        { driverId: string; driverShiftId: string | null; amount: number }
      >();
      for (const g of plan.groups) {
        if (!g.primaryDriverId) continue;
        const paidAtStore = cashPaidByGroup.get(g.id) ?? 0;
        if (paidAtStore <= 0) continue;
        const existing = storeReimbursementByDriver.get(g.primaryDriverId);
        if (existing) {
          existing.amount += paidAtStore;
        } else {
          storeReimbursementByDriver.set(g.primaryDriverId, {
            driverId: g.primaryDriverId,
            driverShiftId: g.primaryDriverShiftId,
            amount: paidAtStore,
          });
        }
      }
      for (const reimbursement of storeReimbursementByDriver.values()) {
        await this.creditDriverWallet(
          client,
          reimbursement.driverId,
          reimbursement.amount,
          orderId,
          reimbursement.driverShiftId,
          `Store food reimbursement for order ${orderNumber}`,
          'CASH_HANDED_TO_VENDOR',
          { skipLock: true },
        );
      }
      return;
    }

    const vendorCashPaid = isContracted
      ? Math.max(0, subtotal - plan.commission)
      : subtotal;
    if (vendorCashPaid > 0 && driverId) {
      await this.creditDriverWallet(
        client,
        driverId,
        vendorCashPaid,
        orderId,
        driverShiftId,
        `Store food reimbursement for order ${orderNumber}`,
        'CASH_HANDED_TO_VENDOR',
        { skipLock: true },
      );
    }
  }

  private async applyDriverCashCollection(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    plan: SettlementPlan,
  ): Promise<void> {
    const {
      orderId,
      orderNumber,
      driverId,
      driverShiftId,
      grandTotal,
      subtotal,
      deliveryFee,
      serviceFee,
      tax,
      driverBonusFee,
      discount,
    } = payload;

    if (plan.groups.length > 0) {
      const collections = await this.splitCollectedCash(client, {
        groups: plan.groups,
        grandTotal,
        subtotal,
        deliveryFee,
        serviceFee,
        tax,
        driverBonusFee,
        discount,
      });
      for (const collected of collections) {
        if (collected.amount <= 0) continue;
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
      return;
    }

    if (driverId && grandTotal > 0) {
      await this.creditDriverWallet(
        client,
        driverId,
        -grandTotal,
        orderId,
        driverShiftId,
        `Collected payment (COD/Mobile Wallet) for order ${orderNumber}`,
        'CASH_COLLECTED',
        { skipLock: true },
      );
    }
  }

  private async applyDriverDeliveryPayouts(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    plan: SettlementPlan,
  ): Promise<void> {
    const combinedDriverPayouts = new Map<
      string,
      {
        driverId: string;
        driverShiftId: string | null;
        amount: number;
        isAssistOnly: boolean;
      }
    >();

    for (const payout of plan.primaryPayouts) {
      if (payout.amount <= 0) continue;
      const existing = combinedDriverPayouts.get(payout.driverId);
      if (existing) {
        existing.amount += payout.amount;
        existing.isAssistOnly = false;
      } else {
        combinedDriverPayouts.set(payout.driverId, {
          driverId: payout.driverId,
          driverShiftId: payout.driverShiftId,
          amount: payout.amount,
          isAssistOnly: false,
        });
      }
    }

    for (const payout of plan.assistPayouts) {
      if (payout.amount <= 0) continue;
      const existing = combinedDriverPayouts.get(payout.driverId);
      if (existing) {
        existing.amount += payout.amount;
      } else {
        combinedDriverPayouts.set(payout.driverId, {
          driverId: payout.driverId,
          driverShiftId: payout.driverShiftId,
          amount: payout.amount,
          isAssistOnly: true,
        });
      }
    }

    for (const payout of combinedDriverPayouts.values()) {
      await this.creditDriverWallet(
        client,
        payout.driverId,
        payout.amount,
        payload.orderId,
        payout.driverShiftId,
        payout.isAssistOnly
          ? `Assisting delivery fee for order ${payload.orderNumber}`
          : `Delivery fee for order ${payload.orderNumber}`,
        'DELIVERY_FEE',
        { skipLock: true },
      );
    }
  }

  private async applyManagerPayouts(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    managerPayouts: Map<string, number>,
  ): Promise<void> {
    for (const [mgrId, share] of managerPayouts.entries()) {
      if (share <= 0) continue;
      await client.$executeRaw`SELECT id FROM driver_managers WHERE id = ${mgrId} FOR UPDATE`;

      const alreadyManagerSettled =
        await client.driverManagerWalletTransaction.findFirst({
          where: {
            orderId: payload.orderId,
            type: 'DELIVERY_SHARE',
            managerId: mgrId,
          },
        });

      if (!alreadyManagerSettled) {
        const updatedManager = await client.driverManager.update({
          where: { id: mgrId },
          data: { walletBalance: { increment: share } },
          select: { walletBalance: true },
        });
        await client.driverManagerWalletTransaction.create({
          data: {
            managerId: mgrId,
            orderId: payload.orderId,
            type: 'DELIVERY_SHARE',
            amount: share,
            balanceAfter: updatedManager.walletBalance,
            description: `Delivery manager share for order ${payload.orderNumber}`,
            idempotencyKey: `${payload.orderId}:DELIVERY_SHARE:${mgrId}`,
          },
        });
      }
    }
  }

  private async updateDriverSettlementCounters(
    client: Prisma.TransactionClient,
    plan: SettlementPlan,
  ): Promise<DriverStatusEffect[]> {
    const statusEffects: DriverStatusEffect[] = [];

    for (const paidDriverId of plan.paidDriverIds) {
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
      const shouldLock = currentBalance < -plan.maxNegative;

      const nextSettlementCount =
        (driverSnapshot?.ordersSinceSettlement ?? 0) + 1;
      const settlementDue =
        !shouldLock &&
        plan.settlementThreshold > 0 &&
        nextSettlementCount >= plan.settlementThreshold &&
        currentBalance < 0;

      const driver = await client.driver.update({
        where: { id: paidDriverId },
        data: {
          totalOrders: { increment: 1 },
          ordersSinceSettlement: { increment: 1 },
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

    return statusEffects;
  }

  private async awardCustomerCoins(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
  ): Promise<void> {
    if (payload.coinsEarned <= 0) return;

    await client.$executeRaw`SELECT id FROM customers WHERE id = ${payload.customerId} FOR UPDATE`;
    const existing = await client.customerCoinTransaction.findFirst({
      where: { orderId: payload.orderId, type: 'EARNED' },
    });
    if (existing) return;

    const customer = await client.customer.update({
      where: { id: payload.customerId },
      data: { coinBalance: { increment: payload.coinsEarned } },
      select: { coinBalance: true },
    });

    try {
      await client.customerCoinTransaction.create({
        data: {
          customerId: payload.customerId,
          orderId: payload.orderId,
          type: 'EARNED',
          amount: payload.coinsEarned,
          balanceAfter: customer.coinBalance,
          description: `Earned coins from order ${payload.orderNumber}`,
        },
      });
    } catch (e: unknown) {
      const code =
        typeof e === 'object' && e !== null && 'code' in e
          ? (e as { code?: string }).code
          : undefined;
      if (code !== 'P2002') throw e;
    }
  }

  private async applyVendorPayables(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    plan: SettlementPlan,
  ): Promise<void> {
    const { orderId, orderNumber, vendorId, isContracted } = payload;

    const portions = await client.orderVendorFulfillment.findMany({
      where: { orderId, status: { notIn: ['PENDING', 'REJECTED', 'CANCELLED'] } },
      select: {
        vendorId: true,
        subtotal: true,
        commissionRate: true,
        vendor: { select: { isContracted: true } },
        vendorBranch: { select: { name: true, isContracted: true } },
      },
    });

    const payables: Array<{
      vendorId: string;
      revenue: number;
      commission: number;
      description: string;
      commissionDescription: string;
    }> =
      portions.length > 0
        ? (() => {
            const byVendor = new Map<
              string,
              {
                vendorId: string;
                revenue: number;
                commission: number;
                branchNames: string[];
              }
            >();
            for (const p of portions) {
              const portionContracted =
                p.vendorBranch?.isContracted != null
                  ? p.vendorBranch.isContracted
                  : (p.vendor?.isContracted ?? false);
              if (!portionContracted) continue;
              const rate = Number(p.commissionRate ?? 0);
              const portionComm = Math.round(p.subtotal * (rate / 100));
              const existing = byVendor.get(p.vendorId);
              if (existing) {
                existing.revenue += p.subtotal;
                existing.commission += portionComm;
                if (
                  p.vendorBranch?.name &&
                  !existing.branchNames.includes(p.vendorBranch.name)
                ) {
                  existing.branchNames.push(p.vendorBranch.name);
                }
              } else {
                byVendor.set(p.vendorId, {
                  vendorId: p.vendorId,
                  revenue: p.subtotal,
                  commission: portionComm,
                  branchNames: p.vendorBranch?.name
                    ? [p.vendorBranch.name]
                    : [],
                });
              }
            }
            return Array.from(byVendor.values()).map((entry) => {
              const bName =
                entry.branchNames.length > 0
                  ? ` (${entry.branchNames.join(', ')})`
                  : '';
              return {
                vendorId: entry.vendorId,
                revenue: entry.revenue,
                commission: entry.commission,
                description: `Order ${orderNumber}${bName} revenue`,
                commissionDescription: `Commission for order ${orderNumber}${bName}`,
              };
            });
          })()
        : vendorId && isContracted
          ? await (async () => {
              const orderRow = await client.order.findUnique({
                where: { id: orderId },
                select: { vendorBranch: { select: { name: true } } },
              });
              const bName = orderRow?.vendorBranch?.name
                ? ` (${orderRow.vendorBranch.name})`
                : '';
              return [
                {
                  vendorId,
                  revenue: plan.vendorRevenue,
                  commission: plan.commission,
                  description: `Order ${orderNumber}${bName} revenue`,
                  commissionDescription: `Commission for order ${orderNumber}${bName}`,
                },
              ];
            })()
          : [];

    for (const payable of payables) {
      await this.applyVendorWalletEntry(client, {
        vendorId: payable.vendorId,
        signedAmount: payable.revenue,
        type: VendorTransactionType.ORDER_REVENUE,
        orderId,
        description: payable.description,
        skipLock: true,
      });

      await this.applyVendorWalletEntry(client, {
        vendorId: payable.vendorId,
        signedAmount: -payable.commission,
        type: VendorTransactionType.COMMISSION_DEDUCTION,
        orderId,
        description: payable.commissionDescription,
        skipLock: true,
      });
    }
  }

  private async applyVendorWalletEntry(
    client: Prisma.TransactionClient,
    params: {
      vendorId: string;
      signedAmount: number;
      type: VendorTransactionType;
      orderId: string | null;
      description: string;
      skipLock?: boolean;
    },
  ): Promise<number> {
    if (!params.skipLock) {
      await client.$executeRaw`SELECT id FROM vendors WHERE id = ${params.vendorId} FOR UPDATE`;
    }

    if (params.orderId) {
      const existing = await client.vendorWalletTransaction.findFirst({
        where: {
          orderId: params.orderId,
          type: params.type,
          vendorId: params.vendorId,
        },
      });
      if (existing) return existing.balanceAfter;
    }

    const vendor = await client.vendor.update({
      where: { id: params.vendorId },
      data: { walletBalance: { increment: params.signedAmount } },
      select: { walletBalance: true },
    });

    await client.vendorWalletTransaction.create({
      data: {
        vendorId: params.vendorId,
        orderId: params.orderId,
        type: params.type,
        amount: params.signedAmount,
        balanceAfter: vendor.walletBalance,
        description: params.description,
      },
    });

    return vendor.walletBalance;
  }

  private async enqueueSettlementStats(
    payload: SettleOrderPayload,
    plan: SettlementPlan,
    periods: StatPeriodRange[],
  ): Promise<void> {
    const { orderId, orderNumber, vendorId, deliveryFee, tax, isContracted } =
      payload;

    const driverEarningsByDriver = new Map<string, number>();
    for (const payout of [...plan.primaryPayouts, ...plan.assistPayouts]) {
      driverEarningsByDriver.set(
        payout.driverId,
        (driverEarningsByDriver.get(payout.driverId) ?? 0) + payout.amount,
      );
    }

    const statsJobs: Array<Promise<void>> = [
      ...Array.from(driverEarningsByDriver.entries()).map(([dId, amount]) =>
        enqueueStatsJob(this.statsQueue, {
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
      enqueueStatsJob(this.statsQueue, {
        name: STATS_JOBS.UPDATE_APP,
        sourceKey: `settle:${orderId}:${STATS_JOBS.UPDATE_APP}`,
        data: {
          increment: {
            totalOrders: 1,
            totalAdminRevenue: plan.platformRevenue,
            totalDeliveryFees: deliveryFee,
          },
        },
        periods,
      }),
    ];

    if (vendorId) {
      statsJobs.push(
        enqueueStatsJob(this.statsQueue, {
          name: STATS_JOBS.UPDATE_VENDOR,
          sourceKey: `settle:${orderId}:${STATS_JOBS.UPDATE_VENDOR}`,
          data: {
            vendorId,
            increment: {
              totalOrders: 1,
              totalRevenue: plan.vendorRevenue,
              totalCommission: isContracted ? plan.commission : 0,
              totalTax: tax,
              completedOrders: 1,
            },
          },
          periods,
        }),
      );
    } else {
      const portions = await this.prisma.orderVendorFulfillment.findMany({
        where: { orderId, status: { notIn: ['PENDING', 'REJECTED', 'CANCELLED'] } },
        select: {
          vendorId: true,
          subtotal: true,
          commissionRate: true,
          vendor: { select: { isContracted: true } },
          vendorBranch: { select: { isContracted: true } },
        },
      });
      const vendorStatsByVendor = new Map<
        string,
        { totalRevenue: number; totalCommission: number }
      >();
      for (const portion of portions) {
        const portionContracted =
          portion.vendorBranch?.isContracted != null
            ? portion.vendorBranch.isContracted
            : (portion.vendor?.isContracted ?? false);
        const portionComm = portionContracted
          ? Math.round(portion.subtotal * (Number(portion.commissionRate) / 100))
          : 0;
        const existing = vendorStatsByVendor.get(portion.vendorId);
        if (existing) {
          existing.totalRevenue += portion.subtotal;
          existing.totalCommission += portionComm;
        } else {
          vendorStatsByVendor.set(portion.vendorId, {
            totalRevenue: portion.subtotal,
            totalCommission: portionComm,
          });
        }
      }
      for (const [vId, agg] of vendorStatsByVendor.entries()) {
        statsJobs.push(
          enqueueStatsJob(this.statsQueue, {
            name: STATS_JOBS.UPDATE_VENDOR,
            sourceKey: `settle:${orderId}:vendor:${vId}`,
            data: {
              vendorId: vId,
              increment: {
                totalOrders: 1,
                totalRevenue: agg.totalRevenue,
                totalCommission: agg.totalCommission,
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

  private emitPostCommitEffects(
    payload: SettleOrderPayload,
    plan: SettlementPlan,
    statusEffects: DriverStatusEffect[],
  ): void {
    const {
      orderId,
      orderNumber,
      vendorId,
      driverId,
      driverShiftId,
      grandTotal,
      deliveryFee,
      commissionRate,
      customerUserId,
    } = payload;

    for (const effect of statusEffects) {
      if (effect.kind === 'LOCKED') {
        this.logger.warn(
          `Driver ${effect.driver.id} locked out due to unpaid commission on driver-collected order ${orderNumber}.`,
        );

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
        plan.defaultTaxRate,
        customerUserId ?? null,
      ),
    );

    this.logger.log(
      `Order ${orderNumber} settled — ` +
        `vendor: +${plan.vendorRevenue} -${plan.commission} commission, ` +
        `drivers: +${plan.driverEarnings} across ${plan.primaryPayouts.length} deliver(s)` +
        (plan.totalAssistEarnings > 0
          ? ` (+${plan.totalAssistEarnings} assisting)`
          : '') +
        `, platform: +${plan.platformRevenue}`,
    );
  }

  /**
   * Split the cash a multi-vendor order's drivers collect at the door.
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
      grandTotal: number;
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
          },
        },
      },
    });

    const goodsByGroup = new Map<string, number>();
    for (const item of items) {
      goodsByGroup.set(
        item.deliveryGroupId,
        (goodsByGroup.get(item.deliveryGroupId) ?? 0) +
          item.fulfillment.subtotal,
      );
    }

    const extras =
      params.serviceFee + params.tax + params.driverBonusFee - params.discount;
    const totalGross =
      params.grandTotal > 0
        ? params.grandTotal
        : Math.max(0, params.subtotal + params.deliveryFee + extras);

    const base = params.groups.map(
      (g) => (goodsByGroup.get(g.id) ?? 0) + g.deliveryFee,
    );
    const baseTotal = base.reduce((s, b) => s + b, 0);

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

      if (gross === 0) return;

      const existing = byDriver.get(g.primaryDriverId);
      if (existing) {
        existing.amount += gross;
      } else {
        byDriver.set(g.primaryDriverId, {
          driverId: g.primaryDriverId,
          driverShiftId: g.primaryDriverShiftId,
          amount: gross,
        });
      }
    });

    return [...byDriver.values()];
  }

  private async resolveDriverManager(
    driverId: string,
    zoneId?: string | null,
  ): Promise<{ id: string } | null> {
    const assignment = await this.prisma.driverManagerAssignment.findUnique({
      where: { driverId },
      select: { driverManagerId: true },
    });
    if (assignment) {
      const manager = await this.prisma.driverManager.findUnique({
        where: { id: assignment.driverManagerId },
        select: { id: true },
      });
      if (manager) return manager;
    }
    if (zoneId) {
      const zoneManager = await this.prisma.driverManager.findFirst({
        where: { zoneId },
        select: { id: true },
      });
      if (zoneManager) return zoneManager;
    }
    return this.prisma.driverManager.findFirst({
      where: { manageAllDrivers: true },
      select: { id: true },
    });
  }

  private async creditDriverWallet(
    client: Prisma.TransactionClient,
    driverId: string,
    amount: number,
    orderId: string,
    driverShiftId: string | null,
    description: string,
    type: DriverWalletTxType = 'DELIVERY_FEE',
    options: { skipLock?: boolean } = {},
  ): Promise<void> {
    if (!options.skipLock) {
      await client.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;
    }

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
