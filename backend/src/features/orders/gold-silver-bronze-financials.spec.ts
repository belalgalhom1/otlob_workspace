import { BadRequestException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DriverShiftStatus,
  DriverStatus,
  DriverTier,
  OrderStatus,
  OrderType,
} from '@prisma/client';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  requiresActiveShiftForOrderType,
  toMoneyCents,
  centsToWholeEgp,
  multiplyMoneyRatioToWholeEgp,
} from '../../common/orders/money.helper';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { STATS_JOBS } from '../../infrastructure/queue/queues.constants';
import { DeliveryFeeCalculator } from '../platform-settings/delivery-fee.calculator';
import { UpdatePlatformSettingsDto } from '../platform-settings/dto/platform-settings.dto';
import { DispatchService } from '../dispatch/dispatch.service';
import { DriverAssistMatchingService } from '../drivers/driver-assist-matching.service';
import { DriversService } from '../drivers/drivers.service';
import { DriverErrors } from '../../common/constants/response.constants';
import { OrderRejectionRecomputor } from './helpers/order-rejection-recomputor';
import {
  OrderSettlementService,
  SettleOrderPayload,
} from './order-settlement.service';
import { OrderRoleProjector } from './projections/order-role.projector';

function makeBaseSettings(overrides: Record<string, any> = {}) {
  return {
    id: 'default',
    currency: 'EGP',
    defaultCommissionRate: 10,
    deliveryCommissionRate: 20,
    driverManagerCommissionRate: 10,
    multiVendorDeliveryCommissionRate: 20,
    multiVendorDriverManagerCommissionRate: 10,
    multiVendorDriverPercentage: 70,
    batchedDeliveryCommissionRate: 40,
    batchedDriverManagerCommissionRate: 10,
    stackedOrderDriverPercentage: 50,
    multiVendorDeliveryDiscountPercent: 20,
    defaultTaxRate: 14,
    baseDeliveryFee: 15,
    pricePerKm: 5,
    minOrderKm: 0,
    minDistanceFixedPrice: 15,
    maxDeliveryFee: 0,
    minDeliveryFee: 15,
    minDeliveryFeeBicycle: 15,
    maxDeliveryFeeBicycle: 0,
    minDeliveryFeeMotorcycle: 15,
    maxDeliveryFeeMotorcycle: 0,
    minDeliveryFeeCar: 15,
    maxDeliveryFeeCar: 0,
    minDeliveryFeeMinibus: 15,
    maxDeliveryFeeMinibus: 0,
    minDeliveryFeeTukTuk: 15,
    maxDeliveryFeeTukTuk: 0,
    minDeliveryFeeMotorTricycle: 15,
    maxDeliveryFeeMotorTricycle: 0,
    minDeliveryFeeQuarterTruck: 15,
    maxDeliveryFeeQuarterTruck: 0,
    minDeliveryFeeHalfTruck: 15,
    maxDeliveryFeeHalfTruck: 0,
    pricePerKmBicycle: 2,
    pricePerKmMotorcycle: 3,
    pricePerKmCar: 5,
    pricePerKmMinibus: 8,
    pricePerKmTukTuk: 4,
    pricePerKmMotorTricycle: 4,
    pricePerKmQuarterTruck: 8,
    pricePerKmHalfTruck: 12,
    driverShiftsEnabled: true,
    goldTierBonusPerOrder: 5,
    bronzeTierDeductionAmount: 4,
    bronzeSupervisorDeductionAmount: 2,
    driverBonusActive: false,
    driverBonusAmount: 0,
    driverBonusPaidByCustomer: false,
    maxNegativeDriverBalance: 500,
    driverSettlementOrderThreshold: 10,
    driverSearchRadiusKm: 5,
    driverSearchRadiusStepKm: 2,
    driverSearchRadiusMaxKm: 15,
    driverSearchMaxAttempts: 5,
    driverAcceptTimeoutSecs: 30,
    maxDispatchBatchSize: 20,
    maxActiveOrdersPerDriver: 1,
    maxDeliveryRadiusKm: 1500,
    maxKmForBicycle: 5,
    allowBicycle: true,
    allowMotorcycle: true,
    allowCar: true,
    allowMinibus: true,
    allowTukTuk: true,
    allowMotorTricycle: true,
    allowQuarterTruck: true,
    allowHalfTruck: true,
    ...overrides,
  } as any;
}

function createSettlementHarness(options?: {
  orderStatus?: string;
  settledAt?: Date | null;
  lockedSettledAt?: Date | null;
  settings?: Record<string, any>;
  drivers?: Array<{ id: string; tier: DriverTier; walletBalance?: number; userId?: string }>;
  groups?: any[];
  fulfillments?: any[];
  managerAssignments?: Record<string, string>;
  zoneManagers?: Record<string, string[]>;
  globalManagers?: string[];
  rankHistoryByDriver?: Record<string, Array<{ previousTier: DriverTier; createdAt: Date }>>;
}) {
  const driverBalances = new Map<string, number>();
  const driverMap = new Map<string, any>();
  for (const d of options?.drivers ?? [{ id: 'drv-1', tier: DriverTier.GOLD, walletBalance: 0 }]) {
    driverBalances.set(d.id, d.walletBalance ?? 0);
    driverMap.set(d.id, {
      id: d.id,
      userId: d.userId ?? `${d.id}-user`,
      tier: d.tier,
      status: DriverStatus.ONLINE,
      ordersSinceSettlement: 0,
    });
  }

  const managerBalances = new Map<string, number>();
  const walletTxCreates: any[] = [];
  const managerTxCreates: any[] = [];
  const vendorTxCreates: any[] = [];
  const coinTxCreates: any[] = [];
  const groupUpdates: any[] = [];
  const orderUpdates: any[] = [];
  const existingDriverKeys = new Set<string>();
  const existingManagerKeys = new Set<string>();
  let orderSettledState = options?.lockedSettledAt ?? options?.settledAt ?? null;

  const settings = makeBaseSettings(options?.settings);

  const txClient: any = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    order: {
      findUnique: jest.fn().mockImplementation(({ select }: any) => {
        if (select?.settledAt) {
          return Promise.resolve({
            settledAt: orderSettledState,
            status: options?.orderStatus ?? OrderStatus.DELIVERED,
          });
        }
        return Promise.resolve(null);
      }),
      update: jest.fn().mockImplementation(({ data }: any) => {
        orderUpdates.push(data);
        if (data?.settledAt) orderSettledState = data.settledAt;
        return Promise.resolve({ id: 'order-1', ...data });
      }),
    },
    orderDeliveryGroup: {
      update: jest.fn().mockImplementation(({ where, data }: any) => {
        groupUpdates.push({ id: where.id, data });
        return Promise.resolve({ id: where.id, ...data });
      }),
    },
    driverWalletTransaction: {
      findFirst: jest.fn().mockImplementation(({ where }: any) => {
        if (where?.driverId && where?.idempotencyKey) {
          const k = `${where.driverId}:${where.idempotencyKey}`;
          if (existingDriverKeys.has(k)) return Promise.resolve({ id: 'existing' });
          return Promise.resolve(null);
        }
        if (where?.driverId && where?.type && orderSettledState) {
          return Promise.resolve({ id: 'existing' });
        }
        return Promise.resolve(null);
      }),
      create: jest.fn().mockImplementation(({ data }: any) => {
        walletTxCreates.push(data);
        if (data.driverId && data.idempotencyKey) {
          existingDriverKeys.add(`${data.driverId}:${data.idempotencyKey}`);
        }
        return Promise.resolve({ id: `dtx-${walletTxCreates.length}`, ...data });
      }),
    },
    driverManagerWalletTransaction: {
      findFirst: jest.fn().mockImplementation(({ where }: any) => {
        if (where?.managerId && where?.idempotencyKey) {
          const k = `${where.managerId}:${where.idempotencyKey}`;
          if (existingManagerKeys.has(k)) return Promise.resolve({ id: 'existing-mgr-tx' });
          return Promise.resolve(null);
        }
        if (where?.managerId && where?.type === 'DELIVERY_SHARE') {
          const k = `${where.managerId}:settle:${where.orderId}:DELIVERY_SHARE:${where.managerId}`;
          if (existingManagerKeys.has(k)) return Promise.resolve({ id: 'existing-share' });
        }
        return Promise.resolve(null);
      }),
      create: jest.fn().mockImplementation(({ data }: any) => {
        managerTxCreates.push(data);
        if (data.managerId && data.idempotencyKey) {
          existingManagerKeys.add(`${data.managerId}:${data.idempotencyKey}`);
        }
        return Promise.resolve({ id: `mtx-${managerTxCreates.length}`, ...data });
      }),
    },
    driver: {
      findUnique: jest.fn().mockImplementation(({ where }: any) => {
        const drv = driverMap.get(where.id) ?? {
          id: where.id,
          userId: `${where.id}-user`,
          status: DriverStatus.ONLINE,
          ordersSinceSettlement: 0,
        };
        return Promise.resolve({
          ...drv,
          walletBalance: driverBalances.get(where.id) ?? 0,
        });
      }),
      update: jest.fn().mockImplementation(({ where, data }: any) => {
        const prev = driverBalances.get(where.id) ?? 0;
        const inc = data.walletBalance?.increment ?? 0;
        const next = prev + inc;
        driverBalances.set(where.id, next);
        const drv = driverMap.get(where.id);
        return Promise.resolve({
          id: where.id,
          userId: drv?.userId ?? `${where.id}-user`,
          status: data.status ?? drv?.status ?? DriverStatus.ONLINE,
          walletBalance: next,
        });
      }),
    },
    driverManager: {
      update: jest.fn().mockImplementation(({ where, data }: any) => {
        const prev = managerBalances.get(where.id) ?? 0;
        const inc = data.walletBalance?.increment ?? 0;
        const next = prev + inc;
        managerBalances.set(where.id, next);
        return Promise.resolve({ id: where.id, walletBalance: next });
      }),
    },
    customer: {
      update: jest.fn().mockResolvedValue({ coinBalance: 100 }),
    },
    customerCoinTransaction: {
      findFirst: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation(({ data }: any) => {
        coinTxCreates.push(data);
        return Promise.resolve(data);
      }),
    },
    vendor: {
      update: jest.fn().mockResolvedValue({ walletBalance: 500 }),
    },
    vendorWalletTransaction: {
      findFirst: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation(({ data }: any) => {
        vendorTxCreates.push(data);
        return Promise.resolve(data);
      }),
    },
    orderVendorFulfillment: {
      findMany: jest.fn().mockResolvedValue(options?.fulfillments ?? []),
    },
    orderDeliveryGroupItem: {
      findMany: jest.fn().mockResolvedValue([]),
    },
  };

  const prisma: any = {
    $transaction: jest.fn().mockImplementation((fn: any) => Promise.resolve(fn(txClient))),
    order: {
      findUnique: jest.fn().mockImplementation(({ select }: any) => {
        if (select?.settledAt) {
          return Promise.resolve({
            settledAt: orderSettledState,
            status: options?.orderStatus ?? OrderStatus.DELIVERED,
          });
        }
        return Promise.resolve(null);
      }),
    },
    orderVendorFulfillment: {
      findMany: jest.fn().mockResolvedValue(options?.fulfillments ?? []),
    },
    orderDeliveryGroup: {
      findMany: jest.fn().mockResolvedValue(options?.groups ?? []),
    },
    driver: {
      findMany: jest.fn().mockImplementation(({ where }: any) => {
        const ids: string[] = where?.id?.in ?? [];
        return Promise.resolve(ids.map((id) => driverMap.get(id)).filter(Boolean));
      }),
    },
    driverRankHistory: {
      findFirst: jest.fn().mockImplementation(({ where }: any) => {
        const hist = (options?.rankHistoryByDriver?.[where?.driverId] ?? [])
          .filter((h) => !where?.createdAt?.gt || h.createdAt > where.createdAt.gt)
          .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
        return Promise.resolve(hist[0] ? { previousTier: hist[0].previousTier } : null);
      }),
    },
    driverManagerAssignment: {
      findUnique: jest.fn().mockImplementation(({ where }: any) => {
        const mgrId = options?.managerAssignments?.[where.driverId];
        return Promise.resolve(mgrId ? { driverManagerId: mgrId } : null);
      }),
    },
    driverManager: {
      findUnique: jest.fn().mockImplementation(({ where }: any) =>
        Promise.resolve(where?.id ? { id: where.id } : null),
      ),
      findFirst: jest.fn().mockImplementation(({ where }: any) => {
        if (where?.zoneId) {
          const list = options?.zoneManagers?.[where.zoneId] ?? [];
          return Promise.resolve(list[0] ? { id: list[0] } : null);
        }
        if (where?.manageAllDrivers) {
          const globals = options?.globalManagers ?? [];
          return Promise.resolve(globals[0] ? { id: globals[0] } : null);
        }
        return Promise.resolve(null);
      }),
    },
  };

  const statsQueue: any = { add: jest.fn().mockResolvedValue(undefined) };
  const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
  const platformSettings = { getSettings: jest.fn().mockResolvedValue(settings) } as any;
  const earnings = new OrderEarningsCalculator(platformSettings);
  const service = new OrderSettlementService(
    prisma,
    platformSettings,
    eventEmitter,
    statsQueue,
    earnings,
  );

  return {
    service,
    prisma,
    settings,
    driverMap,
    driverBalances,
    managerBalances,
    walletTxCreates,
    managerTxCreates,
    groupUpdates,
    orderUpdates,
    statsQueue,
    setOrderStatus: (s: string) => {
      if (options) options.orderStatus = s;
    },
  };
}

function makeOrderPayload(overrides: Partial<SettleOrderPayload> = {}): SettleOrderPayload {
  return {
    orderId: 'order-1',
    orderNumber: 'ORD-100',
    orderType: 'STANDARD',
    vendorId: null,
    driverId: 'drv-1',
    driverShiftId: 'shift-1',
    zoneId: 'zone-1',
    grandTotal: 130,
    upfrontAmount: 0,
    distanceKm: 2,
    driverTier: 'GOLD',
    deliveryFee: 30, // 25 base + 5 gold surcharge
    goldSurchargeAmount: 5,
    driverBonusFee: 0,
    subtotal: 100,
    serviceFee: 0,
    tax: 0,
    commissionRate: 10,
    deliveryCommissionRate: 20,
    isContracted: true,
    paymentMethod: 'CASH_ON_DELIVERY',
    customerId: 'cust-1',
    customerUserId: 'user-cust-1',
    coinsEarned: 0,
    coinsUsed: 0,
    discount: 0,
    isStacked: false,
    ...overrides,
  };
}

describe('Unified Gold / Silver / Bronze Financial Rules Across All Service Types', () => {
  describe('Platform Settings Validation & Precision Helpers', () => {
    it('allows non-negative values above 100 EGP and rejects negative values', async () => {
      const validDto = plainToInstance(UpdatePlatformSettingsDto, {
        goldTierBonusPerOrder: 150.5,
        bronzeTierDeductionAmount: 250,
        bronzeSupervisorDeductionAmount: 175.25,
      });
      expect(await validate(validDto)).toHaveLength(0);

      const zeroDto = plainToInstance(UpdatePlatformSettingsDto, {
        goldTierBonusPerOrder: 0,
        bronzeTierDeductionAmount: 0,
        bronzeSupervisorDeductionAmount: 0,
      });
      expect(await validate(zeroDto)).toHaveLength(0);

      const invalidDto = plainToInstance(UpdatePlatformSettingsDto, {
        goldTierBonusPerOrder: -1,
        bronzeTierDeductionAmount: -0.5,
        bronzeSupervisorDeductionAmount: -10,
      });
      const errs = await validate(invalidDto);
      expect(errs.length).toBeGreaterThanOrEqual(3);
    });

    it('avoids IEEE-754 floating-point precision drift in money calculations', () => {
      expect(centsToWholeEgp(toMoneyCents(0.1) + toMoneyCents(0.2))).toBe(0);
      expect(centsToWholeEgp(toMoneyCents(25) + toMoneyCents(5))).toBe(30);
      expect(multiplyMoneyRatioToWholeEgp(25, 0.7)).toBe(18);
      expect(multiplyMoneyRatioToWholeEgp(50, 0.7)).toBe(35);
    });
  });

  describe('Customer Delivery Fee Calculation (Standard, Ride, Custom Delivery & No Per-Km Tier Bonuses)', () => {
    it('adds goldTierBonusPerOrder equally as a flat fee on total delivery cost across Standard, Ride, and Custom Delivery without per-km tier multipliers', () => {
      const feeCalc = new DeliveryFeeCalculator();
      const s = makeBaseSettings({
        driverShiftsEnabled: true,
        baseDeliveryFee: 15,
        pricePerKm: 5,
        goldTierBonusPerOrder: 5,
      });

      // Standard Order 2km: base 15 + 2*5=25, + flat 5 gold surcharge = 30
      expect(feeCalc.calculateCustomerDeliveryBreakdown(s, { distanceKm: 2, isStandardOrder: true })).toEqual({
        baseFee: 25,
        goldSurcharge: 5,
        totalFee: 30,
      });

      // Ride 2km: base 15 + 2*5=25, + flat 5 gold surcharge = 30
      expect(feeCalc.calculateCustomerDeliveryBreakdown(s, { distanceKm: 2, isStandardOrder: false })).toEqual({
        baseFee: 25,
        goldSurcharge: 5,
        totalFee: 30,
      });

      // Custom Delivery with maxDeliveryFee=25 still adds fixed 5 EGP gold surcharge on top of base 25 -> 30
      const capped = makeBaseSettings({ baseDeliveryFee: 15, pricePerKm: 5, maxDeliveryFee: 25, goldTierBonusPerOrder: 5 });
      expect(feeCalc.calculateCustomerDeliveryBreakdown(capped, { distanceKm: 10, isStandardOrder: false })).toEqual({
        baseFee: 25,
        goldSurcharge: 5,
        totalFee: 30,
      });

      // OrderEarningsCalculator strips 5 surcharge and pays base share; GOLD gets +5 BONUS, SILVER (default) keeps 0 bonus & 0 deduction
      const earningsCalc = new OrderEarningsCalculator();
      expect(
        earningsCalc.calculateDriverEarningsBreakdown(30, s, {
          driverTier: 'GOLD',
          distanceKm: 2,
          isStandardOrder: true,
          goldSurcharge: 5,
        }),
      ).toMatchObject({
        baseDeliveryFee: 25,
        adjustedBaseFee: 25,
        baseEarnings: 18, // round(25 * 0.7) = 18
        goldBonus: 5,
        netEarnings: 23,
      });

      expect(
        earningsCalc.calculateDriverEarningsBreakdown(30, s, {
          driverTier: 'SILVER',
          distanceKm: 2,
          isStandardOrder: true,
          goldSurcharge: 5,
        }),
      ).toMatchObject({
        baseDeliveryFee: 25,
        adjustedBaseFee: 25,
        baseEarnings: 18, // round(25 * 0.7) = 18
        goldBonus: 0,
        platformRetainedGoldSurcharge: 5,
        bronzeDeduction: 0,
        netEarnings: 18,
      });
    });

    it('adds goldTierBonusPerOrder strictly once on multi-group / multi-vendor orders and preserves once on partial rejection', async () => {
      const settingsSvc = {
        getSettings: jest.fn().mockResolvedValue(makeBaseSettings({ goldTierBonusPerOrder: 5 })),
        calculateGroupDeliveryFee: jest.fn().mockResolvedValue(20),
      } as any;
      const recomputor = new OrderRejectionRecomputor({} as any, settingsSvc);

      const nextActiveUpdate = jest.fn().mockResolvedValue({});
      const txPrisma: any = {
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 25, // 20 base + 5 gold surcharge
            goldSurchargeAmount: 5,
            isPaymentCollector: true,
            primaryDriverId: null,
            assistDriverId: null,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findFirst: jest.fn().mockResolvedValue({ id: 'grp-2' }),
          update: nextActiveUpdate,
        },
        orderDeliveryGroupItem: { count: jest.fn().mockResolvedValue(0) },
        orderDispatch: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
        orderStatusEvent: { upsert: jest.fn().mockResolvedValue({}) },
      };

      const res = await recomputor.syncDeliveryGroupAfterVendorRemoved(
        txPrisma,
        'grp-1',
        'order-mv',
        OrderStatus.PENDING,
      );

      // grp-1 cancelled: 20 base removed from order, 5 gold surcharge transferred to surviving grp-2
      expect(nextActiveUpdate).toHaveBeenCalledWith({
        where: { id: 'grp-2' },
        data: {
          deliveryFee: { increment: 5 },
          goldSurchargeAmount: { increment: 5 },
          isPaymentCollector: true,
        },
      });
      expect(res.deliveryFeeDelta).toBe(-20);
    });
  });

  describe('Scenarios 1-9: Standard Orders, Rides & Custom Delivery Across Gold / Silver / Bronze', () => {
    it.each([
      { label: 'Standard Order', orderType: 'STANDARD', shiftId: 'shift-1' },
      { label: 'Ride', orderType: 'RIDE', shiftId: 'shift-1' },
      { label: 'Custom Delivery (no shift)', orderType: 'CUSTOM_DELIVERY', shiftId: null },
    ])('$label — Gold driver receives full surcharge as separate BONUS tx and $0 goes to platform (Scenarios 1, 4, 7)', async ({ orderType, shiftId }) => {
      const h = createSettlementHarness({
        drivers: [{ id: 'drv-gold', tier: DriverTier.GOLD }],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-gold',
            primaryDriverShiftId: shiftId,
            isPaymentCollector: true,
          },
        ],
        managerAssignments: { 'drv-gold': 'mgr-primary' },
      });

      await h.service.settleOrder(
        makeOrderPayload({
          orderType,
          driverId: 'drv-gold',
          driverShiftId: shiftId,
          driverTier: 'GOLD',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      const feeTx = h.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE');
      const bonusTx = h.walletTxCreates.find((t) => t.type === 'BONUS');
      const penaltyTx = h.walletTxCreates.find((t) => t.type === 'PENALTY');

      expect(feeTx?.amount).toBe(18); // round(25 * 0.70) = 18
      expect(bonusTx?.amount).toBe(5); // full Gold surcharge recorded separately
      expect(bonusTx?.idempotencyKey).toBe('settle:order-1:GOLD_BONUS:drv-gold');
      expect(penaltyTx).toBeUndefined();

      // Primary supervisor earns commission strictly on base 25 (3), NOT on 30
      expect(h.managerTxCreates).toHaveLength(1);
      expect(h.managerTxCreates[0]).toMatchObject({
        managerId: 'mgr-primary',
        type: 'DELIVERY_SHARE',
        amount: 3, // round(25 * 0.10) = 3
      });

      // Platform revenue excludes the 5 Gold bonus: (25 - 18 - 3) = 4
      const appJob = (h.statsQueue.add as jest.Mock).mock.calls.find(
        (c) => c[0] === STATS_JOBS.UPDATE_APP,
      );
      expect(appJob?.[1]?.increment?.totalAdminRevenue).toBe(4);
      expect(h.orderUpdates[0]?.settledGoldBonusAmount).toBe(5);
      expect(h.orderUpdates[0]?.settledGoldPlatformRetainedAmount).toBe(0);
    });

    it.each([
      { label: 'Standard Order', orderType: 'STANDARD', shiftId: 'shift-1' },
      { label: 'Ride', orderType: 'RIDE', shiftId: 'shift-1' },
      { label: 'Custom Delivery (no shift)', orderType: 'CUSTOM_DELIVERY', shiftId: null },
    ])('$label — Silver driver gets base share only and platform retains 100% of surcharge (Scenarios 2, 5, 8)', async ({ orderType, shiftId }) => {
      const h = createSettlementHarness({
        drivers: [{ id: 'drv-silver', tier: DriverTier.SILVER }],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-silver',
            primaryDriverShiftId: shiftId,
            isPaymentCollector: true,
          },
        ],
        managerAssignments: { 'drv-silver': 'mgr-primary' },
      });

      await h.service.settleOrder(
        makeOrderPayload({
          orderType,
          driverId: 'drv-silver',
          driverShiftId: shiftId,
          driverTier: 'SILVER',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      expect(h.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE')?.amount).toBe(18);
      expect(h.walletTxCreates.find((t) => t.type === 'BONUS')).toBeUndefined();
      expect(h.walletTxCreates.find((t) => t.type === 'PENALTY')).toBeUndefined();
      expect(h.managerTxCreates).toHaveLength(1);
      expect(h.managerTxCreates[0].amount).toBe(3);

      // Platform retains base cut (4) + Gold surcharge (5) = 9
      const appJob = (h.statsQueue.add as jest.Mock).mock.calls.find(
        (c) => c[0] === STATS_JOBS.UPDATE_APP,
      );
      expect(appJob?.[1]?.increment?.totalAdminRevenue).toBe(9);
      expect(h.orderUpdates[0]?.settledGoldPlatformRetainedAmount).toBe(5);
    });

    it.each([
      { label: 'Standard Order', orderType: 'STANDARD', shiftId: 'shift-1' },
      { label: 'Ride', orderType: 'RIDE', shiftId: 'shift-1' },
      { label: 'Custom Delivery (no shift)', orderType: 'CUSTOM_DELIVERY', shiftId: null },
    ])('$label — Bronze driver surcharge goes to platform and both driver & primary supervisor fixed deductions apply cleanly (Scenarios 3, 6, 9)', async ({ orderType, shiftId }) => {
      const h = createSettlementHarness({
        settings: { bronzeTierDeductionAmount: 4, bronzeSupervisorDeductionAmount: 2 },
        drivers: [{ id: 'drv-bronze', tier: DriverTier.BRONZE }],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-bronze',
            primaryDriverShiftId: shiftId,
            isPaymentCollector: true,
          },
        ],
        managerAssignments: { 'drv-bronze': 'mgr-primary' },
      });

      await h.service.settleOrder(
        makeOrderPayload({
          orderType,
          driverId: 'drv-bronze',
          driverShiftId: shiftId,
          driverTier: 'BRONZE',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      const feeTx = h.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE');
      const penaltyTx = h.walletTxCreates.find((t) => t.type === 'PENALTY');
      const mgrShareTx = h.managerTxCreates.find((t) => t.type === 'DELIVERY_SHARE');
      const mgrPenaltyTx = h.managerTxCreates.find((t) => t.type === 'BRONZE_PENALTY');

      expect(feeTx?.amount).toBe(18);
      expect(penaltyTx?.amount).toBe(-4);
      expect(penaltyTx?.idempotencyKey).toBe('settle:order-1:BRONZE_PENALTY:drv-bronze');
      expect(h.driverBalances.get('drv-bronze')).toBe(14); // 18 - 4

      expect(mgrShareTx?.amount).toBe(3);
      expect(mgrPenaltyTx?.amount).toBe(-2);
      expect(mgrPenaltyTx?.referenceId).toBe('drv-bronze');
      expect(h.managerBalances.get('mgr-primary')).toBe(1); // 3 - 2

      // Platform revenue = 4 base + 5 surcharge + 4 driver deduction + 2 sup deduction = 15
      const appJob = (h.statsQueue.add as jest.Mock).mock.calls.find(
        (c) => c[0] === STATS_JOBS.UPDATE_APP,
      );
      expect(appJob?.[1]?.increment?.totalAdminRevenue).toBe(15);
    });

    it('excludes supervisors and assisting drivers from receiving the Gold per-order surcharge', async () => {
      const h = createSettlementHarness({
        drivers: [
          { id: 'drv-silver', tier: DriverTier.SILVER },
          { id: 'drv-assist-gold', tier: DriverTier.GOLD },
        ],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 55, // 50 base + 5 surcharge
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-silver',
            assistDriverId: 'drv-assist-gold',
            assistCustomerApproved: true,
            isPaymentCollector: true,
          },
        ],
        managerAssignments: { 'drv-silver': 'mgr-1' },
      });

      await h.service.settleOrder(
        makeOrderPayload({
          deliveryFee: 55,
          goldSurchargeAmount: 5,
          grandTotal: 55,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      // Even though assist driver is GOLD, only the actual primary performing driver's badge controls the surcharge
      expect(h.walletTxCreates.find((t) => t.type === 'BONUS')).toBeUndefined();
      // Manager receives share only on 50 base (5), NOT 55
      expect(h.managerTxCreates[0].amount).toBe(5);
      // Assist receives share only on 50 base (round(50 * 0.7) = 35), NOT 55
      expect(
        h.walletTxCreates.find((t) => t.driverId === 'drv-assist-gold' && t.type === 'DELIVERY_FEE')?.amount,
      ).toBe(35);
    });
  });

  describe('Scenarios 10-11: Shift Independence Across Custom Delivery, Rides & Standard Orders', () => {
    it('keeps Custom Delivery independent of driverShiftsEnabled while preserving Standard and Ride shift rules (Scenarios 10 & 11)', () => {
      expect(requiresActiveShiftForOrderType(true, OrderType.STANDARD)).toBe(true);
      expect(requiresActiveShiftForOrderType(true, OrderType.RIDE)).toBe(true);
      expect(requiresActiveShiftForOrderType(true, OrderType.CUSTOM_DELIVERY)).toBe(false);

      expect(requiresActiveShiftForOrderType(false, OrderType.STANDARD)).toBe(false);
      expect(requiresActiveShiftForOrderType(false, OrderType.RIDE)).toBe(false);
      expect(requiresActiveShiftForOrderType(false, OrderType.CUSTOM_DELIVERY)).toBe(false);
    });

    it('passes exact shift requirements per order type in DispatchService and DriverAssistMatchingService', async () => {
      const geoSearch = { findNearbyDrivers: jest.fn().mockResolvedValue([]) };
      const dispatch = new DispatchService(
        { acquireDispatchLock: jest.fn(), releaseDispatchLock: jest.fn() } as any,
        {} as any,
        {
          getSettings: jest.fn().mockResolvedValue(makeBaseSettings({ driverShiftsEnabled: true })),
          getVehiclePerKm: jest.fn().mockResolvedValue(5),
        } as any,
        { emit: jest.fn() } as any,
        {
          order: {
            findUnique: jest.fn().mockImplementation(({ where }: any) =>
              Promise.resolve({
                id: where.id,
                type: where.id === 'custom-1' ? OrderType.CUSTOM_DELIVERY : where.id === 'ride-1' ? OrderType.RIDE : OrderType.STANDARD,
                status: OrderStatus.LOOKING_FOR_DRIVER,
                pickupAddress: 'Addr',
                deliveryFee: 30,
                customer: { userId: 'u-1', user: { name: 'Cust', avatar: null } },
              }),
            ),
          },
          orderDeliveryGroup: {
            count: jest.fn().mockResolvedValue(1),
            findFirst: jest.fn().mockResolvedValue({
              id: 'grp-1',
              orderId: 'ord',
              sequence: 1,
              status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
              deliveryFee: 30,
              distanceKm: 2,
              primaryDriverId: null,
              items: [],
            }),
          },
        } as any,
        {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            requestedVehicleType: 'MOTORCYCLE',
            lng: 31.2,
            lat: 30.0,
            deliveryLng: 31.25,
            deliveryLat: 30.05,
          }),
          getDistanceKm: jest.fn().mockResolvedValue(2),
          getDeliveryGroupPickupLocation: jest.fn().mockResolvedValue({ lng: 31.2, lat: 30.0 }),
        } as any,
        geoSearch as any,
        new OrderEarningsCalculator(),
        { add: jest.fn() } as any,
      );

      // Force findFirst to echo matching orderId
      (dispatch as any).prisma.orderDeliveryGroup.findFirst.mockImplementation(({ where }: any) =>
        Promise.resolve({
          id: 'grp-1',
          orderId: where.orderId,
          sequence: 1,
          status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
          deliveryFee: 30,
          distanceKm: 2,
          primaryDriverId: null,
          items: [],
        }),
      );

      await dispatch.attemptDispatch({ orderId: 'custom-1', orderNumber: 'CD-1', attempt: 1 });
      expect(geoSearch.findNearbyDrivers.mock.calls[0][5]).toBe(false); // Custom Delivery: NO shift required

      await dispatch.attemptDispatch({ orderId: 'ride-1', orderNumber: 'RD-1', attempt: 1 });
      expect(geoSearch.findNearbyDrivers.mock.calls[1][5]).toBe(true); // Ride: shift required when driverShiftsEnabled=true

      await dispatch.attemptDispatch({ orderId: 'std-1', orderNumber: 'ST-1', attempt: 1 });
      expect(geoSearch.findNearbyDrivers.mock.calls[2][5]).toBe(true); // Standard: shift required when driverShiftsEnabled=true

      // Assist matching also skips shift check for CUSTOM_DELIVERY even when driverShiftsEnabled=true
      const shiftFindMany = jest.fn().mockResolvedValue([]);
      const assistOrderFindUnique = jest.fn().mockResolvedValue({ type: OrderType.CUSTOM_DELIVERY });
      const assist = new DriverAssistMatchingService(
        {
          $queryRaw: jest.fn().mockResolvedValue([
            { id: 'drv-p', lng: 31.2, lat: 30.0 },
            { id: 'drv-unshifted', lng: 31.201, lat: 30.001 },
          ]),
          driverAssistRequest: { findUnique: jest.fn() },
          orderDeliveryGroup: {
            findUnique: jest.fn().mockResolvedValue({ primaryDriverId: 'drv-p' }),
            findMany: jest.fn().mockResolvedValue([]),
          },
          driver: { findMany: jest.fn().mockResolvedValue([{ id: 'drv-unshifted', vehicleType: 'MOTORCYCLE' }]) },
          order: { findUnique: assistOrderFindUnique },
          driverShift: { findMany: shiftFindMany, findFirst: jest.fn().mockResolvedValue(null) },
        } as any,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn().mockResolvedValue(makeBaseSettings({ driverShiftsEnabled: true })) } as any,
        {
          getDeliveryGroupPickupLocation: jest.fn().mockResolvedValue({ lng: 31.2, lat: 30.0 }),
          getOrderLocationContext: jest.fn().mockResolvedValue({ lng: 31.2, lat: 30.0 }),
        } as any,
        { mgetStrings: jest.fn().mockResolvedValue([]) } as any,
      );

      const candidate = await assist.findBestCandidate({ deliveryGroupId: 'grp-1', orderId: 'custom-1' });
      expect(candidate).toBe('drv-unshifted');
      expect(shiftFindMany).not.toHaveBeenCalled();

      // While STANDARD still requires active shift for assist candidates when driverShiftsEnabled=true
      assistOrderFindUnique.mockResolvedValueOnce({ type: OrderType.STANDARD });
      await expect(
        assist.findBestCandidate({ deliveryGroupId: 'grp-1', orderId: 'std-1' }),
      ).rejects.toThrow(BadRequestException);
      expect(shiftFindMany).toHaveBeenCalledTimes(1);
    });

    it('allows manual ONLINE/OFFLINE when driver has no active shift or shifts are disabled, while blocking OFFLINE mid-shift', async () => {
      const updateStatus = jest.fn().mockResolvedValue(undefined);
      const makeDriversSvc = (shiftsEnabled: boolean, hasActiveShift: boolean) =>
        new DriversService(
          {
            findByUserId: jest.fn().mockResolvedValue({
              id: 'drv-1',
              userId: 'u-1',
              status: hasActiveShift ? DriverStatus.ONLINE : DriverStatus.OFFLINE,
              isApproved: true,
            }),
            updateStatus,
            findPendingBreak: jest.fn().mockResolvedValue(null),
          } as any,
          {} as any,
          { emit: jest.fn() } as any,
          {
            platformSetting: { findUnique: jest.fn().mockResolvedValue({ driverShiftsEnabled: shiftsEnabled }) },
            driverShift: { findFirst: jest.fn().mockResolvedValue(hasActiveShift ? { id: 'sh-1' } : null) },
          } as any,
        );

      // Shifts enabled + NO active shift -> driver can go ONLINE manually for Custom Delivery (Scenario 7/10)
      await makeDriversSvc(true, false).updateStatus('u-1', { status: DriverStatus.ONLINE });
      expect(updateStatus).toHaveBeenCalledWith('drv-1', DriverStatus.ONLINE);

      // Shifts disabled -> driver can toggle ONLINE / OFFLINE freely
      await makeDriversSvc(false, false).updateStatus('u-1', { status: DriverStatus.ONLINE });
      expect(updateStatus).toHaveBeenLastCalledWith('drv-1', DriverStatus.ONLINE);

      // Shifts enabled + ACTIVE shift running -> manual OFFLINE still managed by shift
      await expect(
        makeDriversSvc(true, true).updateStatus('u-1', { status: DriverStatus.OFFLINE }),
      ).rejects.toThrow(new BadRequestException(DriverErrors.STATUS_MANAGED_BY_SHIFT));
    });
  });

  describe('Scenarios 12-13: Primary Supervisor vs Multiple Supervisors & Attributable Cap', () => {
    it('charges ONLY the primary supervisor when zone and global supervisors also exist, capped at Bronze driver attributable earnings (Scenario 12)', async () => {
      const h = createSettlementHarness({
        settings: {
          bronzeTierDeductionAmount: 4,
          bronzeSupervisorDeductionAmount: 150, // intentionally larger than order commission to verify attributable cap + no 100 EGP cap
        },
        drivers: [
          { id: 'drv-bronze', tier: DriverTier.BRONZE },
          { id: 'drv-gold', tier: DriverTier.GOLD },
        ],
        groups: [
          {
            id: 'grp-bronze',
            sequence: 1,
            deliveryFee: 55, // 50 base + 5 surcharge
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-bronze',
            isPaymentCollector: true,
          },
        ],
        managerAssignments: { 'drv-bronze': 'mgr-primary' },
        zoneManagers: { 'zone-1': ['mgr-zone-secondary'] },
        globalManagers: ['mgr-global-secondary'],
      });
      h.managerBalances.set('mgr-primary', 1000); // Simulate 1000 EGP existing balance from other Gold drivers!
      h.managerBalances.set('mgr-zone-secondary', 500);
      h.managerBalances.set('mgr-global-secondary', 500);

      await h.service.settleOrder(
        makeOrderPayload({
          driverId: 'drv-bronze',
          driverTier: 'BRONZE',
          deliveryFee: 55,
          goldSurchargeAmount: 5,
          grandTotal: 55,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      // Primary supervisor earns 5 EGP (10% of 50) from this Bronze driver.
      // Because bronzeSupervisorDeductionAmount (150) > attributable earnings (5), ONLY 5 is deducted
      // so the supervisor's 1000 EGP balance from other Gold drivers is completely untouched!
      expect(h.managerTxCreates).toHaveLength(2);
      expect(h.managerTxCreates.every((t) => t.managerId === 'mgr-primary')).toBe(true);
      expect(h.managerTxCreates.find((t) => t.type === 'DELIVERY_SHARE')?.amount).toBe(5);
      expect(h.managerTxCreates.find((t) => t.type === 'BRONZE_PENALTY')?.amount).toBe(-5);
      expect(h.managerBalances.get('mgr-primary')).toBe(1000);
      expect(h.managerBalances.get('mgr-zone-secondary')).toBe(500);
      expect(h.managerBalances.get('mgr-global-secondary')).toBe(500);
    });

    it('applies ONLY driver Bronze deduction when driver has NO primary supervisor (Scenario 13)', async () => {
      const h = createSettlementHarness({
        settings: { bronzeTierDeductionAmount: 6, bronzeSupervisorDeductionAmount: 4 },
        drivers: [{ id: 'drv-bronze-nosup', tier: DriverTier.BRONZE }],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-bronze-nosup',
            isPaymentCollector: true,
          },
        ],
      });

      await h.service.settleOrder(
        makeOrderPayload({
          driverId: 'drv-bronze-nosup',
          driverTier: 'BRONZE',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      expect(h.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE')?.amount).toBe(18);
      expect(h.walletTxCreates.find((t) => t.type === 'PENALTY')?.amount).toBe(-6);
      expect(h.managerTxCreates).toHaveLength(0);
    });
  });

  describe('Scenarios 14-15 & Eligibility: Idempotency, Badge/Setting Immutability & Cancellation Guards', () => {
    it('prevents duplicate transactions on repeated settlement execution (Scenario 14)', async () => {
      const h = createSettlementHarness({
        drivers: [{ id: 'drv-gold', tier: DriverTier.GOLD }],
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-gold',
            isPaymentCollector: true,
          },
        ],
      });

      const payload = makeOrderPayload({
        driverId: 'drv-gold',
        driverTier: 'GOLD',
        deliveryFee: 30,
        goldSurchargeAmount: 5,
        grandTotal: 30,
        subtotal: 0,
        paymentMethod: 'CREDIT_CARD',
      });

      await h.service.settleOrder(payload);
      await h.service.settleOrder(payload);
      await h.service.settleOrder(payload);

      expect(h.walletTxCreates).toHaveLength(2); // 1 DELIVERY_FEE + 1 BONUS, never duplicated
      expect(h.driverBalances.get('drv-gold')).toBe(23);
    });

    it('never creates bonuses, deductions, or payouts on cancelled/non-delivered orders', async () => {
      const h = createSettlementHarness({
        orderStatus: OrderStatus.CANCELLED,
        drivers: [{ id: 'drv-bronze', tier: DriverTier.BRONZE }],
      });

      await h.service.settleOrder(makeOrderPayload({ driverId: 'drv-bronze', driverTier: 'BRONZE' }));
      expect(h.walletTxCreates).toHaveLength(0);
      expect(h.managerTxCreates).toHaveLength(0);
    });

    it('uses execution-time weekly badge snapshot and preserves historical settled records after later badge or settings changes (Scenario 15)', async () => {
      const deliveredAt = new Date('2026-11-15T23:55:00Z');
      const evalChangeAt = new Date('2026-11-16T00:05:00Z');
      const h = createSettlementHarness({
        drivers: [{ id: 'drv-1', tier: DriverTier.BRONZE }], // Driver has ALREADY been demoted to BRONZE in new week!
        groups: [
          {
            id: 'grp-1',
            sequence: 1,
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            distanceKm: 2,
            primaryDriverId: 'drv-1',
            primaryDriverTierSnapshot: null,
            deliveredAt,
            isPaymentCollector: true,
          },
        ],
        rankHistoryByDriver: {
          'drv-1': [{ previousTier: DriverTier.GOLD, createdAt: evalChangeAt }],
        },
        managerAssignments: { 'drv-1': 'mgr-1' },
      });

      await h.service.settleOrder(
        makeOrderPayload({
          driverId: 'drv-1',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          subtotal: 0,
          paymentMethod: 'CREDIT_CARD',
        }),
      );

      // Historical execution was GOLD before midnight eval -> settles as GOLD, NOT BRONZE!
      expect(h.walletTxCreates.find((t) => t.type === 'BONUS')?.amount).toBe(5);
      expect(h.walletTxCreates.find((t) => t.type === 'PENALTY')).toBeUndefined();
      expect(h.managerTxCreates.find((t) => t.type === 'BRONZE_PENALTY')).toBeUndefined();

      // Projector reading settled historical order ignores subsequent setting/tier edits
      const projector = new OrderRoleProjector(
        { driver: { findUnique: jest.fn().mockResolvedValue({ id: 'drv-1', tier: 'BRONZE' }) } } as any,
        {
          getSettings: jest.fn().mockResolvedValue(
            makeBaseSettings({
              bronzeTierDeductionAmount: 99,
              goldTierBonusPerOrder: 50,
            }),
          ),
        } as any,
        {} as any,
        new OrderEarningsCalculator(),
      );

      const projected = await projector.projectForDriver(
        {
          id: 'order-1',
          type: 'STANDARD',
          status: 'DELIVERED',
          paymentMethod: 'CREDIT_CARD',
          deliveryFee: 30,
          goldSurchargeAmount: 5,
          grandTotal: 30,
          settledAt: new Date(),
          settledGoldBonusAmount: 5,
          settledBronzeDriverDeduction: 0,
          settledBronzeDriverDeductionRate: 4,
          deliveryGroups: [
            {
              id: 'grp-1',
              sequence: 1,
              status: 'DELIVERED',
              primaryDriverId: 'drv-1',
              primaryDriverTierSnapshot: 'GOLD',
              deliveryFee: 30,
              goldSurchargeAmount: 5,
              settledGoldBonusAmount: 5,
              settledBronzeDriverDeduction: 0,
            },
          ],
        },
        { sub: 'drv-u', role: 'DRIVER' as any },
      );

      expect(projected.driverEarnings).toBe(23); // 18 base + 5 snapshotted Gold bonus
      expect(projected.financials.goldBonusAmount).toBe(5);
      expect(projected.financials.bronzeDeductionAmount).toBe(0);
    });
  });

  describe('Scenario 16: Customer Receipt Presentation', () => {
    it('shows only the final combined deliveryFee to customers without surcharge breakdown fields (Scenario 16)', () => {
      const projector = new OrderRoleProjector({} as any, {} as any, {} as any, new OrderEarningsCalculator());
      const customerOrder = projector.projectForCustomer({
        id: 'order-cust-1',
        type: 'CUSTOM_DELIVERY',
        status: 'DELIVERED',
        paymentMethod: 'CASH_ON_DELIVERY',
        subtotal: 0,
        deliveryFee: 30, // 25 base + 5 Gold surcharge
        goldSurchargeAmount: 5,
        serviceFee: 10,
        tax: 1,
        discount: 0,
        grandTotal: 41,
        upfrontAmount: 0,
        settledAt: new Date(),
        settledGoldBonusAmount: 5,
        settledGoldPlatformRetainedAmount: 0,
        settledBronzeDriverDeduction: 0,
        settledBronzeSupervisorDeduction: 0,
        settledBronzeDriverDeductionRate: 4,
        settledBronzeSupervisorDeductionRate: 2,
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: 'DELIVERED',
            deliveryFee: 30,
            goldSurchargeAmount: 5,
            primaryDriverTierSnapshot: 'GOLD',
            settledGoldBonusAmount: 5,
          },
        ],
      });

      expect(customerOrder.deliveryFee).toBe(30);
      expect(customerOrder.grandTotal).toBe(41);
      expect(customerOrder.goldSurchargeAmount).toBeUndefined();
      expect(customerOrder.settledGoldBonusAmount).toBeUndefined();
      expect(customerOrder.financials.goldSurchargeAmount).toBeUndefined();
      expect(customerOrder.financials.goldBonusAmount).toBeUndefined();
      expect(customerOrder.deliveryGroups[0].goldSurchargeAmount).toBeUndefined();
      expect(customerOrder.deliveryGroups[0].primaryDriverTierSnapshot).toBeUndefined();
    });

    it('adds goldTierBonusPerOrder flatly to total delivery cost regardless of distance (no per-km tier bonuses for Gold, Silver default, or Bronze)', async () => {
      const feeCalc = new DeliveryFeeCalculator();
      const settings = makeBaseSettings({
        baseDeliveryFee: 15,
        pricePerKm: 5,
        minOrderKm: 2,
        minDistanceFixedPrice: 15,
        minDeliveryFee: 15,
        driverShiftsEnabled: true,
        goldTierBonusPerOrder: 7,
        goldTierBonusPerKm: 99, // ignored legacy property if passed dynamically
        silverTierBonusPerKm: 50,
        bronzeTierBonusPerKm: 10,
      });

      // 10km trip: base = 15 + 10*5 = 65; + flat 7 goldTierBonusPerOrder = 72 (NOT 65 + 99*10)
      expect(
        feeCalc.calculateDeliveryFee(settings, { distanceKm: 10, isStandardOrder: true }),
      ).toBe(72);

      // Settlement for SILVER (default) and BRONZE receives full base share without per-km diff deductions
      const silverSettlement = createSettlementHarness({
        drivers: [{ id: 'drv-silver', tier: DriverTier.SILVER }],
        settings: makeBaseSettings({
          goldTierBonusPerOrder: 7,
          bronzeTierDeductionAmount: 4,
        }),
      });
      await silverSettlement.service.settleOrder(
        makeOrderPayload({
          driverId: 'drv-silver',
          driverTier: DriverTier.SILVER,
          distanceKm: 10,
          deliveryFee: 72,
          goldSurchargeAmount: 7,
          subtotal: 0,
          grandTotal: 72,
          paymentMethod: 'CREDIT_CARD',
        }),
      );
      expect(silverSettlement.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE')?.amount).toBe(46); // round(65 * 0.7)
      expect(silverSettlement.walletTxCreates.find((t) => t.type === 'BONUS')).toBeUndefined();
      expect(silverSettlement.walletTxCreates.find((t) => t.type === 'PENALTY')).toBeUndefined();
    });
  });
});
