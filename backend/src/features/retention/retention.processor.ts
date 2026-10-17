import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { StatisticsRepository } from '../statistics/statistics.repository';
import {
  QUEUES,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';

/**
 * Every scheduled data-retention / cleanup task lives here, on its own queue,
 * so hygiene is owned by one worker instead of being scattered across the
 * domain processors it happens to touch (statistics, orders). Each task is a
 * `cron.data_retention` job discriminated by `job.data.type`.
 */
const RETENTION_SCHEDULE: ReadonlyArray<{ type: string; pattern: string }> = [
  { type: 'orders', pattern: '0 1 * * *' },
  { type: 'chats', pattern: '10 1 * * *' },
  { type: 'notifications', pattern: '20 1 * * *' },
  { type: 'sessions', pattern: '30 1 * * *' },
  { type: 'carts', pattern: '40 1 * * *' },
  { type: 'audits', pattern: '50 1 * * *' },
  { type: 'wallets', pattern: '0 2 * * *' },
  { type: 'stats', pattern: '10 2 * * *' },
  { type: 'payment-receipts', pattern: '20 2 * * *' },
  { type: 'shift-start-photos', pattern: '30 2 * * *' },
  { type: 'order-photos', pattern: '40 2 * * *' },
];

const retentionJobId = (type: string) =>
  `cron.data_retention.${type.replace(/-/g, '_')}`;

@Processor(QUEUES.RETENTION, { concurrency: 5 })
export class RetentionProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(RetentionProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly storage: StorageService,
    private readonly statsRepository: StatisticsRepository,
    @InjectQueue(QUEUES.RETENTION) private readonly queue: Queue,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling Data-retention domain cron jobs...');

    for (const { type, pattern } of RETENTION_SCHEDULE) {
      await this.queue.add(
        CRON_JOBS.DATA_RETENTION,
        { type },
        { repeat: { pattern }, jobId: retentionJobId(type) },
      );
    }
  }

  async process(job: Job): Promise<any> {
    this.logger.debug(`Processing retention job [${job.name}] id=${job.id}`);

    if (job.name !== CRON_JOBS.DATA_RETENTION) {
      this.logger.warn(`Unknown retention job name: ${job.name}`);
      return { ignored: true, reason: 'unknown_job_name' };
    }

    switch (job.data.type) {
      case 'orders':
        return this.handleOrdersCleanup();
      case 'chats':
        return this.handleArchivedConversationsCleanup();
      case 'notifications':
        return this.handleNotificationsCleanup();
      case 'sessions':
        return this.handleExpiredSessionsCleanup();
      case 'carts':
        return this.handleAbandonedCartsCleanup();
      case 'audits':
        return this.handleAuditLogsCleanup();
      case 'wallets':
        return this.handleWalletTransactionsCleanup();
      case 'stats':
        return this.handleStatisticsCleanup();
      case 'payment-receipts':
        return this.handlePaymentReceiptsCleanup();
      case 'shift-start-photos':
        return this.handleShiftStartPhotosCleanup();
      case 'order-photos':
        return this.handleOrderPhotosCleanup();
      default:
        return { skipped: true };
    }
  }

  // ─── Orders, chats, sessions & carts ──────────────────────────────────────

  private async handleOrdersCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionOrdersDays * 24 * 60 * 60 * 1000,
      );

      // Soft-delete: order rows (and their wallet/coin ledger, items and
      // conversations) must survive for accounting. Prisma reads already
      // exclude deletedAt != null.
      const result = await this.prisma.order.updateMany({
        where: {
          status: { in: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
          updatedAt: { lt: cutoff },
          deletedAt: null,
        },
        data: { deletedAt: new Date() },
      });

      if (result.count > 0) {
        this.logger.log(`🗑️  Soft-deleted ${result.count} old orders`);
      }
    } catch (error) {
      this.logger.error('Failed to run orders cleanup', (error as Error).stack);
    }
  }

  private async handleArchivedConversationsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionArchivedChatsDays * 24 * 60 * 60 * 1000,
      );

      // Soft-delete: keep chat/wallet ledger rows for audit; Prisma reads
      // already exclude deletedAt != null.
      const result = await this.prisma.conversation.updateMany({
        where: {
          status: 'ARCHIVED',
          updatedAt: { lt: cutoff },
          deletedAt: null,
        },
        data: { deletedAt: new Date() },
      });

      if (result.count > 0) {
        this.logger.log(
          `🗑️  Soft-deleted ${result.count} archived conversations`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to run archived conversations cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handleExpiredSessionsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() -
          settings.retentionExpiredSessionsDays * 24 * 60 * 60 * 1000,
      );

      const result = await this.prisma.session.deleteMany({
        where: {
          expiresAt: { lt: cutoff },
        },
      });

      if (result.count > 0) {
        this.logger.log(`🗑️  Hard-deleted ${result.count} expired sessions`);
      }

      // Clean up dead/inactive devices older than 90 days
      const deviceCutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      const deadDevices = await this.prisma.device.deleteMany({
        where: {
          lastActive: { lt: deviceCutoff },
        },
      });

      if (deadDevices.count > 0) {
        this.logger.log(
          `🗑️  Cleaned up ${deadDevices.count} inactive device tokens`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to run expired sessions and devices cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handleAbandonedCartsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionAbandonedCartsDays * 24 * 60 * 60 * 1000,
      );

      const result = await this.prisma.cart.deleteMany({
        where: {
          updatedAt: { lt: cutoff },
        },
      });

      if (result.count > 0) {
        this.logger.log(`🗑️  Hard-deleted ${result.count} abandoned carts`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run abandoned carts cleanup',
        (error as Error).stack,
      );
    }
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  private async handleNotificationsCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() - settings.retentionNotificationsDays * 24 * 60 * 60 * 1000,
      );

      // Hard-delete: notifications are per-user UI records, not ledger data;
      // users can already clear their own read ones on demand.
      const result = await this.prisma.notification.deleteMany({
        where: { createdAt: { lt: cutoff } },
      });

      if (result.count > 0) {
        this.logger.log(`🗑️  Hard-deleted ${result.count} old notifications`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run notifications cleanup',
        (error as Error).stack,
      );
    }
  }

  // ─── Audit logs, wallets, statistics ──────────────────────────────────────

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

  // ─── Media / file hygiene ─────────────────────────────────────────────────

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
      const cleared = await this.clearOrderMediaUrls(
        'paymentReceiptUrl',
        cutoff,
      );

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

  private async handleOrderPhotosCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const dayMs = 24 * 60 * 60 * 1000;
      const pickupCutoff = new Date(
        Date.now() - settings.retentionPickupPhotosDays * dayMs,
      );
      const deliveryCutoff = new Date(
        Date.now() - settings.retentionDeliveryPhotosDays * dayMs,
      );

      // Pickup/delivery proof photos are dispute evidence, so only settled
      // orders qualify and a live order never loses its proof. As with
      // receipts, the order row and its money ledger are kept — only the image
      // leaves disk, and updatedAt keeps a still-moving order's photos.
      const pickup = await this.clearOrderMediaUrls(
        'pickupImageUrl',
        pickupCutoff,
      );
      const delivery = await this.clearOrderMediaUrls(
        'deliveryImageUrl',
        deliveryCutoff,
      );

      if (pickup + delivery > 0) {
        this.logger.log(
          `🗑️  Cleared ${pickup} pickup and ${delivery} delivery photos`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to run order photos cleanup',
        (error as Error).stack,
      );
    }
  }

  private async handleShiftStartPhotosCleanup(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      const cutoff = new Date(
        Date.now() -
          settings.retentionShiftStartPhotosDays * 24 * 60 * 60 * 1000,
      );

      // The start photo is the driver's selfie taken when the shift begins.
      // Only ended shifts qualify (COMPLETED / CANCELLED / MISSED); the shift
      // row, its earnings and its deliveries are kept. endTime (not createdAt)
      // gates it: a still-running shift keeps its photo.
      let cleared = 0;
      for (;;) {
        const batch = await this.prisma.driverShift.findMany({
          where: {
            startPhotoUrl: { not: null },
            status: { in: ['COMPLETED', 'CANCELLED', 'MISSED'] },
            endTime: { lt: cutoff },
          },
          select: { id: true, startPhotoUrl: true },
          take: 200,
        });
        if (batch.length === 0) break;

        for (const shift of batch) {
          const url = shift.startPhotoUrl;
          if (!url) continue;
          // Conditional clear: a concurrent re-upload swaps the URL, and we
          // must never wipe the fresh photo.
          const clearedRow = await this.prisma.driverShift.updateMany({
            where: { id: shift.id, startPhotoUrl: url },
            data: { startPhotoUrl: null },
          });
          if (clearedRow.count === 0) continue;
          // Idempotent + traversal-guarded; never throws.
          await this.storage.delete(url);
          cleared += 1;
        }

        if (batch.length < 200) break;
      }

      if (cleared > 0) {
        this.logger.log(`🗑️  Cleared ${cleared} old shift start photos`);
      }
    } catch (error) {
      this.logger.error(
        'Failed to run shift start photos cleanup',
        (error as Error).stack,
      );
    }
  }

  /**
   * Batch-clear a nullable order image column once the order is settled and
   * stale. The URL is cleared conditionally (a concurrent re-upload swaps it,
   * and must never be wiped), then the file is deleted from disk. The order
   * row itself is always kept.
   *
   * Deliberately reads with `$queryRaw`: Prisma's soft-delete extension
   * rewrites every Order `findMany` to `deletedAt: null`, and the orders
   * retention job soft-deletes old settled orders (which also bumps their
   * `updatedAt`) before these media jobs run — so an ORM read would hide
   * exactly the rows we are meant to scrub. `createdAt` is the only monotonic
   * clock that survives both the rewrite and the soft-delete; the settled
   * status filter still guarantees a live order never loses its evidence.
   * Covered by the orders (status, createdAt) index.
   */
  private async clearOrderMediaUrls(
    field: 'paymentReceiptUrl' | 'pickupImageUrl' | 'deliveryImageUrl',
    cutoff: Date,
  ): Promise<number> {
    // Identifier is a fixed union member, never user input — safe to inline.
    const column = Prisma.raw(`"${field}"`);
    let cleared = 0;
    for (;;) {
      const batch = await this.prisma.$queryRaw<
        Array<{ id: string; url: string | null }>
      >`
        SELECT "id", ${column} AS "url"
        FROM "orders"
        WHERE ${column} IS NOT NULL
          AND "status" IN ('DELIVERED', 'CANCELLED')
          AND "createdAt" < ${cutoff}
        ORDER BY "createdAt" ASC
        LIMIT 200
      `;
      if (batch.length === 0) break;

      for (const order of batch) {
        const url = order.url;
        if (typeof url !== 'string' || url.length === 0) continue;
        const clearedRow = await this.prisma.order.updateMany({
          where: { id: order.id, [field]: url } as any,
          data: { [field]: null } as any,
        });
        if (clearedRow.count === 0) continue;
        await this.storage.delete(url);
        cleared += 1;
      }

      if (batch.length < 200) break;
    }
    return cleared;
  }
}
