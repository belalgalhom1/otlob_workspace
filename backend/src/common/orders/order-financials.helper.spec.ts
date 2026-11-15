import {
  allocateDriverBonus,
  allocateIntegerProportional,
  allocateOrderCashCollection,
  computeIsMultiVendorOrder,
} from './order-financials.helper';

describe('order-financials.helper', () => {
  describe('computeIsMultiVendorOrder', () => {
    it('returns true when orderIsMultiVendor, activeGroupsCount > 1, or activeFulfillmentsCount > 1', () => {
      expect(
        computeIsMultiVendorOrder({
          orderIsMultiVendor: true,
          activeGroupsCount: 1,
          activeFulfillmentsCount: 1,
        }),
      ).toBe(true);
      expect(
        computeIsMultiVendorOrder({
          orderIsMultiVendor: false,
          activeGroupsCount: 2,
          activeFulfillmentsCount: 1,
        }),
      ).toBe(true);
      expect(
        computeIsMultiVendorOrder({
          orderIsMultiVendor: false,
          activeGroupsCount: 1,
          activeFulfillmentsCount: 2,
        }),
      ).toBe(true);
      expect(
        computeIsMultiVendorOrder({
          orderIsMultiVendor: false,
          activeGroupsCount: 1,
          activeFulfillmentsCount: 1,
        }),
      ).toBe(false);
    });
  });

  describe('allocateIntegerProportional', () => {
    it('distributes total using largest remainder and preserves exact sum', () => {
      const shares = allocateIntegerProportional(100, [10, 20]);
      expect(shares).toEqual([33, 67]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(100);

      const tied = allocateIntegerProportional(15, [10, 10]);
      expect(tied).toEqual([8, 7]);
      expect(tied.reduce((a, b) => a + b, 0)).toBe(15);

      expect(allocateIntegerProportional(10, [0, 0])).toEqual([5, 5]);
      expect(allocateIntegerProportional(0, [10, 20])).toEqual([0, 0]);
    });
  });

  describe('allocateOrderCashCollection', () => {
    it('splits COD normally when collector absorbs fees/upfront without exceeding remaining door cash', () => {
      const { collectorGroupId, allocations } = allocateOrderCashCollection({
        groups: [
          { id: 'g1', sequence: 1, deliveryFee: 30, isPaymentCollector: true },
          { id: 'g2', sequence: 2, deliveryFee: 25, isPaymentCollector: false },
        ],
        goodsByGroup: new Map([
          ['g1', 120],
          ['g2', 80],
        ]),
        grandTotal: 265,
        upfrontAmount: 50,
        paymentMethod: 'CASH_ON_DELIVERY',
      });

      expect(collectorGroupId).toBe('g1');
      // Group 2 collects its standalone (80 + 25 = 105). Group 1 collects remaining door due (215 - 105 = 110) and held total = 160.
      expect(allocations.get('g2')).toEqual({
        doorCashToCollect: 105,
        totalCollectedByDriver: 105,
      });
      expect(allocations.get('g1')).toEqual({
        doorCashToCollect: 110,
        totalCollectedByDriver: 160,
      });
    });

    it('spills high coin discount + upfront across non-collector groups so door cash never exceeds grandTotal - upfront', () => {
      const { allocations } = allocateOrderCashCollection({
        groups: [
          { id: 'g1', sequence: 1, deliveryFee: 20, isPaymentCollector: true },
          { id: 'g2', sequence: 2, deliveryFee: 20, isPaymentCollector: false },
          { id: 'g3', sequence: 3, deliveryFee: 20, isPaymentCollector: false },
        ],
        goodsByGroup: new Map([
          ['g1', 100],
          ['g2', 100],
          ['g3', 100],
        ]),
        grandTotal: 250,
        upfrontAmount: 100, // remaining door due = 150 < nonCollectorSum (120 + 120 = 240)
        paymentMethod: 'CASH_ON_DELIVERY',
      });

      const g1 = allocations.get('g1')!;
      const g2 = allocations.get('g2')!;
      const g3 = allocations.get('g3')!;

      expect(g1.doorCashToCollect + g2.doorCashToCollect + g3.doorCashToCollect).toBe(150);
      expect(
        g1.totalCollectedByDriver + g2.totalCollectedByDriver + g3.totalCollectedByDriver,
      ).toBe(250);
      expect(g1.doorCashToCollect).toBe(0);
      expect(g1.totalCollectedByDriver).toBe(100);
      expect(g2.doorCashToCollect).toBe(75);
      expect(g3.doorCashToCollect).toBe(75);
    });

    it('sets doorCashToCollect to 0 on MOBILE_WALLET only when settled prepaid while keeping totalCollectedByDriver for settlement', () => {
      const pending = allocateOrderCashCollection({
        groups: [
          { id: 'g1', sequence: 1, deliveryFee: 20, isPaymentCollector: true },
          { id: 'g2', sequence: 2, deliveryFee: 20, isPaymentCollector: false },
        ],
        goodsByGroup: new Map([
          ['g1', 100],
          ['g2', 80],
        ]),
        grandTotal: 220,
        upfrontAmount: 0,
        paymentMethod: 'MOBILE_WALLET',
        isOrderSettledPrepaid: false,
      });
      expect(pending.allocations.get('g1')).toEqual({
        doorCashToCollect: 220,
        totalCollectedByDriver: 220,
      });
      expect(pending.allocations.get('g2')).toEqual({
        doorCashToCollect: 0,
        totalCollectedByDriver: 0,
      });

      const settled = allocateOrderCashCollection({
        groups: [
          { id: 'g1', sequence: 1, deliveryFee: 20, isPaymentCollector: true },
          { id: 'g2', sequence: 2, deliveryFee: 20, isPaymentCollector: false },
        ],
        goodsByGroup: new Map([
          ['g1', 100],
          ['g2', 80],
        ]),
        grandTotal: 220,
        upfrontAmount: 0,
        paymentMethod: 'MOBILE_WALLET',
        isOrderSettledPrepaid: true,
      });
      expect(settled.allocations.get('g1')).toEqual({
        doorCashToCollect: 0,
        totalCollectedByDriver: 220,
      });
    });
  });

  describe('allocateDriverBonus', () => {
    it('allocates bonus proportionally across distinct primary drivers and consolidates same-driver groups', () => {
      const twoDrivers = allocateDriverBonus({
        driverBonusFee: 15,
        groups: [
          {
            id: 'g1',
            sequence: 1,
            deliveryFee: 20,
            isPaymentCollector: true,
            primaryDriverId: 'd1',
            primaryDriverShiftId: 's1',
          },
          {
            id: 'g2',
            sequence: 2,
            deliveryFee: 40,
            isPaymentCollector: false,
            primaryDriverId: 'd2',
            primaryDriverShiftId: 's2',
          },
        ],
      });
      expect(twoDrivers).toEqual([
        { driverId: 'd1', driverShiftId: 's1', deliveryGroupId: 'g1', amount: 5 },
        { driverId: 'd2', driverShiftId: 's2', deliveryGroupId: 'g2', amount: 10 },
      ]);

      const oneDriverTwoGroups = allocateDriverBonus({
        driverBonusFee: 15,
        groups: [
          {
            id: 'g1',
            sequence: 1,
            deliveryFee: 20,
            isPaymentCollector: false,
            primaryDriverId: 'd1',
            primaryDriverShiftId: 's1',
          },
          {
            id: 'g2',
            sequence: 2,
            deliveryFee: 40,
            isPaymentCollector: true,
            primaryDriverId: 'd1',
            primaryDriverShiftId: 's1',
          },
        ],
      });
      expect(oneDriverTwoGroups).toEqual([
        { driverId: 'd1', driverShiftId: 's1', deliveryGroupId: 'g2', amount: 15 },
      ]);
    });
  });
});
