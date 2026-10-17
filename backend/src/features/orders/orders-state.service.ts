import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  OrdersRepository,
  CreateOrderData,
  OrderItemData,
} from './orders.repository';
import { CartService } from '../cart/cart.service';
import { DispatchService } from '../dispatch/dispatch.service';
import { DRIVER_ACTIVE_ORDER_STATUSES } from './orders.constants';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  PlaceOrderDto,
  UpdateOrderStatusDto,
  QueryOrdersDto,
  RespondToDispatchDto,
  AdminAssignDriverDto,
  PlaceCustomOrderDto,
  PlaceDirectOrderDto,
} from './dto/order.dto';
import {
  OrderCreatedEvent,
  OrderStatusChangedEvent,
  OrderCancelledEvent,
  OrderDispatchRespondedEvent,
  OrderPaymentStatusChangedEvent,
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
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import {
  CartErrors,
  ProductErrors,
  OrderErrors,
  CustomerErrors,
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

@Injectable()
export class OrdersStateService {
  private readonly logger = new Logger(OrdersStateService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    @Inject(forwardRef(() => DispatchService))
    private readonly dispatchService: DispatchService,
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

    const [isMember, canManage] = await Promise.all([
      order.vendorId
        ? this.prisma.vendorMember.findUnique({
            where: {
              vendorId_userId: { vendorId: order.vendorId, userId: actor.sub },
            },
            select: { id: true, branchId: true },
          })
        : Promise.resolve(null),
      this.canManageOrders(actor.sub, actor.role),
    ]);

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    if (
      isMember &&
      isMember.branchId &&
      isMember.branchId !== (order as any).vendorBranchId
    ) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
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
      }>
    ).filter(Boolean);

    if (groups.length > 0) {
      const group = groups.find((g) => g.primaryDriverId === driver.id);
      if (!group) {
        // Not this driver's delivery (or not assigned yet).
        throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
      }

      const expected = DRIVER_ALLOWED_TRANSITIONS[group.status as OrderStatus];
      if (!expected || !expected.includes(dto.status)) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }

      if (
        dto.status === OrderStatus.PICKED_UP &&
        !dto.pickupImageUrl &&
        !(order as any).pickupImageUrl
      ) {
        throw new BadRequestException(OrderErrors.PICKUP_PHOTO_REQUIRED);
      }
      if (
        dto.status === OrderStatus.DELIVERED &&
        !dto.deliveryImageUrl &&
        !(order as any).deliveryImageUrl
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
  async driverConfirmPickup(
    actor: JwtAccessPayload,
    orderId: string,
    file: Express.Multer.File,
  ) {
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
  ) {
    const imageUrl = await this.storage.upload(file, 'deliveries');
    try {
      return await this.driverUpdateStatus(actor, orderId, {
        status: OrderStatus.DELIVERED,
        deliveryImageUrl: imageUrl,
      });
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
    group: { id: string; sequence: number; status: DeliveryGroupStatus },
    dto: UpdateOrderStatusDto,
  ) {
    const newStatus = dto.status as unknown as DeliveryGroupStatus;

    const data: Prisma.OrderDeliveryGroupUpdateManyMutationInput = {
      status: newStatus,
    };
    if (dto.status === OrderStatus.PICKED_UP) data.pickedUpAt = new Date();
    if (dto.status === OrderStatus.DELIVERED) data.deliveredAt = new Date();

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

    // Mirror the proof photo up to the order (the group has no image column).
    if (
      dto.status === OrderStatus.PICKED_UP &&
      dto.pickupImageUrl &&
      !order.pickupImageUrl
    ) {
      await this.prisma.order.update({
        where: { id: order.id },
        data: { pickupImageUrl: dto.pickupImageUrl },
      });
    }
    if (
      dto.status === OrderStatus.DELIVERED &&
      dto.deliveryImageUrl &&
      !order.deliveryImageUrl
    ) {
      await this.prisma.order.update({
        where: { id: order.id },
        data: { deliveryImageUrl: dto.deliveryImageUrl },
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
        [],
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

    // Never put a driver on a second live order.
    const activeOrder = await this.prisma.order.findFirst({
      where: {
        driverId: driver.id,
        id: { not: orderId },
        status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
      },
      select: { id: true },
    });
    if (activeOrder) {
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
    );

    // The dispatch listener will catch ORDER_STATUS_CHANGED to DRIVER_ASSIGNED
    // and cancel any automated dispatch ping that might be running automatically.

    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
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
        const isMember = await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub, vendorId: order.vendorId ?? '' },
        });
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

    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
      order.vendorId,
    );

    const updatedOrder = await this.ordersRepository.cancelOrder(
      orderId,
      actor?.sub ?? 'system',
      reason,
      order.status,
      order.coinsUsed,
      order.customerId,
      order.orderNumber,
      order.driverId,
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

    const vendorUserIds = await this.ordersRepository.getVendorUserIds(
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
