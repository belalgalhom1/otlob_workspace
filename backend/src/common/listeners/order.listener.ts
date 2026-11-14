import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationType } from '@prisma/client';
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
  OrderFulfillmentDecidedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { OrderWorkflowDispatcher } from '../orders/order-workflow.dispatcher';

const WS = {
  ORDER_STATUS: 'order.status',
  DISPATCH_CANCELLED: 'dispatch.cancelled',
} as const;

@Injectable()
export class OrderListener {
  private readonly logger = new Logger(OrderListener.name);

  constructor(
    private readonly socketService: SocketService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    private readonly outboxService: OutboxService,
    private readonly workflowDispatcher: OrderWorkflowDispatcher,
  ) {}

  // Heavy side-effects run in worker processors (`EventsProcessor` on
  // QUEUES.EVENTS and domain processors on QUEUES.DISPATCH / QUEUES.ORDERS).
  // For outbox-backed lifecycle events we enqueue both paths before calling
  // `outboxService.markProcessed`, so a partial queue failure is recovered by
  // `OutboxService.relayPending()`.

  @OnEvent(EVENTS.ORDER_CREATED, { async: true })
  async handleOrderCreated(event: OrderCreatedEvent) {
    try {
      await Promise.all([
        this.eventsQueue.add(EVENT_JOBS.ORDER_CREATED, event, {
          jobId: `notify_order_created_${event.orderId}`,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderCreated(event),
      ]);
      await this.outboxService.markProcessed('ORDER', event.orderId, event.revision);
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
      ...(event.driverUserIds ?? []),
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
      await Promise.all([
        this.eventsQueue.add(EVENT_JOBS.ORDER_STATUS_CHANGED, event, {
          jobId:
            typeof event.revision === 'number'
              ? `notify_order_status_${event.orderId}_${event.revision}`
              : undefined,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderStatusChanged(event),
      ]);
      await this.outboxService.markProcessed('ORDER', event.orderId, event.revision);
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
      await Promise.all([
        this.eventsQueue.add(EVENT_JOBS.ORDER_CANCELLED, event, {
          jobId: `notify_order_cancelled_${event.orderId}`,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderCancelled(event),
      ]);
      if (typeof event.revision === 'number') {
        await this.outboxService.markProcessed('ORDER', event.orderId, event.revision);
      }
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

    // Enqueue immediately on QUEUES.EVENTS so listeners never block on Prisma.
    try {
      if (event.customerUserId) {
        await this.eventsQueue.add(
          EVENT_JOBS.NOTIFY,
          {
            dto: {
              userId: event.customerUserId,
              title: 'Order delivered',
              titleAr: 'تم توصيل الطلب',
              body: `Order ${event.orderNumber} was delivered. Total: ${event.grandTotal}.`,
              bodyAr: `تم توصيل الطلب ${event.orderNumber}. الإجمالي: ${event.grandTotal}.`,
              type: NotificationType.ORDER_UPDATE,
              data: { orderId: event.orderId, orderNumber: event.orderNumber },
            },
          },
          { attempts: 1 },
        );
      } else {
        await this.eventsQueue.add(
          EVENT_JOBS.ORDER_SETTLED,
          {
            orderId: event.orderId,
            orderNumber: event.orderNumber,
            grandTotal: event.grandTotal,
          },
          { attempts: 2, backoff: { type: 'exponential', delay: 2_000 } },
        );
      }
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue settled receipt: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // ─── Order fulfillment decided (Vendor Accept / Reject) ───────────────────

  @OnEvent(EVENTS.ORDER_FULFILLMENT_DECIDED)
  handleOrderFulfillmentDecided(event: OrderFulfillmentDecidedEvent) {
    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...(event.vendorUserIds ?? []),
      ...(event.driverUserIds ?? []),
    ]);

    const deltaPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      fulfillmentId: event.fulfillmentId,
      vendorId: event.vendorId,
      status: event.status,
      fulfillmentStatus: event.status,
    };

    notifyUserIds.forEach((uid) => {
      if (!uid) return;
      this.socketService
        .emitToUser(uid, 'order.fulfillment_updated', deltaPayload)
        .catch(() => {});
      this.socketService
        .emitToUser(uid, WS.ORDER_STATUS, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          fulfillmentId: event.fulfillmentId,
          fulfillmentStatus: event.status,
          vendorId: event.vendorId,
        })
        .catch(() => {});
    });
  }

  // ─── Order fulfillment updated (Multi-Vendor Delta) ───────────────────────

  @OnEvent(EVENTS.ORDER_FULFILLMENT_UPDATED)
  handleOrderFulfillmentUpdated(event: OrderFulfillmentUpdatedEvent) {
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
          status: event.parentStatus,
          revision: event.revision,
        })
        .catch(() => {});
    });
  }

}
