import { Injectable, Logger } from '@nestjs/common';
import { DriverStatus, DriverTier } from '@prisma/client';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from './location.repository';

export {
  STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES,
  RIDE_ELIGIBLE_VEHICLE_TYPES,
  CUSTOM_DELIVERY_ELIGIBLE_VEHICLE_TYPES,
  buildVehicleAvailabilitySettings,
  getEligibleVehicleTypesForOrderType,
  isValidRegisteredVehicleType,
  isVehicleTypeAllowedForOrderType,
  isVehicleTypeActiveInSettings,
  resolveAllowedVehicleTypes,
  isDriverVehicleEligibleForOrder,
} from '../../common/orders/vehicle-eligibility.helper';
export type { VehicleAvailabilitySettings } from '../../common/orders/vehicle-eligibility.helper';

const GEO_POOL_ACTIVE_DRIVER_STATUSES: readonly string[] = [
  DriverStatus.ONLINE,
  DriverStatus.ON_DELIVERY,
];

const MAX_DISPATCH_CANDIDATES = 20;

export interface NearbyDriverMatch {
  id: string;
  userId: string;
  tier?: string;
  vehicleType?: string | null;
  distanceKm: number;
  activeShiftId: string | null;
  isOnDelivery?: boolean;
}

/**
 * Domain service owning dispatch driver geo-matching rules (radius candidate
 * bounds, batching corridors, shift/vehicle filters) and geo-pool hygiene.
 */
@Injectable()
export class DriverGeoSearchService {
  private readonly logger = new Logger(DriverGeoSearchService.name);

  constructor(
    private readonly locationRepository: LocationRepository,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async findNearbyDrivers(
    longitude: number,
    latitude: number,
    radiusKm: number,
    excludedDriverIds: string[] = [],
    allowedVehicleTypes: string[] = [],
    requireActiveShift: boolean = false,
    dropoffLocation?: { lng: number; lat: number } | null,
    allowStacking: boolean = true,
  ): Promise<NearbyDriverMatch[]> {
    if (allowedVehicleTypes.length === 0) return [];

    const settings = await this.platformSettings.getSettings();
    const geoCandidateLimit = Number(
      settings.driverSearchGeoCandidateLimit ?? 200,
    );

    let nearby = await this.locationRepository.georadiusDrivers(
      longitude,
      latitude,
      radiusKm,
      geoCandidateLimit,
    );
    if (nearby.length === 0) return [];

    const excludedSet = new Set(excludedDriverIds);
    const maxActiveOrders = Number(settings.maxActiveOrdersPerDriver ?? 1);
    const maxVendorMeters =
      Number(settings.batchMaxVendorDistanceKm ?? 2.0) * 1000;
    const maxCustomerMeters =
      Number(settings.batchMaxCustomerDistanceKm ?? 2.5) * 1000;

    const filterAndQuery = async (
      pool: Array<{ member: string; distanceKm: number }>,
    ) => {
      const rawCandidateIds = pool
        .filter((n) => !excludedSet.has(n.member))
        .map((n) => n.member);
      if (rawCandidateIds.length === 0) {
        return {
          rows: [] as Awaited<
            ReturnType<LocationRepository['queryNearbyEligibleDrivers']>
          >,
          candidateIds: rawCandidateIds,
          staleGpsIds: [] as string[],
        };
      }

      const freshIds =
        await this.locationRepository.filterFreshDriverIds(rawCandidateIds);
      const freshCandidateIds = rawCandidateIds.filter((id) =>
        freshIds.has(id),
      );
      const staleGpsIds = rawCandidateIds.filter((id) => !freshIds.has(id));
      if (freshCandidateIds.length === 0) {
        return {
          rows: [] as Awaited<
            ReturnType<LocationRepository['queryNearbyEligibleDrivers']>
          >,
          candidateIds: freshCandidateIds,
          staleGpsIds,
        };
      }

      const matched = await this.locationRepository.queryNearbyEligibleDrivers({
        candidateIds: freshCandidateIds,
        longitude,
        latitude,
        allowedVehicleTypes,
        requireActiveShift,
        maxActiveOrders,
        maxVendorMeters,
        maxCustomerMeters,
        activeOrderStatuses: DRIVER_ACTIVE_ORDER_STATUSES,
        dropoffLocation,
        allowStacking,
      });
      return { rows: matched, candidateIds: freshCandidateIds, staleGpsIds };
    };

    let { rows, candidateIds, staleGpsIds } = await filterAndQuery(nearby);

    // If the initial GEORADIUS hit the candidate cap (e.g., 200+ motorcycles in
    // a dense zone) and returned zero matches for the requested vehicle type,
    // widen the geo scan once so rarer vehicles further inside the radius are
    // not starved.
    if (rows.length === 0 && nearby.length >= geoCandidateLimit) {
      const widenedLimit = Math.max(geoCandidateLimit * 5, 1000);
      nearby = await this.locationRepository.georadiusDrivers(
        longitude,
        latitude,
        radiusKm,
        widenedLimit,
      );
      ({ rows, candidateIds, staleGpsIds } = await filterAndQuery(nearby));
    }

    const distanceMap = new Map<string, number>();
    for (const n of nearby) {
      distanceMap.set(n.member, n.distanceKm);
    }

    const eligibleDriverIds = new Set(rows.map((r) => r.id));
    const nonEligibleIds = candidateIds.filter(
      (id) => !eligibleDriverIds.has(id),
    );

    // Lazy sweep: prune drivers in Redis whose GPS freshness TTL expired or who
    // are no longer offerable in Postgres.
    if (staleGpsIds.length > 0) {
      this.locationRepository
        .removeDriverLocations(staleGpsIds)
        .catch((err: Error) =>
          this.logger.warn(
            `Failed to lazy-sweep stale-GPS drivers from Redis: ${err.message}`,
          ),
        );
    }
    if (nonEligibleIds.length > 0) {
      this.locationRepository
        .findEligibleGeoPoolDriverIds(
          nonEligibleIds,
          GEO_POOL_ACTIVE_DRIVER_STATUSES,
          { requireApproved: true },
        )
        .then((stillValidIds) => {
          const trulyStale = nonEligibleIds.filter(
            (id) => !stillValidIds.has(id),
          );
          if (trulyStale.length > 0) {
            return this.locationRepository
              .removeDriverLocations(trulyStale)
              .catch((err: Error) =>
                this.logger.warn(
                  `Failed to lazy-sweep stale drivers from Redis: ${err.message}`,
                ),
              );
          }
          return undefined;
        })
        .catch(() => {});
    }

    const results: NearbyDriverMatch[] = rows.map((r) => ({
      id: r.id,
      userId: r.userId,
      tier: r.tier ?? DriverTier.SILVER,
      vehicleType: r.vehicleType ?? null,
      distanceKm: distanceMap.get(r.id) ?? 0,
      activeShiftId: r.activeShiftId ?? null,
      isOnDelivery: Boolean(r.isOnDelivery),
    }));

    results.sort((a, b) => a.distanceKm - b.distanceKm);
    return results.slice(0, MAX_DISPATCH_CANDIDATES);
  }

  async sweepStaleDriverLocations(): Promise<{
    scanned: number;
    removed: number;
  }> {
    const members = await this.locationRepository.scanDriverGeoMembers(1000);
    if (members.length === 0) return { scanned: 0, removed: 0 };

    const [valid, fresh] = await Promise.all([
      this.locationRepository.findEligibleGeoPoolDriverIds(
        members,
        GEO_POOL_ACTIVE_DRIVER_STATUSES,
        { chunkSize: 500, requireApproved: true },
      ),
      this.locationRepository.filterFreshDriverIds(members),
    ]);

    const stale = members.filter((id) => !valid.has(id) || !fresh.has(id));
    if (stale.length === 0) return { scanned: members.length, removed: 0 };

    for (let i = 0; i < stale.length; i += 1000) {
      await this.locationRepository.removeDriverLocations(
        stale.slice(i, i + 1000),
      );
    }

    this.logger.log(
      `Geo freshness sweep: pruned ${stale.length} stale member(s) of ${members.length}`,
    );
    return { scanned: members.length, removed: stale.length };
  }
}
