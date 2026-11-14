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
}

export interface DriverShareContext {
  isStacked?: boolean;
  isMultiVendor?: boolean;
}

export interface DriverFeeEarningsContext extends DriverShareContext {
  driverTier?: string | null;
}

export interface DriverDistanceEarningsParams extends DriverFeeEarningsContext {
  distanceKm: number;
  perKmOverride?: number | null;
  prefetchedSettings?: any;
  isStandardOrder?: boolean;
  vehicleType?: string | null;
}

/**
 * Single source of truth for driver share and net driver delivery earnings
 * across order projections, dispatch candidate estimation, and settlement.
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

  calculateDriverEarningsForFee(
    fee: number,
    settings: DriverCommissionSettings | null | undefined,
    context: DriverFeeEarningsContext = {},
  ): number {
    const share = this.computeDriverShare(settings, context);
    let adjustedFee = Number(fee ?? 0);
    if (context.driverTier === 'BRONZE') {
      adjustedFee = Math.max(0, adjustedFee - 2);
    }
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
    });
  }
}
