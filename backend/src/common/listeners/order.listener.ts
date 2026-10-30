import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { NotificationsService } from '../../features/notifications/notifications.service';
import {
  OrderCreatedEvent,
  OrderStatusChangedEvent,
  OrderCancelledEvent,
  OrderDispatchSentEvent,
  OrderDispatchRespondedEvent,
  OrderDispatchCancelledEvent,
  OrderSettledEvent,
  OrderPaymentStatusChangedEvent,
  OrderFulfillmentUpdatedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

const WS = {
  ORDER_STATUS: 'order.status',
  DISPATCH_CANCELLED: 'dispatch.cancelled',
} as const;

@Injectable()
export class OrderListener {
  private readonly logger = new Logger(OrderListener.name);

  constructor(
    private readonly socketService: SocketService,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  // The heavy side-effects (notifications, conversations, stats, dispatch
  // handoff, live-tracking cache) run in the worker's EventsProcessor; these
  // listeners only fan the work off the emitting process's event loop.

  @OnEvent(EVENTS.ORDER_CREATED, { async: true })
  async handleOrderCreated(event: OrderCreatedEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.ORDER_CREATED, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue order.created event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Order payment status changed (Mobile Wallet) ─────────────────────────

  @OnEvent(EVENTS.ORDER_PAYMENT_STATUS_CHANGED)
  handleOrderPaymentStatusChanged(event: OrderPaymentStatusChangedEvent) {
    this.logger.log(
      `Order ${event.orderNumber} payment status: ${event.paymentStatus}`,
    );

    const socketPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      paymentStatus: event.paymentStatus,
      message: event.message,
    };

    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...event.vendorUserIds,
    ]);
    if (event.driverUserId) notifyUserIds.add(event.driverUserId);

    // Socket-only, kept inline for realtime latency.
    notifyUserIds.forEach((uid) => {
      this.socketService
        .emitToUser(uid, WS.ORDER_STATUS, socketPayload)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit WS.ORDER_STATUS for user ${uid}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    });
  }

  // ─── Order status changed ─────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_STATUS_CHANGED, { async: true })
  async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.ORDER_STATUS_CHANGED, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue order.status_changed event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Order cancelled ──────────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_CANCELLED, { async: true })
  async handleOrderCancelled(event: OrderCancelledEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.ORDER_CANCELLED, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue order.cancelled event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Dispatch sent ────────────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_DISPATCH_SENT, { async: true })
  async handleDispatchSent(event: OrderDispatchSentEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.ORDER_DISPATCH_SENT, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue order.dispatch_sent event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Dispatch cancelled ───────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_DISPATCH_CANCELLED)
  handleDispatchCancelled(event: OrderDispatchCancelledEvent) {
    this.logger.log(
      `Dispatch cancelled for driver ${event.driverUserId} on order ${event.orderId}`,
    );

    // Socket-only, kept inline for realtime latency.
    this.socketService
      .emitToUser(event.driverUserId, WS.DISPATCH_CANCELLED, {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
      })
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to emit WS.DISPATCH_CANCELLED for driver ${event.driverUserId}: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
  }

  // ─── Dispatch responded ───────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_DISPATCH_RESPONDED, { async: true })
  async handleDispatchResponded(event: OrderDispatchRespondedEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.ORDER_DISPATCH_RESPONDED, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue order.dispatch_responded event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Order settled ────────────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_SETTLED)
  async handleOrderSettled(event: OrderSettledEvent) {
    this.logger.log(`Order ${event.orderNumber} settled`);

    // Send a receipt notification to the customer (best-effort).
    try {
      const order = await this.prisma.order.findUnique({
        where: { id: event.orderId },
        select: { customerId: true, orderNumber: true },
      });
      if (order?.customerId) {
        const customer = await this.prisma.customer.findUnique({
          where: { id: order.customerId },
          select: { userId: true },
        });
        if (customer?.userId) {
          await this.notificationsService.create({
            userId: customer.userId,
            title: 'Order delivered',
            titleAr: 'تم توصيل الطلب',
            body: `Order ${event.orderNumber} was delivered. Total: ${event.grandTotal}.`,
            bodyAr: `تم توصيل الطلب ${event.orderNumber}. الإجمالي: ${event.grandTotal}.`,
            type: 'ORDER_UPDATE' as any,
            data: { orderId: event.orderId, orderNumber: event.orderNumber },
          });
        }
      }
    } catch (error: unknown) {
      this.logger.error(
        `Failed to send settled receipt: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
}

  // ─── Order fulfillment updated (Multi-Vendor Delta) ───────────────────────

  @OnEvent(EVENTS.ORDER_FULFILLMENT_UPDATED)
  async handleOrderFulfillmentUpdated(event: OrderFulfillmentUpdatedEvent) {
    this.logger.log(
      `Order ${event.orderNumber} fulfillment ${event.fulfillmentId}: ${event.status}`,
    );

    const deltaPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      fulfillmentId: event.fulfillmentId,
      status: event.status,
      pickedUpAt: event.pickedUpAt,
      pickupImageUrl: event.pickupImageUrl,
      parentStatus: event.parentStatus,
      orderStatus: event.parentStatus,
      fulfillmentSummary: event.fulfillmentSummary,
    };

    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...event.vendorUserIds,
      ...event.driverUserIds,
    ]);

    notifyUserIds.forEach((uid) => {
      // 1. Emit dedicated real-time delta event
      this.socketService
        .emitToUser(uid, 'order.fulfillment_updated', deltaPayload)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit order.fulfillment_updated for user ${uid}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );

      // 2. Also emit on order.status with enriched delta for backwards compatibility
      this.socketService
        .emitToUser(uid, WS.ORDER_STATUS, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          oldStatus: event.parentStatus,
          newStatus: event.parentStatus,
          fulfillmentId: event.fulfillmentId,
          fulfillmentStatus: event.status,
          pickedUpAt: event.pickedUpAt,
          pickupImageUrl: event.pickupImageUrl,
          fulfillmentSummary: event.fulfillmentSummary,
          note: `Fulfillment stop ${event.fulfillmentId} ${event.status}`,
        })
        .catch(() => {});
    });
  }

}
