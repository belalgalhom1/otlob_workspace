import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { CartService } from '../cart/cart.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import {
  DriverAssistRequestedEvent,
  OrderCancelledEvent,
  OrderCreatedEvent,
  OrderDispatchRespondedEvent,
  OrderDispatchSentEvent,
  OrderStatusChangedEvent,
} from '../../common/events';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';
import { OrderEventsHandler } from './order-events.handler';
import { DispatchEventsHandler } from './dispatch-events.handler';

export interface CreateNotificationPayload {
  userId: string;
  title: string;
  titleAr?: string | null;
  body?: string | null;
  bodyAr?: string | null;
  type: NotificationType;
  data?: Record<string, any>;
}

/**
 * Worker processor for `QUEUES.EVENTS` fan-out. Enforces two-phase Redis
 * idempotency (`lock` + post-success `DONE`) and delegates domain handling to
 * `OrderEventsHandler` and `DispatchEventsHandler`.
 */
@Processor(QUEUES.EVENTS, { concurrency: 10 })
export class EventsProcessor extends WorkerHost {
  private readonly logger = new Logger(EventsProcessor.name);

  constructor(
    private readonly orderEventsHandler: OrderEventsHandler,
    private readonly dispatchEventsHandler: DispatchEventsHandler,
    private readonly notificationsService: NotificationsService,
    private readonly cartService: CartService,
    private readonly redis: RedisService,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const idempotencyKey = this.eventIdempotencyKey(job.name, job.data);
    const lockKey = idempotencyKey ? `${idempotencyKey}:lock` : null;

    if (idempotencyKey && lockKey) {
      const redis = this.redis.getClient();
      const done = await redis.get(idempotencyKey);
      if (done === 'DONE') return { skipped: true };

      const locked = await redis.set(lockKey, '1', 'EX', 30, 'NX');
      if (!locked) {
        const recheckDone = await redis.get(idempotencyKey);
        if (recheckDone === 'DONE') return { skipped: true };
        throw new Error(
          `Concurrent delivery in progress for ${idempotencyKey}; deferring to BullMQ retry`,
        );
      }
    }

    try {
      const result = await this.dispatchJob(job);

      if (idempotencyKey) {
        await this.redis
          .getClient()
          .set(idempotencyKey, 'DONE', 'EX', 14400)
          .catch(() => undefined);
      }
      return result;
    } catch (error: unknown) {
      this.logger.error(
        `Failed to process event job ${job.name}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      throw error;
    } finally {
      if (lockKey) {
        await this.redis.getClient().del(lockKey).catch(() => undefined);
      }
    }
  }

  private async dispatchJob(job: Job<any, any, string>): Promise<any> {
    switch (job.name) {
      case EVENT_JOBS.ORDER_CREATED:
        return this.orderEventsHandler.handleOrderCreated(
          job.data as OrderCreatedEvent,
        );
      case EVENT_JOBS.ORDER_STATUS_CHANGED:
        return this.orderEventsHandler.handleOrderStatusChanged(
          job.data as OrderStatusChangedEvent,
        );
      case EVENT_JOBS.ORDER_CANCELLED:
        return this.orderEventsHandler.handleOrderCancelled(
          job.data as OrderCancelledEvent,
        );
      case EVENT_JOBS.ORDER_SETTLED:
        return this.orderEventsHandler.handleOrderSettled(
          job.data as {
            orderId: string;
            orderNumber: string;
            grandTotal: number;
          },
        );
      case EVENT_JOBS.ORDER_DISPATCH_SENT:
        return this.dispatchEventsHandler.handleDispatchSent(
          job.data as OrderDispatchSentEvent,
        );
      case EVENT_JOBS.ORDER_DISPATCH_RESPONDED:
        return this.dispatchEventsHandler.handleDispatchResponded(
          job.data as OrderDispatchRespondedEvent,
        );
      case EVENT_JOBS.DRIVER_ASSIST_REQUESTED:
        return this.dispatchEventsHandler.handleDriverAssistRequested(
          job.data as DriverAssistRequestedEvent,
        );
      case EVENT_JOBS.CLEAR_CART: {
        const data = job.data as {
          customerUserId: string;
          vendorId?: string;
          vendorIds?: string[];
        };
        const ids = Array.from(
          new Set([
            ...(data.vendorIds ?? []),
            ...(data.vendorId ? [data.vendorId] : []),
          ]),
        );
        if (ids.length === 0) return { skipped: true };
        for (const vId of ids) {
          await this.cartService.clearCart(data.customerUserId, vId);
        }
        return { cleared: ids.length };
      }
      case EVENT_JOBS.NOTIFY: {
        const dto = (job.data as { dto: CreateNotificationPayload }).dto;
        if (!dto) return { skipped: true };
        return this.notificationsService.create(dto);
      }
      case EVENT_JOBS.CHAT_NOTIFICATIONS: {
        const dtos = (job.data as { dtos: CreateNotificationPayload[] }).dtos;
        if (!dtos?.length) return { skipped: true };
        return this.notificationsService.createMany(dtos);
      }
      default:
        this.logger.warn(`Unknown event job: ${job.name}`);
        return { ignored: true, reason: 'unknown_job_name' };
    }
  }

  private eventIdempotencyKey(name: string, data: any): string | null {
    switch (name) {
      case EVENT_JOBS.ORDER_CREATED:
        return `notify:order_created:${data.orderId}`;
      case EVENT_JOBS.ORDER_CANCELLED:
        return `notify:order_cancelled:${data.orderId}`;
      case EVENT_JOBS.ORDER_DISPATCH_SENT:
        return `notify:dispatch_sent:${data.dispatchId}:${data.driverId}`;
      case EVENT_JOBS.ORDER_DISPATCH_RESPONDED:
        return `notify:dispatch_responded:${data.dispatchId}:${data.status}:${data.driverId}`;
      case EVENT_JOBS.DRIVER_ASSIST_REQUESTED:
        return `notify:driver_assist_requested:${data.requestId}`;
      case EVENT_JOBS.ORDER_STATUS_CHANGED:
        return this.orderStatusIdempotencyKey(data as OrderStatusChangedEvent);
      default:
        return null;
    }
  }

  private orderStatusIdempotencyKey(
    event: OrderStatusChangedEvent,
  ): string | null {
    if (typeof event.revision !== 'number') return null;
    return event.dedupeKey
      ? `notify:order_status:${event.orderId}:${event.revision}:${event.dedupeKey}`
      : `notify:order_status:${event.orderId}:${event.revision}`;
  }
}
