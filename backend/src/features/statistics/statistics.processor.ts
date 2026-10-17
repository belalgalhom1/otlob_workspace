import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job, UnrecoverableError } from 'bullmq';
import { Logger } from '@nestjs/common';
import { StatisticPeriod } from '@prisma/client';
import { StatisticsRepository } from './statistics.repository';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { QUEUES, STATS_JOBS } from '../../infrastructure/queue/queues.constants';

interface SerializedPeriod {
  period: string;
  startDate: string;
  endDate: string;
}

@Processor(QUEUES.STATS, { concurrency: 5 })
export class StatisticsProcessor extends WorkerHost {
  private readonly logger = new Logger(StatisticsProcessor.name);

  constructor(
    private readonly statsRepository: StatisticsRepository,
    private readonly prisma: PrismaService,
  ) {
    super();
  }

  async process(job: Job): Promise<any> {
    this.logger.debug(`Processing stats job [${job.name}] id=${job.id}`);

    switch (job.name) {
      case STATS_JOBS.UPDATE_VENDOR:
        return this.handleUpdateVendor(job);
      case STATS_JOBS.UPDATE_DRIVER:
        return this.handleUpdateDriver(job);
      case STATS_JOBS.UPDATE_APP:
        return this.handleUpdateApp(job);
      default:
        throw new UnrecoverableError(`Unknown stats job: ${job.name}`);
    }
  }

  private async handleUpdateVendor(
    job: Job<{
      sourceKey: string;
      vendorId: string;
      increment: Record<string, number>;
      periods?: SerializedPeriod[];
    }>,
  ) {
    this.logger.debug(`Vendor stat update for ${job.data.vendorId}`);
    const periods = this.resolvePeriods(job.data.periods);
    // Idempotency claim + `+=` upserts commit in the SAME transaction, so a
    // re-delivered job (stalled worker, manual retry) skips instead of
    // double-counting. The claim row decides the winner atomically.
    await this.prisma.$transaction(async (tx) => {
      const claimed = await this.statsRepository.claimProcessingMarker(
        job.data.sourceKey,
        tx,
      );
      if (!claimed) {
        this.logger.debug(
          `Skipping vendor stats ${job.data.vendorId}: ${job.data.sourceKey} already processed.`,
        );
        return;
      }
      for (const { period, startDate, endDate } of periods) {
        await this.statsRepository.upsertVendorStat(
          job.data.vendorId,
          period,
          startDate,
          endDate,
          job.data.increment,
          tx,
        );
      }
    });
    return { ok: true };
  }

  private async handleUpdateDriver(
    job: Job<{
      sourceKey: string;
      driverId: string;
      increment: Record<string, number>;
      periods?: SerializedPeriod[];
    }>,
  ) {
    this.logger.debug(`Driver stat update for ${job.data.driverId}`);
    const periods = this.resolvePeriods(job.data.periods);
    await this.prisma.$transaction(async (tx) => {
      const claimed = await this.statsRepository.claimProcessingMarker(
        job.data.sourceKey,
        tx,
      );
      if (!claimed) {
        this.logger.debug(
          `Skipping driver stats ${job.data.driverId}: ${job.data.sourceKey} already processed.`,
        );
        return;
      }
      for (const { period, startDate, endDate } of periods) {
        await this.statsRepository.upsertDriverStat(
          job.data.driverId,
          period,
          startDate,
          endDate,
          job.data.increment,
          tx,
        );
      }
    });
    return { ok: true };
  }

  private async handleUpdateApp(
    job: Job<{
      sourceKey: string;
      increment: Record<string, number>;
      periods?: SerializedPeriod[];
    }>,
  ) {
    this.logger.debug('App stat update');
    const periods = this.resolvePeriods(job.data.periods);
    await this.prisma.$transaction(async (tx) => {
      const claimed = await this.statsRepository.claimProcessingMarker(
        job.data.sourceKey,
        tx,
      );
      if (!claimed) {
        this.logger.debug(
          `Skipping app stats: ${job.data.sourceKey} already processed.`,
        );
        return;
      }
      for (const { period, startDate, endDate } of periods) {
        await this.statsRepository.upsertAppStat(
          period,
          startDate,
          endDate,
          job.data.increment,
          tx,
        );
      }
    });
    return { ok: true };
  }

  /** Prefer event-time period buckets from the job payload; fall back to now. */
  private resolvePeriods(periods?: SerializedPeriod[]) {
    if (periods && periods.length > 0) {
      return periods.map((p) => ({
        period: p.period as StatisticPeriod,
        startDate: new Date(p.startDate),
        endDate: new Date(p.endDate),
      }));
    }
    return this.statsRepository.getPeriodsForDate(new Date());
  }
}
