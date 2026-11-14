import { Injectable } from '@nestjs/common';
import { PlatformSetting } from '@prisma/client';

interface VehicleFeeFieldKeys {
  perKmKey: keyof PlatformSetting;
  minFeeKey: keyof PlatformSetting;
  maxFeeKey: keyof PlatformSetting;
}

const VEHICLE_FEE_FIELDS: Record<string, VehicleFeeFieldKeys> = {
  BICYCLE: {
    perKmKey: 'pricePerKmBicycle',
    minFeeKey: 'minDeliveryFeeBicycle',
    maxFeeKey: 'maxDeliveryFeeBicycle',
  },
  MOTORCYCLE: {
    perKmKey: 'pricePerKmMotorcycle',
    minFeeKey: 'minDeliveryFeeMotorcycle',
    maxFeeKey: 'maxDeliveryFeeMotorcycle',
  },
  CAR: {
    perKmKey: 'pricePerKmCar',
    minFeeKey: 'minDeliveryFeeCar',
    maxFeeKey: 'maxDeliveryFeeCar',
  },
  VAN: {
    perKmKey: 'pricePerKmVan',
    minFeeKey: 'minDeliveryFeeVan',
    maxFeeKey: 'maxDeliveryFeeVan',
  },
  TRUCK: {
    perKmKey: 'pricePerKmTruck',
    minFeeKey: 'minDeliveryFeeTruck',
    maxFeeKey: 'maxDeliveryFeeTruck',
  },
  MOTOR_TRICYCLE: {
    perKmKey: 'pricePerKmMotorTricycle',
    minFeeKey: 'minDeliveryFeeMotorTricycle',
    maxFeeKey: 'maxDeliveryFeeMotorTricycle',
  },
};

export interface DeliveryFeeCalculationInput {
  distanceKm: number;
  zoneBaseDeliveryFeeOverride?: number | null;
  perKmOverride?: number | null;
  isStandardOrder?: boolean;
  vehicleType?: string | null;
}

/**
 * Pure domain calculator for delivery fees and per-vehicle per-km rates
 * derived from `PlatformSetting`.
 */
@Injectable()
export class DeliveryFeeCalculator {
  getVehiclePerKm(
    settings: PlatformSetting,
    vehicleType: string,
  ): number | null {
    const fields = VEHICLE_FEE_FIELDS[vehicleType.toUpperCase()];
    if (!fields) return null;
    return Number(settings[fields.perKmKey]);
  }

  calculateDeliveryFee(
    settings: PlatformSetting,
    input: DeliveryFeeCalculationInput,
  ): number {
    const {
      distanceKm,
      zoneBaseDeliveryFeeOverride,
      perKmOverride,
      isStandardOrder = true,
      vehicleType,
    } = input;

    const minOrderKm = Number(settings.minOrderKm);
    const minFixedPrice = Number(settings.minDistanceFixedPrice);

    // Zone override takes precedence over global base fee
    const baseFee =
      zoneBaseDeliveryFeeOverride != null
        ? Number(zoneBaseDeliveryFeeOverride)
        : Number(settings.baseDeliveryFee);

    let perKm =
      perKmOverride != null ? Number(perKmOverride) : Number(settings.pricePerKm);

    if (settings.driverShiftsEnabled && isStandardOrder) {
      perKm += Number(settings.goldTierBonusPerKm ?? 0);
    }

    let fee =
      minOrderKm > 0 && distanceKm < minOrderKm
        ? minFixedPrice
        : baseFee + distanceKm * perKm;

    // Vehicle-specific min and max fee overrides
    const vehicleFields = vehicleType
      ? VEHICLE_FEE_FIELDS[vehicleType.toUpperCase()]
      : undefined;
    const vehicleMinFee = vehicleFields
      ? Number(settings[vehicleFields.minFeeKey])
      : 0;
    const vehicleMaxFee = vehicleFields
      ? Number(settings[vehicleFields.maxFeeKey])
      : 0;

    if (vehicleMinFee > 0 && fee < vehicleMinFee) {
      fee = vehicleMinFee;
    }

    const maxFee =
      vehicleMaxFee > 0 ? vehicleMaxFee : Number(settings.maxDeliveryFee);
    if (maxFee > 0 && fee > maxFee) {
      fee = maxFee;
    }

    // Global customer-facing floor (EGP), applied last so the effective
    // minimum is max(per-vehicle minimum, platform minimum). 0 disables.
    const globalMinFee = Number(settings.minDeliveryFee ?? 0);
    if (globalMinFee > 0 && fee < globalMinFee) {
      fee = globalMinFee;
    }

    return Math.round(fee * 100) / 100;
  }
}
