import { Injectable, Optional } from '@nestjs/common';
import { PlatformSettingsService } from '../../features/platform-settings/platform-settings.service';
import {
  centsToDecimalEgp,
  centsToWholeEgp,
  multiplyMoneyRatioToWholeEgp,
  toMoneyCents,
} from './money.helper';

export interface DriverCommissionSettings {
  deliveryCommissionRate?: number | null;
  driverManagerCommissionRate?: number | null;
  stackedOrderDriverPercentage?: number | null;
  batchedDeliveryCommissionRate?: number | null;
  batchedDriverManagerCommissionRate?: number | null;
  multiVendorDeliveryCommissionRate?: number | null;
  multiVendorDriverManagerCommissionRate?: number | null;
  multiVendorDriverPercentage?: number | null;
  driverShiftsEnabled?: boolean | null;
  goldTierBonusPerOrder?: number | null;
  bronzeTierDeductionAmount?: number | null;
  bronzeSupervisorDeductionAmount?: number | null;
}

export interface DriverShareContext {
  isStacked?: boolean;
  isMultiVendor?: boolean;
}

export interface DriverFeeEarningsContext extends DriverShareContext {
  driverTier?: string | null;
  distanceKm?: number | null;
  isStandardOrder?: boolean;
  /**
   * Fixed per-order Gold surcharge already included inside `fee`.
   * Stripped before applying commission percentages so supervisors,
   * assisting drivers, and Silver/Bronze drivers never receive a share of it,
   * and Gold drivers receive 100% of it as a separate bonus.
   */
  goldSurcharge?: number | null;
  /**
   * Controls whether the fixed Bronze driver deduction is subtracted in `netEarnings`.
   * Defaults to true.
   */
  applyBronzeDeduction?: boolean;
}

export interface DriverEarningsBreakdown {
  baseDeliveryFee: number;
  adjustedBaseFee: number;
  driverShareRatio: number;
  baseEarnings: number;
  goldSurcharge: number;
  goldBonus: number;
  platformRetainedGoldSurcharge: number;
  bronzeDeduction: number;
  netEarnings: number;
}

export interface DriverDistanceEarningsParams extends DriverFeeEarningsContext {
  distanceKm: number;
  perKmOverride?: number | null;
  prefetchedSettings?: any;
  isStandardOrder?: boolean;
  vehicleType?: string | null;
}

/**
 * Single source of truth for driver share, tier fee adjustments, and net driver
 * delivery earnings across order projections, dispatch estimation, and settlement.
 */
@Injectable()
export class OrderEarningsCalculator {
  constructor(
    @Optional() private readonly platformSettings?: PlatformSettingsService,
  ) {}

  computeDriverShare(
    settings: DriverCommissionSettings | null | undefined,
    context: DriverShareContext = {},
  ): number {
    if (context.isStacked) {
      return Math.max(
        0,
        Number(settings?.stackedOrderDriverPercentage ?? 50) / 100,
      );
    }

    if (context.isMultiVendor) {
      if (settings?.multiVendorDriverPercentage != null) {
        return Math.max(0, Number(settings.multiVendorDriverPercentage) / 100);
      }
      const platformShare =
        Number(
          settings?.multiVendorDeliveryCommissionRate ??
            settings?.deliveryCommissionRate ??
            20,
        ) / 100;
      const supervisorShare =
        Number(
          settings?.multiVendorDriverManagerCommissionRate ??
            settings?.driverManagerCommissionRate ??
            10,
        ) / 100;
      return Math.max(0, 1 - platformShare - supervisorShare);
    }

    const platformShare = Number(settings?.deliveryCommissionRate ?? 20) / 100;
    const supervisorShare =
      Number(settings?.driverManagerCommissionRate ?? 10) / 100;
    return Math.max(0, 1 - platformShare - supervisorShare);
  }

  computeSupervisorShare(
    settings: DriverCommissionSettings | null | undefined,
    context: DriverShareContext = {},
  ): number {
    if (context.isStacked) {
      return Math.max(
        0,
        Number(
          settings?.batchedDriverManagerCommissionRate ??
            settings?.driverManagerCommissionRate ??
            10,
        ) / 100,
      );
    }
    if (context.isMultiVendor) {
      return Math.max(
        0,
        Number(
          settings?.multiVendorDriverManagerCommissionRate ??
            settings?.driverManagerCommissionRate ??
            10,
        ) / 100,
      );
    }
    return Math.max(0, Number(settings?.driverManagerCommissionRate ?? 10) / 100);
  }

  calculateDriverEarningsBreakdown(
    fee: number,
    settings: DriverCommissionSettings | null | undefined,
    context: DriverFeeEarningsContext = {},
  ): DriverEarningsBreakdown {
    const feeCents = Math.max(0, toMoneyCents(fee ?? 0));
    const rawSurchargeCents = Math.max(
      0,
      toMoneyCents(context.goldSurcharge ?? 0),
    );
    const effectiveSurchargeCents = Math.min(feeCents, rawSurchargeCents);
    const baseDeliveryFee = centsToDecimalEgp(
      Math.max(0, feeCents - effectiveSurchargeCents),
    );
    const goldSurcharge = centsToWholeEgp(effectiveSurchargeCents);

    const share = this.computeDriverShare(settings, context);
    const adjustedBaseFee = baseDeliveryFee;
    const baseEarnings = Math.max(
      0,
      multiplyMoneyRatioToWholeEgp(adjustedBaseFee, share),
    );

    const tier = String(context.driverTier ?? '').toUpperCase();
    const goldBonus = tier === 'GOLD' ? goldSurcharge : 0;
    const platformRetainedGoldSurcharge = tier === 'GOLD' ? 0 : goldSurcharge;

    const configuredBronzeDeduction =
      context.applyBronzeDeduction === false
        ? 0
        : Math.max(
            0,
            centsToWholeEgp(toMoneyCents(settings?.bronzeTierDeductionAmount ?? 0)),
          );
    const bronzeDeduction =
      tier === 'BRONZE'
        ? Math.min(configuredBronzeDeduction, baseEarnings)
        : 0;

    const netEarnings = Math.max(0, baseEarnings + goldBonus - bronzeDeduction);

    return {
      baseDeliveryFee,
      adjustedBaseFee,
      driverShareRatio: share,
      baseEarnings,
      goldSurcharge,
      goldBonus,
      platformRetainedGoldSurcharge,
      bronzeDeduction,
      netEarnings,
    };
  }

  calculateDriverEarningsForFee(
    fee: number,
    settings: DriverCommissionSettings | null | undefined,
    context: DriverFeeEarningsContext = {},
  ): number {
    return this.calculateDriverEarningsBreakdown(fee, settings, context)
      .netEarnings;
  }

  async calculateEstimatedEarningsFromDistance(
    params: DriverDistanceEarningsParams,
  ): Promise<number> {
    if (!this.platformSettings) {
      throw new Error(
        'PlatformSettingsService is required to compute distance delivery fee',
      );
    }

    const settings =
      params.prefetchedSettings ?? (await this.platformSettings.getSettings());

    let deliveryFee: number;
    let goldSurcharge =
      params.goldSurcharge != null
        ? Math.max(0, centsToWholeEgp(toMoneyCents(params.goldSurcharge)))
        : Math.max(
            0,
            centsToWholeEgp(toMoneyCents(settings?.goldTierBonusPerOrder ?? 0)),
          );

    if (
      typeof this.platformSettings.calculateCustomerDeliveryBreakdown ===
      'function'
    ) {
      const breakdown =
        await this.platformSettings.calculateCustomerDeliveryBreakdown(
          params.distanceKm,
          null,
          params.perKmOverride,
          params.isStandardOrder ?? true,
          settings,
          params.vehicleType,
        );
      deliveryFee = breakdown.totalFee;
      goldSurcharge = breakdown.goldSurcharge;
    } else {
      deliveryFee = await this.platformSettings.calculateDeliveryFee(
        params.distanceKm,
        null,
        params.perKmOverride,
        params.isStandardOrder ?? true,
        settings,
        params.vehicleType,
        false,
      );
      if (params.goldSurcharge == null && goldSurcharge > 0) {
        deliveryFee += goldSurcharge;
      }
    }

    return this.calculateDriverEarningsForFee(deliveryFee, settings, {
      isStacked: params.isStacked,
      isMultiVendor: params.isMultiVendor,
      driverTier: params.driverTier,
      distanceKm: params.distanceKm,
      isStandardOrder: params.isStandardOrder ?? true,
      goldSurcharge,
      applyBronzeDeduction: params.applyBronzeDeduction,
    });
  }
}
