import { Injectable, Logger, Optional } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { randomUUID } from 'crypto';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { QUEUES } from '../queue/queues.constants';
import { OrderWorkflowDispatcher } from '../../common/orders/order-workflow.dispatcher';

const MAX_OUTBOX_RELAY_ATTEMPTS = 10;
const OUTBOX_RETRY_KEY_PREFIX = 'otlobegy:outbox:retry:';
const OUTBOX_DLQ_KEY = 'otlobegy:outbox:dlq';
const OUTBOX_RETRY_TTL_SECS = 24 * 60 * 60;
const OUTBOX_DLQ_MAX_ENTRIES = 500;

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
    @Optional() private readonly workflowDispatcher?: OrderWorkflowDispatcher,
    @Optional() private readonly redis?: RedisService,
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
      return await this.prisma.$transaction(
        async (tx) => {
          // Fetch a wider window than batchSize so rows temporarily in
          // exponential backoff cannot cause head-of-line starvation for
          // healthy newer events behind them.
          const scanLimit = Math.max(batchSize * 2, batchSize);
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
          LIMIT ${scanLimit}
          FOR UPDATE SKIP LOCKED
        `;

          if (!rows || rows.length === 0) {
            return { relayed: 0 };
          }

          let count = 0;
          const now = Date.now();
          for (const row of rows) {
            if (count >= batchSize) break;
            try {
              if (!row.jobName) {
                await tx.$executeRaw`
                UPDATE "outbox" SET "processedAt" = NOW() WHERE "id" = ${row.id}
              `;
                continue;
              }

              const retryState = await this.readRetryState(row.id);
              if (retryState && retryState.nextRetryAt > now) {
                continue;
              }

              let payload = row.payload;
              if (typeof payload === 'string') {
                try {
                  payload = JSON.parse(payload);
                } catch {
                  this.logger.error(`Bad JSON payload in outbox row ${row.id}`);
                  await this.deadLetterRow(row, 'Malformed JSON payload');
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

              if (row.aggregateType === 'ORDER' && this.workflowDispatcher) {
                await this.workflowDispatcher.triggerForOutboxRow(
                  row.eventType,
                  payload,
                );
              }

              await tx.$executeRaw`
              UPDATE "outbox"
              SET "processedAt" = NOW()
              WHERE "id" = ${row.id}
            `;
              await this.clearRetryState(row.id);
              count++;
            } catch (rowErr) {
              const errMsg =
                rowErr instanceof Error ? rowErr.message : String(rowErr);
              const attempts = await this.recordRetryFailure(row, errMsg);
              if (attempts >= MAX_OUTBOX_RELAY_ATTEMPTS) {
                this.logger.error(
                  `Outbox row ${row.id} (${row.eventType}) exceeded ${MAX_OUTBOX_RELAY_ATTEMPTS} relay attempts; moving to DLQ and unblocking queue: ${errMsg}`,
                );
                await this.deadLetterRow(row, errMsg, attempts);
                await this.clearRetryState(row.id);
                await tx.$executeRaw`
                  UPDATE "outbox" SET "processedAt" = NOW() WHERE "id" = ${row.id}
                `;
              } else {
                this.logger.warn(
                  `Failed to relay outbox row ${row.id} (attempt ${attempts}/${MAX_OUTBOX_RELAY_ATTEMPTS}): ${errMsg}`,
                );
              }
            }
          }

          if (count > 0) {
            this.logger.log(
              `Outbox: swept and relayed ${count} pending events`,
            );
          }

          return { relayed: count };
        },
        { timeout: 30000, maxWait: 5000 },
      );
    } catch (err) {
      this.logger.error(
        `Failed to relay pending outbox events: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      return { relayed: 0 };
    }
  }

  private async readRetryState(
    rowId: string,
  ): Promise<{ attempts: number; nextRetryAt: number } | null> {
    if (!this.redis || typeof this.redis.get !== 'function') return null;
    try {
      const raw = await this.redis.get(`${OUTBOX_RETRY_KEY_PREFIX}${rowId}`);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as {
        attempts?: number;
        nextRetryAt?: number;
      };
      return {
        attempts: Number(parsed.attempts) || 0,
        nextRetryAt: Number(parsed.nextRetryAt) || 0,
      };
    } catch {
      return null;
    }
  }

  private async recordRetryFailure(
    row: { id: string; eventType: string },
    errorMessage: string,
  ): Promise<number> {
    if (!this.redis || typeof this.redis.set !== 'function') return 1;
    try {
      const prev = await this.readRetryState(row.id);
      const attempts = (prev?.attempts ?? 0) + 1;
      const delayMs = Math.min(2_000 * Math.pow(2, attempts - 1), 300_000);
      await this.redis.set(
        `${OUTBOX_RETRY_KEY_PREFIX}${row.id}`,
        JSON.stringify({
          attempts,
          nextRetryAt: Date.now() + delayMs,
          lastError: errorMessage,
        }),
        OUTBOX_RETRY_TTL_SECS,
      );
      return attempts;
    } catch {
      return 1;
    }
  }

  private async clearRetryState(rowId: string): Promise<void> {
    if (!this.redis || typeof this.redis.del !== 'function') return;
    await this.redis.del(`${OUTBOX_RETRY_KEY_PREFIX}${rowId}`).catch(() => {});
  }

  private async deadLetterRow(
    row: {
      id: string;
      aggregateType: string;
      aggregateId: string;
      version: number;
      eventType: string;
      jobName: string;
      dedupeKey: string | null;
      payload: any;
    },
    errorMessage: string,
    attempts = MAX_OUTBOX_RELAY_ATTEMPTS,
  ): Promise<void> {
    if (!this.redis || typeof this.redis.lpushTrim !== 'function') return;
    await this.redis
      .lpushTrim(
        OUTBOX_DLQ_KEY,
        JSON.stringify({
          ...row,
          attempts,
          lastError: errorMessage,
          deadLetteredAt: new Date().toISOString(),
        }),
        OUTBOX_DLQ_MAX_ENTRIES,
      )
      .catch(() => {});
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
