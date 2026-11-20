import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../../infrastructure/storage/storage.service';
import { OrdersRepository } from '../orders.repository';
import { DeliveryGroupTransitionService } from './delivery-group-transition.service';
import { UpdateOrderStatusDto } from '../dto/order.dto';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import {
  OrderFulfillmentUpdatedEvent,
  OrderStatusChangedEvent,
} from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import {
  DriverErrors,
  OrderErrors,
} from '../../../common/constants/response.constants';
import {
  formatFulfillmentStoreLabel,
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
} from '../helpers/order-actor.helper';

/**
 * Manages per-vendor fulfillment transitions (`PREPARING`, `READY_FOR_PICKUP`,
 * sequential driver stop collection, and group readiness synchronization).
 */
@Injectable()
export class FulfillmentTransitionService {
  private readonly logger = new Logger(FulfillmentTransitionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly ordersRepository: OrdersRepository,
    private readonly storage: StorageService,
    private readonly eventEmitter: EventEmitter2,
    private readonly deliveryGroupTransitions: DeliveryGroupTransitionService,
  ) {}

  /**
   * Move ONE vendor's portion through production without prematurely advancing
   * sibling portions sharing the same delivery group.
   */
  async applyFulfillmentProductionTransition(
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
    if (
      fulfillment.status !== 'ACCEPTED' &&
      fulfillment.status !== 'PREPARING'
    ) {
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
      DeliveryGroupStatus.PENDING,
      DeliveryGroupStatus.DRIVER_ASSIGNED,
      DeliveryGroupStatus.PENDING_PAYMENT,
      DeliveryGroupStatus.ACCEPTED,
      DeliveryGroupStatus.LOOKING_FOR_DRIVER,
      DeliveryGroupStatus.PREPARING,
    ];
    const ALREADY_READY: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.READY_FOR_PICKUP,
      DeliveryGroupStatus.PARTIALLY_PICKED_UP,
      DeliveryGroupStatus.PICKED_UP,
      DeliveryGroupStatus.DELIVERED,
    ];

    const wantedReady = dto.status === OrderStatus.READY_FOR_PICKUP;
    const groupProgressed = ALREADY_READY.includes(group.status);

    if (wantedReady && fulfillment.readyAt) {
      return this.ordersRepository.findById(order.id);
    }
    if (!wantedReady && fulfillment.preparingAt) {
      return this.ordersRepository.findById(order.id);
    }

    if (!groupProgressed && !STARTABLE.includes(group.status)) {
      throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
    }

    const targetStatus = wantedReady
      ? OrderVendorFulfillmentStatus.READY_FOR_PICKUP
      : OrderVendorFulfillmentStatus.PREPARING;

    const allowedPriorStatuses = wantedReady
      ? [
          OrderVendorFulfillmentStatus.ACCEPTED,
          OrderVendorFulfillmentStatus.PREPARING,
        ]
      : [OrderVendorFulfillmentStatus.ACCEPTED];

    const data: Prisma.OrderVendorFulfillmentUpdateManyMutationInput =
      wantedReady
        ? {
            status: targetStatus,
            preparingAt: fulfillment.preparingAt ?? new Date(),
            readyAt: new Date(),
          }
        : {
            status: targetStatus,
            preparingAt: new Date(),
            ...(dto.estimatedPrepTime != null
              ? { estimatedPrepTime: Math.round(dto.estimatedPrepTime) }
              : {}),
          };

    const claimed = await this.prisma.orderVendorFulfillment.updateMany({
      where: { id: fulfillment.id, status: { in: allowedPriorStatuses } },
      data,
    });
    if (claimed.count === 0) {
      throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
    }

    if (!wantedReady) {
      await this.prisma.orderDeliveryGroup.updateMany({
        where: {
          id: group.id,
          status: {
            in: [
              DeliveryGroupStatus.ACCEPTED,
              DeliveryGroupStatus.LOOKING_FOR_DRIVER,
              DeliveryGroupStatus.DRIVER_ASSIGNED,
              DeliveryGroupStatus.PREPARING,
            ],
          },
        },
        data: {
          status: DeliveryGroupStatus.PREPARING,
          ...(dto.estimatedPrepTime != null
            ? {
                estimatedPrepTime: Math.max(
                  group.estimatedPrepTime ?? 0,
                  Math.round(dto.estimatedPrepTime),
                ),
              }
            : {}),
        },
      });
    } else if (dto.estimatedPrepTime != null) {
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

    let groupBecameReady = false;
    if (wantedReady) {
      groupBecameReady = await this.markGroupReadyIfAllPortionsReady(group.id);
    }

    const orderFulfillments = (order.vendorFulfillments ?? []) as any[];
    let targetFulfillment = orderFulfillments.find(
      (f) => f.id === fulfillment.id,
    );
    if (!targetFulfillment && this.prisma?.orderVendorFulfillment?.findUnique) {
      targetFulfillment = await this.prisma.orderVendorFulfillment.findUnique({
        where: { id: fulfillment.id },
        select: {
          id: true,
          vendorId: true,
          vendor: {
            select: { storeName: true, storeNameAr: true, logo: true },
          },
          vendorBranch: { select: { name: true, nameAr: true } },
        },
      });
    }
    const storeLabel = formatFulfillmentStoreLabel(targetFulfillment);
    const liveFulfillments = orderFulfillments.filter(
      (f) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
    );
    const isSinglePortionOrder = liveFulfillments.length <= 1;

    const eventStatus = wantedReady
      ? groupBecameReady || isSinglePortionOrder
        ? OrderStatus.READY_FOR_PICKUP
        : OrderStatus.PREPARING
      : OrderStatus.PREPARING;
    const eventNote = storeLabel
      ? wantedReady
        ? `${storeLabel}: ready for pickup`
        : `${storeLabel}: started preparing`
      : wantedReady
        ? `Delivery ${group.sequence}: vendor portion ready for pickup`
        : `Delivery ${group.sequence}: vendor portion started preparing`;

    const actorSnapshot = await resolveOrderActorSnapshot(
      this.prisma,
      actor.sub,
      {
        fulfillmentId: fulfillment.id,
        vendorId: targetFulfillment?.vendorId ?? null,
        orderId: order.id,
      },
    );

    await recordOrderStatusEventIdempotent(this.prisma, {
      orderId: order.id,
      deliveryGroupId: group.id,
      fulfillmentId: fulfillment.id,
      eventKey: `fulfillment_${wantedReady ? 'ready' : 'preparing'}:${fulfillment.id}`,
      status: eventStatus,
      note: eventNote,
      createdBy: actor.sub,
      actor: actorSnapshot,
    });

    await this.recomputeVendorReadinessStatus(
      actor.sub,
      order.id,
      group.id,
      isSinglePortionOrder ? { skipStatusEvent: true } : undefined,
    );

    const fresh = await this.ordersRepository.findById(order.id);
    try {
      const customerUid =
        (fresh as any).customer?.user?.id ??
        (fresh as any).customer?.userId ??
        fresh.customerId;
      const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
        order.id,
        null,
      );
      const groupWithDriver = await this.prisma.orderDeliveryGroup.findUnique({
        where: { id: group.id },
        select: {
          primaryDriver: { select: { userId: true } },
          assistDriver: { select: { userId: true } },
        },
      });
      const driverUserIds = [
        groupWithDriver?.primaryDriver?.userId,
        groupWithDriver?.assistDriver?.userId,
      ].filter((id): id is string => Boolean(id));
      const allFulfillments = ((fresh as any).vendorFulfillments ??
        []) as any[];
      const liveFulfillments = allFulfillments.filter(
        (f) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
      );
      const completedStops = liveFulfillments.filter((f) =>
        Boolean(f.pickedUpAt),
      ).length;

      this.eventEmitter.emit(
        EVENTS.ORDER_FULFILLMENT_UPDATED,
        new OrderFulfillmentUpdatedEvent(
          order.id,
          fresh.orderNumber,
          fulfillment.id,
          customerUid,
          vendorUserIds,
          driverUserIds,
          targetStatus,
          null,
          null,
          fresh.status,
          {
            totalStops: liveFulfillments.length,
            completedStops,
            currentStopSequence: 1,
            currentStopBranchName: null,
            isFullyCollected: false,
          },
          actor.sub,
          fresh.revision,
        ),
      );
    } catch (err) {
      this.logger.warn(
        `Failed to emit fulfillment production delta for ${order.id}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }

    return fresh;
  }

  /**
   * Re-evaluate a delivery group after one of its vendor portions was removed.
   */
  async syncGroupReadinessAfterPortionRemoved(
    orderId: string,
    deliveryGroupId: string,
    actorUserId: string,
  ): Promise<void> {
    const becameReady =
      await this.markGroupReadyIfAllPortionsReady(deliveryGroupId);
    if (!becameReady) return;
    await this.recomputeVendorReadinessStatus(
      actorUserId,
      orderId,
      deliveryGroupId,
    );
  }

  async driverConfirmFulfillmentPickup(
    actor: JwtAccessPayload,
    orderId: string,
    fulfillmentId: string,
    file: Express.Multer.File,
    onLegacyNoGroupFallback?: (imageUrl: string) => Promise<void>,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new ForbiddenException(DriverErrors.PROFILE_NOT_FOUND);

    const fulfillment = await this.prisma.orderVendorFulfillment.findFirst({
      where: { id: fulfillmentId, orderId },
      include: {
        vendor: {
          select: { id: true, storeName: true, storeNameAr: true, logo: true },
        },
        vendorBranch: { select: { id: true, name: true, nameAr: true } },
        groups: {
          include: {
            deliveryGroup: true,
          },
        },
      },
    });
    if (!fulfillment) {
      throw new NotFoundException(OrderErrors.FULFILLMENT_STOP_NOT_FOUND);
    }

    const order = await this.ordersRepository.findById(orderId);
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);

    const isAssigned = fulfillment.groups.some(
      (g) =>
        g.deliveryGroup.primaryDriverId === driver.id ||
        g.deliveryGroup.assistDriverId === driver.id,
    );
    if (!isAssigned) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    if (
      fulfillment.status === OrderVendorFulfillmentStatus.REJECTED ||
      fulfillment.status === OrderVendorFulfillmentStatus.CANCELLED
    ) {
      throw new BadRequestException(OrderErrors.FULFILLMENT_ALREADY_DECIDED);
    }

    if (
      fulfillment.pickedUpAt != null ||
      fulfillment.status === OrderVendorFulfillmentStatus.PICKED_UP
    ) {
      throw new BadRequestException('Vendor pickup stop already collected');
    }

    if (
      fulfillment.status !== OrderVendorFulfillmentStatus.READY_FOR_PICKUP &&
      !fulfillment.readyAt
    ) {
      throw new BadRequestException(
        'Vendor has not marked this portion ready for pickup yet',
      );
    }

    if (
      (order.paymentMethod === 'MOBILE_WALLET' ||
        Number((order as any).upfrontAmount ?? 0) > 0) &&
      order.paymentStatus !== 'COMPLETED'
    ) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }

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
      const claimed = await this.prisma.orderVendorFulfillment.updateMany({
        where: {
          id: fulfillmentId,
          pickedUpAt: null,
          status: {
            notIn: [
              OrderVendorFulfillmentStatus.CANCELLED,
              OrderVendorFulfillmentStatus.REJECTED,
            ],
          },
        },
        data: {
          status: OrderVendorFulfillmentStatus.PICKED_UP,
          pickedUpAt: now,
          pickupImageUrl: imageUrl,
          pickedUpByDriverId: driver.id,
        },
      });
      if (claimed.count === 0) {
        throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
      }

      if (groupItem) {
        const remaining = await this.prisma.orderDeliveryGroupItem.findMany({
          where: { deliveryGroupId: groupItem.deliveryGroupId },
          include: {
            fulfillment: {
              include: {
                vendorBranch: { select: { name: true, nameAr: true } },
              },
            },
          },
          orderBy: { sequence: 'asc' },
        });
        const liveGroupItems = remaining.filter(
          (it) =>
            it.fulfillment &&
            it.fulfillment.status !== 'REJECTED' &&
            it.fulfillment.status !== 'CANCELLED',
        );
        const allPickedUp = liveGroupItems.every((it) =>
          Boolean(it.fulfillment?.pickedUpAt),
        );

        await this.prisma.orderDeliveryGroup.update({
          where: { id: groupItem.deliveryGroupId },
          data: allPickedUp
            ? {
                status: DeliveryGroupStatus.PICKED_UP,
                pickedUpAt: now,
                pickupImageUrl: imageUrl,
              }
            : {
                status: DeliveryGroupStatus.PARTIALLY_PICKED_UP,
              },
        });
        const stopLabel = formatFulfillmentStoreLabel(fulfillment);
        const driverActorSnapshot = await resolveOrderActorSnapshot(
          this.prisma,
          actor.sub,
          { orderId },
        );
        const allGroupsWillBePickedUp =
          allPickedUp &&
          ((order.deliveryGroups ?? []) as any[])
            .filter(
              (g) =>
                g.id !== groupItem.deliveryGroupId &&
                g.status !== DeliveryGroupStatus.CANCELLED,
            )
            .every(
              (g) =>
                g.status === DeliveryGroupStatus.PICKED_UP ||
                g.status === DeliveryGroupStatus.DELIVERED,
            );
        await recordOrderStatusEventIdempotent(this.prisma, {
          orderId,
          fulfillmentId,
          deliveryGroupId: groupItem.deliveryGroupId,
          eventKey: `fulfillment_pickup:${fulfillmentId}`,
          status: allGroupsWillBePickedUp
            ? OrderStatus.PICKED_UP
            : OrderStatus.PARTIALLY_PICKED_UP,
          note: stopLabel
            ? `Driver picked up from ${stopLabel}`
            : `Driver picked up fulfillment stop ${fulfillmentId}`,
          createdBy: actor.sub,
          actor: driverActorSnapshot,
        });

        await this.deliveryGroupTransitions.recomputeGroupedOrderStatus(
          actor,
          order,
        );

        const fresh = await this.ordersRepository.findById(orderId);
        const customerUid =
          (fresh as any).customer?.user?.id ??
          (fresh as any).customer?.userId ??
          fresh.customerId;
        const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
          orderId,
          null,
        );
        const groupDriverIds = [
          groupItem.deliveryGroup?.primaryDriverId
            ? (
                await this.prisma.driver.findUnique({
                  where: { id: groupItem.deliveryGroup.primaryDriverId },
                  select: { userId: true },
                })
              )?.userId
            : null,
          groupItem.deliveryGroup?.assistDriverId
            ? (
                await this.prisma.driver.findUnique({
                  where: { id: groupItem.deliveryGroup.assistDriverId },
                  select: { userId: true },
                })
              )?.userId
            : null,
        ].filter((id): id is string => Boolean(id));
        const driverUserIds =
          groupDriverIds.length > 0
            ? Array.from(new Set([actor.sub, ...groupDriverIds]))
            : [actor.sub];

        const totalStops = liveGroupItems.length;
        const completedStops = liveGroupItems.filter(
          (it) =>
            it.fulfillmentId === fulfillmentId ||
            Boolean(it.fulfillment?.pickedUpAt),
        ).length;
        const nextItem = liveGroupItems.find(
          (it) =>
            it.fulfillmentId !== fulfillmentId && !it.fulfillment?.pickedUpAt,
        );

        const fulfillmentSummary = {
          totalStops,
          completedStops,
          currentStopSequence: nextItem?.sequence ?? totalStops,
          currentStopBranchName: allPickedUp
            ? null
            : ((nextItem?.fulfillment as any)?.vendorBranch?.nameAr ??
              (nextItem?.fulfillment as any)?.vendorBranch?.name ??
              null),
          isFullyCollected: allPickedUp,
        };

        this.eventEmitter.emit(
          EVENTS.ORDER_FULFILLMENT_UPDATED,
          new OrderFulfillmentUpdatedEvent(
            orderId,
            fresh.orderNumber,
            fulfillmentId,
            customerUid,
            vendorUserIds,
            driverUserIds,
            OrderVendorFulfillmentStatus.PICKED_UP,
            now,
            imageUrl,
            fresh.status,
            fulfillmentSummary,
            actor.sub,
            fresh.revision,
          ),
        );
      } else {
        if (!onLegacyNoGroupFallback) {
          throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
        }
        await onLegacyNoGroupFallback(imageUrl);
        const fallbackOrder = await this.ordersRepository.findById(orderId);
        const driverActorSnapshot = await resolveOrderActorSnapshot(
          this.prisma,
          actor.sub,
          { orderId },
        );
        await recordOrderStatusEventIdempotent(this.prisma, {
          orderId,
          fulfillmentId,
          deliveryGroupId: null,
          eventKey: `fulfillment_pickup:${fulfillmentId}`,
          status: fallbackOrder.status,
          note: `Driver picked up fulfillment stop ${fulfillmentId}`,
          createdBy: actor.sub,
          actor: driverActorSnapshot,
        });
      }

      const finalOrder = await this.ordersRepository.findById(orderId);
      return finalOrder;
    } catch (error) {
      await this.storage.delete(imageUrl);
      throw error;
    }
  }

  private async markGroupReadyIfAllPortionsReady(
    groupId: string,
  ): Promise<boolean> {
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
            DeliveryGroupStatus.PENDING,
            DeliveryGroupStatus.DRIVER_ASSIGNED,
            DeliveryGroupStatus.LOOKING_FOR_DRIVER,
            DeliveryGroupStatus.PREPARING,
            DeliveryGroupStatus.ACCEPTED,
          ],
        },
      },
      data: { status: DeliveryGroupStatus.READY_FOR_PICKUP },
    });
    return updated.count > 0;
  }

  private async recomputeVendorReadinessStatus(
    actorUserId: string,
    orderId: string,
    changedGroupId: string,
    options?: { skipStatusEvent?: boolean },
  ) {
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId },
      select: {
        id: true,
        status: true,
        isPaymentCollector: true,
        primaryDriverId: true,
        sequence: true,
      },
      orderBy: { sequence: 'asc' },
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

    // Never leave PENDING_PAYMENT until the customer payment has been confirmed.
    if (
      fresh.status === OrderStatus.PENDING_PAYMENT &&
      (fresh.paymentMethod === 'MOBILE_WALLET' ||
        Number(fresh.upfrontAmount ?? 0) > 0) &&
      fresh.paymentStatus !== 'COMPLETED'
    ) {
      return;
    }

    const READY_OR_BEYOND: DeliveryGroupStatus[] = [
      DeliveryGroupStatus.READY_FOR_PICKUP,
      DeliveryGroupStatus.PARTIALLY_PICKED_UP,
      DeliveryGroupStatus.PICKED_UP,
      DeliveryGroupStatus.DELIVERED,
    ];
    const allReady = active.every((g) => READY_OR_BEYOND.includes(g.status));
    const changedGroup = groups.find((g) => g.id === changedGroupId);
    const someoneStarted =
      !!changedGroup && !READY_OR_BEYOND.includes(changedGroup.status);

    let target: OrderStatus | null = null;
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
        fresh.status === OrderStatus.LOOKING_FOR_DRIVER ||
        fresh.status === OrderStatus.PENDING_PAYMENT ||
        fresh.status === OrderStatus.ACCEPTED)
    ) {
      target = OrderStatus.PREPARING;
    }
    if (!target) return;

    let updatedRevision = fresh.revision;
    try {
      const readinessNote =
        target === OrderStatus.READY_FOR_PICKUP
          ? 'All vendor portions ready for pickup'
          : 'Vendor portion started preparing';
      const updated = options?.skipStatusEvent
        ? await this.ordersRepository.updateStatus(
            orderId,
            target,
            actorUserId,
            readinessNote,
            undefined,
            fresh.status,
            { skipStatusEvent: true },
          )
        : await this.ordersRepository.updateStatus(
            orderId,
            target,
            actorUserId,
            readinessNote,
            undefined,
            fresh.status,
          );
      updatedRevision = updated.revision;
    } catch {
      return;
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
    const primaryDriverId =
      active.find((g) => g.isPaymentCollector)?.primaryDriverId ??
      active.find((g) => g.primaryDriverId)?.primaryDriverId ??
      null;

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      orderId,
      null,
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
        singleVendorId,
        vendorUserIds,
        primaryDriverId,
        null,
        actorUserId,
        target === OrderStatus.READY_FOR_PICKUP
          ? 'All vendor portions ready for pickup'
          : 'Vendor portion started preparing',
        updatedRevision,
      ),
    );
  }
}
