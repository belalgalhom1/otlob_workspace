import {
  Injectable,
  Logger,
  Inject,
  BadRequestException,
  Optional,
} from '@nestjs/common';
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
import {
  DriverErrors,
  PlatformSettingErrors,
} from '../../common/constants/response.constants';
import { DeliveryFeeCalculator } from './delivery-fee.calculator';
import {
  CUSTOM_DELIVERY_ELIGIBLE_VEHICLE_TYPES,
  RIDE_ELIGIBLE_VEHICLE_TYPES,
  STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES,
} from '../../common/orders/vehicle-eligibility.helper';

const UPLOAD_MANAGED_SETTING_FIELDS = new Set<string>([
  'id',
  'updatedAt',
  'homeCoverUrl',
  'motorcycleIconUrl',
  'carIconUrl',
  'minibusIconUrl',
  'tukTukIconUrl',
  'bicycleIconUrl',
  'motorTricycleIconUrl',
  'quarterTruckIconUrl',
  'halfTruckIconUrl',
  'deliveryBannerIconUrl',
]);

const UPDATABLE_SETTING_FIELDS = Object.values(
  Prisma.PlatformSettingScalarFieldEnum,
).filter((field) => !UPLOAD_MANAGED_SETTING_FIELDS.has(field));

const VEHICLE_ICON_COLUMNS: Record<string, string> = {
  bicycle: 'bicycleIconUrl',
  motorcycle: 'motorcycleIconUrl',
  motor_tricycle: 'motorTricycleIconUrl',
  car: 'carIconUrl',
  minibus: 'minibusIconUrl',
  tuk_tuk: 'tukTukIconUrl',
  quarter_truck: 'quarterTruckIconUrl',
  half_truck: 'halfTruckIconUrl',
};

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
    @Optional() private readonly feeCalculator?: DeliveryFeeCalculator,
  ) {}

  private get fees(): DeliveryFeeCalculator {
    return this.feeCalculator ?? new DeliveryFeeCalculator();
  }

  private emitSettingsUpdated() {
    this.eventEmitter.emit(EVENTS.SETTINGS_UPDATED);
  }

  // ─── Get settings ─────────────────────────────────────────────────────────
  // Seeds a default row if it has never been written (first boot).

  async getSettings() {
    const cached = (await this.cacheManager.get('platform_settings')) as
      | PlatformSetting
      | undefined
      | null;
    if (
      cached &&
      typeof (cached as unknown as Record<string, unknown>).allowMinibus ===
        'boolean' &&
      typeof (cached as unknown as Record<string, unknown>).allowTukTuk ===
        'boolean' &&
      typeof (cached as unknown as Record<string, unknown>)
        .allowQuarterTruck === 'boolean' &&
      typeof (cached as unknown as Record<string, unknown>).allowHalfTruck ===
        'boolean'
    ) {
      return cached;
    }

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
      multiVendorDeliveryDiscountPercent:
        s.multiVendorDeliveryDiscountPercent ?? 20,
      maxMultiVendorVendors: s.maxMultiVendorVendors,
      customOrderPlatformFee: s.customOrderPlatformFee,
      pricePerKm: s.pricePerKm,
      pricePerKmBicycle: s.pricePerKmBicycle,
      pricePerKmMotorcycle: s.pricePerKmMotorcycle,
      pricePerKmCar: s.pricePerKmCar,
      pricePerKmMinibus: s.pricePerKmMinibus,
      pricePerKmTukTuk: s.pricePerKmTukTuk,
      pricePerKmMotorTricycle: s.pricePerKmMotorTricycle,
      pricePerKmQuarterTruck: s.pricePerKmQuarterTruck,
      pricePerKmHalfTruck: s.pricePerKmHalfTruck,
      maxDeliveryFee: s.maxDeliveryFee,
      minDeliveryFeeBicycle: s.minDeliveryFeeBicycle,
      maxDeliveryFeeBicycle: s.maxDeliveryFeeBicycle,
      minDeliveryFeeMotorcycle: s.minDeliveryFeeMotorcycle,
      maxDeliveryFeeMotorcycle: s.maxDeliveryFeeMotorcycle,
      minDeliveryFeeCar: s.minDeliveryFeeCar,
      maxDeliveryFeeCar: s.maxDeliveryFeeCar,
      minDeliveryFeeMinibus: s.minDeliveryFeeMinibus,
      maxDeliveryFeeMinibus: s.maxDeliveryFeeMinibus,
      minDeliveryFeeTukTuk: s.minDeliveryFeeTukTuk,
      maxDeliveryFeeTukTuk: s.maxDeliveryFeeTukTuk,
      minDeliveryFeeMotorTricycle: s.minDeliveryFeeMotorTricycle,
      maxDeliveryFeeMotorTricycle: s.maxDeliveryFeeMotorTricycle,
      minDeliveryFeeQuarterTruck: s.minDeliveryFeeQuarterTruck,
      maxDeliveryFeeQuarterTruck: s.maxDeliveryFeeQuarterTruck,
      minDeliveryFeeHalfTruck: s.minDeliveryFeeHalfTruck,
      maxDeliveryFeeHalfTruck: s.maxDeliveryFeeHalfTruck,
      coinValue: s.coinValue,
      amountSpentPerCoin: s.amountSpentPerCoin,
      minCoinsToUse: s.minCoinsToUse,
      allowBicycle: s.allowBicycle,
      allowMotorcycle: s.allowMotorcycle,
      allowCar: s.allowCar,
      allowMinibus: s.allowMinibus,
      allowTukTuk: s.allowTukTuk,
      allowMotorTricycle: s.allowMotorTricycle,
      allowQuarterTruck: s.allowQuarterTruck,
      allowHalfTruck: s.allowHalfTruck,
      serviceEligibleVehicles: {
        STANDARD: [...STANDARD_ORDER_ELIGIBLE_VEHICLE_TYPES],
        RIDE: [...RIDE_ELIGIBLE_VEHICLE_TYPES],
        CUSTOM_DELIVERY: [...CUSTOM_DELIVERY_ELIGIBLE_VEHICLE_TYPES],
      },
      maxKmForBicycle: s.maxKmForBicycle,
      maxDeliveryRadiusKm: s.maxDeliveryRadiusKm,
      minOrderKm: s.minOrderKm,
      minDistanceFixedPrice: s.minDistanceFixedPrice,
      homeCoverUrl: s.homeCoverUrl,
      motorcycleIconUrl: s.motorcycleIconUrl,
      carIconUrl: s.carIconUrl,
      minibusIconUrl: s.minibusIconUrl,
      tukTukIconUrl: s.tukTukIconUrl,
      bicycleIconUrl: s.bicycleIconUrl,
      motorTricycleIconUrl: s.motorTricycleIconUrl,
      quarterTruckIconUrl: s.quarterTruckIconUrl,
      halfTruckIconUrl: s.halfTruckIconUrl,
      deliveryBannerIconUrl: s.deliveryBannerIconUrl,
      driverBonusActive: s.driverBonusActive,
      driverBonusAmount: s.driverBonusAmount,
      driverBonusStartDate: s.driverBonusStartDate,
      driverBonusEndDate: s.driverBonusEndDate,
      driverBonusPaidByCustomer: s.driverBonusPaidByCustomer,
      goldTierBonusPerOrder: Number(s.goldTierBonusPerOrder ?? 0),
      driverShiftsEnabled: s.driverShiftsEnabled,
      driverSearchRadiusKm: s.driverSearchRadiusKm,
      driverSearchRadiusStepKm: s.driverSearchRadiusStepKm,
      driverSearchRadiusMaxKm: s.driverSearchRadiusMaxKm,
      driverSearchMaxAttempts: s.driverSearchMaxAttempts,
      driverAcceptTimeoutSecs: s.driverAcceptTimeoutSecs,
      driverLocationFreshnessTtlSecs: s.driverLocationFreshnessTtlSecs,
    };
  }

  // ─── Update settings ──────────────────────────────────────────────────────
  // Upserts: always updates the single 'default' row.

  async updateSettings(dto: UpdatePlatformSettingsDto) {
    const data: Prisma.PlatformSettingUpdateInput = {};
    const dtoRecord = dto as Record<string, unknown>;
    const dataRecord = data as Record<string, unknown>;

    for (const field of UPDATABLE_SETTING_FIELDS) {
      if (dtoRecord[field] !== undefined) {
        dataRecord[field] = dtoRecord[field];
      }
    }

    const current = await this.prisma.platformSetting.findUnique({
      where: { id: 'default' },
    });

    const targetGold =
      dto.driverRankingGoldThreshold !== undefined
        ? dto.driverRankingGoldThreshold
        : (current?.driverRankingGoldThreshold ?? 95);
    const targetSilver =
      dto.driverRankingSilverThreshold !== undefined
        ? dto.driverRankingSilverThreshold
        : (current?.driverRankingSilverThreshold ?? 85);

    if (targetGold <= targetSilver) {
      throw new BadRequestException(DriverErrors.INVALID_RANKING_THRESHOLDS);
    }

    if (current) {
      this.syncCommissionTrio(dto, current, data, {
        platformKey: 'batchedDeliveryCommissionRate',
        managerKey: 'batchedDriverManagerCommissionRate',
        driverKey: 'stackedOrderDriverPercentage',
        defaults: [40, 10, 50],
      });
      this.syncCommissionTrio(dto, current, data, {
        platformKey: 'multiVendorDeliveryCommissionRate',
        managerKey: 'multiVendorDriverManagerCommissionRate',
        driverKey: 'multiVendorDriverPercentage',
        defaults: [20, 10, 70],
      });
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

  // ─── Delivery fee calculation helper (delegated to DeliveryFeeCalculator) ─

  async calculateDeliveryFee(
    distanceKm: number,
    zoneBaseDeliveryFeeOverride?: number | null,
    perKmOverride?: number | null,
    isStandardOrder: boolean = true,
    prefetchedSettings?: PlatformSetting,
    vehicleType?: string | null,
    includeGoldSurcharge: boolean = true,
  ): Promise<number> {
    const s = prefetchedSettings ?? (await this.getSettings());
    return this.fees.calculateDeliveryFee(s, {
      distanceKm,
      zoneBaseDeliveryFeeOverride,
      perKmOverride,
      isStandardOrder,
      vehicleType,
      includeGoldSurcharge,
    });
  }

  async calculateCustomerDeliveryBreakdown(
    distanceKm: number,
    zoneBaseDeliveryFeeOverride?: number | null,
    perKmOverride?: number | null,
    isStandardOrder: boolean = true,
    prefetchedSettings?: PlatformSetting,
    vehicleType?: string | null,
  ) {
    const s = prefetchedSettings ?? (await this.getSettings());
    return this.fees.calculateCustomerDeliveryBreakdown(s, {
      distanceKm,
      zoneBaseDeliveryFeeOverride,
      perKmOverride,
      isStandardOrder,
      vehicleType,
    });
  }

  async calculateGroupDeliveryFee(
    stopsDistancesKm: number[],
    zoneBaseDeliveryFeeOverride?: number | null,
    prefetchedSettings?: PlatformSetting,
    includeGoldSurcharge: boolean = false,
  ): Promise<number> {
    const s = prefetchedSettings ?? (await this.getSettings());
    return this.fees.calculateGroupDeliveryFee(
      s,
      stopsDistancesKm,
      zoneBaseDeliveryFeeOverride,
      { includeGoldSurcharge },
    );
  }

  async getVehiclePerKm(vehicleType: string): Promise<number | null> {
    const s = await this.getSettings();
    return this.fees.getVehiclePerKm(s, vehicleType);
  }

  // ─── Image Uploads ────────────────────────────────────────────────────────

  async uploadHomeCover(file: Express.Multer.File) {
    return this.replaceSettingAsset('homeCoverUrl', file);
  }

  async uploadMotorcycleIcon(file: Express.Multer.File) {
    return this.uploadVehicleIcon('motorcycle', file);
  }

  async uploadCarIcon(file: Express.Multer.File) {
    return this.uploadVehicleIcon('car', file);
  }

  async uploadVehicleIcon(vehicleType: string, file: Express.Multer.File) {
    const column = VEHICLE_ICON_COLUMNS[vehicleType];
    if (!column) {
      throw new BadRequestException(`Unknown vehicle type: ${vehicleType}`);
    }
    return this.replaceSettingAsset(column, file);
  }

  async uploadDeliveryBannerIcon(file: Express.Multer.File) {
    return this.replaceSettingAsset('deliveryBannerIconUrl', file);
  }

  private async replaceSettingAsset(
    column: string,
    file: Express.Multer.File,
  ): Promise<{ url: string }> {
    const s = await this.getSettings();
    const oldUrl = (s as unknown as Record<string, string | null>)[column];
    const url = await this.storage.upload(file, 'app/customization');

    await this.prisma.platformSetting.update({
      where: { id: 'default' },
      data: { [column]: url },
    });

    if (oldUrl) {
      await this.storage.delete(oldUrl).catch((err: Error) => {
        this.logger.warn(
          `Failed to delete old platform asset (${column}): ${err.message}`,
        );
      });
    }

    await this.cacheManager.del('platform_settings');
    this.emitSettingsUpdated();
    return { url };
  }

  private syncCommissionTrio(
    dto: UpdatePlatformSettingsDto,
    current: PlatformSetting,
    data: Prisma.PlatformSettingUpdateInput,
    keys: {
      platformKey: keyof PlatformSetting & keyof UpdatePlatformSettingsDto;
      managerKey: keyof PlatformSetting & keyof UpdatePlatformSettingsDto;
      driverKey: keyof PlatformSetting & keyof UpdatePlatformSettingsDto;
      defaults: [number, number, number];
    },
  ): void {
    const dtoRec = dto as Record<string, unknown>;
    const curRec = current as unknown as Record<string, unknown>;
    const dataRec = data as Record<string, unknown>;

    const newPlatform = Number(
      dtoRec[keys.platformKey] ?? curRec[keys.platformKey] ?? keys.defaults[0],
    );
    const newManager = Number(
      dtoRec[keys.managerKey] ?? curRec[keys.managerKey] ?? keys.defaults[1],
    );
    const newDriver = Number(
      dtoRec[keys.driverKey] ?? curRec[keys.driverKey] ?? keys.defaults[2],
    );

    const ratesChanged =
      (dtoRec[keys.platformKey] !== undefined &&
        dtoRec[keys.platformKey] !== curRec[keys.platformKey]) ||
      (dtoRec[keys.managerKey] !== undefined &&
        dtoRec[keys.managerKey] !== curRec[keys.managerKey]);
    const driverChanged =
      dtoRec[keys.driverKey] !== undefined &&
      dtoRec[keys.driverKey] !== curRec[keys.driverKey];

    if (ratesChanged && !driverChanged) {
      dataRec[keys.driverKey] = Math.max(0, 100 - newPlatform - newManager);
    } else if (driverChanged && !ratesChanged) {
      dataRec[keys.platformKey] = Math.max(0, 100 - newDriver - newManager);
    }
  }
}
