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
  /**
   * km. Max straight-line distance between two vendors for them to share a
   * delivery ("close to each other"). Also the allowance for how far off the
   * line a vendor may sit and still ride along ("on the way").
   */
  maxBranchDistanceKm: number;
  /**
   * km. Max vendor→customer distance for a vendor to be eligible to ride along
   * on another vendor's trip ("close to the customer"). Beyond this a vendor is
   * a "far" anchor and always gets its own delivery.
   */
  maxVendorCustomerDistanceKm: number;
}

export type SplitReason = 'SINGLE_VENDOR' | 'FAR_FROM_CUSTOMER' | 'CLUSTERED';

export interface DeliveryGroupPlan {
  /** 1-based customer-facing sequence. */
  sequence: number;
  /** Members, farthest pickup first (the first stop is the distance anchor). */
  stops: VendorStop[];
  /**
   * Straight-line distance of the group's FARTHEST pickup to the customer. This
   * is the fee input: the customer pays for the long leg, not the short one.
   */
  farthestToCustomerKm: number;
  /**
   * Vendors beyond the first. Each one adds half the minimum delivery fee to the
   * group price (an extra stop, not an extra trip).
   */
  extraVendorCount: number;
  /** Why this group is separate from the others (surfaced to the customer). */
  splitReason: SplitReason;
}

export interface GroupingResult {
  groups: DeliveryGroupPlan[];
  /** True when the customer's order is arriving in more than one delivery. */
  isSplit: boolean;
  /** Thresholds actually used, so callers/tests can assert on them. */
  thresholds: GroupingThresholds;
}

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
 * Delivery grouping without any road-network assumption: every distance here is
 * straight-line. Two vendors share a delivery when they are close to each other,
 * and a vendor close to the customer may ride along on another vendor's trip as
 * long as it is roughly on the way.
 */
@Injectable()
export class OrderGroupingService {
  constructor(private readonly platformSettings: PlatformSettingsService) {}

  /** Reads the live thresholds so an admin change affects the next checkout
   * without a restart (PlatformSettingsService caches 1h and self-invalidates
   * on PATCH). */
  async currentThresholds(): Promise<GroupingThresholds> {
    const s = await this.platformSettings.getSettings();
    return {
      maxBranchDistanceKm: Number(s.groupingMaxBranchDistanceKm ?? 15),
      maxVendorCustomerDistanceKm: Number(
        s.groupingMaxVendorCustomerDistanceKm ?? 35,
      ),
    };
  }

  /**
   * Divide vendor pickups into delivery groups.
   *
   *  - Vendors within `maxBranchDistanceKm` of each other ("close to each
   *    other") always share a delivery.
   *  - A vendor within `maxVendorCustomerDistanceKm` of the customer ("close to
   *    the customer") may join a farther vendor's group, but only when it is
   *    roughly on the way — see `canJoin`. This keeps the road-free model from
   *    producing long zig-zag trips it cannot see.
   *
   * Deterministic: vendors are processed farthest-from-customer first (tie-break
   * by vendorId), so the group's first member is always its distance anchor and
   * identical input yields an identical plan.
   */
  plan(
    stops: VendorStop[],
    customer: CustomerPoint,
    thresholds: GroupingThresholds,
  ): GroupingResult {
    const { maxBranchDistanceKm, maxVendorCustomerDistanceKm } = thresholds;

    if (stops.length === 0) {
      return { groups: [], isSplit: false, thresholds };
    }

    const ordered = [...stops].sort((a, b) => {
      const da = haversineKm(a, customer);
      const db = haversineKm(b, customer);
      if (Math.abs(da - db) > 1e-9) return db - da;
      const keyA = a.vendorBranchId ?? a.vendorId;
      const keyB = b.vendorBranchId ?? b.vendorId;
      return keyA.localeCompare(keyB);
    });

    const groups: VendorStop[][] = [];

    for (const stop of ordered) {
      const stopToCustomer = haversineKm(stop, customer);
      const near = stopToCustomer <= maxVendorCustomerDistanceKm;

      let placed = false;
      for (const group of groups) {
        if (
          this.canJoin(
            group,
            stop,
            stopToCustomer,
            customer,
            maxBranchDistanceKm,
            near,
          )
        ) {
          group.push(stop);
          placed = true;
          break;
        }
      }
      if (!placed) groups.push([stop]);
    }

    const plans = groups.map((group, index) => {
      const farthestToCustomerKm = Math.max(
        ...group.map((s) => haversineKm(s, customer)),
      );
      return {
        sequence: index + 1,
        stops: group,
        farthestToCustomerKm,
        extraVendorCount: group.length - 1,
        splitReason: this.splitReason(group, customer, thresholds),
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

  /** May `stop` share a delivery with `group`? */
  private canJoin(
    group: VendorStop[],
    stop: VendorStop,
    stopToCustomer: number,
    customer: CustomerPoint,
    maxBranchDistanceKm: number,
    near: boolean,
  ): boolean {
    // Never let the exact same stop (branch, or vendor if branchless) occupy one group twice.
    const stopKey = stop.vendorBranchId ?? stop.vendorId;
    if (group.some((s) => (s.vendorBranchId ?? s.vendorId) === stopKey)) {
      return false;
    }

    // Safeguard for uncalibrated / (0,0) coordinates:
    const stopHasCoords = Boolean(stop.lat && stop.lng && (stop.lat !== 0 || stop.lng !== 0));
    const anchor = group[0];
    const anchorHasCoords = Boolean(anchor && anchor.lat && anchor.lng && (anchor.lat !== 0 || anchor.lng !== 0));
    if (!stopHasCoords || !anchorHasCoords) {
      return true;
    }

    // Close to each other: within range of any existing member.
    if (group.some((m) => haversineKm(m, stop) <= maxBranchDistanceKm)) {
      return true;
    }

    // A vendor near the customer may ride along on a farther trip, but only if
    // it is roughly on the way. The extra travel of detouring to it
    // (branch→vendor→customer minus the anchor→customer leg) must stay within
    // the branch allowance. group[0] is the anchor because stops are processed
    // farthest-first.
    if (!near) return false;
    const anchorToCustomer = haversineKm(anchor, customer);
    const detourKm =
      haversineKm(stop, anchor) + stopToCustomer - anchorToCustomer;
    return detourKm <= maxBranchDistanceKm;
  }

  private splitReason(
    group: VendorStop[],
    customer: CustomerPoint,
    t: GroupingThresholds,
  ): SplitReason {
    if (group.length === 1) return 'SINGLE_VENDOR';
    const hasFarAnchor = group.some(
      (s) => haversineKm(s, customer) > t.maxVendorCustomerDistanceKm,
    );
    return hasFarAnchor ? 'FAR_FROM_CUSTOMER' : 'CLUSTERED';
  }
}
