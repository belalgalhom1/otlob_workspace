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
  });
});
