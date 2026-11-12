import { Test } from '@nestjs/testing';
import {
  OrderGroupingService,
  haversineKm,
  GroupingThresholds,
  VendorStop,
} from './order-grouping.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

/** Customer drop-off in Cairo. 1 deg lat ≈ 111.2 km, 1 deg lng ≈ 96.3 km @30N. */
const CUSTOMER = { lng: 31.2, lat: 30.0 };
const KM_PER_LNG = 96.3;
const KM_PER_LAT = 111.2;

const stop = (id: string, lng: number, lat: number): VendorStop => ({
  vendorId: id,
  vendorBranchId: `branch-${id}`,
  lng,
  lat,
  fulfillmentId: `ff-${id}`,
});

/** A vendor `km` due east of the customer (straight-line ≈ km). */
const east = (id: string, km: number): VendorStop =>
  stop(id, CUSTOMER.lng + km / KM_PER_LNG, CUSTOMER.lat);

/** A vendor `km` due north of the customer (straight-line ≈ km). */
const north = (id: string, km: number): VendorStop =>
  stop(id, CUSTOMER.lng, CUSTOMER.lat + km / KM_PER_LAT);

const T = (over: Partial<GroupingThresholds> = {}): GroupingThresholds => ({
  maxBranchDistanceKm: 5,
  maxVendorCustomerDistanceKm: 25,
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
    expect(
      haversineKm({ lng: 31.0, lat: 30 }, { lng: 31.5, lat: 30 }),
    ).toBeCloseTo(48.2, 0);
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
        {
          provide: PlatformSettingsService,
          useValue: { getSettings: () => Promise.resolve({}) },
        },
      ],
    }).compile();
    service = moduleRef.get(OrderGroupingService);
  });

  it('returns no groups for no vendors', () => {
    const r = service.plan([], CUSTOMER, T());
    expect(r.groups).toHaveLength(0);
    expect(r.isSplit).toBe(false);
  });

  it('groups two vendors close to each other into one delivery', () => {
    const r = service.plan([east('a', 1), east('b', 1.2)], CUSTOMER, T());
    expect(r.groups).toHaveLength(1);
    expect(r.groups[0].stops).toHaveLength(2);
    expect(r.groups[0].extraVendorCount).toBe(1);
    expect(r.groups[0].splitReason).toBe('CLUSTERED');
    expect(r.isSplit).toBe(false);
  });

  it('groups a far vendor with an on-the-way near vendor (one trip)', () => {
    // a is 20 km out, b is 2 km out on the same line: detour(b) = 18 + 2 - 20 = 0.
    const r = service.plan([east('a', 20), east('b', 2)], CUSTOMER, T());
    expect(r.groups).toHaveLength(1);
    expect(r.groups[0].stops).toHaveLength(2);
    // The customer pays for the far leg, never the short one.
    expect(r.groups[0].farthestToCustomerKm).toBeCloseTo(20, 1);
  });

  it('marks a group anchored beyond the customer range as FAR_FROM_CUSTOMER', () => {
    const r = service.plan([east('a', 30), east('b', 2)], CUSTOMER, T());
    expect(r.groups).toHaveLength(1);
    expect(r.groups[0].splitReason).toBe('FAR_FROM_CUSTOMER');
  });

  it('does not merge near vendors that are off-route from each other', () => {
    // Both 20 km from the customer but on opposite axes: the detour to combine
    // them (~28 km) is far beyond the branch allowance, so they stay separate.
    const r = service.plan([east('a', 20), north('b', 20)], CUSTOMER, T());
    expect(r.groups).toHaveLength(2);
    expect(r.isSplit).toBe(true);
    expect(r.groups.every((g) => g.stops.length === 1)).toBe(true);
  });

  it('keeps two near clusters on opposite sides of the customer separate', () => {
    const west = stop('a', CUSTOMER.lng - 20 / KM_PER_LNG, CUSTOMER.lat);
    const eastStop = east('b', 20);
    const r = service.plan([west, eastStop], CUSTOMER, T());
    expect(r.groups).toHaveLength(2);
  });

  it('honours the branch distance setting for off-route vendors', () => {
    // a and b are ~4.2 km apart, each ~3 km from the customer, off-axis.
    const stops = [east('a', 3), north('b', 3)];

    expect(
      service.plan(stops, CUSTOMER, T({ maxBranchDistanceKm: 5 })).groups,
    ).toHaveLength(1);

    // Tightening the same setting splits them — same inputs, different outcome.
    expect(
      service.plan(stops, CUSTOMER, T({ maxBranchDistanceKm: 2 })).groups,
    ).toHaveLength(2);
  });

  it('honours the vendor→customer distance limit on its own', () => {
    // a is 30 km out, b is 40 km out on the same line (10 km apart, so they are
    // not "close to each other"). Whether they share a trip depends purely on
    // whether a is close enough to the customer to ride along on b's trip.
    const stops = [north('a', 30), north('b', 40)];

    expect(
      service.plan(stops, CUSTOMER, T({ maxVendorCustomerDistanceKm: 25 }))
        .groups,
    ).toHaveLength(2);

    expect(
      service.plan(stops, CUSTOMER, T({ maxVendorCustomerDistanceKm: 45 }))
        .groups,
    ).toHaveLength(1);
  });

  it('is deterministic: identical input yields an identical plan', () => {
    const stops = [east('c', 6), east('a', 2), east('b', 2.1)];
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
      east('a', 2),
      east('a', 12), // same vendor, different branch
      east('b', 2.1),
    ];
    const r = service.plan(stops, CUSTOMER, T());
    for (const g of r.groups) {
      expect(new Set(g.stops.map((s) => s.vendorId)).size).toBe(g.stops.length);
    }
  });

  it('reports SINGLE_VENDOR for a lone vendor', () => {
    const r = service.plan([east('a', 12)], CUSTOMER, T());
    expect(r.groups).toHaveLength(1);
    expect(r.groups[0].splitReason).toBe('SINGLE_VENDOR');
    expect(r.groups[0].extraVendorCount).toBe(0);
    expect(r.groups[0].farthestToCustomerKm).toBeCloseTo(12, 1);
  });

  it('orders the group farthest-first so stops[0] is the distance anchor', () => {
    const r = service.plan([east('near', 2), east('far', 20)], CUSTOMER, T());
    const g = r.groups[0];
    expect(g.stops[0].vendorId).toBe('far');
    expect(haversineKm(g.stops[0], CUSTOMER)).toBeCloseTo(
      g.farthestToCustomerKm,
      6,
    );
  });
});
