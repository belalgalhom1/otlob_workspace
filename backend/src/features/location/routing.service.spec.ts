import { ConfigService } from '@nestjs/config';
import {
  deduplicateAdjacentWaypoints,
  decodePolyline,
  encodePolyline,
  extractGeoPointFromUnknown,
  isValidGeoPoint,
} from '../../common/geo/polyline.utils';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RoutingService } from './routing.service';

describe('Polyline utilities & RoutingService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  describe('polyline.utils', () => {
    it('matches the Google Encoded Polyline reference vector (precision 5)', () => {
      const sample = [
        { lat: 38.5, lng: -120.2 },
        { lat: 40.7, lng: -120.95 },
        { lat: 43.252, lng: -126.453 },
      ];
      const encoded = encodePolyline(sample);
      expect(encoded).toBe('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      const decoded = decodePolyline(encoded);
      expect(decoded).toHaveLength(3);
      for (let i = 0; i < sample.length; i++) {
        expect(decoded[i].lat).toBeCloseTo(sample[i].lat, 4);
        expect(decoded[i].lng).toBeCloseTo(sample[i].lng, 4);
      }
    });

    it('extracts GeoPoint across GeoJSON, object, and tuple inputs while rejecting invalid or (0,0)', () => {
      expect(
        extractGeoPointFromUnknown({
          type: 'Point',
          coordinates: [31.2357, 30.0444],
        }),
      ).toEqual({ lng: 31.2357, lat: 30.0444 });
      expect(
        extractGeoPointFromUnknown({ latitude: 30.0444, longitude: 31.2357 }),
      ).toEqual({ lng: 31.2357, lat: 30.0444 });
      expect(
        extractGeoPointFromUnknown({ lat: 30.0444, lng: 31.2357 }),
      ).toEqual({ lng: 31.2357, lat: 30.0444 });
      expect(extractGeoPointFromUnknown([31.2357, 30.0444])).toEqual({
        lng: 31.2357,
        lat: 30.0444,
      });

      expect(extractGeoPointFromUnknown({ coordinates: [0, 0] })).toBeNull();
      expect(
        extractGeoPointFromUnknown({ latitude: 95, longitude: 31 }),
      ).toBeNull();
      expect(isValidGeoPoint({ lat: 30.0, lng: 181.0 })).toBe(false);
    });

    it('deduplicates waypoints closer than 15m while keeping distinct endpoints', () => {
      const a = { lat: 30.0444, lng: 31.2357 };
      const nearA = { lat: 30.04443, lng: 31.23572 }; // ~4m
      const b = { lat: 30.055, lng: 31.25 };
      expect(deduplicateAdjacentWaypoints([a, nearA, b], 0.015)).toEqual([
        a,
        b,
      ]);
    });
  });

  describe('RoutingService', () => {
    it('fetches multi-waypoint OSRM road geometry, encodes polyline, and caches in Redis', async () => {
      const redis = {
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue(undefined),
      };
      const config = {
        get: jest.fn().mockReturnValue('https://router.example.org/'),
      };

      const fetchMock = jest.fn<
        Promise<Response>,
        [input: RequestInfo | URL, init?: RequestInit]
      >(() =>
        Promise.resolve({
          ok: true,
          json: () =>
            Promise.resolve({
              code: 'Ok',
              routes: [
                {
                  distance: 4210.4,
                  duration: 580.2,
                  geometry: {
                    coordinates: [
                      [31.2357, 30.0444],
                      [31.241, 30.049],
                      [31.249, 30.054],
                      [31.255, 30.06],
                    ],
                  },
                },
              ],
            }),
        } as unknown as Response),
      );
      global.fetch = fetchMock as typeof global.fetch;

      const service = new RoutingService(
        redis as unknown as RedisService,
        config as unknown as ConfigService,
      );
      const result = await service.computeRoute([
        { lat: 30.0444, lng: 31.2357 },
        { lat: 30.054, lng: 31.249 },
        { lat: 30.06, lng: 31.255 },
      ]);

      expect(fetchMock).toHaveBeenCalledTimes(1);
      const firstArg = fetchMock.mock.calls[0]?.[0];
      const requestUrl = typeof firstArg === 'string' ? firstArg : '';
      expect(requestUrl).toContain(
        'https://router.example.org/route/v1/driving/31.2357,30.0444;31.249,30.054;31.255,30.06',
      );
      expect(result.isRoadRoute).toBe(true);
      expect(result.source).toBe('osrm');
      expect(result.coordinates).toHaveLength(4);
      expect(result.distanceMeters).toBe(4210);
      expect(result.durationSeconds).toBe(580);
      expect(decodePolyline(result.encodedPolyline)).toHaveLength(4);
      expect(redis.set).toHaveBeenCalledTimes(1);

      // Subsequent identical request hits in-memory LRU without extra OSRM fetch
      const cached = await service.computeRoute([
        { lat: 30.0444, lng: 31.2357 },
        { lat: 30.054, lng: 31.249 },
        { lat: 30.06, lng: 31.255 },
      ]);
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(cached.encodedPolyline).toBe(result.encodedPolyline);
    });

    it('returns cached road route from Redis without hitting OSRM', async () => {
      const cachedPayload = {
        encodedPolyline: '_p~iF~ps|U_ulLnnqC',
        coordinates: [
          { latitude: 30.0444, longitude: 31.2357 },
          { latitude: 30.06, longitude: 31.255 },
        ],
        waypoints: [
          { latitude: 30.0444, longitude: 31.2357 },
          { latitude: 30.06, longitude: 31.255 },
        ],
        distanceMeters: 2100,
        durationSeconds: 300,
        isRoadRoute: true,
        source: 'osrm',
      };
      const redis = {
        get: jest.fn().mockResolvedValue(JSON.stringify(cachedPayload)),
        set: jest.fn(),
      };
      const fetchMock = jest.fn();
      global.fetch = fetchMock as typeof global.fetch;

      const service = new RoutingService(redis as unknown as RedisService);
      const res = await service.computeRoute([
        { lat: 30.0444, lng: 31.2357 },
        { lat: 30.06, lng: 31.255 },
      ]);

      expect(res).toEqual(cachedPayload);
      expect(fetchMock).not.toHaveBeenCalled();
    });

    it('returns non-cached fallback when OSRM fails or times out', async () => {
      const redis = {
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn(),
      };
      const fetchMock = jest
        .fn()
        .mockRejectedValue(new Error('network timeout'));
      global.fetch = fetchMock as typeof global.fetch;

      const service = new RoutingService(redis as unknown as RedisService);
      const res = await service.computeRoute([
        { lat: 30.0444, lng: 31.2357 },
        { lat: 30.06, lng: 31.255 },
      ]);

      expect(res.isRoadRoute).toBe(false);
      expect(res.source).toBe('fallback');
      expect(res.coordinates).toHaveLength(2);
      expect(res.durationSeconds).toBe(0);
      expect(redis.set).not.toHaveBeenCalled();
    });
  });
});
