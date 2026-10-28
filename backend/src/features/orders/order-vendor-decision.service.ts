import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Prisma,
  VendorMemberRole,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { OrdersRepository } from './orders.repository';
import { OrdersStateService } from './orders-state.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrderErrors } from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  OrderFulfillmentDecidedEvent,
  OrderStatusChangedEvent,
  OrderVendorRejectedEvent,
} from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';

export interface RejectFulfillmentDto {
  /** Machine-readable reason code (enum on the client, stable for analytics). */
  code: string;
  reason: string;
  reasonAr?: string;
}

/**
 * Per-vendor decisions on a customer order.
 *
 * Each vendor accepts or rejects only its own `OrderVendorFulfillment`; other
 * vendors' portions are never touched. Rejection never deletes rows: the items
 * are stamped `rejectedAt` (auditable) and the customer's money is reduced by
 * the rejected portion, per the agreed "refund the rejected portion" rule.
 */
@Injectable()
export class OrderVendorDecisionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ordersRepository: OrdersRepository,
    @Inject(forwardRef(() => OrdersStateService))
    private readonly stateService: OrdersStateService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // ─── Vendor workflow ───────────────────────────────────────────────────────

  async accept(
    actor: JwtAccessPayload,
    fulfillmentId: string,
  ) {
    const fulfillment = await this.assertVendorMember(
      actor,
      fulfillmentId,
    );

    if (fulfillment.status !== OrderVendorFulfillmentStatus.PENDING) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    const claimed = await this.prisma.orderVendorFulfillment.updateMany({
      where: { id: fulfillmentId, status: OrderVendorFulfillmentStatus.PENDING },
      data: {
        status: OrderVendorFulfillmentStatus.ACCEPTED,
        decidedByUserId: actor.sub,
        decidedAt: new Date(),
        rejectionCode: null,
        rejectionReason: null,
        rejectionReasonAr: null,
      },
    });
    if (claimed.count === 0) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    await this.emitDecided(
      fulfillment,
      OrderVendorFulfillmentStatus.ACCEPTED,
      actor.sub,
    );
    await this.maybeAdvanceToDispatch(fulfillment.orderId);
    return this.findById(fulfillmentId);
  }

  /**
   * Reject only this vendor's portion:
   *  - stamp the vendor portion REJECTED with an auditable reason;
   *  - stamp its items `rejectedAt` (never delete — audit trail + original
   *    price snapshot must survive);
   *  - restore their stock like a cancellation does;
   *  - never dispatch them;
   *  - reduce the customer's totals by the rejected portion and emit a single
   *    customer notification naming the vendor, items and reason.
   */
  async reject(
    actor: JwtAccessPayload,
    fulfillmentId: string,
    dto: RejectFulfillmentDto,
  ) {
    const fulfillment = await this.assertVendorMember(
      actor,
      fulfillmentId,
    );

    if (fulfillment.status !== OrderVendorFulfillmentStatus.PENDING) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    const reason = dto.reason?.trim();
    if (!reason) {
      throw new BadRequestException(OrderErrors.REJECTION_REASON_REQUIRED);
    }

    const order = await this.prisma.order.findUnique({
      where: { id: fulfillment.orderId },
      select: {
        id: true,
        orderNumber: true,
        customerId: true,
        customer: { select: { userId: true } },
        status: true,
        paymentMethod: true,
        paymentStatus: true,
      },
    });
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);

    const items = await this.prisma.orderItem.findMany({
      where: { fulfillmentId, rejectedAt: null },
      select: {
        id: true,
        productId: true,
        variantId: true,
        quantity: true,
        selectedUnit: true,
        totalPrice: true,
        productName: true,
        product: { select: { tracksStock: true, stripsPerPackage: true } },
        variant: { select: { tracksStock: true } },
      },
    });

    const refundAmount = items.reduce((sum, i) => sum + i.totalPrice, 0);

    // Extra-vendor surcharge released when this portion leaves its delivery.
    const settings = await this.platformSettings.getSettings();
    const extraVendorFee = Number(
      settings.extraVendorDeliveryFee ?? Math.round(Number(settings.minDeliveryFee ?? 0) / 2),
    );

    // The customer pays commission as a service fee only for UNCONTRACTED
    // vendors, so rejecting a contracted vendor must not reduce it.
    const rejectedVendor = await this.prisma.vendor.findUnique({
      where: { id: fulfillment.vendorId },
      select: { isContracted: true },
    });
    const rejectedBranch = fulfillment.vendorBranchId
      ? await this.prisma.vendorBranch.findUnique({
          where: { id: fulfillment.vendorBranchId },
          select: { isContracted: true },
        })
      : null;
    const isContracted =
      rejectedBranch?.isContracted != null
        ? rejectedBranch.isContracted
        : (rejectedVendor?.isContracted ?? false);
    const serviceFeeDelta = isContracted
      ? 0
      : -Math.round(refundAmount * (fulfillment.commissionRate / 100));

    const result = await this.prisma.$transaction(async (tx) => {
      const claimed = await tx.orderVendorFulfillment.updateMany({
        where: {
          id: fulfillmentId,
          status: OrderVendorFulfillmentStatus.PENDING,
        },
        data: {
          status: OrderVendorFulfillmentStatus.REJECTED,
          decidedByUserId: actor.sub,
          decidedAt: new Date(),
          rejectionCode: dto.code,
          rejectionReason: reason,
          rejectionReasonAr: dto.reasonAr?.trim() || null,
        },
      });
      if (claimed.count === 0) {
        throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
      }

      // Auditable: keep the rows, mark them rejected.
      await tx.orderItem.updateMany({
        where: { fulfillmentId, rejectedAt: null },
        data: { rejectedAt: new Date() },
      });

      // Which delivery was this portion riding on, before it is removed?
      const ridingGroup = await tx.orderDeliveryGroupItem.findFirst({
        where: { fulfillmentId },
        select: { deliveryGroupId: true },
      });

      // Pull them out of any delivery group so they can never be dispatched.
      await tx.orderDeliveryGroupItem.deleteMany({
        where: { fulfillmentId },
      });

      // Losing a vendor can cancel its whole delivery (nobody left to pick up
      // from) or merely release that vendor's extra-stop surcharge.
      const deliveryFeeDelta = ridingGroup
        ? await this.syncDeliveryGroupAfterVendorRemoved(
            tx,
            ridingGroup.deliveryGroupId,
            fulfillment.orderId,
            order.status,
            extraVendorFee,
          )
        : 0;

      await this.restoreStock(tx, items);

      return {
        items,
        refundAmount,
        deliveryFeeDelta,
        ridingGroupId: ridingGroup?.deliveryGroupId ?? null,
      };
    });

    // Recompute the money under the order-money advisory lock so a concurrent
    // cancellation or second rejection cannot double-refund the same portion.
    await this.recomputeTotalsAfterRejection(
      fulfillment.orderId,
      refundAmount,
      result.deliveryFeeDelta,
      serviceFeeDelta,
    );

    const allRejected = await this.recomputeOrderStatus(fulfillment.orderId);

    if (allRejected) {
      // Every vendor said no → reuse the existing cancellation/refund workflow
      // (coins refunded, stock restored, dispatch cancelled) rather than
      // leaving an invalid active order behind.
      await this.stateService.cancelOrder(
        null,
        fulfillment.orderId,
        'All vendors rejected their portions',
      );
    } else {
      // A rejected portion can be the last thing keeping its delivery from
      // being ready (a sibling portion was already declared ready, and this
      // one just left the group). Re-check before dispatch handoff: otherwise
      // the delivery stays DRIVER_ASSIGNED and its driver can never pass the
      // "ready for pickup" gate.
      if (result.ridingGroupId) {
        await this.stateService.syncGroupReadinessAfterPortionRemoved(
          fulfillment.orderId,
          result.ridingGroupId,
          actor.sub,
        );
      }
      // A portion may have been rejected while others are already accepted and
      // none are still pending — start the driver search in that case.
      await this.maybeAdvanceToDispatch(fulfillment.orderId);
    }

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: fulfillment.vendorId },
      select: {
        storeName: true,
        storeNameAr: true,
        members: { where: { role: VendorMemberRole.OWNER }, select: { userId: true } },
      },
    });

    this.eventEmitter.emit(
      EVENTS.ORDER_VENDOR_REJECTED,
      new OrderVendorRejectedEvent(
        fulfillment.orderId,
        order.orderNumber,
        order.customerId,
        order.customer.userId,
        fulfillmentId,
        fulfillment.vendorId,
        vendor?.storeName ?? '',
        vendor?.storeNameAr ?? null,
        dto.code,
        reason,
        dto.reasonAr?.trim() || null,
        result.items.map((i) => i.productName),
        refundAmount,
        allRejected,
        actor.sub,
      ),
    );

    return this.findById(fulfillmentId);
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  /**
   * Portions this vendor still has to answer, across every vendor the caller
   * is a member of. The vendor set is resolved from membership, never from a
   * client-supplied id.
   */
  async listPendingForVendor(actor: JwtAccessPayload) {
    const memberships = await this.prisma.vendorMember.findMany({
      where: { userId: actor.sub },
      select: { vendorId: true, branchId: true, role: true },
    });
    if (memberships.length === 0) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    const vendorIds = memberships.map((m) => m.vendorId);
    return this.prisma.orderVendorFulfillment.findMany({
      where: {
        vendorId: { in: vendorIds },
        status: OrderVendorFulfillmentStatus.PENDING,
        order: { status: { notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED] } },
      },
      orderBy: { createdAt: 'desc' },
      include: this.fulfillmentInclude(),
    });
  }

  async listForVendor(actor: JwtAccessPayload, vendorId: string) {
    const member = await this.prisma.vendorMember.findUnique({
      where: { vendorId_userId: { vendorId, userId: actor.sub } },
      select: { id: true },
    });
    if (!member) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    return this.prisma.orderVendorFulfillment.findMany({
      where: { vendorId },
      orderBy: { createdAt: 'desc' },
      include: this.fulfillmentInclude(),
    });
  }

  async listForOrder(orderId: string) {
    return this.prisma.orderVendorFulfillment.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
      include: this.fulfillmentInclude(),
    });
  }

  async findById(fulfillmentId: string) {
    const row = await this.prisma.orderVendorFulfillment.findUnique({
      where: { id: fulfillmentId },
      include: this.fulfillmentInclude(),
    });
    if (!row) {
      throw new NotFoundException(OrderErrors.FULFILLMENT_NOT_FOUND);
    }
    return row;
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  private async assertVendorMember(actor: JwtAccessPayload, fulfillmentId: string) {
    const fulfillment = await this.prisma.orderVendorFulfillment.findUnique({
      where: { id: fulfillmentId },
      select: {
        id: true,
        orderId: true,
        vendorId: true,
        vendorBranchId: true,
        status: true,
        subtotal: true,
        commissionRate: true,
      },
    });
    if (!fulfillment) {
      throw new NotFoundException(OrderErrors.FULFILLMENT_NOT_FOUND);
    }

    // Vendor identity is derived from the fulfillment itself, never from a
    // client-supplied vendorId, so a member cannot act on another vendor.
    if (actor.role !== 'ADMIN' && actor.role !== 'SUPER_ADMIN') {
      const member = await this.prisma.vendorMember.findUnique({
        where: {
          vendorId_userId: { vendorId: fulfillment.vendorId, userId: actor.sub },
        },
        select: { id: true },
      });
      if (!member) {
        throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
      }
    }
    return fulfillment;
  }

  private fulfillmentInclude() {
    return {
      items: { where: { rejectedAt: null }, select: { id: true, productName: true, quantity: true, totalPrice: true } },
      vendor: { select: { id: true, storeName: true, storeNameAr: true, logo: true } },
      vendorBranch: {
        select: {
          id: true,
          name: true,
          nameAr: true,
          address: true,
          phone: true,
          isContracted: true,
        },
      },
      groups: {
        select: {
          deliveryGroup: {
            select: { id: true, sequence: true, status: true, primaryDriverId: true, assistDriverId: true },
          },
        },
      },
    };
  }

  private async emitDecided(
    fulfillment: { id: string; orderId: string; vendorId: string },
    status: OrderVendorFulfillmentStatus,
    actorUserId: string,
  ): Promise<void> {
    const [order, vendorUserIds] = await Promise.all([
      this.prisma.order.findUnique({
        where: { id: fulfillment.orderId },
        select: {
          orderNumber: true,
          customerId: true,
          customer: { select: { userId: true } },
        },
      }),
      this.ordersRepository.getVendorUserIds(fulfillment.vendorId),
    ]);
    if (!order) return;

    this.eventEmitter.emit(
      EVENTS.ORDER_FULFILLMENT_DECIDED,
      new OrderFulfillmentDecidedEvent(
        fulfillment.orderId,
        order.orderNumber,
        order.customerId,
        order.customer.userId,
        fulfillment.id,
        fulfillment.vendorId,
        vendorUserIds,
        status,
        actorUserId,
      ),
    );
  }

  /** Restore variant/product stock exactly like OrdersRepository.cancelOrder. */
  private async restoreStock(
    tx: any,
    items: Array<{
      productId: string | null;
      variantId: string | null;
      quantity: number;
      selectedUnit: string | null;
      product: { tracksStock: boolean; stripsPerPackage: number | null } | null;
      variant: { tracksStock: boolean } | null;
    }>,
  ): Promise<void> {
    for (const item of items) {
      if (item.quantity <= 0) continue;
      if (item.variantId && item.variant?.tracksStock) {
        await tx.$executeRaw`
          UPDATE product_variants SET stock = stock + ${item.quantity}
          WHERE id = ${item.variantId} AND stock IS NOT NULL
        `;
      }
      if (item.productId && item.product?.tracksStock) {
        const strips = item.selectedUnit === 'strip';
        const per = strips ? (item.product.stripsPerPackage ?? 1) : 1;
        const qty = Math.ceil(item.quantity / per);
        await tx.$executeRaw`
          UPDATE products SET stock = stock + ${qty}
          WHERE id = ${item.productId} AND stock IS NOT NULL
        `;
      }
    }
  }

  /**
   * Cancel a delivery that has lost its last vendor, or release the
   * extra-vendor surcharge when it still has someone to pick up from.
   *
   * An empty delivery can never be dispatched, and because the aggregate order
   * status is derived from "every non-cancelled delivery is delivered", leaving
   * it non-terminal stranded the order at PICKED_UP forever. Cancelling it here
   * is what lets the order reach DELIVERED once the surviving deliveries finish.
   *
   * Returns the change to the ORDER-level delivery fee so the caller can apply
   * it in the single order-level write.
   */
  private async syncDeliveryGroupAfterVendorRemoved(
    tx: Prisma.TransactionClient,
    deliveryGroupId: string,
    orderId: string,
    orderStatus: OrderStatus,
    extraVendorFee: number,
  ): Promise<number> {
    const group = await tx.orderDeliveryGroup.findUnique({
      where: { id: deliveryGroupId },
      select: { deliveryFee: true, sequence: true, primaryDriverId: true },
    });
    if (!group) return 0;

    const remaining = await tx.orderDeliveryGroupItem.count({
      where: { deliveryGroupId },
    });

    if (remaining === 0) {
      // Nobody left to pick up from. Only ever cancel a delivery no driver has
      // taken (a driver can only take a group after every portion was decided,
      // so a group still losing vendors is always unassigned).
      const cancelled = await tx.orderDeliveryGroup.updateMany({
        where: {
          id: deliveryGroupId,
          status: { not: DeliveryGroupStatus.CANCELLED },
          primaryDriverId: null,
        },
        data: { status: DeliveryGroupStatus.CANCELLED, deliveryFee: 0 },
      });
      if (cancelled.count === 0) return 0;

      await tx.orderStatusEvent.create({
        data: {
          orderId,
          status: orderStatus,
          note: `Delivery ${group.sequence} cancelled — no vendors accepted`,
          createdBy: 'system',
        },
      });
      return -group.deliveryFee;
    }

    // One fewer vendor rides along — drop that vendor's extra-stop surcharge.
    const newFee = Math.max(0, Math.round(group.deliveryFee - extraVendorFee));
    if (newFee === group.deliveryFee) return 0;

    await tx.orderDeliveryGroup.update({
      where: { id: deliveryGroupId },
      data: { deliveryFee: newFee },
    });
    return newFee - group.deliveryFee;
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
  private async recomputeTotalsAfterRejection(
    orderId: string,
    rejectedAmount: number,
    deliveryFeeDelta = 0,
    serviceFeeDelta = 0,
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
          paymentStatus: true,
          customerId: true,
          orderNumber: true,
        },
      });
      if (!order) return;

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
        order.driverBonusFee +
        order.serviceFee +
        order.tax;
      const newPreDiscount =
        newSubtotal +
        newDeliveryFee +
        order.driverBonusFee +
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
        await tx.orderStatusEvent.create({
          data: {
            orderId,
            status: order.status,
            note: `Vendor portion rejected — removed ${parts.join(' and ')} from the order`,
            createdBy: 'system',
          },
        });
      }

      // Prepaid orders now owe the customer real money back. There is no
      // dedicated refund model, so the obligation is written onto the order
      // timeline for finance to settle (the notification listener also tells
      // the customer the amount).
      //
      // `grandTotal` is the cash the customer paid after the coin discount, so
      // the cash refund is simply the drop in grandTotal. The coins that paid
      // for the released part of the discount are refunded separately above —
      // they are a different currency and must not be deducted from the cash
      // owed, or a prepaid customer would be short-changed by the coin value.
      if (order.paymentStatus === 'PAID' || order.paymentStatus === 'COMPLETED') {
        const cashRefundOwed = Math.max(0, order.grandTotal - newGrandTotal);
        if (cashRefundOwed > 0) {
          await tx.orderStatusEvent.create({
            data: {
              orderId,
              status: order.status,
              note: `Refund obligation: ${cashRefundOwed} EGP owed to customer after portion rejection (payment already ${order.paymentStatus})`,
              createdBy: 'system',
            },
          });
        }
      }
    });
  }

  /**
   * Recompute the customer-facing order status from its portions.
   * Returns true when every portion is rejected/cancelled (→ cancel the order).
   */
  private async recomputeOrderStatus(orderId: string): Promise<boolean> {
    const portions = await this.prisma.orderVendorFulfillment.findMany({
      where: { orderId },
      select: { status: true },
    });
    if (portions.length === 0) return false;

    const allDead = portions.every(
      (p) =>
        p.status === OrderVendorFulfillmentStatus.REJECTED ||
        p.status === OrderVendorFulfillmentStatus.CANCELLED,
    );
    if (allDead) return true;

    // Some portion is still awaiting a vendor decision. Only walk the order back to
    // PENDING while it is still in a pre-fulfilment state — never resurrect an
    // order that is already being prepared, dispatched or delivered, because
    // that would strand the vendors/drivers that already committed.
    const anyPending = portions.some(
      (p) => p.status === OrderVendorFulfillmentStatus.PENDING,
    );
    const REOPENABLE: OrderStatus[] = [
      OrderStatus.PENDING,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.LOOKING_FOR_DRIVER,
    ];
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (anyPending && order && REOPENABLE.includes(order.status)) {
      await this.ordersRepository.updateStatus(orderId, 'PENDING', 'system');
    }
    return false;
  }

  /**
   * Once every vendor portion has been answered (none left PENDING) and at
   * least one was accepted, move the ORDER into the driver-search state so the
   * dispatch handoff runs. A multi-vendor order is then dispatched one round
   * per delivery group by the handoff, so this only flips the order status once.
   *
   * Guarded and best-effort: a concurrent decision that already advanced the
   * order makes this a no-op rather than an error.
   */
  private async maybeAdvanceToDispatch(orderId: string): Promise<void> {
    const portions = await this.prisma.orderVendorFulfillment.findMany({
      where: { orderId },
      select: { status: true },
    });
    if (portions.length === 0) return;

    const anyPending = portions.some(
      (p) => p.status === OrderVendorFulfillmentStatus.PENDING,
    );
    const anyAccepted = portions.some(
      (p) => p.status === OrderVendorFulfillmentStatus.ACCEPTED,
    );
    if (anyPending || !anyAccepted) return;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        status: true,
        customer: { select: { userId: true } },
      },
    });
    if (!order) return;

    const advanceable: OrderStatus[] = [
      OrderStatus.PENDING,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
    ];
    if (!advanceable.includes(order.status)) return;

    try {
      const updated = await this.ordersRepository.updateStatus(
        orderId,
        OrderStatus.LOOKING_FOR_DRIVER,
        'system',
        'All vendor portions decided — searching for drivers',
        undefined,
        order.status,
      );

      const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
        orderId,
        updated.vendorId,
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          updated.id,
          updated.orderNumber,
          order.status,
          OrderStatus.LOOKING_FOR_DRIVER,
          updated.customerId,
          order.customer.userId,
          updated.vendorId,
          vendorUserIds,
          updated.driverId,
          updated.driver?.userId ?? null,
          'system',
          'All vendor portions decided — searching for drivers',
        ),
      );
    } catch {
      // Lost a race with another decision or flow that already advanced it.
    }
  }
}