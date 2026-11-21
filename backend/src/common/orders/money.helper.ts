import { OrderType } from '@prisma/client';

const CENTS_SCALE = 100;

/**
 * Converts a finite monetary amount into exact integer piasters/cents so
 * intermediate arithmetic avoids IEEE-754 floating-point drift.
 */
export function toMoneyCents(value: number | string | null | undefined): number {
  const num = Number(value ?? 0);
  if (!Number.isFinite(num)) return 0;
  return Math.round((num + Math.sign(num) * Number.EPSILON) * CENTS_SCALE);
}

/**
 * Converts integer piasters/cents back to whole EGP integer using half-away-from-zero rounding.
 */
export function centsToWholeEgp(cents: number): number {
  if (!Number.isFinite(cents) || cents === 0) return 0;
  return Math.sign(cents) * Math.round(Math.abs(cents) / CENTS_SCALE);
}

/**
 * Converts integer piasters/cents to exact 2-decimal number without IEEE-754 noise.
 */
export function centsToDecimalEgp(cents: number): number {
  if (!Number.isFinite(cents) || cents === 0) return 0;
  return Math.round(cents) / CENTS_SCALE;
}

/**
 * Rounds a monetary value cleanly to whole EGP using exact piaster scaling first.
 */
export function roundMoneyWholeEgp(
  value: number | string | null | undefined,
): number {
  return centsToWholeEgp(toMoneyCents(value));
}

/**
 * Computes `Math.round(amount * ratio)` using scaled integer arithmetic so
 * percentage splits never drift due to floating-point representation.
 */
export function multiplyMoneyRatioToWholeEgp(
  amount: number | string | null | undefined,
  ratio: number,
): number {
  const amountCents = toMoneyCents(amount);
  const ratioBasisPoints = Number.isFinite(ratio)
    ? Math.round(ratio * 10_000)
    : 0;
  if (amountCents === 0 || ratioBasisPoints === 0) return 0;
  const scaled = (amountCents * ratioBasisPoints) / 10_000;
  return Math.sign(scaled) * Math.round(Math.abs(scaled) / CENTS_SCALE);
}

/**
 * Canonical shift eligibility rule shared across dispatch, search, and assist matching:
 * - Custom Delivery NEVER requires an active shift, regardless of `driverShiftsEnabled`.
 * - Standard Orders and Rides follow `driverShiftsEnabled`.
 */
export function requiresActiveShiftForOrderType(
  driverShiftsEnabled: boolean | null | undefined,
  orderType?: string | OrderType | null,
): boolean {
  if (!driverShiftsEnabled) return false;
  return orderType !== OrderType.CUSTOM_DELIVERY;
}
