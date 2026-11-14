import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Prisma,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { OrdersRepository } from '../orders.repository';
import { UpdateOrderStatusDto } from '../dto/order.dto';
import { DRIVER_ALLOWED_TRANSITIONS } from './order-state.constants';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { OrderStatusChangedEvent } from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import { OrderErrors } from '../../../common/constants/response.constants';

export interface DeliveryGroupSummary {
  id: string;
  sequence: number;
  status: DeliveryGroupStatus;
  primaryDriverId: string | null;
  assistDriverId?: string | null;
  pickupImageUrl: string | null;
  deliveryImageUrl: string | null;
}

/**
 * Manages the lifecycle of `OrderDeliveryGroup` entities and recomputes
 * aggregate customer-facing order statuses from active delivery groups.
 */
@Injectable()
export class DeliveryGroupTransitionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ordersRepository: OrdersRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async advanceGroupByDriver(
    actor: JwtAccessPayload,
    order: any,
    driverId: string,
    groups: DeliveryGroupSummary[],
    dto: UpdateOrderStatusDto,
  ) {
    const activeGroups = groups.filter(
      (g) =>
        g.primaryDriverId === driverId &&
        g.status !== DeliveryGroupStatus.CANCELLED,
    );
    const group = (dto as any).deliveryGroupId
      ? activeGroups.find((g) => g.id === (dto as any).deliveryGroupId)
      : (activeGroups.find((g) => g.status !== DeliveryGroupStatus.DELIVERED) ??
        activeGroups[0]);
    if (!group) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    const expected = DRIVER_ALLOWED_TRANSITIONS[group.status as OrderStatus];
    if (!expected || !expected.includes(dto.status)) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    if (
      order.type === 'STANDARD' &&
      (dto.status === OrderStatus.READY_FOR_PICKUP ||
        (group.status === DeliveryGroupStatus.DRIVER_ASSIGNED &&
          dto.status === OrderStatus.PICKED_UP))
    ) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    if (
      dto.status === OrderStatus.PICKED_UP ||
      dto.status === OrderStatus.DELIVERED
    ) {
      const groupItems = await this.prisma.orderDeliveryGroupItem.findMany({
        where: { deliveryGroupId: group.id },
        include: { fulfillment: true },
        orderBy: { sequence: 'asc' },
      });
      const activeFulfillments = groupItems
        .map((it) => it.fulfillment)
        .filter(
          (f): f is NonNullable<typeof f> =>
            Boolean(f) && f.status !== 'REJECTED' && f.status !== 'CANCELLED',
        );

      if (dto.status === OrderStatus.PICKED_UP) {
        const anyUnready = activeFulfillments.some(
          (f) =>
            f.status !== OrderVendorFulfillmentStatus.READY_FOR_PICKUP &&
            f.status !== OrderVendorFulfillmentStatus.PICKED_UP &&
            !f.readyAt &&
            !f.pickedUpAt,
        );
        if (anyUnready) {
          throw new BadRequestException(
            'Vendor has not marked this portion ready for pickup yet',
          );
        }
        if (activeFulfillments.length > 1) {
          const anyUncollected = activeFulfillments.some(
            (f) =>
              !f.pickedUpAt &&
              f.status !== OrderVendorFulfillmentStatus.PICKED_UP,
          );
          if (anyUncollected) {
            throw new BadRequestException(
              'All vendor pickup stops must be collected before marking group picked up',
            );
          }
        }
      }

      if (dto.status === OrderStatus.DELIVERED) {
        const anyUncollected = activeFulfillments.some(
          (f) =>
            !f.pickedUpAt &&
            f.status !== OrderVendorFulfillmentStatus.PICKED_UP,
        );
        if (anyUncollected) {
          throw new BadRequestException(
            'All vendor portions must be collected before marking delivered',
          );
        }
      }
    }

    // Proof photos belong strictly to the delivery that produced them.
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
      (order.paymentMethod === PaymentMethod.MOBILE_WALLET ||
        Number(order.upfrontAmount ?? 0) > 0) &&
      order.paymentStatus !== 'COMPLETED' &&
      dto.status !== OrderStatus.PENDING_PAYMENT
    ) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }

    return this.applyGroupStatusTransition(actor, order, group, dto);
  }

  /**
   * Advance ONE delivery group through its own lifecycle and recompute the
   * aggregate customer-facing order status using optimistic CAS.
   */
  async applyGroupStatusTransition(
    actor: JwtAccessPayload,
    order: any,
    group: {
      id: string;
      sequence: number;
      status: DeliveryGroupStatus;
      primaryDriverId?: string | null;
      assistDriverId?: string | null;
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

    if (dto.status === OrderStatus.PICKED_UP) {
      await this.prisma.orderVendorFulfillment.updateMany({
        where: {
          groups: { some: { deliveryGroupId: group.id } },
          status: { notIn: ['REJECTED', 'CANCELLED', 'PICKED_UP'] },
          pickedUpAt: null,
        },
        data: {
          status: OrderVendorFulfillmentStatus.PICKED_UP,
          pickedUpAt: new Date(),
          ...(dto.pickupImageUrl ? { pickupImageUrl: dto.pickupImageUrl } : {}),
          ...(group.primaryDriverId
            ? { pickedUpByDriverId: group.primaryDriverId }
            : {}),
        },
      });
    }

    if (dto.status === OrderStatus.DELIVERED) {
      await this.prisma.orderVendorFulfillment.updateMany({
        where: {
          groups: { some: { deliveryGroupId: group.id } },
          status: { notIn: ['REJECTED', 'CANCELLED'] },
        },
        data: {
          deliveredAt: new Date(),
        },
      });
      const groupDriverIds = [
        group.primaryDriverId,
        group.assistDriverId,
      ].filter((id): id is string => Boolean(id));
      for (const did of new Set(groupDriverIds)) {
        await this.ordersRepository.freeDriver(did);
      }
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

    if (dto.status === OrderStatus.DELIVERED) {
      const latest = await this.prisma.order.findUnique({
        where: { id: order.id },
        select: {
          status: true,
          customerId: true,
          vendorId: true,
          driverId: true,
          revision: true,
          customer: { select: { userId: true } },
        },
      });
      if (latest && latest.status !== OrderStatus.DELIVERED) {
        const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
          order.id,
          latest.vendorId,
        );
        this.eventEmitter.emit(
          EVENTS.ORDER_STATUS_CHANGED,
          new OrderStatusChangedEvent(
            order.id,
            order.orderNumber,
            latest.status,
            latest.status,
            latest.customerId,
            latest.customer?.userId ?? latest.customerId,
            latest.vendorId,
            vendorUserIds,
            group.primaryDriverId ?? latest.driverId,
            actor.sub,
            actor.sub,
            `Delivery ${group.sequence} completed`,
            latest.revision,
            `delivery:${group.sequence}`,
          ),
        );
      }
    }

    return this.ordersRepository.findById(order.id);
  }

  /**
   * Recompute the aggregate order status from its (non-cancelled) delivery groups.
   */
  async recomputeGroupedOrderStatus(
    actor: JwtAccessPayload,
    order: any,
  ): Promise<void> {
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: order.id },
      select: {
        id: true,
        status: true,
        primaryDriverId: true,
        assistDriverId: true,
      },
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
        revision: true,
        customerId: true,
        vendorId: true,
        driverId: true,
        paymentMethod: true,
        upfrontAmount: true,
        paymentStatus: true,
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
    const somePickedUp = active.some(
      (g) =>
        g.status === DeliveryGroupStatus.PICKED_UP ||
        g.status === DeliveryGroupStatus.PARTIALLY_PICKED_UP ||
        g.status === DeliveryGroupStatus.DELIVERED,
    );

    let target: OrderStatus | null = null;
    if (allDelivered) {
      target = OrderStatus.DELIVERED;
    } else if (allPickedUp && fresh.status !== OrderStatus.PICKED_UP) {
      target = OrderStatus.PICKED_UP;
    } else if (
      somePickedUp &&
      fresh.status !== OrderStatus.PARTIALLY_PICKED_UP &&
      fresh.status !== OrderStatus.PICKED_UP &&
      fresh.status !== OrderStatus.DELIVERED
    ) {
      target = OrderStatus.PARTIALLY_PICKED_UP;
    }
    if (!target || fresh.status === target) return;

    if (
      fresh.status === OrderStatus.PENDING_PAYMENT &&
      (fresh.paymentMethod === 'MOBILE_WALLET' ||
        Number(fresh.upfrontAmount ?? 0) > 0) &&
      fresh.paymentStatus !== 'COMPLETED'
    ) {
      return;
    }

    const allowedFrom: Record<string, OrderStatus[]> = {
      [OrderStatus.PARTIALLY_PICKED_UP]: [
        OrderStatus.DRIVER_ASSIGNED,
        OrderStatus.PENDING_PAYMENT,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.ACCEPTED,
        OrderStatus.LOOKING_FOR_DRIVER,
      ],
      [OrderStatus.PICKED_UP]: [
        OrderStatus.DRIVER_ASSIGNED,
        OrderStatus.PENDING_PAYMENT,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.ACCEPTED,
        OrderStatus.LOOKING_FOR_DRIVER,
        OrderStatus.PARTIALLY_PICKED_UP,
      ],
      [OrderStatus.DELIVERED]: [
        OrderStatus.PICKED_UP,
        OrderStatus.PARTIALLY_PICKED_UP,
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.DRIVER_ASSIGNED,
        OrderStatus.PENDING_PAYMENT,
      ],
    };
    if (!(allowedFrom[target] ?? []).includes(fresh.status)) {
      return;
    }

    const extraData: Prisma.OrderUpdateInput = {};
    if (target === OrderStatus.PICKED_UP) extraData.pickedUpAt = new Date();
    if (target === OrderStatus.DELIVERED) {
      extraData.actualDeliveryTime = new Date();
    }

    let updatedRevision = fresh.revision;
    try {
      const updated = await this.ordersRepository.updateStatus(
        order.id,
        target,
        actor.sub,
        target === OrderStatus.DELIVERED
          ? 'All deliveries completed'
          : target === OrderStatus.PICKED_UP
            ? 'All deliveries picked up'
            : 'Driver is collecting portions from stores',
        extraData,
        fresh.status,
      );
      updatedRevision = updated.revision;
    } catch {
      return;
    }

    if (target === OrderStatus.DELIVERED) {
      const driverIds = [
        fresh.driverId,
        ...groups.flatMap((g) => [g.primaryDriverId, g.assistDriverId]),
      ].filter((d): d is string => !!d);
      for (const driverId of new Set(driverIds)) {
        await this.ordersRepository.freeDriver(driverId);
      }
    }

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
          : target === OrderStatus.PICKED_UP
            ? 'All deliveries picked up'
            : 'Driver is collecting portions from stores',
        updatedRevision,
      ),
    );
  }

  /**
   * Synchronize fulfillments, driver pointers, driver availability, and
   * aggregate order status after one or more delivery groups are cancelled.
   */
  async recomputeGroupedOrderStatusAfterCancel(
    orderId: string,
    extraDriverIds: Array<string | null | undefined> = [],
  ): Promise<void> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, orderNumber: true, driverId: true },
    });
    if (!order) return;

    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId },
      select: {
        id: true,
        status: true,
        primaryDriverId: true,
        assistDriverId: true,
      },
      orderBy: { sequence: 'asc' },
    });

    const cancelledGroups = groups.filter(
      (g) => g.status === DeliveryGroupStatus.CANCELLED,
    );
    const activeGroups = groups.filter(
      (g) => g.status !== DeliveryGroupStatus.CANCELLED,
    );

    if (cancelledGroups.length > 0) {
      await this.prisma.orderVendorFulfillment.updateMany({
        where: {
          groups: {
            some: {
              deliveryGroupId: { in: cancelledGroups.map((g) => g.id) },
            },
          },
          status: {
            notIn: [
              OrderVendorFulfillmentStatus.REJECTED,
              OrderVendorFulfillmentStatus.CANCELLED,
            ],
          },
          deliveredAt: null,
        },
        data: { status: OrderVendorFulfillmentStatus.CANCELLED },
      });
    }

    const activeDriverSet = new Set(
      activeGroups
        .filter((g) => g.status !== DeliveryGroupStatus.DELIVERED)
        .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
        .filter((id): id is string => Boolean(id)),
    );

    if (
      order.driverId &&
      !activeGroups.some((g) => g.primaryDriverId === order.driverId)
    ) {
      const replacementGroup = activeGroups.find((g) => g.primaryDriverId);
      await this.prisma.order.update({
        where: { id: orderId },
        data: {
          driverId: replacementGroup?.primaryDriverId ?? null,
          revision: { increment: 1 },
        },
      });
    }

    const driversToCheck = new Set(
      [
        ...cancelledGroups.flatMap((g) => [
          g.primaryDriverId,
          g.assistDriverId,
        ]),
        ...extraDriverIds,
      ].filter((id): id is string => Boolean(id)),
    );
    for (const did of driversToCheck) {
      if (!activeDriverSet.has(did)) {
        await this.ordersRepository.freeDriver(did);
      }
    }

    await this.recomputeGroupedOrderStatus(
      { sub: 'system', role: Role.SUPER_ADMIN } as JwtAccessPayload,
      order,
    );
  }
}
