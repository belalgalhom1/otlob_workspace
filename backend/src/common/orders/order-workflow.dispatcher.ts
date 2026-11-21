import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { DispatchStatus, OrderStatus } from '@prisma/client';
import {
  QUEUES,
  ORDER_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { EVENTS } from '../events/event-names';
import {
  OrderCancelledEvent,
  OrderCreatedEvent,
  OrderDispatchRespondedEvent,
  OrderStatusChangedEvent,
} from '../events';

/**
 * Orchestrates durable workflow jobs on domain queues (`QUEUES.DISPATCH` and
 * `QUEUES.ORDERS`) independently from `QUEUES.EVENTS` notification/socket fan-out.
 * Invoked by real-time listeners and Outbox crash-recovery sweeps alike.
 */
@Injectable()
export class OrderWorkflowDispatcher {
  private readonly logger = new Logger(OrderWorkflowDispatcher.name);

  constructor(
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @InjectQueue(QUEUES.ORDERS) private readonly ordersQueue: Queue,
  ) {}

  async onOrderCreated(
    event: Pick<OrderCreatedEvent, 'orderId' | 'orderNumber' | 'orderType'>,
  ): Promise<void> {
    if (event.orderType === 'RIDE' || event.orderType === 'CUSTOM_DELIVERY') {
      await this.enqueueDispatchHandoff(event.orderId, event.orderNumber);
    }
  }

  async onOrderStatusChanged(
    event: Pick<
      OrderStatusChangedEvent,
      'orderId' | 'orderNumber' | 'newStatus' | 'revision'
    >,
  ): Promise<void> {
    if (
      event.newStatus === OrderStatus.ACCEPTED ||
      event.newStatus === OrderStatus.LOOKING_FOR_DRIVER
    ) {
      await this.enqueueDispatchHandoff(event.orderId, event.orderNumber);
    }

    if (
      event.newStatus === OrderStatus.DRIVER_ASSIGNED ||
      event.newStatus === OrderStatus.PENDING_PAYMENT
    ) {
      await this.enqueueCancelActiveDispatch(event.orderId);
    }

    if (
      event.newStatus === OrderStatus.PICKED_UP ||
      event.newStatus === OrderStatus.PARTIALLY_PICKED_UP
    ) {
      await this.ordersQueue.add(
        ORDER_JOBS.DELIVERY_WATCHDOG,
        { orderId: event.orderId, orderNumber: event.orderNumber },
        { delay: 3 * 60 * 60 * 1000, jobId: `watchdog-${event.orderId}` },
      );
    }

    if (event.newStatus === OrderStatus.DELIVERED) {
      await this.ordersQueue.add(
        ORDER_JOBS.SETTLE,
        { orderId: event.orderId, orderNumber: event.orderNumber },
        { attempts: 3, backoff: { type: 'exponential', delay: 5_000 } },
      );
    }
  }

  async onOrderCancelled(
    event: Pick<OrderCancelledEvent, 'orderId'>,
  ): Promise<void> {
    await this.enqueueCancelActiveDispatch(event.orderId);
  }

  async onDispatchResponded(
    event: Pick<
      OrderDispatchRespondedEvent,
      'dispatchId' | 'driverId' | 'status'
    >,
  ): Promise<void> {
    if (event.status === DispatchStatus.ACCEPTED) {
      await this.dispatchQueue.add(
        ORDER_JOBS.DISPATCH_CLEANUP_EXPIRY,
        { dispatchId: event.dispatchId },
        { attempts: 3, backoff: { type: 'exponential', delay: 1_000 } },
      );
    } else if (event.status === DispatchStatus.REJECTED) {
      await this.dispatchQueue.add(
        ORDER_JOBS.DISPATCH_REJECTION,
        { dispatchId: event.dispatchId, driverId: event.driverId },
        { attempts: 3, backoff: { type: 'exponential', delay: 1_000 } },
      );
    }
  }

  async enqueueDispatchHandoff(
    orderId: string,
    orderNumber: string,
  ): Promise<void> {
    await this.dispatchQueue.add(
      ORDER_JOBS.DISPATCH_HANDOFF,
      { orderId, orderNumber },
      { attempts: 3, backoff: { type: 'exponential', delay: 1_000 } },
    );
  }

  async enqueueCancelActiveDispatch(orderId: string): Promise<void> {
    await this.dispatchQueue.add(
      ORDER_JOBS.CANCEL_ACTIVE_DISPATCH,
      { orderId },
      { attempts: 3, backoff: { type: 'exponential', delay: 1_000 } },
    );
  }

  async enqueueCancelOrder(orderId: string, reason: string): Promise<void> {
    const jobId = `cancel_dispatch_${orderId}`;
    // Remove any completed/stale job with this ID so a retried custom search
    // session that times out again is never silently deduplicated.
    const existing = await this.ordersQueue.getJob?.(jobId);
    if (existing) {
      await existing.remove().catch(() => {});
    }
    await this.ordersQueue.add(
      ORDER_JOBS.CANCEL_ORDER,
      { orderId, reason },
      {
        jobId,
        removeOnComplete: true,
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      },
    );
  }

  /**
   * Ensure outbox crash recovery re-drives workflow orchestration alongside
   * QUEUES.EVENTS fan-out without relying on EventsProcessor for dispatch/settle.
   */
  async triggerForOutboxRow(eventType: string, payload: any): Promise<void> {
    if (!payload) return;
    try {
      if (eventType === EVENTS.ORDER_CREATED) {
        await this.onOrderCreated(payload);
      } else if (eventType === EVENTS.ORDER_STATUS_CHANGED) {
        await this.onOrderStatusChanged(payload);
      } else if (eventType === EVENTS.ORDER_CANCELLED) {
        await this.onOrderCancelled(payload);
      }
    } catch (error) {
      this.logger.warn(
        `Failed workflow dispatch for outbox ${eventType}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
