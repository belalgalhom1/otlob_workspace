import { BadRequestException, ForbiddenException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DispatchStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Permission,
  Role,
} from '@prisma/client';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { OrderWorkflowDispatcher } from '../../common/orders/order-workflow.dispatcher';
import { EVENTS } from '../../common/events/event-names';
import {
  EVENT_JOBS,
  ORDER_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { DispatchProcessor } from '../dispatch/dispatch.processor';
import { DispatchRepository } from '../dispatch/dispatch.repository';
import { DispatchLifecycleService } from '../dispatch/dispatch-lifecycle.service';
import { DispatchService } from '../dispatch/dispatch.service';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { StockService } from './helpers/stock.service';
import {
  ORDER_INCLUDE,
  OrderQueriesRepository,
  portionStatusFilter,
} from './repositories/order-queries.repository';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { ReviewsService } from '../reviews/reviews.service';
import {
  OrderErrors,
  ReviewErrors,
} from '../../common/constants/response.constants';

describe('Order & Dispatch Clean Architecture Units', () => {
  describe('OrderAuthorizationHelper', () => {
    it('enforces role & MANAGE_ORDERS/MANAGE_VENDORS permission rules identically', async () => {
      const findUnique = jest.fn();
      const helper = new OrderAuthorizationHelper({
        user: { findUnique },
      } as any);

      expect(await helper.canManageOrders('u1', Role.DRIVER_MANAGER)).toBe(false);
      expect(await helper.canManageOrders('u2', Role.SUPER_ADMIN)).toBe(true);
      expect(await helper.canManageOrders('u3', Role.ADMIN)).toBe(true);
      expect(findUnique).not.toHaveBeenCalled();

      findUnique.mockResolvedValueOnce({ permissions: [Permission.MANAGE_ORDERS] });
      expect(await helper.canManageOrders('u4', Role.VENDOR_MEMBER)).toBe(true);

      findUnique.mockResolvedValueOnce({ permissions: [] });
      expect(await helper.canManageOrders('u5', Role.CUSTOMER)).toBe(false);
    });
  });

  describe('OrderEarningsCalculator', () => {
    const calculator = new OrderEarningsCalculator();

    it('computes single, stacked, and multi-vendor driver shares consistently', () => {
      const settings = {
        deliveryCommissionRate: 20,
        driverManagerCommissionRate: 10,
        stackedOrderDriverPercentage: 55,
        multiVendorDeliveryCommissionRate: 15,
        multiVendorDriverManagerCommissionRate: 10,
      };

      expect(calculator.computeDriverShare(settings)).toBeCloseTo(0.7, 5);
      expect(
        calculator.computeDriverShare(settings, { isStacked: true }),
      ).toBeCloseTo(0.55, 5);
      expect(
        calculator.computeDriverShare(settings, { isMultiVendor: true }),
      ).toBeCloseTo(0.75, 5);
      expect(
        calculator.computeDriverShare(
          { ...settings, multiVendorDriverPercentage: 80 },
          { isMultiVendor: true },
        ),
      ).toBeCloseTo(0.8, 5);
    });

    it('applies Bronze tier -2 EGP fee adjustment and floors at 0', () => {
      const settings = {
        deliveryCommissionRate: 20,
        driverManagerCommissionRate: 10,
      };
      expect(
        calculator.calculateDriverEarningsForFee(50, settings, {
          driverTier: 'GOLD',
        }),
      ).toBe(35);
      expect(
        calculator.calculateDriverEarningsForFee(50, settings, {
          driverTier: 'BRONZE',
        }),
      ).toBe(34); // (50 - 2) * 0.7 = 33.6 -> 34
      expect(
        calculator.calculateDriverEarningsForFee(1, settings, {
          driverTier: 'BRONZE',
        }),
      ).toBe(0);
    });
  });

  describe('StockService', () => {
    it('aggregates strips into ceil packages on decrement and rejects concurrent sell-outs', async () => {
      const stockService = new StockService();
      const tx: any = {
        productVariant: {
          findMany: jest.fn().mockResolvedValue([{ id: 'var-1', tracksStock: true }]),
        },
        product: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'prod-1',
              tracksStock: true,
              sellByStrip: true,
              stripsPerPackage: 3,
            },
          ]),
        },
        $executeRaw: jest.fn().mockResolvedValue(1),
      };

      await stockService.decrementForItems(tx, [
        { productId: 'prod-1', variantId: 'var-1', quantity: 2, selectedUnit: null },
        { productId: 'prod-1', variantId: null, quantity: 4, selectedUnit: 'strip' },
        { productId: 'prod-1', variantId: null, quantity: 1, selectedUnit: 'package' },
      ]);

      // 2 raw updates: variant qty=2 and product qty = ceil(4/3) + 1 = 3
      expect(tx.$executeRaw).toHaveBeenCalledTimes(2);
      expect(tx.$executeRaw.mock.calls[0]).toContain(2);
      expect(tx.$executeRaw.mock.calls[1]).toContain(3);

      tx.$executeRaw.mockResolvedValueOnce(0);
      await expect(
        stockService.decrementForItems(tx, [
          { productId: 'prod-1', variantId: 'var-1', quantity: 1, selectedUnit: null },
        ]),
      ).rejects.toThrow(BadRequestException);
    });

    it('restores tracked variant and strip-normalized product stock cleanly', async () => {
      const stockService = new StockService();
      const tx: any = {
        productVariant: { findMany: jest.fn().mockResolvedValue([]) },
        product: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'prod-2',
              tracksStock: true,
              sellByStrip: true,
              stripsPerPackage: 2,
            },
          ]),
        },
        $executeRaw: jest.fn().mockResolvedValue(1),
      };

      await stockService.restoreForItems(tx, [
        { productId: 'prod-2', variantId: null, quantity: 3, selectedUnit: 'strip' },
      ]);

      expect(tx.$executeRaw).toHaveBeenCalledTimes(1);
      expect(tx.$executeRaw.mock.calls[0]).toContain(2); // ceil(3/2)
    });
  });

  describe('OrderCancellationService', () => {
    it('enforces actor restrictions and emits ORDER_CANCELLED with all group drivers', async () => {
      const mockRepo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-1',
          orderNumber: 'OTL-10',
          status: OrderStatus.PENDING,
          coinsUsed: 0,
          customerId: 'cust-1',
          vendorId: null,
          driverId: null,
          customer: { userId: 'u-cust' },
        }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue(['u-v1']),
        cancelOrder: jest.fn().mockResolvedValue({
          revision: 2,
          driver: null,
          customer: { user: { id: 'u-cust' } },
        }),
      };
      const mockPrisma: any = {
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            { primaryDriverId: 'd-1', assistDriverId: 'd-2' },
          ]),
        },
      };
      const mockEmitter: any = { emit: jest.fn() };
      const svc = new OrderCancellationService(
        mockRepo,
        mockPrisma,
        new OrderAuthorizationHelper(mockPrisma),
        mockEmitter,
      );

      await expect(
        svc.cancelOrder({ sub: 'u-d', role: Role.DRIVER } as any, 'ord-1', 'reason'),
      ).rejects.toThrow(ForbiddenException);

      await svc.cancelOrder({ sub: 'u-cust', role: Role.CUSTOMER } as any, 'ord-1', 'Changed mind');
      expect(mockRepo.cancelOrder).toHaveBeenCalledWith(
        'ord-1',
        'u-cust',
        'Changed mind',
        OrderStatus.PENDING,
        0,
        'cust-1',
        'OTL-10',
        ['d-1', 'd-2'],
      );
      expect(mockEmitter.emit).toHaveBeenCalledWith(
        EVENTS.ORDER_CANCELLED,
        expect.objectContaining({
          orderId: 'ord-1',
          driverIds: ['d-1', 'd-2'],
          revision: 2,
        }),
      );
    });
  });

  describe('FulfillmentTransitionService & DeliveryGroupTransitionService', () => {
    it('marks delivery group READY_FOR_PICKUP once remaining portion is ready', async () => {
      const mockPrisma: any = {
        orderVendorFulfillment: {
          findMany: jest.fn().mockResolvedValue([
            { status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP, readyAt: new Date() },
            { status: OrderVendorFulfillmentStatus.REJECTED, readyAt: null },
          ]),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              status: DeliveryGroupStatus.READY_FOR_PICKUP,
              primaryDriverId: 'd1',
              isPaymentCollector: true,
            },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            orderNumber: 'OTL-77',
            status: OrderStatus.DRIVER_ASSIGNED,
            revision: 3,
            customerId: 'c1',
            customer: { userId: 'uc1' },
            vendorFulfillments: [{ vendorId: 'v1' }],
          }),
        },
      };
      const mockRepo: any = {
        updateStatus: jest.fn().mockResolvedValue({ revision: 4 }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue(['uv1']),
      };
      const mockEmitter: any = { emit: jest.fn() };
      const groupSvc = new DeliveryGroupTransitionService(
        mockPrisma,
        mockRepo,
        mockEmitter,
      );
      const fulfillmentSvc = new FulfillmentTransitionService(
        mockPrisma,
        mockRepo,
        {} as any,
        mockEmitter,
        groupSvc,
      );

      await fulfillmentSvc.syncGroupReadinessAfterPortionRemoved(
        'ord-77',
        'grp-1',
        'u-actor',
      );

      expect(mockPrisma.orderDeliveryGroup.updateMany).toHaveBeenCalled();
      expect(mockRepo.updateStatus).toHaveBeenCalledWith(
        'ord-77',
        OrderStatus.READY_FOR_PICKUP,
        'u-actor',
        'All vendor portions ready for pickup',
        undefined,
        OrderStatus.DRIVER_ASSIGNED,
      );
      expect(mockEmitter.emit).toHaveBeenCalledWith(
        EVENTS.ORDER_STATUS_CHANGED,
        expect.objectContaining({
          orderId: 'ord-77',
          newStatus: OrderStatus.READY_FOR_PICKUP,
        }),
      );
    });
  });

  describe('OrderWorkflowDispatcher, OutboxService, and DispatchProcessor boundaries', () => {
    it('routes workflow jobs to QUEUES.DISPATCH and QUEUES.ORDERS and recovers from outbox', async () => {
      const dispatchQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const ordersQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const dispatcher = new OrderWorkflowDispatcher(dispatchQueue, ordersQueue);

      await dispatcher.triggerForOutboxRow(EVENTS.ORDER_STATUS_CHANGED, {
        orderId: 'o1',
        orderNumber: 'OTL-1',
        newStatus: OrderStatus.LOOKING_FOR_DRIVER,
        revision: 1,
      });
      expect(dispatchQueue.add).toHaveBeenCalledWith(
        ORDER_JOBS.DISPATCH_HANDOFF,
        { orderId: 'o1', orderNumber: 'OTL-1' },
        expect.objectContaining({ attempts: 3 }),
      );

      await dispatcher.triggerForOutboxRow(EVENTS.ORDER_STATUS_CHANGED, {
        orderId: 'o2',
        orderNumber: 'OTL-2',
        newStatus: OrderStatus.DELIVERED,
        revision: 5,
      });
      expect(ordersQueue.add).toHaveBeenCalledWith(
        ORDER_JOBS.SETTLE,
        { orderId: 'o2', orderNumber: 'OTL-2' },
        expect.objectContaining({ attempts: 3 }),
      );

      await dispatcher.onDispatchResponded({
        dispatchId: 'disp-1',
        driverId: 'drv-1',
        status: DispatchStatus.ACCEPTED,
      });
      expect(dispatchQueue.add).toHaveBeenCalledWith(
        ORDER_JOBS.DISPATCH_CLEANUP_EXPIRY,
        { dispatchId: 'disp-1' },
        expect.objectContaining({ attempts: 3 }),
      );
    });

    it('OutboxService.relayPending enqueues both eventsQueue fan-out and ORDER workflow triggers', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const dispatchQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const ordersQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const dispatcher = new OrderWorkflowDispatcher(dispatchQueue, ordersQueue);
      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue([
          {
            id: 'out-1',
            aggregateType: 'ORDER',
            aggregateId: 'ord-1',
            version: 0,
            eventType: EVENTS.ORDER_CREATED,
            jobName: 'order.created',
            dedupeKey: 'notify:order_created:ord-1',
            queueName: QUEUES.EVENTS,
            payload: {
              orderId: 'ord-1',
              orderNumber: 'OTL-C1',
              orderType: 'CUSTOM_DELIVERY',
            },
          },
        ]),
        $executeRaw: jest.fn().mockResolvedValue(1),
      };
      const prisma: any = { $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))) };
      const outbox = new OutboxService(prisma, eventsQueue, dispatcher);

      const res = await outbox.relayPending();
      expect(res.relayed).toBe(1);
      expect(eventsQueue.add).toHaveBeenCalledTimes(1);
      expect(dispatchQueue.add).toHaveBeenCalledWith(
        ORDER_JOBS.DISPATCH_HANDOFF,
        { orderId: 'ord-1', orderNumber: 'OTL-C1' },
        expect.any(Object),
      );
    });

    it('DispatchProcessor uses DispatchOrderWorkflowPort and enqueues CANCEL_ORDER on max attempts', async () => {
      const orderWorkflowPort = {
        transitionAcceptedOrderToSearching: jest.fn().mockResolvedValue(undefined),
        handleUndispatchableDeliveryGroup: jest
          .fn()
          .mockResolvedValue({ groupCancelled: false, orderCancelled: false }),
      };
      const workflowDispatcher: any = {
        enqueueCancelOrder: jest.fn().mockResolvedValue(undefined),
      };
      const queue: any = {
        add: jest.fn().mockResolvedValue({}),
        getJob: jest.fn().mockResolvedValue({ remove: jest.fn() }),
      };
      const processor = new DispatchProcessor(
        { attemptDispatch: jest.fn() } as any,
        {
          isHandoffDeduped: jest.fn().mockResolvedValue(false),
          markHandoffDeduped: jest.fn().mockResolvedValue(undefined),
        } as any,
        orderWorkflowPort,
        workflowDispatcher,
        { getSettings: jest.fn().mockResolvedValue({ driverSearchMaxAttempts: 3 }) } as any,
        {
          order: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'ord-9',
              status: OrderStatus.ACCEPTED,
            }),
          },
          orderDeliveryGroup: { findMany: jest.fn().mockResolvedValue([]) },
        } as any,
        { sweepStaleDriverLocations: jest.fn() } as any,
        queue,
      );

      await processor.process({
        id: 'job-1',
        name: ORDER_JOBS.DISPATCH,
        data: { orderId: 'ord-9', orderNumber: 'OTL-9', attempt: 4 },
      } as any);

      expect(
        orderWorkflowPort.transitionAcceptedOrderToSearching,
      ).toHaveBeenCalledWith('ord-9');
      expect(workflowDispatcher.enqueueCancelOrder).toHaveBeenCalledWith(
        'ord-9',
        'Auto-cancelled: No drivers accepted the order after maximum attempts',
      );
    });

    it('DispatchService.handleAcceptance triggers immediate workflowDispatcher cancellation and outbox completion', async () => {
      const dispatchData = {
        orderId: 'ord-acc-1',
        type: 'STANDARD',
        expiresAt: new Date(Date.now() + 60_000).toISOString(),
        candidates: [
          {
            driverId: 'drv-1',
            userId: 'u-drv-1',
            driverShiftId: null,
            deliveryGroupId: 'grp-acc-1',
            distanceKm: 1.5,
            estimatedEarnings: 25,
          },
        ],
      };

      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue([{ id: 'drv-1' }]),
        orderDeliveryGroup: {
          count: jest.fn().mockResolvedValue(0),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        order: {
          count: jest.fn().mockResolvedValue(0),
          update: jest.fn().mockResolvedValue({ revision: 2 }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({ revision: 2 }),
        },
        orderDispatch: { create: jest.fn().mockResolvedValue({}) },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
        driver: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      };

      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-acc-1',
            orderNumber: 'OTL-88',
            status: OrderStatus.LOOKING_FOR_DRIVER,
            paymentMethod: 'CASH_ON_DELIVERY',
            upfrontAmount: 0,
            paymentStatus: 'PENDING',
            customerId: 'cust-1',
            distanceKm: 3.2,
            customer: { userId: 'u-cust-1' },
            deliveryGroups: [
              {
                id: 'grp-acc-1',
                status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                primaryDriverId: null,
              },
            ],
            vendorFulfillments: [
              {
                vendorId: 'ven-1',
                status: 'ACCEPTED',
                groups: [{ deliveryGroupId: 'grp-acc-1' }],
              },
            ],
          }),
        },
        orderVendorFulfillment: {
          findMany: jest
            .fn()
            .mockResolvedValue([{ vendorId: 'ven-1', vendorBranchId: 'br-1' }]),
        },
        vendorMember: {
          findMany: jest.fn().mockResolvedValue([{ userId: 'u-ven-1' }]),
        },
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
      };

      const redis: any = {
        get: jest.fn().mockResolvedValue(JSON.stringify(dispatchData)),
        smembers: jest.fn().mockResolvedValue([]),
        del: jest.fn().mockResolvedValue(1),
        delIfValue: jest.fn().mockResolvedValue(true),
        srem: jest.fn().mockResolvedValue(1),
      };

      const locationRepo: any = {
        getOrderLocationContext: jest.fn().mockResolvedValue({
          lng: 31.2,
          lat: 30.0,
          deliveryLng: 31.25,
          deliveryLat: 30.05,
        }),
        getDeliveryGroupPickupLocation: jest
          .fn()
          .mockResolvedValue({ lng: 31.2, lat: 30.0 }),
        getDistanceKm: jest.fn().mockResolvedValue(3.2),
      };

      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const outbox: any = {
        record: jest.fn().mockResolvedValue({}),
        markProcessed: jest.fn().mockResolvedValue(undefined),
      };
      const workflowDispatcher: any = {
        onOrderStatusChanged: jest.fn().mockResolvedValue(undefined),
      };

      const settingsSvc: any = {
        getSettings: jest.fn().mockResolvedValue({ maxActiveOrdersPerDriver: 1 }),
      };
      const emitter: any = { emit: jest.fn() };
      const dispatchQueue: any = { add: jest.fn() };
      const dispatchRepo = new DispatchRepository(prisma, redis);
      const lifecycle = new DispatchLifecycleService(
        dispatchRepo,
        settingsSvc,
        emitter,
        prisma,
        locationRepo,
        dispatchQueue,
        eventsQueue,
        outbox,
        workflowDispatcher,
        new DriverWorkloadHelper(),
      );
      const service = new DispatchService(
        dispatchRepo,
        lifecycle,
        settingsSvc,
        emitter,
        prisma,
        locationRepo,
        { findNearbyDrivers: jest.fn() } as any,
        new OrderEarningsCalculator(settingsSvc),
        dispatchQueue,
      );

      await expect(service.handleAcceptance('disp-acc-1', 'drv-1')).resolves.toBe(
        true,
      );

      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.ORDER_STATUS_CHANGED,
        expect.objectContaining({
          orderId: 'ord-acc-1',
          newStatus: OrderStatus.DRIVER_ASSIGNED,
          revision: 2,
        }),
        expect.objectContaining({ attempts: 3 }),
      );
      expect(workflowDispatcher.onOrderStatusChanged).toHaveBeenCalledWith(
        expect.objectContaining({
          orderId: 'ord-acc-1',
          newStatus: OrderStatus.DRIVER_ASSIGNED,
          revision: 2,
        }),
      );
      expect(outbox.markProcessed).toHaveBeenCalledWith('ORDER', 'ord-acc-1', 2);
    });

    it('DispatchService.resolveDispatchTarget queries group items/fulfillment and prefetches totalGroupsCount in parallel', async () => {
      const orderFindUnique = jest.fn().mockResolvedValue({
        id: 'ord-disp-1',
        orderNumber: 'OTL-DISP-1',
        type: 'STANDARD',
        status: OrderStatus.PARTIALLY_PICKED_UP,
        paymentMethod: 'CASH_ON_DELIVERY',
        deliveryAddress: 'Nasr City',
        subtotal: 200,
        deliveryFee: 30,
        deliveryCommissionRate: null,
        grandTotal: 230,
        isStacked: false,
        distanceKm: 4.5,
        vendorId: null,
        vendorBranchId: null,
        vendor: null,
        vendorBranch: null,
      });
      const groupCount = jest.fn().mockResolvedValue(2);
      const groupFindUnique = jest.fn().mockResolvedValue({
        id: 'grp-disp-1',
        orderId: 'ord-disp-1',
        sequence: 1,
        status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
        primaryDriverId: null,
        deliveryFee: 20,
        distanceKm: 3.1,
        isStacked: false,
        isPaymentCollector: true,
        items: [
          {
            sequence: 1,
            fulfillment: {
              id: 'ff-1',
              vendorId: 'v-1',
              subtotal: 120,
              vendor: { id: 'v-1', storeName: 'V1', storeNameAr: 'م1', zoneId: 'z1' },
              vendorBranch: { id: 'b-1', name: 'B1', nameAr: 'ف1', zoneId: 'z1' },
            },
          },
        ],
      });

      const prisma: any = {
        order: { findUnique: orderFindUnique },
        orderDeliveryGroup: { count: groupCount, findUnique: groupFindUnique },
      };

      const settingsSvc: any = {
        getSettings: jest.fn().mockResolvedValue({ deliveryCommissionRate: 20 }),
      };
      const service = new DispatchService(
        {} as any,
        {} as any,
        settingsSvc,
        { emit: jest.fn() } as any,
        prisma,
        {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            lng: 31.2,
            lat: 30.0,
            deliveryLng: 31.25,
            deliveryLat: 30.05,
          }),
          getDeliveryGroupPickupLocation: jest
            .fn()
            .mockResolvedValue({ lng: 31.21, lat: 30.01 }),
          getDistanceKm: jest.fn(),
        } as any,
        { findNearbyDrivers: jest.fn() } as any,
        new OrderEarningsCalculator(settingsSvc),
        { add: jest.fn() } as any,
      );

      const target = await (service as any).resolveDispatchTarget(
        'ord-disp-1',
        'OTL-DISP-1',
        'grp-disp-1',
      );

      expect(target).not.toBeNull();
      expect(target.totalGroupsCount).toBe(2);
      expect(target.group.distanceKm).toBe(3.1);
      expect(groupCount).toHaveBeenCalledTimes(1);
      const selectArg = groupFindUnique.mock.calls[0][0].select;
      expect(selectArg.items).toBeDefined();
      expect(selectArg.fulfillments).toBeUndefined();
      expect(selectArg.stopSequence).toBeUndefined();
    });
  });

  describe('OrderQueriesRepository filters, cancellation recompute, and ReviewsService guards', () => {
    it('keeps ACCEPTED and LOOKING_FOR_DRIVER portionStatusFilter mutually exclusive and hydrates driver tier', () => {
      const acceptedFilter = portionStatusFilter(OrderStatus.ACCEPTED);
      expect(acceptedFilter.order).toEqual({
        status: { not: OrderStatus.LOOKING_FOR_DRIVER },
      });
      expect(
        (acceptedFilter.groups as any).none.deliveryGroup.status.in,
      ).toEqual(
        expect.arrayContaining([
          DeliveryGroupStatus.PARTIALLY_PICKED_UP,
          DeliveryGroupStatus.PICKED_UP,
          DeliveryGroupStatus.DELIVERED,
        ]),
      );

      const lookingFilter = portionStatusFilter(OrderStatus.LOOKING_FOR_DRIVER);
      const orderLevelBranch = (lookingFilter.OR as any[])[0];
      expect(orderLevelBranch.groups.none.deliveryGroup.status.in).toEqual(
        expect.arrayContaining([
          DeliveryGroupStatus.DRIVER_ASSIGNED,
          DeliveryGroupStatus.PARTIALLY_PICKED_UP,
          DeliveryGroupStatus.PICKED_UP,
        ]),
      );
      expect(ORDER_INCLUDE.deliveryGroups.include.primaryDriver.select.tier).toBe(
        true,
      );
    });

    it('recomputes pre-pickup order status & re-elects payment collector in transaction after group cancel', async () => {
      const groupUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
      const freeDriver = jest.fn().mockResolvedValue(undefined);
      const orderRepo = {
        freeDriver,
        updateStatus: jest.fn().mockResolvedValue({ revision: 5 }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue(['uv-1']),
      };
      const emitter = { emit: jest.fn() };

      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-c-1',
            orderNumber: 'OTL-C-1',
            status: OrderStatus.LOOKING_FOR_DRIVER,
            customerId: 'c1',
            customer: { userId: 'uc1' },
            vendorId: null,
            vendorFulfillments: [{ vendorId: 'v1' }],
          }),
        },
        orderVendorFulfillment: {
          updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.CANCELLED,
              primaryDriverId: 'd1',
              assistDriverId: null,
              isPaymentCollector: false,
            },
            {
              id: 'grp-2',
              sequence: 2,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              primaryDriverId: 'd2',
              assistDriverId: null,
              isPaymentCollector: false,
            },
          ]),
          updateMany: groupUpdateMany,
        },
        $transaction: jest.fn((ops: Promise<any>[]) => Promise.all(ops)),
      };

      const repoQuery = new OrderQueriesRepository({} as any);
      expect(repoQuery).toBeDefined();

      const groupSvc = new DeliveryGroupTransitionService(
        prisma,
        orderRepo as any,
        emitter as any,
      );

      await groupSvc.recomputeGroupedOrderStatusAfterCancel('ord-c-1', ['d1']);

      expect(groupUpdateMany).toHaveBeenCalledWith({
        where: { orderId: 'ord-c-1', id: { not: 'grp-2' } },
        data: { isPaymentCollector: false },
      });
      expect(groupUpdateMany).toHaveBeenCalledWith({
        where: { id: 'grp-2' },
        data: { isPaymentCollector: true },
      });
      expect(freeDriver).toHaveBeenCalledWith('d1');
      expect(orderRepo.updateStatus).toHaveBeenCalledWith(
        'ord-c-1',
        OrderStatus.DRIVER_ASSIGNED,
        'system',
        expect.any(String),
        undefined,
        OrderStatus.LOOKING_FOR_DRIVER,
      );
      expect(emitter.emit).toHaveBeenCalledWith(
        EVENTS.ORDER_STATUS_CHANGED,
        expect.objectContaining({
          orderId: 'ord-c-1',
          newStatus: OrderStatus.DRIVER_ASSIGNED,
          revision: 5,
        }),
      );
    });

    it('ReviewsService rejects missing eligible fulfillments with INVALID_TRANSITION and translates P2002 to ALREADY_RATED', async () => {
      const baseOrder = {
        id: 'ord-rev-1',
        status: OrderStatus.DELIVERED,
        customerId: 'cust-1',
        vendorId: 'v-1',
        driverId: 'd-1',
        vendorFulfillments: [] as any[],
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: DeliveryGroupStatus.DELIVERED,
            primaryDriverId: 'd-1',
          },
        ],
        reviews: [],
      };
      const createMany = jest
        .fn()
        .mockRejectedValue(Object.assign(new Error('Unique'), { code: 'P2002' }));

      const prisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'cust-1' }) },
        order: { findFirst: jest.fn().mockResolvedValue(baseOrder) },
        orderReview: { createMany },
      };

      const reviewsSvc = new ReviewsService(prisma, { emit: jest.fn() } as any);

      await expect(
        reviewsSvc.submitReview(
          { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
          'ord-rev-1',
          { vendorRating: 5 } as any,
        ),
      ).rejects.toThrow(OrderErrors.INVALID_TRANSITION);

      baseOrder.vendorFulfillments = [
        {
          id: 'ff-1',
          vendorId: 'v-1',
          status: OrderVendorFulfillmentStatus.PICKED_UP,
          deliveredAt: new Date(),
        },
      ];

      await expect(
        reviewsSvc.submitReview(
          { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
          'ord-rev-1',
          { vendorRating: 5 } as any,
        ),
      ).rejects.toThrow(ReviewErrors.ALREADY_RATED);
    });
  });
});
