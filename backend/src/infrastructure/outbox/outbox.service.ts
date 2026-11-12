import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { randomUUID } from 'crypto';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { QUEUES } from '../queue/queues.constants';

export interface RecordOutboxParams<T = any> {
  aggregateType: string;
  aggregateId: string;
  version?: number;
  eventType: string;
  jobName: string;
  dedupeKey?: string | null;
  queueName?: string;
  payload: T;
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
   * distributed dual-write problem across any domain (orders, wallets, drivers, etc.).
   * Uses clock_timestamp() so createdAt reflects actual insert time, not transaction start time.
   */
  async record<T = any>(
    tx: Prisma.TransactionClient,
    params: RecordOutboxParams<T>,
  ): Promise<string> {
    const id = randomUUID();
    const version = params.version ?? 0;
    const payloadJson = JSON.stringify(params.payload);

    await tx.$executeRaw`
      INSERT INTO "outbox" (
        "id",
        "aggregateType",
        "aggregateId",
        "version",
        "eventType",
        "jobName",
        "dedupeKey",
        "queueName",
        "payload",
        "createdAt"
      )
      VALUES (
        ${id},
        ${params.aggregateType},
        ${params.aggregateId},
        ${version},
        ${params.eventType},
        ${params.jobName},
        ${params.dedupeKey ?? null},
        ${params.queueName ?? null},
        ${payloadJson}::jsonb,
        clock_timestamp()
      )
    `;

    return id;
  }

  /**
   * Sweep and publish any unprocessed outbox rows (safety net / crash recovery).
   * Generic: relies on row.jobName, row.payload, and row.dedupeKey stored at record-time.
   * Uses FOR UPDATE SKIP LOCKED to prevent concurrency bottlenecks across multiple worker replicas.
   * Uses a 2-second grace period (clock_timestamp() - INTERVAL '2 seconds') to give the
   * in-memory fast-path listener time to process the event first without racing the poller.
   */
  async relayPending(batchSize = 50): Promise<{ relayed: number }> {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const rows = await tx.$queryRaw<
          Array<{
            id: string;
            aggregateType: string;
            aggregateId: string;
            version: number;
            eventType: string;
            jobName: string;
            dedupeKey: string | null;
            queueName: string | null;
            payload: any;
          }>
        >`
          SELECT "id", "aggregateType", "aggregateId", "version", "eventType", "jobName", "dedupeKey", "queueName", "payload"
          FROM "outbox"
          WHERE "processedAt" IS NULL
            AND "createdAt" < clock_timestamp() - INTERVAL '2 seconds'
          ORDER BY "createdAt" ASC
          LIMIT ${batchSize}
          FOR UPDATE SKIP LOCKED
        `;

        if (!rows || rows.length === 0) {
          return { relayed: 0 };
        }

        let count = 0;
        for (const row of rows) {
          try {
            if (!row.jobName) {
              await tx.$executeRaw`
                UPDATE "outbox" SET "processedAt" = NOW() WHERE "id" = ${row.id}
              `;
              continue;
            }

            let payload = row.payload;
            if (typeof payload === 'string') {
              try {
                payload = JSON.parse(payload);
              } catch {
                this.logger.error(`Bad JSON payload in outbox row ${row.id}`);
                await tx.$executeRaw`
                  UPDATE "outbox" SET "processedAt" = NOW() WHERE "id" = ${row.id}
                `;
                continue;
              }
            }

            const jobId = row.dedupeKey
              ? row.dedupeKey.replace(/:/g, '_')
              : undefined;

            await this.eventsQueue.add(row.jobName, payload, {
              jobId,
              attempts: 3,
              backoff: { type: 'exponential', delay: 2_000 },
            });

            await tx.$executeRaw`
              UPDATE "outbox"
              SET "processedAt" = NOW()
              WHERE "id" = ${row.id}
            `;
            count++;
          } catch (rowErr) {
            this.logger.warn(
              `Failed to relay outbox row ${row.id}: ${
                rowErr instanceof Error ? rowErr.message : String(rowErr)
              }`,
            );
          }
        }

        if (count > 0) {
          this.logger.log(`Outbox: swept and relayed ${count} pending events`);
        }

        return { relayed: count };
      }, { timeout: 30000, maxWait: 5000 });
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
  async markProcessed(
    aggregateType: string,
    aggregateId: string,
    version?: number,
  ): Promise<void> {
    try {
      if (typeof version === 'number') {
        await this.prisma.$executeRaw`
          UPDATE "outbox"
          SET "processedAt" = NOW()
          WHERE "aggregateType" = ${aggregateType}
            AND "aggregateId" = ${aggregateId}
            AND "version" = ${version}
            AND "processedAt" IS NULL
        `;
      } else {
        await this.prisma.$executeRaw`
          UPDATE "outbox"
          SET "processedAt" = NOW()
          WHERE "aggregateType" = ${aggregateType}
            AND "aggregateId" = ${aggregateId}
            AND "processedAt" IS NULL
        `;
      }
    } catch {
      // Non-fatal: if this write fails, BullMQ deduplication will drop the replay.
    }
  }
}
