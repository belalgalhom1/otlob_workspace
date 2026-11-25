import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { StatisticsRepository } from '../statistics/statistics.repository';
import { QUEUES, CRON_JOBS } from '../../infrastructure/queue/queues.constants';

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
  { type: 'outbox', pattern: '50 2 * * *' },
];

const retentionJobId = (type: string) =>
  `cron.data_retention.${type.replace(/-/g, '_')}`;

type OrderMediaTargetKey =
  | 'orderPaymentReceipt'
  | 'groupPickupPhoto'
  | 'fulfillmentPickupPhoto'
  | 'groupDeliveryPhoto';

interface OrderMediaTargetConfig {
  readonly tableSql: string;
  readonly columnSql: string;
  readonly joinedOrder: boolean;
}

const ORDER_MEDIA_TARGETS: Record<OrderMediaTargetKey, OrderMediaTargetConfig> =
  {
    orderPaymentReceipt: {
      tableSql: '"orders"',
      columnSql: '"paymentReceiptUrl"',
      joinedOrder: false,
    },
    groupPickupPhoto: {
      tableSql: '"order_delivery_groups"',
      columnSql: '"pickupImageUrl"',
      joinedOrder: true,
    },
    fulfillmentPickupPhoto: {
      tableSql: '"order_vendor_fulfillments"',
      columnSql: '"pickupImageUrl"',
      joinedOrder: true,
    },
    groupDeliveryPhoto: {
      tableSql: '"order_delivery_groups"',
      columnSql: '"deliveryImageUrl"',
      joinedOrder: true,
    },
  };

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

  async process(job: Job<{ type?: string }>): Promise<unknown> {
    this.logger.debug(`Processing retention job [${job.name}] id=${job.id}`);

    if (job.name !== CRON_JOBS.DATA_RETENTION) {
      this.logger.warn(`Unknown retention job name: ${job.name}`);
      return { ignored: true, reason: 'unknown_job_name' };
    }

    switch (job.data?.type) {
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
      case 'outbox':
        return this.handleOutboxCleanup();
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

      // 1. Purge physical media files from disk for messages in stale/closed/archived conversations.
      // Use raw SQL to bypass the soft-delete filter in case conversations were already marked deletedAt != null.
      let totalFilesCleared = 0;
      let totalBytesReclaimed = 0;
      const processedConversationIds = new Set<string>();

      for (;;) {
        const batch = await this.prisma.$queryRaw<
          Array<{ id: string; mediaUrl: string; conversationId: string }>
        >`
          SELECT m."id", m."mediaUrl", m."conversationId"
          FROM "messages" m
          JOIN "conversations" c ON c."id" = m."conversationId"
          WHERE m."mediaUrl" IS NOT NULL
            AND m."mediaUrl" <> ''
            AND (c."status" IN ('ARCHIVED', 'CLOSED') OR c."deletedAt" IS NOT NULL)
            AND c."updatedAt" < ${cutoff}
          ORDER BY m."createdAt" ASC
          LIMIT 200
        `;

        if (batch.length === 0) break;

        let clearedInBatch = 0;
        for (const msg of batch) {
          const url = msg.mediaUrl;
          if (!url || typeof url !== 'string') continue;

          // Conditional clear: only delete if DB row still has this exact mediaUrl
          const clearedRow = await this.prisma.message.updateMany({
            where: { id: msg.id, mediaUrl: url },
            data: { mediaUrl: null },
          });

          if (clearedRow.count === 0) continue;

          clearedInBatch += 1;
          const bytesFreed = await this.storage.delete(url);
          totalFilesCleared += 1;
          totalBytesReclaimed += bytesFreed;
          processedConversationIds.add(msg.conversationId);
        }

        if (batch.length < 200 || clearedInBatch === 0) break;
      }

      // 2. Clean up any empty conversation subdirectories across chat media folders
      for (const convId of processedConversationIds) {
        await Promise.all([
          this.storage.deleteEmptyFolder(`chat/images/${convId}`),
          this.storage.deleteEmptyFolder(`chat/videos/${convId}`),
          this.storage.deleteEmptyFolder(`chat/audio/${convId}`),
          this.storage.deleteEmptyFolder(`chat/${convId}`),
        ]);
      }

      // 3. Soft-delete expired conversations: keep chat/wallet ledger rows for audit;
      // Prisma reads already exclude deletedAt != null.
      const result = await this.prisma.conversation.updateMany({
        where: {
          status: { in: ['ARCHIVED', 'CLOSED'] },
          updatedAt: { lt: cutoff },
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
          status: 'ARCHIVED',
        },
      });

      const reclaimedStr = this.formatBytes(totalBytesReclaimed);
      if (result.count > 0 || totalFilesCleared > 0) {
        this.logger.log(
          `🗑️  Archived ${result.count} conversations, deleted ${totalFilesCleared} chat media files (${reclaimedStr} reclaimed)`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to run archived conversations cleanup',
        (error as Error).stack,
      );
    }
  }

  private formatBytes(bytes: number): string {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
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
      // live PENDING_PAYMENT dispute never loses its evidence.
      const cleared = await this.clearMediaColumn(
        'orderPaymentReceipt',
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

  private async handleOutboxCleanup(): Promise<void> {
    try {
      const processedCutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const staleCutoff = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
      const rows = await this.prisma.$executeRaw`
        DELETE FROM "outbox"
        WHERE ("processedAt" IS NOT NULL AND "processedAt" < ${processedCutoff})
           OR ("processedAt" IS NULL AND "createdAt" < ${staleCutoff})
      `;
      if (rows > 0) {
        this.logger.log(`🗑️  Pruned ${rows} outbox records`);
      }
    } catch (error) {
      this.logger.error('Failed to run outbox cleanup', (error as Error).stack);
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
      // orders qualify and a live order never loses its proof. Pickup URLs can
      // live on both `order_delivery_groups` and `order_vendor_fulfillments`,
      // while delivery proof lives on `order_delivery_groups`.
      const deletedUrls = new Set<string>();
      const groupPickups = await this.clearMediaColumn(
        'groupPickupPhoto',
        pickupCutoff,
        deletedUrls,
      );
      const fulfillmentPickups = await this.clearMediaColumn(
        'fulfillmentPickupPhoto',
        pickupCutoff,
        deletedUrls,
      );
      const delivery = await this.clearMediaColumn(
        'groupDeliveryPhoto',
        deliveryCutoff,
        deletedUrls,
      );
      const pickup = groupPickups + fulfillmentPickups;

      if (pickup + delivery > 0) {
        this.logger.log(
          `🗑️  Cleared ${pickup} pickup and ${delivery} delivery photo refs (${deletedUrls.size} files deleted)`,
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
            NOT: { startPhotoUrl: '' },
            status: { in: ['COMPLETED', 'CANCELLED', 'MISSED'] },
            endTime: { lt: cutoff },
          },
          select: { id: true, startPhotoUrl: true },
          take: 200,
        });
        if (batch.length === 0) break;

        let clearedInBatch = 0;
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
          clearedInBatch += 1;
          // Idempotent + traversal-guarded; never throws.
          await this.storage.delete(url);
          cleared += 1;
        }

        if (batch.length < 200 || clearedInBatch === 0) break;
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
   * Batch-clear a nullable media column on orders or their child execution
   * tables (`order_delivery_groups`, `order_vendor_fulfillments`) once the
   * parent order is settled and stale.
   *
   * Uses `$queryRaw` because Prisma's soft-delete extension rewrites `Order`
   * reads to `deletedAt: null`, and old settled orders are soft-deleted by
   * the orders retention job before media cleanup runs. Joins parent `orders`
   * when clearing child tables so `status` and `createdAt` remain the sole
   * source of truth, and conditionally `updateMany`s before unlinking disk
   * files so concurrent re-uploads are never deleted.
   */
  private async clearMediaColumn(
    targetKey: OrderMediaTargetKey,
    cutoff: Date,
    deletedUrls: Set<string> = new Set<string>(),
  ): Promise<number> {
    const target = ORDER_MEDIA_TARGETS[targetKey];
    const table = Prisma.raw(target.tableSql);
    const column = Prisma.raw(target.columnSql);
    let cleared = 0;

    for (;;) {
      const batch = target.joinedOrder
        ? await this.prisma.$queryRaw<
            Array<{ id: string; url: string | null }>
          >`
            SELECT t."id", t.${column} AS "url"
            FROM ${table} t
            JOIN "orders" o ON o."id" = t."orderId"
            WHERE t.${column} IS NOT NULL
              AND t.${column} <> ''
              AND o."status" IN ('DELIVERED', 'CANCELLED')
              AND o."createdAt" < ${cutoff}
            ORDER BY o."createdAt" ASC
            LIMIT 200
          `
        : await this.prisma.$queryRaw<
            Array<{ id: string; url: string | null }>
          >`
            SELECT "id", ${column} AS "url"
            FROM ${table}
            WHERE ${column} IS NOT NULL
              AND ${column} <> ''
              AND "status" IN ('DELIVERED', 'CANCELLED')
              AND "createdAt" < ${cutoff}
            ORDER BY "createdAt" ASC
            LIMIT 200
          `;
      if (batch.length === 0) break;

      let clearedInBatch = 0;
      for (const row of batch) {
        const url = row.url;
        if (typeof url !== 'string' || url.length === 0) continue;

        const clearedRow = await this.clearConditionalMediaRef(
          targetKey,
          row.id,
          url,
        );
        if (clearedRow.count === 0) continue;

        clearedInBatch += 1;
        cleared += 1;
        if (!deletedUrls.has(url)) {
          deletedUrls.add(url);
          await this.storage.delete(url);
        }
      }

      if (batch.length < 200 || clearedInBatch === 0) break;
    }

    return cleared;
  }

  private clearConditionalMediaRef(
    targetKey: OrderMediaTargetKey,
    id: string,
    url: string,
  ): Promise<{ count: number }> {
    switch (targetKey) {
      case 'orderPaymentReceipt':
        return this.prisma.order.updateMany({
          where: { id, paymentReceiptUrl: url },
          data: { paymentReceiptUrl: null },
        });
      case 'groupPickupPhoto':
        return this.prisma.orderDeliveryGroup.updateMany({
          where: { id, pickupImageUrl: url },
          data: { pickupImageUrl: null },
        });
      case 'fulfillmentPickupPhoto':
        return this.prisma.orderVendorFulfillment.updateMany({
          where: { id, pickupImageUrl: url },
          data: { pickupImageUrl: null },
        });
      case 'groupDeliveryPhoto':
        return this.prisma.orderDeliveryGroup.updateMany({
          where: { id, deliveryImageUrl: url },
          data: { deliveryImageUrl: null },
        });
    }
  }
}
