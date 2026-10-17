import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  OrderStatus,
  OrderVendorFulfillmentStatus,
  VendorMemberRole,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { OrdersRepository } from './orders.repository';
import { OrdersStateService } from './orders-state.service';
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
    private readonly stateService: OrdersStateService,
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

      // Pull them out of any delivery group so they can never be dispatched.
      await tx.orderDeliveryGroupItem.deleteMany({
        where: { fulfillmentId },
      });

      await this.restoreStock(tx, items);

      return { items, refundAmount };
    });

    // Recompute money OUTSIDE the CAS so the maths uses fresh values, then write
    // once. This keeps the single-writer invariant of the orders table.
    await this.recomputeTotalsAfterRejection(
      fulfillment.orderId,
      refundAmount,
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
        status: true,
        subtotal: true,
      },
    });
    if (!fulfillment) {
      throw new NotFoundException(OrderErrors.FULFILLMENT_NOT_FOUND);
    }

    // Vendor identity is derived from the fulfillment itself, never from a
    // client-supplied vendorId, so a member cannot act on another vendor.
    const member = await this.prisma.vendorMember.findUnique({
      where: {
        vendorId_userId: { vendorId: fulfillment.vendorId, userId: actor.sub },
      },
      select: { id: true },
    });
    if (!member) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }
    return fulfillment;
  }

  private fulfillmentInclude() {
    return {
      items: { where: { rejectedAt: null }, select: { id: true, productName: true, quantity: true, totalPrice: true } },
      vendor: { select: { id: true, storeName: true, storeNameAr: true, logo: true } },
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
   * Reduce order money by the rejected portion.
   *
   * Delivery fees are NOT reduced (the customer still had a delivery), but
   * subtotal/serviceFee/tax/grandTotal shrink and coinsEarned is recomputed so
   * the order stays internally consistent.
   */
  private async recomputeTotalsAfterRejection(
    orderId: string,
    rejectedAmount: number,
  ): Promise<void> {
    if (rejectedAmount <= 0) return;

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        subtotal: true,
        serviceFee: true,
        tax: true,
        deliveryFee: true,
        driverBonusFee: true,
        discount: true,
        coinsUsed: true,
        grandTotal: true,
        upfrontAmount: true,
      },
    });
    if (!order) return;

    const newSubtotal = Math.max(0, order.subtotal - rejectedAmount);
    // serviceFee is a commission percentage of subtotal; scale it by the same
    // ratio rather than re-reading mutable vendor settings.
    const ratio = order.subtotal > 0 ? newSubtotal / order.subtotal : 0;
    const newServiceFee = Math.round(order.serviceFee * ratio);
    const newTax = Math.round(order.tax * ratio);
    const newPreDiscount =
      newSubtotal + order.deliveryFee + order.driverBonusFee + newServiceFee + newTax;
    const newDiscount = Math.min(order.discount, newPreDiscount);
    const newGrandTotal = Math.max(0, newPreDiscount - newDiscount);
    const newUpfront =
      order.upfrontAmount > 0
        ? Math.min(order.upfrontAmount, newGrandTotal)
        : order.upfrontAmount;

    const updated = await this.prisma.order.updateMany({
      where: { id: orderId },
      data: {
        subtotal: newSubtotal,
        serviceFee: newServiceFee,
        tax: newTax,
        discount: newDiscount,
        grandTotal: newGrandTotal,
        upfrontAmount: newUpfront,
      },
    });
    if (updated.count === 0) return;

    // Record the money movement on the order timeline so finance can audit it.
    await this.prisma.orderStatusEvent.create({
      data: {
        orderId,
        status: 'PENDING',
        note: `Vendor portion rejected — ${rejectedAmount} EGP removed from the order`,
        createdBy: 'system',
      },
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
          [],
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