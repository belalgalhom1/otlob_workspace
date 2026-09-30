import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { EVENTS } from '../events/event-names';
import { OrderCreatedEvent } from '../events';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

@Injectable()
export class CartListener {
  private readonly logger = new Logger(CartListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  @OnEvent(EVENTS.ORDER_CREATED, { async: true })
  async handleOrderCreated(event: OrderCreatedEvent) {
    if (!event.vendorId) return; // Cart logic is specific to vendor-based orders

    this.logger.debug(
      `Catching ORDER_CREATED event for ${event.orderId}. Clearing customer's cart...`,
    );

    try {
      // The DELETE runs on the worker (EventsProcessor) via the events queue.
      await this.eventsQueue.add(
        EVENT_JOBS.CLEAR_CART,
        { customerUserId: event.customerUserId, vendorId: event.vendorId },
        { attempts: 1 },
      );
    } catch (error) {
      this.logger.error(
        `Failed to enqueue clear-cart event for user ${event.customerUserId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
