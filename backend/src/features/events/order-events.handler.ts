import { Injectable, Logger } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  NotificationType,
  OrderStatus,
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
} from '../../common/events';

const WS = {
  ORDER_NEW: 'order.new',
  ORDER_STATUS: 'order.status',
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
        data: { orderId: event.orderId, orderNumber: event.orderNumber },
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

    const socketPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      oldStatus: event.oldStatus,
      newStatus: event.newStatus,
      status: event.newStatus,
      note: event.note,
      revision: event.revision,
    };

    let customerUserId: string | null = event.customerUserId ?? null;
    let vendorUserIds = event.vendorUserIds || [];
    let driverUserId: string | null = event.driverUserId ?? null;

    if (!customerUserId || vendorUserIds.length === 0) {
      const resolved = await this.resolveOrderUserIds(event.orderId);
      if (!customerUserId) customerUserId = resolved.customerUserId;
      if (vendorUserIds.length === 0) vendorUserIds = resolved.vendorUserIds;
      if (!driverUserId) driverUserId = resolved.driverUserId;
    }

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

    const customerMsg = this.buildCustomerStatusMessage(event.newStatus);
    if (customerMsg && customerUserId) {
      await this.notificationsService.create({
        userId: customerUserId,
        title: customerMsg.en,
        titleAr: customerMsg.ar,
        body: `Order ${event.orderNumber}`,
        bodyAr: `طلب ${event.orderNumber}`,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          status: event.newStatus,
        },
      });
    }

    await this.syncOrderConversationLifecycle(event);
    await this.syncLiveTrackingForDrivers(
      event,
      groupDriverRows,
      driverUserById,
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

    for (const did of allDriverIds) {
      await this.refreshDriverTracking(did, event.orderId);
    }

    let customerUserId: string | null = event.customerUserId ?? null;
    let vendorUserIds = event.vendorUserIds || [];
    let driverUserId: string | null = event.driverUserId ?? null;

    if (!customerUserId || vendorUserIds.length === 0) {
      const resolved = await this.resolveOrderUserIds(event.orderId);
      if (!customerUserId) customerUserId = resolved.customerUserId;
      if (vendorUserIds.length === 0) vendorUserIds = resolved.vendorUserIds;
      if (!driverUserId) driverUserId = resolved.driverUserId;
    }

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
      await this.notificationsService.create({
        userId: customerUserId,
        title: 'Order Cancelled',
        titleAr: 'تم إلغاء الطلب',
        body: bodyEn,
        bodyAr: bodyAr,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
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

    for (const vid of vendorStatTargets) {
      for (const did of driverStatTargets) {
        await this.statisticsService
          .recordCancellation(event.orderId, vid, did)
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to record cancellation stat: ${err instanceof Error ? err.message : String(err)}`,
            ),
          );
      }
    }
  }

  async handleOrderSettled(data: {
    orderId: string;
    orderNumber: string;
    grandTotal: number;
  }) {
    const order = await this.prisma.order.findUnique({
      where: { id: data.orderId },
      select: { customerId: true, customer: { select: { userId: true } } },
    });
    const customerUserId = order?.customer?.userId;
    if (!customerUserId) return { skipped: true };

    await this.notificationsService.create({
      userId: customerUserId,
      title: 'Order delivered',
      titleAr: 'تم توصيل الطلب',
      body: `Order ${data.orderNumber} was delivered. Total: ${data.grandTotal}.`,
      bodyAr: `تم توصيل الطلب ${data.orderNumber}. الإجمالي: ${data.grandTotal}.`,
      type: NotificationType.ORDER_UPDATE,
      data: { orderId: data.orderId, orderNumber: data.orderNumber },
    });

    return { notified: true };
  }

  private async syncOrderConversationLifecycle(event: OrderStatusChangedEvent) {
    const activeChatSyncStatuses: OrderStatus[] = [
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.PARTIALLY_PICKED_UP,
      OrderStatus.PICKED_UP,
    ];

    if (
      event.newStatus === OrderStatus.ACCEPTED ||
      event.newStatus === OrderStatus.LOOKING_FOR_DRIVER
    ) {
      const order = await this.prisma.order.findUnique({
        where: { id: event.orderId },
        select: { type: true },
      });

      if (order?.type === 'STANDARD') {
        await this.conversationsService.createSystemOrderConversation(
          event.orderId,
        );
        if (event.newStatus === OrderStatus.LOOKING_FOR_DRIVER) {
          await this.conversationsService.syncOrderDriverParticipants(
            event.orderId,
          );
        }
      }
    }

    if (activeChatSyncStatuses.includes(event.newStatus)) {
      const order = await this.prisma.order.findUnique({
        where: { id: event.orderId },
        select: { type: true },
      });

      if (order?.type === 'STANDARD') {
        if (event.driverUserId) {
          await this.conversationsService.addParticipantToOrderConversation(
            event.orderId,
            event.driverUserId,
          );
        }
        await this.conversationsService.syncOrderDriverParticipants(
          event.orderId,
        );
      } else if (
        (order?.type === 'RIDE' || order?.type === 'CUSTOM_DELIVERY') &&
        (event.newStatus === OrderStatus.DRIVER_ASSIGNED ||
          event.newStatus === OrderStatus.PENDING_PAYMENT)
      ) {
        await this.conversationsService.createSystemOrderConversation(
          event.orderId,
        );
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
  ) {
    const trackingStatuses: OrderStatus[] = [
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PENDING_PAYMENT,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.PARTIALLY_PICKED_UP,
      OrderStatus.PICKED_UP,
    ];

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
          hasActiveWorkOnThisOrder
            ? {
                orderId: event.orderId,
                customerUserId: event.customerUserId,
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
    if (ensureActiveOrder?.orderId) {
      byOrderId.set(ensureActiveOrder.orderId, ensureActiveOrder);
    }

    await this.driverTracking.syncDriverActiveOrders(
      driverId,
      Array.from(byOrderId.values()),
    );
  }

  private buildCustomerStatusMessage(
    status: OrderStatus,
  ): { en: string; ar: string } | null {
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

  private async resolveOrderUserIds(orderId: string): Promise<{
    customerUserId: string | null;
    vendorUserIds: string[];
    driverUserId: string | null;
  }> {
    try {
      const order = await this.prisma.order.findUnique({
        where: { id: orderId },
        select: {
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
        return { customerUserId: null, vendorUserIds: [], driverUserId: null };
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

      return { customerUserId, vendorUserIds, driverUserId };
    } catch (err) {
      this.logger.error(
        `Failed to resolve order user IDs for ${orderId}: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      return { customerUserId: null, vendorUserIds: [], driverUserId: null };
    }
  }
}
