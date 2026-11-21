import { BadRequestException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DriverStatus,
  NotificationType,
  OrderStatus,
  OrderType,
  Role,
  VehicleType,
} from '@prisma/client';
import { SocketListener } from '../../common/listeners/socket.listener';
import { OrderListener } from '../../common/listeners/order.listener';
import { ShiftListener } from '../../common/listeners/shift.listener';
import { MailListener } from '../../common/listeners/mail.listener';
import { DriverAssistListener } from '../../common/listeners/driver-assist.listener';
import {
  DriverAssistDecidedEvent,
  DriverAssistRequestedEvent,
  DriverLocationUpdatedEvent,
  OrderCancelledEvent,
  OrderDispatchSentEvent,
  OrderSettledEvent,
  OrderStatusChangedEvent,
  OrderVendorRejectedEvent,
  OtpRequestedEvent,
  ShiftAssignedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { OrderWorkflowDispatcher } from '../../common/orders/order-workflow.dispatcher';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import {
  EVENT_JOBS,
  ORDER_JOBS,
  STATS_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { EventsProcessor } from '../events/events.processor';
import { OrderEventsHandler } from '../events/order-events.handler';
import { DispatchEventsHandler } from '../events/dispatch-events.handler';
import { DispatchService } from '../dispatch/dispatch.service';
import { DispatchLifecycleService } from '../dispatch/dispatch-lifecycle.service';
import { DriverGeoSearchService } from '../location/driver-geo-search.service';
import { LocationRepository } from '../location/location.repository';
import { DriversRepository } from '../drivers/drivers.repository';
import { DriverAssistMatchingService } from '../drivers/driver-assist-matching.service';
import { StatisticsService } from '../statistics/statistics.service';
import { OrderSettlementService } from './order-settlement.service';
import { OrdersRepository } from './orders.repository';
import { OrdersPaymentService } from './orders-payment.service';
import { OrderRoleProjector } from './projections/order-role.projector';
import { OrderRejectionRecomputor } from './helpers/order-rejection-recomputor';
import { recordOrderStatusEventIdempotent } from './helpers/order-actor.helper';
import { OrderErrors } from '../../common/constants/response.constants';

describe('System Hardening Regressions (Dispatch, Orders, Outbox, Events, Tracking)', () => {
  // ─── 1. WS Process Live Driver Location Broadcast ─────────────────────────

  describe('1. SocketListener live driver.location broadcast', () => {
    it('broadcasts driver.location to customer user and driver room from SocketListener (active in WsModule)', async () => {
      const emitToUser = jest.fn().mockResolvedValue(undefined);
      const emitToRoom = jest.fn().mockResolvedValue(undefined);
      const listener = new SocketListener(
        {} as any,
        { emitToUser, emitToRoom } as any,
      );

      listener.handleLocationUpdated(
        new DriverLocationUpdatedEvent(
          'drv-1',
          'u-drv-1',
          31.25,
          30.05,
          'ord-1',
          'u-cust-1',
        ),
      );

      expect(emitToUser).toHaveBeenCalledWith(
        'u-cust-1',
        'driver.location',
        expect.objectContaining({
          driverId: 'drv-1',
          orderId: 'ord-1',
          longitude: 31.25,
          latitude: 30.05,
        }),
      );
      expect(emitToRoom).toHaveBeenCalledWith(
        'driver_drv-1',
        'driver.location',
        expect.objectContaining({
          driverId: 'drv-1',
          orderId: 'ord-1',
        }),
      );
    });
  });

  // ─── 2. Multi-Vendor Split Order Group 2 Dispatch ─────────────────────────

  describe('2. Multi-vendor split order dispatch for Group 2+', () => {
    it.each([
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
      OrderStatus.PICKED_UP,
    ])(
      'dispatches unassigned Group 2 when parent order is %s instead of returning invalid',
      async (parentStatus) => {
        const dispatchRepo: any = {
          saveBroadcast: jest.fn().mockResolvedValue(undefined),
          acquireActiveClaim: jest.fn().mockResolvedValue(true),
          saveDispatchState: jest.fn().mockResolvedValue(undefined),
          addDriverPending: jest.fn().mockResolvedValue(undefined),
        };
        const prisma: any = {
          order: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'ord-split',
              orderNumber: 'OTL-SPLIT',
              type: OrderType.STANDARD,
              status: parentStatus,
              deliveryFee: 50,
              goldSurchargeAmount: 0,
              distanceKm: 3,
              customerId: 'cust-1',
              customer: { userId: 'u-cust-1' },
            }),
          },
          orderDeliveryGroup: {
            count: jest.fn().mockResolvedValue(2),
            findUnique: jest.fn().mockResolvedValue({
              id: 'grp-2',
              orderId: 'ord-split',
              sequence: 2,
              status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
              deliveryFee: 25,
              goldSurchargeAmount: 0,
              distanceKm: 2,
              primaryDriverId: null,
              items: [],
            }),
          },
        };
        const locationRepo: any = {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            lng: 31.23,
            lat: 30.04,
            deliveryLng: 31.25,
            deliveryLat: 30.05,
            requestedVehicleType: null,
            pickupAddress: 'Store 2',
            deliveryAddress: 'Customer',
          }),
          getDeliveryGroupPickupLocation: jest
            .fn()
            .mockResolvedValue({ lng: 31.24, lat: 30.045 }),
        };
        const geoSearch: any = {
          findNearbyDrivers: jest.fn().mockResolvedValue([
            {
              id: 'drv-2',
              userId: 'u-drv-2',
              tier: 'SILVER',
              vehicleType: VehicleType.MOTORCYCLE,
              distanceKm: 1.1,
              activeShiftId: null,
              isOnDelivery: false,
            },
          ]),
        };
        const emitter: any = { emit: jest.fn() };
        const dispatchQueue: any = { add: jest.fn().mockResolvedValue({}) };
        const settings: any = {
          getSettings: jest.fn().mockResolvedValue({
            driverSearchRadiusKm: 3,
            driverSearchRadiusStepKm: 3,
            driverSearchRadiusMaxKm: 15,
            driverAcceptTimeoutSecs: 30,
            maxDispatchBatchSize: 5,
            driverShiftsEnabled: false,
            driverDeliverySharePercentage: 80,
            allowMotorcycle: true,
            allowBicycle: true,
            maxKmForBicycle: 5,
          }),
        };
        const earnings: any = {
          calculateDriverEarningsForFee: jest.fn().mockReturnValue(20),
          calculateEstimatedEarningsFromDistance: jest
            .fn()
            .mockResolvedValue(20),
        };

        const svc = new DispatchService(
          dispatchRepo,
          {} as any,
          settings,
          emitter,
          prisma,
          locationRepo,
          geoSearch,
          earnings,
          dispatchQueue,
        );

        const outcome = await svc.attemptDispatch({
          orderId: 'ord-split',
          orderNumber: 'OTL-SPLIT',
          attempt: 1,
          deliveryGroupId: 'grp-2',
        });

        expect(outcome).toBe('dispatched');
        expect(emitter.emit).toHaveBeenCalledWith(
          EVENTS.ORDER_DISPATCH_SENT,
          expect.objectContaining({
            orderId: 'ord-split',
            driverId: 'drv-2',
          }),
        );
      },
    );
  });

  // ─── 3. Gold Bonus + Time-Based driverBonusFee Settlement ─────────────────

  describe('3. OrderSettlementService Gold bonus + time-based driverBonusFee', () => {
    it('avoids (deliveryGroupId, type, driverId) unique collision when both Gold bonus and time-based bonus apply', async () => {
      const walletCreates: any[] = [];
      const uniqueGroupTypeDriver = new Set<string>();
      const uniqueDriverIdempotency = new Set<string>();

      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-gold-bonus',
            settledAt: null,
          }),
          update: jest.fn().mockResolvedValue({}),
        },
        orderDeliveryGroup: {
          update: jest.fn().mockResolvedValue({}),
        },
        orderDeliveryGroupItem: {
          findMany: jest.fn().mockResolvedValue([]),
        },
        orderVendorFulfillment: {
          findMany: jest.fn().mockResolvedValue([]),
        },
        driver: {
          update: jest.fn().mockResolvedValue({ walletBalance: 100 }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-gold',
            userId: 'u-gold',
            walletBalance: 100,
            status: DriverStatus.ONLINE,
            hasUnpaidCommission: false,
            totalDeliveries: 5,
          }),
        },
        driverWalletTransaction: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockImplementation(async ({ data }: any) => {
            if (data.deliveryGroupId != null) {
              const groupKey = `${data.deliveryGroupId}:${data.type}:${data.driverId}`;
              if (uniqueGroupTypeDriver.has(groupKey)) {
                throw Object.assign(new Error('P2002 unique violation'), {
                  code: 'P2002',
                });
              }
              uniqueGroupTypeDriver.add(groupKey);
            }
            if (data.idempotencyKey) {
              const idemKey = `${data.driverId}:${data.idempotencyKey}`;
              if (uniqueDriverIdempotency.has(idemKey)) {
                throw Object.assign(new Error('P2002 idempotency violation'), {
                  code: 'P2002',
                });
              }
              uniqueDriverIdempotency.add(idemKey);
            }
            walletCreates.push(data);
            return data;
          }),
        },
        vendor: { update: jest.fn().mockResolvedValue({}) },
        vendorWalletTransaction: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({}),
        },
        customer: { update: jest.fn().mockResolvedValue({ coinBalance: 10 }) },
        customerCoinTransaction: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({}),
        },
      };

      const prisma: any = {
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
        order: {
          findUnique: jest.fn().mockResolvedValue({
            settledAt: null,
            status: OrderStatus.DELIVERED,
          }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-gold-1',
              sequence: 1,
              status: DeliveryGroupStatus.DELIVERED,
              deliveryFee: 30,
              goldSurchargeAmount: 10,
              distanceKm: 3,
              isStacked: false,
              isPaymentCollector: true,
              primaryDriverId: 'drv-gold',
              primaryDriverShiftId: 'sh-1',
              primaryDriverTierSnapshot: 'GOLD',
              assistDriverId: null,
              assistDriverShiftId: null,
              deliveredAt: new Date(),
            },
          ]),
        },
        orderVendorFulfillment: { findMany: jest.fn().mockResolvedValue([]) },
        driver: {
          findMany: jest
            .fn()
            .mockResolvedValue([{ id: 'drv-gold', tier: 'GOLD' }]),
        },
        driverManagerAssignment: { findUnique: jest.fn().mockResolvedValue(null) },
        driverManager: { findFirst: jest.fn().mockResolvedValue(null) },
      };

      const settings: any = {
        getSettings: jest.fn().mockResolvedValue({
          driverDeliverySharePercentage: 80,
          stackedOrderDriverPercentage: 50,
          multiVendorDriverSharePercentage: 80,
          supervisorCommissionPercentage: 0,
          batchedSupervisorCommissionPercentage: 0,
          multiVendorSupervisorCommissionPercentage: 0,
          bronzeTierDeductionAmount: 0,
          bronzeSupervisorDeductionAmount: 0,
          driverWalletLimit: 1000,
          driverSettlementMilestone: 500,
        }),
      };

      const svc = new OrderSettlementService(
        prisma,
        settings,
        { emit: jest.fn() } as any,
        { add: jest.fn().mockResolvedValue({}) } as any,
      );

      await svc.settleOrder({
        orderId: 'ord-gold-bonus',
        orderNumber: 'OTL-GB-1',
        customerId: 'cust-1',
        customerUserId: 'u-cust-1',
        vendorId: null,
        vendorBranchId: null,
        driverId: 'drv-gold',
        driverShiftId: 'sh-1',
        paymentMethod: 'CASH_ON_DELIVERY',
        paymentStatus: 'COMPLETED',
        subtotal: 0,
        deliveryFee: 30,
        goldSurchargeAmount: 10,
        driverBonusFee: 15,
        serviceFee: 0,
        tax: 0,
        discount: 0,
        grandTotal: 45,
        upfrontAmount: 0,
        coinsEarned: 0,
        distanceKm: 3,
        isContracted: true,
        commissionRate: 0,
        zoneId: null,
      });

      const bonusRows = walletCreates.filter((r) => r.type === 'BONUS');
      expect(bonusRows).toHaveLength(2);
      expect(bonusRows).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            driverId: 'drv-gold',
            deliveryGroupId: 'grp-gold-1',
            amount: 10,
            idempotencyKey: 'settle:ord-gold-bonus:GOLD_BONUS:drv-gold',
          }),
          expect.objectContaining({
            driverId: 'drv-gold',
            deliveryGroupId: null,
            amount: 15,
            idempotencyKey: 'settle:ord-gold-bonus:BONUS:drv-gold',
          }),
        ]),
      );
    });
  });

  // ─── 4. Transaction-Safe Status Events & 2nd Cancellation After Retry ─────

  describe('4. Transaction-safe recordOrderStatusEventIdempotent & revision-scoped cancellation', () => {
    it('uses createMany({ skipDuplicates: true }) when available so duplicate eventKey never triggers P2002/25P02 inside tx', async () => {
      const createMany = jest
        .fn()
        .mockResolvedValueOnce({ count: 1 })
        .mockResolvedValueOnce({ count: 0 });
      const create = jest.fn();
      const tx = { orderStatusEvent: { createMany, create } };

      const r1 = await recordOrderStatusEventIdempotent(tx, {
        orderId: 'ord-1',
        eventKey: 'dup:key',
        status: OrderStatus.CANCELLED,
      });
      const r2 = await recordOrderStatusEventIdempotent(tx, {
        orderId: 'ord-1',
        eventKey: 'dup:key',
        status: OrderStatus.CANCELLED,
      });

      expect(r1.created).toBe(true);
      expect(r2.created).toBe(false);
      expect(createMany).toHaveBeenCalledTimes(2);
      expect(createMany).toHaveBeenCalledWith({
        data: [expect.objectContaining({ eventKey: 'dup:key' })],
        skipDuplicates: true,
      });
      expect(create).not.toHaveBeenCalled();
    });

    it('keys OrderListener and EventsProcessor cancellation deduplication by (orderId, revision)', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const outbox: any = { markProcessed: jest.fn().mockResolvedValue(undefined) };
      const workflow: any = {
        onOrderCancelled: jest.fn().mockResolvedValue(undefined),
        onOrderStatusChanged: jest.fn().mockResolvedValue(undefined),
      };
      const listener = new OrderListener({} as any, eventsQueue, outbox, workflow);

      await listener.handleOrderCancelled(
        new OrderCancelledEvent(
          'ord-retry',
          'OTL-R1',
          'c1',
          'u-c1',
          null,
          [],
          null,
          null,
          'Timeout',
          null,
          [],
          4,
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.ORDER_CANCELLED,
        expect.any(Object),
        expect.objectContaining({ jobId: 'notify_order_cancelled_ord-retry_4' }),
      );

      // EventsProcessor computes distinct Redis idempotency keys per revision
      const redisClient: any = {
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue('OK'),
        del: jest.fn().mockResolvedValue(1),
      };
      const proc = new EventsProcessor(
        { handleOrderCancelled: jest.fn().mockResolvedValue(undefined) } as any,
        {} as any,
        {} as any,
        {} as any,
        { getClient: () => redisClient } as any,
      );
      await proc.process({
        name: EVENT_JOBS.ORDER_CANCELLED,
        data: { orderId: 'ord-retry', revision: 4 },
      } as any);
      expect(redisClient.set).toHaveBeenCalledWith(
        'notify:order_cancelled:ord-retry:4',
        'DONE',
        'EX',
        14400,
      );
    });

    it('OrderListener includes event.dedupeKey in notify_order_status jobId and does not duplicate delivered push on ORDER_SETTLED', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const listener = new OrderListener(
        {} as any,
        eventsQueue,
        { markProcessed: jest.fn().mockResolvedValue(undefined) } as any,
        { onOrderStatusChanged: jest.fn().mockResolvedValue(undefined) } as any,
      );

      await listener.handleOrderStatusChanged(
        new OrderStatusChangedEvent(
          'ord-mv',
          'OTL-MV',
          OrderStatus.PARTIALLY_PICKED_UP,
          OrderStatus.PARTIALLY_PICKED_UP,
          'c1',
          'u-c1',
          null,
          [],
          'd1',
          'u-d1',
          'u-d1',
          'Delivery 1 completed',
          5,
          'delivery:1',
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.ORDER_STATUS_CHANGED,
        expect.any(Object),
        expect.objectContaining({
          jobId: 'notify_order_status_ord-mv_5_delivery_1',
        }),
      );

      eventsQueue.add.mockClear();
      listener.handleOrderSettled(
        new OrderSettledEvent(
          'ord-mv',
          'OTL-MV',
          null,
          'd1',
          null,
          100,
          20,
          10,
          0,
          'u-c1',
        ),
      );
      expect(eventsQueue.add).not.toHaveBeenCalled();
    });
  });

  // ─── 5. Payment Endpoints & Cancelled Guard ───────────────────────────────

  describe('5. OrdersPaymentService returns full Order & blocks confirm on cancelled orders', () => {
    it('rejects driverConfirmPayment when order was concurrently cancelled without updating groups or emitting events', async () => {
      const groupUpdateMany = jest.fn();
      const tx: any = {
        order: {
          updateMany: jest.fn().mockResolvedValue({ count: 0 }), // CANCELLED -> 0 updated
        },
        orderDeliveryGroup: { updateMany: groupUpdateMany },
      };
      const prisma: any = {
        driver: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'drv-1', userId: 'u-drv-1' }),
        },
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
      };
      const ordersRepo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-pay',
          orderNumber: 'OTL-P1',
          status: OrderStatus.PENDING_PAYMENT,
          customerId: 'c1',
          customer: { user: { id: 'u-c1' } },
          deliveryGroups: [
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.PENDING_PAYMENT,
              isPaymentCollector: true,
              primaryDriverId: 'drv-1',
              pickedUpAt: null,
              items: [],
            },
          ],
          vendorFulfillments: [],
        }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const emitter: any = { emit: jest.fn() };
      const svc = new OrdersPaymentService(
        ordersRepo,
        emitter,
        prisma,
        {} as any,
        {} as any,
      );

      await expect(
        svc.driverConfirmPayment(
          { sub: 'u-drv-1', role: Role.DRIVER } as any,
          'ord-pay',
          true,
        ),
      ).rejects.toThrow(BadRequestException);

      expect(groupUpdateMany).not.toHaveBeenCalled();
      expect(emitter.emit).not.toHaveBeenCalled();
    });

    it('returns full updated order from customerMarkPaid and driverConfirmPayment', async () => {
      const updatedOrder = { id: 'ord-pay-2', paymentStatus: 'COMPLETED' };
      const tx: any = {
        order: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({ revision: 3 }),
        },
        orderDeliveryGroup: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderStatusEvent: {
          createMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      const prisma: any = {
        driver: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'drv-1', userId: 'u-drv-1' }),
        },
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
      };
      const ordersRepo: any = {
        findById: jest
          .fn()
          .mockResolvedValueOnce({
            id: 'ord-pay-2',
            orderNumber: 'OTL-P2',
            status: OrderStatus.PENDING_PAYMENT,
            customerId: 'c1',
            customer: { user: { id: 'u-c1' } },
            deliveryGroups: [
              {
                id: 'grp-1',
                sequence: 1,
                status: DeliveryGroupStatus.PENDING_PAYMENT,
                isPaymentCollector: true,
                primaryDriverId: 'drv-1',
                pickedUpAt: null,
                items: [],
              },
            ],
            vendorFulfillments: [],
          })
          .mockResolvedValueOnce(updatedOrder),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const svc = new OrdersPaymentService(
        ordersRepo,
        { emit: jest.fn() } as any,
        prisma,
        {} as any,
        { record: jest.fn().mockResolvedValue('out-1') } as any,
      );

      const res = await svc.driverConfirmPayment(
        { sub: 'u-drv-1', role: Role.DRIVER } as any,
        'ord-pay-2',
        true,
      );
      expect(res).toBe(updatedOrder);
    });
  });

  // ─── 6. Projections: Prepaid MOBILE_WALLET & Internal Field Sanitization ──

  describe('6. OrderRoleProjector prepaid MOBILE_WALLET & internal field stripping', () => {
    it('marks completed MOBILE_WALLET orders as prepaid with 0 cash due for Customer and Admin and strips internal settlement fields for Vendor and Driver', async () => {
      const projector = new OrderRoleProjector(
        {
          driver: { findUnique: jest.fn().mockResolvedValue({ id: 'drv-1', tier: 'SILVER' }) },
          vendorMember: { findMany: jest.fn().mockResolvedValue([{ vendorId: 'v-1', branchId: null, role: 'OWNER' }]) },
        } as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            driverDeliverySharePercentage: 80,
            driverBonusPaidByCustomer: false,
          }),
        } as any,
        { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
        {
          calculateDriverEarningsBreakdown: jest.fn().mockReturnValue({
            netEarnings: 20,
            goldBonus: 0,
            bronzeDeduction: 0,
          }),
        } as any,
      );

      const baseOrder: any = {
        id: 'ord-mw',
        paymentMethod: 'MOBILE_WALLET',
        paymentStatus: 'COMPLETED',
        grandTotal: 250,
        upfrontAmount: 0,
        deliveryFee: 25,
        subtotal: 225,
        settledGoldPlatformRetainedAmount: 10,
        settledBronzeSupervisorDeduction: 4,
        settledBronzeSupervisorDeductionRate: 4,
        goldSurchargeAmount: 10,
        settledGoldBonusAmount: 0,
        settledBronzeDriverDeduction: 5,
        settledBronzeDriverDeductionRate: 5,
        vendor: { id: 'v-1', storeName: 'Store', commissionRate: 15, walletBalance: 5000 },
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: 'DRIVER_ASSIGNED',
            deliveryFee: 25,
            isPaymentCollector: true,
            primaryDriverId: 'drv-1',
            settledGoldPlatformRetainedAmount: 10,
            settledBronzeSupervisorDeduction: 4,
            settledPrimaryManagerId: 'mgr-secret',
          },
        ],
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'v-1',
            status: 'ACCEPTED',
            subtotal: 225,
            isContracted: true,
            commissionRate: 10,
            vendor: { id: 'v-1', storeName: 'Store' },
          },
        ],
        items: [],
      };

      const custView = projector.projectForCustomer(baseOrder);
      expect(custView.financials.isPrepaid).toBe(true);
      expect(custView.financials.cashToPayAtDoor).toBe(0);

      const adminView = await projector.enrichWithAdminHelpers(baseOrder);
      expect(adminView.financials.isPrepaid).toBe(true);
      expect(adminView.financials.cashToCollect).toBe(0);

      const vendorView = await projector.projectForVendor(
        baseOrder,
        { sub: 'u-v1', role: Role.VENDOR_MEMBER } as any,
        'v-1',
      );
      expect(vendorView.settledGoldPlatformRetainedAmount).toBeUndefined();
      expect(vendorView.settledBronzeSupervisorDeduction).toBeUndefined();
      expect(vendorView.goldSurchargeAmount).toBeUndefined();

      const driverView = await projector.projectForDriver(baseOrder, {
        sub: 'u-drv-1',
        role: Role.DRIVER,
      } as any);
      expect(driverView.settledGoldPlatformRetainedAmount).toBeUndefined();
      expect(driverView.settledBronzeSupervisorDeduction).toBeUndefined();
      expect(driverView.deliveryGroups[0].settledPrimaryManagerId).toBeUndefined();
      expect(driverView.vendor?.commissionRate).toBeUndefined();
      expect(driverView.vendor?.walletBalance).toBeUndefined();
    });
  });

  // ─── 7. Redis delIfValue & Dispatch Single-Owner Claim Guards ─────────────

  describe('7. RedisService.delIfValue & DispatchLifecycleService ownership', () => {
    it('strictly returns false when Redis key does not exist (no false-positive claim release)', async () => {
      let capturedScript = '';
      const evalMock = jest.fn().mockImplementation((script: string) => {
        capturedScript = script;
        return Promise.resolve(0);
      });
      const redis = new RedisService({} as any);
      (redis as any).client = { eval: evalMock };

      const deleted = await redis.delIfValue('k', 'v1');
      expect(deleted).toBe(false);
      expect(capturedScript).not.toContain('if not v then');
      expect(capturedScript).toContain('if v and v == ARGV[1] then');
    });

    it('handleExpiry skips expiry penalties and retry when releaseActiveClaim returns false', async () => {
      const dispatchRepo: any = {
        getBroadcast: jest.fn().mockResolvedValue({
          dispatchId: 'd-1',
          orderId: 'o-1',
          deliveryGroupId: 'g-1',
          type: OrderType.STANDARD,
          expiresAt: new Date().toISOString(),
          candidates: [{ driverId: 'drv-1', userId: 'u-1', deliveryGroupId: 'g-1' }],
        }),
        releaseActiveClaim: jest.fn().mockResolvedValue(false),
        deleteBroadcast: jest.fn().mockResolvedValue(undefined),
        deleteDispatchState: jest.fn(),
        createTerminalRecords: jest.fn(),
      };
      const prisma: any = {
        order: { findUnique: jest.fn().mockResolvedValue({ status: OrderStatus.LOOKING_FOR_DRIVER }) },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
            primaryDriverId: null,
          }),
        },
      };
      const dispatchQueue: any = { add: jest.fn() };
      const lifecycle = new DispatchLifecycleService(
        dispatchRepo,
        {} as any,
        { emit: jest.fn() } as any,
        prisma,
        {} as any,
        {} as any,
        {} as any,
        dispatchQueue,
      );

      await lifecycle.handleExpiry({
        dispatchId: 'd-1',
        orderId: 'o-1',
        orderNumber: 'OTL-1',
        attempt: 1,
        excludeDriverIds: [],
        deliveryGroupId: 'g-1',
      });

      expect(dispatchRepo.deleteDispatchState).not.toHaveBeenCalled();
      expect(dispatchRepo.createTerminalRecords).not.toHaveBeenCalled();
      expect(dispatchQueue.add).not.toHaveBeenCalled();
    });

    it('commitAcceptanceTransaction does NOT release active claim on individual DRIVER_ALREADY_ON_ORDER error', async () => {
      const releaseActiveClaim = jest.fn().mockResolvedValue(true);
      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue([{ id: 'x' }]),
        order: {
          findUnique: jest.fn().mockResolvedValue({ status: OrderStatus.LOOKING_FOR_DRIVER }),
        },
      };
      const prisma: any = {
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
        orderVendorFulfillment: { findMany: jest.fn().mockResolvedValue([]) },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-1',
            orderNumber: 'OTL-1',
            type: OrderType.STANDARD,
            status: OrderStatus.LOOKING_FOR_DRIVER,
            paymentMethod: 'CASH_ON_DELIVERY',
            paymentStatus: 'PENDING',
            upfrontAmount: 0,
            customerId: 'c1',
            customer: { userId: 'u-c1' },
            deliveryGroups: [
              { id: 'grp-1', status: DeliveryGroupStatus.LOOKING_FOR_DRIVER, primaryDriverId: null },
            ],
            vendorFulfillments: [],
          }),
        },
      };
      const dispatchRepo: any = {
        getBroadcast: jest.fn().mockResolvedValue({
          dispatchId: 'disp-1',
          orderId: 'ord-1',
          deliveryGroupId: 'grp-1',
          type: OrderType.STANDARD,
          expiresAt: new Date(Date.now() + 60_000).toISOString(),
          candidates: [
            { driverId: 'drv-busy', userId: 'u-busy', deliveryGroupId: 'grp-1', driverShiftId: null, distanceKm: 1, estimatedEarnings: 20, isStacked: false },
            { driverId: 'drv-free', userId: 'u-free', deliveryGroupId: 'grp-1', driverShiftId: null, distanceKm: 2, estimatedEarnings: 20, isStacked: false },
          ],
        }),
        getRejectedDriverIds: jest.fn().mockResolvedValue([]),
        releaseActiveClaim,
      };
      const lifecycle = new DispatchLifecycleService(
        dispatchRepo,
        { getSettings: jest.fn().mockResolvedValue({ maxActiveOrdersPerDriver: 1 }) } as any,
        { emit: jest.fn() } as any,
        prisma,
        {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            lng: 31.23,
            lat: 30.04,
            deliveryLng: 31.25,
            deliveryLat: 30.05,
            requestedVehicleType: null,
          }),
          getDeliveryGroupPickupLocation: jest
            .fn()
            .mockResolvedValue({ lng: 31.24, lat: 30.045 }),
          getDistanceKm: jest.fn().mockResolvedValue(2.5),
        } as any,
        { add: jest.fn() } as any,
        { add: jest.fn() } as any,
        {} as any,
        {} as any,
        { countActiveUnits: jest.fn().mockResolvedValue(1) } as any,
      );

      await expect(lifecycle.handleAcceptance('disp-1', 'drv-busy')).rejects.toThrow(
        OrderErrors.DRIVER_ALREADY_ON_ORDER,
      );
      expect(releaseActiveClaim).not.toHaveBeenCalled();
    });
  });

  // ─── 8. Outbox Workflow Error Propagation, Backoff/DLQ & Replay Tracking ──

  describe('8. Outbox reliability, non-starvation & replay tracking', () => {
    it('does not mark outbox row processed when workflowDispatcher fails, and moves poison rows to DLQ without starving healthy rows', async () => {
      const dispatchQueue: any = {
        add: jest.fn().mockRejectedValueOnce(new Error('Redis dispatch timeout')).mockResolvedValue({}),
      };
      const dispatcher = new OrderWorkflowDispatcher(dispatchQueue, { add: jest.fn() } as any);
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const executeRaw = jest.fn().mockResolvedValue(1);
      const redisStore = new Map<string, string>();
      const dlq: string[] = [];
      const redis: any = {
        get: jest.fn(async (k: string) => redisStore.get(k) ?? null),
        set: jest.fn(async (k: string, v: string) => {
          redisStore.set(k, v);
        }),
        del: jest.fn(async (k: string) => {
          redisStore.delete(k);
        }),
        lpushTrim: jest.fn(async (_k: string, v: string) => {
          dlq.push(v);
        }),
      };

      const rows = [
        {
          id: 'out-poison',
          aggregateType: 'ORDER',
          aggregateId: 'ord-1',
          version: 0,
          eventType: EVENTS.ORDER_CREATED,
          jobName: EVENT_JOBS.ORDER_CREATED,
          dedupeKey: 'notify:order_created:ord-1',
          queueName: null,
          payload: { orderId: 'ord-1', orderNumber: 'OTL-1', orderType: 'RIDE' },
        },
        {
          id: 'out-healthy',
          aggregateType: 'ORDER',
          aggregateId: 'ord-2',
          version: 0,
          eventType: EVENTS.ORDER_CREATED,
          jobName: EVENT_JOBS.ORDER_CREATED,
          dedupeKey: 'notify:order_created:ord-2',
          queueName: null,
          payload: { orderId: 'ord-2', orderNumber: 'OTL-2', orderType: 'RIDE' },
        },
      ];
      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue(rows),
        $executeRaw: executeRaw,
      };
      const outbox = new OutboxService(
        { $transaction: jest.fn((cb: any) => cb(tx)) } as any,
        eventsQueue,
        dispatcher,
        redis,
      );

      // First sweep: out-poison fails workflow trigger -> NOT marked processed,
      // out-healthy succeeds immediately in the same sweep!
      const res1 = await outbox.relayPending(1);
      expect(res1.relayed).toBe(1);
      expect(executeRaw).toHaveBeenCalledTimes(1); // only out-healthy marked processed
      expect(redisStore.has('otlobegy:outbox:retry:out-poison')).toBe(true);

      // Simulate 9 prior failures so next failure hits MAX_OUTBOX_RELAY_ATTEMPTS (10) -> DLQ
      redisStore.set(
        'otlobegy:outbox:retry:out-poison',
        JSON.stringify({ attempts: 9, nextRetryAt: 0 }),
      );
      dispatchQueue.add.mockRejectedValueOnce(new Error('Persistent poison'));
      tx.$queryRaw.mockResolvedValueOnce([rows[0]]);
      executeRaw.mockClear();

      await outbox.relayPending(50);
      expect(dlq).toHaveLength(1);
      expect(executeRaw).toHaveBeenCalledTimes(1); // marked processed after DLQ
    });

    it('OrderEventsHandler preserves DB-resolved customerUserId during outbox replay tracking sync', async () => {
      const syncDriverActiveOrders = jest.fn().mockResolvedValue(undefined);
      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            customerId: 'cust-1',
            customer: { userId: 'u-cust-resolved' },
            vendorFulfillments: [],
            deliveryGroups: [],
          }),
        },
        orderDeliveryGroup: {
          findMany: jest
            .fn()
            .mockResolvedValueOnce([
              {
                status: DeliveryGroupStatus.PICKED_UP,
                primaryDriverId: 'drv-1',
                assistDriverId: null,
                primaryDriver: { userId: 'u-drv-1' },
                assistDriver: null,
              },
            ])
            .mockResolvedValueOnce([
              {
                orderId: 'ord-replay',
                order: {
                  customerId: 'cust-1',
                  customer: { userId: 'u-cust-resolved' },
                },
              },
            ]),
        },
      };
      const handler = new OrderEventsHandler(
        { emitToUser: jest.fn().mockResolvedValue(undefined) } as any,
        { create: jest.fn().mockResolvedValue(undefined) } as any,
        {} as any,
        {
          createSystemOrderConversation: jest.fn().mockResolvedValue(undefined),
          syncSystemOrderConversationParticipants: jest.fn().mockResolvedValue(undefined),
          closeSystemOrderConversation: jest.fn().mockResolvedValue(undefined),
        } as any,
        prisma,
        { syncDriverActiveOrders } as any,
      );

      // Outbox payload without customerUserId
      await handler.handleOrderStatusChanged({
        orderId: 'ord-replay',
        orderNumber: 'OTL-REP',
        oldStatus: OrderStatus.DRIVER_ASSIGNED,
        newStatus: OrderStatus.PICKED_UP,
        customerId: 'cust-1',
        customerUserId: undefined as any,
        vendorId: null,
        vendorUserIds: [],
        driverId: 'drv-1',
        driverUserId: 'u-drv-1',
        actorUserId: 'u-drv-1',
        note: null,
        revision: 3,
      } as OrderStatusChangedEvent);

      expect(syncDriverActiveOrders).toHaveBeenCalledWith('drv-1', [
        { orderId: 'ord-replay', customerUserId: 'u-cust-resolved' },
      ]);
    });
  });

  // ─── 9. OrdersRepository: clientOrderKey, COMPLETED for <=0, freeDriver, assignDriver ──

  describe('9. OrdersRepository safety guards', () => {
    it('returns existing idempotent order BEFORE checking liveActiveCount >= maxActive', async () => {
      const orderCount = jest.fn();
      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-existing',
            orderNumber: 'OTL-EXIST',
            customerId: 'cust-1',
          }),
          count: orderCount,
        },
      };
      const repo = new OrdersRepository(
        { $transaction: jest.fn((cb: any) => cb(tx)) } as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      const res = await repo.createOrder(
        {
          orderNumber: 'OTL-NEW',
          clientOrderKey: 'idem-key-1',
          type: OrderType.STANDARD,
          customerId: 'cust-1',
          paymentMethod: 'CASH_ON_DELIVERY',
          deliveryAddress: 'Addr',
          deliveryLng: 31.2,
          deliveryLat: 30.0,
          subtotal: 50,
          deliveryFee: 10,
          driverBonusFee: 0,
          serviceFee: 0,
          tax: 0,
          grandTotal: 60,
          upfrontAmount: 0,
          activeOrderPolicy: { maxActive: 1, requirePriorDelivery: true },
        },
        [],
        'u-cust-1',
      );

      expect(res).toEqual({
        id: 'ord-existing',
        orderNumber: 'OTL-EXIST',
        created: false,
      });
      expect(orderCount).not.toHaveBeenCalled();
    });

    it('freeDriver locks driver row in tx and only transitions ON_DELIVERY -> ONLINE (never un-suspending SUSPENDED)', async () => {
      const updateMany = jest.fn().mockResolvedValue({ count: 0 });
      const executeRaw = jest.fn().mockResolvedValue(1);
      const tx: any = {
        $executeRaw: executeRaw,
        driver: { updateMany },
      };
      const repo = new OrdersRepository(
        { $transaction: jest.fn((cb: any) => cb(tx)) } as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        { countActiveUnits: jest.fn().mockResolvedValue(0) } as any,
      );

      await repo.freeDriver('drv-suspended');
      expect(executeRaw).toHaveBeenCalledTimes(1);
      expect(updateMany).toHaveBeenCalledWith({
        where: { id: 'drv-suspended', status: DriverStatus.ON_DELIVERY },
        data: { status: DriverStatus.ONLINE },
      });
    });

    it('assignDriver rejects terminal DELIVERED/CANCELLED orders before mutating', async () => {
      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          findUnique: jest.fn().mockResolvedValue({
            status: OrderStatus.DELIVERED,
            orderNumber: 'OTL-DEL',
            customerId: 'c1',
            customer: { userId: 'u-c1' },
          }),
        },
      };
      const repo = new OrdersRepository(
        { $transaction: jest.fn((cb: any) => cb(tx)) } as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      await expect(
        repo.assignDriver('ord-del', 'drv-1', null, 'u-admin'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── 10. OrderRejectionRecomputor Collector Transfer & Terminal Guard ─────

  describe('10. OrderRejectionRecomputor non-Gold collector transfer & terminal order guard', () => {
    it('transfers isPaymentCollector to next active group even when goldSurchargeAmount is 0', async () => {
      const updateGroup = jest.fn().mockResolvedValue({});
      const tx: any = {
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            deliveryFee: 30,
            goldSurchargeAmount: 0,
            isPaymentCollector: true,
            sequence: 1,
            primaryDriverId: null,
            assistDriverId: null,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findFirst: jest.fn().mockResolvedValue({ id: 'grp-2' }),
          update: updateGroup,
        },
        orderDeliveryGroupItem: { count: jest.fn().mockResolvedValue(0) },
        orderDispatch: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
        orderStatusEvent: { createMany: jest.fn().mockResolvedValue({ count: 1 }) },
      };

      const recomputor = new OrderRejectionRecomputor(
        {} as any,
        {} as any,
        {} as any,
      );
      await recomputor.syncDeliveryGroupAfterVendorRemoved(
        tx,
        'ord-1',
        'grp-1',
        OrderStatus.ACCEPTED,
      );

      expect(updateGroup).toHaveBeenCalledWith({
        where: { id: 'grp-2' },
        data: { isPaymentCollector: true },
      });
    });

    it('skips recomputing totals on already CANCELLED orders', async () => {
      const orderUpdateMany = jest.fn();
      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          findUnique: jest.fn().mockResolvedValue({
            status: OrderStatus.CANCELLED,
            subtotal: 100,
          }),
          updateMany: orderUpdateMany,
        },
      };
      const recomputor = new OrderRejectionRecomputor(
        { $transaction: jest.fn((cb: any) => cb(tx)) } as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            coinValue: 1,
            amountSpentPerCoin: 10,
            driverBonusPaidByCustomer: false,
          }),
        } as any,
        {} as any,
      );

      await recomputor.recomputeTotalsAfterRejection('ord-cancelled', 50);
      expect(orderUpdateMany).not.toHaveBeenCalled();
    });
  });

  // ─── 11. Statistics, Shift Assigned, Vehicle Type, Geo Freshness, Breaks & Assist ──

  describe('11. Statistics, SHIFT_ASSIGNED, requestedVehicleType, GPS freshness, Breaks & Assist', () => {
    it('StatisticsService.recordCancellation uses distinct sourceKeys per vendorId and driverId', async () => {
      const add = jest.fn().mockResolvedValue({});
      const stats = new StatisticsService(
        {} as any,
        {} as any,
        {} as any,
        { add } as any,
      );

      await stats.recordCancellation('ord-mv', 'v-1', 'd-1');
      await stats.recordCancellation('ord-mv', 'v-2', 'd-2');

      const allSourceKeys = add.mock.calls.map((call) =>
        String(call[1]?.sourceKey ?? ''),
      );
      expect(allSourceKeys).toContain(
        `cancel:ord-mv:${STATS_JOBS.UPDATE_VENDOR}:v-1`,
      );
      expect(allSourceKeys).toContain(
        `cancel:ord-mv:${STATS_JOBS.UPDATE_VENDOR}:v-2`,
      );
      expect(allSourceKeys).toContain(
        `cancel:ord-mv:${STATS_JOBS.UPDATE_DRIVER}:d-1`,
      );
      expect(allSourceKeys).toContain(
        `cancel:ord-mv:${STATS_JOBS.UPDATE_DRIVER}:d-2`,
      );
    });

    it('ShiftListener handles EVENTS.SHIFT_ASSIGNED', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const listener = new ShiftListener(eventsQueue);

      await listener.handleShiftAssigned(
        new ShiftAssignedEvent('u-drv-shift', 'sh-99'),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'u-drv-shift',
            type: NotificationType.SYSTEM,
            data: expect.objectContaining({
              shiftId: 'sh-99',
              type: 'SHIFT_ASSIGNED',
            }),
          }),
        }),
      );
    });

    it('MailListener swallows transient mail errors, DriverAssistListener owns request/decided, and OrderListener owns vendor rejection', async () => {
      const mailListener = new MailListener({
        sendMail: jest.fn().mockRejectedValue(new Error('SMTP offline')),
      } as any);
      await expect(
        mailListener.handleOtpRequested(
          new OtpRequestedEvent('a@b.com', '123456', 'EMAIL', 'VERIFICATION'),
        ),
      ).resolves.toBeUndefined();

      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const assistListener = new DriverAssistListener(
        eventsQueue,
        { emitToUser: jest.fn().mockResolvedValue(undefined) } as any,
      );
      await assistListener.handleDriverAssistRequested(
        new DriverAssistRequestedEvent(
          'req-1',
          'u-drv-1',
          'ord-1',
          'OTL-1',
          'grp-1',
          'HEAVY',
          null,
        ),
      );
      await assistListener.handleAssistDecided(
        new DriverAssistDecidedEvent(
          'req-1',
          'u-drv-1',
          'ord-1',
          'approved',
          'u-admin',
          null,
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.DRIVER_ASSIST_REQUESTED,
        expect.objectContaining({ requestId: 'req-1' }),
        expect.any(Object),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({ userId: 'u-drv-1' }),
        }),
      );

      eventsQueue.add.mockClear();
      const orderListener = new OrderListener(
        { emitToUser: jest.fn().mockResolvedValue(undefined) } as any,
        eventsQueue,
        {} as any,
        {} as any,
      );
      await orderListener.handleOrderVendorRejected(
        new OrderVendorRejectedEvent(
          'ord-1',
          'OTL-1',
          'c-1',
          'u-c1',
          'ff-1',
          'v-1',
          'Shop A',
          'متجر أ',
          'OUT_OF_STOCK',
          'Out of stock',
          'نفذت الكمية',
          ['Burger'],
          50,
          false,
          'u-v1',
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'u-c1',
            type: NotificationType.ORDER_UPDATE,
          }),
        }),
      );
    });

    it('DispatchEventsHandler emits requestedVehicleType on dispatch.incoming', async () => {
      const emitToUser = jest.fn().mockResolvedValue(undefined);
      const handler = new DispatchEventsHandler(
        { emitToUser } as any,
        { create: jest.fn().mockResolvedValue(undefined) } as any,
        { recordDispatchSent: jest.fn().mockResolvedValue(undefined) } as any,
        {} as any,
      );

      await handler.handleDispatchSent(
        new OrderDispatchSentEvent(
          'disp-v1',
          'ord-v1',
          'OTL-V1',
          'drv-1',
          'u-drv-1',
          OrderType.RIDE,
          40,
          5,
          new Date(),
          'Pickup',
          'Dropoff',
          false,
          50,
          null,
          null,
          VehicleType.MINIBUS,
        ),
      );

      expect(emitToUser).toHaveBeenCalledWith(
        'u-drv-1',
        'dispatch.incoming',
        expect.objectContaining({
          requestedVehicleType: VehicleType.MINIBUS,
        }),
      );
    });

    it('DriverGeoSearchService filters out stale-GPS drivers and sweeps expired freshness keys', async () => {
      const queryRaw = jest.fn().mockResolvedValue([
        {
          id: 'drv-fresh',
          userId: 'u-fresh',
          tier: 'SILVER',
          vehicleType: VehicleType.CAR,
          activeShiftId: null,
          isOnDelivery: false,
        },
      ]);
      const redis: any = {
        georadius: jest.fn().mockResolvedValue([
          { member: 'drv-fresh', distanceKm: 1.0 },
          { member: 'drv-stale-gps', distanceKm: 0.5 },
        ]),
        mget: jest.fn().mockResolvedValue(['1700000000000', null]),
        zrange: jest
          .fn()
          .mockResolvedValueOnce(['drv-fresh', 'drv-stale-gps'])
          .mockResolvedValueOnce([]),
        zremMembers: jest.fn().mockResolvedValue(1),
      };
      const repo = new LocationRepository({ $queryRaw: queryRaw } as any, redis);
      const geo = new DriverGeoSearchService(repo, {
        getSettings: jest.fn().mockResolvedValue({
          driverSearchGeoCandidateLimit: 200,
          maxActiveOrdersPerDriver: 1,
        }),
      } as any);

      const found = await geo.findNearbyDrivers(
        31.25,
        30.05,
        5,
        [],
        [VehicleType.CAR],
        false,
        null,
        false,
      );
      expect(found.map((d) => d.id)).toEqual(['drv-fresh']);

      queryRaw.mockResolvedValueOnce([
        { id: 'drv-fresh' },
        { id: 'drv-stale-gps' },
      ]);
      const swept = await geo.sweepStaleDriverLocations();
      expect(swept).toEqual({ scanned: 2, removed: 1 });
      expect(redis.zremMembers).toHaveBeenCalledWith(
        'otlobegy:driver-locations',
        ['drv-stale-gps'],
      );
    });

    it('DriversRepository.findPendingDispatchForDriver detects active Redis dispatches and prunes expired ones', async () => {
      const srem = jest.fn().mockResolvedValue(1);
      const redis: any = {
        smembers: jest.fn().mockResolvedValue(['disp-expired', 'disp-live']),
        get: jest.fn().mockImplementation(async (key: string) => {
          if (key.endsWith('disp-expired')) {
            return JSON.stringify({
              expiresAt: new Date(Date.now() - 10_000).toISOString(),
              candidates: [{ driverId: 'drv-1' }],
            });
          }
          return JSON.stringify({
            expiresAt: new Date(Date.now() + 60_000).toISOString(),
            candidates: [{ driverId: 'drv-1' }],
          });
        }),
        srem,
      };
      const repo = new DriversRepository({} as any, redis);
      const pending = await repo.findPendingDispatchForDriver('drv-1');
      expect(pending).toEqual({ id: 'disp-live' });
      expect(srem).toHaveBeenCalledWith(
        'otlobegy:driver-pending-dispatches:drv-1',
        'disp-expired',
      );
    });

    it('DriverAssistMatchingService prefers fresh Redis live GPS over stale Postgres lastLocation', async () => {
      const getLiveDriverLocations = jest.fn().mockResolvedValue(
        new Map([
          ['drv-live', { lng: 31.25, lat: 30.05, isFresh: true }],
          ['drv-fallback', { lng: 0, lat: 0, isFresh: false }],
        ]),
      );
      const getPersistedDriverLocations = jest.fn().mockResolvedValue(
        new Map([['drv-fallback', { lng: 31.30, lat: 30.10 }]]),
      );
      const svc = new DriverAssistMatchingService(
        {} as any,
        {} as any,
        {} as any,
        { getLiveDriverLocations, getPersistedDriverLocations } as any,
        {} as any,
      );

      const map = await (svc as any).fetchDriverLocations([
        'drv-live',
        'drv-fallback',
      ]);
      expect(map.get('drv-live')).toEqual({ lng: 31.25, lat: 30.05 });
      expect(map.get('drv-fallback')).toEqual({ lng: 31.30, lat: 30.10 });
      expect(getPersistedDriverLocations).toHaveBeenCalledWith(['drv-fallback']);
    });
  });
});
