import { OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';

describe('Parent/child orders (multi-vendor checkout)', () => {
  describe('OrdersMultiVendorService.placeOrder', () => {
    const buildPlan = () => ({
      customerId: 'customer-1',
      zoneId: 'zone-1',
      subtotal: 300,
      deliveryFee: 20,
      driverBonusFee: 0,
      serviceFee: 5,
      tax: 10,
      coinsUsed: 0,
      discount: 0,
      coinsEarned: 0,
      grandTotal: 335,
      upfrontAmount: 0,
      groupFees: [20],
      portions: [
        {
          vendorId: 'vendor-a',
          vendorBranchId: 'branch-a',
          subtotal: 100,
          commissionRate: 10,
          items: [
            {
              productId: null,
              variantId: null,
              productName: 'Bread',
              variantName: null,
              unitPrice: 50,
              quantity: 2,
              selectedUnit: null,
              baseUnitPrice: 50,
              totalPrice: 100,
              specialRequest: null,
              options: [],
            },
          ],
        },
        {
          vendorId: 'vendor-b',
          vendorBranchId: 'branch-b',
          subtotal: 200,
          commissionRate: 15,
          items: [
            {
              productId: null,
              variantId: null,
              productName: 'Juice',
              variantName: null,
              unitPrice: 100,
              quantity: 2,
              selectedUnit: null,
              baseUnitPrice: 100,
              totalPrice: 200,
              specialRequest: null,
              options: [],
            },
          ],
        },
      ],
      grouping: {
        isSplit: false,
        groups: [
          {
            sequence: 1,
            farthestToCustomerKm: 2,
            extraVendorCount: 1,
            splitReason: null,
            stops: [
              { vendorId: 'vendor-a', vendorBranchId: 'branch-a' },
              { vendorId: 'vendor-b', vendorBranchId: 'branch-b' },
            ],
          },
        ],
      },
    });

    it('creates one parent order plus one child order per vendor', async () => {
      const plan = buildPlan();
      const parentOrderId = 'parent-order-1';

      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        order: {
          findUnique: jest.fn(),
          count: jest.fn().mockResolvedValue(0),
          findFirst: jest.fn().mockResolvedValue(null),
        },
        vendor: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: 'OPEN', deletedAt: null }),
        },
        orderVendorFulfillment: {
          create: jest.fn().mockResolvedValue({}),
          count: jest.fn().mockResolvedValue(0),
          deleteMany: jest.fn(),
        },
        orderItem: {
          createMany: jest.fn().mockResolvedValue({ count: 1 }),
          deleteMany: jest.fn(),
        },
        orderItemOption: {
          createMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
        orderDeliveryGroup: { create: jest.fn().mockResolvedValue({}) },
        orderDeliveryGroupItem: {
          createMany: jest.fn().mockResolvedValue({ count: 2 }),
        },
        orderDeliveryGroupDelete: jest.fn(),
      };

      const prisma: any = {
        $transaction: jest.fn(async (cb: any) => cb(tx)),
      };
      const ordersRepository: any = {
        generateOrderNumber: jest
          .fn()
          .mockResolvedValueOnce('ORD-PARENT')
          .mockResolvedValueOnce('ORD-CHILD-A')
          .mockResolvedValueOnce('ORD-CHILD-B'),
        getVendorUserIds: jest.fn().mockResolvedValue([]),
        findById: jest.fn().mockResolvedValue({ id: parentOrderId }),
      };
      const service = new OrdersMultiVendorService(
        prisma,
        { clearCart: jest.fn().mockResolvedValue(undefined) } as any,
        {} as any,
        {
          validateActiveOrderLimit: jest
            .fn()
            .mockResolvedValue({ maxActive: 3, requirePriorDelivery: false }),
        } as any,
        ordersRepository,
        {} as any,
        { emit: jest.fn() } as any,
        { record: jest.fn().mockResolvedValue(undefined) } as any,
      );

      jest
        .spyOn(service as any, 'buildPlan')
        .mockResolvedValue(plan as any);

      const dto: any = {
        vendorIds: ['vendor-a', 'vendor-b'],
        paymentMethod: 'CASH_ON_DELIVERY',
        deliveryAddress: '1 Test Street',
        deliveryLocation: [31.2, 30.0],
        specialRequest: null,
      };

      await service.placeOrder({ sub: 'user-1' } as any, dto);

      // One canonical portion per vendor on the parent order.
      expect(tx.orderVendorFulfillment.create).toHaveBeenCalledTimes(2);
      const portionVendors = tx.orderVendorFulfillment.create.mock.calls.map(
        ([arg]: any[]) => arg.data.vendorId,
      );
      expect(portionVendors.sort()).toEqual(['vendor-a', 'vendor-b']);

      // Parent insert + two child inserts (all raw SQL).
      const inserts = tx.$executeRaw.mock.calls
        .map(([strings, ...values]: any[]) => ({ strings, values }))
        .filter((call: any) =>
          call.strings.join('').includes('INSERT INTO orders'),
        );
      expect(inserts).toHaveLength(3);

      const parentInsert = inserts[0];
      expect(parentInsert.values[0]).toEqual(expect.any(String));

      const childInserts = inserts.slice(1);
      const childOrderIds = childInserts.map((c: any) => c.values[0]);
      expect(new Set(childOrderIds).size).toBe(2);
      expect(childOrderIds).not.toContain(parentOrderId);
      for (const child of childInserts) {
        // parentOrderId + sourceFulfillmentId are bound right after the child
        // id/number/NULL client key.
        expect(child.values[2]).toBe(parentInsert.values[0]);
        expect(child.values[3]).toMatch(/^[0-9a-f-]{36}$/);
      }

      // Parent items + one copy per child order.
      const itemWrites = tx.orderItem.createMany.mock.calls.map(
        ([arg]: any[]) => arg.data,
      );
      expect(itemWrites).toHaveLength(4);
      const parentWrites = itemWrites.filter((rows: any[]) =>
        rows.every((row) => row.orderId === parentInsert.values[0]),
      );
      expect(parentWrites).toHaveLength(2);
      const childWrites = itemWrites.filter(
        (rows: any[]) =>
          rows.length === 1 && childOrderIds.includes(rows[0].orderId),
      );
      expect(childWrites).toHaveLength(2);

      // Each child item copy belongs to exactly one vendor's child order and
      // keeps the same product/quantity/price as the parent line.
      const childA = childWrites.find(
        (rows: any[]) => rows[0].productName === 'Bread',
      )!;
      const childB = childWrites.find(
        (rows: any[]) => rows[0].productName === 'Juice',
      )!;
      expect(childA[0].quantity).toBe(2);
      expect(childA[0].unitPrice).toBe(50);
      expect(childB[0].quantity).toBe(2);
      expect(childB[0].unitPrice).toBe(100);

      // Parent status event + one PENDING event per child.
      expect(tx.orderStatusEvent.create).toHaveBeenCalledTimes(3);
      const eventOrderIds = tx.orderStatusEvent.create.mock.calls.map(
        ([arg]: any[]) => arg.data.orderId,
      );
      for (const childId of childOrderIds) {
        expect(eventOrderIds).toContain(childId);
      }
    });
  });

  describe('OrdersRepository.findMany scoping', () => {
    const buildRepository = () => {
      const prisma: any = {
        order: {
          findMany: jest.fn().mockResolvedValue([]),
          count: jest.fn().mockResolvedValue(0),
        },
      };
      return {
        repository: new OrdersRepository(prisma, {} as any),
        prisma,
      };
    };

    it('lists only the vendor’s own order rows and excludes the parent', async () => {
      const { repository, prisma } = buildRepository();

      await repository.findMany({ vendorId: 'vendor-a', page: 1, limit: 20 });

      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.parentOrderId).toBeUndefined();
      expect(where.AND).toEqual(
        expect.arrayContaining([{ vendorId: 'vendor-a' }]),
      );
    });

    it('shows customers/admins/drivers only the parent aggregate', async () => {
      const { repository, prisma } = buildRepository();

      await repository.findMany({ customerId: 'customer-1', page: 1, limit: 20 });

      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.parentOrderId).toBeNull();
      expect(where.customerId).toBe('customer-1');
    });

    it('filters vendor tabs by the child order status directly', async () => {
      const { repository, prisma } = buildRepository();

      await repository.findMany({
        vendorId: 'vendor-a',
        status: 'PENDING' as any,
        page: 1,
        limit: 20,
      });

      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.status).toBe('PENDING');
      expect(where.AND).toEqual(
        expect.arrayContaining([{ vendorId: 'vendor-a' }]),
      );
    });

    it('keeps an admin vendor filter on parent orders', async () => {
      const { repository, prisma } = buildRepository();

      await repository.findMany({
        vendorId: 'vendor-a',
        parentOrdersOnly: true,
        page: 1,
        limit: 20,
      });

      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.parentOrderId).toBeNull();
      expect(JSON.stringify(where.AND)).toContain('vendorFulfillments');
    });

    it('matches an admin vendor status tab against that vendor’s portion', async () => {
      const { repository, prisma } = buildRepository();

      await repository.findMany({
        vendorId: 'vendor-a',
        parentOrdersOnly: true,
        status: 'PENDING' as any,
        page: 1,
        limit: 20,
      });

      const where = prisma.order.findMany.mock.calls[0][0].where;
      // The aggregate status is NOT used: a sibling vendor accepting must not
      // move this vendor's PENDING portion out of the New tab.
      expect(where.status).toBeUndefined();
      expect(JSON.stringify(where.AND)).toContain('"status":"PENDING"');
      expect(JSON.stringify(where.AND)).toContain('vendorFulfillments');
    });
  });

  describe('OrdersService vendor projection', () => {
    it('projects a child order with only that vendor’s items and a synthetic fulfillment', async () => {
      const service = new OrdersService(
        {} as any,
        { vendorMember: { findFirst: jest.fn() } } as any,
        {} as any,
      );

      const childOrder = {
        id: 'child-a',
        orderNumber: 'ORD-CHILD-A',
        parentOrderId: 'parent-1',
        sourceFulfillmentId: 'ff-a',
        vendorId: 'vendor-a',
        vendorBranchId: 'branch-a',
        status: 'PREPARING',
        subtotal: 100,
        grandTotal: 100,
        items: [
          {
            id: 'child-item-a',
            productName: 'Bread',
            quantity: 2,
            unitPrice: 50,
            totalPrice: 100,
          },
        ],
        vendor: { storeName: 'Bakery', isContracted: true, commissionRate: 10 },
        vendorBranch: { name: 'Branch A', isContracted: true, commissionRate: 10 },
      };

      const projected = await (service as any).projectForVendor(
        childOrder,
        { sub: 'user-vendor-a' } as any,
        'vendor-a',
      );

      expect(projected.isChildOrder).toBe(true);
      expect(projected.items).toHaveLength(1);
      expect(projected.items[0].productName).toBe('Bread');
      expect(projected.myFulfillmentId).toBe('ff-a');
      expect(projected.vendorFulfillments).toHaveLength(1);
      expect(projected.vendorFulfillments[0].id).toBe('ff-a');
      expect(projected.vendorFulfillments[0].orderId).toBe('parent-1');
      expect(projected.subtotal).toBe(100);
      expect(projected.grandTotal).toBe(100);
    });
  });

  describe('OrdersService.enrichWithAdminHelpers', () => {
    it('exposes both vendor child orders inside one parent order', async () => {
      const service = new OrdersService(
        {} as any,
        {} as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            deliveryCommissionRate: 20,
            driverManagerCommissionRate: 10,
          }),
        } as any,
      );

      const parent = {
        id: 'parent-1',
        orderNumber: 'ORD-PARENT',
        status: 'PENDING',
        paymentMethod: 'CASH_ON_DELIVERY',
        paymentStatus: 'PENDING',
        subtotal: 300,
        deliveryFee: 20,
        serviceFee: 5,
        tax: 10,
        driverBonusFee: 0,
        discount: 0,
        grandTotal: 335,
        vendorId: null,
        vendor: null,
        vendorBranch: null,
        vendorFulfillments: [
          {
            id: 'ff-a',
            vendorId: 'vendor-a',
            status: 'PENDING',
            subtotal: 100,
            commissionRate: 10,
            vendor: {
              storeName: 'Bakery',
              storeNameAr: 'مخبز',
              isContracted: true,
            },
            vendorBranch: {
              name: 'Branch A',
              nameAr: 'فرع أ',
              isContracted: true,
            },
            items: [],
          },
          {
            id: 'ff-b',
            vendorId: 'vendor-b',
            status: 'ACCEPTED',
            subtotal: 200,
            commissionRate: 15,
            vendor: {
              storeName: 'Juice Bar',
              storeNameAr: 'عصائر',
              isContracted: true,
            },
            vendorBranch: {
              name: 'Branch B',
              nameAr: 'فرع ب',
              isContracted: true,
            },
            items: [],
          },
        ],
        childOrders: [
          {
            id: 'child-a',
            orderNumber: 'ORD-CHILD-A',
            parentOrderId: 'parent-1',
            vendorId: 'vendor-a',
            status: 'PENDING',
            subtotal: 100,
            grandTotal: 100,
            paymentStatus: 'PENDING',
            vendor: { storeName: 'Bakery', storeNameAr: 'مخبز' },
            vendorBranch: { name: 'Branch A', nameAr: 'فرع أ' },
            items: [
              {
                id: 'child-item-a',
                productName: 'Bread',
                quantity: 2,
                unitPrice: 50,
                totalPrice: 100,
              },
            ],
          },
          {
            id: 'child-b',
            orderNumber: 'ORD-CHILD-B',
            parentOrderId: 'parent-1',
            vendorId: 'vendor-b',
            status: 'ACCEPTED',
            subtotal: 200,
            grandTotal: 200,
            paymentStatus: 'PENDING',
            vendor: { storeName: 'Juice Bar', storeNameAr: 'عصائر' },
            vendorBranch: { name: 'Branch B', nameAr: 'فرع ب' },
            items: [
              {
                id: 'child-item-b',
                productName: 'Juice',
                quantity: 2,
                unitPrice: 100,
                totalPrice: 200,
              },
            ],
          },
        ],
        items: [],
      };

      const admin = await (service as any).enrichWithAdminHelpers(parent);

      expect(admin.isMultiVendor).toBe(true);
      expect(admin.vendorOrders).toHaveLength(2);

      const [orderA, orderB] = admin.vendorOrders;
      expect(orderA.vendorName).toBe('مخبز');
      expect(orderA.status).toBe('PENDING');
      expect(orderA.items[0]).toMatchObject({
        productName: 'Bread',
        quantity: 2,
        unitPrice: 50,
        totalPrice: 100,
      });

      expect(orderB.vendorName).toBe('عصائر');
      expect(orderB.status).toBe('ACCEPTED');
      expect(orderB.items[0]).toMatchObject({
        productName: 'Juice',
        quantity: 2,
        unitPrice: 100,
        totalPrice: 200,
      });

      // The parent still carries the canonical fulfillments for settlement.
      expect(admin.vendorFulfillments).toHaveLength(2);
      expect(admin.financials.storePayments).toHaveLength(2);
    });
  });
});
