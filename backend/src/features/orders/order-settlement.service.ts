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
import {
  allocateDriverBonus,
  allocateOrderCashCollection,
  computeIsMultiVendorOrder,
} from '../../common/orders/order-financials.helper';
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
  branchName?: string | null;
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
  deliveryGroupId?: string | null;
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
  isPaymentCollector?: boolean | null;
}

interface ManagerPayout {
  managerId: string;
  amount: number;
  deliveryGroupId: string | null;
}

interface SettlementPortionRow {
  id: string;
  vendorId: string;
  subtotal: number;
  commissionRate: unknown;
  isContracted: boolean | null;
  vendor?: { isContracted: boolean | null } | null;
  vendorBranch?: { isContracted: boolean | null } | null;
}

interface SettlementGroupItemRow {
  deliveryGroupId: string;
  fulfillment: {
    status: string;
    subtotal: number;
    commissionRate: unknown;
    isContracted: boolean | null;
    vendor?: { isContracted: boolean | null } | null;
    vendorBranch?: { isContracted: boolean | null } | null;
  } | null;
}

interface SettlementPlan {
  commission: number;
  vendorRevenue: number;
  portions: SettlementPortionRow[];
  groups: DeliveredGroupRow[];
  primaryPayouts: DriverPayout[];
  assistPayouts: DriverPayout[];
  paidDriverIds: string[];
  driverEarnings: number;
  totalAssistEarnings: number;
  platformRevenue: number;
  managerPayouts: ManagerPayout[];
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
 * - Asynchronous stat queue fan-out and post-commit domain events (ORDER_SETTLED, DRIVER_STATUS_CHANGED).
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

    const portions = await this.prisma.orderVendorFulfillment.findMany({
      where: {
        orderId,
        status: { notIn: ['PENDING', 'REJECTED', 'CANCELLED'] },
      },
      select: {
        id: true,
        vendorId: true,
        subtotal: true,
        commissionRate: true,
        isContracted: true,
        vendor: { select: { isContracted: true } },
        vendorBranch: { select: { isContracted: true } },
      },
    });

    const commission =
      portions.length > 0
        ? portions.reduce((sum, p: any) => {
            const contracted =
              p.isContracted ??
              p.vendorBranch?.isContracted ??
              p.vendor?.isContracted ??
              false;
            if (!contracted) return sum;
            return (
              sum + Math.round(p.subtotal * (Number(p.commissionRate ?? 0) / 100))
            );
          }, 0)
        : Math.round(subtotal * (commissionRate / 100));
    const vendorRevenue =
      portions.length > 0
        ? portions.reduce((sum, p) => sum + Number(p.subtotal ?? 0), 0)
        : subtotal;
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
        isPaymentCollector: true,
      },
      orderBy: { sequence: 'asc' },
    })) as DeliveredGroupRow[];

    const primaryPayouts: DriverPayout[] = [];
    const assistPayouts: DriverPayout[] = [];
    const isMultiVendorOrder = computeIsMultiVendorOrder({
      activeGroupsCount: groups.length,
      activeFulfillmentsCount: portions.length,
    });

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
          : isMultiVendorOrder
            ? multiVendorDriverShare
            : driverShare;
        const amount = Math.max(0, Math.round(primaryFee * groupShare));

        primaryPayouts.push({
          driverId: primaryId,
          driverShiftId: g.primaryDriverShiftId ?? null,
          deliveryGroupId: g.id,
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
              deliveryGroupId: g.id,
              amount: assistAmount,
            });
          }
        }
      }
    } else if (driverId) {
      const primaryFee = primaryFeeFor(deliveryFee, distanceKm, driverTier);
      const orderShare =
        payload.isStacked === true ? stackedDriverShare : driverShare;
      primaryPayouts.push({
        driverId,
        driverShiftId,
        deliveryGroupId: null,
        amount: Math.round(primaryFee * orderShare),
      });
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

    const platformFee =
      portions.length > 0
        ? commission + Number(serviceFee ?? 0)
        : isContracted
          ? commission
          : (serviceFee ?? commission);
    const applicationDeliveryCut = deliveryFee - driverEarnings;
    let platformRevenue = platformFee + applicationDeliveryCut;

    if (!settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      platformRevenue -= driverBonusFee;
    }

    // Total assist payouts come out of platform delivery cut regardless of whether customer paid assistFee in deliveryFee.
    platformRevenue -= totalAssistEarnings;

    const managerPayoutBuckets = new Map<
      string,
      { amount: number; groupIds: Set<string> }
    >();
    if (groups.length > 0) {
      const uniquePrimaryIds = Array.from(
        new Set(
          groups
            .map((g) => g.primaryDriverId)
            .filter((id): id is string => !!id),
        ),
      );
      const resolvedManagers = await Promise.all(
        uniquePrimaryIds.map(
          async (id) => [id, await this.resolveDriverManager(id, zoneId)] as const,
        ),
      );
      const managerByDriverId = new Map(resolvedManagers);

      for (const g of groups) {
        if (!g.primaryDriverId) continue;
        const gManager = managerByDriverId.get(g.primaryDriverId);
        if (gManager) {
          const rate =
            g.isStacked === true
              ? batchedSupervisorRate
              : isMultiVendorOrder
                ? multiVendorSupervisorRate
                : supervisorCommissionRate;
          const share = Math.round(g.deliveryFee * rate);
          if (share > 0) {
            const existing = managerPayoutBuckets.get(gManager.id);
            if (existing) {
              existing.amount += share;
              existing.groupIds.add(g.id);
            } else {
              managerPayoutBuckets.set(gManager.id, {
                amount: share,
                groupIds: new Set([g.id]),
              });
            }
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
          managerPayoutBuckets.set(manager.id, {
            amount: share,
            groupIds: new Set(),
          });
        }
      }
    }

    const managerPayouts: ManagerPayout[] = Array.from(
      managerPayoutBuckets.entries(),
    ).map(([managerId, bucket]) => ({
      managerId,
      amount: bucket.amount,
      deliveryGroupId:
        bucket.groupIds.size === 1 ? Array.from(bucket.groupIds)[0] : null,
    }));

    const totalManagerShare = managerPayouts.reduce(
      (sum, m) => sum + m.amount,
      0,
    );
    platformRevenue -= totalManagerShare;

    return {
      commission,
      vendorRevenue,
      portions,
      groups,
      primaryPayouts,
      assistPayouts,
      paidDriverIds,
      driverEarnings,
      totalAssistEarnings,
      platformRevenue,
      managerPayouts,
      isDriverCollected:
        paymentMethod === 'CASH_ON_DELIVERY' ||
        paymentMethod === 'MOBILE_WALLET',
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
          where: {
            orderId,
            type: 'DELIVERY_FEE',
            OR: [
              { idempotencyKey: null },
              { idempotencyKey: { startsWith: 'settle:' } },
            ],
          },
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
        const prefetchedGroupItems =
          plan.groups.length > 0
            ? await this.fetchGroupSettlementItems(
                client,
                plan.groups.map((g) => g.id),
              )
            : undefined;
        await this.applyDriverStoreReimbursement(
          client,
          payload,
          plan,
          prefetchedGroupItems,
        );
        await this.applyDriverCashCollection(
          client,
          payload,
          plan,
          prefetchedGroupItems,
        );
      }

      await this.applyDriverDeliveryPayouts(client, payload, plan);
      await this.applyManagerPayouts(client, payload, plan.managerPayouts);

      if (payload.driverBonusFee > 0) {
        const bonusAllocations = allocateDriverBonus({
          driverBonusFee: payload.driverBonusFee,
          groups: plan.groups,
          fallbackDriverId: payload.driverId,
          fallbackDriverShiftId: payload.driverShiftId,
        });
        for (const bonus of bonusAllocations) {
          await this.creditDriverWallet(
            client,
            bonus.driverId,
            bonus.amount,
            orderId,
            bonus.driverShiftId,
            `Time-based bonus for order ${orderNumber}`,
            'BONUS',
            { skipLock: true, deliveryGroupId: bonus.deliveryGroupId },
          );
        }
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

  private async fetchGroupSettlementItems(
    client: Prisma.TransactionClient,
    deliveryGroupIds: string[],
  ): Promise<SettlementGroupItemRow[]> {
    return client.orderDeliveryGroupItem.findMany({
      where: { deliveryGroupId: { in: deliveryGroupIds } },
      select: {
        deliveryGroupId: true,
        fulfillment: {
          select: {
            status: true,
            subtotal: true,
            commissionRate: true,
            isContracted: true,
            vendor: { select: { isContracted: true } },
            vendorBranch: { select: { isContracted: true } },
          },
        },
      },
    });
  }

  private async applyDriverStoreReimbursement(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    plan: SettlementPlan,
    prefetchedItems?: SettlementGroupItemRow[],
  ): Promise<void> {
    const { orderId, orderNumber, driverId, driverShiftId, subtotal, isContracted } =
      payload;

    if (plan.groups.length > 0) {
      const items =
        prefetchedItems ??
        (await this.fetchGroupSettlementItems(
          client,
          plan.groups.map((g) => g.id),
        ));
      const cashPaidByGroup = new Map<string, number>();
      for (const item of items) {
        const f: any = item.fulfillment;
        if (!f || f.status === 'REJECTED' || f.status === 'CANCELLED') {
          continue;
        }
        const branchOrVendorContracted =
          f.isContracted ??
          (f.vendorBranch?.isContracted != null
            ? f.vendorBranch.isContracted
            : (f.vendor?.isContracted ?? false));
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
        {
          driverId: string;
          driverShiftId: string | null;
          amount: number;
          groupIds: Set<string>;
        }
      >();
      for (const g of plan.groups) {
        if (!g.primaryDriverId) continue;
        const paidAtStore = cashPaidByGroup.get(g.id) ?? 0;
        if (paidAtStore <= 0) continue;
        const existing = storeReimbursementByDriver.get(g.primaryDriverId);
        if (existing) {
          existing.amount += paidAtStore;
          existing.groupIds.add(g.id);
        } else {
          storeReimbursementByDriver.set(g.primaryDriverId, {
            driverId: g.primaryDriverId,
            driverShiftId: g.primaryDriverShiftId,
            amount: paidAtStore,
            groupIds: new Set([g.id]),
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
          {
            skipLock: true,
            deliveryGroupId:
              reimbursement.groupIds.size === 1
                ? Array.from(reimbursement.groupIds)[0]
                : null,
          },
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
    prefetchedItems?: SettlementGroupItemRow[],
  ): Promise<void> {
    const {
      orderId,
      orderNumber,
      driverId,
      driverShiftId,
      grandTotal,
      upfrontAmount,
      subtotal,
      deliveryFee,
      serviceFee,
      tax,
      driverBonusFee,
      discount,
      paymentMethod,
    } = payload;

    if (plan.groups.length > 0) {
      const collections = await this.splitCollectedCash(
        client,
        {
          groups: plan.groups,
          grandTotal,
          upfrontAmount,
          subtotal,
          deliveryFee,
          serviceFee,
          tax,
          driverBonusFee,
          discount,
          paymentMethod,
        },
        prefetchedItems,
      );
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
          {
            skipLock: true,
            deliveryGroupId: collected.deliveryGroupId ?? null,
          },
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
        groupIds: Set<string>;
      }
    >();

    for (const payout of plan.primaryPayouts) {
      if (payout.amount <= 0) continue;
      const existing = combinedDriverPayouts.get(payout.driverId);
      if (existing) {
        existing.amount += payout.amount;
        existing.isAssistOnly = false;
        if (payout.deliveryGroupId) existing.groupIds.add(payout.deliveryGroupId);
      } else {
        combinedDriverPayouts.set(payout.driverId, {
          driverId: payout.driverId,
          driverShiftId: payout.driverShiftId,
          amount: payout.amount,
          isAssistOnly: false,
          groupIds: new Set(
            payout.deliveryGroupId ? [payout.deliveryGroupId] : [],
          ),
        });
      }
    }

    for (const payout of plan.assistPayouts) {
      if (payout.amount <= 0) continue;
      const existing = combinedDriverPayouts.get(payout.driverId);
      if (existing) {
        existing.amount += payout.amount;
        if (payout.deliveryGroupId) existing.groupIds.add(payout.deliveryGroupId);
      } else {
        combinedDriverPayouts.set(payout.driverId, {
          driverId: payout.driverId,
          driverShiftId: payout.driverShiftId,
          amount: payout.amount,
          isAssistOnly: true,
          groupIds: new Set(
            payout.deliveryGroupId ? [payout.deliveryGroupId] : [],
          ),
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
        {
          skipLock: true,
          deliveryGroupId:
            payout.groupIds.size === 1 ? Array.from(payout.groupIds)[0] : null,
        },
      );
    }
  }

  private async applyManagerPayouts(
    client: Prisma.TransactionClient,
    payload: SettleOrderPayload,
    managerPayouts: ManagerPayout[],
  ): Promise<void> {
    const sortedPayouts = [...managerPayouts].sort((a, b) =>
      a.managerId.localeCompare(b.managerId),
    );
    for (const mp of sortedPayouts) {
      const { managerId: mgrId, amount: share, deliveryGroupId } = mp;
      if (share <= 0) continue;
      await client.$executeRaw`SELECT id FROM driver_managers WHERE id = ${mgrId} FOR UPDATE`;

      const alreadyManagerSettled =
        await client.driverManagerWalletTransaction.findFirst({
          where: {
            orderId: payload.orderId,
            type: 'DELIVERY_SHARE',
            managerId: mgrId,
            OR: [
              { idempotencyKey: null },
              { idempotencyKey: { startsWith: 'settle:' } },
            ],
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
            deliveryGroupId: deliveryGroupId ?? null,
            type: 'DELIVERY_SHARE',
            amount: share,
            balanceAfter: updatedManager.walletBalance,
            description: `Delivery manager share for order ${payload.orderNumber}`,
            idempotencyKey: `settle:${payload.orderId}:DELIVERY_SHARE:${mgrId}`,
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
    const { orderId, orderNumber, vendorId, branchName, isContracted } = payload;

    const portions = await client.orderVendorFulfillment.findMany({
      where: { orderId, status: { notIn: ['PENDING', 'REJECTED', 'CANCELLED'] } },
      select: {
        id: true,
        vendorId: true,
        subtotal: true,
        commissionRate: true,
        isContracted: true,
        vendor: { select: { isContracted: true } },
        vendorBranch: { select: { name: true, isContracted: true } },
      },
    });

    const payables: Array<{
      vendorId: string;
      fulfillmentId: string | null;
      revenue: number;
      commission: number;
      description: string;
      commissionDescription: string;
    }> =
      portions.length > 0
        ? portions
            .filter((p: any) => {
              const contracted =
                p.isContracted ??
                (p.vendorBranch?.isContracted != null
                  ? p.vendorBranch.isContracted
                  : (p.vendor?.isContracted ?? false));
              return contracted;
            })
            .map((p: any) => {
              const rate = Number(p.commissionRate ?? 0);
              const portionComm = Math.round(p.subtotal * (rate / 100));
              const bName = p.vendorBranch?.name ? ` (${p.vendorBranch.name})` : '';
              return {
                vendorId: p.vendorId,
                fulfillmentId: p.id ?? null,
                revenue: p.subtotal,
                commission: portionComm,
                description: `Order ${orderNumber}${bName} revenue`,
                commissionDescription: `Commission for order ${orderNumber}${bName}`,
              };
            })
        : vendorId && isContracted
          ? [
              {
                vendorId,
                fulfillmentId: null,
                revenue: plan.vendorRevenue,
                commission: plan.commission,
                description: `Order ${orderNumber}${branchName ? ` (${branchName})` : ''} revenue`,
                commissionDescription: `Commission for order ${orderNumber}${branchName ? ` (${branchName})` : ''}`,
              },
            ]
          : [];

    for (const payable of payables) {
      await this.applyVendorWalletEntry(client, {
        vendorId: payable.vendorId,
        fulfillmentId: payable.fulfillmentId,
        signedAmount: payable.revenue,
        type: VendorTransactionType.ORDER_REVENUE,
        orderId,
        description: payable.description,
        skipLock: true,
      });

      await this.applyVendorWalletEntry(client, {
        vendorId: payable.vendorId,
        fulfillmentId: payable.fulfillmentId,
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
      fulfillmentId?: string | null;
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

    const idempotencyKey = params.orderId
      ? `settle:${params.orderId}:${params.type}:${params.vendorId}:${params.fulfillmentId ?? 'order'}`
      : undefined;

    if (params.orderId) {
      const existing = await client.vendorWalletTransaction.findFirst({
        where: {
          orderId: params.orderId,
          type: params.type,
          vendorId: params.vendorId,
          fulfillmentId: params.fulfillmentId ?? null,
          OR: [
            { idempotencyKey: null },
            { idempotencyKey: { startsWith: 'settle:' } },
          ],
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
        fulfillmentId: params.fulfillmentId ?? null,
        type: params.type,
        amount: params.signedAmount,
        balanceAfter: vendor.walletBalance,
        description: params.description,
        ...(idempotencyKey ? { idempotencyKey } : {}),
      },
    });

    return vendor.walletBalance;
  }

  private async enqueueSettlementStats(
    payload: SettleOrderPayload,
    plan: SettlementPlan,
    periods: StatPeriodRange[],
  ): Promise<void> {
    const { orderId, orderNumber, vendorId, deliveryFee, tax } = payload;

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
              totalCommission: plan.commission,
              totalTax: tax,
              completedOrders: 1,
            },
          },
          periods,
        }),
      );
    } else {
      const portions = plan.portions;
      const vendorStatsByVendor = new Map<
        string,
        { totalRevenue: number; totalCommission: number }
      >();
      for (const portion of portions) {
        const portionContracted =
          (portion as any).isContracted ??
          (portion.vendorBranch?.isContracted != null
            ? portion.vendorBranch.isContracted
            : (portion.vendor?.isContracted ?? false));
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
   * Attribute cash/mobile-wallet collections across delivered delivery groups.
   * For MOBILE_WALLET, 100% of grandTotal is received by the collector driver.
   * For COD, non-collector groups collect their own goods + deliveryFee and the
   * collector group absorbs order-level extras (serviceFee/tax/bonus/discount) + upfront deposit.
   */
  private async splitCollectedCash(
    client: Prisma.TransactionClient,
    params: {
      groups: DeliveredGroupRow[];
      grandTotal: number;
      upfrontAmount: number;
      subtotal: number;
      deliveryFee: number;
      serviceFee: number;
      tax: number;
      driverBonusFee: number;
      discount: number;
      paymentMethod: string;
    },
    prefetchedItems?: SettlementGroupItemRow[],
  ): Promise<
    Array<{
      driverId: string;
      driverShiftId: string | null;
      deliveryGroupId: string | null;
      amount: number;
    }>
  > {
    const items =
      prefetchedItems ??
      (await client.orderDeliveryGroupItem.findMany({
        where: { deliveryGroupId: { in: params.groups.map((g) => g.id) } },
        select: {
          deliveryGroupId: true,
          fulfillment: {
            select: {
              status: true,
              subtotal: true,
            },
          },
        },
      }));

    const goodsByGroup = new Map<string, number>();
    for (const item of items) {
      const f: any = item.fulfillment;
      if (!f || f.status === 'REJECTED' || f.status === 'CANCELLED') {
        continue;
      }
      goodsByGroup.set(
        item.deliveryGroupId,
        (goodsByGroup.get(item.deliveryGroupId) ?? 0) + f.subtotal,
      );
    }

    const { allocations } = allocateOrderCashCollection({
      groups: params.groups,
      goodsByGroup,
      grandTotal: params.grandTotal,
      upfrontAmount: params.upfrontAmount,
      paymentMethod: params.paymentMethod,
    });

    const byDriver = new Map<
      string,
      {
        driverId: string;
        driverShiftId: string | null;
        groupIds: Set<string>;
        amount: number;
      }
    >();
    for (const g of params.groups) {
      if (!g.primaryDriverId) continue;
      const gross = allocations.get(g.id)?.totalCollectedByDriver ?? 0;
      if (gross === 0) continue;

      const existing = byDriver.get(g.primaryDriverId);
      if (existing) {
        existing.amount += gross;
        existing.groupIds.add(g.id);
      } else {
        byDriver.set(g.primaryDriverId, {
          driverId: g.primaryDriverId,
          driverShiftId: g.primaryDriverShiftId,
          groupIds: new Set([g.id]),
          amount: gross,
        });
      }
    }

    return [...byDriver.values()].map((entry) => ({
      driverId: entry.driverId,
      driverShiftId: entry.driverShiftId,
      deliveryGroupId:
        entry.groupIds.size === 1 ? Array.from(entry.groupIds)[0] : null,
      amount: entry.amount,
    }));
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
    options: { skipLock?: boolean; deliveryGroupId?: string | null } = {},
  ): Promise<void> {
    if (!options.skipLock) {
      await client.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;
    }

    const idempotencyKey = `settle:${orderId}:${type}:${driverId}`;
    const existing = await client.driverWalletTransaction.findFirst({
      where: {
        orderId,
        type,
        driverId,
        OR: [
          { idempotencyKey: null },
          { idempotencyKey: { startsWith: 'settle:' } },
        ],
      },
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
        deliveryGroupId: options.deliveryGroupId ?? null,
        driverShiftId,
        type,
        amount,
        balanceAfter: driver.walletBalance,
        description,
        idempotencyKey,
      },
    });
  }
}
