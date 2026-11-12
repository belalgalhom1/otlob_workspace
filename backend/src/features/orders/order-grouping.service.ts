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
   * km. Kept for the platform settings contract. Deliveries are no longer
   * merged, so this value does not change a plan.
   */
  maxBranchDistanceKm: number;
  /**
   * km. Kept for the platform settings contract. Deliveries are no longer
   * merged, so this value does not change a plan.
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
 * Delivery planning without any road-network assumption: every distance here is
 * straight-line.
 *
 * Every vendor portion is its own delivery: one vendor = one pickup = one
 * driver. Vendors are independently fulfilled (each one decides, prepares and
 * readies its own portion), so a shared trip made portions depend on each other:
 * the driver of a merged trip could only start collecting once every vendor in
 * it was ready, a single rejection changed the route of the others, and the
 * driver app — which works one delivery at a time — only ever received one of
 * the order's deliveries. Splitting per vendor gives every vendor portion its
 * own driver, its own tracked delivery and its own fee, exactly like a
 * single-vendor order.
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
   * Exactly one group per vendor portion — a vendor never shares a delivery
   * with another vendor (see the class comment). Delivery sequence is
   * deterministic: farthest pickup from the customer first (tie-break by
   * branch/vendor id), so identical input always yields an identical plan.
   */
  plan(
    stops: VendorStop[],
    customer: CustomerPoint,
    thresholds: GroupingThresholds,
  ): GroupingResult {
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

    const plans = ordered.map((stop, index) => ({
      sequence: index + 1,
      stops: [stop],
      farthestToCustomerKm: haversineKm(stop, customer),
      extraVendorCount: 0,
      splitReason: 'SINGLE_VENDOR' as SplitReason,
    }));

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
}
