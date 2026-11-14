import { BadRequestException, Injectable } from '@nestjs/common';
import { OrderErrors } from '../../../common/constants/response.constants';
import { CartService } from '../../cart/cart.service';
import { OrdersRepository } from '../orders.repository';
import {
  BranchWithProductCoverage,
  NearestBranchLocationResult,
} from '../repositories/order-geo.repository';

export interface AllocatedBranchPortion<TItem = any> {
  branch: NearestBranchLocationResult;
  items: TItem[];
  subtotal: number;
}

/**
 * Resolves the minimum set of open vendor branches within the delivery zone
 * needed to fulfil a single vendor's cart items, preferring the single nearest
 * branch when it carries all items and falling back to greedy nearest-branch
 * set cover when products are only available at distinct branches.
 */
@Injectable()
export class BranchAllocatorHelper {
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly cartService: CartService,
  ) {}

  async allocateForVendorCart<
    TItem extends { productId?: string | null; totalPrice?: number | null },
  >(params: {
    vendorId: string;
    deliveryLng: number;
    deliveryLat: number;
    zoneId?: string;
    cart: { items: TItem[]; subtotal: number };
  }): Promise<Array<AllocatedBranchPortion<TItem>>> {
    const { vendorId, deliveryLng, deliveryLat, zoneId, cart } = params;
    const productIds = [
      ...new Set(
        cart.items
          .map((item) => item.productId)
          .filter((id): id is string => Boolean(id)),
      ),
    ];

    // Fast path: nearest open branch that carries every product in the cart.
    const singleBranch =
      await this.ordersRepository.getNearestOpenBranchLocation(
        vendorId,
        deliveryLng,
        deliveryLat,
        zoneId,
        productIds,
      );
    if (singleBranch) {
      await this.cartService.assertItemsAvailableAtBranch(
        cart.items,
        singleBranch.id,
      );
      return [
        {
          branch: singleBranch,
          items: cart.items,
          subtotal: cart.subtotal,
        },
      ];
    }

    if (
      productIds.length === 0 ||
      typeof this.ordersRepository.getOpenBranchesWithProductAvailability !==
        'function'
    ) {
      if (productIds.length > 0) {
        const anyOpenBranch =
          await this.ordersRepository.getNearestOpenBranchLocation(
            vendorId,
            deliveryLng,
            deliveryLat,
            zoneId,
          );
        if (anyOpenBranch) {
          throw new BadRequestException(
            OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
          );
        }
      }
      throw new BadRequestException(OrderErrors.NO_OPEN_BRANCH);
    }

    const openBranches =
      await this.ordersRepository.getOpenBranchesWithProductAvailability(
        vendorId,
        deliveryLng,
        deliveryLat,
        zoneId,
        productIds,
      );
    if (openBranches.length === 0) {
      throw new BadRequestException(OrderErrors.NO_OPEN_BRANCH);
    }

    const branchCoverage = openBranches.map((branch, idx) => ({
      branch,
      idx,
      covered: new Set(branch.coveredProductIds),
    }));

    // Verify every distinct product has at least one open branch in this zone.
    for (const pid of productIds) {
      const hasCover = branchCoverage.some((entry) => entry.covered.has(pid));
      if (!hasCover) {
        throw new BadRequestException(
          OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
        );
      }
    }

    let uncoveredConstrained = cart.items.filter((item) =>
      Boolean(item.productId),
    );
    const unconstrained = cart.items.filter((item) => !item.productId);

    const chosen: Array<{
      branch: BranchWithProductCoverage;
      idx: number;
      items: TItem[];
    }> = [];
    const remaining = [...branchCoverage];

    while (uncoveredConstrained.length > 0) {
      const uncoveredProductIds = new Set(
        uncoveredConstrained
          .map((item) => item.productId)
          .filter((id): id is string => Boolean(id)),
      );

      let bestEntryIdx = -1;
      let bestProductCover = 0;
      let bestItemCover = 0;

      for (let i = 0; i < remaining.length; i++) {
        const entry = remaining[i];
        let productCover = 0;
        for (const pid of uncoveredProductIds) {
          if (entry.covered.has(pid)) productCover++;
        }
        if (productCover === 0) continue;

        let itemCover = 0;
        for (const item of uncoveredConstrained) {
          if (item.productId && entry.covered.has(item.productId)) itemCover++;
        }

        // Strict > preserves earliest-in-`openBranches` (nearest) on ties.
        if (
          productCover > bestProductCover ||
          (productCover === bestProductCover && itemCover > bestItemCover)
        ) {
          bestEntryIdx = i;
          bestProductCover = productCover;
          bestItemCover = itemCover;
        }
      }

      if (bestEntryIdx < 0 || bestProductCover === 0) {
        throw new BadRequestException(
          OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
        );
      }

      const [picked] = remaining.splice(bestEntryIdx, 1);
      const assigned: TItem[] = [];
      const nextUncovered: TItem[] = [];
      for (const item of uncoveredConstrained) {
        if (item.productId && picked.covered.has(item.productId)) {
          assigned.push(item);
        } else {
          nextUncovered.push(item);
        }
      }
      chosen.push({
        branch: picked.branch,
        idx: picked.idx,
        items: assigned,
      });
      uncoveredConstrained = nextUncovered;
    }

    // Order picked branches closest-first and attach unconstrained lines there.
    chosen.sort((a, b) => a.idx - b.idx);
    if (unconstrained.length > 0 && chosen.length > 0) {
      chosen[0].items.push(...unconstrained);
    }

    for (const bucket of chosen) {
      await this.cartService.assertItemsAvailableAtBranch(
        bucket.items,
        bucket.branch.id,
      );
    }

    const subtotals = chosen.map((bucket) =>
      Math.round(
        bucket.items.reduce(
          (sum, item) => sum + Number(item.totalPrice ?? 0),
          0,
        ),
      ),
    );
    // Conserve rounded cart subtotal across split portions (at most +/-1 EGP rounding).
    const targetTotal = Math.round(Number(cart.subtotal ?? 0));
    const currentSum = subtotals.reduce((sum, value) => sum + value, 0);
    if (subtotals.length > 0 && currentSum !== targetTotal) {
      let largestIdx = 0;
      for (let i = 1; i < subtotals.length; i++) {
        if (subtotals[i] > subtotals[largestIdx]) largestIdx = i;
      }
      subtotals[largestIdx] = Math.max(
        0,
        subtotals[largestIdx] + (targetTotal - currentSum),
      );
    }

    return chosen.map((bucket, idx) => ({
      branch: bucket.branch,
      items: bucket.items,
      subtotal: subtotals[idx],
    }));
  }
}
