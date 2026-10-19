import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger } from '@nestjs/common';
import { DispatchStatus, NotificationType, OrderStatus } from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationsService } from '../../features/notifications/notifications.service';
import { DispatchService } from '../../features/dispatch/dispatch.service';
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
} from '../events';
import {
  QUEUES,
  ORDER_JOBS,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

const WS = {
  ORDER_NEW: 'order.new',
  ORDER_STATUS: 'order.status',
  ORDER_CANCELLED: 'order.cancelled',
  DISPATCH_INCOMING: 'dispatch.incoming',
} as const;

// Lifetime (seconds) of the per-delivery dispatch-handoff dedupe marker. Long
// enough to absorb duplicate emissions of one status transition; short enough
// that a delivery whose round found no drivers can be dispatched again later.
const DISPATCH_HANDOFF_MARKER_TTL = 300;

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
    @InjectQueue(QUEUES.ORDERS) private readonly ordersQueue: Queue,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
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
      // The inline listeners were fire-and-forget the same way: swallow and log.
      this.logger.error(
        `Failed to process event job ${job.name}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      return { failed: true, reason: error };
    }
  }

  // ─── Moved OrderListener bodies ────────────────────────────────────────────

  private async handleOrderCreated(event: OrderCreatedEvent) {
    const idempotencyKey = `notify:order_created:${event.orderId}`;
    const isNew = await this.redis
      .getClient()
      .set(idempotencyKey, '1', 'EX', 14400, 'NX');
    if (!isNew) return { skipped: true };

    this.logger.log(`Order created: ${event.orderNumber}`);

    const notificationPayloads: CreateNotificationPayload[] =
      event.vendorUserIds.map((uid) => ({
        userId: uid,
        title: 'New Order Received',
        titleAr: 'طلب جديد',
        body: `Order ${event.orderNumber} — ${event.grandTotal} EGP`,
        bodyAr: `طلب ${event.orderNumber} — ${event.grandTotal} جنيه`,
        type: NotificationType.ORDER_UPDATE,
        data: { orderId: event.orderId, orderNumber: event.orderNumber },
      }));

    await Promise.all([
      ...event.vendorUserIds.map((uid) =>
        this.socketService.emitToUser(uid, WS.ORDER_NEW, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          grandTotal: event.grandTotal,
          paymentMethod: event.paymentMethod,
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
    const idempotencyKey = `notify:order_status:${event.orderId}:${event.newStatus}`;
    const isNew = await this.redis
      .getClient()
      .set(idempotencyKey, '1', 'EX', 14400, 'NX');
    if (!isNew) return { skipped: true };

    this.logger.log(
      `Order ${event.orderNumber}: ${event.oldStatus} -> ${event.newStatus}`,
    );

    const socketPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      oldStatus: event.oldStatus,
      newStatus: event.newStatus,
      note: event.note,
    };

    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...event.vendorUserIds,
    ]);
    if (event.driverUserId) notifyUserIds.add(event.driverUserId);
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

    if (event.newStatus === OrderStatus.PICKED_UP) {
      await this.ordersQueue.add(
        ORDER_JOBS.DELIVERY_WATCHDOG,
        { orderId: event.orderId, orderNumber: event.orderNumber },
        { delay: 3 * 60 * 60 * 1000, jobId: `watchdog-${event.orderId}` },
      );
    }

    // Live Tracking Cache: maintain driver's active order in Redis
    if (event.driverUserId && event.driverId) {
      if (
        event.newStatus === OrderStatus.DRIVER_ASSIGNED ||
        event.newStatus === OrderStatus.PENDING_PAYMENT ||
        event.newStatus === OrderStatus.PREPARING ||
        event.newStatus === OrderStatus.READY_FOR_PICKUP ||
        event.newStatus === OrderStatus.PICKED_UP
      ) {
        await this.redis.set(
          `otlobegy:driver-active-order:${event.driverId}`,
          JSON.stringify({
            orderId: event.orderId,
            customerUserId: event.customerUserId,
          }),
          12 * 60 * 60,
        );
      } else if (
        event.newStatus === OrderStatus.DELIVERED ||
        event.newStatus === OrderStatus.CANCELLED
      ) {
        await this.redis.del(`otlobegy:driver-active-order:${event.driverId}`);
      }
    }
  }

  private async handleOrderCancelled(event: OrderCancelledEvent) {
    const idempotencyKey = `notify:order_cancelled:${event.orderId}`;
    const isNew = await this.redis
      .getClient()
      .set(idempotencyKey, '1', 'EX', 14400, 'NX');
    if (!isNew) return { skipped: true };
    this.logger.log(`Order cancelled: ${event.orderNumber} — ${event.reason}`);

    const allDriverIds = (event.driverIds && event.driverIds.length > 0)
      ? event.driverIds
      : (event.driverId ? [event.driverId] : []);

    for (const did of allDriverIds) {
      await this.redis.del(`otlobegy:driver-active-order:${did}`);
    }

    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...event.vendorUserIds,
    ]);
    if (event.driverUserId) notifyUserIds.add(event.driverUserId);
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
          status: 'CANCELLED',
          newStatus: 'CANCELLED',
          reason: event.reason,
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
    const idempotencyKey = `notify:dispatch_sent:${event.dispatchId}`;
    const isNew = await this.redis
      .getClient()
      .set(idempotencyKey, '1', 'EX', 14400, 'NX');
    if (!isNew) return { skipped: true };

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
        distanceKm: event.distanceKm,
        expiresAt: event.expiresAt,
        pickupLocationName: event.pickupLocationName,
        dropoffLocationName: event.dropoffLocationName,
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
    const idempotencyKey = `notify:dispatch_responded:${event.dispatchId}:${event.status}`;
    const isNew = await this.redis
      .getClient()
      .set(idempotencyKey, '1', 'EX', 14400, 'NX');
    if (!isNew) return { skipped: true };

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
      await this.redis.set(
        idempotencyKey,
        '1',
        DISPATCH_HANDOFF_MARKER_TTL,
      );
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
}
