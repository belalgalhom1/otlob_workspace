import { OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';

describe('Multi-vendor fulfillment orders', () => {
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

  describe('checkout', () => {
    it('creates ONE parent order and one numbered fulfillment per vendor', async () => {
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
        },
        orderItem: {
          createMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderItemOption: {
          createMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
        orderDeliveryGroup: { create: jest.fn().mockResolvedValue({}) },
        orderDeliveryGroupItem: {
          createMany: jest.fn().mockResolvedValue({ count: 2 }),
        },
      };

      const prisma: any = {
        $transaction: jest.fn(async (cb: any) => cb(tx)),
      };
      const ordersRepository: any = {
        generateOrderNumber: jest.fn().mockResolvedValue('ORD-1042'),
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

      jest.spyOn(service as any, 'buildPlan').mockResolvedValue(plan as any);

      await service.placeOrder(
        { sub: 'user-1' } as any,
        {
          vendorIds: ['vendor-a', 'vendor-b'],
          paymentMethod: 'CASH_ON_DELIVERY',
          deliveryAddress: '1 Test Street',
          deliveryLocation: [31.2, 30.0],
          specialRequest: null,
        } as any,
      );

      // No child orders: exactly one `INSERT INTO orders`.
      const orderInserts = tx.$executeRaw.mock.calls.filter(([strings]: any[]) =>
        strings.join('').includes('INSERT INTO orders'),
      );
      expect(orderInserts).toHaveLength(1);

      // One portion per vendor, each with its own stable display number.
      expect(tx.orderVendorFulfillment.create).toHaveBeenCalledTimes(2);
      const portions = tx.orderVendorFulfillment.create.mock.calls.map(
        ([arg]: any[]) => arg.data,
      );
      expect(portions.map((p: any) => p.vendorId).sort()).toEqual([
        'vendor-a',
        'vendor-b',
      ]);
      expect(portions.map((p: any) => p.displayNumber).sort()).toEqual([
        'ORD-1042-V1',
        'ORD-1042-V2',
      ]);
      // All portions hang off the same single parent order insert.
      const insertedOrderId = orderInserts[0][1];
      expect(new Set(portions.map((p: any) => p.orderId))).toEqual(
        new Set([insertedOrderId]),
      );

      // Every item belongs to exactly one portion.
      const itemRows = tx.orderItem.createMany.mock.calls.flatMap(
        ([arg]: any[]) => arg.data,
      );
      expect(itemRows).toHaveLength(2);
      const portionIds = new Set(portions.map((p: any) => p.id));
      for (const row of itemRows) {
        expect(portionIds.has(row.fulfillmentId)).toBe(true);
        expect(row.orderId).toBe(insertedOrderId);
      }
      const bread = itemRows.find((r: any) => r.productName === 'Bread');
      const juice = itemRows.find((r: any) => r.productName === 'Juice');
      expect(bread.totalPrice).toBe(100);
      expect(juice.totalPrice).toBe(200);

      // Parent status is recorded once, not once per portion.
      expect(tx.orderStatusEvent.create).toHaveBeenCalledTimes(1);
    });
  });

  describe('vendor list/detail isolation', () => {
    const buildFulfillment = (vendor: 'a' | 'b') => ({
      id: `ff-${vendor}`,
      orderId: 'order-1',
      displayNumber: `ORD-1042-V${vendor === 'a' ? 1 : 2}`,
      vendorId: `vendor-${vendor}`,
      vendorBranchId: `branch-${vendor}`,
      status: 'PENDING',
      subtotal: vendor === 'a' ? 100 : 200,
      commissionRate: vendor === 'a' ? 10 : 15,
      preparingAt: null,
      readyAt: null,
      pickedUpAt: null,
      deliveredAt: null,
      createdAt: new Date('2026-01-01T10:00:00Z'),
      vendor: {
        id: `vendor-${vendor}`,
        storeName: vendor === 'a' ? 'Bakery' : 'Juice Bar',
        storeNameAr: vendor === 'a' ? 'مخبز' : 'عصائر',
        isContracted: true,
      },
      vendorBranch: {
        id: `branch-${vendor}`,
        name: `Branch ${vendor}`,
        nameAr: `فرع ${vendor}`,
        isContracted: true,
        commissionRate: vendor === 'a' ? 10 : 15,
      },
      items: [
        {
          id: `item-${vendor}`,
          fulfillmentId: `ff-${vendor}`,
          productName: vendor === 'a' ? 'Bread' : 'Juice',
          quantity: 2,
          totalPrice: vendor === 'a' ? 100 : 200,
        },
      ],
      groups: [
        { deliveryGroup: { id: 'group-1', sequence: 1, status: 'PENDING' } },
      ],
      order: {
        id: 'order-1',
        orderNumber: 'ORD-1042',
        status: 'PENDING',
        paymentMethod: 'CASH_ON_DELIVERY',
        paymentStatus: 'PENDING',
        deliveryAddress: '1 Test Street',
        specialRequest: 'Ring the bell',
        createdAt: new Date('2026-01-01T10:00:00Z'),
        customer: {
          id: 'customer-1',
          user: { id: 'user-customer', name: 'Customer', phone: '+201234567890' },
        },
      },
    });

    const buildService = (rows: any[]) => {
      const repository: any = {
        findMany: jest.fn(),
        findVendorFulfillments: jest.fn(async ({ vendorId }: any) => ({
          fulfillments: rows.filter((r) => r.vendorId === vendorId),
          total: rows.filter((r) => r.vendorId === vendorId).length,
          page: 1,
          limit: 20,
          totalPages: 1,
        })),
        findVendorFulfillmentById: jest.fn(async (id: string) =>
          rows.find((r) => r.id === id) ?? null,
        ),
      };
      const prisma: any = {
        vendorMember: {
          findUnique: jest.fn(async ({ where }: any) => ({
            id: 'member-1',
            vendorId: where.vendorId_userId.vendorId,
            branchId: null,
            role: 'OWNER',
          })),
          findFirst: jest.fn(),
        },
        user: {
          findUnique: jest.fn().mockResolvedValue({ permissions: [] }),
        },
      };
      return {
        service: new OrdersService(repository, prisma, {} as any),
        repository,
      };
    };

    it('returns only the calling vendor’s portion, items and number', async () => {
      const rows = [buildFulfillment('a'), buildFulfillment('b')];
      const { service } = buildService(rows);

      const resultA: any = await service.getVendorOrders(
        { sub: 'user-a', role: 'VENDOR_MEMBER' } as any,
        'vendor-a',
        {} as any,
      );

      expect(resultA.total).toBe(1);
      const orderA = resultA.orders[0];
      expect(orderA.id).toBe('ff-a');
      expect(orderA.orderId).toBe('order-1');
      expect(orderA.myFulfillmentId).toBe('ff-a');
      expect(orderA.displayNumber).toBe('ORD-1042-V1');
      expect(orderA.items).toHaveLength(1);
      expect(orderA.items[0].productName).toBe('Bread');
      expect(orderA.items.some((i: any) => i.productName === 'Juice')).toBe(
        false,
      );
      expect(orderA.subtotal).toBe(100);
      expect(orderA.financials.netPayout).toBe(90);
      expect(orderA.deliveryAddress).toBe('1 Test Street');
      expect(orderA.notes).toBe('Ring the bell');
      // Pending portion: phone is masked.
      expect(orderA.phone).not.toBe('+201234567890');
      expect(orderA.customer.phone).toBe(orderA.phone);

      const resultB: any = await service.getVendorOrders(
        { sub: 'user-b', role: 'VENDOR_MEMBER' } as any,
        'vendor-b',
        {} as any,
      );
      const orderB = resultB.orders[0];
      expect(orderB.id).toBe('ff-b');
      expect(orderB.displayNumber).toBe('ORD-1042-V2');
      expect(orderB.items[0].productName).toBe('Juice');
      expect(orderB.subtotal).toBe(200);
    });

    it('serves a single portion detail without leaking siblings', async () => {
      const rows = [buildFulfillment('a'), buildFulfillment('b')];
      const { service } = buildService(rows);

      const detail: any = await service.getVendorFulfillment(
        { sub: 'user-a', role: 'VENDOR_MEMBER' } as any,
        'ff-a',
      );

      expect(detail.id).toBe('ff-a');
      expect(detail.items).toHaveLength(1);
      expect(detail.vendorFulfillments).toHaveLength(1);
      expect(detail.vendorFulfillments[0].id).toBe('ff-a');
    });
  });

  describe('admin projection', () => {
    it('includes items, fulfilments and a per-vendor breakdown', async () => {
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
        id: 'order-1',
        orderNumber: 'ORD-1042',
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
        items: [],
        vendorFulfillments: [
          {
            id: 'ff-a',
            displayNumber: 'ORD-1042-V1',
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
            items: [
              {
                id: 'item-a',
                productName: 'Bread',
                quantity: 2,
                unitPrice: 50,
                totalPrice: 100,
              },
            ],
          },
          {
            id: 'ff-b',
            displayNumber: 'ORD-1042-V2',
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
            items: [
              {
                id: 'item-b',
                productName: 'Juice',
                quantity: 2,
                unitPrice: 100,
                totalPrice: 200,
              },
            ],
          },
        ],
      };

      const admin: any = await (service as any).enrichWithAdminHelpers(parent);

      expect(admin.isMultiVendor).toBe(true);
      expect(admin.items).toHaveLength(2);
      expect(admin.vendorFulfillments).toHaveLength(2);
      expect(admin.vendorBreakdown).toHaveLength(2);

      const [a, b] = admin.vendorBreakdown;
      expect(a.displayNumber).toBe('ORD-1042-V1');
      expect(a.vendorName).toBe('مخبز');
      expect(a.items[0].productName).toBe('Bread');
      expect(a.netPayout).toBe(90);

      expect(b.displayNumber).toBe('ORD-1042-V2');
      expect(b.vendorName).toBe('عصائر');
      expect(b.items[0].productName).toBe('Juice');
      expect(b.status).toBe('ACCEPTED');

      expect(admin.financials.storePayments).toHaveLength(2);
    });
  });

  describe('vendor status derivation', () => {
    it('derives status from the portion, not the aggregate order', async () => {
      const service = new OrdersService({} as any, {} as any, {} as any);
      const base = {
        id: 'ff-a',
        orderId: 'order-1',
        displayNumber: 'ORD-1042-V1',
        vendorId: 'vendor-a',
        vendorBranchId: 'branch-a',
        status: 'PREPARING',
        subtotal: 100,
        commissionRate: 10,
        preparingAt: new Date('2026-01-01T10:05:00Z'),
        readyAt: null,
        pickedUpAt: null,
        deliveredAt: null,
        vendor: { storeName: 'Bakery', isContracted: true },
        vendorBranch: { name: 'Branch A', isContracted: true },
        items: [],
        groups: [
          { deliveryGroup: { id: 'g1', status: 'READY_FOR_PICKUP' } },
        ],
        order: {
          id: 'order-1',
          orderNumber: 'ORD-1042',
          // Another vendor already pushed the aggregate to PREPARING.
          status: 'PREPARING',
          paymentMethod: 'CASH_ON_DELIVERY',
          paymentStatus: 'PENDING',
          customer: { user: { phone: '+201234567890' } },
          createdAt: new Date('2026-01-01T10:00:00Z'),
        },
      };

      const projected: any = (service as any).projectFulfillmentForVendor({
        ...base,
      });
      expect(projected.status).toBe('READY_FOR_PICKUP');
      expect(projected.orderStatus).toBe('PREPARING');

      const delivered: any = (service as any).projectFulfillmentForVendor({
        ...base,
        status: 'PICKED_UP',
        pickedUpAt: new Date('2026-01-01T10:30:00Z'),
        groups: [{ deliveryGroup: { id: 'g1', status: 'PICKED_UP' } }],
      });
      expect(delivered.status).toBe('PICKED_UP');
      // Phone becomes visible once the portion left PENDING.
      expect(delivered.phone).toBe('+201234567890');
    });
  });
});
