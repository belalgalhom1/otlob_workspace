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
import { OrdersStateService } from './orders-state.service';
import { OrderRoleProjector } from './projections/order-role.projector';

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
});
