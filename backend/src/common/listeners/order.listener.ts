import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  NotificationType,
  OrderVendorFulfillmentStatus,
} from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import {
  OrderCancelledEvent,
  OrderCreatedEvent,
  OrderDispatchCancelledEvent,
  OrderDispatchRespondedEvent,
  OrderDispatchSentEvent,
  OrderFulfillmentDecidedEvent,
  OrderFulfillmentUpdatedEvent,
  OrderPaymentStatusChangedEvent,
  OrderSettledEvent,
  OrderStatusChangedEvent,
  OrderVendorRejectedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import { WS_EVENTS } from '../events/ws-events';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { OrderWorkflowDispatcher } from '../orders/order-workflow.dispatcher';

/**
 * Owns all order lifecycle, payment, dispatch-queue fan-out, and multi-vendor
 * fulfillment event listeners. Heavy side-effects run in worker processors
 * (`EventsProcessor` on `QUEUES.EVENTS` and domain processors on
 * `QUEUES.DISPATCH` / `QUEUES.ORDERS`).
 */
@Injectable()
export class OrderListener {
  private readonly logger = new Logger(OrderListener.name);

  constructor(
    private readonly socketService: SocketService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    private readonly outboxService: OutboxService,
    private readonly workflowDispatcher: OrderWorkflowDispatcher,
  ) {}

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
      await this.outboxService.markProcessed(
        'ORDER',
        event.orderId,
        event.revision,
      );
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

    notifyUserIds.forEach((uid) => {
      this.socketService
        .emitToUser(uid, WS_EVENTS.ORDER_STATUS, socketPayload)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit ${WS_EVENTS.ORDER_STATUS} for user ${uid}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    });
  }

  // ─── Order status changed ─────────────────────────────────────────────────

  @OnEvent(EVENTS.ORDER_STATUS_CHANGED, { async: true })
  async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
    try {
      const dedupeSuffix = event.dedupeKey
        ? `_${event.dedupeKey.replace(/:/g, '_')}`
        : '';
      await Promise.all([
        this.eventsQueue.add(EVENT_JOBS.ORDER_STATUS_CHANGED, event, {
          jobId:
            typeof event.revision === 'number'
              ? `notify_order_status_${event.orderId}_${event.revision}${dedupeSuffix}`
              : undefined,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderStatusChanged(event),
      ]);
      await this.outboxService.markProcessed(
        'ORDER',
        event.orderId,
        event.revision,
      );
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
          jobId:
            typeof event.revision === 'number'
              ? `notify_order_cancelled_${event.orderId}_${event.revision}`
              : `notify_order_cancelled_${event.orderId}`,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderCancelled(event),
      ]);
      if (typeof event.revision === 'number') {
        await this.outboxService.markProcessed(
          'ORDER',
          event.orderId,
          event.revision,
        );
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

    this.socketService
      .emitToUser(event.driverUserId, WS_EVENTS.DISPATCH_CANCELLED, {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
      })
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to emit ${WS_EVENTS.DISPATCH_CANCELLED} for driver ${event.driverUserId}: ${err instanceof Error ? err.message : String(err)}`,
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
  handleOrderSettled(event: OrderSettledEvent) {
    // Customer already receives the canonical outbox-backed "Your order was
    // delivered!" notification on ORDER_STATUS_CHANGED (DELIVERED).
    this.logger.log(`Order ${event.orderNumber} settled`);
  }

  // ─── Multi-vendor fulfillment decisions & rejections ──────────────────────

  @OnEvent(EVENTS.ORDER_FULFILLMENT_DECIDED, { async: true })
  async handleOrderFulfillmentDecided(event: OrderFulfillmentDecidedEvent) {
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
      ...(event.parentStatus
        ? {
            parentStatus: event.parentStatus,
            orderStatus: event.parentStatus,
          }
        : {}),
      ...(event.revision !== undefined ? { revision: event.revision } : {}),
    };

    const statusPayload = {
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      fulfillmentId: event.fulfillmentId,
      fulfillmentStatus: event.status,
      vendorId: event.vendorId,
      ...(event.parentStatus
        ? {
            status: event.parentStatus,
            newStatus: event.parentStatus,
            parentStatus: event.parentStatus,
            orderStatus: event.parentStatus,
          }
        : {}),
      ...(event.revision !== undefined ? { revision: event.revision } : {}),
    };

    notifyUserIds.forEach((uid) => {
      if (!uid) return;
      this.socketService
        .emitToUser(uid, WS_EVENTS.ORDER_FULFILLMENT_UPDATED, deltaPayload)
        .catch(() => {});
      this.socketService
        .emitToUser(uid, WS_EVENTS.ORDER_STATUS, statusPayload)
        .catch(() => {});
    });

    if (event.status === OrderVendorFulfillmentStatus.ACCEPTED) {
      try {
        await this.eventsQueue.add(EVENT_JOBS.NOTIFY, {
          dto: {
            userId: event.customerUserId,
            title: 'A vendor accepted part of your order',
            titleAr: 'قبل أحد الموردين جزءًا من طلبك',
            body: `Part of your order ${event.orderNumber} was accepted and is now being prepared.`,
            bodyAr: `تم قبول جزء من طلبك ${event.orderNumber} ويجري تجهيزه الآن.`,
            type: NotificationType.ORDER_UPDATE,
            data: {
              orderId: event.orderId,
              type: 'FULFILLMENT_ACCEPTED',
              fulfillmentId: event.fulfillmentId,
            },
          },
        });
      } catch (error: unknown) {
        this.logger.error(
          `Failed to enqueue fulfillment-accepted notification: ${error instanceof Error ? error.message : String(error)}`,
        );
      }
    }
  }

  /**
   * A vendor rejected its portion. Tell the customer promptly, naming the
   * vendor, the affected items, the reason, and the adjusted total.
   */
  @OnEvent(EVENTS.ORDER_VENDOR_REJECTED, { async: true })
  async handleOrderVendorRejected(event: OrderVendorRejectedEvent) {
    if (event.allPortionsRejected) return;

    const items =
      event.affectedItemNames.length > 0
        ? event.affectedItemNames.join(', ')
        : 'some items';
    const money =
      event.refundAmount > 0
        ? ` ${event.refundAmount} EGP was removed from your total.`
        : '';

    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, {
        dto: {
          userId: event.customerUserId,
          title: 'Part of your order was unavailable',
          titleAr: 'جزء من طلبك غير متوفر',
          body: `${event.vendorName} could not fulfil: ${items}. ${event.rejectionReason}.${money}`,
          bodyAr: `${event.vendorNameAr ?? event.vendorName} لم يستطع تلبية الطلب: ${items}. ${event.rejectionReasonAr ?? event.rejectionReason}.${money}`,
          type: NotificationType.ORDER_UPDATE,
          data: {
            orderId: event.orderId,
            type: 'VENDOR_PORTION_REJECTED',
            fulfillmentId: event.fulfillmentId,
            refundAmount: event.refundAmount,
          },
        },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue vendor-rejected notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
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
      fulfillmentStatus: event.status,
      pickedUpAt: event.pickedUpAt,
      pickupImageUrl: event.pickupImageUrl,
      parentStatus: event.parentStatus,
      orderStatus: event.parentStatus,
      fulfillmentSummary: event.fulfillmentSummary,
      ...(event.revision !== undefined ? { revision: event.revision } : {}),
    };

    const notifyUserIds = new Set<string>([
      event.customerUserId,
      ...event.vendorUserIds,
      ...event.driverUserIds,
    ]);

    notifyUserIds.forEach((uid) => {
      this.socketService
        .emitToUser(uid, WS_EVENTS.ORDER_FULFILLMENT_UPDATED, deltaPayload)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit ${WS_EVENTS.ORDER_FULFILLMENT_UPDATED} for user ${uid}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );

      this.socketService
        .emitToUser(uid, WS_EVENTS.ORDER_STATUS, {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
          oldStatus: event.parentStatus,
          newStatus: event.parentStatus,
          parentStatus: event.parentStatus,
          orderStatus: event.parentStatus,
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
