import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { EVENTS } from '../events/event-names';
import { OrderDispatchRespondedEvent } from '../events';
import { OrderWorkflowDispatcher } from '../orders/order-workflow.dispatcher';

/**
 * Coordinates dispatch-response domain queue orchestration (`QUEUES.DISPATCH`).
 * Order lifecycle workflow triggers (`ORDER_CREATED`, `ORDER_STATUS_CHANGED`,
 * `ORDER_CANCELLED`) are coordinated atomically alongside Outbox completion in
 * `OrderListener`.
 */
@Injectable()
export class DispatchListener {
  private readonly logger = new Logger(DispatchListener.name);

  constructor(private readonly workflowDispatcher: OrderWorkflowDispatcher) {}

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
