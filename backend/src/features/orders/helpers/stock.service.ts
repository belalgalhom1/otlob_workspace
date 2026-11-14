import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { OrderErrors } from '../../../common/constants/response.constants';

export interface StockLineItem {
  productId: string | null;
  variantId: string | null;
  quantity: number;
  selectedUnit: string | null;
  product?: {
    tracksStock: boolean;
    sellByStrip: boolean | null;
    stripsPerPackage: number | null;
  } | null;
  variant?: {
    tracksStock: boolean;
  } | null;
}

/**
 * Shared transactional inventory service. Handles strip-to-package unit
 * normalization and atomic guarded decrements / restorations for single-vendor
 * checkout, multi-vendor checkout, vendor rejection, and order cancellation.
 */
@Injectable()
export class StockService {
  /**
   * Guarded stock decrement inside an active DB transaction.
   * Throws INSUFFICIENT_STOCK on invalid quantity or concurrent sell-out.
   */
  async decrementForItems(
    tx: Prisma.TransactionClient,
    items: StockLineItem[],
  ): Promise<void> {
    for (const item of items) {
      if (item.quantity <= 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
    }

    const { variantQtyById, trackedVariantIds, productPackageQtyById, trackedProductIds } =
      await this.aggregateTrackedQuantities(tx, items);

    for (const [variantId, qty] of variantQtyById) {
      if (qty <= 0 || !trackedVariantIds.has(variantId)) continue;
      const rows = await tx.$executeRaw`
        UPDATE product_variants
        SET stock = stock - ${qty}
        WHERE id = ${variantId}
          AND stock IS NOT NULL
          AND stock >= ${qty}
      `;
      if (rows === 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
    }

    for (const [productId, qty] of productPackageQtyById) {
      if (qty <= 0 || !trackedProductIds.has(productId)) continue;
      const rows = await tx.$executeRaw`
        UPDATE products
        SET stock = stock - ${qty}
        WHERE id = ${productId}
          AND stock IS NOT NULL
          AND stock >= ${qty}
      `;
      if (rows === 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
    }
  }

  /**
   * Restore tracked variant/product stock inside an active DB transaction.
   */
  async restoreForItems(
    tx: Prisma.TransactionClient,
    items: StockLineItem[],
  ): Promise<void> {
    const validItems = items.filter((item) => item.quantity > 0);
    if (validItems.length === 0) return;

    const { variantQtyById, trackedVariantIds, productPackageQtyById, trackedProductIds } =
      await this.aggregateTrackedQuantities(tx, validItems);

    for (const [variantId, qty] of variantQtyById) {
      if (qty <= 0 || !trackedVariantIds.has(variantId)) continue;
      await tx.$executeRaw`
        UPDATE product_variants
        SET stock = stock + ${qty}
        WHERE id = ${variantId}
          AND stock IS NOT NULL
      `;
    }

    for (const [productId, qty] of productPackageQtyById) {
      if (qty <= 0 || !trackedProductIds.has(productId)) continue;
      await tx.$executeRaw`
        UPDATE products
        SET stock = stock + ${qty}
        WHERE id = ${productId}
          AND stock IS NOT NULL
      `;
    }
  }

  private async aggregateTrackedQuantities(
    tx: Prisma.TransactionClient,
    items: StockLineItem[],
  ) {
    const variantQtyById = new Map<string, number>();
    const rawProductMeta = new Map<
      string,
      { tracksStock: boolean; sellByStrip: boolean | null; stripsPerPackage: number | null }
    >();
    const rawVariantTracked = new Map<string, boolean>();
    const packageQtyByProductId = new Map<string, number>();
    const stripQtyByProductId = new Map<string, number>();
    const allProductIds = new Set<string>();

    for (const item of items) {
      if (item.variantId) {
        variantQtyById.set(
          item.variantId,
          (variantQtyById.get(item.variantId) ?? 0) + item.quantity,
        );
        if (item.variant != null) {
          rawVariantTracked.set(item.variantId, Boolean(item.variant.tracksStock));
        }
      } else if (item.productId) {
        allProductIds.add(item.productId);
        if (item.product != null) {
          rawProductMeta.set(item.productId, item.product);
        }
        if (item.selectedUnit === 'strip') {
          stripQtyByProductId.set(
            item.productId,
            (stripQtyByProductId.get(item.productId) ?? 0) + item.quantity,
          );
        } else {
          packageQtyByProductId.set(
            item.productId,
            (packageQtyByProductId.get(item.productId) ?? 0) + item.quantity,
          );
        }
      }
    }

    const missingVariantIds = [...variantQtyById.keys()]
      .filter((id) => !rawVariantTracked.has(id))
      .sort();
    if (missingVariantIds.length > 0) {
      const variants = await tx.productVariant.findMany({
        where: { id: { in: missingVariantIds } },
        select: { id: true, tracksStock: true },
      });
      for (const v of variants) {
        rawVariantTracked.set(v.id, v.tracksStock);
      }
    }
    const trackedVariantIds = new Set(
      [...rawVariantTracked.entries()]
        .filter(([, tracked]) => tracked)
        .map(([id]) => id),
    );

    const missingProductIds = [...allProductIds]
      .filter((id) => !rawProductMeta.has(id))
      .sort();
    if (missingProductIds.length > 0) {
      const products = await tx.product.findMany({
        where: { id: { in: missingProductIds } },
        select: {
          id: true,
          tracksStock: true,
          sellByStrip: true,
          stripsPerPackage: true,
        },
      });
      for (const p of products) {
        rawProductMeta.set(p.id, p);
      }
    }

    const trackedProductIds = new Set<string>();
    const stripDividerById = new Map<string, number>();
    for (const [productId, meta] of rawProductMeta) {
      if (!meta.tracksStock) continue;
      trackedProductIds.add(productId);
      const divider =
        meta.sellByStrip === true && Number(meta.stripsPerPackage ?? 0) > 0
          ? Math.max(1, Number(meta.stripsPerPackage))
          : 1;
      stripDividerById.set(productId, divider);
    }

    const productPackageQtyById = new Map(packageQtyByProductId);
    for (const [productId, stripQty] of stripQtyByProductId) {
      const divider = stripDividerById.get(productId) ?? 1;
      const packages = Math.ceil(stripQty / divider);
      productPackageQtyById.set(
        productId,
        (productPackageQtyById.get(productId) ?? 0) + packages,
      );
    }

    return {
      variantQtyById,
      trackedVariantIds,
      productPackageQtyById,
      trackedProductIds,
    };
  }
}
