import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { EVENTS } from '../events/event-names';
import { OrderCancelledEvent, OrderStatusChangedEvent } from '../events';
import { OrderStatus } from '@prisma/client';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

@Injectable()
export class DispatchListener {
  private readonly logger = new Logger(DispatchListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  @OnEvent(EVENTS.ORDER_CANCELLED, { async: true })
  async handleOrderCancelled(event: OrderCancelledEvent) {
    this.logger.debug(
      `Catching ORDER_CANCELLED event for ${event.orderId}. Terminating active dispatch...`,
    );
    await this.enqueueCancel(event.orderId);
  }

  @OnEvent(EVENTS.ORDER_STATUS_CHANGED, { async: true })
  async handleOrderStatusChanged(event: OrderStatusChangedEvent) {
    // If order was manually assigned to a driver, or moved to a state that doesn't need dispatch
    if (
      event.newStatus === OrderStatus.DRIVER_ASSIGNED ||
      event.newStatus === OrderStatus.PENDING_PAYMENT
    ) {
      this.logger.debug(
        `Catching ORDER_STATUS_CHANGED to ${event.newStatus} for ${event.orderId}. Terminating active dispatch...`,
      );
      await this.enqueueCancel(event.orderId);
    }
  }

  private async enqueueCancel(orderId: string) {
    try {
      await this.eventsQueue.add(
        EVENT_JOBS.CANCEL_ACTIVE_DISPATCH,
        { orderId },
        {
          attempts: 1,
        },
      );
    } catch (error) {
      this.logger.error(
        `Failed to enqueue cancel-active-dispatch event for order ${orderId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
