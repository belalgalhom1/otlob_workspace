/**
 * Pure driver KPI formulas shared between Weekly Driver Ranking evaluation
 * and Statistics analytics so acceptance & completion rates never diverge.
 */

export function calculateEligibleDispatches(
  accepted: number,
  rejected: number,
  expired: number,
): number {
  return accepted + rejected + expired;
}

export function calculateAcceptanceRate(
  accepted: number,
  rejected: number,
  expired: number,
): number | null {
  const eligible = calculateEligibleDispatches(accepted, rejected, expired);
  return eligible > 0 ? (accepted / eligible) * 100 : null;
}

export function calculateDriverResponsibleOrders(
  completed: number,
  driverFaultFailures: number,
): number {
  return completed + driverFaultFailures;
}

export function calculateCompletionRate(
  completed: number,
  driverFaultFailures: number,
): number | null {
  const responsible = calculateDriverResponsibleOrders(
    completed,
    driverFaultFailures,
  );
  return responsible > 0 ? (completed / responsible) * 100 : null;
}
