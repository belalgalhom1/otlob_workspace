import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
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
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrderErrors } from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  OrderFulfillmentDecidedEvent,
  OrderStatusChangedEvent,
  OrderVendorRejectedEvent,
} from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { StockService } from './helpers/stock.service';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderRejectionRecomputor } from './helpers/order-rejection-recomputor';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import { sanitizeCancelReason } from './helpers/order-actor.helper';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';

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
  private readonly logger = new Logger(OrderVendorDecisionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ordersRepository: OrdersRepository,
    private readonly cancellationService: OrderCancellationService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    @Optional()
    private readonly fulfillmentTransitions?: FulfillmentTransitionService,
    @Optional()
    private readonly deliveryGroupTransitions?: DeliveryGroupTransitionService,
    @Optional() private readonly stockService?: StockService,
    @Optional() private readonly authHelper?: OrderAuthorizationHelper,
    @Optional() private readonly rejectionRecomputor?: OrderRejectionRecomputor,
  ) {}

  private get stock(): StockService {
    return this.stockService ?? new StockService();
  }

  private get auth(): OrderAuthorizationHelper {
    return this.authHelper ?? new OrderAuthorizationHelper(this.prisma);
  }

  private get recomputor(): OrderRejectionRecomputor {
    return (
      this.rejectionRecomputor ??
      new OrderRejectionRecomputor(this.prisma, this.platformSettings)
    );
  }

  // ─── Vendor workflow ───────────────────────────────────────────────────────

  async accept(actor: JwtAccessPayload, fulfillmentId: string) {
    const fulfillment = await this.assertVendorMember(actor, fulfillmentId);

    const order = await this.prisma.order.findUnique({
      where: { id: fulfillment.orderId },
      select: { status: true },
    });
    if (
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED
    ) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    if (fulfillment.status !== OrderVendorFulfillmentStatus.PENDING) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    const claimed = await this.prisma.orderVendorFulfillment.updateMany({
      where: {
        id: fulfillmentId,
        status: OrderVendorFulfillmentStatus.PENDING,
      },
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

    this.logger.log(
      `Fulfillment ${fulfillmentId} for order ${fulfillment.orderId} ACCEPTED by ${actor.sub}`,
    );

    await this.maybeAdvanceToDispatch(fulfillment.orderId);
    await this.emitDecided(
      fulfillment,
      OrderVendorFulfillmentStatus.ACCEPTED,
      actor.sub,
    );
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
    actor: JwtAccessPayload | null,
    fulfillmentId: string,
    dto: RejectFulfillmentDto,
  ) {
    const actorSub = actor?.sub ?? 'system';
    const fulfillment = await this.assertVendorMember(actor, fulfillmentId);

    const rejectableStatuses: OrderVendorFulfillmentStatus[] = [
      OrderVendorFulfillmentStatus.PENDING,
      OrderVendorFulfillmentStatus.ACCEPTED,
      OrderVendorFulfillmentStatus.PREPARING,
      OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
    ];
    if (
      !rejectableStatuses.includes(fulfillment.status) ||
      fulfillment.pickedUpAt != null
    ) {
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
    if (
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED
    ) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    const items = await this.prisma.orderItem.findMany({
      where: { fulfillmentId, rejectedAt: null },
      select: {
        id: true,
        productId: true,
        variantId: true,
        variantName: true,
        quantity: true,
        selectedUnit: true,
        totalPrice: true,
        productName: true,
        product: {
          select: {
            hasVariants: true,
            tracksStock: true,
            sellByStrip: true,
            stripsPerPackage: true,
          },
        },
        variant: { select: { tracksStock: true } },
      },
    });

    const refundAmount = items.reduce((sum, i) => sum + i.totalPrice, 0);

    // The customer pays commission as a service fee only for UNCONTRACTED
    // vendors, so rejecting a contracted vendor must not reduce it.
    let isContracted: boolean;
    if (
      (fulfillment as { isContracted?: boolean | null }).isContracted != null
    ) {
      isContracted = Boolean(
        (fulfillment as { isContracted?: boolean | null }).isContracted,
      );
    } else {
      const [rejectedVendor, rejectedBranch] = await Promise.all([
        this.prisma.vendor.findUnique({
          where: { id: fulfillment.vendorId },
          select: { isContracted: true },
        }),
        fulfillment.vendorBranchId
          ? this.prisma.vendorBranch.findUnique({
              where: { id: fulfillment.vendorBranchId },
              select: { isContracted: true },
            })
          : Promise.resolve(null),
      ]);
      isContracted =
        rejectedBranch?.isContracted != null
          ? rejectedBranch.isContracted
          : (rejectedVendor?.isContracted ?? false);
    }
    const serviceFeeDelta = isContracted
      ? 0
      : -Math.round(refundAmount * (fulfillment.commissionRate / 100));

    const result = await this.prisma.$transaction(async (tx) => {
      const claimed = await tx.orderVendorFulfillment.updateMany({
        where: {
          id: fulfillmentId,
          status: { in: rejectableStatuses },
          pickedUpAt: null,
        },
        data: {
          status: OrderVendorFulfillmentStatus.REJECTED,
          decidedByUserId: actorSub,
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
      // from) or dynamically recompute the delivery fee for remaining vendor stops.
      const groupSync = ridingGroup
        ? await this.recomputor.syncDeliveryGroupAfterVendorRemoved(
            tx,
            ridingGroup.deliveryGroupId,
            fulfillment.orderId,
            order.status,
          )
        : { deliveryFeeDelta: 0, freedDriverIds: [] as string[] };

      await this.stock.restoreForItems(tx, items);

      return {
        items,
        refundAmount,
        deliveryFeeDelta: groupSync.deliveryFeeDelta,
        freedDriverIds: groupSync.freedDriverIds,
        ridingGroupId: ridingGroup?.deliveryGroupId ?? null,
      };
    });

    await Promise.all(
      Array.from(new Set(result.freedDriverIds)).map((driverId) =>
        this.ordersRepository.freeDriver(driverId),
      ),
    );

    // Recompute the money under the order-money advisory lock so a concurrent
    // cancellation or second rejection cannot double-refund the same portion.
    await this.recomputor.recomputeTotalsAfterRejection(
      fulfillment.orderId,
      refundAmount,
      result.deliveryFeeDelta,
      serviceFeeDelta,
      fulfillmentId,
    );

    this.logger.log(
      `Fulfillment ${fulfillmentId} for order ${fulfillment.orderId} REJECTED by ${actorSub} (${dto.code})`,
    );

    const allRejected = await this.recomputeOrderStatus(fulfillment.orderId);

    if (allRejected) {
      // Every vendor said no → reuse the existing cancellation/refund workflow
      // (coins refunded, stock restored, dispatch cancelled) rather than
      // leaving an invalid active order behind. Guard against two simultaneous
      // rejections/timeouts both entering `cancelOrder` at the same time.
      const cancelReason =
        sanitizeCancelReason(reason) ?? 'All vendors rejected their portions';
      try {
        await this.cancellationService.cancelOrder(
          actor,
          fulfillment.orderId,
          cancelReason,
          { vendorId: fulfillment.vendorId },
        );
      } catch (err) {
        const latest = await this.prisma.order.findUnique({
          where: { id: fulfillment.orderId },
          select: { status: true },
        });
        if (latest?.status !== OrderStatus.CANCELLED) {
          throw err;
        }
      }
    } else {
      // A rejected portion can be the last thing keeping its delivery from
      // being ready (a sibling portion was already declared ready, and this
      // one just left the group). Re-check before dispatch handoff: otherwise
      // the delivery stays DRIVER_ASSIGNED and its driver can never pass the
      // "ready for pickup" gate.
      if (result.ridingGroupId && this.fulfillmentTransitions) {
        await this.fulfillmentTransitions.syncGroupReadinessAfterPortionRemoved(
          fulfillment.orderId,
          result.ridingGroupId,
          actorSub,
        );
      }
      // A portion may have been rejected while others are already accepted and
      // none are still pending — start the driver search in that case.
      await this.maybeAdvanceToDispatch(fulfillment.orderId);
      // If a cancelled delivery group left all surviving groups already delivered,
      // advance the aggregate order to DELIVERED so settlement runs.
      if (this.deliveryGroupTransitions) {
        await this.deliveryGroupTransitions.recomputeGroupedOrderStatusAfterCancel(
          fulfillment.orderId,
        );
      }
    }

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: fulfillment.vendorId },
      select: {
        storeName: true,
        storeNameAr: true,
        members: {
          where: { role: VendorMemberRole.OWNER },
          select: { userId: true },
        },
      },
    });

    await this.emitDecided(
      fulfillment,
      OrderVendorFulfillmentStatus.REJECTED,
      actorSub,
    );

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
        actorSub,
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
    if (
      actor &&
      (actor.role === 'SUPER_ADMIN' ||
        actor.role === 'ADMIN' ||
        (await this.auth.canManageOrders(actor.sub, actor.role)))
    ) {
      return this.prisma.orderVendorFulfillment.findMany({
        where: {
          status: OrderVendorFulfillmentStatus.PENDING,
          order: {
            status: { notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED] },
          },
        },
        orderBy: { createdAt: 'desc' },
        include: this.fulfillmentInclude(),
      });
    }

    const memberships = await this.prisma.vendorMember.findMany({
      where: { userId: actor.sub },
      select: { vendorId: true, branchId: true, role: true },
    });
    if (memberships.length === 0) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    const membershipConditions: Prisma.OrderVendorFulfillmentWhereInput[] =
      memberships.map((m) => ({
        vendorId: m.vendorId,
        ...(m.role !== VendorMemberRole.OWNER && m.branchId
          ? { OR: [{ vendorBranchId: m.branchId }, { vendorBranchId: null }] }
          : {}),
      }));
    return this.prisma.orderVendorFulfillment.findMany({
      where: {
        OR: membershipConditions,
        status: OrderVendorFulfillmentStatus.PENDING,
        order: {
          status: { notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED] },
        },
      },
      orderBy: { createdAt: 'desc' },
      include: this.fulfillmentInclude(),
    });
  }

  async listForVendor(actor: JwtAccessPayload, vendorId: string) {
    if (
      actor &&
      (actor.role === 'SUPER_ADMIN' ||
        actor.role === 'ADMIN' ||
        (await this.auth.canManageOrders(actor.sub, actor.role)))
    ) {
      return this.prisma.orderVendorFulfillment.findMany({
        where: { vendorId },
        orderBy: { createdAt: 'desc' },
        include: this.fulfillmentInclude(),
      });
    }

    const member = await this.prisma.vendorMember.findUnique({
      where: { vendorId_userId: { vendorId, userId: actor.sub } },
      select: { id: true, branchId: true, role: true },
    });
    if (!member) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    const effectiveBranchId =
      member.role === VendorMemberRole.OWNER ? null : member.branchId;

    return this.prisma.orderVendorFulfillment.findMany({
      where: {
        vendorId,
        ...(effectiveBranchId
          ? {
              OR: [
                { vendorBranchId: effectiveBranchId },
                { vendorBranchId: null },
              ],
            }
          : {}),
      },
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

  private async assertVendorMember(
    actor: JwtAccessPayload | null,
    fulfillmentId: string,
  ) {
    const fulfillment = await this.prisma.orderVendorFulfillment.findUnique({
      where: { id: fulfillmentId },
      select: {
        id: true,
        orderId: true,
        vendorId: true,
        vendorBranchId: true,
        status: true,
        pickedUpAt: true,
        subtotal: true,
        commissionRate: true,
        isContracted: true,
      },
    });
    if (!fulfillment) {
      throw new NotFoundException(OrderErrors.FULFILLMENT_NOT_FOUND);
    }

    // Vendor identity is derived from the fulfillment itself, never from a
    // client-supplied vendorId, so a member cannot act on another vendor or branch.
    if (actor && actor.role !== 'ADMIN' && actor.role !== 'SUPER_ADMIN') {
      const canManage = await this.auth.canManageOrders(actor.sub, actor.role);
      if (!canManage) {
        const member = await this.prisma.vendorMember.findUnique({
          where: {
            vendorId_userId: {
              vendorId: fulfillment.vendorId,
              userId: actor.sub,
            },
          },
          select: { id: true, branchId: true, role: true },
        });
        if (!member) {
          throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
        }
        if (
          member.role !== VendorMemberRole.OWNER &&
          member.branchId &&
          fulfillment.vendorBranchId &&
          member.branchId !== fulfillment.vendorBranchId
        ) {
          throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
        }
      }
    }
    return fulfillment;
  }

  private fulfillmentInclude() {
    return {
      items: {
        where: { rejectedAt: null },
        select: {
          id: true,
          fulfillmentId: true,
          productId: true,
          productName: true,
          variantName: true,
          quantity: true,
          selectedUnit: true,
          unitPrice: true,
          totalPrice: true,
          specialRequest: true,
          selectedOptions: true,
          product: { select: { imageUrl: true } },
        },
      },
      vendor: {
        select: {
          id: true,
          storeName: true,
          storeNameAr: true,
          logo: true,
          coverImage: true,
          isContracted: true,
          commissionRate: true,
          phone: true,
        },
      },
      vendorBranch: {
        select: {
          id: true,
          name: true,
          nameAr: true,
          address: true,
          phone: true,
          isContracted: true,
          commissionRate: true,
        },
      },
      groups: {
        select: {
          deliveryGroup: {
            select: {
              id: true,
              sequence: true,
              status: true,
              primaryDriverId: true,
              assistDriverId: true,
            },
          },
        },
      },
    };
  }

  private async emitDecided(
    fulfillment: {
      id: string;
      orderId: string;
      vendorId: string;
      vendorBranchId?: string | null;
    },
    status: OrderVendorFulfillmentStatus,
    actorUserId: string,
  ): Promise<void> {
    const [order, vendorUserIds] = await Promise.all([
      this.prisma.order.findUnique({
        where: { id: fulfillment.orderId },
        select: {
          orderNumber: true,
          status: true,
          revision: true,
          customerId: true,
          customer: { select: { userId: true } },
          deliveryGroups: {
            where: { status: { not: DeliveryGroupStatus.CANCELLED } },
            select: {
              primaryDriver: { select: { userId: true } },
              assistDriver: { select: { userId: true } },
            },
          },
        },
      }),
      this.ordersRepository.getVendorUserIds(
        fulfillment.vendorId,
        fulfillment.vendorBranchId,
      ),
    ]);
    if (!order) return;

    const driverUserIds: string[] = Array.from(
      new Set(
        ((order as any).deliveryGroups ?? [])
          .flatMap((g: any) => [
            g?.primaryDriver?.userId as string | undefined,
            g?.assistDriver?.userId as string | undefined,
          ])
          .filter((id: string | undefined): id is string => Boolean(id)),
      ),
    );

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
        driverUserIds,
        order.status,
        order.revision,
      ),
    );
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
      try {
        await this.ordersRepository.updateStatus(
          orderId,
          'PENDING',
          'system',
          undefined,
          undefined,
          order.status,
        );
      } catch {
        // Concurrent transition already moved the order atomically.
      }
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
      (p) =>
        p.status === OrderVendorFulfillmentStatus.ACCEPTED ||
        p.status === OrderVendorFulfillmentStatus.PREPARING ||
        p.status === OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
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
      await this.prisma.orderDeliveryGroup.updateMany({
        where: {
          orderId,
          primaryDriverId: null,
          status: {
            in: [DeliveryGroupStatus.PENDING, DeliveryGroupStatus.ACCEPTED],
          },
        },
        data: { status: DeliveryGroupStatus.LOOKING_FOR_DRIVER },
      });

      const updated = await this.ordersRepository.updateStatus(
        orderId,
        OrderStatus.LOOKING_FOR_DRIVER,
        'system',
        'All vendor portions decided — searching for drivers',
        undefined,
        order.status,
      );

      const vendorIds = Array.from(
        new Set(
          (
            ((updated as any).vendorFulfillments ?? []) as Array<{
              vendorId: string;
            }>
          ).map((f) => f.vendorId),
        ),
      );
      const singleVendorId = vendorIds.length === 1 ? vendorIds[0] : null;
      const groups = ((updated as any).deliveryGroups ?? []) as Array<{
        primaryDriverId?: string | null;
        primaryDriver?: { userId?: string | null } | null;
        isPaymentCollector?: boolean;
        status?: string;
      }>;
      const collectorGroup =
        groups.find((g) => g.isPaymentCollector && g.primaryDriverId) ??
        groups.find((g) => g.primaryDriverId && g.status !== 'CANCELLED') ??
        null;

      const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
        orderId,
        null,
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
          singleVendorId,
          vendorUserIds,
          collectorGroup?.primaryDriverId ?? null,
          collectorGroup?.primaryDriver?.userId ?? null,
          'system',
          'All vendor portions decided — searching for drivers',
          updated.revision,
        ),
      );
    } catch {
      // Lost a race with another decision or flow that already advanced it.
    }
  }
}
