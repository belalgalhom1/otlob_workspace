import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

export const DRIVER_GEO_POOL_KEY = 'otlobegy:driver-locations';
const DRIVER_FRESHNESS_KEY_PREFIX = 'otlobegy:driver-location-ts:';
const USER_DRIVER_MAP_KEY_PREFIX = 'otlobegy:user-driver-map:';
const DRIVER_ACTIVE_ORDER_KEY_PREFIX = 'otlobegy:driver-active-order:';

export interface ZoneLocationSummary {
  id: string;
  name: string;
  nameAr: string | null;
  isActive: boolean;
  baseDeliveryFeeOverride: number | null;
  minOrderAmountOverride: number | null;
}

export interface NearbyDriverCandidateRow {
  id: string;
  userId: string;
  tier: string | null;
  vehicleType: string | null;
  activeShiftId: string | null;
  isOnDelivery: boolean;
}

export interface OrderDriverLocationSnapshot {
  driverId: string | null;
  customerUserId: string;
  lastLng: number | null;
  lastLat: number | null;
}

/**
 * Pure persistence & PostGIS/Redis-Geo query repository for the location feature.
 * Contains no business policies (settings thresholds, privacy rules, ownership,
 * or presence heuristics); domain services supply those parameters explicitly.
 */
@Injectable()
export class LocationRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  // ─── Redis Geo & Presence Cache Primitives ───────────────────────────────

  async getCachedUserDriverId(userId: string): Promise<string | null> {
    return this.redis.get(`${USER_DRIVER_MAP_KEY_PREFIX}${userId}`);
  }

  async cacheUserDriverId(
    userId: string,
    driverId: string,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.set(
      `${USER_DRIVER_MAP_KEY_PREFIX}${userId}`,
      driverId,
      ttlSecs,
    );
  }

  async getCachedDriverActiveOrderRaw(
    driverId: string,
  ): Promise<string | null> {
    return this.redis.get(`${DRIVER_ACTIVE_ORDER_KEY_PREFIX}${driverId}`);
  }

  async setCachedDriverActiveOrderRaw(
    driverId: string,
    payloadJson: string,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.set(
      `${DRIVER_ACTIVE_ORDER_KEY_PREFIX}${driverId}`,
      payloadJson,
      ttlSecs,
    );
  }

  async clearCachedDriverActiveOrder(driverId: string): Promise<void> {
    await this.redis.del(`${DRIVER_ACTIVE_ORDER_KEY_PREFIX}${driverId}`);
  }

  async upsertDriverGeoPoint(
    driverId: string,
    lng: number,
    lat: number,
    freshnessTtlSecs: number,
  ): Promise<void> {
    await this.redis.geoadd(DRIVER_GEO_POOL_KEY, lng, lat, driverId);
    await this.redis.set(
      `${DRIVER_FRESHNESS_KEY_PREFIX}${driverId}`,
      String(Date.now()),
      freshnessTtlSecs,
    );
  }

  async isDriverLocationFresh(driverId: string): Promise<boolean> {
    const ts = await this.redis.get(
      `${DRIVER_FRESHNESS_KEY_PREFIX}${driverId}`,
    );
    return ts !== null;
  }

  async getDriverLocation(
    driverId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    return this.redis.geopos(DRIVER_GEO_POOL_KEY, driverId);
  }

  async removeDriverLocation(driverId: string): Promise<void> {
    await this.redis.zrem(DRIVER_GEO_POOL_KEY, driverId);
  }

  async removeDriverLocations(driverIds: string[]): Promise<number> {
    if (driverIds.length === 0) return 0;
    return this.redis.zremMembers(DRIVER_GEO_POOL_KEY, driverIds);
  }

  async georadiusDrivers(
    longitude: number,
    latitude: number,
    radiusKm: number,
    limit: number,
  ): Promise<Array<{ member: string; distanceKm: number }>> {
    return this.redis.georadius(
      DRIVER_GEO_POOL_KEY,
      longitude,
      latitude,
      radiusKm,
      limit,
    );
  }

  async scanDriverGeoMembers(pageSize = 1000): Promise<string[]> {
    const members: string[] = [];
    for (let offset = 0; ; offset += pageSize) {
      const chunk = await this.redis.zrange(
        DRIVER_GEO_POOL_KEY,
        offset,
        offset + pageSize - 1,
      );
      if (chunk.length === 0) break;
      members.push(...chunk);
      if (chunk.length < pageSize) break;
    }
    return members;
  }

  async getLiveDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number; isFresh: boolean }>> {
    const map = new Map<
      string,
      { lng: number; lat: number; isFresh: boolean }
    >();
    if (driverIds.length === 0) return map;

    const positions = await this.redis.geoposMany(
      DRIVER_GEO_POOL_KEY,
      driverIds,
    );
    await Promise.all(
      [...positions.keys()].map(async (id) => {
        const isFresh = await this.isDriverLocationFresh(id);
        map.set(id, { ...positions.get(id)!, isFresh });
      }),
    );
    return map;
  }

  // ─── Prisma / PostGIS Data Queries ────────────────────────────────────────

  async findDriverByUserId(
    userId: string,
  ): Promise<{ id: string; status: string } | null> {
    return this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true, status: true },
    });
  }

  async findEligibleGeoPoolDriverIds(
    driverIds: string[],
    allowedStatuses: readonly string[],
    options?: { requireApproved?: boolean; chunkSize?: number },
  ): Promise<Set<string>> {
    const valid = new Set<string>();
    if (driverIds.length === 0 || allowedStatuses.length === 0) return valid;

    const chunkSize = options?.chunkSize ?? 500;
    const approvedClause = options?.requireApproved
      ? Prisma.sql`AND d."isApproved" = true`
      : Prisma.empty;

    for (let i = 0; i < driverIds.length; i += chunkSize) {
      const chunk = driverIds.slice(i, i + chunkSize);
      const rows = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT d.id
        FROM drivers d
        WHERE d.id IN (${Prisma.join(chunk)})
          AND d."deletedAt" IS NULL
          ${approvedClause}
          AND d."hasUnpaidCommission" = false
          AND d.status::text IN (${Prisma.join(allowedStatuses)})
      `;
      for (const r of rows) {
        valid.add(r.id);
      }
    }

    return valid;
  }

  async getPersistedDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number }>> {
    const map = new Map<string, { lng: number; lat: number }>();
    if (driverIds.length === 0) return map;

    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; lng: number | null; lat: number | null }>
    >`
      SELECT
        id,
        ST_X("lastLocation"::geometry) AS "lng",
        ST_Y("lastLocation"::geometry) AS "lat"
      FROM drivers
      WHERE id IN (${Prisma.join(driverIds)})
    `;

    for (const r of rows) {
      if (r.lng != null && r.lat != null) {
        map.set(r.id, { lng: Number(r.lng), lat: Number(r.lat) });
      }
    }
    return map;
  }

  async queryOrderDriverLocationSnapshot(
    orderId: string,
  ): Promise<OrderDriverLocationSnapshot | null> {
    const rows = await this.prisma.$queryRaw<OrderDriverLocationSnapshot[]>`
      SELECT
        (
          SELECT g."primaryDriverId"
          FROM order_delivery_groups g
          WHERE g."orderId" = o.id
            AND g."primaryDriverId" IS NOT NULL
            AND g.status::text NOT IN ('CANCELLED', 'DELIVERED')
          ORDER BY g.sequence ASC
          LIMIT 1
        ) AS "driverId",
        c."userId" AS "customerUserId",
        ST_X(d."lastLocation"::geometry) AS "lastLng",
        ST_Y(d."lastLocation"::geometry) AS "lastLat"
      FROM orders o
      JOIN customers c ON c.id = o."customerId"
      LEFT JOIN drivers d ON d.id = (
        SELECT g."primaryDriverId"
        FROM order_delivery_groups g
        WHERE g."orderId" = o.id
          AND g."primaryDriverId" IS NOT NULL
          AND g.status::text NOT IN ('CANCELLED', 'DELIVERED')
        ORDER BY g.sequence ASC
        LIMIT 1
      )
      WHERE o.id = ${orderId}
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  async getDistanceKm(
    fromLng: number,
    fromLat: number,
    toLng: number,
    toLat: number,
  ): Promise<number> {
    const rows = await this.prisma.$queryRaw<Array<{ km: number }>>`
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint(${fromLng}, ${fromLat}), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${toLng}, ${toLat}), 4326)::geography
      ) / 1000 AS km
    `;
    return rows[0]?.km ?? 0;
  }

  async queryNearbyEligibleDrivers(params: {
    candidateIds: string[];
    longitude: number;
    latitude: number;
    allowedVehicleTypes: string[];
    requireActiveShift: boolean;
    maxActiveOrders: number;
    maxVendorMeters: number;
    maxCustomerMeters: number;
    activeOrderStatuses: readonly string[];
    dropoffLocation?: { lng: number; lat: number } | null;
  }): Promise<NearbyDriverCandidateRow[]> {
    const {
      candidateIds,
      longitude,
      latitude,
      allowedVehicleTypes,
      requireActiveShift,
      maxActiveOrders,
      maxVendorMeters,
      maxCustomerMeters,
      activeOrderStatuses,
      dropoffLocation,
    } = params;

    if (candidateIds.length === 0) return [];

    const vehicleTypeCond =
      allowedVehicleTypes.length > 0
        ? Prisma.sql`AND d."vehicleType"::text IN (${Prisma.join(allowedVehicleTypes)})`
        : Prisma.empty;

    const activeShiftCond = requireActiveShift
      ? Prisma.sql`AND ds.id IS NOT NULL`
      : Prisma.empty;

    const activeStatusCond =
      activeOrderStatuses.length > 0
        ? Prisma.sql`AND g.status::text IN (${Prisma.join(activeOrderStatuses)})`
        : Prisma.sql`AND FALSE`;
    const corridorCond = dropoffLocation
      ? Prisma.sql`AND EXISTS (
          SELECT 1
          FROM order_delivery_groups g
          JOIN orders o ON o.id = g."orderId"
          LEFT JOIN order_delivery_group_items gi ON gi."deliveryGroupId" = g.id
          LEFT JOIN order_vendor_fulfillments f
            ON f.id = gi."fulfillmentId"
            AND f.status::text NOT IN ('REJECTED', 'CANCELLED')
          LEFT JOIN vendor_branches b ON b.id = f."vendorBranchId"
          WHERE (g."primaryDriverId" = d.id OR g."assistDriverId" = d.id)
            ${activeStatusCond}
            AND ST_DWithin(
              COALESCE(b."location", o."pickupLocation")::geography,
              ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
              ${maxVendorMeters}
            )
            AND ST_DWithin(
              o."deliveryLocation"::geography,
              ST_SetSRID(ST_MakePoint(${dropoffLocation.lng}, ${dropoffLocation.lat}), 4326)::geography,
              ${maxCustomerMeters}
            )
        )`
      : Prisma.empty;

    const driverAvailabilityCond =
      maxActiveOrders > 1
        ? Prisma.sql`AND (
            d.status::text = 'ONLINE'
            OR (
              d.status::text = 'ON_DELIVERY'
              AND (
                SELECT COUNT(*)::int
                FROM order_delivery_groups g
                WHERE (g."primaryDriverId" = d.id OR g."assistDriverId" = d.id)
                  ${activeStatusCond}
              ) < ${maxActiveOrders}
              ${corridorCond}
            )
          )`
        : Prisma.sql`AND d.status::text = 'ONLINE'`;

    return this.prisma.$queryRaw<NearbyDriverCandidateRow[]>`
      SELECT
        d.id,
        d."userId",
        d.tier,
        d."vehicleType"::text AS "vehicleType",
        ds.id AS "activeShiftId",
        (d.status::text = 'ON_DELIVERY') AS "isOnDelivery"
      FROM drivers d
      LEFT JOIN driver_shifts ds
        ON ds."driverId" = d.id
        AND ds.status::text = 'ACTIVE'
      WHERE d.id IN (${Prisma.join(candidateIds)})
        ${driverAvailabilityCond}
        AND d."deletedAt" IS NULL
        AND d."isApproved" = true
        AND d."hasUnpaidCommission" = false
        ${vehicleTypeCond}
        ${activeShiftCond}
    `;
  }

  // ─── PostGIS Zone Spatial Queries ─────────────────────────────────────────

  async isPointInZone(
    zoneId: string,
    longitude: number,
    latitude: number,
    options?: { activeOnly?: boolean },
  ): Promise<boolean> {
    const activeClause = options?.activeOnly
      ? Prisma.sql`AND "isActive" = true`
      : Prisma.empty;
    const rows = await this.prisma.$queryRaw<{ inside: boolean }[]>`
      SELECT ST_Covers(
        ST_MakeValid("boundary"),
        ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)
      ) AS inside
      FROM zones
      WHERE id = ${zoneId}
        ${activeClause}
      LIMIT 1
    `;
    return rows[0]?.inside === true;
  }

  async findContainingActiveZone(
    longitude: number,
    latitude: number,
  ): Promise<ZoneLocationSummary | null> {
    const zones = await this.prisma.$queryRaw<ZoneLocationSummary[]>`
      SELECT
        "id", "name", "nameAr", "isActive",
        "baseDeliveryFeeOverride", "minOrderAmountOverride"
      FROM "zones"
      WHERE ST_Covers(
          ST_MakeValid("boundary"),
          ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)
        )
        AND "isActive" = true
      ORDER BY ST_Area("boundary") ASC
      LIMIT 1
    `;
    return zones[0] ?? null;
  }

  async findClosestActiveZoneId(
    longitude: number,
    latitude: number,
  ): Promise<string | null> {
    const rows = await this.prisma.$queryRaw<Array<{ id: string }>>`
      SELECT "id"
      FROM "zones"
      WHERE "isActive" = true
      ORDER BY ST_Distance(
        "boundary"::geography,
        ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography
      ) ASC
      LIMIT 1
    `;
    return rows[0]?.id ?? null;
  }

  // ─── Dispatch / Order Location Context Queries ────────────────────────────

  async getOrderLocationContext(orderId: string): Promise<{
    requestedVehicleType: string | null;
    lng: number;
    lat: number;
    deliveryLng: number;
    deliveryLat: number;
  } | null> {
    const rows = await this.prisma.$queryRaw<any[]>`
      SELECT
        "requestedVehicleType",
        COALESCE(
          ST_X("pickupLocation"::geometry),
          (
            SELECT ST_X(b.location::geometry)
            FROM order_vendor_fulfillments f
            JOIN vendor_branches b ON b.id = f."vendorBranchId"
            WHERE f."orderId" = orders.id
              AND f.status::text NOT IN ('REJECTED', 'CANCELLED')
            ORDER BY f."createdAt" ASC
            LIMIT 1
          ),
          ST_X("deliveryLocation"::geometry)
        ) AS lng,
        COALESCE(
          ST_Y("pickupLocation"::geometry),
          (
            SELECT ST_Y(b.location::geometry)
            FROM order_vendor_fulfillments f
            JOIN vendor_branches b ON b.id = f."vendorBranchId"
            WHERE f."orderId" = orders.id
              AND f.status::text NOT IN ('REJECTED', 'CANCELLED')
            ORDER BY f."createdAt" ASC
            LIMIT 1
          ),
          ST_Y("deliveryLocation"::geometry)
        ) AS lat,
        ST_X("deliveryLocation"::geometry) AS "deliveryLng",
        ST_Y("deliveryLocation"::geometry) AS "deliveryLat"
      FROM orders
      WHERE id = ${orderId}
    `;
    return rows[0] || null;
  }

  async getDeliveryGroupPickupLocation(
    deliveryGroupId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    const rows = await this.prisma.$queryRaw<any[]>`
      SELECT ST_X(b."location"::geometry) AS lng,
             ST_Y(b."location"::geometry) AS lat
      FROM order_delivery_group_items gi
      JOIN order_vendor_fulfillments f ON f.id = gi."fulfillmentId"
      JOIN vendor_branches b ON b.id = f."vendorBranchId"
      WHERE gi."deliveryGroupId" = ${deliveryGroupId}
      ORDER BY gi.sequence ASC
      LIMIT 1
    `;
    return rows[0] || null;
  }
}
