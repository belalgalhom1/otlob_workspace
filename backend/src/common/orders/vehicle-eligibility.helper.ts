import { OrderType, VehicleType } from '@prisma/client';

export const STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES: readonly VehicleType[] = [
  VehicleType.MOTORCYCLE,
  VehicleType.BICYCLE,
];

export const RIDE_ELIGIBLE_VEHICLE_TYPES: readonly VehicleType[] = [
  VehicleType.MOTORCYCLE,
  VehicleType.CAR,
  VehicleType.MINIBUS,
  VehicleType.TUK_TUK,
];

export const CUSTOM_DELIVERY_ELIGIBLE_VEHICLE_TYPES: readonly VehicleType[] = [
  VehicleType.MOTORCYCLE,
  VehicleType.MOTOR_TRICYCLE,
  VehicleType.QUARTER_TRUCK,
  VehicleType.HALF_TRUCK,
];

const VALID_VEHICLE_TYPES: ReadonlySet<string> = new Set(
  Object.values(VehicleType),
);

export interface VehicleAvailabilitySettings {
  allowBicycle: boolean;
  allowMotorcycle: boolean;
  allowCar: boolean;
  allowMinibus: boolean;
  allowTukTuk: boolean;
  allowMotorTricycle: boolean;
  allowQuarterTruck: boolean;
  allowHalfTruck: boolean;
  maxKmForBicycle?: number | null;
}

/**
 * Normalizes a partial settings object (including test doubles) into a complete
 * VehicleAvailabilitySettings record with safe defaults.
 */
export function buildVehicleAvailabilitySettings(
  raw?: Partial<VehicleAvailabilitySettings> | null,
): VehicleAvailabilitySettings {
  return {
    allowBicycle: raw?.allowBicycle ?? true,
    allowMotorcycle: raw?.allowMotorcycle ?? true,
    allowCar: raw?.allowCar ?? true,
    allowMinibus: raw?.allowMinibus ?? true,
    allowTukTuk: raw?.allowTukTuk ?? true,
    allowMotorTricycle: raw?.allowMotorTricycle ?? true,
    allowQuarterTruck: raw?.allowQuarterTruck ?? true,
    allowHalfTruck: raw?.allowHalfTruck ?? true,
    maxKmForBicycle: raw?.maxKmForBicycle ?? 5.0,
  };
}

/**
 * Returns the canonical list of vehicle types permitted for a given service type.
 */
export function getEligibleVehicleTypesForOrderType(
  orderType?: OrderType | string | null,
): readonly VehicleType[] {
  switch (orderType) {
    case OrderType.STANDARD:
      return STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES;
    case OrderType.RIDE:
      return RIDE_ELIGIBLE_VEHICLE_TYPES;
    case OrderType.CUSTOM_DELIVERY:
      return CUSTOM_DELIVERY_ELIGIBLE_VEHICLE_TYPES;
    default:
      return Object.values(VehicleType);
  }
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
 * Verifies that a vehicle type is allowed for the specified service/order type.
 */
export function isVehicleTypeAllowedForOrderType(
  orderType: OrderType | string | null | undefined,
  vehicleType: unknown,
): vehicleType is VehicleType {
  if (!isValidRegisteredVehicleType(vehicleType)) return false;
  return getEligibleVehicleTypesForOrderType(orderType).includes(vehicleType);
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
    case VehicleType.MINIBUS:
      return Boolean(settings.allowMinibus);
    case VehicleType.TUK_TUK:
      return Boolean(settings.allowTukTuk);
    case VehicleType.MOTOR_TRICYCLE:
      return Boolean(settings.allowMotorTricycle);
    case VehicleType.QUARTER_TRUCK:
      return Boolean(settings.allowQuarterTruck);
    case VehicleType.HALF_TRUCK:
      return Boolean(settings.allowHalfTruck);
    default:
      return false;
  }
}

/**
 * Resolves eligible vehicle types for a trip/order based on order type,
 * requested vehicle type, platform settings, and maximum bicycle distance.
 *
 * - STANDARD:        active MOTORCYCLE and BICYCLE (within maxKmForBicycle)
 * - RIDE:            active MOTORCYCLE, CAR, MINIBUS, TUK_TUK (exact match when requested)
 * - CUSTOM_DELIVERY: active MOTORCYCLE, MOTOR_TRICYCLE, QUARTER_TRUCK, HALF_TRUCK (exact match when requested)
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

  if (orderType === OrderType.RIDE || orderType === OrderType.CUSTOM_DELIVERY) {
    const serviceEligible = getEligibleVehicleTypesForOrderType(orderType);
    if (requestedVehicleType) {
      return isValidRegisteredVehicleType(requestedVehicleType) &&
        serviceEligible.includes(requestedVehicleType) &&
        isVehicleTypeActiveInSettings(requestedVehicleType, settings)
        ? [requestedVehicleType]
        : [];
    }
    return serviceEligible.filter((vt) =>
      isVehicleTypeActiveInSettings(vt, settings),
    );
  }

  if (requestedVehicleType) {
    if (
      requestedVehicleType === VehicleType.BICYCLE &&
      orderDistanceKm > maxBicycleKm
    ) {
      return [];
    }
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
  if (settings.allowMinibus) allowed.push(VehicleType.MINIBUS);
  if (settings.allowTukTuk) allowed.push(VehicleType.TUK_TUK);
  if (settings.allowMotorTricycle) allowed.push(VehicleType.MOTOR_TRICYCLE);
  if (settings.allowQuarterTruck) allowed.push(VehicleType.QUARTER_TRUCK);
  if (settings.allowHalfTruck) allowed.push(VehicleType.HALF_TRUCK);
  return allowed;
}

/**
 * Authoritative single-source-of-truth check confirming a driver's registered
 * vehicle type is valid, active, allowed for the service, and matches any
 * requested vehicle type on the target order.
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
    orderType &&
    !isVehicleTypeAllowedForOrderType(orderType, driverVehicleType)
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
