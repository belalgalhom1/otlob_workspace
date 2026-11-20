import { Injectable, Optional } from '@nestjs/common';
import { PlatformSettingsService } from '../../features/platform-settings/platform-settings.service';

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
  goldTierBonusPerKm?: number | null;
  silverTierBonusPerKm?: number | null;
  bronzeTierBonusPerKm?: number | null;
}

export interface DriverShareContext {
  isStacked?: boolean;
  isMultiVendor?: boolean;
}

export interface DriverFeeEarningsContext extends DriverShareContext {
  driverTier?: string | null;
  distanceKm?: number | null;
  isStandardOrder?: boolean;
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

  /**
   * Mirrors settlement tier adjustments: when shifts are enabled on STANDARD
   * orders, customer delivery fees include `goldTierBonusPerKm`; SILVER/BRONZE
   * drivers receive their tier's per-km bonus rate instead, plus the -2 EGP
   * Bronze adjustment.
   */
  adjustPrimaryFeeForTier(
    fee: number,
    settings: DriverCommissionSettings | null | undefined,
    context: {
      driverTier?: string | null;
      distanceKm?: number | null;
      isStandardOrder?: boolean;
    } = {},
  ): number {
    const baseFee = Number(fee ?? 0);
    const goldBonus = Number(settings?.goldTierBonusPerKm ?? 0);
    const silverBonus = Number(settings?.silverTierBonusPerKm ?? 0);
    const bronzeBonus = Number(settings?.bronzeTierBonusPerKm ?? 0);

    const tier = context.driverTier;
    const tierBonus =
      tier === 'SILVER'
        ? silverBonus
        : tier === 'BRONZE'
          ? bronzeBonus
          : goldBonus;

    const routeKm = Number(context.distanceKm ?? 0);
    const tierDiffPerKm = goldBonus - tierBonus;

    let adjustedFee =
      settings?.driverShiftsEnabled &&
      context.isStandardOrder === true &&
      tierDiffPerKm > 0 &&
      routeKm > 0
        ? Math.max(0, baseFee - tierDiffPerKm * routeKm)
        : baseFee;

    if (tier === 'BRONZE') {
      adjustedFee = Math.max(0, adjustedFee - 2);
    }
    return adjustedFee;
  }

  calculateDriverEarningsForFee(
    fee: number,
    settings: DriverCommissionSettings | null | undefined,
    context: DriverFeeEarningsContext = {},
  ): number {
    const share = this.computeDriverShare(settings, context);
    const adjustedFee = this.adjustPrimaryFeeForTier(fee, settings, {
      driverTier: context.driverTier,
      distanceKm: context.distanceKm,
      isStandardOrder: context.isStandardOrder,
    });
    return Math.max(0, Math.round(adjustedFee * share));
  }

  async calculateEstimatedEarningsFromDistance(
    params: DriverDistanceEarningsParams,
  ): Promise<number> {
    if (!this.platformSettings) {
      throw new Error(
        'PlatformSettingsService is required to compute distance delivery fee',
      );
    }

    const deliveryFee = await this.platformSettings.calculateDeliveryFee(
      params.distanceKm,
      null,
      params.perKmOverride,
      params.isStandardOrder ?? true,
      params.prefetchedSettings,
      params.vehicleType,
    );
    const settings =
      params.prefetchedSettings ?? (await this.platformSettings.getSettings());

    return this.calculateDriverEarningsForFee(deliveryFee, settings, {
      isStacked: params.isStacked,
      isMultiVendor: params.isMultiVendor,
      driverTier: params.driverTier,
      distanceKm: params.distanceKm,
      isStandardOrder: params.isStandardOrder ?? true,
    });
  }
}
