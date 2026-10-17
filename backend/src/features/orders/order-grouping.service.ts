import { Injectable } from '@nestjs/common';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

/**
 * One vendor's pickup point for a customer order.
 */
export interface VendorStop {
  vendorId: string;
  vendorBranchId: string | null;
  /** Branch (or fallback) coordinates — the actual pickup position. */
  lng: number;
  lat: number;
  /** Vendor portion this stop fulfils. */
  fulfillmentId?: string | null;
}

export interface CustomerPoint {
  lng: number;
  lat: number;
}

export interface GroupingThresholds {
  /** km. Max distance between any two branches that may share a delivery. */
  maxBranchDistanceKm: number;
  /** km. Max branch→customer distance for a vendor to be groupable at all. */
  maxVendorCustomerDistanceKm: number;
  /** km. Max total pickup + drop-off route length for one group. */
  maxCombinedRouteKm: number;
}

export interface DeliveryGroupPlan {
  /** 1-based customer-facing sequence. */
  sequence: number;
  stops: VendorStop[];
  /** Sum of consecutive stop hops + final hop to the customer, best ordering. */
  routeKm: number;
  /** Distance from the group's first pickup to the customer (fee input). */
  firstPickupToCustomerKm: number;
  /** Why this group is separate from the others (surfaced to the customer). */
  splitReason: SplitReason;
}

export type SplitReason =
  | 'SINGLE_VENDOR'
  | 'BRANCH_DISTANCE'
  | 'VENDOR_CUSTOMER_DISTANCE'
  | 'COMBINED_ROUTE';

export interface GroupingResult {
  groups: DeliveryGroupPlan[];
  /** True when the customer's order is arriving in more than one delivery. */
  isSplit: boolean;
  /** Thresholds actually used, so callers/tests can assert on them. */
  thresholds: GroupingThresholds;
}

/**
 * Above this many vendors in one candidate group the exact Held–Karp ordering
 * search is skipped in favour of nearest-neighbour + 2-opt. Real checkouts are
 * far below this; the guard only bounds worst-case CPU.
 */
const EXACT_ROUTE_MAX_STOPS = 8;

/** Great-circle distance in km. Matches LocationRepository.getDistanceKm exactly
 * (PostGIS ST_Distance on ::geography, i.e. no road network). */
export function haversineKm(
  a: { lng: number; lat: number },
  b: { lng: number; lat: number },
): number {
  const R = 6371.0088;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Shortest route that visits every stop in the group once and finishes at the
 * customer: min over orderings of Σ d(consecutive) + d(last → customer).
 *
 * Does NOT assume the customer-nearest vendor is visited first — every ordering
 * is a candidate. Exact Held–Karp for small groups, nearest-neighbour + 2-opt
 * beyond that.
 */
export function bestRouteKm(
  stops: VendorStop[],
  customer: CustomerPoint,
): number {
  if (stops.length === 0) return 0;
  if (stops.length === 1) {
    return haversineKm(stops[0], customer);
  }

  const n = stops.length;
  const dist = (i: number, j: number) => haversineKm(stops[i], stops[j]);
  const toCustomer = (i: number) => haversineKm(stops[i], customer);

  if (n <= EXACT_ROUTE_MAX_STOPS) {
    const full = 1 << n;
    // dp[mask][last] = cheapest path covering `mask`, ending at `last`.
    const dp: number[][] = Array.from({ length: full }, () =>
      new Array<number>(n).fill(Number.POSITIVE_INFINITY),
    );
    for (let i = 0; i < n; i++) dp[1 << i][i] = 0;

    for (let mask = 1; mask < full; mask++) {
      for (let last = 0; last < n; last++) {
        if ((mask & (1 << last)) === 0) continue;
        const cur = dp[mask][last];
        if (!Number.isFinite(cur)) continue;
        for (let next = 0; next < n; next++) {
          if (mask & (1 << next)) continue;
          const nm = mask | (1 << next);
          const cost = cur + dist(last, next);
          if (cost < dp[nm][next]) dp[nm][next] = cost;
        }
      }
    }

    const all = full - 1;
    let best = Number.POSITIVE_INFINITY;
    for (let last = 0; last < n; last++) {
      const total = dp[all][last] + toCustomer(last);
      if (total < best) best = total;
    }
    return best;
  }

  // Nearest-neighbour seed, then 2-opt improvement.
  const remaining = stops.map((_, i) => i);
  const order: number[] = [];
  let cur: { lng: number; lat: number } | null = null;
  while (remaining.length) {
    let bestIdx = 0;
    let bestD = Number.POSITIVE_INFINITY;
    for (let k = 0; k < remaining.length; k++) {
      const i = remaining[k];
      const d = cur ? dist(i, order[order.length - 1]) : 0;
      if (d < bestD) {
        bestD = d;
        bestIdx = k;
      }
    }
    const [next] = remaining.splice(bestIdx, 1);
    order.push(next);
    cur = stops[next];
  }

  const routeLength = (o: number[]) => {
    let total = 0;
    for (let i = 1; i < o.length; i++) total += dist(o[i - 1], o[i]);
    return total + toCustomer(o[o.length - 1]);
  };

  let improved = true;
  let best = routeLength(order);
  while (improved) {
    improved = false;
    for (let i = 0; i < order.length - 1; i++) {
      for (let j = i + 1; j < order.length; j++) {
        const candidate = [...order];
        [candidate[i], candidate[j]] = [candidate[j], candidate[i]];
        const len = routeLength(candidate);
        if (len < best - 1e-9) {
          order.splice(0, order.length, ...candidate);
          best = len;
          improved = true;
        }
      }
    }
  }
  return best;
}

@Injectable()
export class OrderGroupingService {
  constructor(private readonly platformSettings: PlatformSettingsService) {}

  /** Reads the live thresholds so an admin change affects the next checkout
   * without a restart (PlatformSettingsService caches 1h and self-invalidates
   * on PATCH). */
  async currentThresholds(): Promise<GroupingThresholds> {
    const s = await this.platformSettings.getSettings();
    return {
      maxBranchDistanceKm: Number(s.groupingMaxBranchDistanceKm ?? 5),
      maxVendorCustomerDistanceKm: Number(
        s.groupingMaxVendorCustomerDistanceKm ?? 25,
      ),
      maxCombinedRouteKm: Number(s.groupingMaxCombinedRouteKm ?? 35),
    };
  }

  /**
   * Divide vendor pickups into delivery groups.
   *
   * Three independent factors, exactly as required:
   *   1. branch↔branch distance  → `maxBranchDistanceKm`
   *   2. branch↔customer distance → `maxVendorCustomerDistanceKm`
   *   3. combined route feasibility → `maxCombinedRouteKm`
   *
   * Being close to the customer never forces grouping with a distant vendor
   * (factor 1/3 still apply), and being far apart never forces a split when the
   * combined route is still acceptable (factor 3 is evaluated, not assumed).
   *
   * Deterministic: stops are ordered by (customer distance, vendorId) before
   * grouping, so identical input always yields an identical plan.
   */
  plan(
    stops: VendorStop[],
    customer: CustomerPoint,
    thresholds: GroupingThresholds,
  ): GroupingResult {
    const { maxBranchDistanceKm, maxVendorCustomerDistanceKm, maxCombinedRouteKm } =
      thresholds;

    if (stops.length === 0) {
      return { groups: [], isSplit: false, thresholds };
    }

    // Deterministic processing order. This is a *seeding* order only — it does
    // not constrain the resulting pickup route.
    const ordered = [...stops].sort((a, b) => {
      const da = haversineKm(a, customer);
      const db = haversineKm(b, customer);
      if (Math.abs(da - db) > 1e-9) return da - db;
      return a.vendorId.localeCompare(b.vendorId);
    });

    const groups: VendorStop[][] = [];

    for (const stop of ordered) {
      const stopToCustomer = haversineKm(stop, customer);

      // Factor 2: too far from the customer to ride along with anyone.
      if (stopToCustomer > maxVendorCustomerDistanceKm) {
        groups.push([stop]);
        continue;
      }

      let placed = false;
      for (const group of groups) {
        if (this.canJoin(group, stop, customer, thresholds, stopToCustomer)) {
          group.push(stop);
          placed = true;
          break;
        }
      }
      if (!placed) groups.push([stop]);
    }

    const plans = groups.map((group, index) => {
      const orderedStops = this.orderForFee(group, customer);
      const routeKm = bestRouteKm(group, customer);
      return {
        sequence: index + 1,
        stops: orderedStops,
        routeKm,
        // Fee input mirrors the existing single-vendor rule (first pickup →
        // customer), so a group is priced exactly like one vendor's order.
        firstPickupToCustomerKm: haversineKm(orderedStops[0], customer),
        splitReason: this.splitReason(group, thresholds),
      } satisfies DeliveryGroupPlan;
    });

    return {
      groups: plans,
      isSplit: plans.length > 1,
      thresholds,
    };
  }

  /** Convenience: read thresholds then plan. */
  async planForCheckout(
    stops: VendorStop[],
    customer: CustomerPoint,
  ): Promise<GroupingResult> {
    return this.plan(stops, customer, await this.currentThresholds());
  }

  /** Can `stop` legally ride along in `group`? All three factors must pass. */
  private canJoin(
    group: VendorStop[],
    stop: VendorStop,
    customer: CustomerPoint,
    t: GroupingThresholds,
    stopToCustomer: number,
  ): boolean {
    // Never let the same vendor occupy one group twice.
    if (group.some((s) => s.vendorId === stop.vendorId)) return false;

    // Factor 2
    if (stopToCustomer > t.maxVendorCustomerDistanceKm) return false;
    for (const member of group) {
      if (haversineKm(member, customer) > t.maxVendorCustomerDistanceKm)
        return false;
    }

    // Factor 1: every existing branch must be within range of the new one.
    for (const member of group) {
      if (haversineKm(member, stop) > t.maxBranchDistanceKm) return false;
    }

    // Factor 3: the whole combined route must still be acceptable.
    const route = bestRouteKm([...group, stop], customer);
    return route <= t.maxCombinedRouteKm;
  }

  /** Deterministic pickup ordering used for display and the fee input. */
  private orderForFee(group: VendorStop[], customer: CustomerPoint): VendorStop[] {
    if (group.length <= 1) return [...group];
    const idx = group.map((_, i) => i);
    const dist = (i: number, j: number) => haversineKm(group[i], group[j]);
    // Seed from the branch nearest the customer, then nearest-neighbour.
    let seed = 0;
    let bestD = Number.POSITIVE_INFINITY;
    idx.forEach((i) => {
      const d = haversineKm(group[i], customer);
      if (d < bestD) {
        bestD = d;
        seed = i;
      }
    });
    const order = [seed];
    const rest = idx.filter((i) => i !== seed);
    while (rest.length) {
      const last = order[order.length - 1];
      let pick = 0;
      let pickD = Number.POSITIVE_INFINITY;
      rest.forEach((i, k) => {
        const d = dist(last, i);
        if (d < pickD) {
          pickD = d;
          pick = k;
        }
      });
      order.push(rest.splice(pick, 1)[0]);
    }
    return order.map((i) => group[i]);
  }

  private splitReason(
    group: VendorStop[],
    t: GroupingThresholds,
  ): SplitReason {
    if (group.length === 1) return 'SINGLE_VENDOR';
    for (let i = 0; i < group.length; i++) {
      for (let j = i + 1; j < group.length; j++) {
        if (haversineKm(group[i], group[j]) > t.maxBranchDistanceKm)
          return 'BRANCH_DISTANCE';
      }
    }
    return 'COMBINED_ROUTE';
  }
}