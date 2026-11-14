import { ForbiddenException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Role,
} from '@prisma/client';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import {
  ChatMessageSentEvent,
  OrderFulfillmentDecidedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { ChatListener } from '../../common/listeners/chat.listener';
import { OrderListener } from '../../common/listeners/order.listener';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import { SOCKET_EVENTS } from '../notifications/notifications.service';
import { DriverAssistMatchingService } from '../drivers/driver-assist-matching.service';
import { CancelOrderDto } from './dto/order.dto';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { OrdersStateService } from './orders-state.service';
import { OrderRoleProjector } from './projections/order-role.projector';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';

describe('Audit 8c1c1fa Backend Regressions', () => {
  const defaultSettings = {
    deliveryCommissionRate: 15,
    driverManagerCommissionRate: 10,
    stackedOrderDriverPercentage: 50,
    batchedDeliveryCommissionRate: 40,
    batchedDriverManagerCommissionRate: 10,
    multiVendorDeliveryCommissionRate: 20,
    multiVendorDriverManagerCommissionRate: 10,
    multiVendorDriverPercentage: 70,
    driverBonusPaidByCustomer: false,
  };

  function makeProjector(settingsOverrides: Record<string, any> = {}) {
    const settings = { ...defaultSettings, ...settingsOverrides };
    const platformSettings: any = {
      getSettings: jest.fn().mockResolvedValue(settings),
    };
    const prisma: any = {
      vendorMember: { findMany: jest.fn().mockResolvedValue([]) },
      driver: { findUnique: jest.fn() },
      user: { findUnique: jest.fn().mockResolvedValue({ permissions: [] }) },
    };
    const auth = new OrderAuthorizationHelper(prisma);
    const earnings = new OrderEarningsCalculator(platformSettings);
    return {
      projector: new OrderRoleProjector(prisma, platformSettings, auth, earnings),
      settings,
    };
  }

  describe('OrderRoleProjector driver / vendor / customer fixes', () => {
    it('zeroes cashToCollect for MOBILE_WALLET only when paymentStatus is COMPLETED', async () => {
      const { projector, settings } = makeProjector();
      const baseOrder = {
        id: 'ord-mw',
        status: 'READY_FOR_PICKUP',
        paymentMethod: PaymentMethod.MOBILE_WALLET,
        grandTotal: 250,
        upfrontAmount: 0,
        deliveryFee: 30,
        driverBonusFee: 0,
        items: [],
        vendorFulfillments: [],
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: 'READY_FOR_PICKUP',
            primaryDriverId: 'drv-1',
            assistDriverId: null,
            isPaymentCollector: true,
            deliveryFee: 30,
            items: [],
            primaryDriver: { id: 'drv-1', tier: 'BRONZE' },
          },
        ],
      };

      const paidProj = await projector.projectOrderForRole(
        { ...baseOrder, paymentStatus: 'COMPLETED' },
        { sub: 'u-drv-1', role: Role.DRIVER } as any,
        undefined,
        { driverId: 'drv-1', settings },
      );
      expect(paidProj.financials.isPrepaid).toBe(true);
      expect(paidProj.financials.cashToCollect).toBe(0);

      const unpaidProj = await projector.projectOrderForRole(
        { ...baseOrder, paymentStatus: 'PENDING' },
        { sub: 'u-drv-1', role: Role.DRIVER } as any,
        undefined,
        { driverId: 'drv-1', settings },
      );
      expect(unpaidProj.financials.isPrepaid).toBe(false);
      expect(unpaidProj.financials.cashToCollect).toBe(250);
    });

    it('gives assist driver 0 cashToCollect, 0 cashToPayStore, and assistFee earnings', async () => {
      const { projector, settings } = makeProjector();
      const order = {
        id: 'ord-assist',
        status: 'READY_FOR_PICKUP',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        grandTotal: 300,
        upfrontAmount: 0,
        deliveryFee: 50,
        driverBonusFee: 0,
        items: [{ id: 'i1', totalPrice: 250, fulfillmentId: 'f1' }],
        vendorFulfillments: [
          {
            id: 'f1',
            vendorId: 'v1',
            status: 'READY_FOR_PICKUP',
            vendor: { id: 'v1', storeName: 'Bakery', isContracted: false },
          },
        ],
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: 'READY_FOR_PICKUP',
            primaryDriverId: 'drv-primary',
            assistDriverId: 'drv-assist',
            isPaymentCollector: true,
            deliveryFee: 50,
            assistFee: 35,
            items: [{ id: 'gi1', fulfillmentId: 'f1', sequence: 1 }],
            primaryDriver: { id: 'drv-primary', tier: 'GOLD' },
          },
        ],
      };

      const assistProj = await projector.projectOrderForRole(
        order,
        { sub: 'u-assist', role: Role.DRIVER } as any,
        undefined,
        { driverId: 'drv-assist', settings },
      );

      expect(assistProj.isAssistDriver).toBe(true);
      expect(assistProj.isPrimaryDriver).toBe(false);
      expect(assistProj.financials.cashToCollect).toBe(0);
      expect(assistProj.financials.cashToPayStore).toBe(0);
      expect(assistProj.financials.driverEarnings).toBe(35);
      expect(assistProj.financials.storePayments[0].cashToPay).toBe(0);
    });

    it('prioritizes PICKED_UP group for activeDeliveryGroupId & projectedStatus when same driver owns 2 groups', async () => {
      const { projector, settings } = makeProjector();
      const order = {
        id: 'ord-2grp',
        status: 'DRIVER_ASSIGNED',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        grandTotal: 420,
        upfrontAmount: 0,
        deliveryFee: 70,
        driverBonusFee: 0,
        items: [
          { id: 'i1', totalPrice: 150, fulfillmentId: 'f1' },
          { id: 'i2', totalPrice: 200, fulfillmentId: 'f2' },
        ],
        vendorFulfillments: [
          {
            id: 'f1',
            vendorId: 'v1',
            status: 'READY_FOR_PICKUP',
            vendor: { id: 'v1', storeName: 'V1', isContracted: false },
          },
          {
            id: 'f2',
            vendorId: 'v2',
            status: 'PICKED_UP',
            pickedUpAt: new Date(),
            vendor: { id: 'v2', storeName: 'V2', isContracted: false },
          },
        ],
        deliveryGroups: [
          {
            id: 'grp-1',
            sequence: 1,
            status: 'READY_FOR_PICKUP',
            primaryDriverId: 'drv-1',
            assistDriverId: null,
            isPaymentCollector: false,
            deliveryFee: 35,
            items: [{ id: 'gi1', fulfillmentId: 'f1', sequence: 1 }],
            primaryDriver: { id: 'drv-1', tier: 'BRONZE' },
          },
          {
            id: 'grp-2',
            sequence: 2,
            status: 'PICKED_UP',
            primaryDriverId: 'drv-1',
            assistDriverId: null,
            isPaymentCollector: true,
            deliveryFee: 35,
            items: [{ id: 'gi2', fulfillmentId: 'f2', sequence: 1 }],
            primaryDriver: { id: 'drv-1', tier: 'BRONZE' },
          },
        ],
      };

      const proj = await projector.projectOrderForRole(
        order,
        { sub: 'u-drv-1', role: Role.DRIVER } as any,
        undefined,
        { driverId: 'drv-1', settings },
      );

      expect(proj.activeDeliveryGroupId).toBe('grp-2');
      expect(proj.status).toBe('PICKED_UP');
      expect(proj.vendorFulfillments.map((f: any) => f.deliveryGroupId)).toEqual([
        'grp-2',
        'grp-1',
      ]);
      expect(proj.financials.storePayments[0].deliveryGroupId).toBeDefined();
    });

    it('zeroes vendor subtotal & commission when all of a vendor’s portions are REJECTED/CANCELLED', async () => {
      const { projector, settings } = makeProjector();
      const order = {
        id: 'ord-v-dead',
        status: 'PREPARING',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        grandTotal: 200,
        vendorId: 'v1',
        items: [
          { id: 'i1', totalPrice: 100, fulfillmentId: 'f1', vendorId: 'v1' },
          { id: 'i2', totalPrice: 200, fulfillmentId: 'f2', vendorId: 'v2' },
        ],
        vendorFulfillments: [
          {
            id: 'f1',
            vendorId: 'v1',
            status: 'REJECTED',
            subtotal: 100,
            commissionRate: 15,
            vendor: { id: 'v1', commissionRate: 15 },
          },
          {
            id: 'f2',
            vendorId: 'v2',
            status: 'ACCEPTED',
            subtotal: 200,
            commissionRate: 10,
            vendor: { id: 'v2', commissionRate: 10 },
          },
        ],
        deliveryGroups: [],
      };

      const proj = await projector.projectForVendor(
        order,
        { sub: 'u-v1', role: Role.VENDOR_MEMBER } as any,
        'v1',
        { vendorId: 'v1', memberBranchId: null },
      );

      expect(proj.financials.storeSubtotal).toBe(0);
      expect(proj.financials.commissionAmount).toBe(0);
      expect(proj.financials.netPayout).toBe(0);
      expect(proj.financials.cashToCollectFromDriver).toBe(0);
    });

    it('projects customerDriverBonusFee according to driverBonusPaidByCustomer setting', async () => {
      const { projector: projFalse, settings: sFalse } = makeProjector({
        driverBonusPaidByCustomer: false,
      });
      const baseCustomerOrder = {
        id: 'ord-c-bonus',
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        grandTotal: 120,
        upfrontAmount: 0,
        deliveryFee: 20,
        driverBonusFee: 15,
        items: [],
        vendorFulfillments: [],
        deliveryGroups: [],
      };

      const outFalse = projFalse.projectForCustomer(baseCustomerOrder, {
        settings: sFalse,
      });
      expect(outFalse.driverBonusPaidByCustomer).toBe(false);
      expect(outFalse.customerDriverBonusFee).toBe(0);
      expect(outFalse.financials.customerDriverBonusFee).toBe(0);

      const { projector: projTrue, settings: sTrue } = makeProjector({
        driverBonusPaidByCustomer: true,
      });
      const outTrue = projTrue.projectForCustomer(baseCustomerOrder, {
        settings: sTrue,
      });
      expect(outTrue.driverBonusPaidByCustomer).toBe(true);
      expect(outTrue.customerDriverBonusFee).toBe(15);
      expect(outTrue.financials.customerDriverBonusFee).toBe(15);
    });
  });

  describe('DeliveryGroupTransitionService assist driver gates', () => {
    it('allows assist driver to advance PICKED_UP but blocks DELIVERED and PENDING_PAYMENT', async () => {
      const prisma: any = {
        orderDeliveryGroup: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              status: DeliveryGroupStatus.PICKED_UP,
              primaryDriverId: 'drv-primary',
              assistDriverId: 'drv-assist',
            },
          ]),
        },
        orderDeliveryGroupItem: {
          findMany: jest.fn().mockResolvedValue([{ fulfillmentId: 'f1' }]),
        },
        orderVendorFulfillment: {
          findMany: jest.fn().mockResolvedValue([{ status: 'PICKED_UP' }]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-1',
            status: OrderStatus.READY_FOR_PICKUP,
          }),
        },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
        $transaction: jest.fn((cb: any) => cb(prisma)),
      };
      const ordersRepo: any = {
        findById: jest.fn().mockResolvedValue({ id: 'ord-1', status: OrderStatus.PICKED_UP }),
        updateStatus: jest.fn().mockResolvedValue({ revision: 2 }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const svc = new DeliveryGroupTransitionService(
        prisma,
        ordersRepo,
        { emit: jest.fn() } as any,
      );

      const order = {
        id: 'ord-1',
        orderNumber: 'OTL-1',
        customerId: 'c1',
        customer: { userId: 'u-c1' },
        status: OrderStatus.READY_FOR_PICKUP,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        paymentStatus: 'PENDING',
        vendorId: null,
        vendorBranchId: null,
        driverId: 'drv-primary',
        driver: { userId: 'u-p' },
      };
      const groups: any[] = [
        {
          id: 'grp-1',
          sequence: 1,
          status: DeliveryGroupStatus.READY_FOR_PICKUP,
          primaryDriverId: 'drv-primary',
          assistDriverId: 'drv-assist',
          isPaymentCollector: true,
          deliveryFee: 30,
          pickupImageUrl: null,
          deliveryImageUrl: null,
        },
      ];
      const assistActor: any = { sub: 'u-assist', role: Role.DRIVER };

      await expect(
        svc.advanceGroupByDriver(assistActor, order, 'drv-assist', groups, {
          status: OrderStatus.DELIVERED,
        } as any),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        svc.advanceGroupByDriver(assistActor, order, 'drv-assist', groups, {
          status: OrderStatus.PENDING_PAYMENT,
        } as any),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        svc.advanceGroupByDriver(assistActor, order, 'drv-assist', groups, {
          status: OrderStatus.PICKED_UP,
          pickupImageUrl: 'https://cdn.test/pick.jpg',
        } as any),
      ).resolves.toBeDefined();
    });
  });

  describe('OrdersStateService.adminForceAssignDriver & CancelOrderDto', () => {
    it('allows adminForceAssignDriver when order is already DRIVER_ASSIGNED', async () => {
      const assignDriverMock = jest.fn().mockResolvedValue({
        id: 'ord-re',
        orderNumber: 'OTL-RE',
        status: OrderStatus.DRIVER_ASSIGNED,
        vendorId: null,
        customerId: 'c1',
        customer: { userId: 'u-c1' },
        items: [],
      });
      const freeDriverMock = jest.fn().mockResolvedValue(undefined);
      const prisma: any = {
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-new',
            userId: 'u-drv-new',
            isApproved: true,
            deletedAt: null,
            hasUnpaidCommission: false,
          }),
        },
        platformSetting: {
          findUnique: jest.fn().mockResolvedValue({ maxActiveOrdersPerDriver: 2 }),
        },
        driverShift: { findFirst: jest.fn().mockResolvedValue(null) },
        order: {
          findUnique: jest.fn().mockResolvedValue({ status: OrderStatus.DRIVER_ASSIGNED }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              primaryDriverId: 'drv-old',
              deliveryFee: 30,
            },
          ]),
          update: jest.fn().mockResolvedValue({}),
        },
        orderVendorFulfillment: {
          findMany: jest.fn().mockResolvedValue([]),
        },
      };
      const ordersRepo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-re',
          status: OrderStatus.DRIVER_ASSIGNED,
          paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
          paymentStatus: 'PENDING',
          vendorId: null,
          customerId: 'c1',
        }),
        assignDriver: assignDriverMock,
        freeDriver: freeDriverMock,
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const svc = new OrdersStateService(
        ordersRepo,
        {} as any,
        {} as any,
        { emit: jest.fn() } as any,
        prisma,
        {} as any,
        undefined,
        undefined,
        undefined,
        undefined,
        { countActiveUnits: jest.fn().mockResolvedValue(0) } as any,
      );

      await svc.adminForceAssignDriver(
        { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
        'ord-re',
        { driverId: 'drv-new' },
      );

      expect(assignDriverMock).toHaveBeenCalled();
      expect(freeDriverMock).toHaveBeenCalledWith('drv-old');
    });

    it('validates CancelOrderDto optional reason cleanly', async () => {
      expect(
        await validate(plainToInstance(CancelOrderDto, {})),
      ).toHaveLength(0);
      expect(
        await validate(
          plainToInstance(CancelOrderDto, { reason: 'Customer requested cancellation' }),
        ),
      ).toHaveLength(0);
    });
  });

  describe('DriverAssistMatchingService, OrderVendorDecisionService & Listeners', () => {
    it('enriches pending assist offers with orderNumber, reason, deliveryGroupId, and proposedAssistFee', async () => {
      const redisMock: any = {
        set: jest.fn().mockResolvedValue(undefined),
        scanKeys: jest.fn().mockResolvedValue(['assist:offer:req-1']),
        get: jest.fn().mockResolvedValue(
          JSON.stringify({
            driverIds: ['drv-2'],
            orderId: 'ord-1',
            orderNumber: 'OTL-77',
            deliveryGroupId: 'grp-1',
            reason: 'Heavy groceries',
            proposedAssistFee: 45,
            expiresAt: new Date(Date.now() + 60_000).toISOString(),
          }),
        ),
      };
      const prisma: any = {
        driver: { findUnique: jest.fn().mockResolvedValue({ id: 'drv-2' }) },
      };
      const matching = new DriverAssistMatchingService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
        redisMock,
      );

      const offers = await matching.getPendingAssistOffers({
        sub: 'u-drv-2',
        role: Role.DRIVER,
      } as any);

      expect(offers).toHaveLength(1);
      expect(offers[0]).toMatchObject({
        id: 'req-1',
        requestId: 'req-1',
        orderId: 'ord-1',
        orderNumber: 'OTL-77',
        deliveryGroupId: 'grp-1',
        reason: 'Heavy groceries',
        proposedAssistFee: 45,
        order: { id: 'ord-1', orderNumber: 'OTL-77' },
      });
    });

    it('emits parentStatus and revision after maybeAdvanceToDispatch on accept and forwards them in OrderListener', async () => {
      const callOrder: string[] = [];
      const emitMock = jest.fn(() => callOrder.push('emit'));
      const prisma: any = {
        orderVendorFulfillment: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ff-1',
            orderId: 'ord-1',
            vendorId: 'v-1',
            vendorBranchId: 'br-1',
            status: OrderVendorFulfillmentStatus.PENDING,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findMany: jest.fn().mockImplementation(async (args: any) => {
            callOrder.push('advance');
            if (args?.select?.status) {
              return [{ id: 'ff-1', status: OrderVendorFulfillmentStatus.ACCEPTED }];
            }
            return [];
          }),
        },
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValueOnce({ status: OrderStatus.PENDING })
            .mockResolvedValueOnce({
              orderNumber: 'OTL-99',
              status: OrderStatus.LOOKING_FOR_DRIVER,
              revision: 3,
              customerId: 'c1',
              customer: { userId: 'u-c1' },
            }),
        },
      };
      const decisionSvc = new OrderVendorDecisionService(
        prisma,
        {
          findById: jest.fn().mockResolvedValue({
            id: 'ord-1',
            status: OrderStatus.ACCEPTED,
            orderNumber: 'OTL-99',
          }),
          getVendorUserIds: jest.fn().mockResolvedValue(['u-v1']),
        } as any,
        {} as any,
        {} as any,
        { emit: emitMock } as any,
      );
      jest
        .spyOn(decisionSvc as any, 'assertVendorMember')
        .mockResolvedValue({
          id: 'ff-1',
          orderId: 'ord-1',
          vendorId: 'v-1',
          vendorBranchId: 'br-1',
          status: OrderVendorFulfillmentStatus.PENDING,
        });
      jest
        .spyOn(decisionSvc as any, 'maybeAdvanceToDispatch')
        .mockImplementation(async () => {
          callOrder.push('maybeAdvanceToDispatch');
        });

      await decisionSvc.accept(
        { sub: 'u-v1', role: Role.VENDOR_MEMBER } as any,
        'ff-1',
      );

      expect(callOrder.indexOf('maybeAdvanceToDispatch')).toBeLessThan(
        callOrder.indexOf('emit'),
      );
      expect(emitMock).toHaveBeenCalledWith(
        EVENTS.ORDER_FULFILLMENT_DECIDED,
        expect.objectContaining({
          status: OrderVendorFulfillmentStatus.ACCEPTED,
          parentStatus: OrderStatus.LOOKING_FOR_DRIVER,
          revision: 3,
        }),
      );

      const socketService: any = { emitToUser: jest.fn().mockResolvedValue(undefined) };
      const orderListener = new OrderListener(
        socketService,
        { add: jest.fn() } as any,
        {} as any,
        {} as any,
      );
      orderListener.handleOrderFulfillmentDecided(
        new OrderFulfillmentDecidedEvent(
          'ord-1',
          'OTL-99',
          'c1',
          'u-c1',
          'ff-1',
          'v-1',
          ['u-v1'],
          OrderVendorFulfillmentStatus.ACCEPTED,
          'u-v1',
          [],
          OrderStatus.LOOKING_FOR_DRIVER,
          3,
        ),
      );
      expect(socketService.emitToUser).toHaveBeenCalledWith(
        'u-c1',
        'order.status',
        expect.objectContaining({
          status: OrderStatus.LOOKING_FOR_DRIVER,
          newStatus: OrderStatus.LOOKING_FOR_DRIVER,
          parentStatus: OrderStatus.LOOKING_FOR_DRIVER,
          orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
          fulfillmentStatus: OrderVendorFulfillmentStatus.ACCEPTED,
          revision: 3,
        }),
      );
    });

    it('includes orderId in ChatListener socket payload and queued CHAT_MESSAGE notification data', async () => {
      const socketService: any = { emitToUser: jest.fn().mockResolvedValue(undefined) };
      const eventsQueue: any = { add: jest.fn().mockResolvedValue(undefined) };
      const chatListener = new ChatListener(socketService, eventsQueue);

      await chatListener.handleMessageSent(
        new ChatMessageSentEvent(
          'msg-1',
          'conv-1',
          'u-1',
          'Ali',
          'CUSTOMER',
          ['u-1', 'u-2'],
          'Hello',
          'TEXT',
          null,
          null,
          new Date(),
          'ORDER',
          null,
          null,
          null,
          'ord-chat-1',
        ),
      );

      expect(socketService.emitToUser).toHaveBeenCalledWith(
        'u-2',
        SOCKET_EVENTS.CHAT_MESSAGE,
        expect.objectContaining({
          conversationId: 'conv-1',
          orderId: 'ord-chat-1',
        }),
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.CHAT_NOTIFICATIONS,
        expect.objectContaining({
          dtos: expect.arrayContaining([
            expect.objectContaining({
              userId: 'u-2',
              data: expect.objectContaining({
                conversationId: 'conv-1',
                orderId: 'ord-chat-1',
              }),
            }),
          ]),
        }),
        expect.anything(),
      );
    });
  });
});
