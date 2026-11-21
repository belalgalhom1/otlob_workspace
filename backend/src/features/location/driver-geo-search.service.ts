import { Injectable, Logger } from '@nestjs/common';
import { DriverStatus, DriverTier, OrderType, VehicleType } from '@prisma/client';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from './location.repository';

const GEO_POOL_ACTIVE_DRIVER_STATUSES: readonly string[] = [
  DriverStatus.ONLINE,
  DriverStatus.ON_DELIVERY,
];

const MAX_DISPATCH_CANDIDATES = 20;

export const STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES: readonly VehicleType[] = [
  VehicleType.MOTORCYCLE,
  VehicleType.BICYCLE,
];

const VALID_VEHICLE_TYPES: ReadonlySet<string> = new Set(
  Object.values(VehicleType),
);

export interface NearbyDriverMatch {
  id: string;
  userId: string;
  tier?: string;
  vehicleType?: string | null;
  distanceKm: number;
  activeShiftId: string | null;
  isOnDelivery?: boolean;
}

export interface VehicleAvailabilitySettings {
  allowBicycle: boolean;
  allowMotorcycle: boolean;
  allowCar: boolean;
  allowVan: boolean;
  allowTruck: boolean;
  allowMotorTricycle: boolean;
  maxKmForBicycle?: number | null;
}

/**
 * Verifies that a driver's registered vehicle type is a recognized, valid enum value.
 */
export function isValidRegisteredVehicleType(
  vehicleType: unknown,
): vehicleType is VehicleType {
  return (
    typeof vehicleType === 'string' && VALID_VEHICLE_TYPES.has(vehicleType)
  );
}

/**
 * Verifies that a registered vehicle type is both valid and enabled/active in platform settings.
 */
export function isVehicleTypeActiveInSettings(
  vehicleType: unknown,
  settings: VehicleAvailabilitySettings,
): boolean {
  if (!isValidRegisteredVehicleType(vehicleType)) return false;
  switch (vehicleType) {
    case VehicleType.BICYCLE:
      return Boolean(settings.allowBicycle);
    case VehicleType.MOTORCYCLE:
      return Boolean(settings.allowMotorcycle);
    case VehicleType.CAR:
      return Boolean(settings.allowCar);
    case VehicleType.VAN:
      return Boolean(settings.allowVan);
    case VehicleType.TRUCK:
      return Boolean(settings.allowTruck);
    case VehicleType.MOTOR_TRICYCLE:
      return Boolean(settings.allowMotorTricycle);
    default:
      return false;
  }
}

/**
 * Resolves eligible vehicle types for a trip/order based on order type,
 * platform settings, and maximum bicycle distance constraints.
 *
 * STANDARD orders are strictly restricted to active MOTORCYCLE and BICYCLE drivers;
 * CUSTOM_DELIVERY and RIDE preserve their existing vehicle eligibility rules.
 */
export function resolveAllowedVehicleTypes(
  requestedVehicleType: string | null | undefined,
  orderDistanceKm: number,
  settings: VehicleAvailabilitySettings,
  orderType?: OrderType | string | null,
): string[] {
  const maxBicycleKm = Number(settings.maxKmForBicycle ?? 5.0);

  if (orderType === OrderType.STANDARD) {
    const allowed: string[] = [];
    if (
      requestedVehicleType === VehicleType.MOTORCYCLE ||
      requestedVehicleType === VehicleType.BICYCLE
    ) {
      if (
        requestedVehicleType === VehicleType.MOTORCYCLE &&
        settings.allowMotorcycle
      ) {
        allowed.push(VehicleType.MOTORCYCLE);
      } else if (
        requestedVehicleType === VehicleType.BICYCLE &&
        settings.allowBicycle &&
        orderDistanceKm <= maxBicycleKm
      ) {
        allowed.push(VehicleType.BICYCLE);
      }
      return allowed;
    }

    if (settings.allowMotorcycle) allowed.push(VehicleType.MOTORCYCLE);
    if (settings.allowBicycle && orderDistanceKm <= maxBicycleKm) {
      allowed.push(VehicleType.BICYCLE);
    }
    return allowed;
  }

  if (requestedVehicleType) {
    return isVehicleTypeActiveInSettings(requestedVehicleType, settings)
      ? [requestedVehicleType]
      : [];
  }

  const allowed: string[] = [];
  if (settings.allowMotorcycle) allowed.push(VehicleType.MOTORCYCLE);
  if (settings.allowBicycle && orderDistanceKm <= maxBicycleKm) {
    allowed.push(VehicleType.BICYCLE);
  }
  if (settings.allowCar) allowed.push(VehicleType.CAR);
  if (settings.allowVan) allowed.push(VehicleType.VAN);
  if (settings.allowTruck) allowed.push(VehicleType.TRUCK);
  if (settings.allowMotorTricycle) allowed.push(VehicleType.MOTOR_TRICYCLE);
  return allowed;
}

/**
 * Authoritative single-source-of-truth check confirming a driver's registered
 * vehicle type is valid, active, and eligible for the target order.
 */
export function isDriverVehicleEligibleForOrder(params: {
  orderType?: OrderType | string | null;
  requestedVehicleType?: string | null;
  driverVehicleType: unknown;
  orderDistanceKm: number;
  settings: VehicleAvailabilitySettings;
}): boolean {
  const {
    orderType,
    requestedVehicleType,
    driverVehicleType,
    orderDistanceKm,
    settings,
  } = params;
  if (!isValidRegisteredVehicleType(driverVehicleType)) {
    return false;
  }
  if (
    orderType === OrderType.STANDARD &&
    !STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES.includes(driverVehicleType)
  ) {
    return false;
  }
  const allowed = resolveAllowedVehicleTypes(
    requestedVehicleType,
    orderDistanceKm,
    settings,
    orderType,
  );
  return allowed.includes(driverVehicleType);
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
    if (allowedVehicleTypes.length === 0) return [];

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
