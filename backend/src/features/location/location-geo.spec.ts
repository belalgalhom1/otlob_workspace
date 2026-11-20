import { NotFoundException } from '@nestjs/common';
import { DriverStatus } from '@prisma/client';
import { ZoneErrors } from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  applyPrecisionReduction,
  EARTH_MEAN_RADIUS_KM,
  haversineKm,
} from '../../common/geo/geo.utils';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';
import { haversineKm as orderGroupingHaversineKm } from '../orders/order-grouping.service';
import { DRIVER_ACTIVE_ORDER_STATUSES as ORDERS_ACTIVE_STATUSES } from '../orders/orders.constants';
import { ZonesService } from '../zones/zones.service';
import { DriverGeoSearchService } from './driver-geo-search.service';
import { DriverTrackingService } from './driver-tracking.service';
import { DRIVER_GEO_POOL_KEY, LocationRepository } from './location.repository';

describe('Location Feature Architecture (Zero Business Logic in Infrastructure)', () => {
  describe('Shared geo utilities & active order status constants', () => {
    it('shares canonical haversineKm, precision math, and DRIVER_ACTIVE_ORDER_STATUSES', () => {
      expect(orderGroupingHaversineKm).toBe(haversineKm);
      expect(EARTH_MEAN_RADIUS_KM).toBe(6371.0088);
      expect(ORDERS_ACTIVE_STATUSES).toBe(DRIVER_ACTIVE_ORDER_STATUSES);

      const a = { lng: 31.2357, lat: 30.0444 };
      const b = { lng: 31.26, lat: 29.96 };
      expect(haversineKm(a, a)).toBeCloseTo(0, 9);
      expect(haversineKm(a, b)).toBeCloseTo(haversineKm(b, a), 9);

      expect(applyPrecisionReduction(a.lng, a.lat, 0)).toEqual(a);
      const masked = applyPrecisionReduction(a.lng, a.lat, 500);
      expect(masked.lng).not.toBe(a.lng);
      expect(masked.lat).not.toBe(a.lat);
    });
  });

  describe('DriverGeoSearchService & LocationRepository', () => {
    it('parameterizes DRIVER_ACTIVE_ORDER_STATUSES in both corridor and availability SQL clauses', async () => {
      const queryRaw = jest.fn().mockResolvedValue([]);
      const redis = {
        georadius: jest
          .fn()
          .mockResolvedValue([{ member: 'd1', distanceKm: 1.5 }]),
        zremMembers: jest.fn().mockResolvedValue(0),
      };
      const repo = new LocationRepository(
        { $queryRaw: queryRaw } as any,
        redis as any,
      );
      const search = new DriverGeoSearchService(repo, {
        getSettings: jest.fn().mockResolvedValue({
          maxActiveOrdersPerDriver: 2,
          driverSearchGeoCandidateLimit: 150,
          batchMaxVendorDistanceKm: 3,
          batchMaxCustomerDistanceKm: 4,
        }),
      } as any);

      await search.findNearbyDrivers(31.25, 29.96, 5, [], ['CAR'], false, {
        lng: 31.27,
        lat: 29.98,
      });

      expect(redis.georadius).toHaveBeenCalledWith(
        DRIVER_GEO_POOL_KEY,
        31.25,
        29.96,
        5,
        150,
      );

      const [, candidateSql, availabilitySql] = queryRaw.mock.calls[0];
      expect(candidateSql.values).toEqual(['d1']);
      expect(availabilitySql.values).toEqual(
        expect.arrayContaining(DRIVER_ACTIVE_ORDER_STATUSES),
      );
      for (const status of DRIVER_ACTIVE_ORDER_STATUSES) {
        expect(
          availabilitySql.values.filter((v: unknown) => v === status).length,
        ).toBe(2);
      }
      expect(availabilitySql.sql).not.toContain('PARTIALLY_PICKED_UP');
    });

    it('sweeps stale geo pool members whose status is no longer ONLINE or ON_DELIVERY', async () => {
      const zrange = jest
        .fn()
        .mockResolvedValueOnce(['d-online', 'd-stale'])
        .mockResolvedValueOnce([]);
      const zremMembers = jest.fn().mockResolvedValue(1);
      const queryRaw = jest.fn().mockResolvedValue([{ id: 'd-online' }]);

      const repo = new LocationRepository(
        { $queryRaw: queryRaw } as any,
        { zrange, zremMembers } as any,
      );
      const search = new DriverGeoSearchService(repo, {} as any);

      const res = await search.sweepStaleDriverLocations();
      expect(res).toEqual({ scanned: 2, removed: 1 });
      expect(zremMembers).toHaveBeenCalledWith(DRIVER_GEO_POOL_KEY, [
        'd-stale',
      ]);
    });
  });

  describe('DriverTrackingService', () => {
    it('tracks live GPS updates using configured TTL and emits per-order events', async () => {
      const redis = {
        get: jest
          .fn()
          .mockResolvedValueOnce('drv-1') // user-driver map
          .mockResolvedValueOnce(
            JSON.stringify({
              orders: [
                { orderId: 'ord-1', customerUserId: 'cust-1' },
                { orderId: 'ord-2', customerUserId: 'cust-2' },
              ],
            }),
          ),
        geoadd: jest.fn().mockResolvedValue(1),
        set: jest.fn().mockResolvedValue(undefined),
      };
      const eventEmitter = { emit: jest.fn() };
      const tracking = new DriverTrackingService(
        new LocationRepository({} as any, redis as any),
        {
          getSettings: jest
            .fn()
            .mockResolvedValue({ driverLocationFreshnessTtlSecs: 45 }),
        } as any,
        eventEmitter as any,
      );

      await tracking.processLiveLocationUpdate('user-drv-1', 31.25, 29.96);

      expect(redis.geoadd).toHaveBeenCalledWith(
        DRIVER_GEO_POOL_KEY,
        31.25,
        29.96,
        'drv-1',
      );
      expect(redis.set).toHaveBeenCalledWith(
        'otlobegy:driver-location-ts:drv-1',
        expect.any(String),
        45,
      );
      expect(eventEmitter.emit).toHaveBeenCalledTimes(2);
      expect(eventEmitter.emit).toHaveBeenNthCalledWith(
        1,
        EVENTS.DRIVER_LOCATION_UPDATED,
        expect.objectContaining({
          driverId: 'drv-1',
          activeOrderId: 'ord-1',
          customerUserId: 'cust-1',
        }),
      );
      expect(eventEmitter.emit).toHaveBeenNthCalledWith(
        2,
        EVENTS.DRIVER_LOCATION_UPDATED,
        expect.objectContaining({
          driverId: 'drv-1',
          activeOrderId: 'ord-2',
          customerUserId: 'cust-2',
        }),
      );
    });

    it('preserves ONLINE/ON_DELIVERY drivers on socket disconnect and evicts OFFLINE drivers', async () => {
      const findUnique = jest
        .fn()
        .mockResolvedValueOnce({ id: 'drv-on', status: DriverStatus.ONLINE })
        .mockResolvedValueOnce({ id: 'drv-off', status: DriverStatus.OFFLINE });
      const zrem = jest.fn().mockResolvedValue(undefined);

      const tracking = new DriverTrackingService(
        new LocationRepository(
          { driver: { findUnique } } as any,
          { zrem } as any,
        ),
        {} as any,
        { emit: jest.fn() } as any,
      );

      await tracking.handleUserDisconnect('u-on');
      expect(zrem).not.toHaveBeenCalled();

      await tracking.handleUserDisconnect('u-off');
      expect(zrem).toHaveBeenCalledWith(DRIVER_GEO_POOL_KEY, 'drv-off');
    });

    it('enforces order customer ownership and privacy precision in getOrderDriverLocation', async () => {
      const queryRaw = jest.fn().mockResolvedValue([
        {
          driverId: 'drv-1',
          customerUserId: 'cust-owner',
          lastLng: 31.2357,
          lastLat: 30.0444,
        },
      ]);
      const redis = {
        geopos: jest.fn().mockResolvedValue({ lng: 31.25123, lat: 29.96123 }),
        get: jest.fn().mockResolvedValue(String(Date.now())),
      };

      const tracking = new DriverTrackingService(
        new LocationRepository({ $queryRaw: queryRaw } as any, redis as any),
        {
          getSettings: jest
            .fn()
            .mockResolvedValue({ driverLocationPrecisionMeters: 250 }),
        } as any,
        { emit: jest.fn() } as any,
      );

      // Wrong customer cannot inspect order driver location
      await expect(
        tracking.getOrderDriverLocation('ord-1', 'other-user'),
      ).resolves.toBeNull();

      const ownerView = await tracking.getOrderDriverLocation(
        'ord-1',
        'cust-owner',
      );
      expect(ownerView).toEqual(
        applyPrecisionReduction(31.25123, 29.96123, 250),
      );
    });

    it('syncs and clears active-order tracking cache through the location domain', async () => {
      const set = jest.fn().mockResolvedValue(undefined);
      const del = jest.fn().mockResolvedValue(undefined);
      const tracking = new DriverTrackingService(
        new LocationRepository({} as any, { set, del } as any),
        {} as any,
        { emit: jest.fn() } as any,
      );

      await tracking.syncDriverActiveOrders('drv-1', [
        { orderId: 'ord-1', customerUserId: 'cust-1' },
      ]);
      expect(set).toHaveBeenCalledWith(
        'otlobegy:driver-active-order:drv-1',
        JSON.stringify({
          orderId: 'ord-1',
          customerUserId: 'cust-1',
          orders: [{ orderId: 'ord-1', customerUserId: 'cust-1' }],
        }),
        12 * 60 * 60,
      );

      await tracking.syncDriverActiveOrders('drv-1', []);
      expect(del).toHaveBeenCalledWith('otlobegy:driver-active-order:drv-1');
    });
  });

  describe('ZonesService.findZoneByLocation', () => {
    it('delegates containing active zone lookup to LocationRepository and throws NOT_FOUND when null', async () => {
      const sampleZone = {
        id: 'z1',
        name: 'Maadi',
        nameAr: 'المعادي',
        isActive: true,
        baseDeliveryFeeOverride: null,
        minOrderAmountOverride: null,
      };
      const locationRepository = {
        findContainingActiveZone: jest
          .fn()
          .mockResolvedValueOnce(sampleZone)
          .mockResolvedValueOnce(null),
      };

      const zonesService = new ZonesService(
        {} as any,
        locationRepository as any,
      );

      await expect(
        zonesService.findZoneByLocation({ longitude: 31.25, latitude: 29.96 }),
      ).resolves.toEqual(sampleZone);

      await expect(
        zonesService.findZoneByLocation({ longitude: 10, latitude: 10 }),
      ).rejects.toThrow(new NotFoundException(ZoneErrors.NOT_FOUND));

      expect(
        locationRepository.findContainingActiveZone,
      ).toHaveBeenNthCalledWith(1, 31.25, 29.96);
    });
  });
});
