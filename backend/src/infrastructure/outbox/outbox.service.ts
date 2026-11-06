import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { randomUUID } from 'crypto';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { QUEUES, EVENT_JOBS } from '../queue/queues.constants';
import { EVENTS } from '../../common/events/event-names';

export interface RecordOutboxParams {
  orderId: string;
  revision: number;
  eventType: string;
  payload: any;
}

@Injectable()
export class OutboxService {
  private readonly logger = new Logger(OutboxService.name);

  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  /**
   * Persist a Domain Event inside the caller's active database transaction.
   * Atomically couples state mutation to event persistence, solving the
   * distributed dual-write problem.
   */
  async record(
    tx: Prisma.TransactionClient,
    params: RecordOutboxParams,
  ): Promise<string> {
    const id = randomUUID();
    const payloadJson = JSON.stringify(params.payload);

    await tx.$executeRaw`
      INSERT INTO "order_outbox" ("id", "orderId", "revision", "eventType", "payload", "createdAt")
      VALUES (${id}, ${params.orderId}, ${params.revision}, ${params.eventType}, ${payloadJson}::jsonb, NOW())
    `;

    return id;
  }

  /**
   * Immediate post-transaction relay (fast path).
   * Pushes the event directly to BullMQ and stamps processedAt in Postgres.
   */
  async relay(id: string, eventType: string, payload: any): Promise<void> {
    try {
      const jobName = this.mapEventTypeToJobName(eventType);
      if (!jobName) return;

      const dedupeKey = this.buildDedupeKey(eventType, payload);

      await this.eventsQueue.add(jobName, payload, {
        jobId: dedupeKey ?? undefined,
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });

      await this.prisma.$executeRaw`
        UPDATE "order_outbox"
        SET "processedAt" = NOW()
        WHERE "id" = ${id}
      `;
    } catch (err) {
      this.logger.warn(
        `Immediate outbox relay for ${id} deferred to background sweep: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
    }
  }

  /**
   * Sweep and publish any unprocessed outbox rows (safety net / crash recovery).
   * Picks rows where processedAt IS NULL and createdAt < NOW() - 1 second to
   * avoid racing an in-flight transaction.
   */
  async relayPending(batchSize = 50): Promise<{ relayed: number }> {
    try {
      const rows = await this.prisma.$queryRaw<
        Array<{
          id: string;
          orderId: string;
          revision: number;
          eventType: string;
          payload: any;
        }>
      >`
        SELECT "id", "orderId", "revision", "eventType", "payload"
        FROM "order_outbox"
        WHERE "processedAt" IS NULL
          AND "createdAt" < NOW() - INTERVAL '1 second'
        ORDER BY "createdAt" ASC
        LIMIT ${batchSize}
      `;

      if (!rows || rows.length === 0) {
        return { relayed: 0 };
      }

      let count = 0;
      for (const row of rows) {
        const jobName = this.mapEventTypeToJobName(row.eventType);
        if (!jobName) {
          // Unrecognized event type — mark processed so it doesn't loop forever
          await this.prisma.$executeRaw`
            UPDATE "order_outbox" SET "processedAt" = NOW() WHERE "id" = ${row.id}
          `;
          continue;
        }

        const payload =
          typeof row.payload === 'string'
            ? JSON.parse(row.payload)
            : row.payload;

        const dedupeKey = this.buildDedupeKey(row.eventType, payload);

        await this.eventsQueue.add(jobName, payload, {
          jobId: dedupeKey ?? undefined,
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        });

        await this.prisma.$executeRaw`
          UPDATE "order_outbox"
          SET "processedAt" = NOW()
          WHERE "id" = ${row.id}
        `;
        count++;
      }

      if (count > 0) {
        this.logger.log(`Outbox: swept and relayed ${count} pending events`);
      }

      return { relayed: count };
    } catch (err) {
      this.logger.error(
        `Failed to relay pending outbox events: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      return { relayed: 0 };
    }
  }

  /**
   * When an in-memory event listener successfully enqueues the job, mark the
   * corresponding outbox row processed so the background poller skips it.
   */
  async markProcessed(orderId: string, revision: number): Promise<void> {
    try {
      await this.prisma.$executeRaw`
        UPDATE "order_outbox"
        SET "processedAt" = NOW()
        WHERE "orderId" = ${orderId}
          AND "revision" = ${revision}
          AND "processedAt" IS NULL
      `;
    } catch {
      // Non-fatal: if this write fails, BullMQ deduplication will drop the replay.
    }
  }

  private mapEventTypeToJobName(eventType: string): string | null {
    switch (eventType) {
      case EVENTS.ORDER_CREATED:
        return EVENT_JOBS.ORDER_CREATED;
      case EVENTS.ORDER_STATUS_CHANGED:
        return EVENT_JOBS.ORDER_STATUS_CHANGED;
      case EVENTS.ORDER_CANCELLED:
        return EVENT_JOBS.ORDER_CANCELLED;
      default:
        return null;
    }
  }

  private buildDedupeKey(eventType: string, payload: any): string | null {
    if (!payload?.orderId) return null;
    if (eventType === EVENTS.ORDER_STATUS_CHANGED) {
      return payload.dedupeKey
        ? `notify:order_status:${payload.orderId}:${payload.revision}:${payload.dedupeKey}`
        : `notify:order_status:${payload.orderId}:${payload.revision}`;
    }
    if (eventType === EVENTS.ORDER_CREATED) {
      return `notify:order_created:${payload.orderId}`;
    }
    if (eventType === EVENTS.ORDER_CANCELLED) {
      return `notify:order_cancelled:${payload.orderId}:${payload.revision ?? 0}`;
    }
    return null;
  }
}
