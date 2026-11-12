import { OrdersService } from './orders.service';

describe('OrdersService financial projections & vendor isolation', () => {
  let ordersService: OrdersService;
  let mockPrisma: any;

  beforeEach(() => {
    mockPrisma = {
      vendorMember: { findFirst: jest.fn() },
      driver: { findUnique: jest.fn() },
      customer: { findUnique: jest.fn() },
    };

    ordersService = new OrdersService(
      {} as any,
      mockPrisma,
      {
        getSettings: jest.fn().mockResolvedValue({
          deliveryCommissionRate: 20,
          driverManagerCommissionRate: 10,
        }),
      } as any,
    );
  });

  describe('projectForDriver', () => {
    it('calculates net cashToPay for contracted store and full cashToPay for uncontracted store', async () => {
      const actor = { sub: 'user-driver-1' } as any;
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });

      const mockOrder = {
        id: 'order-123',
        status: 'READY_FOR_PICKUP',
        paymentMethod: 'CASH_ON_DELIVERY',
        paymentStatus: 'PENDING',
        deliveryFee: 40,
        deliveryGroups: [
          {
            id: 'group-1',
            sequence: 1,
            primaryDriverId: 'driver-1',
            deliveryFee: 40,
            status: 'READY_FOR_PICKUP',
            items: [
              { fulfillmentId: 'ff-contracted', sequence: 1 },
              { fulfillmentId: 'ff-uncontracted', sequence: 2 },
            ],
          },
        ],
        vendorFulfillments: [
          {
            id: 'ff-contracted',
            vendorId: 'vendor-contracted',
            subtotal: 500,
            commissionRate: 20,
            vendor: {
              name: 'Contracted Restaurant',
              isContracted: true,
              commissionRate: 20,
            },
            vendorBranch: {
              name: 'Branch 1',
              isContracted: true,
              commissionRate: 20,
            },
          },
          {
            id: 'ff-uncontracted',
            vendorId: 'vendor-uncontracted',
            subtotal: 300,
            commissionRate: 15,
            vendor: {
              name: 'Uncontracted Supermarket',
              isContracted: false,
              commissionRate: 15,
            },
            vendorBranch: {
              name: 'Branch 2',
              isContracted: false,
              commissionRate: 15,
            },
          },
        ],
        items: [],
      };

      const projected = await (ordersService as any).projectForDriver(mockOrder, actor);

      expect(projected.financials).toBeDefined();
      const storePayments = projected.financials.storePayments;
      expect(storePayments).toHaveLength(2);

      // Contracted store: 500 EGP - 20% (100 EGP) = 400 EGP
      const contractedPayment = storePayments.find((p: any) => p.fulfillmentId === 'ff-contracted');
      expect(contractedPayment.isContracted).toBe(true);
      expect(contractedPayment.subtotal).toBe(500);
      expect(contractedPayment.commissionAmount).toBe(100);
      expect(contractedPayment.cashToPay).toBe(400);

      // Uncontracted store: 300 EGP full cashToPay
      const uncontractedPayment = storePayments.find((p: any) => p.fulfillmentId === 'ff-uncontracted');
      expect(uncontractedPayment.isContracted).toBe(false);
      expect(uncontractedPayment.subtotal).toBe(300);
      expect(uncontractedPayment.commissionAmount).toBe(0);
      expect(uncontractedPayment.cashToPay).toBe(300);

      // Total cashToPayStore is 400 + 300 = 700 EGP
      expect(projected.financials.cashToPayStore).toBe(700);
    });

    const buildMultiGroupOrder = (group1Status = 'DRIVER_ASSIGNED') => ({
      id: 'order-multigroup',
      status: 'DRIVER_ASSIGNED',
      paymentMethod: 'CASH_ON_DELIVERY',
      paymentStatus: 'PENDING',
      deliveryFee: 60,
      serviceFee: 10,
      tax: 5,
      driverBonusFee: 1,
      discount: 2,
      deliveryGroups: [
        {
          id: 'group-1',
          sequence: 1,
          primaryDriverId: 'driver-1',
          deliveryFee: 30,
          status: group1Status,
          items: [{ fulfillmentId: 'ff-store-1', sequence: 1 }],
        },
        {
          id: 'group-2',
          sequence: 2,
          primaryDriverId: 'driver-1',
          deliveryFee: 30,
          status: 'DRIVER_ASSIGNED',
          items: [{ fulfillmentId: 'ff-store-2', sequence: 1 }],
        },
      ],
      vendorFulfillments: [
        {
          id: 'ff-store-1',
          vendorId: 'vendor-1',
          subtotal: 200,
          commissionRate: 10,
          vendor: { name: 'Store 1', isContracted: true },
          vendorBranch: { name: 'Branch 1', isContracted: true },
        },
        {
          id: 'ff-store-2',
          vendorId: 'vendor-2',
          subtotal: 300,
          commissionRate: 10,
          vendor: { name: 'Store 2', isContracted: false },
          vendorBranch: { name: 'Branch 2', isContracted: false },
        },
      ],
      items: [
        { id: 'i1', fulfillmentId: 'ff-store-1' },
        { id: 'i2', fulfillmentId: 'ff-store-2' },
      ],
    });

    it('scopes a grouped order to the current delivery group only', async () => {
      const actor = { sub: 'user-driver-1' } as any;
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });

      const projected = await (ordersService as any).projectForDriver(
        buildMultiGroupOrder(),
        actor,
      );

      // The driver is working delivery 1, so only its store/items are visible.
      expect(projected.vendorFulfillments).toHaveLength(1);
      expect(projected.vendorFulfillments[0].id).toBe('ff-store-1');
      expect(projected.financials.storePayments).toHaveLength(1);
      expect(projected.items).toHaveLength(1);
      expect(projected.items[0].id).toBe('i1');
      expect(projected.deliveryFee).toBe(30);
      expect(projected.subtotal).toBe(200);
      // Goods 200 + group delivery 30 + order extras (10 + 5 + 1 - 2) = 244
      expect(projected.grandTotal).toBe(244);
      expect(projected.currentDeliveryGroupId).toBe('group-1');
      expect(projected.deliveryGroups).toHaveLength(2);
    });

    it('advances to the next group after delivery and charges order extras only once', async () => {
      const actor = { sub: 'user-driver-1' } as any;
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });

      const projected = await (ordersService as any).projectForDriver(
        buildMultiGroupOrder('DELIVERED'),
        actor,
      );

      // Delivery 1 is done: the projection points the app at delivery 2.
      expect(projected.currentDeliveryGroupId).toBe('group-2');
      expect(projected.vendorFulfillments).toHaveLength(1);
      expect(projected.vendorFulfillments[0].id).toBe('ff-store-2');
      expect(projected.items).toHaveLength(1);
      expect(projected.items[0].id).toBe('i2');
      expect(projected.deliveryFee).toBe(30);
      // Goods 300 + group delivery 30, no order-level extras a second time.
      expect(projected.grandTotal).toBe(330);
      expect(projected.deliveryGroups).toHaveLength(2);
    });

    it('reports DELIVERED with no work once every assigned group is delivered', async () => {
      const actor = { sub: 'user-driver-1' } as any;
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });

      const order = buildMultiGroupOrder('DELIVERED');
      order.deliveryGroups[1].status = 'DELIVERED';

      const projected = await (ordersService as any).projectForDriver(order, actor);

      expect(projected.status).toBe('DELIVERED');
      expect(projected.currentDeliveryGroupId).toBeNull();
      expect(projected.items).toHaveLength(0);
      expect(projected.vendorFulfillments).toHaveLength(0);
      expect(projected.financials.storePayments).toHaveLength(0);
      expect(projected.grandTotal).toBe(0);
      expect(projected.driverEarnings).toBe(0);
      expect(projected.deliveryGroups).toHaveLength(2);
    });
    it('calculates driverEarnings matching dispatch and settlement commission rates (net 70%)', async () => {
      const actor = { sub: 'user-driver-1' } as any;
      mockPrisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', tier: 'GOLD' });

      const mockOrder = {
        id: 'order-single',
        status: 'DRIVER_ASSIGNED',
        paymentMethod: 'CASH_ON_DELIVERY',
        deliveryFee: 30,
        subtotal: 100,
        grandTotal: 130,
      };

      const projected = await (ordersService as any).projectForDriver(mockOrder, actor);

      // 30 deliveryFee * (1 - 0.20 platform - 0.10 supervisor) = 21 EGP
      expect(projected.driverEarnings).toBe(21);
      expect(projected.financials.driverEarnings).toBe(21);
      expect(projected.deliveryFee).toBe(30);
    });
  });

  describe('projectForVendor', () => {
    it('isolates vendor data and strips other stores and delivery groups', async () => {
      const actor = { sub: 'user-vendor-1' } as any;

      const mockOrder = {
        id: 'order-multistore',
        status: 'READY_FOR_PICKUP',
        vendorFulfillments: [
          {
            id: 'ff-vendor-1',
            vendorId: 'vendor-1',
            subtotal: 500,
            commissionRate: 20,
            vendor: { name: 'My Bakery', isContracted: true },
            vendorBranch: { name: 'Branch Downtown', isContracted: true },
            items: [{ id: 'item-1', name: 'Croissant', price: 50, quantity: 10, fulfillmentId: 'ff-vendor-1' }],
          },
          {
            id: 'ff-vendor-2',
            vendorId: 'vendor-2',
            subtotal: 900,
            commissionRate: 15,
            vendor: { name: 'Secret Other Store', isContracted: false },
            vendorBranch: { name: 'Branch Other', isContracted: false },
            items: [{ id: 'item-2', name: 'Secret Perfume', price: 900, quantity: 1, fulfillmentId: 'ff-vendor-2' }],
          },
        ],
        deliveryGroups: [
          { id: 'group-internal', sequence: 1, details: 'secret route coordinates' },
        ],
        items: [
          { id: 'item-1', name: 'Croissant', fulfillmentId: 'ff-vendor-1' },
          { id: 'item-2', name: 'Secret Perfume', fulfillmentId: 'ff-vendor-2' },
        ],
      };

      const vendorProjection = await (ordersService as any).projectForVendor(
        mockOrder,
        actor,
        'vendor-1',
      );

      // 1. Only vendor-1's fulfillment is visible
      expect(vendorProjection.vendorFulfillments).toHaveLength(1);
      expect(vendorProjection.vendorFulfillments[0].vendorId).toBe('vendor-1');

      // 2. Only vendor-1's items are visible
      expect(vendorProjection.items).toHaveLength(1);
      expect(vendorProjection.items[0].name).toBe('Croissant');

      // 3. deliveryGroups routing is completely sanitized
      expect(vendorProjection.deliveryGroups).toHaveLength(0);

      // 4. Financials for contracted store: 500 subtotal - 20% (100) = 400 netPayout
      expect(vendorProjection.financials.storeSubtotal).toBe(500);
      expect(vendorProjection.financials.commissionAmount).toBe(100);
      expect(vendorProjection.financials.netPayout).toBe(400);
      expect(vendorProjection.financials.cashToCollectFromDriver).toBe(400);
    });

    it('never leaks items whose fulfillment is unknown or unlinked', async () => {
      const actor = { sub: 'user-vendor-1' } as any;

      const mockOrder = {
        id: 'order-unlinked',
        status: 'PENDING',
        vendorFulfillments: [
          {
            id: 'ff-vendor-1',
            vendorId: 'vendor-1',
            subtotal: 100,
            commissionRate: 20,
            vendor: { name: 'My Bakery', isContracted: true },
            vendorBranch: { name: 'Branch Downtown', isContracted: true },
          },
        ],
        deliveryGroups: [],
        items: [
          { id: 'item-unlinked', name: 'Mystery Item', price: 100, quantity: 1, fulfillmentId: null },
          { id: 'item-other', name: 'Other Store Item', price: 50, quantity: 1, fulfillmentId: 'ff-other' },
        ],
      };

      const vendorProjection = await (ordersService as any).projectForVendor(
        mockOrder,
        actor,
        'vendor-1',
      );

      expect(vendorProjection.items).toHaveLength(0);
      expect(vendorProjection.vendorFulfillments).toHaveLength(1);
      expect(vendorProjection.vendorFulfillments[0].id).toBe('ff-vendor-1');
    });

    it('exposes only the delivery groups carrying this vendor portion', async () => {
      const actor = { sub: 'user-vendor-1' } as any;

      const mockOrder = {
        id: 'order-vendor-groups',
        status: 'READY_FOR_PICKUP',
        vendorFulfillments: [
          {
            id: 'ff-vendor-1',
            vendorId: 'vendor-1',
            status: 'READY_FOR_PICKUP',
            subtotal: 200,
            commissionRate: 20,
            vendor: { name: 'My Bakery', isContracted: true },
            vendorBranch: { id: 'branch-1', name: 'Branch Downtown', isContracted: true },
          },
          {
            id: 'ff-vendor-2',
            vendorId: 'vendor-2',
            status: 'PREPARING',
            subtotal: 300,
            commissionRate: 10,
            vendor: { name: 'Other Store', isContracted: false },
            vendorBranch: { id: 'branch-2', name: 'Branch Other', isContracted: false },
          },
        ],
        deliveryGroups: [
          {
            id: 'group-vendor-2',
            sequence: 1,
            status: 'PREPARING',
            primaryDriverId: 'driver-2',
            items: [{ fulfillmentId: 'ff-vendor-2', sequence: 1 }],
          },
          {
            id: 'group-vendor-1',
            sequence: 2,
            status: 'READY_FOR_PICKUP',
            primaryDriverId: 'driver-1',
            estimatedPrepTime: 25,
            items: [
              { fulfillmentId: 'ff-vendor-1', sequence: 1 },
              { fulfillmentId: 'ff-vendor-2', sequence: 2 },
            ],
          },
        ],
        items: [
          { id: 'item-1', name: 'Croissant', fulfillmentId: 'ff-vendor-1' },
          { id: 'item-2', name: 'Secret Perfume', fulfillmentId: 'ff-vendor-2' },
        ],
      };

      const vendorProjection = await (ordersService as any).projectForVendor(
        mockOrder,
        actor,
        'vendor-1',
      );

      expect(vendorProjection.deliveryGroups).toHaveLength(1);
      const [group] = vendorProjection.deliveryGroups;
      expect(group.id).toBe('group-vendor-1');
      expect(group.primaryDriverId).toBe('driver-1');
      expect(group.estimatedPrepTime).toBe(25);
      expect(group.items).toHaveLength(1);
      expect(group.items[0].fulfillmentId).toBe('ff-vendor-1');
      // Never reveal the other vendor's route details.
      expect(group.details).toBeUndefined();
    });
  });

  describe('enrichWithAdminHelpers (Super Admin multi-vendor visibility)', () => {
    it('synthesizes multi-vendor object and full storePayments breakdown for admin', async () => {
      const mockOrder = {
        id: 'mv-order-1',
        orderNumber: 'ORD-MV-100',
        status: 'PENDING',
        paymentMethod: 'CASH_ON_DELIVERY',
        subtotal: 1000,
        deliveryFee: 50,
        grandTotal: 1050,
        vendorId: null,
        vendor: null,
        vendorBranch: null,
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'vendor-1',
            status: 'PENDING',
            subtotal: 600,
            commissionRate: 20,
            vendor: { storeName: 'Burger Joint', storeNameAr: 'برجر جوينت', isContracted: true },
            vendorBranch: { name: 'Main Branch', nameAr: 'الفرع الرئيسي', address: 'Cairo', isContracted: true },
          },
          {
            id: 'ff-2',
            vendorId: 'vendor-2',
            status: 'PENDING',
            subtotal: 400,
            commissionRate: 10,
            vendor: { storeName: 'Juice Bar', storeNameAr: 'عصائر النعيم', isContracted: false },
            vendorBranch: { name: 'Branch 2', nameAr: 'فرع 2', address: 'Giza', isContracted: false },
          },
        ],
      };

      const adminEnriched = await (ordersService as any).enrichWithAdminHelpers(mockOrder);

      expect(adminEnriched.isMultiVendor).toBe(true);
      expect(adminEnriched.vendor).toBeDefined();
      expect(adminEnriched.vendor.isMultiVendor).toBe(true);
      expect(adminEnriched.vendor.storeNameAr).toBe('برجر جوينت + عصائر النعيم');
      expect(adminEnriched.vendor.storeName).toBe('Burger Joint + Juice Bar');
      expect(adminEnriched.vendorBranch).toBeNull();

      // Financials breakdown
      expect(adminEnriched.financials.storePayments).toHaveLength(2);
      expect(adminEnriched.financials.storePayments[0].vendorName).toBe('برجر جوينت');
      expect(adminEnriched.financials.storePayments[0].cashToPay).toBe(480); // 600 - 20%
      expect(adminEnriched.financials.storePayments[1].vendorName).toBe('عصائر النعيم');
      expect(adminEnriched.financials.storePayments[1].cashToPay).toBe(400); // uncontracted full 400
      expect(adminEnriched.financials.cashToPayStore).toBe(880);
      expect(adminEnriched.financials.isStorePrepaid).toBe(false); // since one is uncontracted
    });

    it('merges rejected lines back into each portion for full admin visibility', async () => {
      const mockOrder = {
        id: 'mv-order-2',
        orderNumber: 'ORD-MV-200',
        status: 'PENDING',
        paymentMethod: 'CASH_ON_DELIVERY',
        subtotal: 100,
        deliveryFee: 20,
        grandTotal: 120,
        vendorId: null,
        vendor: null,
        vendorBranch: null,
        vendorFulfillments: [
          {
            id: 'ff-1',
            vendorId: 'vendor-1',
            status: 'PENDING',
            subtotal: 100,
            commissionRate: 20,
            vendor: { storeName: 'Burger Joint', isContracted: true },
            vendorBranch: { name: 'Main Branch', isContracted: true },
            // Repository filters rejected rows out of this list.
            items: [{ id: 'item-kept', productName: 'Burger', quantity: 1, fulfillmentId: 'ff-1' }],
          },
        ],
        items: [
          { id: 'item-kept', productName: 'Burger', quantity: 1, fulfillmentId: 'ff-1' },
          { id: 'item-rejected', productName: 'Sold Out', quantity: 2, fulfillmentId: 'ff-1', rejectedAt: new Date() },
        ],
      };

      const adminEnriched = await (ordersService as any).enrichWithAdminHelpers(mockOrder);

      expect(adminEnriched.vendorFulfillments).toHaveLength(1);
      const portion = adminEnriched.vendorFulfillments[0];
      expect(portion.items).toHaveLength(2);
      expect(portion.items.map((i: any) => i.id).sort()).toEqual([
        'item-kept',
        'item-rejected',
      ]);
    });
  });
});
