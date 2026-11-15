export interface CashCollectionGroupInput {
  id: string;
  sequence?: number | null;
  deliveryFee?: number | null;
  isPaymentCollector?: boolean | null;
  primaryDriverId?: string | null;
  primaryDriverShiftId?: string | null;
}

export interface GroupCashAllocation {
  doorCashToCollect: number;
  totalCollectedByDriver: number;
}

export interface DriverBonusAllocation {
  driverId: string;
  driverShiftId: string | null;
  deliveryGroupId: string | null;
  amount: number;
}

/**
 * Canonical predicate across dispatch, projections, and settlement for whether an
 * order spans multiple vendors or multiple vendor portions/branches.
 */
export function computeIsMultiVendorOrder(params: {
  orderIsMultiVendor?: boolean | null;
  activeGroupsCount: number;
  activeFulfillmentsCount: number;
}): boolean {
  return Boolean(
    params.orderIsMultiVendor ||
      params.activeGroupsCount > 1 ||
      params.activeFulfillmentsCount > 1,
  );
}

/**
 * Distributes an integer non-negative total across non-negative weights using
 * Hamilton's largest-remainder method so the output sums strictly to `total`.
 */
export function allocateIntegerProportional(
  total: number,
  weights: number[],
): number[] {
  const safeTotal = Math.max(0, Math.round(total));
  if (weights.length === 0) return [];
  if (safeTotal === 0) return weights.map(() => 0);

  const normalizedWeights = weights.map((w) => Math.max(0, Number(w) || 0));
  const weightSum = normalizedWeights.reduce((acc, w) => acc + w, 0);
  const effectiveWeights =
    weightSum > 0 ? normalizedWeights : normalizedWeights.map(() => 1);
  const effectiveSum = effectiveWeights.reduce((acc, w) => acc + w, 0);

  const exactShares = effectiveWeights.map((w) => (safeTotal * w) / effectiveSum);
  const floors = exactShares.map((v) => Math.floor(v));
  let remainder = safeTotal - floors.reduce((acc, v) => acc + v, 0);

  const rankedIndices = exactShares
    .map((val, index) => ({ frac: val - floors[index], index }))
    .sort((a, b) => b.frac - a.frac || a.index - b.index);

  for (let i = 0; i < rankedIndices.length && remainder > 0; i++) {
    floors[rankedIndices[i].index] += 1;
    remainder -= 1;
  }

  return floors;
}

/**
 * Single source of truth for per-delivery-group cash collection at the door
 * (`doorCashToCollect`, used by driver projections) and total cash/wallet held by
 * each driver (`totalCollectedByDriver`, used by financial settlement).
 *
 * Guarantees:
 * - Customer is never asked for more cash at the door than `max(0, grandTotal - upfrontAmount)`.
 * - Combined cash attributed across groups equals `grandTotal` when driver-collected.
 */
export function allocateOrderCashCollection(params: {
  groups: CashCollectionGroupInput[];
  goodsByGroup: Map<string, number>;
  grandTotal: number;
  upfrontAmount: number;
  paymentMethod: string;
  isOrderSettledPrepaid?: boolean;
}): {
  collectorGroupId: string | null;
  allocations: Map<string, GroupCashAllocation>;
} {
  const sortedGroups = [...params.groups].sort(
    (a, b) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
  );
  const collectorGroup =
    sortedGroups.find((g) => g.isPaymentCollector === true) ??
    sortedGroups[0] ??
    null;

  const allocations = new Map<string, GroupCashAllocation>();
  for (const g of sortedGroups) {
    allocations.set(g.id, { doorCashToCollect: 0, totalCollectedByDriver: 0 });
  }

  if (sortedGroups.length === 0) {
    return { collectorGroupId: null, allocations };
  }

  const safeGrandTotal = Math.max(0, Math.round(params.grandTotal));
  const safeUpfront = Math.max(0, Math.round(params.upfrontAmount));
  const isMobileWallet = params.paymentMethod === 'MOBILE_WALLET';
  const isCashOnDelivery = params.paymentMethod === 'CASH_ON_DELIVERY';

  if (!isMobileWallet && !isCashOnDelivery) {
    return { collectorGroupId: collectorGroup?.id ?? null, allocations };
  }

  const remainingDoorDue = Math.max(0, safeGrandTotal - safeUpfront);

  if (isMobileWallet) {
    if (collectorGroup) {
      allocations.set(collectorGroup.id, {
        doorCashToCollect: params.isOrderSettledPrepaid ? 0 : remainingDoorDue,
        totalCollectedByDriver: safeGrandTotal,
      });
    }
    return { collectorGroupId: collectorGroup?.id ?? null, allocations };
  }

  // CASH_ON_DELIVERY: non-collector groups normally collect their own goods + deliveryFee
  // while the collector group absorbs order-level fees/discounts + paid upfront.
  // When coin discount + upfront exceeds collector's standalone total, excess discount/upfront
  // spills cleanly onto non-collector groups so customer never pays above grandTotal - upfront.
  const nonCollectorGroups = sortedGroups.filter(
    (g) => !collectorGroup || g.id !== collectorGroup.id,
  );
  const nonCollectorStandalones = nonCollectorGroups.map((g) =>
    Math.max(
      0,
      Math.round(
        (params.goodsByGroup.get(g.id) ?? 0) + Number(g.deliveryFee ?? 0),
      ),
    ),
  );
  const nonCollectorSum = nonCollectorStandalones.reduce((a, b) => a + b, 0);

  if (remainingDoorDue >= nonCollectorSum) {
    for (let i = 0; i < nonCollectorGroups.length; i++) {
      const amount = nonCollectorStandalones[i];
      allocations.set(nonCollectorGroups[i].id, {
        doorCashToCollect: amount,
        totalCollectedByDriver: amount,
      });
    }
    if (collectorGroup) {
      const collectorDoor = remainingDoorDue - nonCollectorSum;
      const collectorHeld = Math.max(0, safeGrandTotal - nonCollectorSum);
      allocations.set(collectorGroup.id, {
        doorCashToCollect: collectorDoor,
        totalCollectedByDriver: collectorHeld,
      });
    }
  } else {
    const nonCollectorShares = allocateIntegerProportional(
      remainingDoorDue,
      nonCollectorStandalones,
    );
    for (let i = 0; i < nonCollectorGroups.length; i++) {
      const share = nonCollectorShares[i];
      allocations.set(nonCollectorGroups[i].id, {
        doorCashToCollect: share,
        totalCollectedByDriver: share,
      });
    }
    if (collectorGroup) {
      allocations.set(collectorGroup.id, {
        doorCashToCollect: 0,
        totalCollectedByDriver: Math.max(0, safeGrandTotal - remainingDoorDue),
      });
    }
  }

  return {
    collectorGroupId: collectorGroup?.id ?? null,
    allocations,
  };
}

/**
 * Allocates `driverBonusFee` fairly across distinct primary drivers running active
 * delivery groups (single-driver orders award 100% to that driver; multi-driver
 * orders share proportionally by each driver's delivery fee).
 */
export function allocateDriverBonus(params: {
  driverBonusFee: number;
  groups: CashCollectionGroupInput[];
  fallbackDriverId?: string | null;
  fallbackDriverShiftId?: string | null;
}): DriverBonusAllocation[] {
  const safeBonus = Math.max(0, Math.round(params.driverBonusFee));
  if (safeBonus <= 0) return [];

  const sortedGroups = [...params.groups].sort(
    (a, b) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
  );
  const collectorGroup =
    sortedGroups.find((g) => g.isPaymentCollector === true) ?? sortedGroups[0];

  const byDriver = new Map<
    string,
    {
      driverId: string;
      driverShiftId: string | null;
      deliveryGroupId: string | null;
      isCollectorDriver: boolean;
      feeWeight: number;
    }
  >();

  for (const g of sortedGroups) {
    if (!g.primaryDriverId) continue;
    const isCollector = collectorGroup?.id === g.id;
    const fee = Math.max(0, Number(g.deliveryFee ?? 0));
    const existing = byDriver.get(g.primaryDriverId);
    if (existing) {
      existing.feeWeight += fee;
      if (isCollector && !existing.isCollectorDriver) {
        existing.deliveryGroupId = g.id;
        existing.driverShiftId = g.primaryDriverShiftId ?? existing.driverShiftId;
        existing.isCollectorDriver = true;
      }
    } else {
      byDriver.set(g.primaryDriverId, {
        driverId: g.primaryDriverId,
        driverShiftId: g.primaryDriverShiftId ?? null,
        deliveryGroupId: g.id,
        isCollectorDriver: isCollector,
        feeWeight: fee,
      });
    }
  }

  const entries = [...byDriver.values()];
  if (entries.length === 0) {
    if (!params.fallbackDriverId) return [];
    return [
      {
        driverId: params.fallbackDriverId,
        driverShiftId: params.fallbackDriverShiftId ?? null,
        deliveryGroupId: null,
        amount: safeBonus,
      },
    ];
  }

  // Collector driver goes first so largest-remainder +1 prefers collector cleanly on ties.
  entries.sort((a, b) => Number(b.isCollectorDriver) - Number(a.isCollectorDriver));
  const shares = allocateIntegerProportional(
    safeBonus,
    entries.map((e) => e.feeWeight),
  );

  return entries
    .map((entry, idx) => ({
      driverId: entry.driverId,
      driverShiftId: entry.driverShiftId,
      deliveryGroupId: entry.deliveryGroupId,
      amount: shares[idx],
    }))
    .filter((row) => row.amount > 0);
}
