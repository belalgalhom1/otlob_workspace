import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DispatchStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Prisma,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { OrdersRepository } from './orders.repository';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import {
  AdminAssignDriverDto,
  RespondToDispatchDto,
  UpdateOrderStatusDto,
} from './dto/order.dto';
import {
  OrderDispatchRespondedEvent,
  OrderStatusChangedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { DISPATCH_PORT } from '../../common/orders/order-dispatch.ports';
import type { DispatchPort } from '../../common/orders/order-dispatch.ports';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  DriverErrors,
  OrderErrors,
} from '../../common/constants/response.constants';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import {
  DRIVER_ALLOWED_TRANSITIONS,
  VENDOR_ALLOWED_TRANSITIONS,
} from './transitions/order-state.constants';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import {
  DeliveryGroupSummary,
  DeliveryGroupTransitionService,
} from './transitions/delivery-group-transition.service';
import { FulfillmentTransitionService } from './transitions/fulfillment-transition.service';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';

/**
 * Coordinates order state transitions across single-vendor orders while
 * delegating fulfillment production, multi-vendor delivery groups, and
 * cancellations to their dedicated aggregate transition services.
 */
@Injectable()
export class OrdersStateService {
  private readonly logger = new Logger(OrdersStateService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    @Inject(DISPATCH_PORT)
    private readonly dispatchPort: DispatchPort,
    private readonly vendorDecisionService: OrderVendorDecisionService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    @Optional() private readonly authHelper?: OrderAuthorizationHelper,
    @Optional() private readonly cancellationService?: OrderCancellationService,
    @Optional()
    private readonly fulfillmentTransitions?: FulfillmentTransitionService,
    @Optional()
    private readonly deliveryGroupTransitions?: DeliveryGroupTransitionService,
    @Optional()
    private readonly driverWorkloadHelper?: DriverWorkloadHelper,
  ) {}

  private get auth(): OrderAuthorizationHelper {
    return this.authHelper ?? new OrderAuthorizationHelper(this.prisma);
  }

  private get driverWorkload(): DriverWorkloadHelper {
    return this.driverWorkloadHelper ?? new DriverWorkloadHelper();
  }

  private get deliveryGroup(): DeliveryGroupTransitionService {
    return (
      this.deliveryGroupTransitions ??
      new DeliveryGroupTransitionService(
        this.prisma,
        this.ordersRepository,
        this.eventEmitter,
        undefined,
        undefined,
        this.cancellationService,
      )
    );
  }

  private get fulfillmentTransition(): FulfillmentTransitionService {
    return (
      this.fulfillmentTransitions ??
      new FulfillmentTransitionService(
        this.prisma,
        this.ordersRepository,
        this.storage,
        this.eventEmitter,
        this.deliveryGroup,
      )
    );
  }

  private get cancellation(): OrderCancellationService {
    return (
      this.cancellationService ??
      new OrderCancellationService(
        this.ordersRepository,
        this.prisma,
        this.auth,
        this.eventEmitter,
      )
    );
  }

  async vendorUpdateStatus(
    actor: JwtAccessPayload,
    orderId: string,
    dto: UpdateOrderStatusDto,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    const fulfillments = ((order as any).vendorFulfillments ?? []) as any[];
    let isMember: {
      id: string;
      branchId: string | null;
      role?: string;
      vendorId?: string;
    } | null = null;
    let matchingFulfillments: any[] = [];

    if (fulfillments.length > 0) {
      const portionVendorIds = Array.from(
        new Set(fulfillments.map((f: any) => f.vendorId)),
      ) as string[];
      const members = await this.prisma.vendorMember.findMany({
        where: {
          userId: actor.sub,
          vendorId: { in: portionVendorIds },
        },
        select: { id: true, branchId: true, role: true, vendorId: true },
      });
      const preferredVendorId = dto.fulfillmentId
        ? fulfillments.find((f: any) => f.id === dto.fulfillmentId)?.vendorId
        : undefined;
      const member =
        (preferredVendorId
          ? members.find((m) => m.vendorId === preferredVendorId)
          : undefined) ??
        members.find((m) => {
          const effBranch = m.role === 'OWNER' ? null : m.branchId;
          return fulfillments.some(
            (f: any) =>
              f.vendorId === m.vendorId &&
              (!effBranch ||
                !f.vendorBranchId ||
                f.vendorBranchId === effBranch),
          );
        }) ??
        members[0];
      if (member) {
        isMember = member;
        const effectiveBranchId =
          member.role === 'OWNER' ? null : member.branchId;
        const vendorPortions = fulfillments.filter(
          (f: any) => f.vendorId === member.vendorId,
        );
        matchingFulfillments = effectiveBranchId
          ? vendorPortions.filter(
              (f: any) =>
                !f.vendorBranchId || f.vendorBranchId === effectiveBranchId,
            )
          : vendorPortions;
      }
    }

    const canManage = await this.auth.canManageOrders(actor.sub, actor.role);

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_MEMBER_OF_VENDOR);
    }

    if (!isMember && canManage && fulfillments.length > 0) {
      matchingFulfillments = fulfillments;
    }

    const memberEffectiveBranchId =
      isMember && isMember.role !== 'OWNER' ? isMember.branchId : null;

    if (
      isMember &&
      memberEffectiveBranchId &&
      fulfillments.length > 0 &&
      matchingFulfillments.length === 0
    ) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
    }

    // For multi-vendor / multi-branch orders, decisions/production are per fulfillment
    if (matchingFulfillments.length > 0) {
      let targetFulfillments = matchingFulfillments;
      if (dto.fulfillmentId) {
        if (!fulfillments.some((f: any) => f.id === dto.fulfillmentId)) {
          throw new NotFoundException(OrderErrors.FULFILLMENT_NOT_FOUND);
        }
        targetFulfillments = matchingFulfillments.filter(
          (f: any) => f.id === dto.fulfillmentId,
        );
        if (targetFulfillments.length === 0) {
          throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_BRANCH);
        }
      }

      if (dto.status === OrderStatus.ACCEPTED) {
        for (const f of targetFulfillments) {
          if (f.status === 'PENDING') {
            await this.vendorDecisionService.accept(actor, f.id);
          }
        }
        return this.ordersRepository.findById(orderId);
      }
      if (dto.status === OrderStatus.CANCELLED) {
        if (!isMember && canManage && !dto.fulfillmentId) {
          return this.cancelOrder(
            actor,
            orderId,
            dto.note ?? 'Cancelled by admin',
          );
        }
        for (const f of targetFulfillments) {
          if (f.status !== 'REJECTED' && f.status !== 'CANCELLED') {
            await this.vendorDecisionService.reject(actor, f.id, {
              code: 'VENDOR_CANCELLED',
              reason: dto.note ?? 'Cancelled by vendor',
            });
          }
        }
        return this.ordersRepository.findById(orderId);
      }
      if (
        dto.status === OrderStatus.PREPARING ||
        dto.status === OrderStatus.READY_FOR_PICKUP
      ) {
        let lastResult: any = null;
        const eligible = targetFulfillments.filter(
          (f: any) => f.status === 'ACCEPTED' || f.status === 'PREPARING',
        );
        for (const f of eligible) {
          lastResult =
            await this.fulfillmentTransition.applyFulfillmentProductionTransition(
              actor,
              order,
              f,
              dto,
            );
        }
        return lastResult ?? this.ordersRepository.findById(orderId);
      }
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

    const groups = (
      ((order as any).deliveryGroups ?? []) as DeliveryGroupSummary[]
    ).filter(Boolean);

    if (groups.length > 0) {
      return this.deliveryGroup.advanceGroupByDriver(
        actor,
        order,
        driver.id,
        groups,
        dto,
      );
    }

    throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
  }

  async driverConfirmFulfillmentPickup(
    actor: JwtAccessPayload,
    orderId: string,
    fulfillmentId: string,
    file: Express.Multer.File,
  ) {
    return this.fulfillmentTransition.driverConfirmFulfillmentPickup(
      actor,
      orderId,
      fulfillmentId,
      file,
      async (imageUrl) => {
        await this.driverUpdateStatus(actor, orderId, {
          status: OrderStatus.PICKED_UP,
          pickupImageUrl: imageUrl,
        });
      },
    );
  }

  async driverConfirmPickup(
    actor: JwtAccessPayload,
    orderId: string,
    file: Express.Multer.File,
    fulfillmentId?: string,
  ) {
    if (fulfillmentId) {
      return this.driverConfirmFulfillmentPickup(
        actor,
        orderId,
        fulfillmentId,
        file,
      );
    }

    const order = await this.ordersRepository.findById(orderId);
    if (
      order &&
      order.vendorFulfillments &&
      order.vendorFulfillments.length > 0
    ) {
      const driver = await this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      });
      let candidateFulfillments: any[] = order.vendorFulfillments;
      if (
        driver &&
        Array.isArray((order as any).deliveryGroups) &&
        (order as any).deliveryGroups.length > 0
      ) {
        const myGroups = (order as any).deliveryGroups.filter(
          (g: any) =>
            g.status !== DeliveryGroupStatus.CANCELLED &&
            g.status !== DeliveryGroupStatus.DELIVERED &&
            (g.primaryDriverId === driver.id ||
              g.assistDriverId === driver.id),
        );
        const myGroupItems = myGroups
          .flatMap((g: any) => (Array.isArray(g.items) ? g.items : []))
          .sort((a: any, b: any) => (a.sequence ?? 0) - (b.sequence ?? 0));
        if (myGroupItems.length > 0) {
          const byId = new Map(
            order.vendorFulfillments.map((f: any) => [f.id, f]),
          );
          candidateFulfillments = myGroupItems
            .map((it: any) => byId.get(it.fulfillmentId))
            .filter(Boolean);
        }
      }
      const nextUnpicked = candidateFulfillments.find(
        (f: any) =>
          f.status !== 'REJECTED' &&
          f.status !== 'CANCELLED' &&
          !f.pickedUpAt,
      );
      if (nextUnpicked) {
        return this.driverConfirmFulfillmentPickup(
          actor,
          orderId,
          nextUnpicked.id,
          file,
        );
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
      });
    } catch (error) {
      await this.storage.delete(imageUrl);
      throw error;
    }
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

    if (dto.response === 'ACCEPTED' && driver.status === 'ON_BREAK') {
      throw new BadRequestException(DriverErrors.CANNOT_ACCEPT_ON_BREAK);
    }

    const orderId = await this.dispatchPort.verifyPendingDispatch(
      dispatchId,
      driver.id,
    );
    if (!orderId) {
      throw new BadRequestException(OrderErrors.DISPATCH_NOT_FOUND);
    }

    if (dto.response === 'ACCEPTED') {
      try {
        const assigned = await this.dispatchPort.handleAcceptance(
          dispatchId,
          driver.id,
        );
        if (!assigned) {
          throw new BadRequestException(
            OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED,
          );
        }

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
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PARTIALLY_PICKED_UP,
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

    if (driver.status === 'ON_BREAK') {
      throw new BadRequestException(DriverErrors.CANNOT_ASSIGN_ON_BREAK);
    }

    const settings = await this.prisma.platformSetting.findUnique({
      where: { id: 'default' },
      select: { maxActiveOrdersPerDriver: true },
    });
    const maxActive = settings?.maxActiveOrdersPerDriver ?? 1;

    const activeOrdersCount = await this.driverWorkload.countActiveUnits(
      this.prisma,
      driver.id,
      orderId,
    );
    if (activeOrdersCount >= maxActive) {
      throw new BadRequestException(OrderErrors.DRIVER_ALREADY_ON_ORDER);
    }

    const activeShift = await this.prisma.driverShift.findFirst({
      where: { driverId: driver.id, status: 'ACTIVE' },
      select: { id: true },
    });

    const nextStatus =
      (order.paymentMethod === 'MOBILE_WALLET' ||
        Number((order as any).upfrontAmount ?? 0) > 0) &&
      order.paymentStatus !== 'COMPLETED'
        ? OrderStatus.PENDING_PAYMENT
        : OrderStatus.DRIVER_ASSIGNED;

    const freshOrder = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (!freshOrder || !assignableStatuses.includes(freshOrder.status)) {
      throw new BadRequestException(OrderErrors.CANNOT_FORCE_ASSIGN_DRIVER);
    }

    const existingGroups = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        orderId,
        status: { not: DeliveryGroupStatus.CANCELLED },
      },
      select: {
        id: true,
        sequence: true,
        status: true,
        primaryDriverId: true,
        assistDriverId: true,
      },
      orderBy: { sequence: 'asc' },
    });

    const assignableGroupStatuses: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.PENDING,
      DeliveryGroupStatus.ACCEPTED,
      DeliveryGroupStatus.LOOKING_FOR_DRIVER,
      DeliveryGroupStatus.PREPARING,
      DeliveryGroupStatus.READY_FOR_PICKUP,
      DeliveryGroupStatus.DRIVER_ASSIGNED,
      DeliveryGroupStatus.PENDING_PAYMENT,
    ];
    const targetGroup = dto.deliveryGroupId
      ? existingGroups.find((g) => g.id === dto.deliveryGroupId)
      : (existingGroups.find(
          (g) =>
            !g.primaryDriverId && assignableGroupStatuses.includes(g.status),
        ) ??
        existingGroups.find((g) => assignableGroupStatuses.includes(g.status)));

    if (!targetGroup || !assignableGroupStatuses.includes(targetGroup.status)) {
      throw new BadRequestException(OrderErrors.CANNOT_FORCE_ASSIGN_DRIVER);
    }

    const updated = await this.ordersRepository.assignDriver(
      orderId,
      driver.id,
      activeShift?.id ?? null,
      actor.sub,
      nextStatus,
      maxActive,
      targetGroup.id,
    );

    await this.prisma.orderDeliveryGroup.update({
      where: { id: targetGroup.id },
      data: { assignedByUserId: actor.sub },
    });

    if (
      targetGroup.primaryDriverId &&
      targetGroup.primaryDriverId !== driver.id
    ) {
      await this.ordersRepository.freeDriver(targetGroup.primaryDriverId);
    }

    const distinctVendorIds = Array.from(
      new Set(
        (((order as any).vendorFulfillments ?? []) as Array<{ vendorId: string }>)
          .map((f) => f.vendorId)
          .filter(Boolean),
      ),
    );
    const singleVendorId =
      distinctVendorIds.length === 1 ? distinctVendorIds[0] : null;
    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
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
        singleVendorId,
        vendorUserIds,
        driver.id,
        driver.userId,
        actor.sub,
        `Driver manually assigned by admin. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
        updated.revision,
      ),
    );

    this.logger.log(
      `Admin ${actor.sub} force-assigned driver ${driver.id} to order ${order.orderNumber} (group ${targetGroup.sequence})`,
    );
    return this.ordersRepository.findById(orderId);
  }

  async cancelOrder(
    actor: JwtAccessPayload | null,
    orderId: string,
    reason: string,
  ) {
    if (actor?.role === Role.VENDOR_MEMBER) {
      const order = await this.ordersRepository.findById(orderId);
      if ((((order as any).vendorFulfillments ?? []) as any[]).length > 0) {
        return this.vendorUpdateStatus(actor, orderId, {
          status: OrderStatus.CANCELLED,
          note: reason,
        });
      }
    }
    return this.cancellation.cancelOrder(actor, orderId, reason);
  }

  private async applyStatusTransition(
    actor: JwtAccessPayload,
    order: {
      id: string;
      status: string;
      orderNumber: string;
      customerId: string;
      customer: { user: { id: string } };
      vendorFulfillments?: Array<{ vendorId: string }>;
      deliveryGroups?: Array<{
        primaryDriverId: string | null;
        primaryDriver?: { userId: string } | null;
        isPaymentCollector?: boolean;
      }>;
    },
    dto: UpdateOrderStatusDto,
  ) {
    const oldStatus = order.status as OrderStatus;
    const newStatus = dto.status;

    if (newStatus === OrderStatus.READY_FOR_PICKUP) {
      const grouped = ((order as any).deliveryGroups ?? []) as Array<{
        id: string;
      }>;
      if (grouped.length > 0) {
        const now = new Date();
        await this.prisma.orderVendorFulfillment.updateMany({
          where: {
            orderId: order.id,
            status: { in: ['ACCEPTED', 'PREPARING'] },
            readyAt: null,
          },
          data: {
            status: OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
            preparingAt: now,
            readyAt: now,
          },
        });
        await this.prisma.orderDeliveryGroup.updateMany({
          where: {
            orderId: order.id,
            status: {
              in: [
                DeliveryGroupStatus.DRIVER_ASSIGNED,
                DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                DeliveryGroupStatus.PREPARING,
                DeliveryGroupStatus.ACCEPTED,
              ],
            },
          },
          data: { status: DeliveryGroupStatus.READY_FOR_PICKUP },
        });
      }
    }

    const extraData: Prisma.OrderUpdateInput = {};
    if (newStatus === OrderStatus.DELIVERED) {
      extraData.actualDeliveryTime = new Date();
    }

    const updated = await this.ordersRepository.updateStatus(
      order.id,
      newStatus,
      actor.sub,
      dto.note,
      extraData,
      oldStatus,
    );

    const groups = (order.deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId?: string | null;
      primaryDriver?: { userId: string } | null;
      isPaymentCollector?: boolean;
    }>;

    if (newStatus === OrderStatus.DELIVERED) {
      const driverIds = groups
        .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
        .filter((id): id is string => Boolean(id));
      for (const did of new Set(driverIds)) {
        await this.ordersRepository.freeDriver(did);
      }
    }

    const distinctVendorIds = Array.from(
      new Set((order.vendorFulfillments ?? []).map((f) => f.vendorId)),
    );
    const singleVendorId =
      distinctVendorIds.length === 1 ? distinctVendorIds[0] : null;
    const collectorGroup =
      groups.find((g) => g.isPaymentCollector && g.primaryDriverId) ??
      groups.find((g) => g.primaryDriverId) ??
      null;
    const primaryDriverId = collectorGroup?.primaryDriverId ?? null;
    const driverUserId = collectorGroup?.primaryDriver?.userId ?? null;

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
    );

    this.eventEmitter.emit(
      EVENTS.ORDER_STATUS_CHANGED,
      new OrderStatusChangedEvent(
        order.id,
        order.orderNumber,
        oldStatus,
        newStatus,
        order.customerId,
        order.customer.user.id,
        singleVendorId,
        vendorUserIds,
        primaryDriverId,
        driverUserId,
        actor.sub,
        dto.note ?? null,
        updated.revision,
      ),
    );

    this.logger.log(`Order ${order.orderNumber}: ${oldStatus} → ${newStatus}`);
    return updated;
  }

  async recomputeGroupedOrderStatusAfterCancel(
    orderId: string,
    extraDriverIds: Array<string | null | undefined> = [],
  ): Promise<void> {
    await this.deliveryGroup.recomputeGroupedOrderStatusAfterCancel(
      orderId,
      extraDriverIds,
    );
  }

  async cancelDeliveryGroupAfterAssistFailure(
    orderId: string,
    deliveryGroupId: string,
    reason: string,
    extraDriverIds: Array<string | null | undefined> = [],
  ): Promise<void> {
    const result = await this.deliveryGroup.cancelDeliveryGroupAndRecompute({
      orderId,
      deliveryGroupId,
      reason,
      extraDriverIds,
      requireDriverless: false,
    });
    if (!result.groupCancelled) {
      await this.deliveryGroup.recomputeGroupedOrderStatusAfterCancel(
        orderId,
        extraDriverIds,
      );
    }
  }
}
