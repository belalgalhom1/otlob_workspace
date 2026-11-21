import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderType,
  OrderVendorFulfillmentStatus,
  PaymentMethod,
  Prisma,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { OrdersRepository } from '../orders.repository';
import { UpdateOrderStatusDto } from '../dto/order.dto';
import {
  DRIVER_ALLOWED_TRANSITIONS,
  requiresOrderProofPhotos,
} from './order-state.constants';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import {
  OrderFulfillmentDecidedEvent,
  OrderStatusChangedEvent,
  OrderVendorRejectedEvent,
} from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import { OrderErrors } from '../../../common/constants/response.constants';
import { StockService } from '../helpers/stock.service';
import { OrderRejectionRecomputor } from '../helpers/order-rejection-recomputor';
import { OrderCancellationService } from './order-cancellation.service';
import {
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
  systemActorSnapshot,
} from '../helpers/order-actor.helper';

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
    @Optional() private readonly stockService?: StockService,
    @Optional() private readonly recomputor?: OrderRejectionRecomputor,
    @Optional() private readonly cancellationService?: OrderCancellationService,
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
        (g.primaryDriverId === driverId || g.assistDriverId === driverId) &&
        g.status !== DeliveryGroupStatus.CANCELLED,
    );
    const group = (dto as any).deliveryGroupId
      ? activeGroups.find((g) => g.id === (dto as any).deliveryGroupId)
      : (activeGroups.find((g) => g.status !== DeliveryGroupStatus.DELIVERED) ??
        activeGroups[0]);
    if (!group) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }
    if (
      group.primaryDriverId !== driverId &&
      (dto.status === OrderStatus.DELIVERED ||
        dto.status === OrderStatus.PENDING_PAYMENT)
    ) {
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

    // Proof photos belong strictly to the delivery that produced them, and
    // are skipped for normal passenger rides (OrderType.RIDE).
    if (requiresOrderProofPhotos(order.type)) {
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

    const driverActorSnapshot = await resolveOrderActorSnapshot(
      this.prisma,
      actor.sub,
      { orderId: order.id },
    );
    await recordOrderStatusEventIdempotent(this.prisma, {
      orderId: order.id,
      deliveryGroupId: group.id,
      eventKey: `group_transition:${group.id}:${group.status}:${dto.status}`,
      status:
        dto.status === OrderStatus.DELIVERED
          ? OrderStatus.DELIVERED
          : dto.status === OrderStatus.PICKED_UP
            ? OrderStatus.PICKED_UP
            : order.status,
      note:
        order.type === OrderType.RIDE
          ? `Ride ${group.sequence}: ${group.status} → ${dto.status}`
          : `Delivery ${group.sequence}: ${group.status} → ${dto.status}`,
      createdBy: actor.sub,
      actor: driverActorSnapshot,
    });

    await this.recomputeGroupedOrderStatus(actor, order);

    if (dto.status === OrderStatus.DELIVERED) {
      const latest = await this.prisma.order.findUnique({
        where: { id: order.id },
        select: {
          status: true,
          customerId: true,
          revision: true,
          customer: { select: { userId: true } },
          vendorFulfillments: { select: { vendorId: true } },
        },
      });
      if (latest && latest.status !== OrderStatus.DELIVERED) {
        const uniqueVendorIds = Array.from(
          new Set(latest.vendorFulfillments.map((f) => f.vendorId)),
        );
        const singleVendorId =
          uniqueVendorIds.length === 1 ? uniqueVendorIds[0] : null;
        const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
          order.id,
          null,
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
            singleVendorId,
            vendorUserIds,
            group.primaryDriverId ?? null,
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
        sequence: true,
        status: true,
        isPaymentCollector: true,
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
        paymentMethod: true,
        upfrontAmount: true,
        paymentStatus: true,
        customer: { select: { userId: true } },
        vendorFulfillments: { select: { vendorId: true } },
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
        OrderStatus.PREPARING,
        OrderStatus.DRIVER_ASSIGNED,
        OrderStatus.PENDING_PAYMENT,
      ],
    };
    if (!(allowedFrom[target] ?? []).includes(fresh.status)) {
      return;
    }

    const extraData: Prisma.OrderUpdateInput = {};
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
      const driverIds = groups
        .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
        .filter((d): d is string => !!d);
      for (const driverId of new Set(driverIds)) {
        await this.ordersRepository.freeDriver(driverId);
      }
    }

    const uniqueVendorIds: string[] = Array.from(
      new Set<string>(
        ((fresh.vendorFulfillments ?? []) as Array<{ vendorId: string }>).map(
          (f) => f.vendorId,
        ),
      ),
    );
    const singleVendorId =
      uniqueVendorIds.length === 1 ? uniqueVendorIds[0] : null;
    const collectorDriverId =
      active.find((g) => g.isPaymentCollector)?.primaryDriverId ??
      active.find((g) => g.primaryDriverId)?.primaryDriverId ??
      null;

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
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
        singleVendorId,
        vendorUserIds,
        collectorDriverId,
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
      select: { id: true, orderNumber: true },
    });
    if (!order) return;

    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId },
      select: {
        id: true,
        status: true,
        isPaymentCollector: true,
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

    // Ensure at least one surviving active group remains the designated payment collector.
    if (
      activeGroups.length > 0 &&
      !activeGroups.some((g) => g.isPaymentCollector)
    ) {
      const replacementCollector =
        activeGroups.find((g) => g.primaryDriverId) ?? activeGroups[0];
      await this.prisma.$transaction([
        this.prisma.orderDeliveryGroup.updateMany({
          where: { orderId, id: { not: replacementCollector.id } },
          data: { isPaymentCollector: false },
        }),
        this.prisma.orderDeliveryGroup.updateMany({
          where: { id: replacementCollector.id },
          data: { isPaymentCollector: true },
        }),
      ]);
    }

    const activeDriverSet = new Set(
      activeGroups
        .filter((g) => g.status !== DeliveryGroupStatus.DELIVERED)
        .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
        .filter((id): id is string => Boolean(id)),
    );

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

    if (
      activeGroups.length > 0 &&
      !activeGroups.some(
        (g) =>
          g.status === DeliveryGroupStatus.PICKED_UP ||
          g.status === DeliveryGroupStatus.PARTIALLY_PICKED_UP ||
          g.status === DeliveryGroupStatus.DELIVERED,
      )
    ) {
      const fresh = await this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
          status: true,
          customerId: true,
          customer: { select: { userId: true } },
          vendorFulfillments: {
            where: {
              status: {
                notIn: [
                  OrderVendorFulfillmentStatus.CANCELLED,
                  OrderVendorFulfillmentStatus.REJECTED,
                ],
              },
            },
            select: { vendorId: true },
          },
        },
      });
      if (
        fresh &&
        fresh.status !== OrderStatus.CANCELLED &&
        fresh.status !== OrderStatus.DELIVERED &&
        fresh.status !== OrderStatus.PICKED_UP &&
        fresh.status !== OrderStatus.PARTIALLY_PICKED_UP
      ) {
        let prePickupTarget: OrderStatus | null = null;
        if (
          activeGroups.every(
            (g) => g.status === DeliveryGroupStatus.READY_FOR_PICKUP,
          )
        ) {
          prePickupTarget = OrderStatus.READY_FOR_PICKUP;
        } else if (
          activeGroups.some(
            (g) =>
              g.status === DeliveryGroupStatus.PREPARING ||
              g.status === DeliveryGroupStatus.READY_FOR_PICKUP,
          )
        ) {
          prePickupTarget = OrderStatus.PREPARING;
        } else if (
          activeGroups.some(
            (g) => g.status === DeliveryGroupStatus.PENDING_PAYMENT,
          )
        ) {
          prePickupTarget = OrderStatus.PENDING_PAYMENT;
        } else if (
          activeGroups.some(
            (g) =>
              g.status === DeliveryGroupStatus.DRIVER_ASSIGNED ||
              g.primaryDriverId != null,
          )
        ) {
          prePickupTarget = OrderStatus.DRIVER_ASSIGNED;
        } else if (
          activeGroups.some(
            (g) => g.status === DeliveryGroupStatus.LOOKING_FOR_DRIVER,
          )
        ) {
          prePickupTarget = OrderStatus.LOOKING_FOR_DRIVER;
        } else if (
          activeGroups.some((g) => g.status === DeliveryGroupStatus.ACCEPTED)
        ) {
          prePickupTarget = OrderStatus.ACCEPTED;
        }

        if (prePickupTarget && prePickupTarget !== fresh.status) {
          try {
            const updated = await this.ordersRepository.updateStatus(
              orderId,
              prePickupTarget,
              'system',
              'Recomputed order status after delivery group cancellation',
              undefined,
              fresh.status,
            );
            const uniqueVendorIds = Array.from(
              new Set(fresh.vendorFulfillments.map((f) => f.vendorId)),
            );
            const singleVendorId =
              uniqueVendorIds.length === 1 ? uniqueVendorIds[0] : null;
            const collectorDriverId =
              activeGroups.find((g) => g.isPaymentCollector)?.primaryDriverId ??
              activeGroups.find((g) => g.primaryDriverId)?.primaryDriverId ??
              null;
            const vendorUserIds =
              await this.ordersRepository.getOrderVendorUserIds(orderId, null);
            this.eventEmitter.emit(
              EVENTS.ORDER_STATUS_CHANGED,
              new OrderStatusChangedEvent(
                orderId,
                order.orderNumber,
                fresh.status,
                prePickupTarget,
                fresh.customerId,
                fresh.customer?.userId ?? fresh.customerId,
                singleVendorId,
                vendorUserIds,
                collectorDriverId,
                null,
                'system',
                'Recomputed order status after delivery group cancellation',
                updated.revision,
              ),
            );
          } catch {
            // Concurrent transition won
          }
        }
      }
    }
  }

  /**
   * Cancel a single delivery group (e.g. undispatchable timeout or assist refusal),
   * cancel its non-delivered fulfillments, restore their stock, recompute order totals,
   * and cancel the entire order if zero active delivery groups remain.
   */
  async cancelDeliveryGroupAndRecompute(params: {
    orderId: string;
    deliveryGroupId: string;
    reason: string;
    extraDriverIds?: Array<string | null | undefined>;
    requireDriverless?: boolean;
  }): Promise<{ groupCancelled: boolean; orderCancelled: boolean }> {
    const {
      orderId,
      deliveryGroupId,
      reason,
      extraDriverIds = [],
      requireDriverless = false,
    } = params;

    const txResult = await this.prisma.$transaction(async (tx) => {
      const group = await tx.orderDeliveryGroup.findFirst({
        where: { id: deliveryGroupId, orderId },
        select: {
          id: true,
          sequence: true,
          status: true,
          deliveryFee: true,
          primaryDriverId: true,
          assistDriverId: true,
          order: {
            select: {
              orderNumber: true,
              status: true,
              customerId: true,
              customer: { select: { userId: true } },
            },
          },
          items: {
            select: {
              fulfillment: {
                select: {
                  id: true,
                  vendorId: true,
                  vendorBranchId: true,
                  status: true,
                  subtotal: true,
                  commissionRate: true,
                  isContracted: true,
                  deliveredAt: true,
                  vendor: { select: { storeName: true, storeNameAr: true } },
                  items: {
                    where: { rejectedAt: null },
                    select: {
                      productId: true,
                      variantId: true,
                      productName: true,
                      quantity: true,
                      selectedUnit: true,
                    },
                  },
                },
              },
            },
          },
        },
      });
      if (!group) return null;
      if (
        group.status === DeliveryGroupStatus.CANCELLED ||
        group.status === DeliveryGroupStatus.DELIVERED ||
        group.status === DeliveryGroupStatus.PICKED_UP ||
        group.status === DeliveryGroupStatus.PARTIALLY_PICKED_UP
      ) {
        return null;
      }
      if (requireDriverless && group.primaryDriverId != null) {
        return null;
      }

      await tx.orderDispatch.updateMany({
        where: { deliveryGroupId, status: 'PENDING' },
        data: { status: 'CANCELLED' },
      });

      const cancelled = await tx.orderDeliveryGroup.updateMany({
        where: {
          id: deliveryGroupId,
          status: {
            notIn: [
              DeliveryGroupStatus.CANCELLED,
              DeliveryGroupStatus.DELIVERED,
              DeliveryGroupStatus.PICKED_UP,
              DeliveryGroupStatus.PARTIALLY_PICKED_UP,
            ],
          },
          ...(requireDriverless ? { primaryDriverId: null } : {}),
        },
        data: {
          status: DeliveryGroupStatus.CANCELLED,
          deliveryFee: 0,
        },
      });
      if (cancelled.count === 0) return null;

      let refundAmount = 0;
      let serviceFeeDelta = 0;
      const itemsToRestore: Array<{
        productId: string | null;
        variantId: string | null;
        quantity: number;
        selectedUnit: string | null;
      }> = [];

      const liveFulfillments = group.items
        .map((it) => it.fulfillment)
        .filter(
          (f) =>
            f &&
            f.status !== OrderVendorFulfillmentStatus.REJECTED &&
            f.status !== OrderVendorFulfillmentStatus.CANCELLED &&
            f.deliveredAt == null,
        );

      if (liveFulfillments.length > 0) {
        const fulfillmentIds = liveFulfillments.map((f) => f.id);
        await tx.orderVendorFulfillment.updateMany({
          where: { id: { in: fulfillmentIds } },
          data: {
            status: OrderVendorFulfillmentStatus.CANCELLED,
            rejectionReason: reason,
          },
        });
        await tx.orderItem.updateMany({
          where: { fulfillmentId: { in: fulfillmentIds }, rejectedAt: null },
          data: { rejectedAt: new Date() },
        });
        for (const f of liveFulfillments) {
          refundAmount += Number(f.subtotal ?? 0);
          if (!f.isContracted) {
            serviceFeeDelta -= Math.round(
              Number(f.subtotal ?? 0) * (Number(f.commissionRate ?? 0) / 100),
            );
          }
          itemsToRestore.push(...f.items);
        }
      }

      if (itemsToRestore.length > 0) {
        const stock = this.stockService ?? new StockService();
        await stock.restoreForItems(tx, itemsToRestore);
      }

      if (
        group.primaryDriverId &&
        typeof tx.driverDeliveryIncident?.create === 'function'
      ) {
        const isCustomerDecline = reason
          .toLowerCase()
          .includes('customer declined');
        await tx.driverDeliveryIncident.create({
          data: {
            orderId,
            deliveryGroupId,
            driverId: group.primaryDriverId,
            incidentType: 'DELIVERY_FAILURE',
            responsibility: isCustomerDecline
              ? 'CUSTOMER'
              : 'EXTERNAL_OR_SYSTEM',
            reason,
            reportedByUserId: null,
            occurredAt: new Date(),
          },
        });
      }

      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        deliveryGroupId,
        eventKey: `group_cancelled:${deliveryGroupId}`,
        status: group.order.status,
        note: `Delivery ${group.sequence} cancelled: ${reason}`,
        createdBy: 'system',
        actor: systemActorSnapshot(),
      });

      const remainingActiveCount = await tx.orderDeliveryGroup.count({
        where: {
          orderId,
          status: { not: DeliveryGroupStatus.CANCELLED },
        },
      });

      return {
        orderNumber: group.order.orderNumber,
        orderStatus: group.order.status,
        customerId: group.order.customerId,
        customerUserId: group.order.customer?.userId ?? group.order.customerId,
        cancelledFulfillments: liveFulfillments.map((f) => ({
          id: f.id,
          vendorId: f.vendorId,
          vendorBranchId: f.vendorBranchId ?? null,
          vendorName: f.vendor?.storeName ?? 'Store',
          vendorNameAr: f.vendor?.storeNameAr ?? null,
          subtotal: Number(f.subtotal ?? 0),
          itemNames: f.items.map((it) => it.productName).filter(Boolean),
        })),
        refundAmount,
        deliveryFeeDelta: -Number(group.deliveryFee ?? 0),
        serviceFeeDelta,
        remainingActiveCount,
        freedDriverIds: [
          group.primaryDriverId,
          group.assistDriverId,
          ...extraDriverIds,
        ].filter((id): id is string => Boolean(id)),
      };
    });

    if (!txResult) {
      return { groupCancelled: false, orderCancelled: false };
    }

    if (this.recomputor) {
      await this.recomputor.recomputeTotalsAfterRejection(
        orderId,
        txResult.refundAmount,
        txResult.deliveryFeeDelta,
        txResult.serviceFeeDelta,
      );
    }

    if (txResult.remainingActiveCount === 0 && this.cancellationService) {
      try {
        await this.cancellationService.cancelOrder(null, orderId, reason);
      } catch (err) {
        const latest = await this.prisma.order.findUnique({
          where: { id: orderId },
          select: { status: true },
        });
        if (latest?.status !== OrderStatus.CANCELLED) {
          throw err;
        }
      }
      return { groupCancelled: true, orderCancelled: true };
    }

    await this.recomputeGroupedOrderStatusAfterCancel(
      orderId,
      txResult.freedDriverIds,
    );

    const latestOrder = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true, revision: true },
    });

    for (const f of txResult.cancelledFulfillments) {
      const vendorUserIds = await this.ordersRepository.getVendorUserIds(
        f.vendorId,
        f.vendorBranchId,
      );
      this.eventEmitter.emit(
        EVENTS.ORDER_FULFILLMENT_DECIDED,
        new OrderFulfillmentDecidedEvent(
          orderId,
          txResult.orderNumber,
          txResult.customerId,
          txResult.customerUserId,
          f.id,
          f.vendorId,
          vendorUserIds,
          OrderVendorFulfillmentStatus.CANCELLED,
          'system',
          [],
          latestOrder?.status ?? txResult.orderStatus,
          latestOrder?.revision,
        ),
      );
      this.eventEmitter.emit(
        EVENTS.ORDER_VENDOR_REJECTED,
        new OrderVendorRejectedEvent(
          orderId,
          txResult.orderNumber,
          txResult.customerId,
          txResult.customerUserId,
          f.id,
          f.vendorId,
          f.vendorName,
          f.vendorNameAr,
          'NO_DRIVER_AVAILABLE',
          reason,
          null,
          f.itemNames,
          f.subtotal,
          false,
          'system',
        ),
      );
    }

    return { groupCancelled: true, orderCancelled: false };
  }
}
