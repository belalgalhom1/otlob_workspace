import {
  DeliveryGroupStatus,
  DriverStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Role,
} from '@prisma/client';
import {
  recordOrderStatusEventIdempotent,
  sanitizeCancelReason,
} from './helpers/order-actor.helper';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { OrderQueriesRepository } from './repositories/order-queries.repository';
import { WalletService } from '../wallet/wallet.service';
import { DriversRepository } from '../drivers/drivers.repository';
import { UsersService } from '../users/users.service';
import { EVENTS } from '../../common/events/event-names';

describe('Order Activity Log Deduplication, Cancellation Actor, Avatars & Driver Wallet Notes', () => {
  describe('recordOrderStatusEventIdempotent', () => {
    it('ignores Prisma P2002 duplicate eventKey cleanly without throwing', async () => {
      const prismaErr = Object.assign(new Error('Unique constraint'), {
        code: 'P2002',
      });
      const tx = {
        orderStatusEvent: {
          create: jest
            .fn()
            .mockResolvedValueOnce({ id: 'ev-1' })
            .mockRejectedValueOnce(prismaErr),
        },
      };

      const first = await recordOrderStatusEventIdempotent(tx, {
        orderId: 'ord-1',
        eventKey: 'fulfillment_ready:ff-1',
        status: OrderStatus.PREPARING,
        note: 'Store A: ready for pickup',
      });
      const second = await recordOrderStatusEventIdempotent(tx, {
        orderId: 'ord-1',
        eventKey: 'fulfillment_ready:ff-1',
        status: OrderStatus.PREPARING,
        note: 'Store A: ready for pickup',
      });

      expect(first.created).toBe(true);
      expect(second.created).toBe(false);
    });
  });

  describe('Multi-store readiness events produce distinct store-labeled idempotent entries', () => {
    it('labels each vendor portion with its store/branch name and unique fulfillment eventKey', async () => {
      const createdEvents: any[] = [];
      const mockPrisma: any = {
        orderDeliveryGroupItem: {
          findFirst: jest.fn().mockResolvedValue({ deliveryGroupId: 'grp-1' }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            sequence: 1,
            status: DeliveryGroupStatus.PREPARING,
            estimatedPrepTime: 15,
          }),
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.READY_FOR_PICKUP,
              isPaymentCollector: true,
              primaryDriverId: 'drv-1',
            },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderVendorFulfillment: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findMany: jest
            .fn()
            .mockResolvedValueOnce([
              {
                status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
                readyAt: new Date(),
              },
              { status: OrderVendorFulfillmentStatus.PREPARING, readyAt: null },
            ])
            .mockResolvedValueOnce([
              {
                status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
                readyAt: new Date(),
              },
              {
                status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
                readyAt: new Date(),
              },
            ]),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            orderNumber: 'ORD-100',
            status: OrderStatus.PREPARING,
            revision: 3,
            customerId: 'cust-1',
            paymentMethod: 'CASH_ON_DELIVERY',
            upfrontAmount: 0,
            paymentStatus: 'PENDING',
            customer: { userId: 'u-cust' },
            vendorFulfillments: [{ vendorId: 'v-1' }, { vendorId: 'v-2' }],
          }),
        },
        orderStatusEvent: {
          create: jest.fn((args: any) => {
            createdEvents.push(args.data);
            return Promise.resolve({
              id: `ev-${createdEvents.length}`,
              ...args.data,
            });
          }),
        },
        user: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'u-v1',
            name: 'Staff 1',
            role: Role.VENDOR_MEMBER,
            avatar: null,
            vendorMemberships: [
              {
                vendorId: 'v-1',
                vendor: {
                  id: 'v-1',
                  storeName: 'test2',
                  storeNameAr: null,
                  logo: '/media/v1.webp',
                },
              },
              {
                vendorId: 'v-2',
                vendor: {
                  id: 'v-2',
                  storeName: 'test',
                  storeNameAr: null,
                  logo: '/media/v2.webp',
                },
              },
            ],
          }),
        },
      };

      const orderGraph = {
        id: 'ord-1',
        orderNumber: 'ORD-100',
        status: OrderStatus.PREPARING,
        revision: 3,
        customerId: 'cust-1',
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'v-1',
            status: OrderVendorFulfillmentStatus.PREPARING,
            vendor: { storeName: 'test2', logo: '/media/v1.webp' },
            vendorBranch: { name: 'haha' },
          },
          {
            id: 'ff-2',
            vendorId: 'v-2',
            status: OrderVendorFulfillmentStatus.PREPARING,
            vendor: { storeName: 'test', logo: '/media/v2.webp' },
            vendorBranch: { name: 'Abu zabaal' },
          },
        ],
      };

      const mockRepo: any = {
        findById: jest.fn().mockResolvedValue(orderGraph),
        getOrderVendorUserIds: jest.fn().mockResolvedValue(['u-v1', 'u-v2']),
        updateStatus: jest.fn().mockResolvedValue({ revision: 4 }),
      };
      const service = new FulfillmentTransitionService(
        mockPrisma,
        mockRepo,
        {} as any,
        { emit: jest.fn() } as any,
        {} as any,
      );

      await service.applyFulfillmentProductionTransition(
        { sub: 'u-v1', role: Role.VENDOR_MEMBER } as any,
        orderGraph,
        { id: 'ff-1', status: OrderVendorFulfillmentStatus.PREPARING },
        { status: OrderStatus.READY_FOR_PICKUP },
      );
      await service.applyFulfillmentProductionTransition(
        { sub: 'u-v1', role: Role.VENDOR_MEMBER } as any,
        orderGraph,
        { id: 'ff-2', status: OrderVendorFulfillmentStatus.PREPARING },
        { status: OrderStatus.READY_FOR_PICKUP },
      );

      expect(createdEvents).toHaveLength(2);
      expect(createdEvents[0].eventKey).toBe('fulfillment_ready:ff-1');
      expect(createdEvents[0].note).toBe('test2 (haha): ready for pickup');
      expect(createdEvents[1].eventKey).toBe('fulfillment_ready:ff-2');
      expect(createdEvents[1].note).toBe('test (Abu zabaal): ready for pickup');
    });
  });

  describe('OrderQueriesRepository activity deduplication & actor enrichment', () => {
    it('collapses exact duplicates while preserving distinct On the Way / Preparing events and recovers cancellation actor', async () => {
      const t1 = new Date('2026-11-20T01:56:00.000Z');
      const t2 = new Date('2026-11-20T01:56:02.000Z');
      const t3 = new Date('2026-11-20T01:58:00.000Z');
      const t4 = new Date('2026-11-20T01:58:10.000Z');
      const t5 = new Date('2026-11-20T01:59:00.000Z');
      const t6 = new Date('2026-11-20T01:59:05.000Z');

      const rawOrder = {
        id: 'ord-hist',
        status: OrderStatus.CANCELLED,
        cancelReason: null,
        cancelledByUserId: null,
        cancelledAt: null,
        customer: {
          user: {
            id: 'u-cust',
            name: 'Mona',
            phone: '010',
            avatar: '/media/cust.webp',
          },
        },
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'v-1',
            status: 'REJECTED',
            decidedByUserId: 'u-vend',
            decidedAt: t6,
            rejectionReason: 'Out of stock',
            vendor: {
              id: 'v-1',
              storeName: 'Fresh Mart',
              storeNameAr: 'فريش مارت',
              logo: '/media/v1.webp',
            },
            vendorBranch: { id: 'b-1', name: 'Maadi', nameAr: 'المعادي' },
          },
          {
            id: 'ff-2',
            vendorId: 'v-2',
            status: 'READY_FOR_PICKUP',
            vendor: {
              id: 'v-2',
              storeName: 'Bakery',
              storeNameAr: 'المخبز',
              logo: '/media/v2.webp',
            },
            vendorBranch: { id: 'b-2', name: 'Zamalek', nameAr: 'الزمالك' },
          },
        ],
        deliveryGroups: [
          {
            id: 'grp-1',
            primaryDriver: {
              id: 'drv-1',
              name: 'Karim',
              avatar: null,
              user: {
                id: 'u-drv',
                name: 'Karim',
                phone: '011',
                avatar: '/media/drv.webp',
              },
            },
            assistDriver: null,
          },
        ],
        statusEvents: [
          // Exact duplicate preparing event #1 and #2 (same fulfillment & note) -> collapse to ONE
          {
            id: 'e-dup-b',
            orderId: 'ord-hist',
            fulfillmentId: 'ff-1',
            deliveryGroupId: 'grp-1',
            status: OrderStatus.PREPARING,
            note: 'Delivery 1: vendor portion ready for pickup',
            createdBy: 'u-vend',
            createdAt: new Date(t1.getTime() + 500),
          },
          {
            id: 'e-dup-a',
            orderId: 'ord-hist',
            fulfillmentId: 'ff-1',
            deliveryGroupId: 'grp-1',
            status: OrderStatus.PREPARING,
            note: 'Delivery 1: vendor portion ready for pickup',
            createdBy: 'u-vend',
            createdAt: t1,
          },
          // Different fulfillment under Preparing -> MUST BE PRESERVED
          {
            id: 'e-prep-2',
            orderId: 'ord-hist',
            fulfillmentId: 'ff-2',
            deliveryGroupId: 'grp-1',
            status: OrderStatus.PREPARING,
            note: 'Delivery 1: vendor portion ready for pickup',
            createdBy: 'u-vend2',
            createdAt: t2,
          },
          // Three separate legitimate On the Way (PICKED_UP) events -> ALL MUST BE PRESERVED
          {
            id: 'e-otw-1',
            orderId: 'ord-hist',
            fulfillmentId: null,
            deliveryGroupId: null,
            status: OrderStatus.PICKED_UP,
            note: 'All deliveries picked up',
            createdBy: 'u-drv',
            createdAt: t3,
          },
          {
            id: 'e-otw-2',
            orderId: 'ord-hist',
            fulfillmentId: 'ff-2',
            deliveryGroupId: 'grp-1',
            status: OrderStatus.PICKED_UP,
            note: 'Driver picked up fulfillment stop ff-2',
            createdBy: 'u-drv',
            createdAt: t4,
          },
          {
            id: 'e-otw-3',
            orderId: 'ord-hist',
            fulfillmentId: null,
            deliveryGroupId: 'grp-1',
            status: OrderStatus.PICKED_UP,
            note: 'Delivery 1: PICKED_UP → DELIVERED',
            createdBy: 'u-drv',
            createdAt: t5,
          },
          // Legacy system cancel from vendor rejection
          {
            id: 'e-cancel',
            orderId: 'ord-hist',
            fulfillmentId: null,
            deliveryGroupId: null,
            status: OrderStatus.CANCELLED,
            note: 'Cancelled by user',
            createdBy: 'system',
            createdAt: t6,
          },
        ],
      };

      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue(rawOrder),
        },
        $queryRaw: jest.fn().mockResolvedValue([]),
        user: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'u-vend',
              name: 'Ahmed Owner',
              role: Role.VENDOR_MEMBER,
              avatar: '/media/user-v1.webp',
              vendorMemberships: [
                {
                  vendorId: 'v-1',
                  vendor: {
                    id: 'v-1',
                    storeName: 'Fresh Mart',
                    storeNameAr: 'فريش مارت',
                    logo: '/media/v1.webp',
                  },
                },
              ],
            },
            {
              id: 'u-vend2',
              name: 'Sara Staff',
              role: Role.VENDOR_MEMBER,
              avatar: null,
              vendorMemberships: [
                {
                  vendorId: 'v-2',
                  vendor: {
                    id: 'v-2',
                    storeName: 'Bakery',
                    storeNameAr: 'المخبز',
                    logo: '/media/v2.webp',
                  },
                },
              ],
            },
            {
              id: 'u-drv',
              name: 'Karim',
              role: Role.DRIVER,
              avatar: null,
              driver: { id: 'drv-1', name: 'Karim', avatar: '/media/drv.webp' },
              vendorMemberships: [],
            },
          ]),
        },
      };

      const repo = new OrderQueriesRepository(prisma);
      const result = await repo.findById('ord-hist');

      // 7 input rows - 1 true duplicate = 6 distinct chronological events
      expect(result.statusEvents).toHaveLength(6);
      // Preserves all 3 On the Way events
      const pickedUpEvents = result.statusEvents.filter(
        (e: any) => e.status === OrderStatus.PICKED_UP,
      );
      expect(pickedUpEvents).toHaveLength(3);
      expect(
        pickedUpEvents.some(
          (e: any) => e.note === 'Driver picked up from Bakery (Zamalek)',
        ),
      ).toBe(true);

      // Preserves both separate store Preparing events with store labels and earliest timestamp t1
      const preparingEvents = result.statusEvents.filter(
        (e: any) => e.status === OrderStatus.PREPARING,
      );
      expect(preparingEvents).toHaveLength(2);
      expect(
        preparingEvents.find((e: any) => e.fulfillmentId === 'ff-1')?.createdAt,
      ).toEqual(t1);
      expect(
        preparingEvents.find((e: any) => e.fulfillmentId === 'ff-1')?.note,
      ).toBe('Fresh Mart (Maadi): vendor portion ready for pickup');
      expect(
        preparingEvents.find((e: any) => e.fulfillmentId === 'ff-2')?.note,
      ).toBe('Bakery (Zamalek): vendor portion ready for pickup');

      // Driver avatar coalesced from User.avatar
      expect(result.deliveryGroups[0].primaryDriver.avatar).toBe(
        '/media/drv.webp',
      );

      // Legacy placeholder 'Cancelled by user' + system recovered to real rejecting Vendor!
      expect(sanitizeCancelReason('Cancelled by user')).toBeNull();
      expect(result.cancelledBy).toMatchObject({
        userId: 'u-vend',
        name: 'Fresh Mart',
        nameAr: 'فريش مارت',
        role: Role.VENDOR_MEMBER,
        avatar: '/media/v1.webp',
        reason: 'Out of stock',
        isSystem: false,
      });
    });
  });

  describe('OrderCancellationService preserves exact actor name, role & avatar across all roles', () => {
    it.each([
      [Role.CUSTOMER, 'Omar Customer', '/media/c.webp'],
      [Role.ADMIN, 'Nour Admin', '/media/a.webp'],
      [Role.SUPER_ADMIN, 'Super Khaled', '/media/sa.webp'],
    ])(
      'resolves %s cancellation actor properly',
      async (role, expectedName, expectedAvatar) => {
        const prisma: any = {
          user: {
            findUnique: jest.fn().mockResolvedValue({
              id: `u-${role}`,
              name: expectedName,
              role,
              avatar: expectedAvatar,
              driver: null,
              vendorMemberships: [],
            }),
          },
          orderDeliveryGroup: { findMany: jest.fn().mockResolvedValue([]) },
        };
        const ordersRepo: any = {
          findById: jest.fn().mockResolvedValue({
            id: 'ord-c',
            orderNumber: 'ORD-55',
            status: OrderStatus.PENDING,
            coinsUsed: 0,
            customerId: 'cust-1',
            customer: { userId: `u-${role}`, user: { id: 'u-cust' } },
            vendorFulfillments: [{ vendorId: 'v-1' }],
          }),
          getOrderVendorUserIds: jest.fn().mockResolvedValue(['u-v1']),
          cancelOrder: jest.fn().mockResolvedValue({
            id: 'ord-c',
            revision: 2,
            customer: { user: { id: 'u-cust' } },
            deliveryGroups: [],
          }),
        };
        const eventEmitter: any = { emit: jest.fn() };
        const service = new OrderCancellationService(
          ordersRepo,
          prisma,
          { canManageOrders: jest.fn().mockResolvedValue(true) } as any,
          eventEmitter,
        );

        await service.cancelOrder(
          { sub: `u-${role}`, role } as any,
          'ord-c',
          'Out of coverage',
        );

        expect(ordersRepo.cancelOrder).toHaveBeenCalledWith(
          'ord-c',
          `u-${role}`,
          'Out of coverage',
          OrderStatus.PENDING,
          0,
          'cust-1',
          'ORD-55',
          [],
          expect.objectContaining({
            actor: expect.objectContaining({
              actorUserId: `u-${role}`,
              actorRole: role,
              actorName: expectedName,
              actorAvatar: expectedAvatar,
            }),
          }),
        );
        expect(eventEmitter.emit).toHaveBeenCalledWith(
          EVENTS.ORDER_CANCELLED,
          expect.objectContaining({
            cancelledByUserId: `u-${role}`,
            cancelledByName: expectedName,
            cancelledByRole: role,
            cancelledByAvatar: expectedAvatar,
          }),
        );
      },
    );
  });

  describe('Driver Wallet adjustment notes saving, retrieval, sanitization & avatar sync', () => {
    it('saves Super Admin note, omits idempotencyKey and generic fallbacks on driver read, and scopes strictly by driverId', async () => {
      const createdPayloads: any[] = [];
      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue([{ walletBalance: 100 }]),
        driver: { update: jest.fn().mockResolvedValue({ walletBalance: 150 }) },
        driverWalletTransaction: {
          findUnique: jest.fn().mockResolvedValue(null),
          create: jest.fn((args: any) => {
            createdPayloads.push(args.data);
            return Promise.resolve({ id: 'tx-1', ...args.data });
          }),
        },
      };
      const prisma: any = {
        driver: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'drv-own', walletBalance: 100 }),
        },
        driverWalletTransaction: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'tx-with-note',
              driverId: 'drv-own',
              type: 'ADJUSTMENT',
              amount: 50,
              balanceAfter: 150,
              description: 'Weekend rain surge bonus',
              note: 'Weekend rain surge bonus',
              isManualAdjustment: true,
              referenceId: null,
              createdAt: new Date('2026-11-20T01:00:00Z'),
              order: null,
            },
            {
              id: 'tx-no-note',
              driverId: 'drv-own',
              type: 'ADJUSTMENT',
              amount: 20,
              balanceAfter: 170,
              description: 'Manual Admin Transaction',
              note: null,
              isManualAdjustment: true,
              referenceId: null,
              createdAt: new Date('2026-11-20T00:00:00Z'),
              order: null,
            },
          ]),
          count: jest.fn().mockResolvedValue(2),
        },
        $transaction: jest.fn((cb: any) => cb(tx)),
      };

      const wallet = new WalletService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
      );
      await wallet.processDriverTransaction('drv-own', {
        type: 'BONUS',
        amount: 50,
        description: '  Weekend rain surge bonus  ',
      });
      await wallet.processDriverTransaction('drv-own', {
        type: 'ADJUSTMENT',
        amount: 20,
        description: '',
      });

      expect(createdPayloads[0]).toMatchObject({
        note: 'Weekend rain surge bonus',
        description: 'Weekend rain surge bonus',
        isManualAdjustment: true,
      });
      expect(createdPayloads[1]).toMatchObject({
        note: null,
        description: 'Manual Admin Transaction',
        isManualAdjustment: true,
      });

      const driverTxs = await wallet.getDriverTransactions('u-drv-own');
      expect(prisma.driverWalletTransaction.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { driverId: 'drv-own' },
        }),
      );
      expect(driverTxs[0].note).toBe('Weekend rain surge bonus');
      expect(driverTxs[0].isManualAdjustment).toBe(true);
      expect((driverTxs[0] as any).idempotencyKey).toBeUndefined();
      // Adjustment with no real note MUST return null, never fake empty/default note
      expect(driverTxs[1].note).toBeNull();

      const driversRepo = new DriversRepository(prisma);
      const paged = await driversRepo.getWalletTransactions('drv-own', 1, 20);
      expect(paged.transactions[0].note).toBe('Weekend rain surge bonus');
      expect(paged.transactions[1].note).toBeNull();
    });

    it('synchronizes Driver.avatar and User.avatar on upload/update', async () => {
      const prisma: any = {
        user: {
          findUnique: jest.fn().mockResolvedValue({ avatar: null }),
          update: jest.fn().mockResolvedValue({}),
        },
        driver: {
          update: jest.fn().mockResolvedValue({
            id: 'drv-1',
            avatar: '/media/avatars/new.webp',
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      const storage: any = {
        upload: jest.fn().mockResolvedValue('/media/avatars/new.webp'),
        delete: jest.fn(),
      };
      const driversRepo = new DriversRepository(prisma);
      await driversRepo.updateAvatar('drv-1', '/media/drivers/a.webp');
      expect(prisma.driver.update).toHaveBeenCalledWith({
        where: { id: 'drv-1' },
        data: {
          avatar: '/media/drivers/a.webp',
          user: { update: { avatar: '/media/drivers/a.webp' } },
        },
      });

      const usersSvc = new UsersService(prisma, storage, {} as any);
      await usersSvc.uploadAvatar('u-1', { buffer: Buffer.from('x') } as any);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'u-1' },
        data: { avatar: '/media/avatars/new.webp' },
      });
      expect(prisma.driver.updateMany).toHaveBeenCalledWith({
        where: { userId: 'u-1' },
        data: { avatar: '/media/avatars/new.webp' },
      });
    });
  });
});
