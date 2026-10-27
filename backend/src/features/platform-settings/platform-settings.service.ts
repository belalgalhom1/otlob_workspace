import { Injectable, Logger, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSetting, Prisma } from '@prisma/client';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { EVENTS } from '../../common/events/event-names';
import {
  UpdatePlatformSettingsDto,
  AppVersionCheckDto,
} from './dto/platform-settings.dto';
import { PlatformSettingErrors } from '../../common/constants/response.constants';

// Semantic version compare: returns true if `current` satisfies `minimum`
function semverGte(current: string, minimum: string): boolean {
  const parse = (v: string) =>
    v
      .replace(/^v/, '')
      .split('.')
      .map((n) => parseInt(n, 10) || 0);

  const [cMaj, cMin, cPat] = parse(current);
  const [mMaj, mMin, mPat] = parse(minimum);

  if (cMaj !== mMaj) return cMaj > mMaj;
  if (cMin !== mMin) return cMin > mMin;
  return cPat >= mPat;
}

@Injectable()
export class PlatformSettingsService {
  private readonly logger = new Logger(PlatformSettingsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly eventEmitter: EventEmitter2,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {}

  private emitSettingsUpdated() {
    this.eventEmitter.emit(EVENTS.SETTINGS_UPDATED);
  }

  // ─── Get settings ─────────────────────────────────────────────────────────
  // Seeds a default row if it has never been written (first boot).

  async getSettings() {
    const cached = await this.cacheManager.get('platform_settings');
    if (cached) return cached as PlatformSetting;

    let settings = await this.prisma.platformSetting.findUnique({
      where: { id: 'default' },
    });

    if (!settings) {
      this.logger.log('Platform settings not found — seeding defaults');
      try {
        settings = await this.prisma.platformSetting.create({
          data: { id: 'default' },
        });
      } catch (error: any) {
        if (error.code === 'P2002') {
          settings = await this.prisma.platformSetting.findUnique({
            where: { id: 'default' },
          });
          if (!settings)
            throw new Error(PlatformSettingErrors.CONCURRENT_CREATION_FAILED);
        } else {
          throw error;
        }
      }
    }

    await this.cacheManager.set('platform_settings', settings, 3600000);
    return settings;
  }

  // ─── Public projection — safe subset for unauthenticated callers ──────────
  // Exposes only what mobile/web clients need (maintenance flag, app versions,
  // support contacts, legal URLs). Hides financial/operational config.

  async getPublicSettings() {
    const s = await this.getSettings();

    return {
      isMaintenanceMode: s.isMaintenanceMode,
      android: {
        minVersion: s.androidMinVersion,
        latestVersion: s.androidLatestVersion,
        forceUpdate: s.androidForceUpdate,
        storeUrl: s.androidStoreUrl,
      },
      ios: {
        minVersion: s.iosMinVersion,
        latestVersion: s.iosLatestVersion,
        forceUpdate: s.iosForceUpdate,
        storeUrl: s.iosStoreUrl,
      },
      support: {
        email: s.supportEmail,
        phone: s.supportPhone,
        whatsapp: s.supportWhatsapp,
      },
      legal: {
        termsUrl: s.termsUrl,
        privacyUrl: s.privacyUrl,
      },
      currency: s.currency,
      minOrderAmount: s.minOrderAmount,
      defaultTaxRate: s.defaultTaxRate,
      baseDeliveryFee: s.baseDeliveryFee,
      extraVendorDeliveryFee: s.extraVendorDeliveryFee,
      customOrderPlatformFee: s.customOrderPlatformFee,
      pricePerKm: s.pricePerKm,
      pricePerKmBicycle: s.pricePerKmBicycle,
      pricePerKmMotorcycle: s.pricePerKmMotorcycle,
      pricePerKmCar: s.pricePerKmCar,
      pricePerKmVan: s.pricePerKmVan,
      pricePerKmTruck: s.pricePerKmTruck,
      pricePerKmMotorTricycle: s.pricePerKmMotorTricycle,
      maxDeliveryFee: s.maxDeliveryFee,
      minDeliveryFeeBicycle: s.minDeliveryFeeBicycle,
      maxDeliveryFeeBicycle: s.maxDeliveryFeeBicycle,
      minDeliveryFeeMotorcycle: s.minDeliveryFeeMotorcycle,
      maxDeliveryFeeMotorcycle: s.maxDeliveryFeeMotorcycle,
      minDeliveryFeeCar: s.minDeliveryFeeCar,
      maxDeliveryFeeCar: s.maxDeliveryFeeCar,
      minDeliveryFeeVan: s.minDeliveryFeeVan,
      maxDeliveryFeeVan: s.maxDeliveryFeeVan,
      minDeliveryFeeTruck: s.minDeliveryFeeTruck,
      maxDeliveryFeeTruck: s.maxDeliveryFeeTruck,
      minDeliveryFeeMotorTricycle: s.minDeliveryFeeMotorTricycle,
      maxDeliveryFeeMotorTricycle: s.maxDeliveryFeeMotorTricycle,
      coinValue: s.coinValue,
      amountSpentPerCoin: s.amountSpentPerCoin,
      minCoinsToUse: s.minCoinsToUse,
      allowBicycle: s.allowBicycle,
      allowMotorcycle: s.allowMotorcycle,
      allowCar: s.allowCar,
      allowVan: s.allowVan,
      allowTruck: s.allowTruck,
      allowMotorTricycle: s.allowMotorTricycle,
      maxKmForBicycle: s.maxKmForBicycle,
      maxDeliveryRadiusKm: s.maxDeliveryRadiusKm,
      minOrderKm: s.minOrderKm,
      minDistanceFixedPrice: s.minDistanceFixedPrice,
      homeCoverUrl: s.homeCoverUrl,
      motorcycleIconUrl: s.motorcycleIconUrl,
      carIconUrl: s.carIconUrl,
      bicycleIconUrl: s.bicycleIconUrl,
      motorTricycleIconUrl: s.motorTricycleIconUrl,
      vanIconUrl: s.vanIconUrl,
      truckIconUrl: s.truckIconUrl,
      deliveryBannerIconUrl: s.deliveryBannerIconUrl,
      driverBonusActive: s.driverBonusActive,
      driverBonusAmount: s.driverBonusAmount,
      driverBonusStartDate: s.driverBonusStartDate,
      driverBonusEndDate: s.driverBonusEndDate,
      driverBonusPaidByCustomer: s.driverBonusPaidByCustomer,
      driverShiftsEnabled: s.driverShiftsEnabled,
    };
  }

  // ─── Update settings ──────────────────────────────────────────────────────
  // Upserts: always updates the single 'default' row.

  async updateSettings(dto: UpdatePlatformSettingsDto) {
    const data: Prisma.PlatformSettingUpdateInput = {};

    // Only include fields that were explicitly provided
    const fields: (keyof UpdatePlatformSettingsDto)[] = [
      'currency',
      'defaultCommissionRate',
      'deliveryCommissionRate',
      'driverManagerCommissionRate',
      'defaultTaxRate',
      'minOrderAmount',
      'baseDeliveryFee',
      'extraVendorDeliveryFee',
      'pricePerKm',
      'pricePerKmBicycle',
      'pricePerKmMotorcycle',
      'pricePerKmCar',
      'pricePerKmVan',
      'pricePerKmTruck',
      'pricePerKmMotorTricycle',
      'maxDeliveryFee',
      'minDeliveryFee',
      'minDeliveryFeeBicycle',
      'maxDeliveryFeeBicycle',
      'minDeliveryFeeMotorcycle',
      'maxDeliveryFeeMotorcycle',
      'minDeliveryFeeCar',
      'maxDeliveryFeeCar',
      'minDeliveryFeeVan',
      'maxDeliveryFeeVan',
      'minDeliveryFeeTruck',
      'maxDeliveryFeeTruck',
      'minDeliveryFeeMotorTricycle',
      'maxDeliveryFeeMotorTricycle',
      'allowBicycle',
      'allowMotorcycle',
      'allowCar',
      'allowVan',
      'allowTruck',
      'allowMotorTricycle',
      'minOrderKm',
      'minDistanceFixedPrice',
      'maxDeliveryRadiusKm',
      'driverSearchRadiusKm',
      'driverSearchRadiusStepKm',
      'driverSearchRadiusMaxKm',
      'driverSearchMaxAttempts',
      'driverSearchGeoCandidateLimit',
      'driverLocationFreshnessTtlSecs',
      'driverLocationPrecisionMeters',
      'groupingMaxBranchDistanceKm',
      'groupingMaxVendorCustomerDistanceKm',
      'customOrderPlatformFee',
      'autoCancelPendingMins',
      'mobileWalletTimeoutMins',
      'driverAcceptTimeoutSecs',
    'assistDecisionTimeoutSecs',
    'maxNegativeDriverBalance',
      'isMaintenanceMode',
      'androidMinVersion',
      'androidLatestVersion',
      'androidForceUpdate',
      'androidStoreUrl',
      'iosMinVersion',
      'iosLatestVersion',
      'iosForceUpdate',
      'iosStoreUrl',
      'supportEmail',
      'supportPhone',
      'supportWhatsapp',
      'termsUrl',
      'privacyUrl',
      'retentionOrdersDays',
      'retentionArchivedChatsDays',
      'retentionNotificationsDays',
      'retentionExpiredSessionsDays',
      'retentionAuditLogsDays',
      'retentionAbandonedCartsDays',
      'retentionPaymentReceiptsDays',
      'retentionShiftStartPhotosDays',
      'retentionPickupPhotosDays',
      'retentionDeliveryPhotosDays',
      'retentionWalletTransactionsDays',
      'retentionStatisticsDays',
      'maxKmForBicycle',
      'maxDispatchBatchSize',
      'maxActiveOrdersPerDriver',
      'coinValue',
      'amountSpentPerCoin',
      'minCoinsToUse',
      'driverBonusActive',
      'driverBonusAmount',
      'driverBonusStartDate',
      'driverBonusEndDate',
      'driverBonusPaidByCustomer',
      'highValueOrderThreshold',
      'highValueUpfrontRate',
      'driverShiftsEnabled',
      'breaksEnabled',
      'maxActiveOrdersPerCustomer',
      'requirePriorDeliveryForMultipleOrders',
      'maxOtpAttempts',
      'otpExpirySeconds',
      'bronzeTierBonusPerKm',
      'silverTierBonusPerKm',
      'goldTierBonusPerKm',
      'driverSettlementOrderThreshold',
      'maxBreakMinutesPerShift',
      'maxBreaksPerShift',
      'maxSingleBreakMinutes',
      'pendingBreakExpiryMins',
    ];

    for (const field of fields) {
      if (dto[field] !== undefined) {
        data[field] = dto[field];
      }
    }

    const settings = await this.prisma.platformSetting.upsert({
      where: { id: 'default' },
      create: { id: 'default', ...(data as any) },
      update: data,
    });

    await this.cacheManager.del('platform_settings');

    this.emitSettingsUpdated();

    return settings;
  }

  // ─── App version check ────────────────────────────────────────────────────
  // Mobile clients call this on startup to determine if they should force-update.

  async checkAppVersion(dto: AppVersionCheckDto) {
    const s = await this.getSettings();

    const isAndroid = dto.platform === 'android';
    const minVersion = isAndroid ? s.androidMinVersion : s.iosMinVersion;
    const latestVersion = isAndroid
      ? s.androidLatestVersion
      : s.iosLatestVersion;
    const forceUpdate = isAndroid ? s.androidForceUpdate : s.iosForceUpdate;
    const storeUrl = isAndroid ? s.androidStoreUrl : s.iosStoreUrl;

    const meetsMinimum = semverGte(dto.version, minVersion);
    const isLatest = semverGte(dto.version, latestVersion);

    return {
      platform: dto.platform,
      currentVersion: dto.version,
      minVersion,
      latestVersion,
      meetsMinimum,
      isLatest,
      // forceUpdate flag is only relevant if the version is below minimum
      mustUpdate: !meetsMinimum && forceUpdate,
      shouldUpdate: !isLatest,
      storeUrl,
      isMaintenanceMode: s.isMaintenanceMode,
    };
  }

  // ─── Delivery fee calculation helper (used by checkout) ───────────────────
  // Returns computed delivery fee based on distance and zone overrides.

  async calculateDeliveryFee(
    distanceKm: number,
    zoneBaseDeliveryFeeOverride?: number | null,
    perKmOverride?: number | null,
    isStandardOrder: boolean = true,
    prefetchedSettings?: PlatformSetting,
    vehicleType?: string | null,
  ): Promise<number> {
    const s = prefetchedSettings ?? (await this.getSettings());

    const minOrderKm = Number(s.minOrderKm);
    const minFixedPrice = Number(s.minDistanceFixedPrice);

    // Zone override takes precedence over global base fee
    const baseFee =
      zoneBaseDeliveryFeeOverride != null
        ? Number(zoneBaseDeliveryFeeOverride)
        : Number(s.baseDeliveryFee);

    let perKm =
      perKmOverride != null ? Number(perKmOverride) : Number(s.pricePerKm);

    if (s.driverShiftsEnabled && isStandardOrder) {
      perKm += Number(s.goldTierBonusPerKm ?? 0);
    }

    let fee =
      minOrderKm > 0 && distanceKm < minOrderKm
        ? minFixedPrice
        : baseFee + distanceKm * perKm;

    // Vehicle-specific min and max fee overrides
    let vehicleMinFee = 0;
    let vehicleMaxFee = 0;
    if (vehicleType) {
      const v = vehicleType.toUpperCase();
      if (v === 'BICYCLE') {
        vehicleMinFee = Number(s.minDeliveryFeeBicycle);
        vehicleMaxFee = Number(s.maxDeliveryFeeBicycle);
      } else if (v === 'MOTORCYCLE') {
        vehicleMinFee = Number(s.minDeliveryFeeMotorcycle);
        vehicleMaxFee = Number(s.maxDeliveryFeeMotorcycle);
      } else if (v === 'CAR') {
        vehicleMinFee = Number(s.minDeliveryFeeCar);
        vehicleMaxFee = Number(s.maxDeliveryFeeCar);
      } else if (v === 'VAN') {
        vehicleMinFee = Number(s.minDeliveryFeeVan);
        vehicleMaxFee = Number(s.maxDeliveryFeeVan);
      } else if (v === 'TRUCK') {
        vehicleMinFee = Number(s.minDeliveryFeeTruck);
        vehicleMaxFee = Number(s.maxDeliveryFeeTruck);
      } else if (v === 'MOTOR_TRICYCLE') {
        vehicleMinFee = Number(s.minDeliveryFeeMotorTricycle);
        vehicleMaxFee = Number(s.maxDeliveryFeeMotorTricycle);
      }
    }

    if (vehicleMinFee > 0 && fee < vehicleMinFee) {
      fee = vehicleMinFee;
    }

    const maxFee = vehicleMaxFee > 0 ? vehicleMaxFee : Number(s.maxDeliveryFee);
    if (maxFee > 0 && fee > maxFee) {
      fee = maxFee;
    }

    // Global customer-facing floor (EGP). Applied last so a configured
    // per-vehicle minimum still wins over it, and so a cheap zone override or
    // sub-minimum `minDistanceFixedPrice` can never drop a delivery below the
    // platform minimum. 0 disables the floor.
    const globalMinFee = Number(s.minDeliveryFee ?? 0);
    if (globalMinFee > 0 && fee < globalMinFee) {
      fee = globalMinFee;
    }

    // Round to 2 decimal places
    return Math.round(fee * 100) / 100;
  }

  async getVehiclePerKm(vehicleType: string): Promise<number | null> {
    const s = await this.getSettings();
    switch (vehicleType) {
      case 'BICYCLE':
        return Number(s.pricePerKmBicycle);
      case 'MOTORCYCLE':
        return Number(s.pricePerKmMotorcycle);
      case 'CAR':
        return Number(s.pricePerKmCar);
      case 'VAN':
        return Number(s.pricePerKmVan);
      case 'TRUCK':
        return Number(s.pricePerKmTruck);
      case 'MOTOR_TRICYCLE':
        return Number(s.pricePerKmMotorTricycle);
      default:
        return null;
    }
  }

  // ─── Image Uploads ────────────────────────────────────────────────────────

  async uploadHomeCover(file: Express.Multer.File) {
    const s = await this.getSettings();
    if (s.homeCoverUrl) {
      await this.storage.delete(s.homeCoverUrl);
    }
    const url = await this.storage.upload(file, 'app/customization');
    await this.prisma.platformSetting.update({
      where: { id: 'default' },
      data: { homeCoverUrl: url },
    });
    await this.cacheManager.del('platform_settings');
    this.emitSettingsUpdated();
    return { url };
  }

  async uploadMotorcycleIcon(file: Express.Multer.File) {
    return this.uploadVehicleIcon('motorcycle', file);
  }

  async uploadCarIcon(file: Express.Multer.File) {
    return this.uploadVehicleIcon('car', file);
  }

  async uploadVehicleIcon(vehicleType: string, file: Express.Multer.File) {
    const column = {
      bicycle: 'bicycleIconUrl',
      motorcycle: 'motorcycleIconUrl',
      motor_tricycle: 'motorTricycleIconUrl',
      car: 'carIconUrl',
      van: 'vanIconUrl',
      truck: 'truckIconUrl',
    }[vehicleType];
    if (!column) {
      throw new Error(`Unknown vehicle type: ${vehicleType}`);
    }
    const s = await this.getSettings();
    const oldUrl = (s as unknown as Record<string, string | null>)[column];
    if (oldUrl) {
      await this.storage.delete(oldUrl);
    }
    const url = await this.storage.upload(file, 'app/customization');
    await this.prisma.platformSetting.update({
      where: { id: 'default' },
      data: { [column]: url },
    });
    await this.cacheManager.del('platform_settings');
    this.emitSettingsUpdated();
    return { url };
  }

  async uploadDeliveryBannerIcon(file: Express.Multer.File) {
    const s = await this.getSettings();
    if (s.deliveryBannerIconUrl) {
      await this.storage.delete(s.deliveryBannerIconUrl);
    }
    const url = await this.storage.upload(file, 'app/customization');
    await this.prisma.platformSetting.update({
      where: { id: 'default' },
      data: { deliveryBannerIconUrl: url },
    });
    await this.cacheManager.del('platform_settings');
    this.emitSettingsUpdated();
    return { url };
  }
}
