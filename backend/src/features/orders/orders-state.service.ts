import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrdersRepository } from './orders.repository';
import { DispatchService } from '../dispatch/dispatch.service';
import { DRIVER_ACTIVE_ORDER_STATUSES } from './orders.constants';
import {
  UpdateOrderStatusDto,
  RespondToDispatchDto,
  AdminAssignDriverDto,
} from './dto/order.dto';
import {
  OrderStatusChangedEvent,
  OrderCancelledEvent,
  OrderDispatchRespondedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  Prisma,
  OrderStatus,
  Role,
  PaymentMethod,
  DispatchStatus,
  DeliveryGroupStatus,
  Permission,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import {
  OrderErrors,
  DriverErrors,
} from '../../common/constants/response.constants';

const VENDOR_ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.ACCEPTED],
  // Vendor can only start preparing once a driver is assigned
  // (or is pending payment). Accepting and waiting-for-driver are
  // too early — the vendor must wait for a driver to accept first.
  [OrderStatus.ACCEPTED]: [],
  [OrderStatus.LOOKING_FOR_DRIVER]: [],
  [OrderStatus.DRIVER_ASSIGNED]: [
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [OrderStatus.PENDING_PAYMENT]: [
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.PICKED_UP],
  [OrderStatus.PICKED_UP]: [],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
  [OrderStatus.CHANGES_REQUESTED]: [],
};

const DRIVER_ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.DRIVER_ASSIGNED]: [
    OrderStatus.PENDING_PAYMENT,
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
  ],
  [OrderStatus.PENDING_PAYMENT]: [
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
  ],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.PICKED_UP],
  [OrderStatus.PICKED_UP]: [OrderStatus.DELIVERED, OrderStatus.PENDING_PAYMENT],
  [OrderStatus.PENDING]: [],
  [OrderStatus.CHANGES_REQUESTED]: [],
  [OrderStatus.ACCEPTED]: [],
  [OrderStatus.PREPARING]: [],
  [OrderStatus.LOOKING_FOR_DRIVER]: [],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
};

const NON_CANCELLABLE: OrderStatus[] = [
  OrderStatus.DELIVERED,
  OrderStatus.CANCELLED,
  OrderStatus.PICKED_UP,
];
import { forwardRef, Inject } from '@nestjs/common';
import { OrderVendorDecisionService } from './order-vendor-decision.service';

@Injectable()
export class OrdersStateService {
  private readonly logger = new Logger(OrdersStateService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    @Inject(forwardRef(() => DispatchService))
    private readonly dispatchService: DispatchService,
    @Inject(forwardRef(() => OrderVendorDecisionService))
    private readonly vendorDecisionService: OrderVendorDecisionService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async vendorUpdateStatus(
    actor: JwtAccessPayload,
    orderId: string,
    dto: UpdateOrderStatusDto,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    let isMember: { id: string; branchId: string | null; vendorId?: string } | null = order.vendorId
      ? await this.prisma.vendorMember.findUnique({
          where: {
            vendorId_userId: { vendorId: order.vendorId, userId: actor.sub },
          },
          select: { id: true, branchId: true },
        })
      : null;

    let matchingFulfillment: any = null;
    const fulfillments = ((order as any).vendorFulfillments ?? []) as any[];

    if (!isMember && fulfillments.length > 0) {
      const portionVendorIds = Array.from(
        new Set(fulfillments.map((f: any) => f.vendorId)),
      ) as string[];
      const member = await this.prisma.vendorMember.findFirst({
        where: {
          userId: actor.sub,
          vendorId: { in: portionVendorIds },
        },
        select: { id: true, branchId: true, vendorId: true },
      });
      if (member) {
        isMember = member;
        matchingFulfillment = fulfillments.find(
          (f: any) => f.vendorId === member.vendorId,
        );
      }
    }

    const canManage = await this.canManageOrders(actor.sub, actor.role);

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    if (
      isMember &&
      isMember.branchId &&
      matchingFulfillment &&
      matchingFulfillment.vendorBranchId &&
      isMember.branchId !== matchingFulfillment.vendorBranchId
    ) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
    } else if (
      isMember &&
      isMember.branchId &&
      (order as any).vendorBranchId &&
      isMember.branchId !== (order as any).vendorBranchId
    ) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
    }

    // For multi-vendor orders, accept / cancel are per-fulfillment decisions
    if (matchingFulfillment) {
      if (dto.status === OrderStatus.ACCEPTED) {
        if (matchingFulfillment.status === 'ACCEPTED') {
          return this.ordersRepository.findById(orderId);
        }
        await this.vendorDecisionService.accept(actor, matchingFulfillment.id);
        return this.ordersRepository.findById(orderId);
      }
      if (dto.status === OrderStatus.CANCELLED) {
        await this.vendorDecisionService.reject(actor, matchingFulfillment.id, {
          code: 'VENDOR_CANCELLED',
          reason: dto.note ?? 'Cancelled by vendor',
        });
        return this.ordersRepository.findById(orderId);
      }
      if (
        dto.status === OrderStatus.PREPARING ||
        dto.status === OrderStatus.READY_FOR_PICKUP
      ) {
        return this.applyFulfillmentProductionTransition(
          actor,
          order,
          matchingFulfillment,
          dto,
        );
      }
      // Anything else is not a decision a single vendor may make about a
      // shared order (pickup/delivery belong to the driver of the delivery).
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    if (dto.status === OrderStatus.CANCELLED) {
      return this.cancelOrder(
        actor,
        orderId,
        dto.note ?? 'Cancelled by vendor',
      );
    }

    const allowed = VENDOR_ALLOWED_TRANSITIONS[order.status];
    if (!allowed || !allowed.includes(dto.status)) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    return this.applyStatusTransition(actor, order, dto);
  }

  /**
   * Move ONE vendor's portion through production without touching the
   * aggregate order status.
   *
   * On a multi-vendor order the vendors work independently: each portion starts
   * preparing on its own and becomes ready on its own. Writing `PREPARING` /
   * `READY_FOR_PICKUP` on the order row (as the single-vendor path does) made
   * the first vendor's tap speak for every other vendor, so the second vendor
   * could skip preparation and its delivery could look ready before the food
   * was. Portion timestamps keep that state private; the shared delivery group
   * only becomes READY_FOR_PICKUP once every live portion in it is ready.
   */
  private async applyFulfillmentProductionTransition(
    actor: JwtAccessPayload,
    order: any,
    fulfillment: {
      id: string;
      status: string;
      preparingAt?: Date | null;
      readyAt?: Date | null;
    },
    dto: UpdateOrderStatusDto,
  ) {
    if (fulfillment.status !== 'ACCEPTED') {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const groupItem = await this.prisma.orderDeliveryGroupItem.findFirst({
      where: { fulfillmentId: fulfillment.id },
      select: { deliveryGroupId: true },
    });
    if (!groupItem) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const group = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: groupItem.deliveryGroupId },
      select: {
        id: true,
        sequence: true,
        status: true,
        estimatedPrepTime: true,
      },
    });
    if (!group) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const STARTABLE: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.DRIVER_ASSIGNED,
      DeliveryGroupStatus.PENDING_PAYMENT,
      DeliveryGroupStatus.ACCEPTED,
    ];
    const ALREADY_READY: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.READY_FOR_PICKUP,
      DeliveryGroupStatus.PICKED_UP,
      DeliveryGroupStatus.DELIVERED,
    ];

    const wantedReady = dto.status === OrderStatus.READY_FOR_PICKUP;
    const groupProgressed = ALREADY_READY.includes(group.status);

    // Re-tapping a stage the portion already reached is a no-op, not an error:
    // the vendor app keeps its button visible while the refetch is in flight.
    if (wantedReady && fulfillment.readyAt) {
      return this.ordersRepository.findById(order.id);
    }
    if (!wantedReady && fulfillment.preparingAt) {
      return this.ordersRepository.findById(order.id);
    }

    if (!groupProgressed && !STARTABLE.includes(group.status)) {
      // No driver committed to this delivery yet (still PENDING /
      // LOOKING_FOR_DRIVER), so there is nothing to hand over.
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const data: Prisma.OrderVendorFulfillmentUpdateManyMutationInput = wantedReady
      ? {
          preparingAt: fulfillment.preparingAt ?? new Date(),
          readyAt: new Date(),
        }
      : { preparingAt: new Date() };

    const claimed = await this.prisma.orderVendorFulfillment.updateMany({
      where: { id: fulfillment.id, status: 'ACCEPTED' },
      data,
    });
    if (claimed.count === 0) {
      throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
    }

    // Vendors sharing a delivery each estimate their own portion; the group
    // keeps the longest estimate so the driver is never promised food early.
    if (!wantedReady && dto.estimatedPrepTime) {
      await this.prisma.orderDeliveryGroup.updateMany({
        where: { id: group.id },
        data: {
          estimatedPrepTime: Math.max(
            group.estimatedPrepTime ?? 0,
            Math.round(dto.estimatedPrepTime),
          ),
        },
      });
    }

    await this.prisma.orderStatusEvent.create({
      data: {
        orderId: order.id,
        status: order.status,
        note: wantedReady
          ? `Delivery ${group.sequence}: vendor portion ready for pickup`
          : `Delivery ${group.sequence}: vendor portion started preparing`,
        createdBy: actor.sub,
      },
    });

    if (wantedReady) {
      await this.markGroupReadyIfAllPortionsReady(group.id);
    }
    await this.recomputeVendorReadinessStatus(actor.sub, order.id, group.id);

    return this.ordersRepository.findById(order.id);
  }

  /**
   * Re-evaluate a delivery after one of its vendor portions left it.
   *
   * A rejection removes its portion from the delivery group, which can leave a
   * delivery whose only remaining portion was already declared ready. Without
   * this re-check the group stays DRIVER_ASSIGNED and, because pickup now
   * requires READY_FOR_PICKUP, that driver can never collect the goods. Called
   * after the rejection transaction commits so the reads see the final rows.
   */
  async syncGroupReadinessAfterPortionRemoved(
    orderId: string,
    deliveryGroupId: string,
    actorUserId: string,
  ): Promise<void> {
    const becameReady =
      await this.markGroupReadyIfAllPortionsReady(deliveryGroupId);
    // The surviving portions' own production state did not change when this
    // delivery still has work left, and re-deriving the aggregate then could
    // walk an already-dispatched order backwards. Only a delivery that just
    // became ready can justify moving the aggregate.
    if (!becameReady) return;
    await this.recomputeVendorReadinessStatus(
      actorUserId,
      orderId,
      deliveryGroupId,
    );
  }

  /**
   * A delivery can only be handed to its driver when EVERY live vendor portion
   * in it is ready. Vendors sharing a delivery therefore no longer race: the
   * group flips exactly once, on the last portion to become ready.
   */
  private async markGroupReadyIfAllPortionsReady(groupId: string): Promise<boolean> {
    const portions = await this.prisma.orderVendorFulfillment.findMany({
      where: { groups: { some: { deliveryGroupId: groupId } } },
      select: { status: true, readyAt: true },
    });
    const live = portions.filter(
      (p) => p.status !== 'REJECTED' && p.status !== 'CANCELLED',
    );
    if (live.length === 0) return false;
    if (!live.every((p) => p.readyAt != null)) return false;

    const updated = await this.prisma.orderDeliveryGroup.updateMany({
      where: {
        id: groupId,
        status: {
          in: [
            DeliveryGroupStatus.DRIVER_ASSIGNED,
            DeliveryGroupStatus.PENDING_PAYMENT,
            DeliveryGroupStatus.ACCEPTED,
          ],
        },
      },
      data: { status: DeliveryGroupStatus.READY_FOR_PICKUP },
    });
    return updated.count > 0;
  }

  /**
   * Keep the customer-facing aggregate in step with per-portion production:
   * PREPARING as soon as any portion starts cooking, READY_FOR_PICKUP only
   * once every live delivery is ready. Never walks the aggregate backwards.
   */
  private async recomputeVendorReadinessStatus(
    actorUserId: string,
    orderId: string,
    changedGroupId: string,
  ) {
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId },
      select: { id: true, status: true },
    });
    const active = groups.filter(
      (g) => g.status !== DeliveryGroupStatus.CANCELLED,
    );
    if (active.length === 0) return;

    const fresh = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        orderNumber: true,
        status: true,
        customerId: true,
        vendorId: true,
        driverId: true,
        customer: { select: { userId: true } },
      },
    });
    if (!fresh) return;

    const READY_OR_BEYOND: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.READY_FOR_PICKUP,
      DeliveryGroupStatus.PICKED_UP,
      DeliveryGroupStatus.DELIVERED,
    ];
    const allReady = active.every((g) => READY_OR_BEYOND.includes(g.status));
    const changedGroup = groups.find((g) => g.id === changedGroupId);
    const someoneStarted =
      !!changedGroup && !READY_OR_BEYOND.includes(changedGroup.status);

    let target: OrderStatus | null = null;
    // Only pre-pickup aggregates may move. Once a delivery is on the road (or
    // finished) the order must never be walked back to READY_FOR_PICKUP just
    // because a portion marked itself ready late.
    const PRE_READY: OrderStatus[] = [
      OrderStatus.PENDING,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.LOOKING_FOR_DRIVER,
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
    ];
    if (
      allReady &&
      fresh.status !== OrderStatus.READY_FOR_PICKUP &&
      PRE_READY.includes(fresh.status)
    ) {
      target = OrderStatus.READY_FOR_PICKUP;
    } else if (
      !allReady &&
      someoneStarted &&
      (fresh.status === OrderStatus.DRIVER_ASSIGNED ||
        fresh.status === OrderStatus.PENDING_PAYMENT ||
        fresh.status === OrderStatus.ACCEPTED)
    ) {
      target = OrderStatus.PREPARING;
    }
    if (!target) return;

    const extraData: Prisma.OrderUpdateInput = {};
    if (target === OrderStatus.READY_FOR_PICKUP) {
      extraData.preparedAt = new Date();
    }

    try {
      await this.ordersRepository.updateStatus(
        orderId,
        target,
        actorUserId,
        target === OrderStatus.READY_FOR_PICKUP
          ? 'All vendor portions ready for pickup'
          : 'Vendor portion started preparing',
        extraData,
        fresh.status,
      );
    } catch {
      // Another writer moved the aggregate first; its value is authoritative.
      return;
    }

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      orderId,
      fresh.vendorId,
    );

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        orderId,
        fresh.orderNumber,
        fresh.status,
        target,
        fresh.customerId,
        fresh.customer?.userId ?? fresh.customerId,
        fresh.vendorId,
        vendorUserIds,
        fresh.driverId,
        null,
        actorUserId,
        target === OrderStatus.READY_FOR_PICKUP
          ? 'All vendor portions ready for pickup'
          : 'Vendor portion started preparing',
      ),
    );
  }

  async driverUpdateStatus(
    actor: JwtAccessPayload,
    orderId: string,
    dto: UpdateOrderStatusDto,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    // Multi-vendor orders split into delivery groups, each with its OWN primary
    // driver. Only that driver may advance their group; the order-level status
    // is an aggregate recomputed once every group reaches a milestone.
    const groups = (
      ((order as any).deliveryGroups ?? []) as Array<{
        id: string;
        sequence: number;
        status: DeliveryGroupStatus;
        primaryDriverId: string | null;
        pickupImageUrl: string | null;
        deliveryImageUrl: string | null;
      }>
    ).filter(Boolean);

    if (groups.length > 0) {
      const activeGroups = groups.filter(
        (g) =>
          g.primaryDriverId === driver.id &&
          g.status !== DeliveryGroupStatus.CANCELLED,
      );
      const group = (dto as any).deliveryGroupId
        ? activeGroups.find((g) => g.id === (dto as any).deliveryGroupId)
        : (activeGroups.find((g) => g.status !== DeliveryGroupStatus.DELIVERED) ??
           activeGroups[0]);
      if (!group) {
        // Not this driver's delivery (or not assigned yet).
        throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
      }

      const expected = DRIVER_ALLOWED_TRANSITIONS[group.status as OrderStatus];
      if (!expected || !expected.includes(dto.status)) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }

      // Same rule as the single-vendor path: the vendors must declare the
      // delivery ready before its driver can collect it. Without this a driver
      // could confirm pickup while the portion was still being prepared.
      if (
        order.type === 'STANDARD' &&
        group.status === DeliveryGroupStatus.DRIVER_ASSIGNED &&
        dto.status === OrderStatus.PICKED_UP
      ) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }

      // Each delivery carries its OWN proof photos: the order-level photo is
      // deliberately NOT accepted as a fallback, otherwise the first delivery's
      // photo would let every later delivery skip its own proof.
      if (
        dto.status === OrderStatus.PICKED_UP &&
        !dto.pickupImageUrl &&
        !group.pickupImageUrl
      ) {
        throw new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED);
      }
      if (
        dto.status === OrderStatus.DELIVERED &&
        !dto.deliveryImageUrl &&
        !group.deliveryImageUrl
      ) {
        throw new BadRequestException(OrderErrors.DELIVERY_PHOTO_REQUIRED);
      }

      if (
        order.paymentMethod === PaymentMethod.MOBILE_WALLET &&
        order.paymentStatus !== 'COMPLETED' &&
        dto.status !== OrderStatus.PENDING_PAYMENT
      ) {
        throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
      }

      return this.applyGroupStatusTransition(actor, order, group, dto);
    }

    if (order.driverId !== driver.id) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    // Vendor orders must be marked READY_FOR_PICKUP by the vendor before
    // the driver can confirm pickup. Custom delivery / ride orders have no
    // vendor to mark them ready, so the driver can confirm directly.
    if (
      order.type === 'STANDARD' &&
      order.status === OrderStatus.DRIVER_ASSIGNED &&
      dto.status === OrderStatus.PICKED_UP
    ) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const expected = DRIVER_ALLOWED_TRANSITIONS[order.status];
    if (!expected || !expected.includes(dto.status)) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    // The driver cannot confirm pickup without a photo of the order as proof.
    if (
      dto.status === OrderStatus.PICKED_UP &&
      !dto.pickupImageUrl &&
      !order.pickupImageUrl
    ) {
      throw new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED);
    }

    // The driver cannot confirm delivery without a photo of the order as proof.
    if (
      dto.status === OrderStatus.DELIVERED &&
      !dto.deliveryImageUrl &&
      !order.deliveryImageUrl
    ) {
      throw new BadRequestException(OrderErrors.DELIVERY_PHOTO_REQUIRED);
    }

    // Mobile-wallet orders are paid before pickup: the driver must never be able
    // to advance the order while payment is still unpaid. The confirmation flow
    // (driverConfirmPayment) writes paymentStatus=COMPLETED when it advances the
    // order, so no transition here may run ahead of that.
    if (
      order.paymentMethod === 'MOBILE_WALLET' &&
      order.paymentStatus !== 'COMPLETED' &&
      dto.status !== OrderStatus.PENDING_PAYMENT
    ) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }

    return this.applyStatusTransition(actor, order, dto);
  }

  // Driver-only pickup confirmation: the order photo is uploaded as part of the
  // action, then the standard PICKED_UP transition runs (which itself enforces
  // that a photo was provided). If the transition fails the upload is rolled back.
  async driverConfirmFulfillmentPickup(
    actor: JwtAccessPayload,
    orderId: string,
    fulfillmentId: string,
    file: Express.Multer.File,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new ForbiddenException(DriverErrors.PROFILE_NOT_FOUND);

    const fulfillment = await this.prisma.orderVendorFulfillment.findFirst({
      where: { id: fulfillmentId, orderId },
      include: {
        groups: {
          include: {
            deliveryGroup: true,
          },
        },
      },
    });
    if (!fulfillment) throw new NotFoundException('Fulfillment stop not found');

    const order = await this.ordersRepository.findById(orderId);
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);

    const isAssigned =
      order.driverId === driver.id ||
      fulfillment.groups.some(
        (g) =>
          g.deliveryGroup.primaryDriverId === driver.id ||
          g.deliveryGroup.assistDriverId === driver.id,
      );
    if (!isAssigned) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    // Enforce sequential pickup if multiple fulfillments belong to this delivery group
    const groupItem = fulfillment.groups[0];
    if (groupItem) {
      const allGroupItems = await this.prisma.orderDeliveryGroupItem.findMany({
        where: { deliveryGroupId: groupItem.deliveryGroupId },
        include: { fulfillment: true },
        orderBy: { sequence: 'asc' },
      });
      for (const item of allGroupItems) {
        if (item.fulfillmentId === fulfillmentId) break;
        if (
          item.fulfillment &&
          item.fulfillment.status !== 'REJECTED' &&
          item.fulfillment.status !== 'CANCELLED' &&
          !item.fulfillment.pickedUpAt
        ) {
          throw new BadRequestException(
            'Earlier vendor pickup stop must be completed first',
          );
        }
      }
    }

    const imageUrl = await this.storage.upload(file, 'pickups');
    try {
      const now = new Date();
      await this.prisma.orderVendorFulfillment.update({
        where: { id: fulfillmentId },
        data: {
          pickedUpAt: now,
          pickupImageUrl: imageUrl,
          pickedUpByDriverId: driver.id,
        },
      });

      // Check if all active fulfillments in the group are now picked up
      if (groupItem) {
        const remaining = await this.prisma.orderDeliveryGroupItem.findMany({
          where: { deliveryGroupId: groupItem.deliveryGroupId },
          include: { fulfillment: true },
        });
        const allPickedUp = remaining.every(
          (it) =>
            !it.fulfillment ||
            it.fulfillment.status === 'REJECTED' ||
            it.fulfillment.status === 'CANCELLED' ||
            Boolean(it.fulfillment.pickedUpAt),
        );

        if (allPickedUp) {
          await this.prisma.orderDeliveryGroup.update({
            where: { id: groupItem.deliveryGroupId },
            data: {
              status: DeliveryGroupStatus.PICKED_UP,
              pickedUpAt: now,
              pickupImageUrl: imageUrl,
            },
          });
          await this.recomputeGroupedOrderStatus(actor, order);
        }
      } else {
        await this.driverUpdateStatus(actor, orderId, {
          status: OrderStatus.PICKED_UP,
          pickupImageUrl: imageUrl,
        });
      }

      await this.prisma.orderStatusEvent.create({
        data: {
          orderId,
          status: order.status,
          note: `Driver picked up fulfillment stop ${fulfillmentId}`,
          createdBy: actor.sub,
        },
      });

      return this.ordersRepository.findById(orderId);
    } catch (error) {
      await this.storage.delete(imageUrl);
      throw error;
    }
  }

  async driverConfirmPickup(
    actor: JwtAccessPayload,
    orderId: string,
    file: Express.Multer.File,
    fulfillmentId?: string,
  ) {
    if (fulfillmentId) {
      return this.driverConfirmFulfillmentPickup(actor, orderId, fulfillmentId, file);
    }

    // If order has fulfillments, find the next unpicked one
    const order = await this.ordersRepository.findById(orderId);
    if (order && order.vendorFulfillments && order.vendorFulfillments.length > 0) {
      const nextUnpicked = order.vendorFulfillments.find(
        (f: any) =>
          f.status !== 'REJECTED' &&
          f.status !== 'CANCELLED' &&
          !f.pickedUpAt,
      );
      if (nextUnpicked) {
        return this.driverConfirmFulfillmentPickup(actor, orderId, nextUnpicked.id, file);
      }
    }

    const imageUrl = await this.storage.upload(file, 'pickups');
    try {
      return await this.driverUpdateStatus(actor, orderId, {
        status: OrderStatus.PICKED_UP,
        pickupImageUrl: imageUrl,
      });
    } catch (error) {
      await this.storage.delete(imageUrl);
      throw error;
    }
  }

  // Driver-only delivery confirmation: the order photo is uploaded as part of
  // the action, then the standard DELIVERED transition runs (which itself
  // enforces that a photo was provided). If the transition fails the upload is
  // rolled back.
  async driverConfirmDelivery(
    actor: JwtAccessPayload,
    orderId: string,
    file: Express.Multer.File,
    deliveryGroupId?: string,
  ) {
    const imageUrl = await this.storage.upload(file, 'deliveries');
    try {
      return await this.driverUpdateStatus(actor, orderId, {
        status: OrderStatus.DELIVERED,
        deliveryImageUrl: imageUrl,
        ...(deliveryGroupId ? { deliveryGroupId } : {}),
      } as any);
    } catch (error) {
      await this.storage.delete(imageUrl);
      throw error;
    }
  }

  // ── Multi-vendor delivery-group lifecycle ──────────────────────────────────

  /**
   * Advance ONE delivery group through its own lifecycle and then recompute the
   * customer-facing order status from all groups. Uses a status CAS so a
   * duplicate/stale update cannot double-apply.
   */
  private async applyGroupStatusTransition(
    actor: JwtAccessPayload,
    order: any,
    group: {
      id: string;
      sequence: number;
      status: DeliveryGroupStatus;
      pickupImageUrl?: string | null;
      deliveryImageUrl?: string | null;
    },
    dto: UpdateOrderStatusDto,
  ) {
    const newStatus = dto.status as unknown as DeliveryGroupStatus;

    const data: Prisma.OrderDeliveryGroupUpdateManyMutationInput = {
      status: newStatus,
    };
    if (dto.status === OrderStatus.PICKED_UP) data.pickedUpAt = new Date();
    if (dto.status === OrderStatus.DELIVERED) data.deliveredAt = new Date();
    // Proof photos belong to the delivery that produced them — never mirrored
    // to the order, so one delivery's proof cannot satisfy another's.
    if (dto.status === OrderStatus.PICKED_UP && dto.pickupImageUrl) {
      data.pickupImageUrl = dto.pickupImageUrl;
    }
    if (dto.status === OrderStatus.DELIVERED && dto.deliveryImageUrl) {
      data.deliveryImageUrl = dto.deliveryImageUrl;
    }

    const claimed = await this.prisma.orderDeliveryGroup.updateMany({
      where: { id: group.id, status: group.status },
      data,
    });
    if (claimed.count === 0) {
      throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
    }

    // Stamp this group's vendor portions as delivered.
    if (dto.status === OrderStatus.DELIVERED) {
      await this.prisma.orderVendorFulfillment.updateMany({
        where: { groups: { some: { deliveryGroupId: group.id } } },
        data: { deliveredAt: new Date() },
      });
    }

    await this.prisma.orderStatusEvent.create({
      data: {
        orderId: order.id,
        status: order.status,
        note: `Delivery ${group.sequence}: ${group.status} → ${dto.status}`,
        createdBy: actor.sub,
      },
    });

    await this.recomputeGroupedOrderStatus(actor, order);

    return this.ordersRepository.findById(order.id);
  }

  /**
   * Recompute the aggregate order status from its (non-cancelled) delivery
   * groups: PICKED_UP once every group is on the road, DELIVERED once every
   * group is delivered. Emits ORDER_STATUS_CHANGED so settlement/chat run.
   */
  private async recomputeGroupedOrderStatus(
    actor: JwtAccessPayload,
    order: any,
  ): Promise<void> {
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: order.id },
      select: { id: true, status: true, primaryDriverId: true },
      orderBy: { sequence: 'asc' },
    });
    const active = groups.filter(
      (g) => g.status !== DeliveryGroupStatus.CANCELLED,
    );
    if (active.length === 0) return;

    const fresh = await this.prisma.order.findUnique({
      where: { id: order.id },
      select: {
        status: true,
        customerId: true,
        vendorId: true,
        driverId: true,
        customer: { select: { userId: true } },
      },
    });
    if (!fresh) return;

    const allDelivered = active.every(
      (g) => g.status === DeliveryGroupStatus.DELIVERED,
    );
    const allPickedUp = active.every(
      (g) =>
        g.status === DeliveryGroupStatus.PICKED_UP ||
        g.status === DeliveryGroupStatus.DELIVERED,
    );

    let target: OrderStatus | null = null;
    if (allDelivered) target = OrderStatus.DELIVERED;
    else if (allPickedUp && fresh.status !== OrderStatus.PICKED_UP) {
      target = OrderStatus.PICKED_UP;
    }
    if (!target || fresh.status === target) return;

    // Only ever move forward.
    const allowedFrom: Record<string, OrderStatus[]> = {
      [OrderStatus.PICKED_UP]: [
        OrderStatus.DRIVER_ASSIGNED,
        OrderStatus.PENDING_PAYMENT,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.ACCEPTED,
        OrderStatus.LOOKING_FOR_DRIVER,
      ],
      [OrderStatus.DELIVERED]: [OrderStatus.PICKED_UP],
    };
    if (!(allowedFrom[target] ?? []).includes(fresh.status)) {
      return;
    }

    const extraData: Prisma.OrderUpdateInput = {};
    if (target === OrderStatus.PICKED_UP) extraData.pickedUpAt = new Date();
    if (target === OrderStatus.DELIVERED)
      extraData.actualDeliveryTime = new Date();

    try {
      await this.ordersRepository.updateStatus(
        order.id,
        target,
        actor.sub,
        target === OrderStatus.DELIVERED
          ? 'All deliveries completed'
          : 'All deliveries picked up',
        extraData,
        fresh.status,
      );
    } catch {
      // Lost a race with a concurrent group update — the other writer wins.
      return;
    }

    if (target === OrderStatus.DELIVERED) {
      const driverIds = [
        fresh.driverId,
        ...groups.map((g) => g.primaryDriverId),
      ].filter((d): d is string => !!d);
      for (const driverId of new Set(driverIds)) {
        await this.ordersRepository.freeDriver(driverId);
      }
    }

    // Notify every participating vendor, not just an order-level one: a
    // multi-vendor order has no order-level vendor.
    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      fresh.vendorId,
    );

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        fresh.status,
        target,
        fresh.customerId,
        fresh.customer?.userId ?? fresh.customerId,
        fresh.vendorId,
        vendorUserIds,
        fresh.driverId,
        null,
        actor.sub,
        target === OrderStatus.DELIVERED
          ? 'All deliveries completed'
          : 'All deliveries picked up',
      ),
    );
  }

  async respondToDispatch(
    actor: JwtAccessPayload,
    dispatchId: string,
    dto: RespondToDispatchDto,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true, status: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    // A driver on break holds only stale pre-break dispatches — fail fast
    // with a clear error instead of the generic already-on-order message
    // from the guarded acceptance update.
    if (dto.response === 'ACCEPTED' && driver.status === 'ON_BREAK') {
      throw new BadRequestException(DriverErrors.CANNOT_ACCEPT_ON_BREAK);
    }

    const orderId = await this.dispatchService.verifyPendingDispatch(
      dispatchId,
      driver.id,
    );
    if (!orderId) {
      throw new BadRequestException(OrderErrors.DISPATCH_NOT_FOUND);
    }

    if (dto.response === 'ACCEPTED') {
      try {
        const assigned = await this.dispatchService.handleAcceptance(
          dispatchId,
          driver.id,
        );

        // The dispatch is no longer available for this driver (expired,
        // already won by someone else, or cancelled). Surface a real error
        // instead of pretending the acceptance succeeded.
        if (!assigned) {
          throw new BadRequestException(
            OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED,
          );
        }

        // Emit purely for analytical tracking after successful assignment
        this.eventEmitter.emit(
          EVENTS.ORDER_DISPATCH_RESPONDED,
          new OrderDispatchRespondedEvent(
            dispatchId,
            orderId,
            driver.id,
            DispatchStatus.ACCEPTED,
          ),
        );
      } catch (error) {
        if (
          (error as Error).message === OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED
        ) {
          throw new BadRequestException(
            OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED,
          );
        }
        if ((error as Error).message === OrderErrors.DRIVER_ALREADY_ON_ORDER) {
          throw new BadRequestException(OrderErrors.DRIVER_ALREADY_ON_ORDER);
        }
        throw error;
      }
    } else {
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_RESPONDED,
        new OrderDispatchRespondedEvent(
          dispatchId,
          orderId,
          driver.id,
          DispatchStatus.REJECTED,
        ),
      );
    }

    return { response: dto.response };
  }

  async adminForceAssignDriver(
    actor: JwtAccessPayload,
    orderId: string,
    dto: AdminAssignDriverDto,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    const assignableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.LOOKING_FOR_DRIVER,
    ];
    if (!assignableStatuses.includes(order.status)) {
      throw new BadRequestException(OrderErrors.CANNOT_FORCE_ASSIGN_DRIVER);
    }

    const driver = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: { id: true, status: true, userId: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    if (driver.status === 'SUSPENDED') {
      throw new BadRequestException(OrderErrors.CANNOT_ASSIGN_SUSPENDED_DRIVER);
    }

    // On-break drivers are invisible to dispatch; force-assign must not
    // silently yank them back (admin force-ends the break first instead).
    if (driver.status === 'ON_BREAK') {
      throw new BadRequestException(DriverErrors.CANNOT_ASSIGN_ON_BREAK);
    }

    const settings = await this.prisma.platformSetting.findUnique({
      where: { id: 'default' },
      select: { maxActiveOrdersPerDriver: true },
    });
    const maxActive = settings?.maxActiveOrdersPerDriver ?? 1;

    // Never put a driver on more live orders than maxActive.
    const activeOrdersCount = await this.prisma.order.count({
      where: {
        driverId: driver.id,
        id: { not: orderId },
        status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
      },
    });
    if (activeOrdersCount >= maxActive) {
      throw new BadRequestException(OrderErrors.DRIVER_ALREADY_ON_ORDER);
    }

    // Get active shift if any
    const activeShift = await this.prisma.driverShift.findFirst({
      where: { driverId: driver.id, status: 'ACTIVE' },
      select: { id: true },
    });

    // If the order already had a driver, free them first
    if (order.driverId && order.driverId !== driver.id) {
      await this.ordersRepository.freeDriver(order.driverId);
    }

    const nextStatus =
      order.paymentMethod === 'MOBILE_WALLET'
        ? OrderStatus.PENDING_PAYMENT
        : OrderStatus.DRIVER_ASSIGNED;

    const updated = await this.ordersRepository.assignDriver(
      orderId,
      driver.id,
      activeShift?.id ?? null,
      actor.sub,
      nextStatus,
      maxActive,
    );

    // The dispatch listener will catch ORDER_STATUS_CHANGED to DRIVER_ASSIGNED
    // and cancel any automated dispatch ping that might be running automatically.

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      order.vendorId,
    );
    const customerUser = (order as { customer?: { user?: { id: string } } })
      .customer?.user;

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        orderId,
        order.orderNumber,
        order.status,
        nextStatus,
        order.customerId,
        customerUser?.id ?? '',
        order.vendorId,
        vendorUserIds,
        driver.id,
        driver.userId,
        actor.sub,
        `Driver manually assigned by admin. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
      ),
    );

    this.logger.log(
      `Admin ${actor.sub} force-assigned driver ${driver.id} to order ${order.orderNumber}`,
    );
    return updated;
  }

  async cancelOrder(
    actor: JwtAccessPayload | null,
    orderId: string,
    reason: string,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    if (NON_CANCELLABLE.includes(order.status)) {
      throw new BadRequestException(OrderErrors.CANNOT_CANCEL_ORDER);
    }

    if (actor) {
      if (actor.role === Role.CUSTOMER) {
        if (order.customer.userId !== actor.sub) {
          throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
        }
        // Customer cannot cancel if vendor has already started preparing or completed food
        const customerCancellableStatuses: OrderStatus[] = [
          OrderStatus.PENDING,
          OrderStatus.CHANGES_REQUESTED,
          OrderStatus.ACCEPTED,
          OrderStatus.LOOKING_FOR_DRIVER,
        ];
        if (!customerCancellableStatuses.includes(order.status)) {
          throw new BadRequestException(
            OrderErrors.CANNOT_CANCEL_PREPARATION_STARTED,
          );
        }
      } else if (actor.role === Role.VENDOR_MEMBER) {
        // A multi-vendor order has no single order-level vendor, so membership
        // must be resolved against every portion's vendor. Otherwise no vendor
        // could ever cancel their side of a multi-vendor order.
        const vendorIds = new Set<string>();
        if (order.vendorId) vendorIds.add(order.vendorId);
        for (const f of ((order as any).vendorFulfillments ?? []) as Array<{
          vendorId: string;
        }>) {
          if (f.vendorId) vendorIds.add(f.vendorId);
        }
        const isMember =
          vendorIds.size > 0 &&
          (await this.prisma.vendorMember.findFirst({
            where: { userId: actor.sub, vendorId: { in: [...vendorIds] } },
          })) !== null;
        if (!isMember) {
          throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
        }
      } else if (actor.role === Role.DRIVER) {
        throw new ForbiddenException(OrderErrors.DRIVERS_CANNOT_CANCEL);
      } else if (actor.role === Role.ADMIN || actor.role === Role.SUPER_ADMIN) {
        const canManage = await this.canManageOrders(actor.sub, actor.role);
        if (!canManage) {
          throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
        }
      }
    }

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      order.vendorId,
    );

    // Multi-vendor orders have no single order-level driver; collect every
    // primary driver of the (non-cancelled) delivery groups so the cancellation
    // side-effects (cache clear, stats, notification) reach all of them.
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: order.id },
      select: { primaryDriverId: true, assistDriverId: true },
    });
    const groupDriverIds = groups
      .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
      .filter((id): id is string => !!id);
    const allDriverIds = Array.from(
      new Set([order.driverId, ...groupDriverIds].filter((id): id is string => !!id)),
    );

    const updatedOrder = await this.ordersRepository.cancelOrder(
      orderId,
      actor?.sub ?? 'system',
      reason,
      order.status,
      order.coinsUsed,
      order.customerId,
      order.orderNumber,
      allDriverIds,
    );

    const orderWithRelations = updatedOrder as {
      driver: { userId: string } | null;
      customer: { user: { id: string } };
    };

    const driverUserId = orderWithRelations.driver?.userId ?? null;

    this.eventEmitter.emit(
      EVENTS.ORDER_CANCELLED,
      new OrderCancelledEvent(
        orderId,
        order.orderNumber,
        order.customerId,
        orderWithRelations.customer.user.id,
        order.vendorId,
        vendorUserIds,
        order.driverId,
        driverUserId,
        reason,
        actor?.sub ?? null,
        allDriverIds,
      ),
    );

    this.logger.log(`Order ${order.orderNumber} cancelled: ${reason}`);
    return this.ordersRepository.findById(orderId);
  }

  private async applyStatusTransition(
    actor: JwtAccessPayload,
    order: {
      id: string;
      status: string;
      orderNumber: string;
      customerId: string;
      vendorId: string | null;
      driverId: string | null;
      customer: { user: { id: string } };
      driver: { userId: string } | null;
    },
    dto: UpdateOrderStatusDto,
  ) {
    const oldStatus = order.status as OrderStatus;
    const newStatus = dto.status;

    // A manager may still move a grouped order by hand. Keep each delivery's
    // own state in step, otherwise the "vendor must mark the delivery ready"
    // guard would leave every driver of that order unable to collect.
    if (newStatus === OrderStatus.READY_FOR_PICKUP) {
      const grouped = ((order as any).deliveryGroups ?? []) as Array<{
        id: string;
      }>;
      if (grouped.length > 0) {
        const now = new Date();
        await this.prisma.orderVendorFulfillment.updateMany({
          where: { orderId: order.id, status: 'ACCEPTED', readyAt: null },
          data: { preparingAt: now, readyAt: now },
        });
        await this.prisma.orderDeliveryGroup.updateMany({
          where: {
            orderId: order.id,
            status: {
              in: [
                DeliveryGroupStatus.DRIVER_ASSIGNED,
                DeliveryGroupStatus.PENDING_PAYMENT,
                DeliveryGroupStatus.ACCEPTED,
              ],
            },
          },
          data: { status: DeliveryGroupStatus.READY_FOR_PICKUP },
        });
      }
    }

    const extraData: Prisma.OrderUpdateInput = {};
    if (
      newStatus === OrderStatus.ACCEPTED ||
      newStatus === OrderStatus.PREPARING
    ) {
      if (newStatus === OrderStatus.ACCEPTED) extraData.acceptedAt = new Date();
      if (dto.estimatedPrepTime)
        extraData.estimatedPrepTime = dto.estimatedPrepTime;
    }
    if (newStatus === OrderStatus.READY_FOR_PICKUP)
      extraData.preparedAt = new Date();
    if (newStatus === OrderStatus.PICKED_UP) {
      extraData.pickedUpAt = new Date();
      if (dto.pickupImageUrl) extraData.pickupImageUrl = dto.pickupImageUrl;
    }
    if (newStatus === OrderStatus.DELIVERED) {
      extraData.actualDeliveryTime = new Date();
      if (dto.deliveryImageUrl)
        extraData.deliveryImageUrl = dto.deliveryImageUrl;
    }

    const updated = await this.ordersRepository.updateStatus(
      order.id,
      newStatus,
      actor.sub,
      dto.note,
      extraData,
      oldStatus,
    );

    if (order.driverId && newStatus === OrderStatus.DELIVERED) {
      await this.ordersRepository.freeDriver(order.driverId);
    }

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      order.vendorId,
    );
    const driverUserId = order.driver?.userId ?? null;

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        oldStatus,
        newStatus,
        order.customerId,
        order.customer.user.id,
        order.vendorId,
        vendorUserIds,
        order.driverId,
        driverUserId,
        actor.sub,
        dto.note ?? null,
      ),
    );

    this.logger.log(`Order ${order.orderNumber}: ${oldStatus} → ${newStatus}`);
    return updated;
  }

  private async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.SUPER_ADMIN) return true;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!user?.permissions.includes(Permission.MANAGE_ORDERS);
  }
}
