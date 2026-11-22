import { BadRequestException } from '@nestjs/common';
import { PaymentMethod, PlatformSetting } from '@prisma/client';
import { CustomerErrors } from '../../../common/constants/response.constants';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';

export const DEFAULT_DRIVER_SEARCH_RADIUS_KM = 3;

/**
 * Computes the expanding dispatch/search radius for a given wave attempt,
 * ensuring every service (search preview, dispatch waves, Redis snapshots)
 * uses the exact same progression.
 */
export function computeSearchWaveRadiusKm(
  baseRadiusKm: number | null | undefined,
  stepRadiusKm: number | null | undefined,
  maxRadiusKm: number | null | undefined,
  attempt: number,
): number {
  const base =
    baseRadiusKm != null && Number(baseRadiusKm) > 0
      ? Number(baseRadiusKm)
      : DEFAULT_DRIVER_SEARCH_RADIUS_KM;
  const step =
    stepRadiusKm != null && Number(stepRadiusKm) > 0
      ? Number(stepRadiusKm)
      : DEFAULT_DRIVER_SEARCH_RADIUS_KM;
  const max =
    maxRadiusKm != null && Number(maxRadiusKm) > 0
      ? Number(maxRadiusKm)
      : Math.max(base, 15);
  const safeAttempt = Math.max(1, Math.floor(attempt || 1));
  return Math.min(base + step * Math.max(0, safeAttempt - 1), max);
}

/**
 * Resolves the active customer/driver bonus fee if the promotional bonus
 * window is currently active. Supports open-ended start/end dates consistently
 * across Standard, Multi-Vendor, Custom Delivery, and Ride orders.
 */
export function resolveActiveDriverBonusFee(
  settings: Partial<PlatformSetting>,
  now: Date = new Date(),
): number {
  const amount = Number(settings.driverBonusAmount ?? 0);
  if (!settings.driverBonusActive || amount <= 0) {
    return 0;
  }
  const start = settings.driverBonusStartDate ?? null;
  const end = settings.driverBonusEndDate ?? null;
  if (start && now < start) return 0;
  if (end && now > end) return 0;
  return amount;
}

/**
 * Resolves customer delivery fee and gold surcharge from PlatformSettingsService
 * using the canonical breakdown method (with legacy mock fallback for tests).
 */
export async function resolveCustomerDeliveryBreakdown(
  platformSettings: PlatformSettingsService,
  params: {
    distanceKm: number;
    zoneBaseDeliveryFeeOverride?: number | null;
    perKmOverride?: number | null;
    isStandardOrder: boolean;
    settings: PlatformSetting;
    vehicleType?: string | null;
  },
): Promise<{ deliveryFee: number; goldSurchargeAmount: number }> {
  const svc = platformSettings as unknown as {
    calculateCustomerDeliveryBreakdown?: (
      distanceKm: number,
      zoneBaseDeliveryFeeOverride?: number | null,
      perKmOverride?: number | null,
      isStandardOrder?: boolean,
      preloadedSettings?: PlatformSetting,
      vehicleType?: string | null,
    ) => Promise<{ totalFee: number; goldSurcharge: number }>;
  };

  if (typeof svc.calculateCustomerDeliveryBreakdown === 'function') {
    const breakdown = await svc.calculateCustomerDeliveryBreakdown(
      params.distanceKm,
      params.zoneBaseDeliveryFeeOverride ?? null,
      params.perKmOverride ?? null,
      params.isStandardOrder,
      params.settings,
      params.vehicleType ?? null,
    );
    return {
      deliveryFee: Number(breakdown.totalFee ?? 0),
      goldSurchargeAmount: Math.max(
        0,
        Math.round(Number(breakdown.goldSurcharge ?? 0)),
      ),
    };
  }

  const baseFee = await platformSettings.calculateDeliveryFee(
    params.distanceKm,
    params.zoneBaseDeliveryFeeOverride ?? null,
    params.perKmOverride ?? null,
    params.isStandardOrder,
    params.settings,
    params.vehicleType ?? null,
  );
  const goldSurchargeAmount = Math.max(
    0,
    Math.round(Number(params.settings.goldTierBonusPerOrder ?? 0)),
  );
  return {
    deliveryFee: Math.round(baseFee) + goldSurchargeAmount,
    goldSurchargeAmount,
  };
}

export interface OrderCoinsAndUpfrontResult {
  coinsUsed: number;
  discount: number;
  grandTotal: number;
  coinsEarned: number;
  upfrontAmount: number;
}

/**
 * Canonical coin redemption, grand total, coin earning, and high-value upfront
 * calculation shared by Standard, Multi-Vendor, Custom Delivery, and Ride flows.
 */
export function applyOrderCoinsAndUpfront(params: {
  preDiscountTotal: number;
  coinsToUse?: number | null;
  coinBalance: number;
  paymentMethod: PaymentMethod | string;
  settings: Partial<PlatformSetting>;
}): OrderCoinsAndUpfrontResult {
  const { preDiscountTotal, coinsToUse, coinBalance, paymentMethod, settings } =
    params;

  let coinsUsed = 0;
  let discount = 0;

  if (coinsToUse && coinsToUse > 0) {
    const minCoinsToUse = Math.max(0, Number(settings.minCoinsToUse ?? 0));
    if (coinBalance < minCoinsToUse) {
      throw new BadRequestException(CustomerErrors.MINIMUM_COINS_REQUIRED);
    }
    if (coinBalance < coinsToUse) {
      throw new BadRequestException(CustomerErrors.INSUFFICIENT_COIN_BALANCE);
    }
    coinsUsed = coinsToUse;
    const coinValue = Number(settings.coinValue ?? 0) || 0;
    discount = coinsUsed * coinValue;
    if (discount > preDiscountTotal) {
      discount = preDiscountTotal;
      coinsUsed = coinValue > 0 ? Math.ceil(discount / coinValue) : 0;
    }
  }

  const grandTotal = Math.max(0, preDiscountTotal - discount);
  const amountSpentPerCoin = Number(settings.amountSpentPerCoin ?? 0) || 0;
  const coinsEarned =
    amountSpentPerCoin > 0 ? Math.floor(grandTotal / amountSpentPerCoin) : 0;

  let upfrontAmount = 0;
  const highValueThreshold = Number(settings.highValueOrderThreshold ?? 0);
  if (
    paymentMethod === PaymentMethod.CASH_ON_DELIVERY &&
    highValueThreshold > 0 &&
    grandTotal >= highValueThreshold
  ) {
    upfrontAmount = Math.round(
      grandTotal * (Number(settings.highValueUpfrontRate ?? 0) / 100),
    );
  }

  return {
    coinsUsed,
    discount,
    grandTotal,
    coinsEarned,
    upfrontAmount,
  };
}
