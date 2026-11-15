import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Role,
  VendorMemberRole,
} from '@prisma/client';
import { OrdersStateService } from './orders-state.service';
import { OrdersService } from './orders.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { OrdersCheckoutService } from './orders-checkout.service';
import { BranchAllocatorHelper } from './helpers/branch-allocator.helper';
import { OrdersRepository } from './orders.repository';
import { OrderRoleProjector } from './projections/order-role.projector';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { PlaceMultiVendorOrderDto } from './dto/multi-vendor-order.dto';
import { EventsProcessor } from '../events/events.processor';
import { OrderEventsHandler } from '../events/order-events.handler';
import { DispatchEventsHandler } from '../events/dispatch-events.handler';
import { NotificationListener } from '../../common/listeners/notification.listener';
import { NotificationsService } from '../notifications/notifications.service';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import { OrderErrors } from '../../common/constants/response.constants';
import { ReviewsService } from '../reviews/reviews.service';

describe('Multi-Vendor Order End-to-End Workflow (1, 2, and 3+ Vendors)', () => {
  describe('1. Single-vendor backward compatibility & multi-vendor driver collection gates (OrdersStateService)', () => {
    let stateService: OrdersStateService;
    let mockOrdersRepo: any;
    let mockPrisma: any;
    let mockStorage: any;
    let mockEventEmitter: any;
    let mockVendorDecisionService: any;

    const driverActor = { sub: 'user-driver-1', role: Role.DRIVER } as any;
    const vendorOwnerA = { sub: 'user-owner-a', role: Role.VENDOR_MEMBER } as any;
    const superAdminActor = { sub: 'user-admin', role: Role.SUPER_ADMIN } as any;

    beforeEach(() => {
      mockOrdersRepo = {
        findById: jest.fn(),
        updateStatus: jest.fn().mockResolvedValue({ revision: 2 }),
        freeDriver: jest.fn().mockResolvedValue(undefined),
        getOrderVendorUserIds: jest.fn().mockResolvedValue(['user-owner-a', 'user-owner-b']),
        assignDriver: jest.fn(),
      };
      mockVendorDecisionService = {
        accept: jest.fn().mockResolvedValue({}),
        reject: jest.fn().mockResolvedValue({}),
      };
      mockEventEmitter = { emit: jest.fn() };
      mockStorage = {
        upload: jest.fn().mockResolvedValue('https://cdn.test/proof.jpg'),
        delete: jest.fn().mockResolvedValue(undefined),
      };
      mockPrisma = {
        driver: { findUnique: jest.fn().mockResolvedValue({ id: 'driver-1', userId: 'user-driver-1' }) },
        vendorMember: {
          findUnique: jest.fn().mockResolvedValue(null),
          findMany: jest.fn().mockResolvedValue([]),
        },
        user: { findUnique: jest.fn().mockResolvedValue({ permissions: [] }) },
        order: {
          findUnique: jest.fn(),
          updateMany: jest.fn(),
        },
        orderVendorFulfillment: {
          findFirst: jest.fn(),
          findMany: jest.fn(),
          update: jest.fn().mockResolvedValue({}),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn(),
          findMany: jest.fn(),
          update: jest.fn().mockResolvedValue({}),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderDeliveryGroupItem: {
          findFirst: jest.fn(),
          findMany: jest.fn(),
        },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
      };

      stateService = new OrdersStateService(
        mockOrdersRepo,
        {} as any,
        mockVendorDecisionService,
        mockEventEmitter,
        mockPrisma,
        mockStorage,
      );
    });

    it('1-vendor order: allows READY_FOR_PICKUP -> PICKED_UP -> DELIVERED with proof photos', async () => {
      const baseGroup = {
        id: 'grp-1',
        sequence: 1,
        status: DeliveryGroupStatus.READY_FOR_PICKUP,
        isPaymentCollector: true,
        primaryDriverId: 'driver-1',
        assistDriverId: null,
        pickupImageUrl: null,
        deliveryImageUrl: null,
      };
      const singleOrder = {
        id: 'ord-single',
        orderNumber: 'OTL-1001',
        type: 'STANDARD',
        status: OrderStatus.READY_FOR_PICKUP,
        customerId: 'cust-1',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        upfrontAmount: 0,
        revision: 2,
        deliveryGroups: [baseGroup],
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'vendor-1',
            vendorBranchId: 'branch-1',
            status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
          },
        ],
        customer: { userId: 'user-cust-1', user: { id: 'user-cust-1' } },
      };

      mockOrdersRepo.findById.mockResolvedValue(singleOrder);
      mockPrisma.orderDeliveryGroupItem.findMany.mockResolvedValueOnce([
        {
          fulfillmentId: 'ff-1',
          sequence: 1,
          fulfillment: {
            id: 'ff-1',
            status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
            readyAt: new Date(),
            pickedUpAt: null,
          },
        },
      ]);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValueOnce([
        { ...baseGroup, status: DeliveryGroupStatus.PICKED_UP },
      ]);
      mockPrisma.order.findUnique.mockResolvedValueOnce(singleOrder);
      mockOrdersRepo.updateStatus.mockResolvedValueOnce({
        ...singleOrder,
        status: OrderStatus.PICKED_UP,
        revision: 3,
      });

      await stateService.driverUpdateStatus(driverActor, 'ord-single', {
        status: OrderStatus.PICKED_UP,
        pickupImageUrl: 'https://cdn.test/pickup-1.jpg',
      });
      expect(mockPrisma.orderDeliveryGroup.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'grp-1', status: DeliveryGroupStatus.READY_FOR_PICKUP },
          data: expect.objectContaining({
            status: DeliveryGroupStatus.PICKED_UP,
            pickupImageUrl: 'https://cdn.test/pickup-1.jpg',
          }),
        }),
      );
      expect(mockOrdersRepo.updateStatus).toHaveBeenCalledWith(
        'ord-single',
        OrderStatus.PICKED_UP,
        'user-driver-1',
        'All deliveries picked up',
        {},
        OrderStatus.READY_FOR_PICKUP,
      );

      const pickedUpOrder = {
        ...singleOrder,
        status: OrderStatus.PICKED_UP,
        revision: 3,
        deliveryGroups: [
          {
            ...baseGroup,
            status: DeliveryGroupStatus.PICKED_UP,
            pickupImageUrl: 'https://cdn.test/pickup-1.jpg',
          },
        ],
      };
      mockOrdersRepo.findById.mockResolvedValue(pickedUpOrder);
      mockPrisma.orderDeliveryGroupItem.findMany.mockResolvedValueOnce([
        {
          fulfillmentId: 'ff-1',
          sequence: 1,
          fulfillment: {
            id: 'ff-1',
            status: OrderVendorFulfillmentStatus.PICKED_UP,
            readyAt: new Date(),
            pickedUpAt: new Date(),
          },
        },
      ]);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValueOnce([
        { ...baseGroup, status: DeliveryGroupStatus.DELIVERED },
      ]);
      mockPrisma.order.findUnique.mockResolvedValueOnce(pickedUpOrder);
      mockOrdersRepo.updateStatus.mockResolvedValueOnce({
        ...pickedUpOrder,
        status: OrderStatus.DELIVERED,
        revision: 4,
      });

      await stateService.driverUpdateStatus(driverActor, 'ord-single', {
        status: OrderStatus.DELIVERED,
        deliveryImageUrl: 'https://cdn.test/delivery-1.jpg',
      });
      expect(mockPrisma.orderDeliveryGroup.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'grp-1', status: DeliveryGroupStatus.PICKED_UP },
          data: expect.objectContaining({
            status: DeliveryGroupStatus.DELIVERED,
            deliveryImageUrl: 'https://cdn.test/delivery-1.jpg',
          }),
        }),
      );
      expect(mockOrdersRepo.updateStatus).toHaveBeenCalledWith(
        'ord-single',
        OrderStatus.DELIVERED,
        'user-driver-1',
        'All deliveries completed',
        expect.objectContaining({ actualDeliveryTime: expect.any(Date) }),
        OrderStatus.PICKED_UP,
      );
    });

    it('2-vendor order: blocks driver from picking up a stop before vendor marks READY_FOR_PICKUP', async () => {
      const mvOrder = {
        id: 'ord-mv-2',
        orderNumber: 'OTL-2001',
        type: 'STANDARD',
        status: OrderStatus.DRIVER_ASSIGNED,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        upfrontAmount: 0,
        driverId: 'driver-1',
      };
      mockOrdersRepo.findById.mockResolvedValue(mvOrder);
      mockPrisma.orderVendorFulfillment.findFirst.mockResolvedValue({
        id: 'ff-1',
        orderId: 'ord-mv-2',
        status: OrderVendorFulfillmentStatus.PREPARING,
        readyAt: null,
        pickedUpAt: null,
        groups: [
          {
            deliveryGroupId: 'grp-1',
            deliveryGroup: { id: 'grp-1', primaryDriverId: 'driver-1', assistDriverId: null },
          },
        ],
      });

      await expect(
        stateService.driverConfirmFulfillmentPickup(driverActor, 'ord-mv-2', 'ff-1', {} as any),
      ).rejects.toThrow(BadRequestException);
      expect(mockStorage.upload).not.toHaveBeenCalled();
    });

    it('2-vendor order: blocks skipping Stop 1 and blocks marking PARTIALLY_PICKED_UP order as DELIVERED or PICKED_UP while Stop 2 uncollected', async () => {
      const mvOrder = {
        id: 'ord-mv-2',
        orderNumber: 'OTL-2001',
        type: 'STANDARD',
        status: OrderStatus.PARTIALLY_PICKED_UP,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        upfrontAmount: 0,
        driverId: 'driver-1',
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: DeliveryGroupStatus.PARTIALLY_PICKED_UP,
            primaryDriverId: 'driver-1',
            assistDriverId: null,
          },
        ],
      };
      mockOrdersRepo.findById.mockResolvedValue(mvOrder);

      // Trying to pick up Stop 2 before Stop 1 is collected
      mockPrisma.orderVendorFulfillment.findFirst.mockResolvedValue({
        id: 'ff-2',
        orderId: 'ord-mv-2',
        status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
        readyAt: new Date(),
        pickedUpAt: null,
        groups: [
          {
            deliveryGroupId: 'grp-1',
            deliveryGroup: { id: 'grp-1', primaryDriverId: 'driver-1', assistDriverId: null },
          },
        ],
      });
      mockPrisma.orderDeliveryGroupItem.findMany.mockResolvedValue([
        {
          fulfillmentId: 'ff-1',
          sequence: 1,
          fulfillment: { id: 'ff-1', status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP, pickedUpAt: null },
        },
        {
          fulfillmentId: 'ff-2',
          sequence: 2,
          fulfillment: { id: 'ff-2', status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP, pickedUpAt: null },
        },
      ]);

      await expect(
        stateService.driverConfirmFulfillmentPickup(driverActor, 'ord-mv-2', 'ff-2', {} as any),
      ).rejects.toThrow('Earlier vendor pickup stop must be completed first');

      // Trying to mark order DELIVERED directly from PARTIALLY_PICKED_UP
      await expect(
        stateService.driverUpdateStatus(driverActor, 'ord-mv-2', {
          status: OrderStatus.DELIVERED,
          deliveryImageUrl: 'https://cdn.test/del.jpg',
        }),
      ).rejects.toThrow(BadRequestException);

      // Trying to mark order PICKED_UP via PATCH status while Stop 2 has not been picked up
      mockPrisma.orderDeliveryGroupItem.findMany.mockResolvedValue([
        {
          fulfillmentId: 'ff-1',
          sequence: 1,
          fulfillment: { id: 'ff-1', status: OrderVendorFulfillmentStatus.PICKED_UP, readyAt: new Date(), pickedUpAt: new Date() },
        },
        {
          fulfillmentId: 'ff-2',
          sequence: 2,
          fulfillment: { id: 'ff-2', status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP, readyAt: new Date(), pickedUpAt: null },
        },
      ]);
      await expect(
        stateService.driverUpdateStatus(driverActor, 'ord-mv-2', {
          status: OrderStatus.PICKED_UP,
          pickupImageUrl: 'https://cdn.test/pick.jpg',
        }),
      ).rejects.toThrow('All vendor pickup stops must be collected before marking group picked up');
    });

    it('3-vendor order: sequential collection Stop 1 -> Stop 2 -> Stop 3 transitions PARTIALLY_PICKED_UP -> PICKED_UP -> DELIVERED', async () => {
      const baseOrder = {
        id: 'ord-mv-3',
        orderNumber: 'OTL-3001',
        type: 'STANDARD',
        status: OrderStatus.READY_FOR_PICKUP,
        customerId: 'cust-1',
        vendorId: null,
        driverId: 'driver-1',
        revision: 1,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        upfrontAmount: 0,
        customer: { userId: 'user-cust-1' },
      };

      const makeStop = (id: string, seq: number, pickedUp: boolean, branchName: string) => ({
        fulfillmentId: id,
        sequence: seq,
        fulfillment: {
          id,
          status: pickedUp ? OrderVendorFulfillmentStatus.PICKED_UP : OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
          readyAt: new Date(),
          pickedUpAt: pickedUp ? new Date() : null,
          vendorBranch: { name: branchName, nameAr: branchName },
        },
      });

      // Stop 1 pickup -> PARTIALLY_PICKED_UP
      mockOrdersRepo.findById.mockResolvedValue({ ...baseOrder, revision: 2, status: OrderStatus.PARTIALLY_PICKED_UP });
      mockPrisma.orderVendorFulfillment.findFirst.mockResolvedValue({
        id: 'ff-1',
        orderId: 'ord-mv-3',
        status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
        readyAt: new Date(),
        pickedUpAt: null,
        groups: [{ deliveryGroupId: 'grp-1', deliveryGroup: { id: 'grp-1', primaryDriverId: 'driver-1', assistDriverId: null } }],
      });
      mockPrisma.orderDeliveryGroupItem.findMany
        .mockResolvedValueOnce([makeStop('ff-1', 1, false, 'Branch 1'), makeStop('ff-2', 2, false, 'Branch 2'), makeStop('ff-3', 3, false, 'Branch 3')])
        .mockResolvedValueOnce([makeStop('ff-1', 1, true, 'Branch 1'), makeStop('ff-2', 2, false, 'Branch 2'), makeStop('ff-3', 3, false, 'Branch 3')]);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        { id: 'grp-1', status: DeliveryGroupStatus.PARTIALLY_PICKED_UP, primaryDriverId: 'driver-1', assistDriverId: null },
      ]);
      mockPrisma.order.findUnique.mockResolvedValue({ ...baseOrder, status: OrderStatus.READY_FOR_PICKUP, revision: 1 });
      mockOrdersRepo.updateStatus.mockResolvedValue({ revision: 2 });

      await stateService.driverConfirmFulfillmentPickup(driverActor, 'ord-mv-3', 'ff-1', {} as any);
      expect(mockPrisma.orderDeliveryGroup.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: DeliveryGroupStatus.PARTIALLY_PICKED_UP } }),
      );
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'order.fulfillment.updated',
        expect.objectContaining({
          fulfillmentId: 'ff-1',
          fulfillmentSummary: expect.objectContaining({
            totalStops: 3,
            completedStops: 1,
            currentStopSequence: 2,
            currentStopBranchName: 'Branch 2',
            isFullyCollected: false,
          }),
        }),
      );

      // Stop 3 pickup (Stops 1 & 2 already picked up) -> PICKED_UP
      jest.clearAllMocks();
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', userId: 'user-driver-1' });
      mockOrdersRepo.findById.mockResolvedValue({ ...baseOrder, revision: 4, status: OrderStatus.PICKED_UP });
      mockPrisma.orderVendorFulfillment.findFirst.mockResolvedValue({
        id: 'ff-3',
        orderId: 'ord-mv-3',
        status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
        readyAt: new Date(),
        pickedUpAt: null,
        groups: [{ deliveryGroupId: 'grp-1', deliveryGroup: { id: 'grp-1', primaryDriverId: 'driver-1', assistDriverId: null } }],
      });
      mockPrisma.orderDeliveryGroupItem.findMany
        .mockResolvedValueOnce([makeStop('ff-1', 1, true, 'Branch 1'), makeStop('ff-2', 2, true, 'Branch 2'), makeStop('ff-3', 3, false, 'Branch 3')])
        .mockResolvedValueOnce([makeStop('ff-1', 1, true, 'Branch 1'), makeStop('ff-2', 2, true, 'Branch 2'), makeStop('ff-3', 3, true, 'Branch 3')]);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        { id: 'grp-1', status: DeliveryGroupStatus.PICKED_UP, primaryDriverId: 'driver-1', assistDriverId: null },
      ]);
      mockPrisma.order.findUnique.mockResolvedValue({ ...baseOrder, status: OrderStatus.PARTIALLY_PICKED_UP, revision: 3 });
      mockOrdersRepo.updateStatus.mockResolvedValue({ revision: 4 });

      await stateService.driverConfirmFulfillmentPickup(driverActor, 'ord-mv-3', 'ff-3', {} as any);
      expect(mockPrisma.orderDeliveryGroup.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: DeliveryGroupStatus.PICKED_UP }),
        }),
      );
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'order.fulfillment.updated',
        expect.objectContaining({
          fulfillmentId: 'ff-3',
          fulfillmentSummary: expect.objectContaining({
            totalStops: 3,
            completedStops: 3,
            isFullyCollected: true,
          }),
        }),
      );
    });

    it('Super Admin updating one store with fulfillmentId ONLY updates that store portion, and rejects cross-vendor updates', async () => {
      const mvOrder = {
        id: 'ord-mv-2',
        orderNumber: 'OTL-2002',
        type: 'STANDARD',
        status: OrderStatus.DRIVER_ASSIGNED,
        vendorId: null,
        vendorFulfillments: [
          { id: 'ff-a', vendorId: 'vendor-a', vendorBranchId: 'br-a', status: OrderVendorFulfillmentStatus.ACCEPTED },
          { id: 'ff-b', vendorId: 'vendor-b', vendorBranchId: 'br-b', status: OrderVendorFulfillmentStatus.ACCEPTED },
        ],
      };
      mockOrdersRepo.findById.mockResolvedValue(mvOrder);
      mockPrisma.user.findUnique.mockResolvedValue({ permissions: ['MANAGE_ORDERS'] });
      mockPrisma.orderDeliveryGroupItem.findFirst.mockResolvedValue({ deliveryGroupId: 'grp-1' });
      mockPrisma.orderDeliveryGroup.findUnique.mockResolvedValue({
        id: 'grp-1',
        sequence: 1,
        status: DeliveryGroupStatus.DRIVER_ASSIGNED,
        estimatedPrepTime: null,
        primaryDriver: null,
        assistDriver: null,
      });
      mockPrisma.orderVendorFulfillment.findMany.mockResolvedValue([
        { status: OrderVendorFulfillmentStatus.PREPARING, readyAt: null },
        { status: OrderVendorFulfillmentStatus.ACCEPTED, readyAt: null },
      ]);
      mockPrisma.orderDeliveryGroup.findMany.mockResolvedValue([
        { id: 'grp-1', status: DeliveryGroupStatus.DRIVER_ASSIGNED },
      ]);

      await stateService.vendorUpdateStatus(superAdminActor, 'ord-mv-2', {
        status: OrderStatus.PREPARING,
        estimatedPrepTime: 15,
        fulfillmentId: 'ff-b',
      });

      expect(mockPrisma.orderVendorFulfillment.updateMany).toHaveBeenCalledTimes(1);
      expect(mockPrisma.orderVendorFulfillment.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ id: 'ff-b' }) }),
      );

      // Branch-scoped manager at Branch A cannot update Branch B of the same vendor
      mockPrisma.vendorMember.findMany.mockResolvedValue([
        { id: 'vm-a', vendorId: 'vendor-a', branchId: 'br-a', role: VendorMemberRole.MANAGER },
      ]);
      mockOrdersRepo.findById.mockResolvedValue({
        ...mvOrder,
        vendorFulfillments: [
          { id: 'ff-a2', vendorId: 'vendor-a', vendorBranchId: 'br-a2', status: OrderVendorFulfillmentStatus.ACCEPTED },
        ],
      });
      await expect(
        stateService.vendorUpdateStatus(vendorOwnerA, 'ord-mv-2', {
          status: OrderStatus.PREPARING,
          fulfillmentId: 'ff-a2',
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('2. Multi-vendor coordinate normalization & single-order creation (OrdersMultiVendorService)', () => {
    it('coerces stringified deliveryLocation coordinates from client API DTOs into numeric coordinates', async () => {
      const mockPrisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'cust-1', coinBalance: 0 }) },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'v1',
            status: 'OPEN',
            commissionRate: 15,
            isContracted: true,
            deletedAt: null,
          }),
          findMany: jest.fn().mockResolvedValue([
            { id: 'v1', isContracted: true, commissionRate: 15 },
            { id: 'v2', isContracted: false, commissionRate: 10 },
          ]),
        },
        vendorBranch: { findMany: jest.fn().mockResolvedValue([]) },
      };
      const mockRepo: any = {
        getZoneAtLocation: jest.fn().mockResolvedValue({ id: 'zone-1' }),
        getNearestOpenBranchLocation: jest
          .fn()
          .mockResolvedValueOnce({ id: 'b1', lng: 31.2, lat: 30.0, commissionRate: 15 })
          .mockResolvedValueOnce({ id: 'b2', lng: 31.21, lat: 30.01, commissionRate: 10 }),
      };
      const mockCart: any = {
        validateForCheckout: jest.fn().mockResolvedValue({
          cart: {
            subtotal: 200,
            items: [
              {
                productId: 'p1',
                variantId: null,
                product: { name: 'Item' },
                unitPrice: 100,
                quantity: 2,
                totalPrice: 200,
                options: [],
              },
            ],
          },
        }),
        assertItemsAvailableAtBranch: jest.fn().mockResolvedValue(undefined),
      };
      const mockGrouping: any = {
        planForCheckout: jest.fn().mockResolvedValue({
          isSplit: false,
          groups: [
            {
              sequence: 1,
              stops: [
                { vendorId: 'v1', vendorBranchId: 'b1', lng: 31.2, lat: 30.0 },
                { vendorId: 'v2', vendorBranchId: 'b2', lng: 31.21, lat: 30.01 },
              ],
              farthestToCustomerKm: 4.5,
              extraVendorCount: 1,
              splitReason: null,
            },
          ],
        }),
      };

      const svc = new OrdersMultiVendorService(
        mockPrisma,
        mockCart,
        {
          getSettings: jest.fn().mockResolvedValue({
            baseDeliveryFee: 20,
            feePerKm: 5,
            multiVendorExtraStopFee: 10,
            defaultTaxRate: 0,
            maxDeliveryRadiusKm: 50,
            serviceFeeEnabled: false,
          }),
          calculateDeliveryFee: jest.fn().mockResolvedValue(20),
        } as any,
        {} as any,
        mockRepo,
        mockGrouping,
        { emit: jest.fn() } as any,
        {} as any,
      );

      const est = await svc.estimate(
        { sub: 'user-cust', role: Role.CUSTOMER } as any,
        {
          vendorIds: ['v1', 'v2'],
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          deliveryAddress: 'Nasr City',
          deliveryLocation: ['31.33', '30.0444'] as any,
        },
      );

      expect(mockRepo.getZoneAtLocation).toHaveBeenCalledWith(31.33, 30.0444);
      expect(mockGrouping.planForCheckout).toHaveBeenCalledWith(
        expect.any(Array),
        { lng: 31.33, lat: 30.0444 },
      );
      expect(est.vendorCount).toBe(2);
      expect(est.deliveryCount).toBe(1);
    });

    it('returns the existing order on sequential retry with an Idempotency-Key without failing on cleared carts', async () => {
      const existingOrder = { id: 'mv-existing', orderNumber: 'OTL-777' };
      const mockRepo: any = {
        findByClientOrderKeyForUser: jest.fn().mockResolvedValue(existingOrder),
      };
      const mockCart: any = {
        validateForCheckout: jest
          .fn()
          .mockRejectedValue(new BadRequestException('cart.error.is_empty')),
      };
      const mockPrisma: any = {
        $transaction: jest.fn(),
      };

      const svc = new OrdersMultiVendorService(
        mockPrisma,
        mockCart,
        {} as any,
        {} as any,
        mockRepo,
        {} as any,
        { emit: jest.fn() } as any,
        {} as any,
      );

      const res = await svc.placeOrder(
        { sub: 'user-cust', role: Role.CUSTOMER } as any,
        {
          vendorIds: ['v1', 'v2'],
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          deliveryAddress: 'Nasr City',
          deliveryLocation: [31.33, 30.0444],
        },
        'idem-key-123',
      );

      expect(res).toBe(existingOrder);
      expect(mockRepo.findByClientOrderKeyForUser).toHaveBeenCalledWith(
        'idem-key-123',
        'user-cust',
      );
      expect(mockCart.validateForCheckout).not.toHaveBeenCalled();
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('resolves or rejects clientOrderKey lookups in OrdersRepository by owner userId', async () => {
      const existingOrder = { id: 'order-1', orderNumber: 'OTL-100' };
      const findUnique = jest.fn();
      const queriesRepo: any = {
        findById: jest.fn().mockResolvedValue(existingOrder),
      };
      const repo = new OrdersRepository(
        { order: { findUnique } } as any,
        {} as any,
        undefined,
        queriesRepo,
      );

      findUnique.mockResolvedValueOnce(null);
      await expect(
        repo.findByClientOrderKeyForUser('missing-key', 'user-1'),
      ).resolves.toBeNull();

      findUnique.mockResolvedValueOnce({
        id: 'order-1',
        customer: { userId: 'user-1' },
      });
      await expect(
        repo.findByClientOrderKeyForUser('valid-key', 'user-1'),
      ).resolves.toBe(existingOrder);
      expect(queriesRepo.findById).toHaveBeenCalledWith('order-1');

      findUnique.mockResolvedValueOnce({
        id: 'order-1',
        customer: { userId: 'other-user' },
      });
      await expect(
        repo.findByClientOrderKeyForUser('stolen-key', 'user-1'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('3. Super Admin, Vendor, and Driver projections for 3-vendor & partially rejected orders (OrdersService)', () => {
    it('excludes rejected vendor payout from Super Admin cashToPayStore while showing all 3 vendors & items', async () => {
      const ordersService = new OrdersService(
        {} as any,
        { vendorMember: { findMany: jest.fn() }, driver: { findUnique: jest.fn() } } as any,
        { getSettings: jest.fn().mockResolvedValue({ deliveryCommissionRate: 20, driverManagerCommissionRate: 10 }) } as any,
      );

      const enriched = await (ordersService as any).enrichWithAdminHelpers({
        id: 'mv-3',
        orderNumber: 'OTL-3009',
        status: OrderStatus.READY_FOR_PICKUP,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        subtotal: 700,
        deliveryFee: 40,
        grandTotal: 740,
        vendorId: null,
        vendor: null,
        vendorBranch: null,
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'v1',
            status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
            subtotal: 500,
            commissionRate: 20,
            vendor: { storeName: 'Store 1', storeNameAr: 'متجر 1', isContracted: true },
            vendorBranch: { name: 'B1', isContracted: true },
          },
          {
            id: 'ff-2',
            vendorId: 'v2',
            status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
            subtotal: 200,
            commissionRate: 10,
            vendor: { storeName: 'Store 2', storeNameAr: 'متجر 2', isContracted: false },
            vendorBranch: { name: 'B2', isContracted: false },
          },
          {
            id: 'ff-3',
            vendorId: 'v3',
            status: OrderVendorFulfillmentStatus.REJECTED,
            subtotal: 300,
            commissionRate: 10,
            vendor: { storeName: 'Store 3', storeNameAr: 'متجر 3', isContracted: false },
            vendorBranch: { name: 'B3', isContracted: false },
          },
        ],
      });

      expect(enriched.financials.storePayments).toHaveLength(3);
      expect(enriched.financials.storePayments[2].cashToPay).toBe(0);
      // 400 (Store 1 net) + 200 (Store 2) + 0 (rejected Store 3) = 600
      expect(enriched.financials.cashToPayStore).toBe(600);
    });
  });

  describe('4. Crash recovery & simultaneous decision races (EventsProcessor + OrderVendorDecisionService)', () => {
    it('replays a job after a mid-flight worker kill and deduplicates only once marked DONE', async () => {
      const store = new Map<string, string>();
      const mockRedisClient: any = {
        get: jest.fn((k: string) => Promise.resolve(store.get(k) ?? null)),
        set: jest.fn((k: string, v: string, _ex?: string, _ttl?: number, nx?: string) => {
          if (nx === 'NX' && store.has(k)) return Promise.resolve(null);
          store.set(k, v);
          return Promise.resolve('OK');
        }),
        del: jest.fn((k: string) => {
          store.delete(k);
          return Promise.resolve(1);
        }),
      };
      const mockSocket = { emitToUser: jest.fn().mockResolvedValue(undefined) };
      const mockNotifications = { createMany: jest.fn().mockResolvedValue([]) };
      const mockPrisma = {
        vendorMember: { findMany: jest.fn().mockResolvedValue([]) },
        order: { findUnique: jest.fn().mockResolvedValue(null) },
        orderVendorFulfillment: { findMany: jest.fn().mockResolvedValue([]) },
      };

      const orderEventsHandler = new OrderEventsHandler(
        mockSocket as any,
        mockNotifications as any,
        {} as any,
        {} as any,
        mockPrisma as any,
        {} as any,
      );
      const dispatchEventsHandler = new DispatchEventsHandler(
        mockSocket as any,
        mockNotifications as any,
        {} as any,
        mockPrisma as any,
      );

      const processor = new EventsProcessor(
        orderEventsHandler,
        dispatchEventsHandler,
        mockNotifications as any,
        {} as any,
        { getClient: () => mockRedisClient } as any,
      );

      // Simulate prior attempt crashed (e.g. SIGKILL) after lock expired:
      // idempotencyKey is NOT marked 'DONE'.
      const job = {
        id: 'notify_order_created_ord-crash',
        name: EVENT_JOBS.ORDER_CREATED,
        data: {
          orderId: 'ord-crash',
          orderNumber: 'OTL-9999',
          customerId: 'cust-1',
          actorUserId: 'cust-user',
          vendorId: null,
          vendorUserIds: ['u-v1', 'u-v2'],
          grandTotal: 350,
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          orderType: 'STANDARD',
          revision: 0,
        },
      } as any;

      await processor.process(job);
      expect(mockSocket.emitToUser).toHaveBeenCalledTimes(2);
      expect(store.get('notify:order_created:ord-crash')).toBe('DONE');
      expect(store.has('notify:order_created:ord-crash:lock')).toBe(false);

      // Subsequent duplicate delivery MUST skip without re-notifying.
      const second = await processor.process(job);
      expect(second).toEqual({ skipped: true });
      expect(mockSocket.emitToUser).toHaveBeenCalledTimes(2);
    });

    it('ignores ALREADY_CANCELLED race when two final portions reject/timeout simultaneously', async () => {
      const mockPrisma: any = {
        orderVendorFulfillment: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ff-2',
            orderId: 'ord-race',
            vendorId: 'v2',
            vendorBranchId: 'b2',
            status: OrderVendorFulfillmentStatus.PENDING,
            commissionRate: 10,
            pickedUpAt: null,
          }),
          findMany: jest.fn().mockResolvedValue([
            { status: OrderVendorFulfillmentStatus.REJECTED },
            { status: OrderVendorFulfillmentStatus.REJECTED },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        order: {
          findUnique: jest
            .fn()
            // Initial read before tx
            .mockResolvedValueOnce({
              id: 'ord-race',
              orderNumber: 'OTL-777',
              customerId: 'cust-1',
              customer: { userId: 'u-cust' },
              status: OrderStatus.PENDING,
              paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
              paymentStatus: 'PENDING',
            })
            // Catch check after cancelOrder throws (winner already cancelled)
            .mockResolvedValueOnce({ status: OrderStatus.CANCELLED })
            // emitDecided read
            .mockResolvedValueOnce({
              orderNumber: 'OTL-777',
              customerId: 'cust-1',
              customer: { userId: 'u-cust' },
            })
            // final findById lookup if needed
            .mockResolvedValue({ status: OrderStatus.CANCELLED }),
        },
        orderItem: {
          findMany: jest.fn().mockResolvedValue([]),
          updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        orderDeliveryGroupItem: {
          findFirst: jest.fn().mockResolvedValue(null),
          deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({
            storeName: 'Store 2',
            storeNameAr: 'متجر 2',
            isContracted: false,
            members: [],
          }),
        },
        vendorBranch: {
          findUnique: jest.fn().mockResolvedValue({ isContracted: false }),
        },
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(mockPrisma))),
      };

      const mockOrdersRepo: any = {
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
        getVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const mockCancellationService: any = {
        cancelOrder: jest
          .fn()
          .mockRejectedValue(new BadRequestException('Order already cancelled')),
      };
      const mockDecision = new OrderVendorDecisionService(
        mockPrisma,
        mockOrdersRepo,
        mockCancellationService,
        { getSettings: jest.fn().mockResolvedValue({ extraVendorDeliveryFee: 10 }) } as any,
        { emit: jest.fn() } as any,
      );
      jest.spyOn(mockDecision, 'findById').mockResolvedValue({
        id: 'ff-2',
        status: OrderVendorFulfillmentStatus.REJECTED,
      } as any);

      await expect(
        mockDecision.reject(null, 'ff-2', {
          code: 'TIMEOUT',
          reason: 'Timed out',
        }),
      ).resolves.toMatchObject({ id: 'ff-2', status: OrderVendorFulfillmentStatus.REJECTED });
    });

    it('normalizes and validates PlaceMultiVendorOrderDto coordinates for numbers and legacy string tuples', async () => {
      const base = {
        vendorIds: [
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ],
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        deliveryAddress: '15 El Gomhoria St, Cairo',
      };

      const fromStrings = plainToInstance(PlaceMultiVendorOrderDto, {
        ...base,
        deliveryLocation: ['31.33', '30.0444'],
      });
      expect(fromStrings.deliveryLocation).toEqual([31.33, 30.0444]);
      expect(await validate(fromStrings)).toHaveLength(0);

      const fromBadStrings = plainToInstance(PlaceMultiVendorOrderDto, {
        ...base,
        deliveryLocation: ['not-a-lng', '30.0444'],
      });
      expect(await validate(fromBadStrings)).not.toHaveLength(0);
    });

    it('enqueues EVENT_JOBS.NOTIFY with queue default retries and keeps socket/push failures non-fatal', async () => {
      const add = jest.fn().mockResolvedValue(undefined);
      const listener = new NotificationListener({ add } as any);
      await listener.handleFulfillmentDecided({
        customerUserId: 'cust-u-1',
        orderId: 'ord-1',
        orderNumber: 'OTL-1',
        fulfillmentId: 'ff-1',
        status: OrderVendorFulfillmentStatus.ACCEPTED,
      } as any);

      expect(add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({ dto: expect.objectContaining({ userId: 'cust-u-1' }) }),
      );

      const notifSvc = new NotificationsService(
        {
          notification: {
            create: jest.fn().mockResolvedValue({
              id: 'notif-1',
              title: 't',
              titleAr: null,
              body: null,
              bodyAr: null,
              type: 'ORDER_UPDATE',
              data: null,
              createdAt: new Date(),
            }),
          },
          user: {
            findUnique: jest.fn().mockRejectedValue(new Error('Push lookup transient error')),
          },
        } as any,
        {} as any,
        { emitToUser: jest.fn().mockRejectedValue(new Error('Socket transient error')) } as any,
      );

      await expect(
        notifSvc.create({
          userId: 'cust-u-1',
          title: 't',
          type: 'ORDER_UPDATE' as any,
        }),
      ).resolves.toMatchObject({ id: 'notif-1' });
    });

    it('rejects multi-vendor estimate and placeOrder when vendor count exceeds maxMultiVendorVendors', async () => {
      const mockRepo: any = {
        findByClientOrderKeyForUser: jest.fn().mockResolvedValue(null),
      };
      const mockPrisma: any = {
        customer: { findUnique: jest.fn() },
        $transaction: jest.fn(),
      };
      const mockCart: any = {
        validateForCheckout: jest.fn(),
      };
      const mockSettings: any = {
        getSettings: jest.fn().mockResolvedValue({ maxMultiVendorVendors: 2 }),
      };

      const svc = new OrdersMultiVendorService(
        mockPrisma,
        mockCart,
        mockSettings,
        {} as any,
        mockRepo,
        {} as any,
        { emit: jest.fn() } as any,
        {} as any,
      );

      await expect(
        svc.estimate(
          { sub: 'user-cust', role: Role.CUSTOMER } as any,
          {
            vendorIds: ['v1', 'v2', 'v3'],
            paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
            deliveryAddress: 'Nasr City',
            deliveryLocation: [31.33, 30.0444],
          },
        ),
      ).rejects.toThrow(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);

      await expect(
        svc.placeOrder(
          { sub: 'user-cust', role: Role.CUSTOMER } as any,
          {
            vendorIds: ['v1', 'v2', 'v3'],
            paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
            deliveryAddress: 'Nasr City',
            deliveryLocation: [31.33, 30.0444],
          },
        ),
      ).rejects.toThrow(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);

      // Setting maxMultiVendorVendors = 1 disables multi-vendor checkout (>= 2)
      mockSettings.getSettings.mockResolvedValue({ maxMultiVendorVendors: 1 });
      await expect(
        svc.estimate(
          { sub: 'user-cust', role: Role.CUSTOMER } as any,
          {
            vendorIds: ['v1', 'v2'],
            paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
            deliveryAddress: 'Nasr City',
            deliveryLocation: [31.33, 30.0444],
          },
        ),
      ).rejects.toThrow(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);

      expect(mockPrisma.customer.findUnique).not.toHaveBeenCalled();
      expect(mockCart.validateForCheckout).not.toHaveBeenCalled();
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('allocates minimal nearest open branches cleanly and rejects uncovered products or no open branches', async () => {
      const mockRepo: any = {
        getNearestOpenBranchLocation: jest.fn().mockResolvedValue(null),
        getOpenBranchesWithProductAvailability: jest.fn().mockResolvedValue([
          {
            id: 'b1',
            zoneId: 'z1',
            lng: 31.31,
            lat: 30.05,
            isContracted: true,
            coveredProductIds: ['pA'],
          },
          {
            id: 'b2',
            zoneId: 'z1',
            lng: 31.32,
            lat: 30.06,
            isContracted: true,
            coveredProductIds: ['pB', 'pC'],
          },
          {
            id: 'b3',
            zoneId: 'z1',
            lng: 31.35,
            lat: 30.08,
            isContracted: true,
            coveredProductIds: ['pA', 'pB'],
          },
        ]),
      };
      const mockCart: any = {
        assertItemsAvailableAtBranch: jest.fn().mockResolvedValue(undefined),
      };

      const allocator = new BranchAllocatorHelper(mockRepo, mockCart);
      const result = await allocator.allocateForVendorCart({
        vendorId: 'v1',
        deliveryLng: 31.33,
        deliveryLat: 30.04,
        zoneId: 'z1',
        cart: {
          subtotal: 150,
          items: [
            { productId: 'pA', totalPrice: 50 },
            { productId: 'pB', totalPrice: 60 },
            { productId: 'pC', totalPrice: 40 },
          ],
        },
      });

      expect(result.map((r) => r.branch.id)).toEqual(['b1', 'b2']);
      expect(result.map((r) => r.subtotal)).toEqual([50, 100]);

      // Uncovered product across all open branches -> PRODUCT_NOT_AVAILABLE_AT_BRANCH
      await expect(
        allocator.allocateForVendorCart({
          vendorId: 'v1',
          deliveryLng: 31.33,
          deliveryLat: 30.04,
          zoneId: 'z1',
          cart: {
            subtotal: 50,
            items: [{ productId: 'pMissing', totalPrice: 50 }],
          },
        }),
      ).rejects.toThrow(OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH);

      // No open branches -> NO_OPEN_BRANCH
      mockRepo.getOpenBranchesWithProductAvailability.mockResolvedValue([]);
      await expect(
        allocator.allocateForVendorCart({
          vendorId: 'v1',
          deliveryLng: 31.33,
          deliveryLat: 30.04,
          zoneId: 'z1',
          cart: {
            subtotal: 50,
            items: [{ productId: 'pA', totalPrice: 50 }],
          },
        }),
      ).rejects.toThrow(OrderErrors.NO_OPEN_BRANCH);
    });

    it('splits single-vendor checkout across branches via OrdersCheckoutService and enforces maxMultiVendorVendors on unique branches', async () => {
      const createdFulfillments: any[] = [];
      const createdGroupItems: any[] = [];
      const createdItemFulfillmentIds: string[] = [];

      const mockRepo: any = {
        findByClientOrderKeyForUser: jest.fn().mockResolvedValue(null),
        generateOrderNumber: jest.fn().mockResolvedValue('OTL-SPLIT-1'),
        findById: jest.fn().mockResolvedValue({ id: 'order-split-1' }),
        getZoneAtLocation: jest.fn().mockResolvedValue({
          id: 'zone-1',
          baseDeliveryFeeOverride: null,
          minOrderAmountOverride: 0,
        }),
        getNearestOpenBranchLocation: jest.fn().mockResolvedValue(null),
        getOpenBranchesWithProductAvailability: jest.fn().mockResolvedValue([
          {
            id: 'b1',
            zoneId: 'zone-1',
            lng: 31.31,
            lat: 30.05,
            isContracted: true,
            commissionRate: 10,
            coveredProductIds: ['p1'],
          },
          {
            id: 'b2',
            zoneId: 'zone-1',
            lng: 31.41,
            lat: 30.15,
            isContracted: true,
            commissionRate: 15,
            coveredProductIds: ['p2'],
          },
        ]),
        getVendorUserIds: jest.fn().mockResolvedValue(['owner-v1']),
      };

      const mockCart: any = {
        validateForCheckout: jest.fn().mockResolvedValue({
          customerId: 'cust-1',
          coinBalance: 0,
          cart: {
            subtotal: 120,
            items: [
              {
                productId: 'p1',
                variantId: null,
                unitPrice: 70,
                quantity: 1,
                totalPrice: 70,
                selectedUnit: 'PIECE',
                product: { name: 'Item Branch 1' },
                options: [],
              },
              {
                productId: 'p2',
                variantId: null,
                unitPrice: 50,
                quantity: 1,
                totalPrice: 50,
                selectedUnit: 'PIECE',
                product: { name: 'Item Branch 2' },
                options: [],
              },
            ],
          },
        }),
        assertItemsAvailableAtBranch: jest.fn().mockResolvedValue(undefined),
        clearCart: jest.fn().mockResolvedValue(undefined),
      };

      const settingsObj: any = {
        maxMultiVendorVendors: 1,
        maxActiveOrdersPerCustomer: 5,
        requirePriorDeliveryForMultipleOrders: false,
        defaultTaxRate: 0,
        maxDeliveryRadiusKm: 100,
        extraVendorDeliveryFee: 10,
        minOrderAmount: 0,
      };
      const mockSettings: any = {
        getSettings: jest.fn().mockImplementation(async () => settingsObj),
        calculateDeliveryFee: jest.fn().mockResolvedValue(20),
      };

      const mockTx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          count: jest.fn().mockResolvedValue(0),
          findFirst: jest.fn(),
        },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({
            status: 'OPEN',
            deletedAt: null,
          }),
        },
        orderVendorFulfillment: {
          create: jest.fn().mockImplementation(async ({ data }) => {
            createdFulfillments.push(data);
            return data;
          }),
        },
        orderItem: {
          createMany: jest.fn().mockImplementation(async ({ data }) => {
            for (const row of data) {
              createdItemFulfillmentIds.push(row.fulfillmentId);
            }
            return { count: data.length };
          }),
        },
        orderItemOption: { createMany: jest.fn() },
        orderDeliveryGroup: { create: jest.fn().mockResolvedValue({}) },
        orderDeliveryGroupItem: {
          createMany: jest.fn().mockImplementation(async ({ data }) => {
            createdGroupItems.push(...data);
            return { count: data.length };
          }),
        },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
      };

      const mockPrisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'cust-1', coinBalance: 0 }) },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'v1',
            status: 'OPEN',
            deletedAt: null,
            isContracted: true,
            commissionRate: 10,
          }),
          findMany: jest.fn().mockResolvedValue([
            { id: 'v1', isContracted: true, commissionRate: 10 },
          ]),
        },
        vendorBranch: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'b1', isContracted: true, commissionRate: 10 },
            { id: 'b2', isContracted: true, commissionRate: 15 },
          ]),
        },
        order: { count: jest.fn().mockResolvedValue(0) },
        $transaction: jest.fn().mockImplementation(async (cb) => cb(mockTx)),
      };

      const mockGrouping: any = {
        planForCheckout: jest.fn().mockImplementation(async (stops) => ({
          isSplit: stops.length > 1,
          groups: stops.map((s: any, idx: number) => ({
            sequence: idx + 1,
            stops: [s],
            farthestToCustomerKm: 3,
            extraVendorCount: 0,
            splitReason: 'TOO_FAR_APART',
          })),
        })),
      };

      const multiVendorSvc = new OrdersMultiVendorService(
        mockPrisma,
        mockCart,
        mockSettings,
        {} as any,
        mockRepo,
        mockGrouping,
        { emit: jest.fn() } as any,
        { record: jest.fn().mockResolvedValue(undefined) } as any,
        { decrementForItems: jest.fn().mockResolvedValue(undefined) } as any,
      );

      const checkoutSvc = new OrdersCheckoutService(
        mockRepo,
        mockCart,
        mockSettings,
        { emit: jest.fn() } as any,
        mockPrisma,
        multiVendorSvc,
      );

      const actor = { sub: 'user-cust', role: Role.CUSTOMER } as any;
      const dto: any = {
        vendorId: 'v1',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        deliveryAddress: 'Nasr City',
        deliveryLocation: [31.33, 30.0444],
      };

      // With limit = 1, spanning 2 branches of v1 is rejected
      await expect(checkoutSvc.estimateOrder(actor, dto)).rejects.toThrow(
        OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED,
      );

      // With limit = 2, estimate & placeOrder succeed with 1 vendor and 2 branch fulfillments
      settingsObj.maxMultiVendorVendors = 2;
      const est = await checkoutSvc.estimateOrder(actor, dto);
      expect(est).toMatchObject({
        vendorCount: 1,
        branchCount: 2,
        deliveryCount: 2,
        isSplit: true,
        subtotal: 120,
      });

      const placed = await checkoutSvc.placeOrder(actor, dto);
      expect(placed).toEqual({ id: 'order-split-1' });
      expect(createdFulfillments).toHaveLength(2);
      expect(createdFulfillments.map((f) => [f.vendorId, f.vendorBranchId])).toEqual([
        ['v1', 'b1'],
        ['v1', 'b2'],
      ]);
      // Distinct fulfillment IDs preserved for both branches of same vendor
      expect(new Set(createdItemFulfillmentIds).size).toBe(2);
      expect(createdGroupItems.map((g) => g.fulfillmentId)).toEqual(
        createdFulfillments.map((f) => f.id),
      );
      expect(mockCart.clearCart).toHaveBeenCalledTimes(1);
    });

    it('rejects multi-vendor checkout when 2 vendors require 3 unique branches and maxMultiVendorVendors is 2', async () => {
      const mockRepo: any = {
        findByClientOrderKeyForUser: jest.fn().mockResolvedValue(null),
        getZoneAtLocation: jest.fn().mockResolvedValue({
          id: 'zone-1',
          baseDeliveryFeeOverride: null,
          minOrderAmountOverride: 0,
        }),
        getNearestOpenBranchLocation: jest.fn().mockImplementation(
          async (vendorId: string) =>
            vendorId === 'v2'
              ? {
                  id: 'b2',
                  zoneId: 'zone-1',
                  lng: 31.34,
                  lat: 30.05,
                  isContracted: true,
                }
              : null,
        ),
        getOpenBranchesWithProductAvailability: jest.fn().mockResolvedValue([
          {
            id: 'b1a',
            zoneId: 'zone-1',
            lng: 31.31,
            lat: 30.05,
            isContracted: true,
            coveredProductIds: ['p1'],
          },
          {
            id: 'b1b',
            zoneId: 'zone-1',
            lng: 31.32,
            lat: 30.06,
            isContracted: true,
            coveredProductIds: ['p2'],
          },
        ]),
      };

      const mockCart: any = {
        validateForCheckout: jest.fn().mockImplementation(async (_u, vid) => ({
          customerId: 'cust-1',
          coinBalance: 0,
          cart:
            vid === 'v1'
              ? {
                  subtotal: 100,
                  items: [
                    { productId: 'p1', unitPrice: 50, quantity: 1, totalPrice: 50, options: [] },
                    { productId: 'p2', unitPrice: 50, quantity: 1, totalPrice: 50, options: [] },
                  ],
                }
              : {
                  subtotal: 60,
                  items: [
                    { productId: 'p3', unitPrice: 60, quantity: 1, totalPrice: 60, options: [] },
                  ],
                },
        })),
        assertItemsAvailableAtBranch: jest.fn().mockResolvedValue(undefined),
      };

      const settingsObj: any = {
        maxMultiVendorVendors: 2,
        defaultTaxRate: 0,
        maxDeliveryRadiusKm: 100,
        extraVendorDeliveryFee: 10,
        minOrderAmount: 0,
      };
      const mockSettings: any = {
        getSettings: jest.fn().mockImplementation(async () => settingsObj),
        calculateDeliveryFee: jest.fn().mockResolvedValue(20),
      };

      const mockPrisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'cust-1', coinBalance: 0 }) },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({ status: 'OPEN', deletedAt: null, isContracted: true }),
          findMany: jest.fn().mockResolvedValue([
            { id: 'v1', isContracted: true },
            { id: 'v2', isContracted: true },
          ]),
        },
        vendorBranch: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'b1a', isContracted: true },
            { id: 'b1b', isContracted: true },
            { id: 'b2', isContracted: true },
          ]),
        },
      };

      const mockGrouping: any = {
        planForCheckout: jest.fn().mockResolvedValue({
          isSplit: false,
          groups: [
            {
              sequence: 1,
              stops: [
                { vendorId: 'v1', vendorBranchId: 'b1a' },
                { vendorId: 'v1', vendorBranchId: 'b1b' },
                { vendorId: 'v2', vendorBranchId: 'b2' },
              ],
              farthestToCustomerKm: 4,
              extraVendorCount: 2,
              splitReason: 'GROUPED',
            },
          ],
        }),
      };

      const svc = new OrdersMultiVendorService(
        mockPrisma,
        mockCart,
        mockSettings,
        {} as any,
        mockRepo,
        mockGrouping,
        { emit: jest.fn() } as any,
        {} as any,
      );

      // 2 unique vendors, 3 unique branches > max 2 -> rejected!
      await expect(
        svc.estimate(
          { sub: 'user-cust', role: Role.CUSTOMER } as any,
          {
            vendorIds: ['v1', 'v2'],
            paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
            deliveryAddress: 'Nasr City',
            deliveryLocation: [31.33, 30.0444],
          },
        ),
      ).rejects.toThrow(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);

      // Raising limit to 3 allows the 2-vendor / 3-branch checkout
      settingsObj.maxMultiVendorVendors = 3;
      const est = await svc.estimate(
        { sub: 'user-cust', role: Role.CUSTOMER } as any,
        {
          vendorIds: ['v1', 'v2'],
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          deliveryAddress: 'Nasr City',
          deliveryLocation: [31.33, 30.0444],
        },
      );
      expect(est.vendorCount).toBe(2);
      expect(est.branchCount).toBe(3);
    });

    it('formats repeated-vendor multi-branch store labels distinctly in OrderRoleProjector', async () => {
      const projector = new OrderRoleProjector(
        {} as any,
        { getSettings: jest.fn().mockResolvedValue({}) } as any,
        {} as any,
        { calculateDriverEarningsForFee: jest.fn().mockReturnValue(20) } as any,
      );

      const enriched = await projector.enrichWithAdminHelpers({
        id: 'order-mb-1',
        paymentMethod: 'CASH_ON_DELIVERY',
        grandTotal: 200,
        upfrontAmount: 0,
        deliveryFee: 30,
        subtotal: 170,
        vendorFulfillments: [
          {
            id: 'f1',
            vendorId: 'v1',
            subtotal: 100,
            status: 'PENDING',
            vendor: { storeName: 'Al Baik', storeNameAr: 'البيك', isContracted: true },
            vendorBranch: { name: 'Nasr City', nameAr: 'مدينة نصر', isContracted: true },
          },
          {
            id: 'f2',
            vendorId: 'v1',
            subtotal: 70,
            status: 'PENDING',
            vendor: { storeName: 'Al Baik', storeNameAr: 'البيك', isContracted: true },
            vendorBranch: { name: 'Maadi', nameAr: 'المعادي', isContracted: true },
          },
        ],
      });

      expect(enriched.vendor.storeName).toBe('Al Baik (Nasr City) + Al Baik (Maadi)');
      expect(enriched.vendor.storeNameAr).toBe('البيك (مدينة نصر) + البيك (المعادي)');
    });

    it('resolves branch, commission override, distanceKm, decidedByUserId, and branch vendor users in adminPlaceDirectOrder', async () => {
      const createOrderMock = jest.fn().mockResolvedValue({
        id: 'direct-ord-1',
        orderNumber: 'OTL-DIR-1',
        status: OrderStatus.ACCEPTED,
        created: true,
      });
      const getVendorUserIdsMock = jest.fn().mockResolvedValue(['u-branch-mgr']);
      const fulfillmentUpdateManyMock = jest.fn().mockResolvedValue({ count: 1 });
      const groupUpdateManyMock = jest.fn().mockResolvedValue({ count: 1 });

      const checkoutSvc = new OrdersCheckoutService(
        {
          getZoneAtLocation: jest.fn().mockResolvedValue({ id: 'zone-1' }),
          getNearestOpenBranchLocation: jest.fn().mockResolvedValue({
            id: 'br-direct-1',
            zoneId: 'zone-1',
            commissionRate: 18,
            isContracted: true,
            lng: 31.2,
            lat: 30.0,
          }),
          getDistanceKm: jest.fn().mockResolvedValue(4.2),
          generateOrderNumber: jest.fn().mockResolvedValue('OTL-DIR-1'),
          createOrder: createOrderMock,
          updateStatus: jest.fn().mockResolvedValue({ revision: 2 }),
          getVendorUserIds: getVendorUserIdsMock,
          findById: jest.fn().mockResolvedValue({ id: 'direct-ord-1' }),
        } as any,
        {} as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            defaultCommissionRate: 10,
            defaultTaxRate: 14,
            baseDeliveryFee: 20,
            pricePerKm: 5,
          }),
        } as any,
        { emit: jest.fn() } as any,
        {
          customer: {
            findUnique: jest.fn().mockResolvedValue({ id: 'cust-1', userId: 'u-cust-1' }),
          },
          order: {
            count: jest.fn().mockResolvedValue(0),
          },
          vendor: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'v-1',
              status: 'OPEN',
              deletedAt: null,
              commissionRate: 12,
              isContracted: false,
            }),
          },
          orderVendorFulfillment: { updateMany: fulfillmentUpdateManyMock },
          orderDeliveryGroup: { updateMany: groupUpdateManyMock },
        } as any,
        {} as any,
      );

      await checkoutSvc.adminPlaceDirectOrder(
        { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
        {
          customerId: 'u-cust-1',
          vendorId: 'v-1',
          price: 100,
          quantity: 2,
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          deliveryAddress: 'Maadi',
          deliveryLocation: [31.25, 29.96],
        } as any,
      );

      expect(createOrderMock).toHaveBeenCalledWith(
        expect.objectContaining({
          vendorBranchId: 'br-direct-1',
          distanceKm: 4.2,
          commissionRate: 18,
          isContracted: true,
        }),
        expect.any(Array),
        'admin-1',
      );
      expect(fulfillmentUpdateManyMock).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: 'ACCEPTED',
            decidedByUserId: 'admin-1',
            decidedAt: expect.any(Date),
          }),
        }),
      );
      expect(getVendorUserIdsMock).toHaveBeenCalledWith('v-1', 'br-direct-1');
    });

    it('accumulates owner notification subtotals across owned stores/branches and syncs late-accepted Group 2+ drivers into chat', async () => {
      const emitToUser = jest.fn().mockResolvedValue(undefined);
      const createMany = jest.fn().mockResolvedValue({ count: 2 });
      const addParticipantToOrderConversation = jest.fn().mockResolvedValue(undefined);
      const syncOrderDriverParticipants = jest.fn().mockResolvedValue(undefined);
      const createSystemOrderConversation = jest.fn().mockResolvedValue(undefined);

      const prisma: any = {
        orderVendorFulfillment: {
          findMany: jest.fn().mockResolvedValue([
            { vendorId: 'v-1', vendorBranchId: 'br-1', subtotal: 100 },
            { vendorId: 'v-2', vendorBranchId: 'br-2', subtotal: 150 },
          ]),
        },
        vendorMember: {
          findMany: jest.fn().mockResolvedValue([
            { userId: 'u-shared-owner', vendorId: 'v-1', role: 'OWNER', branchId: null },
            { userId: 'u-shared-owner', vendorId: 'v-2', role: 'OWNER', branchId: null },
            { userId: 'u-staff-b', vendorId: 'v-2', role: 'STAFF', branchId: 'br-2' },
            { userId: 'u-other-branch', vendorId: 'v-2', role: 'STAFF', branchId: 'br-other' },
          ]),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            type: 'STANDARD',
            customerId: 'cust-1',
            customer: { userId: 'u-cust-1' },
            vendorId: null,
            vendorFulfillments: [],
            deliveryGroups: [],
          }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([]),
        },
      };

      const handler = new OrderEventsHandler(
        { emitToUser } as any,
        { createMany, create: jest.fn() } as any,
        {} as any,
        {
          createSystemOrderConversation,
          addParticipantToOrderConversation,
          syncOrderDriverParticipants,
        } as any,
        prisma,
        { syncDriverActiveOrders: jest.fn().mockResolvedValue(undefined) } as any,
      );

      await handler.handleOrderCreated({
        orderId: 'ord-mv-owner',
        orderNumber: 'OTL-MV-OWNER',
        customerId: 'cust-1',
        customerUserId: 'u-cust-1',
        vendorId: null,
        vendorUserIds: [],
        grandTotal: 310,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        orderType: 'STANDARD',
        revision: 0,
      } as any);

      expect(emitToUser).toHaveBeenCalledWith(
        'u-shared-owner',
        'order.new',
        expect.objectContaining({ grandTotal: 250 }),
      );
      expect(emitToUser).toHaveBeenCalledWith(
        'u-staff-b',
        'order.new',
        expect.objectContaining({ grandTotal: 150 }),
      );
      expect(emitToUser).not.toHaveBeenCalledWith(
        'u-other-branch',
        'order.new',
        expect.anything(),
      );

      await handler.handleOrderStatusChanged({
        orderId: 'ord-mv-owner',
        orderNumber: 'OTL-MV-OWNER',
        oldStatus: OrderStatus.READY_FOR_PICKUP,
        newStatus: OrderStatus.PARTIALLY_PICKED_UP,
        customerId: 'cust-1',
        customerUserId: 'u-cust-1',
        vendorId: null,
        vendorUserIds: [],
        driverId: 'drv-2',
        driverUserId: 'u-drv-2',
        changedBy: 'u-drv-2',
        note: 'Group 2 driver joined',
        revision: 4,
      } as any);

      expect(addParticipantToOrderConversation).toHaveBeenCalledWith(
        'ord-mv-owner',
        'u-drv-2',
      );
      expect(syncOrderDriverParticipants).toHaveBeenCalledWith('ord-mv-owner');
    });

    it('ReviewsService legacy scalar vendorRating/driverRating rates all unrated delivered fulfillments and delivery groups', async () => {
      const createMany = jest.fn().mockResolvedValue({ count: 4 });
      const prisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'cust-1' }) },
        order: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'ord-rev-mv',
            status: OrderStatus.DELIVERED,
            customerId: 'cust-1',
            vendorFulfillments: [
              { id: 'ff-1', vendorId: 'v-1', deliveredAt: new Date() },
              { id: 'ff-2', vendorId: 'v-2', deliveredAt: new Date() },
            ],
            deliveryGroups: [
              {
                id: 'grp-1',
                status: DeliveryGroupStatus.DELIVERED,
                primaryDriverId: 'drv-1',
              },
              {
                id: 'grp-2',
                status: DeliveryGroupStatus.DELIVERED,
                primaryDriverId: 'drv-2',
              },
            ],
            reviews: [],
          }),
        },
        orderReview: { createMany },
      };

      const reviews = new ReviewsService(prisma, { emit: jest.fn() } as any);
      await reviews.submitReview(
        { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
        'ord-rev-mv',
        { vendorRating: 5, driverRating: 4, comment: 'Great' } as any,
      );

      expect(createMany).toHaveBeenCalledWith({
        data: expect.arrayContaining([
          expect.objectContaining({ fulfillmentId: 'ff-1', vendorId: 'v-1', rating: 5 }),
          expect.objectContaining({ fulfillmentId: 'ff-2', vendorId: 'v-2', rating: 5 }),
          expect.objectContaining({ deliveryGroupId: 'grp-1', driverId: 'drv-1', rating: 4 }),
          expect.objectContaining({ deliveryGroupId: 'grp-2', driverId: 'drv-2', rating: 4 }),
        ]),
      });
    });

    it('OrdersService.getVendorOrders("my") queries all owned vendor scopes and projects each order cleanly', async () => {
      const findMany = jest.fn().mockResolvedValue({
        orders: [
          {
            id: 'ord-b1',
            status: OrderStatus.PENDING,
            vendorFulfillments: [{ id: 'ff-b1', vendorId: 'v-b', vendorBranchId: 'br-b', status: 'PENDING', subtotal: 90 }],
          },
        ],
        total: 1,
        page: 1,
        limit: 20,
        totalPages: 1,
      });
      const prisma: any = {
        vendorMember: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'm1', vendorId: 'v-a', branchId: null, role: 'OWNER' },
            { id: 'm2', vendorId: 'v-b', branchId: 'br-b', role: 'STAFF' },
          ]),
        },
        user: { findUnique: jest.fn().mockResolvedValue({ permissions: [] }) },
      };
      const ordersRepo: any = { findMany };
      const ordersSvc = new OrdersService(
        ordersRepo,
        prisma,
        { getSettings: jest.fn().mockResolvedValue({}) } as any,
      );
      const projectSpy = jest
        .spyOn(ordersSvc, 'projectOrderForRole')
        .mockImplementation(async (o) => o);

      const res = await ordersSvc.getVendorOrders(
        { sub: 'u-multi', role: Role.VENDOR_MEMBER } as any,
        'my',
        {} as any,
      );

      expect(res.total).toBe(1);
      expect(findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          vendorScopes: [
            { vendorId: 'v-a', branchId: null },
            { vendorId: 'v-b', branchId: 'br-b' },
          ],
        }),
      );
      expect(projectSpy).toHaveBeenCalledWith(
        expect.anything(),
        expect.anything(),
        'v-b',
        expect.objectContaining({ vendorId: 'v-b', memberBranchId: 'br-b' }),
      );
    });
  });
});
