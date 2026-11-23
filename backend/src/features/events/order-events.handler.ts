import { Injectable, Logger } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  NotificationType,
  OrderStatus,
  OrderType,
} from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationsService } from '../notifications/notifications.service';
import { StatisticsService } from '../statistics/statistics.service';
import { ConversationsService } from '../chat/conversations.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';
import {
  OrderCancelledEvent,
  OrderCreatedEvent,
  OrderStatusChangedEvent,
  WS_EVENTS,
} from '../../common/events';

const WS = {
  ORDER_NEW: WS_EVENTS.ORDER_NEW,
  ORDER_STATUS: WS_EVENTS.ORDER_STATUS,
} as const;

/**
 * Worker-side handler for durable order lifecycle event fan-out
 * (notifications, sockets, order conversations, stats, and driver active-order cache).
 */
@Injectable()
export class OrderEventsHandler {
  private readonly logger = new Logger(OrderEventsHandler.name);

  constructor(
    private readonly socketService: SocketService,
    private readonly notificationsService: NotificationsService,
    private readonly statisticsService: StatisticsService,
    private readonly conversationsService: ConversationsService,
    private readonly prisma: PrismaService,
    private readonly driverTracking: DriverTrackingService,
  ) {}

  async handleOrderCreated(event: OrderCreatedEvent) {
    this.logger.log(`Order created: ${event.orderNumber}`);

    const fulfillments =
      (await this.prisma.orderVendorFulfillment?.findMany({
        where: { orderId: event.orderId },
        select: { vendorId: true, vendorBranchId: true, subtotal: true },
      })) ?? [];

    const distinctVendors = new Set(fulfillments.map((f) => f.vendorId));
    const isMultiPortionOrVendor =
      distinctVendors.size > 1 || fulfillments.length > 1;

    // Resolve each user's visible order total (sum of their eligible fulfillments in
    // multi-vendor or multi-branch split orders; full grandTotal for single-portion orders).
    const vendorTotalByUserId = new Map<string, number>();

    if (fulfillments.length > 0) {
      const orClauses = fulfillments.map((f) => ({
        vendorId: f.vendorId,
        ...(f.vendorBranchId
          ? {
              OR: [
                { role: 'OWNER' as const },
                { branchId: null },
                { branchId: f.vendorBranchId },
              ],
            }
          : {}),
      }));
      const members = await this.prisma.vendorMember.findMany({
        where: { OR: orClauses },
        select: { userId: true, vendorId: true, role: true, branchId: true },
      });

      for (const m of members) {
        const matchingFulfillments = fulfillments.filter(
          (f) =>
            f.vendorId === m.vendorId &&
            (!f.vendorBranchId ||
              m.role === 'OWNER' ||
              !m.branchId ||
              m.branchId === f.vendorBranchId),
        );
        if (matchingFulfillments.length === 0) continue;

        const eligibleSubtotal = matchingFulfillments.reduce(
          (sum, f) => sum + Number(f.subtotal ?? 0),
          0,
        );

        if (isMultiPortionOrVendor) {
          const prev = vendorTotalByUserId.get(m.userId) ?? 0;
          vendorTotalByUserId.set(
            m.userId,
            Number((prev + eligibleSubtotal).toFixed(2)),
          );
        } else {
          vendorTotalByUserId.set(m.userId, event.grandTotal);
        }
      }
    }

    let vendorUserIds = Array.from(vendorTotalByUserId.keys());
    if (vendorUserIds.length === 0) {
      vendorUserIds = event.vendorUserIds || [];
    }

    const notificationPayloads = vendorUserIds.map((uid) => {
      const amount = vendorTotalByUserId.get(uid) ?? event.grandTotal;
      return {
        userId: uid,
        title: 'New Order Received',
        titleAr: 'طلب جديد',
        body: `Order ${event.orderNumber} — ${amount} EGP`,
        bodyAr: `طلب ${event.orderNumber} — ${amount} جنيه`,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          eventType: 'ORDER_NEW',
        },
      };
    });

    await Promise.all([
      ...vendorUserIds.map((uid) =>
        this.socketService.emitToUser(uid, WS.ORDER_NEW, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          grandTotal: vendorTotalByUserId.get(uid) ?? event.grandTotal,
          paymentMethod: event.paymentMethod,
          revision: event.revision,
        }),
      ),
      ...(notificationPayloads.length
        ? [this.notificationsService.createMany(notificationPayloads)]
        : []),
    ]);
  }

  async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
    this.logger.log(
      `Order ${event.orderNumber}: ${event.oldStatus} -> ${event.newStatus}`,
    );

    let customerUserId: string | null = event.customerUserId ?? null;
    let vendorUserIds = event.vendorUserIds || [];
    let driverUserId: string | null = event.driverUserId ?? null;
    let orderType: OrderType = OrderType.STANDARD;

    const resolved = await this.resolveOrderMeta(event.orderId);
    orderType = resolved.orderType;
    if (!customerUserId) customerUserId = resolved.customerUserId;
    if (vendorUserIds.length === 0) vendorUserIds = resolved.vendorUserIds;
    if (!driverUserId) driverUserId = resolved.driverUserId;

    const socketPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      orderType,
      oldStatus: event.oldStatus,
      newStatus: event.newStatus,
      status: event.newStatus,
      note: event.note,
      revision: event.revision,
    };

    const notifyUserIds = new Set<string>();
    if (customerUserId) notifyUserIds.add(customerUserId);
    for (const uid of vendorUserIds) {
      if (uid) notifyUserIds.add(uid);
    }
    if (driverUserId) notifyUserIds.add(driverUserId);

    // Multi-vendor orders assign each delivery group to its own driver.
    const groupDriverRows = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: event.orderId },
      select: {
        status: true,
        primaryDriverId: true,
        assistDriverId: true,
        primaryDriver: { select: { userId: true } },
        assistDriver: { select: { userId: true } },
      },
    });
    const driverUserById = new Map<string, string | null>();
    if (event.driverId) {
      driverUserById.set(event.driverId, event.driverUserId ?? null);
    }
    for (const g of groupDriverRows) {
      if (g.primaryDriverId) {
        driverUserById.set(g.primaryDriverId, g.primaryDriver?.userId ?? null);
      }
      if (g.assistDriverId) {
        driverUserById.set(g.assistDriverId, g.assistDriver?.userId ?? null);
      }
    }
    for (const userId of driverUserById.values()) {
      if (userId) notifyUserIds.add(userId);
    }

    await Promise.all(
      [...notifyUserIds].map((uid) =>
        this.socketService.emitToUser(uid, WS.ORDER_STATUS, socketPayload),
      ),
    );

    const customerMsg = this.buildCustomerStatusMessage(
      event.newStatus,
      orderType,
    );
    if (customerMsg && customerUserId) {
      const refEn =
        orderType === OrderType.RIDE
          ? `Ride ${event.orderNumber}`
          : orderType === OrderType.CUSTOM_DELIVERY
            ? `Delivery ${event.orderNumber}`
            : `Order ${event.orderNumber}`;
      const refAr =
        orderType === OrderType.RIDE
          ? `رحلة ${event.orderNumber}`
          : orderType === OrderType.CUSTOM_DELIVERY
            ? `توصيل ${event.orderNumber}`
            : `طلب ${event.orderNumber}`;
      await this.notificationsService.create({
        userId: customerUserId,
        title: customerMsg.en,
        titleAr: customerMsg.ar,
        body: refEn,
        bodyAr: refAr,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          orderType,
          status: event.newStatus,
        },
      });
    }

    await this.syncOrderConversationLifecycle(event, orderType);
    await this.syncLiveTrackingForDrivers(
      event,
      groupDriverRows,
      driverUserById,
      customerUserId,
    );
  }

  async handleOrderCancelled(event: OrderCancelledEvent) {
    this.logger.log(`Order cancelled: ${event.orderNumber} — ${event.reason}`);

    const allDriverIds =
      event.driverIds && event.driverIds.length > 0
        ? event.driverIds
        : event.driverId
          ? [event.driverId]
          : [];

    await Promise.all(
      allDriverIds.map((did) => this.refreshDriverTracking(did, event.orderId)),
    );

    let customerUserId: string | null = event.customerUserId ?? null;
    let vendorUserIds = event.vendorUserIds || [];
    let driverUserId: string | null = event.driverUserId ?? null;
    const resolved = await this.resolveOrderMeta(event.orderId);
    const orderType = resolved.orderType;
    if (!customerUserId) customerUserId = resolved.customerUserId;
    if (vendorUserIds.length === 0) vendorUserIds = resolved.vendorUserIds;
    if (!driverUserId) driverUserId = resolved.driverUserId;

    const notifyUserIds = new Set<string>();
    if (customerUserId) notifyUserIds.add(customerUserId);
    for (const uid of vendorUserIds) {
      if (uid) notifyUserIds.add(uid);
    }
    if (driverUserId) notifyUserIds.add(driverUserId);
    if (allDriverIds.length > 0) {
      const drivers = await this.prisma.driver.findMany({
        where: { id: { in: allDriverIds } },
        select: { userId: true },
      });
      for (const d of drivers) {
        if (d.userId) notifyUserIds.add(d.userId);
      }
    }

    await Promise.all(
      [...notifyUserIds].map((uid) =>
        this.socketService.emitToUser(uid, WS.ORDER_STATUS, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          orderType,
          oldStatus: null,
          newStatus: 'CANCELLED',
          status: 'CANCELLED',
          note: event.reason,
          reason: event.reason,
          cancelledByUserId: event.cancelledByUserId ?? null,
          cancelledByName: event.cancelledByName ?? null,
          cancelledByNameAr: event.cancelledByNameAr ?? null,
          cancelledByRole: event.cancelledByRole ?? null,
          cancelledByAvatar: event.cancelledByAvatar ?? null,
          revision: event.revision ?? null,
        }),
      ),
    );

    if (customerUserId) {
      const actorEn = event.cancelledByName?.trim() || 'User';
      const actorAr = event.cancelledByNameAr?.trim() || actorEn;
      const cleanReason = event.reason?.trim();
      const bodyEn = cleanReason
        ? `Canceled by ${actorEn}: ${cleanReason}`
        : `Canceled by ${actorEn}`;
      const bodyAr = cleanReason
        ? `تم الإلغاء بواسطة ${actorAr}: ${cleanReason}`
        : `تم الإلغاء بواسطة ${actorAr}`;
      const cancelTitleEn =
        orderType === OrderType.RIDE
          ? 'Ride Cancelled'
          : orderType === OrderType.CUSTOM_DELIVERY
            ? 'Delivery Cancelled'
            : 'Order Cancelled';
      const cancelTitleAr =
        orderType === OrderType.RIDE
          ? 'تم إلغاء الرحلة'
          : orderType === OrderType.CUSTOM_DELIVERY
            ? 'تم إلغاء التوصيل'
            : 'تم إلغاء الطلب';
      await this.notificationsService.create({
        userId: customerUserId,
        title: cancelTitleEn,
        titleAr: cancelTitleAr,
        body: bodyEn,
        bodyAr: bodyAr,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          orderType,
          cancelledByUserId: event.cancelledByUserId ?? null,
          cancelledByName: actorEn,
          cancelledByNameAr: actorAr,
          cancelledByRole: event.cancelledByRole ?? null,
        },
      });
    }

    await this.conversationsService
      .closeSystemOrderConversation(event.orderId)
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to close order conversation on cancel: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );

    const cancelDrivers =
      allDriverIds.length > 0
        ? allDriverIds
        : event.driverId
          ? [event.driverId]
          : [];
    const distinctVendorIds = event.vendorId
      ? [event.vendorId]
      : Array.from(
          new Set(
            (
              await this.prisma.orderVendorFulfillment.findMany({
                where: { orderId: event.orderId },
                select: { vendorId: true },
              })
            ).map((f) => f.vendorId),
          ),
        );
    const vendorStatTargets: Array<string | null> =
      distinctVendorIds.length > 0 ? distinctVendorIds : [null];
    const driverStatTargets: Array<string | null> =
      cancelDrivers.length > 0 ? cancelDrivers : [null];

    const maxStatCalls = Math.max(
      vendorStatTargets.length,
      driverStatTargets.length,
    );
    await Promise.all(
      Array.from({ length: maxStatCalls }, (_, i) =>
        this.statisticsService
          .recordCancellation(
            event.orderId,
            vendorStatTargets[i] ?? null,
            driverStatTargets[i] ?? null,
          )
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to record cancellation stat: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
      ),
    );
  }

  async handleOrderSettled(data: {
    orderId: string;
    orderNumber: string;
    grandTotal: number;
  }) {
    // Delivery push notification is sent once via handleOrderStatusChanged
    // (DELIVERED); keep handler as a clean no-op for any in-flight jobs.
    this.logger.debug(
      `Skipping duplicate settled delivery notification for ${data.orderNumber}`,
    );
    return { skipped: true };
  }

  private async syncOrderConversationLifecycle(
    event: OrderStatusChangedEvent,
    resolvedOrderType?: OrderType,
  ) {
    const activeChatSyncStatuses: OrderStatus[] = [
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.PARTIALLY_PICKED_UP,
      OrderStatus.PICKED_UP,
    ];

    let orderType = resolvedOrderType;
    const resolveType = async (): Promise<OrderType> => {
      if (orderType) return orderType;
      const row = await this.prisma.order.findUnique({
        where: { id: event.orderId },
        select: { type: true },
      });
      orderType = row?.type ?? OrderType.STANDARD;
      return orderType;
    };

    if (
      event.newStatus === OrderStatus.ACCEPTED ||
      event.newStatus === OrderStatus.LOOKING_FOR_DRIVER
    ) {
      const type = await resolveType();
      if (type === OrderType.STANDARD) {
        if (
          typeof this.conversationsService?.createSystemOrderConversation ===
          'function'
        ) {
          await this.conversationsService.createSystemOrderConversation(
            event.orderId,
          );
        }
        if (
          event.newStatus === OrderStatus.LOOKING_FOR_DRIVER &&
          typeof this.conversationsService?.syncOrderDriverParticipants ===
            'function'
        ) {
          await this.conversationsService.syncOrderDriverParticipants(
            event.orderId,
          );
        }
      }
    }

    if (activeChatSyncStatuses.includes(event.newStatus)) {
      const type = await resolveType();
      if (type === OrderType.STANDARD) {
        if (
          event.driverUserId &&
          typeof this.conversationsService?.addParticipantToOrderConversation ===
            'function'
        ) {
          await this.conversationsService.addParticipantToOrderConversation(
            event.orderId,
            event.driverUserId,
          );
        }
        if (
          typeof this.conversationsService?.syncOrderDriverParticipants ===
          'function'
        ) {
          await this.conversationsService.syncOrderDriverParticipants(
            event.orderId,
          );
        }
      } else if (
        type === OrderType.RIDE ||
        type === OrderType.CUSTOM_DELIVERY
      ) {
        // Ensure conversation exists once a driver is assigned (or active) AND
        // keep participants synced so admin driver reassignments add the new
        // driver and prune the previous driver identically to STANDARD orders.
        if (
          typeof this.conversationsService?.createSystemOrderConversation ===
          'function'
        ) {
          await this.conversationsService.createSystemOrderConversation(
            event.orderId,
          );
        }
        if (
          event.driverUserId &&
          typeof this.conversationsService?.addParticipantToOrderConversation ===
            'function'
        ) {
          await this.conversationsService.addParticipantToOrderConversation(
            event.orderId,
            event.driverUserId,
          );
        }
        if (
          typeof this.conversationsService?.syncOrderDriverParticipants ===
          'function'
        ) {
          await this.conversationsService.syncOrderDriverParticipants(
            event.orderId,
          );
        }
      }
    }

    if (event.newStatus === OrderStatus.DELIVERED) {
      await this.conversationsService
        .closeSystemOrderConversation(event.orderId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to close order conversation on delivery: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }
  }

  private async syncLiveTrackingForDrivers(
    event: OrderStatusChangedEvent,
    groupDriverRows: Array<{
      status: DeliveryGroupStatus;
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>,
    driverUserById: Map<string, string | null>,
    resolvedCustomerUserId?: string | null,
  ) {
    const trackingStatuses: OrderStatus[] = [
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.PARTIALLY_PICKED_UP,
      OrderStatus.PICKED_UP,
    ];
    const effectiveCustomerUserId =
      resolvedCustomerUserId ?? event.customerUserId ?? null;

    for (const driverId of driverUserById.keys()) {
      if (trackingStatuses.includes(event.newStatus)) {
        const hasActiveWorkOnThisOrder =
          groupDriverRows.length > 0
            ? groupDriverRows.some(
                (g) =>
                  (g.primaryDriverId === driverId ||
                    g.assistDriverId === driverId) &&
                  g.status !== DeliveryGroupStatus.CANCELLED &&
                  g.status !== DeliveryGroupStatus.DELIVERED,
              )
            : driverId === event.driverId;
        await this.refreshDriverTracking(
          driverId,
          hasActiveWorkOnThisOrder ? undefined : event.orderId,
          hasActiveWorkOnThisOrder && effectiveCustomerUserId
            ? {
                orderId: event.orderId,
                customerUserId: effectiveCustomerUserId,
              }
            : undefined,
        );
      } else if (
        event.newStatus === OrderStatus.DELIVERED ||
        event.newStatus === OrderStatus.CANCELLED
      ) {
        await this.refreshDriverTracking(driverId, event.orderId);
      }
    }
  }

  private async refreshDriverTracking(
    driverId: string,
    endedOrderId?: string,
    ensureActiveOrder?: { orderId: string; customerUserId: string },
  ) {
    const remainingGroups = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        status: {
          notIn: [DeliveryGroupStatus.CANCELLED, DeliveryGroupStatus.DELIVERED],
        },
        order: { status: { in: DRIVER_ACTIVE_ORDER_STATUSES } },
        OR: [{ primaryDriverId: driverId }, { assistDriverId: driverId }],
      },
      select: {
        orderId: true,
        order: {
          select: {
            customerId: true,
            customer: { select: { userId: true } },
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    const byOrderId = new Map<
      string,
      { orderId: string; customerUserId: string }
    >();
    for (const g of remainingGroups) {
      if (endedOrderId && g.orderId === endedOrderId) continue;
      byOrderId.set(g.orderId, {
        orderId: g.orderId,
        customerUserId: g.order.customer?.userId ?? g.order.customerId,
      });
    }
    if (ensureActiveOrder?.orderId && ensureActiveOrder.customerUserId) {
      byOrderId.set(ensureActiveOrder.orderId, ensureActiveOrder);
    }

    await this.driverTracking.syncDriverActiveOrders(
      driverId,
      Array.from(byOrderId.values()),
    );
  }

  private buildCustomerStatusMessage(
    status: OrderStatus,
    orderType: OrderType = OrderType.STANDARD,
  ): { en: string; ar: string } | null {
    if (orderType === OrderType.RIDE) {
      const rideMessages: Partial<
        Record<OrderStatus, { en: string; ar: string }>
      > = {
        [OrderStatus.DRIVER_ASSIGNED]: {
          en: 'Your driver is on the way',
          ar: 'كابتن الرحلة في طريقه إليك',
        },
        [OrderStatus.PENDING_PAYMENT]: {
          en: 'Driver accepted! Complete payment to confirm your ride',
          ar: 'قبل الكابتن رحلتك! أكمل الدفع للتأكيد',
        },
        [OrderStatus.READY_FOR_PICKUP]: {
          en: 'Your driver has arrived!',
          ar: 'وصل الكابتن!',
        },
        [OrderStatus.PICKED_UP]: {
          en: 'Your ride has started!',
          ar: 'بدأت رحلتك!',
        },
        [OrderStatus.DELIVERED]: {
          en: 'Your ride is complete!',
          ar: 'اكتملت رحلتك!',
        },
      };
      return rideMessages[status] ?? null;
    }

    if (orderType === OrderType.CUSTOM_DELIVERY) {
      const deliveryMessages: Partial<
        Record<OrderStatus, { en: string; ar: string }>
      > = {
        [OrderStatus.DRIVER_ASSIGNED]: {
          en: 'Your driver is on the way to pickup',
          ar: 'السائق في طريقه إلى نقطة الاستلام',
        },
        [OrderStatus.PENDING_PAYMENT]: {
          en: 'Driver accepted! Complete payment to confirm your delivery',
          ar: 'قبل السائق طلبك! أكمل الدفع للتأكيد',
        },
        [OrderStatus.READY_FOR_PICKUP]: {
          en: 'Your driver has arrived!',
          ar: 'وصل السائق إلى نقطة الاستلام!',
        },
        [OrderStatus.PICKED_UP]: {
          en: 'Your delivery is on its way!',
          ar: 'توصيلك في الطريق!',
        },
        [OrderStatus.DELIVERED]: {
          en: 'Your delivery is complete!',
          ar: 'تم التوصيل بنجاح!',
        },
      };
      return deliveryMessages[status] ?? null;
    }

    const messages: Partial<Record<OrderStatus, { en: string; ar: string }>> = {
      [OrderStatus.ACCEPTED]: {
        en: 'Your order was accepted!',
        ar: 'تم قبول طلبك!',
      },
      [OrderStatus.PREPARING]: {
        en: 'Your order is being prepared',
        ar: 'جاري تحضير طلبك',
      },
      [OrderStatus.READY_FOR_PICKUP]: {
        en: 'Your order is ready',
        ar: 'طلبك جاهز',
      },
      [OrderStatus.DRIVER_ASSIGNED]: {
        en: 'A driver is on the way',
        ar: 'السائق في الطريق إليك',
      },
      [OrderStatus.PARTIALLY_PICKED_UP]: {
        en: 'The driver is collecting your order from stores',
        ar: 'الكابتن يجمع طلبك من المتاجر',
      },
      [OrderStatus.PICKED_UP]: {
        en: 'Your order has been picked up',
        ar: 'تم استلام طلبك',
      },
      [OrderStatus.DELIVERED]: {
        en: 'Your order was delivered!',
        ar: 'تم توصيل طلبك!',
      },
    };
    return messages[status] ?? null;
  }

  private async resolveOrderMeta(orderId: string): Promise<{
    orderType: OrderType;
    customerUserId: string | null;
    vendorUserIds: string[];
    driverUserId: string | null;
  }> {
    try {
      const order = await this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
          type: true,
          customerId: true,
          customer: { select: { userId: true } },
          vendorFulfillments: {
            select: { vendorId: true, vendorBranchId: true },
          },
          deliveryGroups: {
            where: { status: { not: DeliveryGroupStatus.CANCELLED } },
            orderBy: { sequence: 'asc' },
            select: {
              primaryDriver: { select: { userId: true } },
              assistDriver: { select: { userId: true } },
            },
          },
        },
      });
      if (!order) {
        return {
          orderType: OrderType.STANDARD,
          customerUserId: null,
          vendorUserIds: [],
          driverUserId: null,
        };
      }

      const customerUserId = order.customer?.userId || order.customerId;
      const driverUserId =
        order.deliveryGroups
          .map((g) => g.primaryDriver?.userId ?? g.assistDriver?.userId ?? null)
          .find((uid): uid is string => Boolean(uid)) ?? null;

      let vendorUserIds: string[] = [];
      if (order.vendorFulfillments.length > 0) {
        const orClauses = order.vendorFulfillments.map((f) => ({
          vendorId: f.vendorId,
          ...(f.vendorBranchId
            ? {
                OR: [
                  { role: 'OWNER' as const },
                  { branchId: null },
                  { branchId: f.vendorBranchId },
                ],
              }
            : {}),
        }));
        const members = await this.prisma.vendorMember.findMany({
          where: { OR: orClauses },
          select: { userId: true },
        });
        vendorUserIds = Array.from(new Set(members.map((m) => m.userId)));
      }

      return {
        orderType: order.type ?? OrderType.STANDARD,
        customerUserId,
        vendorUserIds,
        driverUserId,
      };
    } catch (err) {
      this.logger.error(
        `Failed to resolve order user IDs for ${orderId}: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      return {
        orderType: OrderType.STANDARD,
        customerUserId: null,
        vendorUserIds: [],
        driverUserId: null,
      };
    }
  }
}
