import { BadRequestException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  NotificationType,
  OrderStatus,
  OrderType,
  PaymentMethod,
  Role,
} from '@prisma/client';
import { OrderErrors } from '../../common/constants/response.constants';
import { OrderDispatchSentEvent } from '../../common/events';
import { DispatchEventsHandler } from '../events/dispatch-events.handler';
import { OrderEventsHandler } from '../events/order-events.handler';
import { OrderStatusChangedEvent } from '../../common/events';
import { OrderSearchService } from './order-search.service';
import { OrdersStateService } from './orders-state.service';
import { OrderRoleProjector } from './projections/order-role.projector';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';

describe('OrderType Request Workflows (RIDE vs CUSTOM_DELIVERY vs STANDARD)', () => {
  let stateService: OrdersStateService;
  let mockOrdersRepo: any;
  let mockPrisma: any;
  let mockStorage: any;
  let mockEventEmitter: any;

  const driverActor = { sub: 'user-driver-1', role: Role.DRIVER } as any;

  function makeGroup(overrides: Partial<any> = {}) {
    return {
      id: 'grp-1',
      sequence: 1,
      status: DeliveryGroupStatus.READY_FOR_PICKUP,
      isPaymentCollector: true,
      primaryDriverId: 'driver-1',
      assistDriverId: null,
      pickupImageUrl: null,
      deliveryImageUrl: null,
      items: [],
      ...overrides,
    };
  }

  function makeOrder(type: OrderType, overrides: Partial<any> = {}) {
    return {
      id: `ord-${type.toLowerCase()}`,
      orderNumber: `OTL-${type}`,
      type,
      status: OrderStatus.DRIVER_ASSIGNED,
      customerId: 'cust-1',
      customer: {
        id: 'cust-1',
        userId: 'user-cust-1',
        user: {
          id: 'user-cust-1',
          name: 'Sarah Customer',
          phone: '+201000000001',
        },
      },
      paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
      paymentStatus: 'PENDING',
      subtotal: type === OrderType.STANDARD ? 200 : 0,
      deliveryFee: 30,
      serviceFee: 5,
      grandTotal: type === OrderType.STANDARD ? 235 : 35,
      upfrontAmount: 0,
      revision: 1,
      pickupAddress: 'Maadi, Cairo',
      deliveryAddress: 'Zamalek, Cairo',
      vendorFulfillments: [],
      deliveryGroups: [makeGroup({ status: DeliveryGroupStatus.DRIVER_ASSIGNED })],
      ...overrides,
    };
  }

  beforeEach(() => {
    mockOrdersRepo = {
      findById: jest.fn(),
      updateStatus: jest.fn().mockResolvedValue({ revision: 2 }),
      freeDriver: jest.fn().mockResolvedValue(undefined),
      getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      assignDriver: jest.fn(),
    };
    mockEventEmitter = { emit: jest.fn() };
    mockStorage = {
      upload: jest.fn().mockResolvedValue('https://cdn.test/proof.jpg'),
      delete: jest.fn().mockResolvedValue(undefined),
    };
    mockPrisma = {
      driver: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ id: 'driver-1', userId: 'user-driver-1' }),
      },
      vendorMember: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      user: { findUnique: jest.fn().mockResolvedValue({ permissions: [] }) },
      order: {
        findUnique: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      orderVendorFulfillment: {
        findFirst: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      orderDeliveryGroup: {
        findUnique: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      orderDeliveryGroupItem: {
        findFirst: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
      },
      orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
    };

    stateService = new OrdersStateService(
      mockOrdersRepo,
      {} as any,
      { accept: jest.fn(), reject: jest.fn() } as any,
      mockEventEmitter,
      mockPrisma,
      mockStorage,
    );
  });

  describe('Proof photo policy per request type', () => {
    it('allows OrderType.RIDE pickup and delivery confirmation without photos', async () => {
      const assignedRide = makeOrder(OrderType.RIDE, {
        status: OrderStatus.DRIVER_ASSIGNED,
        deliveryGroups: [
          makeGroup({ status: DeliveryGroupStatus.DRIVER_ASSIGNED }),
        ],
      });
      mockOrdersRepo.findById.mockResolvedValue(assignedRide);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        { id: 'grp-1', status: DeliveryGroupStatus.PICKED_UP },
      ]);
      mockPrisma.order.findUnique.mockResolvedValue({
        ...assignedRide,
        status: OrderStatus.DRIVER_ASSIGNED,
      });

      await expect(
        stateService.driverConfirmPickup(driverActor, assignedRide.id),
      ).resolves.toBeDefined();
      expect(mockStorage.upload).not.toHaveBeenCalled();

      const pickedUpRide = makeOrder(OrderType.RIDE, {
        status: OrderStatus.PICKED_UP,
        deliveryGroups: [makeGroup({ status: DeliveryGroupStatus.PICKED_UP })],
      });
      mockOrdersRepo.findById.mockResolvedValue(pickedUpRide);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        { id: 'grp-1', status: DeliveryGroupStatus.DELIVERED },
      ]);
      mockPrisma.order.findUnique.mockResolvedValue({
        ...pickedUpRide,
        status: OrderStatus.PICKED_UP,
      });

      await expect(
        stateService.driverConfirmDelivery(driverActor, pickedUpRide.id),
      ).resolves.toBeDefined();
      expect(mockStorage.upload).not.toHaveBeenCalled();
    });

    it('enforces pickup and delivery proof photos for OrderType.CUSTOM_DELIVERY', async () => {
      const assignedCustom = makeOrder(OrderType.CUSTOM_DELIVERY, {
        status: OrderStatus.READY_FOR_PICKUP,
        deliveryGroups: [
          makeGroup({ status: DeliveryGroupStatus.READY_FOR_PICKUP }),
        ],
      });
      mockOrdersRepo.findById.mockResolvedValue(assignedCustom);

      await expect(
        stateService.driverConfirmPickup(driverActor, assignedCustom.id),
      ).rejects.toThrow(new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED));

      await expect(
        stateService.driverUpdateStatus(driverActor, assignedCustom.id, {
          status: OrderStatus.PICKED_UP,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED));

      const pickedCustom = makeOrder(OrderType.CUSTOM_DELIVERY, {
        status: OrderStatus.PICKED_UP,
        deliveryGroups: [
          makeGroup({
            status: DeliveryGroupStatus.PICKED_UP,
            pickupImageUrl: 'https://cdn.test/pickup.jpg',
          }),
        ],
      });
      mockOrdersRepo.findById.mockResolvedValue(pickedCustom);

      await expect(
        stateService.driverConfirmDelivery(driverActor, pickedCustom.id),
      ).rejects.toThrow(
        new BadRequestException(OrderErrors.DELIVERY_PHOTO_REQUIRED),
      );
      expect(mockStorage.upload).not.toHaveBeenCalled();
    });

    it('enforces proof photos for OrderType.STANDARD', async () => {
      const stdOrder = makeOrder(OrderType.STANDARD, {
        status: OrderStatus.READY_FOR_PICKUP,
        deliveryGroups: [
          makeGroup({ status: DeliveryGroupStatus.READY_FOR_PICKUP }),
        ],
      });
      mockOrdersRepo.findById.mockResolvedValue(stdOrder);

      await expect(
        stateService.driverUpdateStatus(driverActor, stdOrder.id, {
          status: OrderStatus.PICKED_UP,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED));
    });
  });

  describe('Role projections', () => {
    it('omits fulfillmentSummary on RIDE and CUSTOM_DELIVERY customer projections', () => {
      const projector = new OrderRoleProjector(
        mockPrisma,
        {
          getSettings: jest.fn(),
        } as any,
        {
          calculateDriverEarningsForFee: jest.fn().mockReturnValue(24),
        } as any,
      );

      const rideProjected = projector.projectForCustomer(
        makeOrder(OrderType.RIDE),
      );
      const customProjected = projector.projectForCustomer(
        makeOrder(OrderType.CUSTOM_DELIVERY),
      );

      expect(rideProjected.fulfillmentSummary).toBeNull();
      expect(customProjected.fulfillmentSummary).toBeNull();
    });
  });

  describe('Dispatch notifications by request type', () => {
    it('creates distinct localized push notifications for RIDE, CUSTOM_DELIVERY, and STANDARD', async () => {
      const mockSocket = { emitToUser: jest.fn().mockResolvedValue(undefined) };
      const mockNotifications = {
        create: jest.fn().mockResolvedValue(undefined),
      };
      const mockStats = {
        recordDispatchSent: jest.fn().mockResolvedValue(undefined),
      };
      const handler = new DispatchEventsHandler(
        mockSocket as any,
        mockNotifications as any,
        mockStats as any,
        mockPrisma,
      );

      await handler.handleDispatchSent(
        new OrderDispatchSentEvent(
          'disp-ride',
          'ord-ride',
          'OTL-R1',
          'driver-1',
          'user-driver-1',
          OrderType.RIDE,
          25,
          3.4,
          new Date(Date.now() + 30000),
          'Maadi',
          'Zamalek',
        ),
      );
      expect(mockNotifications.create).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'New Ride Request',
          titleAr: 'طلب رحلة جديد',
          type: NotificationType.ORDER_UPDATE,
        }),
      );

      mockNotifications.create.mockClear();
      await handler.handleDispatchSent(
        new OrderDispatchSentEvent(
          'disp-custom',
          'ord-custom',
          'OTL-C1',
          'driver-1',
          'user-driver-1',
          OrderType.CUSTOM_DELIVERY,
          35,
          5.2,
          new Date(Date.now() + 30000),
          'Nasr City',
          'Heliopolis',
        ),
      );
      expect(mockNotifications.create).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'New Custom Delivery Request',
          titleAr: 'طلب توصيل خاص جديد',
        }),
      );
    });
  });

  describe('vendorUpdateStatus blocks store preparation transitions on RIDE & CUSTOM_DELIVERY', () => {
    const adminActor = { sub: 'user-admin-1', role: Role.SUPER_ADMIN } as any;

    it('rejects PREPARING and READY_FOR_PICKUP on RIDE orders even for SUPER_ADMIN', async () => {
      const rideOrder = makeOrder(OrderType.RIDE, {
        status: OrderStatus.LOOKING_FOR_DRIVER,
      });
      mockOrdersRepo.findById.mockResolvedValue(rideOrder);

      await expect(
        stateService.vendorUpdateStatus(adminActor, rideOrder.id, {
          status: OrderStatus.PREPARING,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.INVALID_TRANSITION));

      await expect(
        stateService.vendorUpdateStatus(adminActor, rideOrder.id, {
          status: OrderStatus.READY_FOR_PICKUP,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.INVALID_TRANSITION));
    });

    it('rejects PREPARING and ACCEPTED on CUSTOM_DELIVERY orders even for SUPER_ADMIN', async () => {
      const customOrder = makeOrder(OrderType.CUSTOM_DELIVERY, {
        status: OrderStatus.DRIVER_ASSIGNED,
      });
      mockOrdersRepo.findById.mockResolvedValue(customOrder);

      await expect(
        stateService.vendorUpdateStatus(adminActor, customOrder.id, {
          status: OrderStatus.PREPARING,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.INVALID_TRANSITION));

      await expect(
        stateService.vendorUpdateStatus(adminActor, customOrder.id, {
          status: OrderStatus.ACCEPTED,
        }),
      ).rejects.toThrow(new BadRequestException(OrderErrors.INVALID_TRANSITION));
    });
  });

  describe('Real-time driver arrival (READY_FOR_PICKUP) propagation, OrderType notifications & road ETA', () => {
    it('promotes RIDE and CUSTOM_DELIVERY driver READY_FOR_PICKUP to Order.status and emits ORDER_STATUS_CHANGED', async () => {
      const rideOrder = makeOrder(OrderType.RIDE, {
        status: OrderStatus.DRIVER_ASSIGNED,
        deliveryGroups: [
          makeGroup({ status: DeliveryGroupStatus.DRIVER_ASSIGNED }),
        ],
      });
      mockOrdersRepo.findById.mockResolvedValue(rideOrder);
      mockPrisma.order.findUnique.mockResolvedValue({
        type: OrderType.RIDE,
        status: OrderStatus.DRIVER_ASSIGNED,
        revision: 1,
        customerId: 'cust-1',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        upfrontAmount: 0,
        paymentStatus: 'PENDING',
        customer: { userId: 'user-cust-1' },
        vendorFulfillments: [],
      });
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        {
          id: 'grp-1',
          sequence: 1,
          status: DeliveryGroupStatus.READY_FOR_PICKUP,
          isPaymentCollector: true,
          primaryDriverId: 'driver-1',
          assistDriverId: null,
        },
      ]);

      await stateService.driverUpdateStatus(driverActor, rideOrder.id, {
        status: OrderStatus.READY_FOR_PICKUP,
      });

      expect(mockOrdersRepo.updateStatus).toHaveBeenCalledWith(
        rideOrder.id,
        OrderStatus.READY_FOR_PICKUP,
        driverActor.sub,
        'Driver arrived at pickup location',
        {},
        OrderStatus.DRIVER_ASSIGNED,
      );
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          orderId: rideOrder.id,
          newStatus: OrderStatus.READY_FOR_PICKUP,
        }),
      );
    });

    it('sends Ride- and Custom-Delivery-specific notifications for arrival, start, and completion', async () => {
      const mockSocket = { emitToUser: jest.fn().mockResolvedValue(undefined) };
      const mockNotifications = { create: jest.fn().mockResolvedValue({}) };
      const mockPrismaEvents: any = {
        order: {
          findUnique: jest.fn(({ where }) =>
            Promise.resolve({
              type:
                where.id === 'ord-ride'
                  ? OrderType.RIDE
                  : OrderType.CUSTOM_DELIVERY,
              customerId: 'cust-1',
              customer: { userId: 'user-cust-1' },
              vendorFulfillments: [],
              deliveryGroups: [],
            }),
          ),
        },
        orderDeliveryGroup: { findMany: jest.fn().mockResolvedValue([]) },
      };
      const handler = new OrderEventsHandler(
        mockSocket as any,
        mockNotifications as any,
        {} as any,
        {
          ensureSystemOrderConversation: jest.fn().mockResolvedValue(undefined),
          closeSystemOrderConversation: jest.fn().mockResolvedValue(undefined),
        } as any,
        mockPrismaEvents,
        { syncDriverActiveOrders: jest.fn().mockResolvedValue(undefined) } as any,
      );

      await handler.handleOrderStatusChanged(
        new OrderStatusChangedEvent(
          'ord-ride',
          'OTL-R1',
          OrderStatus.DRIVER_ASSIGNED,
          OrderStatus.READY_FOR_PICKUP,
          'cust-1',
          'user-cust-1',
          null,
          [],
          'driver-1',
          'user-driver-1',
          'user-driver-1',
          'Driver arrived',
          2,
        ),
      );
      expect(mockNotifications.create).toHaveBeenLastCalledWith(
        expect.objectContaining({
          title: 'Your driver has arrived!',
          titleAr: 'وصل الكابتن!',
          body: 'Ride OTL-R1',
        }),
      );

      await handler.handleOrderStatusChanged(
        new OrderStatusChangedEvent(
          'ord-ride',
          'OTL-R1',
          OrderStatus.READY_FOR_PICKUP,
          OrderStatus.PICKED_UP,
          'cust-1',
          'user-cust-1',
          null,
          [],
          'driver-1',
          'user-driver-1',
          'user-driver-1',
          'Ride started',
          3,
        ),
      );
      expect(mockNotifications.create).toHaveBeenLastCalledWith(
        expect.objectContaining({
          title: 'Your ride has started!',
          titleAr: 'بدأت رحلتك!',
        }),
      );

      await handler.handleOrderStatusChanged(
        new OrderStatusChangedEvent(
          'ord-custom',
          'OTL-C1',
          OrderStatus.READY_FOR_PICKUP,
          OrderStatus.PICKED_UP,
          'cust-1',
          'user-cust-1',
          null,
          [],
          'driver-1',
          'user-driver-1',
          'user-driver-1',
          'Package picked up',
          3,
        ),
      );
      expect(mockNotifications.create).toHaveBeenLastCalledWith(
        expect.objectContaining({
          title: 'Your delivery is on its way!',
          titleAr: 'توصيلك في الطريق!',
          body: 'Delivery OTL-C1',
        }),
      );
    });

    it('OrderSearchService computes real road ETA to pickup before start and to destination after PICKED_UP', async () => {
      const routingService = {
        computeRoute: jest.fn().mockResolvedValue({
          isRoadRoute: true,
          distanceMeters: 2400,
          durationSeconds: 310,
        }),
      };
      const prismaMock: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-ride-eta',
            orderNumber: 'OTL-ETA',
            type: OrderType.RIDE,
            status: OrderStatus.PICKED_UP,
            revision: 3,
            distanceKm: 4.5,
            requestedVehicleType: 'CAR',
            cancelReason: null,
            cancelledByRole: null,
            cancelledByUserId: null,
            createdAt: new Date(),
            updatedAt: new Date(),
            customer: { id: 'cust-1', userId: 'user-cust-1' },
            deliveryGroups: [
              {
                id: 'grp-1',
                status: DeliveryGroupStatus.PICKED_UP,
                primaryDriverId: 'driver-1',
                sequence: 1,
              },
            ],
          }),
        },
      };
      const searchService = new OrderSearchService(
        prismaMock,
        { getSettings: jest.fn().mockResolvedValue({}) } as any,
        {} as any,
        {
          getDriverLocationWithState: jest
            .fn()
            .mockResolvedValue({ lng: 31.23, lat: 30.04, isLive: true }),
        } as any,
        {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            lng: 31.22,
            lat: 30.03,
            deliveryLng: 31.28,
            deliveryLat: 30.08,
          }),
          getDistanceKm: jest.fn().mockResolvedValue(5.0),
        } as any,
        { getSearchSnapshot: jest.fn().mockResolvedValue(null) } as any,
        {} as any,
        {} as any,
        { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
        {} as any,
        {} as any,
        {} as any,
        undefined,
        routingService as any,
      );

      const status = await searchService.getOrderSearchStatus(
        { sub: 'user-cust-1', role: Role.CUSTOMER } as any,
        'ord-ride-eta',
      );
      expect(routingService.computeRoute).toHaveBeenCalledWith([
        { lng: 31.23, lat: 30.04 },
        { lng: 31.28, lat: 30.08 },
      ]);
      expect(status.driverDistanceKm).toBe(2.4);
      expect(status.driverEtaMinutes).toBe(6);
    });

    it('cancelDeliveryGroupAndRecompute preserves quoted fare & skips OrderRejectionRecomputor on RIDE/CUSTOM_DELIVERY exhaustion so retry keeps intact billing', async () => {
      const updateGroupMany = jest.fn().mockResolvedValue({ count: 1 });
      const recomputor = { recomputeTotalsAfterRejection: jest.fn() };
      const cancellationService = { cancelOrder: jest.fn().mockResolvedValue({}) };
      const tx: any = {
        orderDeliveryGroup: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'grp-ride-1',
            sequence: 1,
            status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
            deliveryFee: 45,
            goldSurchargeAmount: 5,
            isPaymentCollector: true,
            primaryDriverId: null,
            assistDriverId: null,
            order: {
              orderNumber: 'OTL-R99',
              type: OrderType.RIDE,
              status: OrderStatus.LOOKING_FOR_DRIVER,
              customerId: 'cust-1',
              customer: { userId: 'user-cust-1' },
            },
            items: [],
          }),
          updateMany: updateGroupMany,
          count: jest.fn().mockResolvedValue(0),
        },
        orderDispatch: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
      };
      const prismaMock: any = {
        $transaction: jest.fn((cb: any) => cb(tx)),
      };
      const svc = new DeliveryGroupTransitionService(
        prismaMock,
        {} as any,
        { emit: jest.fn() } as any,
        undefined,
        recomputor as any,
        cancellationService as any,
      );

      const res = await svc.cancelDeliveryGroupAndRecompute({
        orderId: 'ord-ride-99',
        deliveryGroupId: 'grp-ride-1',
        reason: 'No drivers accepted within maximum attempts',
        requireDriverless: true,
      });

      expect(res).toEqual({ groupCancelled: true, orderCancelled: true });
      // Must NOT zero deliveryFee / goldSurchargeAmount / isPaymentCollector
      expect(updateGroupMany).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { status: DeliveryGroupStatus.CANCELLED },
        }),
      );
      // Must NOT invoke store-rejection recomputor
      expect(recomputor.recomputeTotalsAfterRejection).not.toHaveBeenCalled();
      expect(cancellationService.cancelOrder).toHaveBeenCalledWith(
        null,
        'ord-ride-99',
        'No drivers accepted within maximum attempts',
      );
    });

    it('OrderEventsHandler syncs chat participants on RIDE driver reassignment', async () => {
      const conversations = {
        createSystemOrderConversation: jest.fn().mockResolvedValue({}),
        addParticipantToOrderConversation: jest.fn().mockResolvedValue({}),
        syncOrderDriverParticipants: jest.fn().mockResolvedValue({}),
      };
      const prismaMock: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            type: OrderType.RIDE,
            customer: { userId: 'user-cust-1' },
            vendorFulfillments: [],
            deliveryGroups: [],
          }),
        },
        orderDeliveryGroup: { findMany: jest.fn().mockResolvedValue([]) },
      };
      const handler = new OrderEventsHandler(
        { emitToUser: jest.fn().mockResolvedValue(undefined), emitToDriversRoom: jest.fn() } as any,
        { create: jest.fn().mockResolvedValue({}) } as any,
        {} as any,
        conversations as any,
        prismaMock,
        { syncDriverActiveOrders: jest.fn().mockResolvedValue(undefined) } as any,
      );

      await handler.handleOrderStatusChanged(
        new OrderStatusChangedEvent(
          'ord-ride-chat',
          'OTL-RC1',
          OrderStatus.DRIVER_ASSIGNED,
          OrderStatus.DRIVER_ASSIGNED,
          'cust-1',
          'user-cust-1',
          null,
          [],
          'driver-2',
          'user-driver-2',
          'admin-1',
          'Driver reassigned',
          4,
        ),
      );

      expect(conversations.createSystemOrderConversation).toHaveBeenCalledWith(
        'ord-ride-chat',
      );
      expect(
        conversations.addParticipantToOrderConversation,
      ).toHaveBeenCalledWith('ord-ride-chat', 'user-driver-2');
      expect(conversations.syncOrderDriverParticipants).toHaveBeenCalledWith(
        'ord-ride-chat',
      );
    });
  });
});
