import { Injectable } from '@nestjs/common';
import { DeliveryGroupStatus, OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';
import { haversineKm } from '../../../common/geo/geo.utils';
import {
  recordOrderStatusEventIdempotent,
  systemActorSnapshot,
} from './order-actor.helper';

export interface GroupVendorRemovalResult {
  deliveryFeeDelta: number;
  freedDriverIds: string[];
}

/**
 * Computes delivery-group fee adjustments, order totals, proportional discount
 * & tax adjustments, coin refunds, and prepaid refund obligations when a vendor
 * rejects or times out on an order portion.
 */
@Injectable()
export class OrderRejectionRecomputor {
  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  /**
   * Keep the delivery group coherent after a vendor portion leaves it:
   * - If no portions remain in the group, cancel the group (unless already picked
   *   up / delivered) and cancel its pending dispatches, returning any assigned
   *   drivers so the caller can release them once the tx commits.
   * - Otherwise reduce the group's delivery fee by the extra-vendor surcharge.
   *
   * Returns the change to the ORDER-level delivery fee so the caller can apply
   * it in the single order-level write.
   */
  async syncDeliveryGroupAfterVendorRemoved(
    tx: Prisma.TransactionClient,
    deliveryGroupId: string,
    orderId: string,
    orderStatus: OrderStatus,
    _deprecatedExtraVendorFee?: number,
  ): Promise<GroupVendorRemovalResult> {
    const group = await tx.orderDeliveryGroup.findUnique({
      where: { id: deliveryGroupId },
      select: {
        deliveryFee: true,
        sequence: true,
        primaryDriverId: true,
        assistDriverId: true,
      },
    });
    if (!group) return { deliveryFeeDelta: 0, freedDriverIds: [] };

    const remaining = await tx.orderDeliveryGroupItem.count({
      where: { deliveryGroupId },
    });

    if (remaining === 0) {
      // Nobody left to pick up from: cancel the delivery group (as long as it
      // has not been picked up/delivered yet), cancel any pending dispatches for
      // it, and return any assigned driver(s) so they can be freed after commit.
      const cancelled = await tx.orderDeliveryGroup.updateMany({
        where: {
          id: deliveryGroupId,
          status: {
            notIn: [
              DeliveryGroupStatus.CANCELLED,
              DeliveryGroupStatus.PICKED_UP,
              DeliveryGroupStatus.PARTIALLY_PICKED_UP,
              DeliveryGroupStatus.DELIVERED,
            ],
          },
        },
        data: { status: DeliveryGroupStatus.CANCELLED, deliveryFee: 0 },
      });
      if (cancelled.count === 0) {
        return { deliveryFeeDelta: 0, freedDriverIds: [] };
      }

      await tx.orderDispatch.updateMany({
        where: { deliveryGroupId, status: 'PENDING' },
        data: { status: 'CANCELLED' },
      });

      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        deliveryGroupId,
        eventKey: `group_no_vendors:${deliveryGroupId}`,
        status: orderStatus,
        note: `Delivery ${group.sequence} cancelled — no vendors accepted`,
        createdBy: 'system',
        actor: systemActorSnapshot(),
      });
      const freedDriverIds = [
        group.primaryDriverId,
        group.assistDriverId,
      ].filter((id): id is string => Boolean(id));
      return { deliveryFeeDelta: -group.deliveryFee, freedDriverIds };
    }

    // Recompute the delivery fee for the remaining vendor portions in this group.
    let newFee: number;
    try {
      const remainingItems = await tx.orderDeliveryGroupItem.findMany({
        where: { deliveryGroupId },
        select: { fulfillmentId: true },
      });
      const fulfillmentIds = remainingItems.map((i) => i.fulfillmentId);
      const fulfillments = await tx.orderVendorFulfillment.findMany({
        where: { id: { in: fulfillmentIds } },
        select: { vendorBranchId: true, vendorId: true },
      });

      const explicitBranchIds = fulfillments
        .map((f) => f.vendorBranchId)
        .filter((id): id is string => Boolean(id));

      const orderLocs = await tx.$queryRaw<Array<{ lng: number; lat: number }>>`
        SELECT ST_X("deliveryLocation"::geometry) AS lng, ST_Y("deliveryLocation"::geometry) AS lat
        FROM orders WHERE id = ${orderId} LIMIT 1
      `;

      let branchLocs: Array<{ lng: number; lat: number }> = [];
      if (explicitBranchIds.length > 0) {
        branchLocs = await tx.$queryRaw<Array<{ lng: number; lat: number }>>`
          SELECT ST_X(location::geometry) AS lng, ST_Y(location::geometry) AS lat
          FROM vendor_branches WHERE id IN (${Prisma.join(explicitBranchIds)})
        `;
      }

      const settings = await this.platformSettings.getSettings();
      const minFee = Number(settings.minDeliveryFee ?? 15);
      const discountPercent = Number(
        (settings as any).multiVendorDeliveryDiscountPercent ?? 20,
      );
      const discountMultiplier =
        Math.max(0, Math.min(100, discountPercent)) / 100;

      if (orderLocs.length > 0 && branchLocs.length > 0) {
        const dest = {
          lng: Number(orderLocs[0].lng),
          lat: Number(orderLocs[0].lat),
        };
        if (branchLocs.length === 1) {
          const dist = haversineKm(branchLocs[0], dest);
          const base = await this.platformSettings.calculateDeliveryFee(
            dist,
            null,
            null,
            true,
            settings,
          );
          newFee = Math.max(minFee, Math.round(base));
        } else {
          let rawSum = 0;
          for (const stop of branchLocs) {
            const dist = haversineKm(stop, dest);
            const fee = await this.platformSettings.calculateDeliveryFee(
              dist,
              null,
              null,
              true,
              settings,
            );
            rawSum += fee;
          }
          const discounted = Math.round(rawSum * (1 - discountMultiplier));
          newFee = Math.max(minFee, discounted);
        }
      } else {
        // Fallback when coordinates are missing: scale fee proportionally to remaining stops
        newFee = Math.max(minFee, Math.round((group.deliveryFee * remaining) / (remaining + 1)));
      }
    } catch {
      const minFee = Number((await this.platformSettings.getSettings()).minDeliveryFee ?? 15);
      newFee = Math.max(minFee, Math.round((group.deliveryFee * remaining) / (remaining + 1)));
    }

    if (newFee === group.deliveryFee) {
      return { deliveryFeeDelta: 0, freedDriverIds: [] };
    }

    await tx.orderDeliveryGroup.update({
      where: { id: deliveryGroupId },
      data: { deliveryFee: newFee },
    });
    return {
      deliveryFeeDelta: newFee - group.deliveryFee,
      freedDriverIds: [],
    };
  }

  /**
   * Reduce order money by the rejected portion.
   *
   * The delivery fee drops only when the delivery itself shrank (a cancelled
   * delivery, or one with fewer vendors riding along) — the caller passes that
   * as `deliveryFeeDelta`. The service fee drops by exactly the rejected
   * vendor's commission, and only when that vendor was uncontracted (contracted
   * vendors' commission is never part of the customer-facing service fee).
   */
  async recomputeTotalsAfterRejection(
    orderId: string,
    rejectedAmount: number,
    deliveryFeeDelta = 0,
    serviceFeeDelta = 0,
    fulfillmentId?: string,
  ): Promise<void> {
    if (rejectedAmount <= 0 && deliveryFeeDelta === 0 && serviceFeeDelta === 0) {
      return;
    }

    const settings = await this.platformSettings.getSettings();
    const coinValue = Number(settings.coinValue) || 0;
    const amountSpentPerCoin = Number(settings.amountSpentPerCoin) || 0;

    await this.prisma.$transaction(async (tx) => {
      // Serialize every money mutation for this order (cancel, rejection,
      // payment settlement). Without this a rejection racing a cancellation
      // could each read the pre-change totals and refund the same money twice.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('order-money:' || ${orderId}::text))`;

      const order = await tx.order.findUnique({
        where: { id: orderId },
        select: {
          status: true,
          subtotal: true,
          serviceFee: true,
          tax: true,
          deliveryFee: true,
          driverBonusFee: true,
          discount: true,
          coinsUsed: true,
          coinsEarned: true,
          grandTotal: true,
          upfrontAmount: true,
          paymentMethod: true,
          paymentStatus: true,
          customerId: true,
          orderNumber: true,
        },
      });
      if (!order) return;

      const customerBonusFee = Boolean(settings.driverBonusPaidByCustomer)
        ? order.driverBonusFee
        : 0;
      const newSubtotal = Math.max(0, order.subtotal - rejectedAmount);
      const newDeliveryFee = Math.max(0, order.deliveryFee + deliveryFeeDelta);
      const newServiceFee = Math.max(0, order.serviceFee + serviceFeeDelta);
      // Tax was charged on (subtotal + serviceFee); re-derive it from the order's
      // own implied rate so the untouched portion keeps its original basis even if
      // the platform rate changed since checkout.
      const taxableBase = order.subtotal + order.serviceFee;
      const impliedTaxRate = taxableBase > 0 ? order.tax / taxableBase : 0;
      const newTax = Math.max(
        0,
        Math.round((newSubtotal + newServiceFee) * impliedTaxRate),
      );

      const oldPreDiscount =
        order.subtotal +
        order.deliveryFee +
        customerBonusFee +
        order.serviceFee +
        order.tax;
      const newPreDiscount =
        newSubtotal +
        newDeliveryFee +
        customerBonusFee +
        newServiceFee +
        newTax;

      // The discount was earned against the original basket, so the part that
      // covered the rejected items must leave with them. Keeping the full
      // discount while shrinking the subtotal would let the customer keep a
      // discount (and the coins paid for it) on food they never received.
      const newDiscount =
        oldPreDiscount > 0
          ? Math.min(
              newPreDiscount,
              Math.round((order.discount * newPreDiscount) / oldPreDiscount),
            )
          : 0;
      const newGrandTotal = Math.max(0, newPreDiscount - newDiscount);
      const newUpfront =
        order.upfrontAmount > 0
          ? Math.min(order.upfrontAmount, newGrandTotal)
          : order.upfrontAmount;
      // Earned coins track the money actually kept, so a rejection also claws
      // back the coins the customer would have earned on the removed items.
      const newCoinsEarned =
        amountSpentPerCoin > 0
          ? Math.floor(newGrandTotal / amountSpentPerCoin)
          : 0;

      const updated = await tx.order.updateMany({
        where: { id: orderId },
        data: {
          subtotal: newSubtotal,
          deliveryFee: newDeliveryFee,
          serviceFee: newServiceFee,
          tax: newTax,
          discount: newDiscount,
          coinsEarned: newCoinsEarned,
          grandTotal: newGrandTotal,
          upfrontAmount: newUpfront,
          revision: { increment: 1 },
        },
      });
      if (updated.count === 0) return;

      // Give back the coins that paid for the discount we just released.
      // `coinsUsed` stays as the historical amount spent; the ledger keeps a
      // single accumulating REFUNDED row per order (unique orderId+type), and
      // a later cancellation only refunds the remainder.
      const discountReleased = order.discount - newDiscount;
      const refundedAgg = await tx.customerCoinTransaction.aggregate({
        where: { orderId, type: 'REFUNDED' },
        _sum: { amount: true },
      });
      const alreadyRefunded = Number(refundedAgg._sum.amount ?? 0);
      const coinsForReleasedDiscount =
        coinValue > 0 ? Math.floor(discountReleased / coinValue) : 0;
      const coinsToRefund = Math.max(
        0,
        Math.min(order.coinsUsed - alreadyRefunded, coinsForReleasedDiscount),
      );

      if (coinsToRefund > 0) {
        await tx.$executeRaw`SELECT id FROM customers WHERE id = ${order.customerId} FOR UPDATE`;
        const customer = await tx.customer.update({
          where: { id: order.customerId },
          data: { coinBalance: { increment: coinsToRefund } },
          select: { coinBalance: true },
        });
        await tx.customerCoinTransaction.upsert({
          where: { orderId_type: { orderId, type: 'REFUNDED' } },
          create: {
            customerId: order.customerId,
            orderId,
            type: 'REFUNDED',
            amount: coinsToRefund,
            balanceAfter: customer.coinBalance,
            description: `Refund for rejected items on order ${order.orderNumber}`,
          },
          update: {
            amount: { increment: coinsToRefund },
            balanceAfter: customer.coinBalance,
          },
        });
      }

      // Record the money movement on the order timeline so finance can audit it.
      const parts: string[] = [];
      if (rejectedAmount > 0) parts.push(`${rejectedAmount} EGP of food`);
      if (deliveryFeeDelta !== 0)
        parts.push(`${Math.abs(deliveryFeeDelta)} EGP of delivery fee`);
      if (parts.length > 0) {
        await recordOrderStatusEventIdempotent(tx, {
          orderId,
          fulfillmentId: fulfillmentId ?? null,
          eventKey: fulfillmentId ? `portion_rejected:${fulfillmentId}` : null,
          status: order.status,
          note: `Vendor portion rejected — removed ${parts.join(' and ')} from the order`,
          createdBy: 'system',
          actor: systemActorSnapshot(),
        });
      }

      // Prepaid / upfront-paid orders may now owe the customer real money back.
      // There is no dedicated customer cash-wallet model, so any overpayment is
      // written onto the order timeline for finance to settle (notification
      // listener also informs the customer).
      //
      // For COD orders, `paymentStatus` can become COMPLETED once the upfront
      // deposit is confirmed, so only `upfrontAmount - newGrandTotal` (when
      // reduced below the paid deposit) was actually pre-collected.
      if (order.paymentStatus === 'PAID' || order.paymentStatus === 'COMPLETED') {
        const alreadyPaidCash =
          order.paymentMethod === 'CASH_ON_DELIVERY'
            ? order.upfrontAmount
            : order.grandTotal;
        const cashRefundOwed = Math.max(0, alreadyPaidCash - newGrandTotal);
        if (cashRefundOwed > 0) {
          await recordOrderStatusEventIdempotent(tx, {
            orderId,
            fulfillmentId: fulfillmentId ?? null,
            eventKey: fulfillmentId ? `refund_obligation:${fulfillmentId}` : null,
            status: order.status,
            note: `Refund obligation: ${cashRefundOwed} EGP owed to customer after portion rejection (payment already ${order.paymentStatus})`,
            createdBy: 'system',
            actor: systemActorSnapshot(),
          });
        }
      }
    });
  }
}
