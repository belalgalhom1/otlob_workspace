import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { EVENTS } from '../events/event-names';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  QUEUES,
  REVIEW_JOBS,
} from '../../infrastructure/queue/queues.constants';

@Injectable()
export class ReviewListener {
  private readonly logger = new Logger(ReviewListener.name);

  constructor(@InjectQueue(QUEUES.REVIEWS) private readonly queue: Queue) {}

  @OnEvent(EVENTS.REVIEW_SUBMITTED, { async: true })
  async handleReviewSubmitted(payload: {
    vendorId?: string | null;
    driverId?: string | null;
  }) {
    try {
      // Ratings are recomputed by the worker (QUEUES.REVIEWS) so the API event
      // loop never runs the aggregate queries. The job is idempotent: it SETs
      // rating/ratingCount from the full recomputed average, so retries are safe.
      await this.queue.add(
        REVIEW_JOBS.UPDATE_RATINGS,
        {
          vendorId: payload.vendorId ?? null,
          driverId: payload.driverId ?? null,
        },
        { attempts: 3, backoff: { type: 'exponential', delay: 5000 } },
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue review rating update: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }
}
