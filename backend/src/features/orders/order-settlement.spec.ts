import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverStatus } from '@prisma/client';
import { EVENTS } from '../../common/events/event-names';
import { OrderSettledEvent, DriverStatusChangedEvent } from '../../common/events';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { STATS_JOBS } from '../../infrastructure/queue/queues.constants';
import { OrderSettlementService, SettleOrderPayload } from './order-settlement.service';

describe('OrderSettlementService', () => {
  function makePayload(
    overrides: Partial<SettleOrderPayload> = {},
  ): SettleOrderPayload {
    return {
      orderId: 'order-1',
      orderNumber: 'ORD-001',
      orderType: 'STANDARD',
      vendorId: 'vendor-1',
      driverId: 'driver-1',
      driverShiftId: 'shift-1',
      zoneId: 'zone-1',
      grandTotal: 250,
      upfrontAmount: 0,
      distanceKm: 5,
      driverTier: 'GOLD',
      deliveryFee: 50,
      driverBonusFee: 0,
      subtotal: 200,
      serviceFee: 10,
      tax: 0,
      commissionRate: 10,
      deliveryCommissionRate: 20,
      isContracted: true,
      paymentMethod: 'CASH_ON_DELIVERY',
      customerId: 'cust-1',
      customerUserId: 'cust-user-1',
      coinsEarned: 25,
      coinsUsed: 0,
      discount: 0,
      isStacked: false,
      ...overrides,
    };
  }

  function createHarness(options?: {
    settledAt?: Date | null;
    lockedSettledAt?: Date | null;
    alreadySettledTx?: boolean;
    groups?: any[];
    driverSnapshot?: {
      walletBalance?: number;
      ordersSinceSettlement?: number;
      status?: DriverStatus;
      userId?: string;
    };
    driverFindMany?: any[];
    fulfillments?: any[];
    groupItems?: any[];
    assistOrder?: any;
    settings?: Record<string, any>;
    managerAssignment?: { driverManagerId: string } | null;
  }) {
    const walletTxCreates: any[] = [];
    const vendorWalletTxCreates: any[] = [];
    const vendorUpdates: any[] = [];
    const managerTxCreates: any[] = [];
    const coinTxCreates: any[] = [];
    const driverUpdates: any[] = [];

    const txClient: any = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      order: {
        findUnique: jest.fn().mockImplementation(({ select }: any) => {
          if (select?.settledAt) {
            return Promise.resolve({
              settledAt: options?.lockedSettledAt ?? null,
            });
          }
          if (select?.vendorBranch) {
            return Promise.resolve({ vendorBranch: { name: 'Main Branch' } });
          }
          return Promise.resolve(null);
        }),
        update: jest.fn().mockResolvedValue({ id: 'order-1' }),
      },
      driverWalletTransaction: {
        findFirst: jest.fn().mockImplementation(({ where }: any) => {
          if (where?.type === 'DELIVERY_FEE' && options?.alreadySettledTx) {
            return Promise.resolve({ id: 'existing-tx' });
          }
          return Promise.resolve(null);
        }),
        create: jest.fn().mockImplementation(({ data }: any) => {
          walletTxCreates.push(data);
          return Promise.resolve({ id: `tx-${walletTxCreates.length}`, ...data });
        }),
      },
      orderVendorFulfillment: {
        findMany: jest.fn().mockResolvedValue(options?.fulfillments ?? []),
      },
      orderDeliveryGroupItem: {
        findMany: jest.fn().mockResolvedValue(options?.groupItems ?? []),
      },
      driver: {
        findUnique: jest.fn().mockImplementation(({ where }: any) => {
          const id = where.id;
          return Promise.resolve({
            id,
            userId: options?.driverSnapshot?.userId ?? `${id}-user`,
            status: options?.driverSnapshot?.status ?? DriverStatus.ONLINE,
            walletBalance: options?.driverSnapshot?.walletBalance ?? 0,
            ordersSinceSettlement:
              options?.driverSnapshot?.ordersSinceSettlement ?? 0,
          });
        }),
        update: jest.fn().mockImplementation(({ where, data }: any) => {
          driverUpdates.push({ id: where.id, data });
          const inc = data.walletBalance?.increment ?? 0;
          const nextBalance =
            (options?.driverSnapshot?.walletBalance ?? 0) + inc;
          return Promise.resolve({
            id: where.id,
            userId: options?.driverSnapshot?.userId ?? `${where.id}-user`,
            status: data.status ?? options?.driverSnapshot?.status ?? DriverStatus.ONLINE,
            walletBalance: nextBalance,
          });
        }),
      },
      driverManagerWalletTransaction: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }: any) => {
          managerTxCreates.push(data);
          return Promise.resolve(data);
        }),
      },
      driverManager: {
        update: jest.fn().mockResolvedValue({ walletBalance: 100 }),
      },
      customer: {
        update: jest.fn().mockResolvedValue({ coinBalance: 125 }),
      },
      customerCoinTransaction: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }: any) => {
          coinTxCreates.push(data);
          return Promise.resolve(data);
        }),
      },
      vendor: {
        update: jest.fn().mockImplementation(({ where, data }: any) => {
          vendorUpdates.push({ id: where.id, data });
          return Promise.resolve({
            walletBalance: 500 + (data.walletBalance?.increment ?? 0),
          });
        }),
      },
      vendorWalletTransaction: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }: any) => {
          vendorWalletTxCreates.push(data);
          return Promise.resolve(data);
        }),
      },
    };

    const prisma: any = {
      $transaction: jest
        .fn()
        .mockImplementation((fn: any) => Promise.resolve(fn(txClient))),
      order: {
        findUnique: jest.fn().mockImplementation(({ select }: any) => {
          if (select?.settledAt) {
            return Promise.resolve(
              options?.settledAt !== undefined
                ? { settledAt: options.settledAt }
                : { settledAt: null },
            );
          }
          if (select?.assistDriverId) {
            return Promise.resolve(options?.assistOrder ?? null);
          }
          return Promise.resolve(null);
        }),
      },
      orderDeliveryGroup: {
        findMany: jest.fn().mockResolvedValue(options?.groups ?? []),
      },
      orderVendorFulfillment: {
        findMany: jest.fn().mockResolvedValue(options?.fulfillments ?? []),
      },
      driver: {
        findMany: jest.fn().mockResolvedValue(options?.driverFindMany ?? []),
        findUnique: jest.fn().mockResolvedValue({ tier: 'GOLD' }),
      },
      driverManagerAssignment: {
        findUnique: jest
          .fn()
          .mockResolvedValue(options?.managerAssignment ?? null),
      },
      driverManager: {
        findUnique: jest
          .fn()
          .mockImplementation(({ where }: any) =>
            Promise.resolve(where.id ? { id: where.id } : null),
          ),
        findFirst: jest.fn().mockResolvedValue(null),
      },
    };

    const platformSettings: any = {
      getSettings: jest.fn().mockResolvedValue({
        driverShiftsEnabled: true,
        goldTierBonusPerKm: 2,
        silverTierBonusPerKm: 1.5,
        bronzeTierBonusPerKm: 1,
        deliveryCommissionRate: 20,
        driverManagerCommissionRate: 10,
        multiVendorDriverManagerCommissionRate: 12,
        batchedDriverManagerCommissionRate: 8,
        driverBonusPaidByCustomer: true,
        maxNegativeDriverBalance: 500,
        driverSettlementOrderThreshold: 10,
        defaultTaxRate: 14,
        ...(options?.settings ?? {}),
      }),
    };

    const eventEmit = jest.fn();
    const eventEmitter = { emit: eventEmit } as unknown as EventEmitter2;

    const statsQueue: any = {
      add: jest.fn().mockResolvedValue(undefined),
    };

    const earningsCalculator: OrderEarningsCalculator = {
      computeDriverShare: jest.fn().mockImplementation((_s: any, ctx?: any) => {
        if (ctx?.isStacked) return 0.75;
        if (ctx?.isMultiVendor) return 0.85;
        return 0.8;
      }),
    } as unknown as OrderEarningsCalculator;

    const service = new OrderSettlementService(
      prisma,
      platformSettings,
      eventEmitter,
      statsQueue,
      earningsCalculator,
    );

    return {
      service,
      prisma,
      txClient,
      eventEmit,
      statsQueue,
      earningsCalculator,
      walletTxCreates,
      vendorWalletTxCreates,
      vendorUpdates,
      managerTxCreates,
      coinTxCreates,
      driverUpdates,
    };
  }

  it('skips transaction and events when order already has settledAt (fast-path idempotency)', async () => {
    const h = createHarness({ settledAt: new Date('2026-11-14T08:00:00Z') });

    await h.service.settleOrder(makePayload());

    expect(h.prisma.$transaction).not.toHaveBeenCalled();
    expect(h.statsQueue.add).not.toHaveBeenCalled();
    expect(h.eventEmit).not.toHaveBeenCalled();
  });

  it('aborts cleanly on concurrent lock race when in-tx check detects settled order', async () => {
    const h = createHarness({
      settledAt: null,
      lockedSettledAt: new Date('2026-11-14T08:00:00Z'),
      alreadySettledTx: true,
    });

    await h.service.settleOrder(makePayload());

    expect(h.prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(h.walletTxCreates).toHaveLength(0);
    expect(h.txClient.order.update).not.toHaveBeenCalled();
    expect(h.statsQueue.add).not.toHaveBeenCalled();
    expect(h.eventEmit).not.toHaveBeenCalled();
  });

  it('settles single-vendor Bronze-tier COD order with -2 tier deduction, vendor ledger, coins, stats & ORDER_SETTLED', async () => {
    const h = createHarness({
      driverSnapshot: { walletBalance: 100, ordersSinceSettlement: 0 },
    });

    await h.service.settleOrder(
      makePayload({
        branchName: 'Main Branch',
        driverTier: 'BRONZE',
        distanceKm: 5,
        deliveryFee: 50,
        subtotal: 200,
        commissionRate: 10,
        grandTotal: 250,
        coinsEarned: 25,
      }),
    );

    // Bronze diff vs Gold = (2 - 1) * 5 = 5 -> 50 - 5 = 45; Bronze - 2 = 43; 80% share = 34
    const txByType = new Map(h.walletTxCreates.map((t) => [t.type, t.amount]));
    expect(txByType.get('CASH_HANDED_TO_VENDOR')).toBe(180);
    expect(txByType.get('CASH_COLLECTED')).toBe(-250);
    expect(txByType.get('DELIVERY_FEE')).toBe(34);

    expect(h.vendorWalletTxCreates).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          vendorId: 'vendor-1',
          orderId: 'order-1',
          type: 'ORDER_REVENUE',
          amount: 200,
          description: 'Order ORD-001 (Main Branch) revenue',
        }),
        expect.objectContaining({
          vendorId: 'vendor-1',
          orderId: 'order-1',
          type: 'COMMISSION_DEDUCTION',
          amount: -20,
          description: 'Commission for order ORD-001 (Main Branch)',
        }),
      ]),
    );
    expect(h.vendorUpdates).toEqual([
      { id: 'vendor-1', data: { walletBalance: { increment: 200 } } },
      { id: 'vendor-1', data: { walletBalance: { increment: -20 } } },
    ]);

    expect(h.coinTxCreates).toHaveLength(1);
    expect(h.coinTxCreates[0]).toMatchObject({
      customerId: 'cust-1',
      orderId: 'order-1',
      type: 'EARNED',
      amount: 25,
    });

    const jobNames = (h.statsQueue.add as jest.Mock).mock.calls.map((c) => c[0]);
    expect(jobNames).toEqual(
      expect.arrayContaining([
        STATS_JOBS.UPDATE_DRIVER,
        STATS_JOBS.UPDATE_APP,
        STATS_JOBS.UPDATE_VENDOR,
      ]),
    );

    expect(h.eventEmit).toHaveBeenCalledWith(
      EVENTS.ORDER_SETTLED,
      expect.any(OrderSettledEvent),
    );
  });

  it('settles multi-vendor non-COD order with approved assist driver, manager DELIVERY_SHARE, and per-vendor payables', async () => {
    const h = createHarness({
      driverFindMany: [
        { id: 'd-primary', tier: 'GOLD' },
        { id: 'd-assist', tier: 'BRONZE' },
      ],
      groups: [
        {
          id: 'grp-1',
          sequence: 1,
          deliveryFee: 40,
          distanceKm: 2,
          primaryDriverId: 'd-primary',
          primaryDriverShiftId: 'shift-1',
          assistDriverId: 'd-assist',
          assistDriverShiftId: 'shift-2',
          assistCustomerApproved: true,
          isStacked: false,
        },
        {
          id: 'grp-2',
          sequence: 2,
          deliveryFee: 20,
          distanceKm: 2,
          primaryDriverId: 'd-primary',
          primaryDriverShiftId: 'shift-1',
          assistDriverId: null,
          assistDriverShiftId: null,
          assistCustomerApproved: null,
          isStacked: true,
        },
      ],
      fulfillments: [
        {
          vendorId: 'v-1',
          subtotal: 150,
          commissionRate: 10,
          vendor: { isContracted: true },
          vendorBranch: { name: 'B1', isContracted: true },
        },
        {
          vendorId: 'v-2',
          subtotal: 100,
          commissionRate: 20,
          vendor: { isContracted: false },
          vendorBranch: null,
        },
      ],
      managerAssignment: { driverManagerId: 'mgr-1' },
    });

    await h.service.settleOrder(
      makePayload({
        vendorId: null,
        driverId: 'd-primary',
        paymentMethod: 'CREDIT_CARD',
        deliveryFee: 60,
        subtotal: 250,
        grandTotal: 310,
        coinsEarned: 0,
      }),
    );

    // Non-COD skips store reimbursement & cash collection
    expect(
      h.walletTxCreates.some(
        (t) =>
          t.type === 'CASH_HANDED_TO_VENDOR' || t.type === 'CASH_COLLECTED',
      ),
    ).toBe(false);

    // grp-1: 40 * 0.85 = 34, grp-2 (stacked): 20 * 0.75 = 15 => combined d-primary = 49
    // assist d-assist (BRONZE): (40 - (2-1)*2) = 38 * 0.8 = 30, Bronze -2 = 28
    const feeTxByDriver = new Map(
      h.walletTxCreates
        .filter((t) => t.type === 'DELIVERY_FEE')
        .map((t) => [t.driverId, t]),
    );
    expect(feeTxByDriver.get('d-primary')?.amount).toBe(49);
    expect(feeTxByDriver.get('d-assist')?.amount).toBe(28);

    // Manager gets round(40*0.12)=5 + round(20*0.08)=2 = 7
    expect(h.managerTxCreates).toHaveLength(1);
    expect(h.managerTxCreates[0]).toMatchObject({
      managerId: 'mgr-1',
      type: 'DELIVERY_SHARE',
      amount: 7,
    });

    // Only contracted v-1 receives vendor wallet payable
    const revenueTx = h.vendorWalletTxCreates.filter(
      (t) => t.type === 'ORDER_REVENUE',
    );
    expect(revenueTx).toHaveLength(1);
    expect(revenueTx[0]).toMatchObject({
      vendorId: 'v-1',
      orderId: 'order-1',
      type: 'ORDER_REVENUE',
      amount: 150,
      description: 'Order ORD-001 (B1) revenue',
    });

    const vendorJobs = (h.statsQueue.add as jest.Mock).mock.calls.filter(
      (c) => c[0] === STATS_JOBS.UPDATE_VENDOR,
    );
    expect(vendorJobs).toHaveLength(2);
  });

  it('suspends driver and disconnects socket when wallet balance drops below -maxNegativeDriverBalance', async () => {
    const h = createHarness({
      driverSnapshot: {
        walletBalance: -600,
        ordersSinceSettlement: 2,
        status: DriverStatus.ONLINE,
        userId: 'drv-user-locked',
      },
      settings: { maxNegativeDriverBalance: 500 },
    });

    await h.service.settleOrder(makePayload());

    const counterUpdate = h.driverUpdates.find((u) => 'totalOrders' in u.data);
    expect(counterUpdate?.data).toMatchObject({
      hasUnpaidCommission: true,
      status: DriverStatus.SUSPENDED,
    });

    expect(h.eventEmit).toHaveBeenCalledWith(
      EVENTS.DRIVER_STATUS_CHANGED,
      expect.objectContaining({
        driverId: 'driver-1',
        driverUserId: 'drv-user-locked',
        oldStatus: DriverStatus.ONLINE,
        newStatus: DriverStatus.SUSPENDED,
        reason: 'UNPAID_COMMISSION',
      }),
    );
  });

  it('emits SETTLEMENT_REQUIRED without suspending when order threshold is reached with negative balance above lockout floor', async () => {
    const h = createHarness({
      driverSnapshot: {
        walletBalance: -100,
        ordersSinceSettlement: 9,
        status: DriverStatus.ONLINE,
        userId: 'drv-user-due',
      },
      settings: {
        maxNegativeDriverBalance: 500,
        driverSettlementOrderThreshold: 10,
      },
    });

    await h.service.settleOrder(makePayload());

    const counterUpdate = h.driverUpdates.find((u) => 'totalOrders' in u.data);
    expect(counterUpdate?.data.hasUnpaidCommission).toBe(true);
    expect(counterUpdate?.data.status).toBeUndefined();

    const statusCalls = h.eventEmit.mock.calls.filter(
      (c) => c[0] === EVENTS.DRIVER_STATUS_CHANGED,
    );
    expect(statusCalls).toHaveLength(1);
    expect(statusCalls[0][1]).toBeInstanceOf(DriverStatusChangedEvent);
    expect(statusCalls[0][1]).toMatchObject({
      driverId: 'driver-1',
      newStatus: DriverStatus.ONLINE,
      reason: 'SETTLEMENT_REQUIRED',
    });
  });

  it('uses single-vendor driverShare and supervisorCommissionRate when a grouped order has 1 group and 1 fulfillment', async () => {
    const h = createHarness({
      driverFindMany: [{ id: 'd-1', tier: 'GOLD' }],
      groups: [
        {
          id: 'grp-1',
          sequence: 1,
          deliveryFee: 50,
          distanceKm: 5,
          primaryDriverId: 'd-1',
          primaryDriverShiftId: 'shift-1',
          assistDriverId: null,
          assistDriverShiftId: null,
          assistCustomerApproved: null,
          isStacked: false,
          isPaymentCollector: true,
        },
      ],
      fulfillments: [
        {
          id: 'ff-1',
          vendorId: 'v-1',
          subtotal: 200,
          commissionRate: 10,
          isContracted: true,
          vendor: { isContracted: true },
          vendorBranch: { name: 'Main', isContracted: true },
        },
      ],
      managerAssignment: { driverManagerId: 'mgr-1' },
    });

    await h.service.settleOrder(
      makePayload({
        vendorId: null,
        driverId: 'd-1',
        paymentMethod: 'CREDIT_CARD',
        deliveryFee: 50,
        subtotal: 200,
        grandTotal: 250,
        coinsEarned: 0,
      }),
    );

    const feeTx = h.walletTxCreates.find((t) => t.type === 'DELIVERY_FEE');
    expect(feeTx?.amount).toBe(40); // 50 * 0.8 (driverShare), NOT 43 (0.85)
    expect(feeTx?.idempotencyKey).toBe('settle:order-1:DELIVERY_FEE:d-1');

    expect(h.managerTxCreates).toHaveLength(1);
    expect(h.managerTxCreates[0]).toMatchObject({
      managerId: 'mgr-1',
      amount: 5, // round(50 * 0.1), NOT 6 (0.12)
      idempotencyKey: 'settle:order-1:DELIVERY_SHARE:mgr-1',
    });
  });

  it('subtracts totalAssistEarnings from platformRevenue and credits BONUS to collector primary driver even when payload.driverId is null', async () => {
    const h = createHarness({
      driverFindMany: [
        { id: 'd-primary', tier: 'GOLD' },
        { id: 'd-assist', tier: 'BRONZE' },
      ],
      groups: [
        {
          id: 'grp-1',
          sequence: 1,
          deliveryFee: 40,
          distanceKm: 2,
          primaryDriverId: 'd-primary',
          primaryDriverShiftId: 'shift-1',
          assistDriverId: 'd-assist',
          assistDriverShiftId: 'shift-2',
          assistCustomerApproved: true,
          isStacked: false,
          isPaymentCollector: true,
        },
        {
          id: 'grp-2',
          sequence: 2,
          deliveryFee: 20,
          distanceKm: 2,
          primaryDriverId: 'd-primary',
          primaryDriverShiftId: 'shift-1',
          assistDriverId: null,
          assistDriverShiftId: null,
          assistCustomerApproved: null,
          isStacked: true,
          isPaymentCollector: false,
        },
      ],
      fulfillments: [
        {
          id: 'ff-1',
          vendorId: 'v-1',
          subtotal: 150,
          commissionRate: 10,
          vendor: { isContracted: true },
          vendorBranch: { name: 'B1', isContracted: true },
        },
        {
          id: 'ff-2',
          vendorId: 'v-2',
          subtotal: 100,
          commissionRate: 20,
          vendor: { isContracted: false },
          vendorBranch: null,
        },
      ],
      managerAssignment: { driverManagerId: 'mgr-1' },
    });

    await h.service.settleOrder(
      makePayload({
        vendorId: null,
        driverId: null as unknown as string,
        driverShiftId: null,
        paymentMethod: 'CREDIT_CARD',
        deliveryFee: 60,
        driverBonusFee: 15,
        subtotal: 250,
        grandTotal: 325,
        coinsEarned: 0,
      }),
    );

    const bonusTx = h.walletTxCreates.find((t) => t.type === 'BONUS');
    expect(bonusTx).toMatchObject({
      driverId: 'd-primary',
      driverShiftId: 'shift-1',
      deliveryGroupId: 'grp-1',
      amount: 15,
      idempotencyKey: 'settle:order-1:BONUS:d-primary',
    });

    const appJobCall = (h.statsQueue.add as jest.Mock).mock.calls.find(
      (c) => c[0] === STATS_JOBS.UPDATE_APP,
    );
    // platformFee(25) + (deliveryFee 60 - primary 49) - totalAssist 28 - manager 7 = 1
    expect(appJobCall?.[1]?.increment?.totalAdminRevenue).toBe(1);
  });

  it('scopes transaction idempotency checks to settle: or null keys', async () => {
    const h = createHarness();
    await h.service.settleOrder(makePayload());

    const feeLookupCall = h.txClient.driverWalletTransaction.findFirst.mock.calls.find(
      (c: any[]) => c[0]?.where?.type === 'DELIVERY_FEE',
    );
    expect(feeLookupCall?.[0]?.where?.OR).toEqual([
      { idempotencyKey: null },
      { idempotencyKey: { startsWith: 'settle:' } },
    ]);
    expect(
      h.walletTxCreates.every((t) => t.idempotencyKey?.startsWith('settle:')),
    ).toBe(true);
    expect(
      h.vendorWalletTxCreates.every((t) =>
        t.idempotencyKey?.startsWith('settle:'),
      ),
    ).toBe(true);
  });
});
