import { Injectable } from '@nestjs/common';
import { PlatformSetting } from '@prisma/client';
import {
  centsToDecimalEgp,
  centsToWholeEgp,
  toMoneyCents,
} from '../../common/orders/money.helper';

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
  MINIBUS: {
    perKmKey: 'pricePerKmMinibus',
    minFeeKey: 'minDeliveryFeeMinibus',
    maxFeeKey: 'maxDeliveryFeeMinibus',
  },
  TUK_TUK: {
    perKmKey: 'pricePerKmTukTuk',
    minFeeKey: 'minDeliveryFeeTukTuk',
    maxFeeKey: 'maxDeliveryFeeTukTuk',
  },
  MOTOR_TRICYCLE: {
    perKmKey: 'pricePerKmMotorTricycle',
    minFeeKey: 'minDeliveryFeeMotorTricycle',
    maxFeeKey: 'maxDeliveryFeeMotorTricycle',
  },
  QUARTER_TRUCK: {
    perKmKey: 'pricePerKmQuarterTruck',
    minFeeKey: 'minDeliveryFeeQuarterTruck',
    maxFeeKey: 'maxDeliveryFeeQuarterTruck',
  },
  HALF_TRUCK: {
    perKmKey: 'pricePerKmHalfTruck',
    minFeeKey: 'minDeliveryFeeHalfTruck',
    maxFeeKey: 'maxDeliveryFeeHalfTruck',
  },
};

export interface DeliveryFeeCalculationInput {
  distanceKm: number;
  zoneBaseDeliveryFeeOverride?: number | null;
  perKmOverride?: number | null;
  isStandardOrder?: boolean;
  vehicleType?: string | null;
  /**
   * Whether to include the fixed per-order `goldTierBonusPerOrder` surcharge.
   * Defaults to `true` for standalone order fee calculation; multi-stop group
   * builders pass `false` so the per-order surcharge is applied strictly once
   * per order rather than once per stop or once per delivery group.
   */
  includeGoldSurcharge?: boolean;
}

export interface CustomerDeliveryFeeBreakdown {
  baseFee: number;
  goldSurcharge: number;
  totalFee: number;
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

  resolveGoldSurchargePerOrder(
    settings?: Pick<PlatformSetting, 'goldTierBonusPerOrder'> | null,
  ): number {
    const cents = Math.max(0, toMoneyCents(settings?.goldTierBonusPerOrder ?? 0));
    return centsToDecimalEgp(cents);
  }

  calculateDeliveryFee(
    settings: PlatformSetting,
    input: DeliveryFeeCalculationInput,
  ): number {
    const {
      distanceKm,
      zoneBaseDeliveryFeeOverride,
      perKmOverride,
      vehicleType,
      includeGoldSurcharge = true,
    } = input;

    const minOrderKm = Number(settings.minOrderKm);
    const minFixedPrice = Number(settings.minDistanceFixedPrice);

    // Zone override takes precedence over global base fee
    const baseFee =
      zoneBaseDeliveryFeeOverride != null
        ? Number(zoneBaseDeliveryFeeOverride)
        : Number(settings.baseDeliveryFee);

    const perKm =
      perKmOverride != null
        ? Number(perKmOverride)
        : Number(settings.pricePerKm);

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

    const baseCents = toMoneyCents(fee);
    if (!includeGoldSurcharge) {
      return centsToDecimalEgp(baseCents);
    }

    const goldSurchargeCents = Math.max(
      0,
      toMoneyCents((settings as { goldTierBonusPerOrder?: number | null })?.goldTierBonusPerOrder ?? 0),
    );
    return centsToDecimalEgp(baseCents + goldSurchargeCents);
  }

  /**
   * Computes integer-EGP delivery fee breakdown for checkout/order creation so
   * `baseFee + goldSurcharge === totalFee` strictly holds in DB integer columns.
   */
  calculateCustomerDeliveryBreakdown(
    settings: PlatformSetting,
    input: Omit<DeliveryFeeCalculationInput, 'includeGoldSurcharge'>,
  ): CustomerDeliveryFeeBreakdown {
    const rawBase = this.calculateDeliveryFee(settings, {
      ...input,
      includeGoldSurcharge: false,
    });
    const baseFee = Math.max(0, centsToWholeEgp(toMoneyCents(rawBase)));
    const rawGoldSurchargeCents = Math.max(
      0,
      toMoneyCents((settings as { goldTierBonusPerOrder?: number | null })?.goldTierBonusPerOrder ?? 0),
    );
    const totalFee = Math.max(
      baseFee,
      centsToWholeEgp(toMoneyCents(baseFee) + rawGoldSurchargeCents),
    );
    return {
      baseFee,
      goldSurcharge: Math.max(0, totalFee - baseFee),
      totalFee,
    };
  }

  /**
   * Option 1: Calculates delivery fee for a delivery group's stops.
   * - Single-stop trip (single store or split route): standard distance fee.
   * - Multi-stop trip (2+ stores sharing 1 driver): sum of individual distance
   *   fees discounted by multiVendorDeliveryDiscountPercent, floored at minDeliveryFee.
   * - Optional `includeGoldSurcharge` defaults to `false` so multi-group orders add
   *   `goldTierBonusPerOrder` once at the order level rather than once per stop/group.
   */
  calculateGroupDeliveryFee(
    settings: PlatformSetting,
    stopsDistancesKm: number[],
    zoneBaseDeliveryFeeOverride?: number | null,
    options?: { includeGoldSurcharge?: boolean },
  ): number {
    if (stopsDistancesKm.length === 0) {
      return 0;
    }
    const minFee = Number(settings.minDeliveryFee ?? 15);
    const goldSurchargeCents = options?.includeGoldSurcharge
      ? Math.max(
          0,
          toMoneyCents((settings as { goldTierBonusPerOrder?: number | null })?.goldTierBonusPerOrder ?? 0),
        )
      : 0;

    if (stopsDistancesKm.length === 1) {
      const dist = stopsDistancesKm[0] ?? 0;
      const base = this.calculateDeliveryFee(settings, {
        distanceKm: dist,
        zoneBaseDeliveryFeeOverride,
        isStandardOrder: true,
        includeGoldSurcharge: false,
      });
      const flooredBase = Math.max(minFee, centsToWholeEgp(toMoneyCents(base)));
      return centsToWholeEgp(toMoneyCents(flooredBase) + goldSurchargeCents);
    }

    const discountPercent = Number(
      settings.multiVendorDeliveryDiscountPercent ?? 20,
    );
    const discountMultiplier =
      Math.max(0, Math.min(100, discountPercent)) / 100;

    let rawSumCents = 0;
    for (const dist of stopsDistancesKm) {
      const fee = this.calculateDeliveryFee(settings, {
        distanceKm: dist,
        zoneBaseDeliveryFeeOverride,
        isStandardOrder: true,
        includeGoldSurcharge: false,
      });
      rawSumCents += toMoneyCents(fee);
    }

    const discountedBase = Math.max(
      minFee,
      centsToWholeEgp(
        Math.round(rawSumCents * (1 - discountMultiplier)),
      ),
    );
    return centsToWholeEgp(toMoneyCents(discountedBase) + goldSurchargeCents);
  }
}
