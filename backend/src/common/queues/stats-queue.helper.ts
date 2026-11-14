import { StatisticPeriod } from '@prisma/client';
import type { Queue } from 'bullmq';
import { tzDayEnd, tzDayStart, tzParts } from '../utils/timezone';

export interface StatPeriodRange {
  period: StatisticPeriod;
  startDate: Date;
  endDate: Date;
}

export interface EnqueueStatsJobParams {
  name: string;
  sourceKey: string;
  data: Record<string, unknown>;
  periods: StatPeriodRange[];
}

/**
 * Only the finest grain (DAILY) is materialized by the incremental worker;
 * WEEKLY/MONTHLY/YEARLY aggregates are rolled up from DAILY rows on read.
 */
export function getStatsPeriodsForDate(date: Date): StatPeriodRange[] {
  const p = tzParts(new Date(date));

  return [
    {
      period: StatisticPeriod.DAILY,
      startDate: tzDayStart(p.year, p.month, p.day),
      endDate: tzDayEnd(p.year, p.month, p.day),
    },
  ];
}

/**
 * Enqueue an idempotent statistics update job onto the STATS queue.
 * Exact-once semantics are enforced by the worker claiming `sourceKey` inside
 * the same transaction as the aggregate upserts.
 */
export async function enqueueStatsJob(
  statsQueue: Queue,
  params: EnqueueStatsJobParams,
): Promise<void> {
  await statsQueue.add(params.name, {
    ...params.data,
    sourceKey: params.sourceKey,
    // Serialize as ISO strings: BullMQ round-trips job.data through JSON
    // and the worker rehydrates them into Dates.
    periods: params.periods.map((p) => ({
      period: p.period,
      startDate: p.startDate.toISOString(),
      endDate: p.endDate.toISOString(),
    })),
  });
}
