import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PlatformSettingsService } from '../../features/platform-settings/platform-settings.service';
import { EVENTS } from 'src/common/events/event-names';
import { DriverLocationUpdatedEvent } from 'src/common/events';
import { Prisma } from '@prisma/client';

@Injectable()
export class LocationRepository {
  private readonly logger = new Logger(LocationRepository.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly eventEmitter: EventEmitter2,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  /**
   * Process a live high-frequency location update from WebSockets
   */
  async processLiveLocationUpdate(
    userId: string,
    lng: number,
    lat: number,
  ): Promise<void> {
    // 1. Resolve userId -> driverId (with Redis caching)
    let driverId = await this.redis.get(`otlobegy:user-driver-map:${userId}`);
    if (!driverId) {
      const driver = await this.prisma.driver.findUnique({
        where: { userId },
        select: { id: true },
      });
      if (!driver) return;
      driverId = driver.id;
      // Cache for 12 hours
      await this.redis.set(
        `otlobegy:user-driver-map:${userId}`,
        driverId,
        12 * 60 * 60,
      );
    }

    // 2. Track geospatial location in Redis
    await this.trackDriverLocation(driverId, lng, lat);

    // 3. Check if driver is actively delivering an order
    const activeOrderRaw = await this.redis.get(
      `otlobegy:driver-active-order:${driverId}`,
    );
    if (activeOrderRaw) {
      const activeOrder = JSON.parse(activeOrderRaw);
      const activeList: Array<{ orderId: string; customerUserId: string }> =
        Array.isArray(activeOrder?.orders) && activeOrder.orders.length > 0
          ? activeOrder.orders
          : activeOrder?.orderId
            ? [
                {
                  orderId: activeOrder.orderId,
                  customerUserId: activeOrder.customerUserId,
                },
              ]
            : [];

      // 4. Emit event instantly to broadcast to all active batched customers (Zero DB hits!)
      for (const entry of activeList) {
        if (!entry?.orderId) continue;
        this.eventEmitter.emit(
          EVENTS.DRIVER_LOCATION_UPDATED,
          new DriverLocationUpdatedEvent(
            driverId,
            userId,
            lng,
            lat,
            entry.orderId,
            entry.customerUserId,
          ),
        );
      }
    }
  }

  /**
   * Process user disconnect to clean up location pool
   */
  async handleUserDisconnect(userId: string): Promise<void> {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true, status: true },
    });
    if (!driver) return;

    // If driver is currently ONLINE or ON_DELIVERY, do NOT evict from active location pool on transient socket drops.
    // They continue to receive dispatches via FCM background push & HTTP fallback.
    // Drivers are explicitly removed from the pool when they switch status to OFFLINE.
    if (driver.status === 'ONLINE' || driver.status === 'ON_DELIVERY') {
      this.logger.debug(
        `Driver ${driver.id} socket disconnected, but driver is ${driver.status}. Preserving location in active pool.`,
      );
      return;
    }

    await this.removeDriverLocation(driver.id);
    this.logger.debug(
      `Removed driver ${driver.id} (${driver.status}) from active location pool due to disconnect`,
    );
  }

  /**
   * Reduce location precision for customer-facing display (security/privacy).
   * If precisionMeters > 0, rounds coordinates to a grid of that size.
   */
  static applyPrecisionReduction(
    lng: number,
    lat: number,
    precisionMeters: number,
  ): { lng: number; lat: number } {
    if (precisionMeters <= 0) return { lng, lat };
    // 1 degree latitude ≈ 111,111 meters
    // 1 degree longitude ≈ 111,111 * cos(lat) meters
    const latDeg = precisionMeters / 111111;
    const lngDeg = precisionMeters / (111111 * Math.cos((lat * Math.PI) / 180));
    const roundedLat = Math.round(lat / latDeg) * latDeg;
    const roundedLng = Math.round(lng / lngDeg) * lngDeg;
    return { lng: roundedLng, lat: roundedLat };
  }

  /**
   * Helper to build a PostGIS point for Prisma raw queries
   */
  static buildPointSql(lng: number, lat: number): Prisma.Sql {
    return Prisma.sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`;
  }

  /**
   * Track driver location in Redis
   */
  async trackDriverLocation(
    driverId: string,
    lng: number,
    lat: number,
  ): Promise<void> {
    const settings = await this.platformSettings.getSettings();
    await this.redis.geoadd('otlobegy:driver-locations', lng, lat, driverId);
    // Freshness signal: expires shortly after the driver stops broadcasting,
    // letting consumers tell a live position apart from a stale geo member.
    // Must comfortably exceed the driver app's slowest heartbeat (30s when
    // idle/stationary) or a live position would be misreported as stale.
    const ttlSecs = Number(settings.driverLocationFreshnessTtlSecs ?? 30);
    await this.redis.set(
      `otlobegy:driver-location-ts:${driverId}`,
      String(Date.now()),
      ttlSecs,
    );
  }

  /**
   * Whether the driver has broadcast a location within the freshness window.
   */
  async isDriverLocationFresh(driverId: string): Promise<boolean> {
    const ts = await this.redis.get(`otlobegy:driver-location-ts:${driverId}`);
    return ts !== null;
  }

  /**
   * Get current driver location from Redis
   */
  async getDriverLocation(
    driverId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    return this.redis.geopos('otlobegy:driver-locations', driverId);
  }

  /**
   * Remove driver from Redis active locations
   */
  async removeDriverLocation(driverId: string): Promise<void> {
    await this.redis.zrem('otlobegy:driver-locations', driverId);
  }

  /**
   * Global geo-pool hygiene: prune members whose driver is no longer available
   * (offline, suspended, deleted, or unpaid commission).
   *
   * ONLINE and ON_DELIVERY drivers are always preserved — a momentarily silent
   * driver stays offerable and keep live-tracking data intact. The per-query
   * lazy sweep in findNearbyDrivers only prunes within each search radius, so a
   * single global pass here keeps the set bounded without touching hot paths.
   */
  async sweepStaleDriverLocations(): Promise<{
    scanned: number;
    removed: number;
  }> {
    // Page through the geo set instead of pulling every member at once —
    // the fleet can be large and this sweep runs every few minutes.
    const members: string[] = [];
    const PAGE = 1000;
    for (let offset = 0; ; offset += PAGE) {
      const chunk = await this.redis.zrange(
        'otlobegy:driver-locations',
        offset,
        offset + PAGE - 1,
      );
      if (chunk.length === 0) break;
      members.push(...chunk);
      if (chunk.length < PAGE) break;
    }
    if (members.length === 0) return { scanned: 0, removed: 0 };

    // Batch the availability check to keep the SQL IN list reasonable.
    const CHUNK = 500;
    const stale: string[] = [];

    for (let i = 0; i < members.length; i += CHUNK) {
      const chunk = members.slice(i, i + CHUNK);
      const rows = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT d.id
        FROM drivers d
        WHERE d.id IN (${Prisma.join(chunk)})
          AND d."deletedAt" IS NULL
          AND d."hasUnpaidCommission" = false
          AND d.status::text IN ('ONLINE', 'ON_DELIVERY')
      `;

      const valid = new Set(rows.map((r) => r.id));
      for (const id of chunk) {
        if (!valid.has(id)) stale.push(id);
      }
    }

    if (stale.length === 0) return { scanned: members.length, removed: 0 };

    // ZREM in batches to respect per-command argument limits. Freshness keys
    // are left to their 90s TTL — no extra cleanup needed.
    for (let i = 0; i < stale.length; i += 1000) {
      await this.redis.zremMembers(
        'otlobegy:driver-locations',
        stale.slice(i, i + 1000),
      );
    }

    this.logger.log(
      `Geo freshness sweep: pruned ${stale.length} stale member(s) of ${members.length}`,
    );
    return { scanned: members.length, removed: stale.length };
  }

  /**
   * Live (fresh Redis broadcast) positions for a batch of drivers.
   */
  async getLiveDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number }>> {
    const map = new Map<string, { lng: number; lat: number }>();
    if (driverIds.length === 0) return map;
    // One GEOPOS round-trip for all drivers, then freshness checks only for
    // drivers that actually have a position.
    const positions = await this.redis.geoposMany(
      'otlobegy:driver-locations',
      driverIds,
    );
    await Promise.all(
      [...positions.keys()].map(async (id) => {
        if (await this.isDriverLocationFresh(id)) {
          map.set(id, positions.get(id)!);
        }
      }),
    );
    return map;
  }

  /**
   * Last persisted PostGIS locations for a batch of drivers.
   */
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

  /**
   * Resolve a driver's location for admin/management views: live Redis
   * position when fresh, falling back to the last persisted PostGIS point.
   * Returns null when the driver has never had a location.
   */
  async getDriverLocationWithState(
    driverId: string,
  ): Promise<{ lng: number; lat: number; isLive: boolean } | null> {
    const settings = await this.platformSettings.getSettings();
    const precisionMeters = Number(settings.driverLocationPrecisionMeters ?? 0);

    const live = await this.getDriverLocation(driverId);
    if (live && (await this.isDriverLocationFresh(driverId))) {
      const reduced = LocationRepository.applyPrecisionReduction(live.lng, live.lat, precisionMeters);
      return { ...reduced, isLive: true };
    }

    const map = await this.getPersistedDriverLocations([driverId]);
    const persisted = map.get(driverId);
    if (persisted) {
      const reduced = LocationRepository.applyPrecisionReduction(persisted.lng, persisted.lat, precisionMeters);
      return { ...reduced, isLive: false };
    }

    return null;
  }

  /**
   * Active order being delivered by the driver (Redis cache), if any.
   */
  async getDriverActiveOrder(
    driverId: string,
  ): Promise<{ orderId: string } | null> {
    const raw = await this.redis.get(
      `otlobegy:driver-active-order:${driverId}`,
    );
    if (!raw) return null;
    try {
      const parsed = JSON.parse(raw);
      return parsed?.orderId ? { orderId: parsed.orderId } : null;
    } catch {
      return null;
    }
  }

  /**
   * Resolve the current location of the driver assigned to an order.
   *
   * Ownership is enforced against the requesting customer user id. Prefers the
   * live Redis geo position and falls back to the driver's last persisted
   * location when the driver has never broadcast (e.g. stationary since going
   * online). Returns null when the order has no driver or the caller is not the
   * order's customer.
   */
  async getOrderDriverLocation(
    orderId: string,
    customerUserId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    const settings = await this.platformSettings.getSettings();
    const precisionMeters = Number(settings.driverLocationPrecisionMeters ?? 0);

    const rows = await this.prisma.$queryRaw<
      Array<{
        driverId: string | null;
        customerUserId: string;
        lastLng: number | null;
        lastLat: number | null;
      }>
    >`
      SELECT
        COALESCE(
          o."driverId",
          (
            SELECT g."primaryDriverId"
            FROM order_delivery_groups g
            WHERE g."orderId" = o.id
              AND g."primaryDriverId" IS NOT NULL
              AND g.status::text NOT IN ('CANCELLED', 'DELIVERED')
            ORDER BY g.sequence ASC
            LIMIT 1
          )
        ) AS "driverId",
        c."userId" AS "customerUserId",
        ST_X(d."lastLocation"::geometry) AS "lastLng",
        ST_Y(d."lastLocation"::geometry) AS "lastLat"
      FROM orders o
      JOIN customers c ON c.id = o."customerId"
      LEFT JOIN drivers d ON d.id = COALESCE(
        o."driverId",
        (
          SELECT g."primaryDriverId"
          FROM order_delivery_groups g
          WHERE g."orderId" = o.id
            AND g."primaryDriverId" IS NOT NULL
            AND g.status::text NOT IN ('CANCELLED', 'DELIVERED')
          ORDER BY g.sequence ASC
          LIMIT 1
        )
      )
      WHERE o.id = ${orderId}
      LIMIT 1
    `;

    const row = rows[0];
    if (!row || row.customerUserId !== customerUserId || !row.driverId) {
      return null;
    }

    const live = await this.getDriverLocation(row.driverId);
    if (live && (await this.isDriverLocationFresh(row.driverId))) {
      return LocationRepository.applyPrecisionReduction(live.lng, live.lat, precisionMeters);
    }

    if (row.lastLng != null && row.lastLat != null) {
      return LocationRepository.applyPrecisionReduction(row.lastLng, row.lastLat, precisionMeters);
    }

    return null;
  }

  /**
   * Helper to build a PostGIS geometry from GeoJSON
   */
  static buildGeoJsonSql(geoJson: string): Prisma.Sql {
    return Prisma.sql`ST_SetSRID(ST_GeomFromGeoJSON(${geoJson}), 4326)`;
  }

  /**
   * Calculate distance between two coordinates in kilometers using PostGIS
   */
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

  /**
   * Find nearby online drivers
   */
  async findNearbyDrivers(
    longitude: number,
    latitude: number,
    radiusKm: number,
    excludedDriverIds: string[] = [],
    allowedVehicleTypes: string[] = [],
    requireActiveShift: boolean = false,
    dropoffLocation?: { lng: number; lat: number } | null,
  ): Promise<
    {
      id: string;
      userId: string;
      distanceKm: number;
      activeShiftId: string | null;
      isOnDelivery?: boolean;
    }[]
  > {
    // Bound the GEO radius scan to the nearest N candidates. The SQL filter
    // (status/vehicleType/shift) may discard some, so keep a generous headroom
    // above the final cap of 20 that dispatch actually consumes. Without this
    // bound, a dense region can return the entire cluster on every round.
    const settings = await this.platformSettings.getSettings();
    const geoCandidateLimit = Number(settings.driverSearchGeoCandidateLimit ?? 200);

    const nearby = await this.redis.georadius(
      'otlobegy:driver-locations',
      longitude,
      latitude,
      radiusKm,
      geoCandidateLimit,
    );
    if (nearby.length === 0) return [];

    const candidateIds = nearby
      .filter((n) => !excludedDriverIds.includes(n.member))
      .map((n) => n.member);

    if (candidateIds.length === 0) return [];

    const distanceMap = new Map<string, number>();
    for (const n of nearby) {
      distanceMap.set(n.member, n.distanceKm);
    }

    const vehicleTypeCond =
      allowedVehicleTypes.length > 0
        ? Prisma.sql`AND d."vehicleType"::text IN (${Prisma.join(allowedVehicleTypes)})`
        : Prisma.empty;

    const activeShiftCond = requireActiveShift
      ? Prisma.sql`AND ds.id IS NOT NULL`
      : Prisma.empty;

    const maxActiveOrders = Number(settings.maxActiveOrdersPerDriver ?? 1);
    const maxVendorMeters = Number(settings.batchMaxVendorDistanceKm ?? 2.0) * 1000;
    const maxCustomerMeters = Number(settings.batchMaxCustomerDistanceKm ?? 2.5) * 1000;

    const corridorCond = dropoffLocation
      ? Prisma.sql`AND EXISTS (
          SELECT 1
          FROM orders o
          LEFT JOIN vendor_branches ob ON ob.id = o."vendorBranchId"
          LEFT JOIN order_delivery_groups g ON g."orderId" = o.id
          LEFT JOIN order_delivery_group_items gi ON gi."deliveryGroupId" = g.id
          LEFT JOIN order_vendor_fulfillments f ON f.id = gi."fulfillmentId"
          LEFT JOIN vendor_branches b ON b.id = f."vendorBranchId"
          WHERE (
            (g.id IS NULL AND o."driverId" = d.id AND o.status::text IN ('DRIVER_ASSIGNED', 'PREPARING', 'READY_FOR_PICKUP', 'PENDING_PAYMENT', 'PARTIALLY_PICKED_UP', 'PICKED_UP'))
            OR ((g."primaryDriverId" = d.id OR g."assistDriverId" = d.id) AND g.status::text NOT IN ('CANCELLED', 'DELIVERED'))
          )
          AND ST_DWithin(
            COALESCE(b."location", ob."location", o."pickupLocation")::geography,
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
                FROM (
                  SELECT g.id
                  FROM order_delivery_groups g
                  WHERE (g."primaryDriverId" = d.id OR g."assistDriverId" = d.id)
                    AND g.status::text NOT IN ('CANCELLED', 'DELIVERED')
                  UNION ALL
                  SELECT o.id
                  FROM orders o
                  WHERE o."driverId" = d.id
                    AND o.status::text IN ('DRIVER_ASSIGNED', 'PREPARING', 'READY_FOR_PICKUP', 'PENDING_PAYMENT', 'PARTIALLY_PICKED_UP', 'PICKED_UP')
                    AND NOT EXISTS (
                      SELECT 1 FROM order_delivery_groups og WHERE og."orderId" = o.id
                    )
                ) work
              ) < ${maxActiveOrders}
              ${corridorCond}
            )
          )`
        : Prisma.sql`AND d.status::text = 'ONLINE'`;

    const rows = await this.prisma.$queryRaw<any[]>`
      SELECT
        d.id,
        d."userId",
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

    const eligibleDriverIds = new Set(rows.map((r) => r.id));
    const nonEligibleIds = candidateIds.filter((id) => !eligibleDriverIds.has(id));

    // Lazy sweep: Remove drivers from Redis who are truly no longer available
    if (nonEligibleIds.length > 0) {
      this.prisma
        .$queryRaw<Array<{ id: string }>>`
          SELECT d.id
          FROM drivers d
          WHERE d.id IN (${Prisma.join(nonEligibleIds)})
            AND d."deletedAt" IS NULL
            AND d."isApproved" = true
            AND d."hasUnpaidCommission" = false
            AND d.status::text IN ('ONLINE', 'ON_DELIVERY')
        `
        .then((stillValid) => {
          const stillValidIds = new Set(stillValid.map((v) => v.id));
          const trulyStale = nonEligibleIds.filter(
            (id) => !stillValidIds.has(id),
          );
          if (trulyStale.length > 0) {
            this.redis
              .zremMembers('otlobegy:driver-locations', trulyStale)
              .catch((err: Error) =>
              this.logger.warn(
                `Failed to lazy-sweep stale drivers from Redis: ${err.message}`,
              ),
            );
          }
        })
        .catch(() => {});
    }

    const results = rows.map((r) => ({
      id: r.id,
      userId: r.userId,
      distanceKm: distanceMap.get(r.id) ?? 0,
      activeShiftId: r.activeShiftId ?? null,
      isOnDelivery: Boolean(r.isOnDelivery),
    }));

    results.sort((a, b) => a.distanceKm - b.distanceKm);

    return results.slice(0, 20);
  }

  /**
   * Whether the given point lies inside ONE specific zone.
   *
   * Deliberately checks the requested zone instead of resolving "which zone
   * contains this point": zones may overlap/nest, so picking an arbitrary
   * containing zone (unordered LIMIT 1) can return a different zone than the
   * one we care about and wrongly report the point as outside it.
   */
  async isPointInZone(
    zoneId: string,
    longitude: number,
    latitude: number,
  ): Promise<boolean> {
    const rows = await this.prisma.$queryRaw<{ inside: boolean }[]>`
      SELECT ST_Covers(
        ST_MakeValid("boundary"),
        ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)
      ) AS inside
      FROM zones
      WHERE id = ${zoneId}
      LIMIT 1
    `;
    return rows[0]?.inside === true;
  }

  /**
   * Extract order dispatch context locations
   */
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
          (SELECT ST_X(location::geometry) FROM vendor_branches WHERE id = orders."vendorBranchId"),
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
          (SELECT ST_Y(location::geometry) FROM vendor_branches WHERE id = orders."vendorBranchId"),
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
  /**
   * Pickup point for one delivery group: the first branch in the group's
   * planned pickup order. Raw SQL because `location` is `Unsupported("geometry")`
   * and cannot be selected through Prisma (same reason as
   * getOrderLocationContext). Returns null when the group has no branch yet.
   */
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
