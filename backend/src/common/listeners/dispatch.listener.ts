import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { EVENTS } from '../events/event-names';
import {
  OrderCancelledEvent,
  OrderCreatedEvent,
  OrderDispatchRespondedEvent,
  OrderStatusChangedEvent,
} from '../events';
import { OrderWorkflowDispatcher } from '../orders/order-workflow.dispatcher';

/**
 * Orchestrates durable workflow transitions on domain queues (`QUEUES.DISPATCH`
 * and `QUEUES.ORDERS`) independently from notification/socket fan-out.
 */
@Injectable()
export class DispatchListener {
  private readonly logger = new Logger(DispatchListener.name);

  constructor(private readonly workflowDispatcher: OrderWorkflowDispatcher) {}

  @OnEvent(EVENTS.ORDER_CREATED, { async: true })
  async handleOrderCreated(event: OrderCreatedEvent) {
    try {
      await this.workflowDispatcher.onOrderCreated(event);
    } catch (error: unknown) {
      this.logger.error(
        `Failed workflow dispatch on order.created for ${event.orderId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.ORDER_STATUS_CHANGED, { async: true })
  async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
    try {
      await this.workflowDispatcher.onOrderStatusChanged(event);
    } catch (error: unknown) {
      this.logger.error(
        `Failed workflow dispatch on order.status_changed (${event.newStatus}) for ${event.orderId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.ORDER_CANCELLED, { async: true })
  async handleOrderCancelled(event: OrderCancelledEvent) {
    try {
      await this.workflowDispatcher.onOrderCancelled(event);
    } catch (error: unknown) {
      this.logger.error(
        `Failed workflow dispatch on order.cancelled for ${event.orderId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.ORDER_DISPATCH_RESPONDED, { async: true })
  async handleDispatchResponded(event: OrderDispatchRespondedEvent) {
    try {
      await this.workflowDispatcher.onDispatchResponded(event);
    } catch (error: unknown) {
      this.logger.error(
        `Failed workflow dispatch on dispatch.responded for ${event.dispatchId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
