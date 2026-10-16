import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue, UnrecoverableError } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { StatisticPeriod } from '@prisma/client';
import { StatisticsRepository } from './statistics.repository';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import {
  QUEUES,
  STATS_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';

interface SerializedPeriod {
  period: string;
  startDate: string;
  endDate: string;
}

@Processor(QUEUES.STATS, { concurrency: 5 })
export class StatisticsProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(StatisticsProcessor.name);

  constructor(
    private readonly statsRepository: StatisticsRepository,
    private readonly platformSettings: PlatformSettingsService,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    @InjectQueue(QUEUES.STATS) private readonly queue: Queue,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling Statistics domain cron jobs...');
    await this.queue.add(
      CRON_JOBS.DATA_RETENTION,
      { type: 'audits' },
      {
        repeat: { pattern: '50 1 * * *' },
        jobId: 'cron.data_retention.audits',
      },
    );
    await this.queue.add(
      CRON_JOBS.DATA_RETENTION,
      { type: 'wallets' },
      {
        repeat: { pattern: '0 2 * * *' },
        jobId: 'cron.data_retention.wallets',
      },
    );
    await this.queue.add(
      CRON_JOBS.DATA_RETENTION,
      { type: 'stats' },
      { repeat: { pattern: '10 2 * * *' }, jobId: 'cron.data_retention.stats' },
    );
    await this.queue.add(
      CRON_JOBS.DATA_RETENTION,
      { type: 'payment-receipts' },
      {
        repeat: { pattern: '20 2 * * *' },
        jobId: 'cron.data_retention.payment_receipts',
      },
    );
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
      case CRON_JOBS.DATA_RETENTION:
        switch (job.data.type) {
          case 'audits':
            return this.handleAuditLogsCleanup();
          case 'wallets':
            return this.handleWalletTransactionsCleanup();
          case 'stats':
            return this.handleStatisticsCleanup();
          case 'payment-receipts':
            return this.handlePaymentReceiptsCleanup();
          default:
            return { skipped: true };
        }
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

  // ─── CRON jobs ────────────────────────────────────────────────────────────

  private async handleAuditLogsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionAuditLogsDays * 24 * 60 * 60 * 1000,
      );

      const result = await this.prisma.auditLog.deleteMany({
        where: { createdAt: { lt: cutoff } },
      });

      if (result.count > 0) {
        this.logger.log(`🗑️  Hard-deleted ${result.count} old audit logs`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run audit logs cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handleWalletTransactionsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() -
          settings.retentionWalletTransactionsDays * 24 * 60 * 60 * 1000,
      );

      const p1 = this.prisma.vendorWalletTransaction.deleteMany({
        where: { createdAt: { lt: cutoff } },
      });
      const p2 = this.prisma.driverWalletTransaction.deleteMany({
        where: { createdAt: { lt: cutoff } },
      });

      const [r1, r2] = await Promise.all([p1, p2]);
      const total = r1.count + r2.count;

      if (total > 0) {
        this.logger.log(`🗑️  Hard-deleted ${total} old wallet transactions`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run wallet transactions cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handleStatisticsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionStatisticsDays * 24 * 60 * 60 * 1000,
      );

      const p1 = this.prisma.vendorStatistic.deleteMany({
        where: { endDate: { lt: cutoff } },
      });
      const p2 = this.prisma.driverStatistic.deleteMany({
        where: { endDate: { lt: cutoff } },
      });
      const p3 = this.prisma.appStatistic.deleteMany({
        where: { endDate: { lt: cutoff } },
      });
      // Idempotency markers only need to outlive any possible job re-delivery;
      // purge them once they've lived as long as the stats they guard.
      const p4 = this.statsRepository.purgeProcessingMarkers(cutoff);

      const [r1, r2, r3, r4] = await Promise.all([p1, p2, p3, p4]);
      const total = r1.count + r2.count + r3.count + r4;

      if (total > 0) {
        this.logger.log(
          `🗑️  Hard-deleted ${r1.count + r2.count + r3.count} old statistics records and ${r4} idempotency markers`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to run statistics cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handlePaymentReceiptsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() -
          settings.retentionPaymentReceiptsDays * 24 * 60 * 60 * 1000,
      );

      // Privacy-first file hygiene, not row deletion: the order row (and its
      // wallet/coin ledger) survives for accounting — only the sensitive
      // transfer screenshot leaves disk. Only settled orders qualify, so a
      // live PENDING_PAYMENT dispute never loses its evidence. updatedAt
      // (not createdAt) gates it: an order still moving keeps its receipt.
      let cleared = 0;
      for (;;) {
        const batch = await this.prisma.order.findMany({
          where: {
            paymentReceiptUrl: { not: null },
            status: { in: ['DELIVERED', 'CANCELLED'] },
            updatedAt: { lt: cutoff },
          },
          select: { id: true, paymentReceiptUrl: true },
          take: 200,
        });
        if (batch.length === 0) break;

        for (const order of batch) {
          const url = order.paymentReceiptUrl as string | null;
          if (!url) continue;
          // Conditional clear: a concurrent re-pay swaps the URL, and we
          // must never wipe the fresh receipt.
          const clearedRow = await this.prisma.order.updateMany({
            where: { id: order.id, paymentReceiptUrl: url },
            data: { paymentReceiptUrl: null },
          });
          if (clearedRow.count === 0) continue;
          // Idempotent + traversal-guarded; never throws.
          await this.storage.delete(url);
          cleared += 1;
        }

        if (batch.length < 200) break;
      }

      if (cleared > 0) {
        this.logger.log(`🗑️  Cleared ${cleared} old payment receipts`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run payment receipts cleanup',
        (error as Error).stack,
      );
    }
  }
}
