import {
  DriverRankChangeReason,
  DriverShiftStatus,
  DriverTier,
} from '@prisma/client';
import {
  calculateAcceptanceRate,
  calculateCompletionRate,
  calculateDriverResponsibleOrders,
  calculateEligibleDispatches,
} from '../../../common/drivers/driver-kpi.helper';

export const GOLD_MIN_PERCENTAGE = 95;
export const SILVER_MIN_PERCENTAGE = 85;
export const SHIFT_GRACE_MINUTES = 5;

export enum DriverRankingOutcome {
  PROMOTED = 'PROMOTED',
  DEMOTED = 'DEMOTED',
  UNCHANGED = 'UNCHANGED',
  INACTIVE_SILVER = 'INACTIVE_SILVER',
  CAPPED_SILVER = 'CAPPED_SILVER',
}

export type ShiftRankingClassification =
  | 'excused'
  | 'cancelled'
  | 'onTime'
  | 'late'
  | 'missed'
  | 'upcoming';

export interface ExcludedIncidentsSummary {
  customer: number;
  vendor: number;
  externalOrSystem: number;
  underReview: number;
}

export interface DriverWeeklyMetricInput {
  driverId: string;
  driverName: string;
  currentTier: DriverTier;
  isSuspended?: boolean;
  acceptedDispatches: number;
  rejectedDispatches: number;
  expiredDispatches: number;
  cancelledDispatches: number;
  completedOrders: number;
  driverFaultFailures: number;
  excludedIncidents: ExcludedIncidentsSummary;
  onTimeShifts: number;
  lateShifts: number;
  missedShifts: number;
  cancelledShifts: number;
  excusedShifts: number;
}

export interface DriverMetricsSnapshot {
  acceptedDispatches: number;
  rejectedDispatches: number;
  expiredDispatches: number;
  eligibleDispatches: number;
  cancelledDispatches: number;
  completedOrders: number;
  driverFaultFailures: number;
  driverResponsibleOrders: number;
  excludedIncidents: ExcludedIncidentsSummary;
  onTimeShifts: number;
  lateShifts: number;
  missedShifts: number;
  eligibleShifts: number;
  cancelledShifts: number;
  excusedShifts: number;
  acceptanceRate: number | null;
  completionRate: number | null;
  shiftPunctualityRate: number | null;
  applicableMetricsCount: number;
  cappedDueToNoOrders: boolean;
  explanations: string[];
}

export interface DriverWeeklyEvaluationResult {
  driverId: string;
  driverName: string;
  previousTier: DriverTier;
  newTier: DriverTier;
  changeReason: DriverRankChangeReason;
  outcome: DriverRankingOutcome;
  performancePercentage: number | null;
  acceptanceRate: number | null;
  completionRate: number | null;
  shiftPunctualityRate: number | null;
  metricsSnapshot: DriverMetricsSnapshot;
  explanations: string[];
}

export const TIER_WEIGHT: Record<DriverTier, number> = {
  [DriverTier.BRONZE]: 1,
  [DriverTier.SILVER]: 2,
  [DriverTier.GOLD]: 3,
};

/** Returns >0 if promoted, <0 if demoted, 0 if unchanged. */
export function compareTiers(
  previousTier: DriverTier,
  newTier: DriverTier,
): number {
  return TIER_WEIGHT[newTier] - TIER_WEIGHT[previousTier];
}

/** Summarizes total/promoted/demoted/unchanged/inactive counts across rank entries. */
export function summarizeRankTransitions(
  entries: ReadonlyArray<{
    previousTier: DriverTier;
    newTier: DriverTier;
    changeReason: DriverRankChangeReason;
  }>,
) {
  let promotedCount = 0;
  let demotedCount = 0;
  let unchangedCount = 0;
  let inactiveCount = 0;

  for (const entry of entries) {
    if (entry.changeReason === DriverRankChangeReason.INACTIVE_DRIVER) {
      inactiveCount++;
    }
    const diff = compareTiers(entry.previousTier, entry.newTier);
    if (diff > 0) promotedCount++;
    else if (diff < 0) demotedCount++;
    else unchangedCount++;
  }

  return {
    totalDrivers: entries.length,
    promotedCount,
    demotedCount,
    unchangedCount,
    inactiveCount,
  };
}

/**
 * Classifies a shift into its ranking bucket as of `effectiveEndMs` (typically
 * `min(periodEnd, now)` so future scheduled shifts in an in-progress week are
 * not penalized as missed).
 */
export function classifyShiftForRanking(
  shift: {
    status: DriverShiftStatus;
    startTime: Date;
    actualStart: Date | null;
    isExcused: boolean;
  },
  effectiveEndMs: number,
  graceMs = SHIFT_GRACE_MINUTES * 60_000,
): ShiftRankingClassification {
  if (shift.isExcused) return 'excused';
  if (shift.status === DriverShiftStatus.CANCELLED) return 'cancelled';
  if (shift.status === DriverShiftStatus.MISSED) return 'missed';

  if (
    (shift.status === DriverShiftStatus.ACTIVE ||
      shift.status === DriverShiftStatus.COMPLETED) &&
    shift.actualStart != null
  ) {
    return shift.actualStart.getTime() <= shift.startTime.getTime() + graceMs
      ? 'onTime'
      : 'late';
  }

  if (
    shift.status === DriverShiftStatus.SCHEDULED &&
    shift.startTime.getTime() + graceMs <= effectiveEndMs
  ) {
    return 'missed';
  }

  return 'upcoming';
}

/**
 * Maps an exact, unrounded percentage to the fixed Gold / Silver / Bronze tiers.
 */
export function resolveTierForPercentage(percentage: number): DriverTier {
  if (percentage >= GOLD_MIN_PERCENTAGE) return DriverTier.GOLD;
  if (percentage >= SILVER_MIN_PERCENTAGE) return DriverTier.SILVER;
  return DriverTier.BRONZE;
}

/**
 * Pure weekly driver ranking evaluation implementing the 3 equal-weight KPIs:
 * 1) Order Acceptance Rate (OrderDispatch)
 * 2) Order Completion Rate (Primary completed orders vs driver-fault incidents)
 * 3) Shift Punctuality Rate (5-minute grace period, excused/cancelled excluded)
 */
export function evaluateDriverWeeklyMetrics(
  input: DriverWeeklyMetricInput,
): DriverWeeklyEvaluationResult {
  const eligibleDispatches = calculateEligibleDispatches(
    input.acceptedDispatches,
    input.rejectedDispatches,
    input.expiredDispatches,
  );
  const acceptanceRate = calculateAcceptanceRate(
    input.acceptedDispatches,
    input.rejectedDispatches,
    input.expiredDispatches,
  );

  const driverResponsibleOrders = calculateDriverResponsibleOrders(
    input.completedOrders,
    input.driverFaultFailures,
  );
  const completionRate = calculateCompletionRate(
    input.completedOrders,
    input.driverFaultFailures,
  );

  const eligibleShifts =
    input.onTimeShifts + input.lateShifts + input.missedShifts;
  const shiftPunctualityRate =
    eligibleShifts > 0 ? (input.onTimeShifts / eligibleShifts) * 100 : null;

  const applicableRates = [
    acceptanceRate,
    completionRate,
    shiftPunctualityRate,
  ].filter((v): v is number => v !== null);

  const explanations: string[] = [];
  if (input.cancelledDispatches > 0) {
    explanations.push(
      `${input.cancelledDispatches} cancelled/reassigned dispatch offer(s) excluded`,
    );
  }
  if (input.excludedIncidents.customer > 0) {
    explanations.push(
      `${input.excludedIncidents.customer} customer cancellation(s) excluded`,
    );
  }
  if (input.excludedIncidents.vendor > 0) {
    explanations.push(
      `${input.excludedIncidents.vendor} vendor cancellation(s) excluded`,
    );
  }
  if (input.excludedIncidents.externalOrSystem > 0) {
    explanations.push(
      `${input.excludedIncidents.externalOrSystem} external/system incident(s) excluded`,
    );
  }
  if (input.excludedIncidents.underReview > 0) {
    explanations.push(
      `${input.excludedIncidents.underReview} incident(s) under review excluded`,
    );
  }
  if (input.cancelledShifts > 0) {
    explanations.push(
      `${input.cancelledShifts} platform-cancelled shift(s) excluded`,
    );
  }
  if (input.excusedShifts > 0) {
    explanations.push(`${input.excusedShifts} excused shift(s) excluded`);
  }

  let performancePercentage: number | null = null;
  let newTier: DriverTier;
  let changeReason: DriverRankChangeReason;
  let outcome: DriverRankingOutcome;
  let cappedDueToNoOrders = false;

  if (applicableRates.length === 0) {
    changeReason = DriverRankChangeReason.INACTIVE_DRIVER;
    if (input.isSuspended) {
      // Do not auto-promote or reset a suspended driver to SILVER for being inactive.
      newTier = input.currentTier;
      outcome = DriverRankingOutcome.UNCHANGED;
      explanations.push(
        'Driver is suspended with no qualifying weekly activity — badge unchanged',
      );
    } else {
      // Inactive / newly onboarded driver with zero qualifying weekly activity.
      newTier = DriverTier.SILVER;
      outcome = DriverRankingOutcome.INACTIVE_SILVER;
      explanations.push(
        'No qualifying weekly activity — assigned SILVER tier',
      );
    }
  } else {
    // Exact unrounded average across all applicable indicators.
    performancePercentage =
      applicableRates.reduce((sum, val) => sum + val, 0) /
      applicableRates.length;
    const rawTier = resolveTierForPercentage(performancePercentage);

    if (
      eligibleDispatches === 0 &&
      driverResponsibleOrders === 0 &&
      eligibleShifts > 0 &&
      rawTier === DriverTier.GOLD
    ) {
      newTier = DriverTier.SILVER;
      cappedDueToNoOrders = true;
      outcome = DriverRankingOutcome.CAPPED_SILVER;
      explanations.push(
        'Capped at SILVER: attended shift(s) with zero eligible dispatch/order activity',
      );
    } else {
      newTier = rawTier;
      const diff = compareTiers(input.currentTier, newTier);
      outcome =
        diff > 0
          ? DriverRankingOutcome.PROMOTED
          : diff < 0
            ? DriverRankingOutcome.DEMOTED
            : DriverRankingOutcome.UNCHANGED;
    }
    changeReason = DriverRankChangeReason.WEEKLY_EVALUATION;
  }

  const metricsSnapshot: DriverMetricsSnapshot = {
    acceptedDispatches: input.acceptedDispatches,
    rejectedDispatches: input.rejectedDispatches,
    expiredDispatches: input.expiredDispatches,
    eligibleDispatches,
    cancelledDispatches: input.cancelledDispatches,
    completedOrders: input.completedOrders,
    driverFaultFailures: input.driverFaultFailures,
    driverResponsibleOrders,
    excludedIncidents: { ...input.excludedIncidents },
    onTimeShifts: input.onTimeShifts,
    lateShifts: input.lateShifts,
    missedShifts: input.missedShifts,
    eligibleShifts,
    cancelledShifts: input.cancelledShifts,
    excusedShifts: input.excusedShifts,
    acceptanceRate,
    completionRate,
    shiftPunctualityRate,
    applicableMetricsCount: applicableRates.length,
    cappedDueToNoOrders,
    explanations,
  };

  return {
    driverId: input.driverId,
    driverName: input.driverName,
    previousTier: input.currentTier,
    newTier,
    changeReason,
    outcome,
    performancePercentage,
    acceptanceRate,
    completionRate,
    shiftPunctualityRate,
    metricsSnapshot,
    explanations,
  };
}
