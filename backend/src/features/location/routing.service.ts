import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { GeoPoint, haversineKm } from '../../common/geo/geo.utils';
import {
  deduplicateAdjacentWaypoints,
  encodePolyline,
  isValidGeoPoint,
} from '../../common/geo/polyline.utils';

export type RouteSource = 'osrm' | 'fallback';

export interface RouteCoordinate {
  latitude: number;
  longitude: number;
}

export interface ComputedRouteResult {
  encodedPolyline: string;
  coordinates: RouteCoordinate[];
  waypoints: RouteCoordinate[];
  distanceMeters: number;
  durationSeconds: number;
  isRoadRoute: boolean;
  source: RouteSource;
}

interface OsrmRouteApiResponse {
  code?: string;
  routes?: Array<{
    distance?: number;
    duration?: number;
    geometry?: {
      coordinates?: Array<[number, number]>;
    };
  }>;
}

const DEFAULT_OSRM_BASE_URL = 'https://router.project-osrm.org';
const ROUTE_CACHE_KEY_PREFIX = 'otlobegy:route:v1:';
const ROUTE_CACHE_TTL_SECONDS = 900; // 15 minutes
const OSRM_TIMEOUT_MS = 3500;
const MAX_L1_CACHE_ENTRIES = 250;
const MIN_ROUTABLE_PATH_KM = 0.015; // 15m

/**
 * Shared road-routing service computing driving directions and encoded polylines
 * along ordered waypoints via OSRM with Redis + bounded L1 caching and
 * graceful straight-chord fallback when offline/unreachable.
 */
@Injectable()
export class RoutingService {
  private readonly logger = new Logger(RoutingService.name);
  private readonly l1Cache = new Map<
    string,
    { value: ComputedRouteResult; expiresAt: number }
  >();
  private readonly inFlight = new Map<string, Promise<ComputedRouteResult>>();

  constructor(
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  async computeRoute(
    rawWaypoints: readonly GeoPoint[],
  ): Promise<ComputedRouteResult> {
    const validInput = rawWaypoints.filter(isValidGeoPoint);
    if (validInput.length < 2) {
      return this.buildFallbackRoute(validInput);
    }

    const waypoints = deduplicateAdjacentWaypoints(
      validInput,
      MIN_ROUTABLE_PATH_KM,
    );
    if (waypoints.length < 2) {
      return this.buildFallbackRoute(validInput);
    }

    const totalStraightKm = this.computeTotalStraightKm(waypoints);
    if (totalStraightKm < MIN_ROUTABLE_PATH_KM) {
      return this.buildFallbackRoute(waypoints);
    }

    const cacheSuffix = waypoints
      .map((p) => `${p.lat.toFixed(5)},${p.lng.toFixed(5)}`)
      .join('|');
    const cacheKey = `${ROUTE_CACHE_KEY_PREFIX}${cacheSuffix}`;

    const l1Hit = this.readL1Cache(cacheKey);
    if (l1Hit) return l1Hit;

    const redisHit = await this.readRedisCache(cacheKey);
    if (redisHit) {
      this.writeL1Cache(cacheKey, redisHit);
      return redisHit;
    }

    const existingPromise = this.inFlight.get(cacheKey);
    if (existingPromise) {
      return existingPromise;
    }

    const pending = this.fetchAndCacheRoute(cacheKey, waypoints).finally(() => {
      this.inFlight.delete(cacheKey);
    });
    this.inFlight.set(cacheKey, pending);
    return pending;
  }

  private getBaseUrl(): string {
    const configured =
      this.configService?.get<string>('OSRM_BASE_URL') ??
      process.env.OSRM_BASE_URL ??
      DEFAULT_OSRM_BASE_URL;
    const trimmed = configured.trim();
    return (trimmed.length > 0 ? trimmed : DEFAULT_OSRM_BASE_URL).replace(
      /\/+$/,
      '',
    );
  }

  private async fetchAndCacheRoute(
    cacheKey: string,
    waypoints: readonly GeoPoint[],
  ): Promise<ComputedRouteResult> {
    const coordStr = waypoints.map((p) => `${p.lng},${p.lat}`).join(';');
    const url =
      `${this.getBaseUrl()}/route/v1/driving/${coordStr}` +
      '?overview=full&geometries=geojson&steps=false&continue_straight=default';

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), OSRM_TIMEOUT_MS);

    try {
      const response = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          Accept: 'application/json',
        },
      });

      if (!response.ok) {
        this.logger.warn(
          `OSRM returned HTTP ${response.status} for ${waypoints.length} waypoints`,
        );
        return this.buildFallbackRoute(waypoints);
      }

      const payload = (await response.json()) as OsrmRouteApiResponse;
      if (
        payload?.code !== 'Ok' ||
        !Array.isArray(payload.routes) ||
        payload.routes.length === 0
      ) {
        this.logger.warn(
          `OSRM returned non-Ok payload (${payload?.code ?? 'unknown'})`,
        );
        return this.buildFallbackRoute(waypoints);
      }

      const primary = payload.routes[0];
      const rawCoords = primary?.geometry?.coordinates;
      if (!Array.isArray(rawCoords) || rawCoords.length < 2) {
        return this.buildFallbackRoute(waypoints);
      }

      const points: GeoPoint[] = [];
      for (const pair of rawCoords) {
        if (!Array.isArray(pair) || pair.length < 2) continue;
        const point: GeoPoint = {
          lng: Number(pair[0]),
          lat: Number(pair[1]),
        };
        if (isValidGeoPoint(point)) {
          points.push(point);
        }
      }

      if (points.length < 2) {
        return this.buildFallbackRoute(waypoints);
      }

      const distanceMeters = Math.max(
        0,
        Math.round(Number(primary.distance ?? 0)),
      );
      const durationSeconds = Math.max(
        0,
        Math.round(Number(primary.duration ?? 0)),
      );

      const result: ComputedRouteResult = {
        encodedPolyline: encodePolyline(points),
        coordinates: points.map((p) => ({
          latitude: p.lat,
          longitude: p.lng,
        })),
        waypoints: waypoints.map((p) => ({
          latitude: p.lat,
          longitude: p.lng,
        })),
        distanceMeters,
        durationSeconds,
        isRoadRoute: true,
        source: 'osrm',
      };

      // Never cache fallback straight lines; only cache genuine OSRM road geometry.
      this.writeL1Cache(cacheKey, result);
      await this.writeRedisCache(cacheKey, result);
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`OSRM road route fetch failed: ${message}`);
      return this.buildFallbackRoute(waypoints);
    } finally {
      clearTimeout(timer);
    }
  }

  private buildFallbackRoute(
    waypoints: readonly GeoPoint[],
  ): ComputedRouteResult {
    const distanceMeters = Math.round(
      this.computeTotalStraightKm(waypoints) * 1000,
    );
    return {
      encodedPolyline: encodePolyline(waypoints),
      coordinates: waypoints.map((p) => ({
        latitude: p.lat,
        longitude: p.lng,
      })),
      waypoints: waypoints.map((p) => ({
        latitude: p.lat,
        longitude: p.lng,
      })),
      distanceMeters,
      durationSeconds: 0,
      isRoadRoute: false,
      source: 'fallback',
    };
  }

  private computeTotalStraightKm(waypoints: readonly GeoPoint[]): number {
    let total = 0;
    for (let i = 1; i < waypoints.length; i++) {
      total += haversineKm(waypoints[i - 1], waypoints[i]);
    }
    return total;
  }

  private readL1Cache(cacheKey: string): ComputedRouteResult | null {
    const hit = this.l1Cache.get(cacheKey);
    if (!hit) return null;
    if (Date.now() >= hit.expiresAt) {
      this.l1Cache.delete(cacheKey);
      return null;
    }
    // Refresh insertion order for LRU eviction.
    this.l1Cache.delete(cacheKey);
    this.l1Cache.set(cacheKey, hit);
    return hit.value;
  }

  private writeL1Cache(cacheKey: string, value: ComputedRouteResult): void {
    if (this.l1Cache.size >= MAX_L1_CACHE_ENTRIES) {
      const oldest = this.l1Cache.keys().next();
      if (!oldest.done) this.l1Cache.delete(oldest.value);
    }
    this.l1Cache.set(cacheKey, {
      value,
      expiresAt: Date.now() + ROUTE_CACHE_TTL_SECONDS * 1000,
    });
  }

  private async readRedisCache(
    cacheKey: string,
  ): Promise<ComputedRouteResult | null> {
    if (!this.redis) return null;
    try {
      const raw = await this.redis.get(cacheKey);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as ComputedRouteResult;
      if (
        parsed?.isRoadRoute !== true ||
        !parsed.encodedPolyline ||
        !Array.isArray(parsed.coordinates) ||
        parsed.coordinates.length < 2
      ) {
        return null;
      }
      return parsed;
    } catch {
      return null;
    }
  }

  private async writeRedisCache(
    cacheKey: string,
    value: ComputedRouteResult,
  ): Promise<void> {
    if (!this.redis) return;
    try {
      await this.redis.set(
        cacheKey,
        JSON.stringify(value),
        ROUTE_CACHE_TTL_SECONDS,
      );
    } catch (error) {
      this.logger.warn(
        `Failed to write Redis route cache: ${(error as Error).message}`,
      );
    }
  }
}
