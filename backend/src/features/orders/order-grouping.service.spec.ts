import { Test } from '@nestjs/testing';
import {
  OrderGroupingService,
  bestRouteKm,
  haversineKm,
  GroupingThresholds,
  VendorStop,
} from './order-grouping.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

/** Customer drop-off in Cairo. 1 deg lat ≈ 111.19 km, 1 deg lng ≈ 96.5 km @30N. */
const CUSTOMER = { lng: 31.2, lat: 30.0 };

const stop = (id: string, lng: number, lat: number): VendorStop => ({
  vendorId: id,
  vendorBranchId: `branch-${id}`,
  lng,
  lat,
  fulfillmentId: `ff-${id}`,
});

const T = (over: Partial<GroupingThresholds> = {}): GroupingThresholds => ({
  maxBranchDistanceKm: 5,
  maxVendorCustomerDistanceKm: 25,
  maxCombinedRouteKm: 35,
  ...over,
});

describe('haversineKm', () => {
  it('is zero for identical points', () => {
    expect(haversineKm(CUSTOMER, CUSTOMER)).toBeCloseTo(0, 9);
  });

  it('is symmetric', () => {
    const a = { lng: 31.2, lat: 30.0 };
    const b = { lng: 31.3, lat: 30.1 };
    expect(haversineKm(a, b)).toBeCloseTo(haversineKm(b, a), 9);
  });

  it('matches a known great-circle distance (~0.5 deg lng at 30N ≈ 48 km)', () => {
    expect(haversineKm({ lng: 31.0, lat: 30 }, { lng: 31.5, lat: 30 })).toBeCloseTo(
      48.2,
      0,
    );
  });
});

describe('bestRouteKm', () => {
  it('is a straight line for a single stop', () => {
    const s = [stop('a', 31.21, 30.0)];
    expect(bestRouteKm(s, CUSTOMER)).toBeCloseTo(haversineKm(s[0], CUSTOMER), 6);
  });

  it('does not force the customer-nearest vendor to be visited first', () => {
    // "far" is nearer the customer, "near" is further out but the customer sits
    // beyond "far". The cheaper ordering is far -> near -> customer.
    const far = stop('far', 31.21, 30.0);
    const near = stop('near', 31.24, 30.0);
    const customer = { lng: 31.26, lat: 30.0 };

    const route = bestRouteKm([near, far], customer);
    // Visiting the customer-nearest stop (`near`) first and doubling back to
    // `far` costs this much more than the optimal far -> near -> customer trip.
    const nearestFirst = haversineKm(near, far) + haversineKm(far, customer);
    expect(route).toBeLessThan(nearestFirst);
  });

  it('equals the cheapest ordering for two stops', () => {
    const a = stop('a', 31.21, 30.0);
    const b = stop('b', 31.23, 30.0);
    const o1 = haversineKm(a, b) + haversineKm(b, CUSTOMER);
    const o2 = haversineKm(b, a) + haversineKm(a, CUSTOMER);
    expect(bestRouteKm([a, b], CUSTOMER)).toBeCloseTo(Math.min(o1, o2), 6);
  });
});

describe('OrderGroupingService.plan', () => {
  let service: OrderGroupingService;

  beforeEach(async () => {
    // The service only needs PlatformSettingsService for `currentThresholds()`;
    // `plan()` is pure, so a stub keeps these tests free of the database.
    const moduleRef = await Test.createTestingModule({
      providers: [
        OrderGroupingService,
        { provide: PlatformSettingsService, useValue: { getSettings: async () => ({}) } },
      ],
    }).compile();
    service = moduleRef.get(OrderGroupingService);
  });

  it('returns no groups for no vendors', () => {
    const r = service.plan([], CUSTOMER, T());
    expect(r.groups).toHaveLength(0);
    expect(r.isSplit).toBe(false);
  });

  // Scenario A — two nearby vendors
  it('Scenario A: groups two nearby vendors into one delivery', () => {
    const r = service.plan(
      [stop('a', 31.205, 30.005), stop('b', 31.208, 30.007)],
      CUSTOMER,
      T(),
    );
    expect(r.groups).toHaveLength(1);
    expect(r.groups[0].stops).toHaveLength(2);
    expect(r.isSplit).toBe(false);
  });

  // Scenario B — far apart
  it('Scenario B: splits vendors that violate the inter-branch distance', () => {
    const r = service.plan([stop('a', 31.2, 30.0), stop('b', 31.45, 30.0)], CUSTOMER, T());
    expect(r.groups).toHaveLength(2);
    expect(r.isSplit).toBe(true);
    expect(r.groups.every((g) => g.stops.length === 1)).toBe(true);
  });

  // Scenario C — two nearby + one distant => 2 groups (2 + 1)
  it('Scenario C: groups the two nearby vendors and splits the distant one', () => {
    const r = service.plan(
      [
        stop('a', 31.205, 30.005),
        stop('b', 31.208, 30.007),
        stop('c', 31.35, 30.0),
      ],
      CUSTOMER,
      T(),
    );
    expect(r.groups).toHaveLength(2);
    const sizes = r.groups.map((g) => g.stops.length).sort();
    expect(sizes).toEqual([1, 2]);
  });

  // Scenario D — one vendor near the customer, far from the other
  it('Scenario D: does not group a customer-adjacent vendor with a distant one', () => {
    // a ≈1.1 km from the customer, b ≈10 km away from both a and the customer.
    const r = service.plan([stop('a', 31.21, 30.0), stop('b', 31.2, 30.09)], CUSTOMER, T());
    expect(r.groups).toHaveLength(2);
  });

  // Scenario F — one vendor near the customer, another far from both
  it('Scenario F: never forces a far-from-both vendor into the same delivery', () => {
    const r = service.plan(
      [stop('a', 31.205, 30.0), stop('b', 31.2, 30.2)],
      CUSTOMER,
      T(),
    );
    expect(r.groups).toHaveLength(2);
  });

  it('Scenario E: branch distance is a setting, not a hardcode', () => {
    // a and b sit on opposite sides of the customer ~3.9 km apart.
    const stops = [stop('a', 31.22, 30.0), stop('b', 31.18, 30.0)];

    // Branch limit admits them and the combined route is short => one delivery.
    expect(service.plan(stops, CUSTOMER, T({ maxBranchDistanceKm: 5 })).groups)
      .toHaveLength(1);

    // Tightening the same setting splits them — same inputs, different outcome.
    expect(
      service.plan(stops, CUSTOMER, T({ maxBranchDistanceKm: 2 })).groups,
    ).toHaveLength(2);
  });

  it('Scenario E / test 7: splits when branches are close but the combined route is not', () => {
    // Branch-to-branch is tiny (~0.14 km), but both branches sit ~7.8 km from the
    // customer, so a combined trip exceeds the 6 km route budget.
    const r = service.plan(
      [stop('a', 31.2, 30.07), stop('b', 31.201, 30.071)],
      CUSTOMER,
      T({ maxBranchDistanceKm: 5, maxVendorCustomerDistanceKm: 30, maxCombinedRouteKm: 6 }),
    );
    expect(r.groups).toHaveLength(2);
  });

  it('honours the vendor→customer distance limit on its own', () => {
    // Branch distance is generous, but the vendor is too far from the customer.
    const r = service.plan(
      [stop('a', 31.21, 30.0), stop('b', 31.2, 30.15)],
      CUSTOMER,
      T({ maxVendorCustomerDistanceKm: 10 }),
    );
    expect(r.groups).toHaveLength(2);
  });

  it('is deterministic: identical input yields an identical plan', () => {
    const stops = [
      stop('c', 31.35, 30.0),
      stop('a', 31.205, 30.005),
      stop('b', 31.208, 30.007),
    ];
    const first = service.plan(stops, CUSTOMER, T());
    const second = service.plan(stops, CUSTOMER, T());
    expect(second).toEqual(first);
  });

  it('handles an arbitrary number of vendors without special-casing', () => {
    const many = Array.from({ length: 25 }, (_, i) =>
      stop(`v${i}`, 31.2 + (i % 5) * 0.02, 30 + Math.floor(i / 5) * 0.02),
    );
    const r = service.plan(many, CUSTOMER, T());
    const total = r.groups.reduce((n, g) => n + g.stops.length, 0);
    expect(total).toBe(25);
    expect(r.groups.length).toBeGreaterThanOrEqual(1);
  });

  it('never puts the same vendor into two groups', () => {
    const stops = [
      stop('a', 31.205, 30.0),
      stop('a', 31.24, 30.0), // same vendor, different branch
      stop('b', 31.205, 30.005),
    ];
    const r = service.plan(stops, CUSTOMER, T());
    for (const g of r.groups) {
      expect(new Set(g.stops.map((s) => s.vendorId)).size).toBe(g.stops.length);
    }
  });

  it('treats an inclusive boundary as groupable', () => {
    // Place b exactly maxBranchDistanceKm away from a by construction.
    const a = stop('a', 31.2, 30.0);
    const limit = 5;
    const b = stop('b', 31.2 + limit / 96.5, 30.0); // ≈ limit km east
    const r = service.plan([a, b], CUSTOMER, T({ maxBranchDistanceKm: limit }));
    // b is ~5 km from a and ~5 km from the customer; route ≈ 10 km < 35.
    expect(haversineKm(a, b)).toBeLessThanOrEqual(limit + 0.2);
    expect(r.groups).toHaveLength(1);
  });

  it('reports the split reason so the customer can be told why', () => {
    const single = service.plan([stop('a', 31.21, 30.0)], CUSTOMER, T());
    expect(single.groups[0].splitReason).toBe('SINGLE_VENDOR');

    const split = service.plan([stop('a', 31.2, 30.0), stop('b', 31.45, 30.0)], CUSTOMER, T());
    expect(split.groups[0].splitReason).toBe('SINGLE_VENDOR');
    expect(split.isSplit).toBe(true);
  });

  it('prices a group from its first pickup to the customer', () => {
    const r = service.plan(
      [stop('a', 31.205, 30.005), stop('b', 31.208, 30.007)],
      CUSTOMER,
      T(),
    );
    const g = r.groups[0];
    expect(g.firstPickupToCustomerKm).toBeCloseTo(
      haversineKm(g.stops[0], CUSTOMER),
      6,
    );
    expect(g.routeKm).toBeGreaterThanOrEqual(g.firstPickupToCustomerKm);
  });
});