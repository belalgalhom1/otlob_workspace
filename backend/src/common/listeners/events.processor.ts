import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger } from '@nestjs/common';
import { DispatchStatus, DeliveryGroupStatus, NotificationType, OrderStatus, Role } from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationsService } from '../../features/notifications/notifications.service';
import { DispatchService } from '../../features/dispatch/dispatch.service';
import { PlatformSettingsService } from '../../features/platform-settings/platform-settings.service';
import { StatisticsService } from '../../features/statistics/statistics.service';
import { ConversationsService } from '../../features/chat/conversations.service';
import { CartService } from '../../features/cart/cart.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import {
  OrderCreatedEvent,
  OrderStatusChangedEvent,
  OrderCancelledEvent,
  OrderDispatchSentEvent,
  OrderDispatchRespondedEvent,
  DriverAssistRequestedEvent,
} from '../events';
import {
  QUEUES,
  ORDER_JOBS,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { DRIVER_ACTIVE_ORDER_STATUSES } from '../../features/orders/orders.constants';

const WS = {
  ORDER_NEW: 'order.new',
  ORDER_STATUS: 'order.status',
  ORDER_CANCELLED: 'order.cancelled',
  DISPATCH_INCOMING: 'dispatch.incoming',
} as const;

// Lifetime (seconds) of the per-delivery dispatch-handoff dedupe marker. Now
// configurable via platform settings (dispatchHandoffDedupeTtlSecs), default 300.

export interface CreateNotificationPayload {
  userId: string;
  title: string;
  titleAr?: string | null;
  body?: string | null;
  bodyAr?: string | null;
  type: NotificationType;
  data?: Record<string, any>;
}

// The public event listeners only fan jobs into this queue; the heavy I/O
// (DB writes, notification/socket fan-out, conversation creation, stats
// enqueues) executes here, on the worker process, instead of on the API
// event loop of the process that emitted the event.
@Processor(QUEUES.EVENTS, { concurrency: 10 })
export class EventsProcessor extends WorkerHost {
  private readonly logger = new Logger(EventsProcessor.name);

  constructor(
    private readonly socketService: SocketService,
    private readonly notificationsService: NotificationsService,
    private readonly dispatchService: DispatchService,
    private readonly statisticsService: StatisticsService,
    private readonly conversationsService: ConversationsService,
    private readonly cartService: CartService,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly platformSettings: PlatformSettingsService,
    @InjectQueue(QUEUES.ORDERS) private readonly ordersQueue: Queue,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    // Claim the event-level idempotency marker BEFORE running the handler so
    // duplicate emissions are skipped. On failure the claim is released and
    // the error is re-thrown: BullMQ must see the failure, otherwise the
    // attempts/backoff configured on the producing job never apply.
    const idempotencyKey = this.eventIdempotencyKey(job.name, job.data);
    if (idempotencyKey) {
      const claimed = await this.redis
        .getClient()
        .set(idempotencyKey, '1', 'EX', 14400, 'NX');
      if (!claimed) return { skipped: true };
    }

    try {
      switch (job.name) {
        case EVENT_JOBS.ORDER_CREATED:
          return await this.handleOrderCreated(job.data as OrderCreatedEvent);
        case EVENT_JOBS.ORDER_STATUS_CHANGED:
          return await this.handleOrderStatusChanged(
            job.data as OrderStatusChangedEvent,
          );
        case EVENT_JOBS.ORDER_CANCELLED:
          return await this.handleOrderCancelled(
            job.data as OrderCancelledEvent,
          );
        case EVENT_JOBS.ORDER_DISPATCH_SENT:
          return await this.handleDispatchSent(
            job.data as OrderDispatchSentEvent,
          );
        case EVENT_JOBS.ORDER_DISPATCH_RESPONDED:
          return await this.handleDispatchResponded(
            job.data as OrderDispatchRespondedEvent,
          );
        case EVENT_JOBS.DRIVER_ASSIST_REQUESTED:
          return await this.handleDriverAssistRequested(
            job.data as DriverAssistRequestedEvent,
          );
        case EVENT_JOBS.DISPATCH_HANDOFF:
          return await this.handleDispatchHandoff(
            job.data as { orderId: string; orderNumber: string },
          );
        case EVENT_JOBS.CANCEL_ACTIVE_DISPATCH:
          return await this.cancelActiveDispatch(
            (job.data as { orderId: string }).orderId,
          );
        case EVENT_JOBS.CLEAR_CART:
          return await this.clearCart(
            job.data as { customerUserId: string; vendorId: string },
          );
        case EVENT_JOBS.NOTIFY:
          return await this.createNotification(
            (job.data as { dto: CreateNotificationPayload }).dto,
          );
        case EVENT_JOBS.CHAT_NOTIFICATIONS:
          return await this.createNotifications(
            (job.data as { dtos: CreateNotificationPayload[] }).dtos,
          );
        default:
          this.logger.warn(`Unknown event job: ${job.name}`);
          return { ignored: true, reason: 'unknown_job_name' };
      }
    } catch (error: unknown) {
      if (idempotencyKey) {
        // Without releasing the claim the retry would immediately skip as a
        // duplicate, making the retry policy useless.
        await this.redis
          .getClient()
          .del(idempotencyKey)
          .catch(() => undefined);
      }
      this.logger.error(
        `Failed to process event job ${job.name}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      throw error;
    }
  }

  /**
   * Deterministic idempotency marker for event jobs. Centralised here so the
   * claim can be released on failure; the handlers no longer shadow it.
   */
  private eventIdempotencyKey(name: string, data: any): string | null {
    switch (name) {
      case EVENT_JOBS.ORDER_CREATED:
        return `notify:order_created:${data.orderId}`;
      case EVENT_JOBS.ORDER_CANCELLED:
        return `notify:order_cancelled:${data.orderId}`;
      case EVENT_JOBS.ORDER_DISPATCH_SENT:
        return `notify:dispatch_sent:${data.dispatchId}`;
      case EVENT_JOBS.ORDER_DISPATCH_RESPONDED:
        // Include the driver: an expiry round emits one EXPIRED event per
        // candidate, and they must not dedupe each other away.
        return `notify:dispatch_responded:${data.dispatchId}:${data.status}:${data.driverId}`;
      case EVENT_JOBS.DRIVER_ASSIST_REQUESTED:
        return `notify:driver_assist_requested:${data.requestId}`;
      case EVENT_JOBS.ORDER_STATUS_CHANGED:
        return this.orderStatusIdempotencyKey(
          data as OrderStatusChangedEvent,
        );
      default:
        return null;
    }
  }

  private orderStatusIdempotencyKey(
    event: OrderStatusChangedEvent,
  ): string | null {
    // Event identity is (orderId, revision, dedupeKey). Order.revision is bumped
    // in the same transaction as every status write (enforced by a DB trigger),
    // so a revision identifies exactly one transition. A transition that emits
    // several events supplies a stable dedupeKey; everything else emits one
    // event per revision.
    //
    // A missing revision can only come from a job that was already sitting in
    // the queue before the revision rollout. Such a job has no reliable
    // identity, so it is deliberately NOT deduped rather than risking a false
    // suppression of a distinct transition.
    if (typeof event.revision !== 'number') return null;
    return event.dedupeKey
      ? `notify:order_status:${event.orderId}:${event.revision}:${event.dedupeKey}`
      : `notify:order_status:${event.orderId}:${event.revision}`;
  }

  // ─── Moved OrderListener bodies ────────────────────────────────────────────

  private async handleOrderCreated(event: OrderCreatedEvent) {
    this.logger.log(`Order created: ${event.orderNumber}`);

    let vendorUserIds = event.vendorUserIds || [];
    if (!vendorUserIds || vendorUserIds.length === 0) {
      const resolved = await this.resolveOrderUserIds(event.orderId);
      vendorUserIds = resolved.vendorUserIds;
    }

    const notificationPayloads: CreateNotificationPayload[] =
      vendorUserIds.map((uid) => ({
        userId: uid,
        title: 'New Order Received',
        titleAr: 'طلب جديد',
        body: `Order ${event.orderNumber} — ${event.grandTotal} EGP`,
        bodyAr: `طلب ${event.orderNumber} — ${event.grandTotal} جنيه`,
        type: NotificationType.ORDER_UPDATE,
        data: { orderId: event.orderId, orderNumber: event.orderNumber },
      }));

    await Promise.all([
      ...vendorUserIds.map((uid) =>
        this.socketService.emitToUser(uid, WS.ORDER_NEW, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          grandTotal: event.grandTotal,
          paymentMethod: event.paymentMethod,
          // Seeds the client's last-seen revision; every later status event
          // carries a revision >= this one.
          revision: event.revision,
        }),
      ),
      ...(notificationPayloads.length
        ? [this.notificationsService.createMany(notificationPayloads)]
        : []),
    ]);

    // Custom orders (no vendor to accept) go straight to dispatch. The handoff is
    // its own retryable job so a transient EVENTS worker failure cannot stall
    // dispatch start (the parent ORDER_CREATED job is attempts: 1).
    if (event.orderType === 'RIDE' || event.orderType === 'CUSTOM_DELIVERY') {
      await this.enqueueDispatchHandoff(event.orderId, event.orderNumber);
    }
  }

  private async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
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

    // Multi-vendor orders hand each delivery group to its own driver (and an
    // optional assistant). The event only carries the order-level mirror of
    // the first group, so every assigned group driver must be resolved here or
    // the other vendors' drivers never receive live status updates.
    const groupDriverRows = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: event.orderId },
      select: {
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

    // Customer push notification for key status changes
    const customerMsg = this.buildCustomerStatusMessage(event.newStatus);
    if (customerMsg) {
      await this.notificationsService.create({
        userId: event.customerUserId,
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

    // Trigger dispatch and chat when vendor accepts order (looking-for-driver
    // transitions also re-kick dispatch for flows that skip ACCEPTED).
    if (
      event.newStatus === OrderStatus.ACCEPTED ||
      event.newStatus === OrderStatus.LOOKING_FOR_DRIVER
    ) {
      const order = await this.prisma.order.findUnique({
        where: { id: event.orderId },
        select: { type: true },
      });

      // Multi-vendor orders never pass through ACCEPTED — they advance from
      // PENDING straight to LOOKING_FOR_DRIVER once every portion is decided —
      // so the chat must also be created on that transition.
      if (
        (event.newStatus === OrderStatus.ACCEPTED ||
          event.newStatus === OrderStatus.LOOKING_FOR_DRIVER) &&
        order?.type === 'STANDARD'
      ) {
        await this.conversationsService.createSystemOrderConversation(
          event.orderId,
        );
        if (event.newStatus === OrderStatus.LOOKING_FOR_DRIVER) {
          await this.conversationsService.syncOrderDriverParticipants(
            event.orderId,
          );
        }
      }

      await this.enqueueDispatchHandoff(event.orderId, event.orderNumber);
    }

    // Assign driver to chat if they just took the order
    if (
      event.newStatus === OrderStatus.DRIVER_ASSIGNED ||
      event.newStatus === OrderStatus.PENDING_PAYMENT
    ) {
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
      } else if (order?.type === 'RIDE' || order?.type === 'CUSTOM_DELIVERY') {
        await this.conversationsService.createSystemOrderConversation(
          event.orderId,
        );
      }
    }

    // Settle + close chat on delivery
    if (event.newStatus === OrderStatus.DELIVERED) {
      await this.conversationsService
        .closeSystemOrderConversation(event.orderId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to close order conversation on delivery: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );

      await this.ordersQueue.add(
        ORDER_JOBS.SETTLE,
        { orderId: event.orderId, orderNumber: event.orderNumber },
        { attempts: 3, backoff: { type: 'exponential', delay: 5_000 } },
      );
    }

    if (event.newStatus === OrderStatus.PICKED_UP || event.newStatus === OrderStatus.PARTIALLY_PICKED_UP) {
      await this.ordersQueue.add(
        ORDER_JOBS.DELIVERY_WATCHDOG,
        { orderId: event.orderId, orderNumber: event.orderNumber },
        { delay: 3 * 60 * 60 * 1000, jobId: `watchdog-${event.orderId}` },
      );
    }

    // Live Tracking Cache: maintain each assigned driver's active order in
    // Redis. A multi-vendor order can have several drivers (one per delivery),
    // so every group driver is updated, not just the order-level mirror.
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
        await this.refreshDriverTracking(driverId, undefined, {
          orderId: event.orderId,
          customerUserId: event.customerUserId,
        });
      } else if (
        event.newStatus === OrderStatus.DELIVERED ||
        event.newStatus === OrderStatus.CANCELLED
      ) {
        await this.refreshDriverTracking(driverId, event.orderId);
      }
    }
  }

  /**
   * Rebuild one driver's live-order tracking key across all batched/active work.
   *
   * A driver can carry more than one unit of work simultaneously (batched orders
   * or multiple delivery groups), so all active orders are stored in `orders`
   * (with `orderId`/`customerUserId` kept at top level for backward compatibility).
   */
  private async refreshDriverTracking(
    driverId: string,
    endedOrderId?: string,
    ensureActiveOrder?: { orderId: string; customerUserId: string },
  ) {
    const [remainingGroups, remainingOrders] = await Promise.all([
      this.prisma.orderDeliveryGroup.findMany({
        where: {
          status: {
            notIn: [
              DeliveryGroupStatus.CANCELLED,
              DeliveryGroupStatus.DELIVERED,
            ],
          },
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
      }),
      this.prisma.order.findMany({
        where: {
          driverId,
          ...(endedOrderId ? { id: { not: endedOrderId } } : {}),
          status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
          deliveryGroups: { none: {} },
        },
        select: {
          id: true,
          customerId: true,
          customer: { select: { userId: true } },
        },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    const byOrderId = new Map<string, { orderId: string; customerUserId: string }>();
    for (const g of remainingGroups) {
      if (endedOrderId && g.orderId === endedOrderId) continue;
      byOrderId.set(g.orderId, {
        orderId: g.orderId,
        customerUserId: g.order.customer?.userId ?? g.order.customerId,
      });
    }
    for (const o of remainingOrders) {
      byOrderId.set(o.id, {
        orderId: o.id,
        customerUserId: o.customer?.userId ?? o.customerId,
      });
    }
    if (ensureActiveOrder?.orderId) {
      byOrderId.set(ensureActiveOrder.orderId, ensureActiveOrder);
    }

    const activeList = Array.from(byOrderId.values());
    if (activeList.length > 0) {
      await this.redis.set(
        `otlobegy:driver-active-order:${driverId}`,
        JSON.stringify({
          orderId: activeList[0].orderId,
          customerUserId: activeList[0].customerUserId,
          orders: activeList,
        }),
        12 * 60 * 60,
      );
    } else {
      await this.redis.del(`otlobegy:driver-active-order:${driverId}`);
    }
  }

  private async handleOrderCancelled(event: OrderCancelledEvent) {
    this.logger.log(`Order cancelled: ${event.orderNumber} — ${event.reason}`);

    const allDriverIds = (event.driverIds && event.driverIds.length > 0)
      ? event.driverIds
      : (event.driverId ? [event.driverId] : []);

    for (const did of allDriverIds) {
      // The cancelled order's groups are already cancelled, but the driver may
      // still be carrying another delivery, so only repoint/clear their key.
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
    // Multi-vendor: notify every primary driver, not just the order-level one.
    if (allDriverIds.length > 0) {
      const drivers = await this.prisma.driver.findMany({
        where: { id: { in: allDriverIds } },
        select: { userId: true },
      });
      for (const d of drivers) {
        if (d.userId) notifyUserIds.add(d.userId);
      }
    }

    // Single canonical event: every client already handles order.status with
    // CANCELLED (fast flip + refetch). The legacy order.cancelled emit only
    // doubled Redis publishes and client re-renders.
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
          revision: event.revision ?? null,
        }),
      ),
    );

    // Notify customer via push
    await this.notificationsService.create({
      userId: event.customerUserId,
      title: 'Order Cancelled',
      titleAr: 'تم إلغاء الطلب',
      body: event.reason,
      bodyAr: event.reason,
      type: NotificationType.ORDER_UPDATE,
      data: { orderId: event.orderId, orderNumber: event.orderNumber },
    });

    await this.conversationsService
      .closeSystemOrderConversation(event.orderId)
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to close order conversation on cancel: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );

    const cancelDrivers = allDriverIds.length > 0 ? allDriverIds : (event.driverId ? [event.driverId] : []);
    for (const did of cancelDrivers) {
      await this.statisticsService
        .recordCancellation(event.orderId, event.vendorId, did)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record cancellation stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }
  }

  private async handleDispatchSent(event: OrderDispatchSentEvent) {
    this.logger.log(
      `Dispatch sent to driver ${event.driverId} for order ${event.orderNumber}`,
    );

    await this.socketService.emitToUser(
      event.driverUserId,
      WS.DISPATCH_INCOMING,
      {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
        orderNumber: event.orderNumber,
        type: event.type,
        estimatedEarnings: event.estimatedEarnings,
        deliveryFee: event.deliveryFee ?? null,
        distanceKm: event.distanceKm,
        expiresAt: event.expiresAt,
        pickupLocationName: event.pickupLocationName,
        dropoffLocationName: event.dropoffLocationName,
        isStacked: event.isStacked,
      },
    );

    await this.notificationsService.create({
      userId: event.driverUserId,
      title: 'New Delivery Request',
      titleAr: 'طلب توصيل جديد',
      body: `Order ${event.orderNumber} — ${event.distanceKm.toFixed(1)}km`,
      bodyAr: `طلب ${event.orderNumber} — ${event.distanceKm.toFixed(1)} كم`,
      type: NotificationType.ORDER_UPDATE,
      data: {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
        type: 'DISPATCH',
      },
    });

    await this.statisticsService
      .recordDispatchSent(event.dispatchId, event.driverId)
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to record dispatch-sent stat: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
  }

  private async handleDispatchResponded(event: OrderDispatchRespondedEvent) {
    this.logger.log(
      `Dispatch ${event.dispatchId} responded: ${event.status} by driver ${event.driverId}`,
    );

    if (event.status === DispatchStatus.ACCEPTED) {
      const expiryJob = await this.dispatchQueue.getJob(
        `dispatch-expire-${event.dispatchId}`,
      );
      if (expiryJob) await expiryJob.remove();

      await this.statisticsService
        .recordDispatchAccepted(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-accepted stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    } else if (event.status === DispatchStatus.REJECTED) {
      await this.dispatchService.handleRejection(
        event.dispatchId,
        event.driverId,
      );
      await this.statisticsService
        .recordDispatchRejected(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-rejected stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    } else if (event.status === DispatchStatus.EXPIRED) {
      await this.statisticsService
        .recordDispatchExpired(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-expired stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }
  }

  // ─── Driver assist requests ────────────────────────────────────────────────

  // DRIVER_ASSIST_REQUESTED had no subscriber, so a driver asking for a second
  // pair of hands never surfaced to operations. Notify the people who can
  // approve it through the normal notification pipeline, which also emits the
  // realtime socket event.
  //
  // Scope matters: a driver manager only handles drivers in their own zone
  // (unless granted manageAllDrivers), so blasting every manager in the
  // country would page people who cannot act on the request.
  private async handleDriverAssistRequested(
    event: DriverAssistRequestedEvent,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: event.orderId },
      select: { zoneId: true },
    });
    const zoneId = order?.zoneId ?? null;

    const managerScope = zoneId
      ? { OR: [{ manageAllDrivers: true }, { zoneId }] }
      : { manageAllDrivers: true };

    const recipients = await this.prisma.user.findMany({
      where: {
        OR: [
          { role: { in: [Role.ADMIN, Role.SUPER_ADMIN] } },
          {
            role: Role.DRIVER_MANAGER,
            driverManager: { is: managerScope },
          },
        ],
      },
      select: { id: true },
    });
    if (recipients.length === 0) return { skipped: true };

    await this.notificationsService.createMany(
      recipients.map(({ id }) => ({
        userId: id,
        title: 'Driver assistance requested',
        titleAr: 'طلب مساعدة سائق',
        body: `A driver requested assistance on order ${event.orderNumber}.`,
        bodyAr: `طلب سائق المساعدة في الطلب ${event.orderNumber}.`,
        type: NotificationType.SYSTEM,
        data: {
          requestId: event.requestId,
          orderId: event.orderId,
          deliveryGroupId: event.deliveryGroupId,
          driverUserId: event.driverUserId,
        },
      })),
    );

    return { notified: recipients.length };
  }

  // ─── Dispatch handoff ──────────────────────────────────────────────────────

  // Enqueues ORDER_JOBS.DISPATCH. It runs as its own retryable EVENTS job so a
  // transient failure cannot stall a dispatch start (parent event jobs are
  // attempts: 1, fire-and-forget). A completion marker in Redis makes replays
  // safe if the parent event ever fires twice.
  private async enqueueDispatchHandoff(orderId: string, orderNumber: string) {
    await this.eventsQueue.add(
      EVENT_JOBS.DISPATCH_HANDOFF,
      { orderId, orderNumber },
      { attempts: 3, backoff: { type: 'exponential', delay: 1_000 } },
    );
  }

  private async handleDispatchHandoff(data: {
    orderId: string;
    orderNumber: string;
  }) {
    // A multi-vendor order splits into delivery groups, each of which needs its
    // OWN driver, so fan out one independent dispatch round per non-empty group.
    // Legacy/single-delivery orders (no groups) keep the single order-level job.
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: data.orderId, items: { some: {} } },
      select: { id: true },
      orderBy: { sequence: 'asc' },
    });

    const jobPayloads: Array<{
      orderId: string;
      orderNumber: string;
      attempt: number;
      deliveryGroupId?: string | null;
    }> =
      groups.length > 0
        ? groups.map((group) => ({
            orderId: data.orderId,
            orderNumber: data.orderNumber,
            attempt: 1,
            deliveryGroupId: group.id,
          }))
        : [
            {
              orderId: data.orderId,
              orderNumber: data.orderNumber,
              attempt: 1,
            },
          ];

    // One settings read for the whole fan-out instead of one per delivery group.
    // A missing or corrupt value falls back to the documented default rather
    // than making Redis SET EX reject every handoff.
    const configuredHandoffTtl = Number(
      (await this.platformSettings.getSettings().catch(() => null))
        ?.dispatchHandoffDedupeTtlSecs ?? 300,
    );
    const handoffTtl =
      Number.isFinite(configuredHandoffTtl) && configuredHandoffTtl > 0
        ? configuredHandoffTtl
        : 300;

    let enqueued = 0;
    for (const payload of jobPayloads) {
      // Dedupe per DELIVERY, not per order: an order-level key meant one
      // delivery's marker suppressed every other delivery's dispatch for the
      // whole TTL, and the 4h TTL blocked a legitimate later re-dispatch.
      const scope = payload.deliveryGroupId ?? payload.orderId;
      const idempotencyKey = `otlobegy:dispatch-handoff:${data.orderId}:${scope}`;
      if (await this.redis.get(idempotencyKey)) continue;

      await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, payload, {
        delay: 500,
        attempts: 5,
        backoff: { type: 'fixed', delay: 60_000 },
      });

      // Marker set AFTER the add, so a retry after a partial failure re-runs
      // the missing adds while a duplicate event emission is deduped. The TTL
      // only needs to cover duplicate emissions of the same transition — long
      // enough for that, short enough to allow a real re-dispatch later.
      // Duplicated enqueues are additionally absorbed by the dispatch
      // processor's in-flight guard.
      await this.redis.set(idempotencyKey, '1', handoffTtl);
      enqueued++;
    }

    return { enqueued, groups: groups.length };
  }

  // ─── Moved DispatchListener / CartListener / NotificationListener ──────────

  private async cancelActiveDispatch(orderId: string) {
    this.logger.debug(`Cancelling active dispatch for order ${orderId}`);
    await this.dispatchService.cancelActiveDispatch(orderId);
  }

  private async clearCart(data: { customerUserId: string; vendorId: string }) {
    if (!data.vendorId) return { skipped: true };
    await this.cartService.clearCart(data.customerUserId, data.vendorId);
  }

  private async createNotification(dto: CreateNotificationPayload) {
    if (!dto) return { skipped: true };
    await this.notificationsService.create(dto);
  }

  private async createNotifications(dtos: CreateNotificationPayload[]) {
    if (!dtos?.length) return { skipped: true };
    await this.notificationsService.createMany(dtos);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

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
          vendorId: true,
          driverId: true,
          driver: { select: { userId: true } },
        },
      });
      if (!order) {
        return { customerUserId: null, vendorUserIds: [], driverUserId: null };
      }

      const customerUserId = order.customer?.userId || order.customerId;
      const driverUserId = order.driver?.userId || null;

      let vendorUserIds: string[] = [];
      if (order.vendorId) {
        const members = await this.prisma.vendorMember.findMany({
          where: { vendorId: order.vendorId },
          select: { userId: true },
        });
        vendorUserIds = members.map((m) => m.userId);
      } else {
        const fulfillments = await this.prisma.orderVendorFulfillment.findMany({
          where: { orderId },
          select: { vendorId: true },
        });
        const vIds = [...new Set(fulfillments.map((f) => f.vendorId))];
        if (vIds.length > 0) {
          const members = await this.prisma.vendorMember.findMany({
            where: { vendorId: { in: vIds } },
            select: { userId: true },
          });
          vendorUserIds = members.map((m) => m.userId);
        }
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
