import { Injectable, Logger } from '@nestjs/common';
import { DriverStatus, DriverTier } from '@prisma/client';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from './location.repository';

const GEO_POOL_ACTIVE_DRIVER_STATUSES: readonly string[] = [
  DriverStatus.ONLINE,
  DriverStatus.ON_DELIVERY,
];

const MAX_DISPATCH_CANDIDATES = 20;

export interface NearbyDriverMatch {
  id: string;
  userId: string;
  tier?: string;
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
  ): Promise<NearbyDriverMatch[]> {
    const settings = await this.platformSettings.getSettings();
    const geoCandidateLimit = Number(
      settings.driverSearchGeoCandidateLimit ?? 200,
    );

    const nearby = await this.locationRepository.georadiusDrivers(
      longitude,
      latitude,
      radiusKm,
      geoCandidateLimit,
    );
    if (nearby.length === 0) return [];

    const excludedSet = new Set(excludedDriverIds);
    const candidateIds = nearby
      .filter((n) => !excludedSet.has(n.member))
      .map((n) => n.member);
    if (candidateIds.length === 0) return [];

    const distanceMap = new Map<string, number>();
    for (const n of nearby) {
      distanceMap.set(n.member, n.distanceKm);
    }

    const maxActiveOrders = Number(settings.maxActiveOrdersPerDriver ?? 1);
    const maxVendorMeters =
      Number(settings.batchMaxVendorDistanceKm ?? 2.0) * 1000;
    const maxCustomerMeters =
      Number(settings.batchMaxCustomerDistanceKm ?? 2.5) * 1000;

    const rows = await this.locationRepository.queryNearbyEligibleDrivers({
      candidateIds,
      longitude,
      latitude,
      allowedVehicleTypes,
      requireActiveShift,
      maxActiveOrders,
      maxVendorMeters,
      maxCustomerMeters,
      activeOrderStatuses: DRIVER_ACTIVE_ORDER_STATUSES,
      dropoffLocation,
    });

    const eligibleDriverIds = new Set(rows.map((r) => r.id));
    const nonEligibleIds = candidateIds.filter(
      (id) => !eligibleDriverIds.has(id),
    );

    // Lazy sweep: prune drivers in Redis who are truly no longer offerable
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

    const valid = await this.locationRepository.findEligibleGeoPoolDriverIds(
      members,
      GEO_POOL_ACTIVE_DRIVER_STATUSES,
      { chunkSize: 500, requireApproved: true },
    );

    const stale = members.filter((id) => !valid.has(id));
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
