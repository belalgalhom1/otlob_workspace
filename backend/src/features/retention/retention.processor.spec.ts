import { Job, Queue } from 'bullmq';
import { RetentionProcessor } from './retention.processor';
import { CRON_JOBS } from '../../infrastructure/queue/queues.constants';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { StatisticsRepository } from '../statistics/statistics.repository';

function flattenSqlText(
  input: unknown,
  positionalValues: readonly unknown[] = [],
): string {
  if (input == null) return '';
  if (typeof input === 'string') return input;
  if (input instanceof Date) return '$DATE';
  if (typeof input === 'number' || typeof input === 'boolean') {
    return String(input);
  }
  if (Array.isArray(input)) {
    let out = '';
    for (let i = 0; i < input.length; i++) {
      out += String(input[i]);
      if (i < positionalValues.length) {
        out += flattenSqlText(positionalValues[i]);
      }
    }
    return out;
  }
  if (typeof input === 'object') {
    const obj = input as {
      strings?: readonly string[];
      values?: readonly unknown[];
      sql?: string;
    };
    if (Array.isArray(obj.strings)) {
      return flattenSqlText(obj.strings, obj.values ?? []);
    }
    if (typeof obj.sql === 'string') {
      return obj.sql;
    }
  }
  return '';
}

describe('RetentionProcessor', () => {
  function createHarness() {
    const executedSql: string[] = [];

    const prisma = {
      $queryRaw: jest.fn(),
      $executeRaw: jest.fn(),
      order: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      orderDeliveryGroup: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      orderVendorFulfillment: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };

    const platformSettings = {
      getSettings: jest.fn().mockResolvedValue({
        retentionPickupPhotosDays: 90,
        retentionDeliveryPhotosDays: 90,
        retentionPaymentReceiptsDays: 365,
      }),
    };

    const storage = {
      delete: jest.fn().mockResolvedValue(1024),
    };

    const statsRepository = {
      purgeProcessingMarkers: jest.fn().mockResolvedValue(0),
    };

    const queue = {
      add: jest.fn().mockResolvedValue(undefined),
    };

    const processor = new RetentionProcessor(
      prisma as unknown as PrismaService,
      platformSettings as unknown as PlatformSettingsService,
      storage as unknown as StorageService,
      statsRepository as unknown as StatisticsRepository,
      queue as unknown as Queue,
    );

    return {
      processor,
      prisma,
      storage,
      executedSql,
    };
  }

  it('cleans pickup & delivery proof photos from order_delivery_groups and order_vendor_fulfillments without touching invalid orders columns', async () => {
    const { processor, prisma, storage, executedSql } = createHarness();

    const sharedPickupUrl = 'pickups/shared-proof.webp';
    const partialFulfillmentPickupUrl = 'pickups/fulfillment-only.webp';
    const deliveryProofUrl = 'deliveries/proof-1.webp';

    prisma.$queryRaw.mockImplementation(
      (query: unknown, ...values: unknown[]) => {
        const sql = flattenSqlText(query, values);
        executedSql.push(sql);

        if (
          sql.includes('"order_delivery_groups"') &&
          sql.includes('"pickupImageUrl"')
        ) {
          return Promise.resolve([{ id: 'grp-1', url: sharedPickupUrl }]);
        }
        if (
          sql.includes('"order_vendor_fulfillments"') &&
          sql.includes('"pickupImageUrl"')
        ) {
          return Promise.resolve([
            { id: 'ful-1', url: sharedPickupUrl },
            { id: 'ful-2', url: partialFulfillmentPickupUrl },
          ]);
        }
        if (
          sql.includes('"order_delivery_groups"') &&
          sql.includes('"deliveryImageUrl"')
        ) {
          return Promise.resolve([{ id: 'grp-1', url: deliveryProofUrl }]);
        }
        return Promise.resolve([]);
      },
    );

    await processor.process({
      id: 'job-order-photos',
      name: CRON_JOBS.DATA_RETENTION,
      data: { type: 'order-photos' },
    } as Job<{ type?: string }>);

    expect(executedSql).toHaveLength(3);
    for (const sql of executedSql) {
      expect(sql).toContain('JOIN "orders" o ON o."id" = t."orderId"');
      expect(sql).toContain("o.\"status\" IN ('DELIVERED', 'CANCELLED')");
      expect(sql).not.toMatch(/FROM\s+"orders"\s+WHERE/i);
    }

    expect(prisma.orderDeliveryGroup.updateMany).toHaveBeenNthCalledWith(1, {
      where: { id: 'grp-1', pickupImageUrl: sharedPickupUrl },
      data: { pickupImageUrl: null },
    });
    expect(prisma.orderVendorFulfillment.updateMany).toHaveBeenNthCalledWith(
      1,
      {
        where: { id: 'ful-1', pickupImageUrl: sharedPickupUrl },
        data: { pickupImageUrl: null },
      },
    );
    expect(prisma.orderVendorFulfillment.updateMany).toHaveBeenNthCalledWith(
      2,
      {
        where: { id: 'ful-2', pickupImageUrl: partialFulfillmentPickupUrl },
        data: { pickupImageUrl: null },
      },
    );
    expect(prisma.orderDeliveryGroup.updateMany).toHaveBeenNthCalledWith(2, {
      where: { id: 'grp-1', deliveryImageUrl: deliveryProofUrl },
      data: { deliveryImageUrl: null },
    });

    // Shared pickup file between group and fulfillment is deleted once from storage.
    expect(storage.delete).toHaveBeenCalledTimes(3);
    expect(storage.delete).toHaveBeenCalledWith(sharedPickupUrl);
    expect(storage.delete).toHaveBeenCalledWith(partialFulfillmentPickupUrl);
    expect(storage.delete).toHaveBeenCalledWith(deliveryProofUrl);
  });

  it('skips storage deletion when concurrent re-upload swaps URL before updateMany', async () => {
    const { processor, prisma, storage } = createHarness();

    prisma.$queryRaw.mockImplementation(
      (query: unknown, ...values: unknown[]) => {
        const sql = flattenSqlText(query, values);
        if (
          sql.includes('"order_delivery_groups"') &&
          sql.includes('"deliveryImageUrl"')
        ) {
          return Promise.resolve([
            { id: 'grp-race', url: 'deliveries/swapped.webp' },
          ]);
        }
        return Promise.resolve([]);
      },
    );
    prisma.orderDeliveryGroup.updateMany.mockResolvedValue({ count: 0 });

    await processor.process({
      id: 'job-race',
      name: CRON_JOBS.DATA_RETENTION,
      data: { type: 'order-photos' },
    } as Job<{ type?: string }>);

    expect(storage.delete).not.toHaveBeenCalled();
  });

  it('continues clearing paymentReceiptUrl directly from orders table', async () => {
    const { processor, prisma, storage, executedSql } = createHarness();

    prisma.$queryRaw.mockImplementation(
      (query: unknown, ...values: unknown[]) => {
        const sql = flattenSqlText(query, values);
        executedSql.push(sql);
        return Promise.resolve([{ id: 'ord-rcpt-1', url: 'receipts/r1.webp' }]);
      },
    );

    await processor.process({
      id: 'job-receipts',
      name: CRON_JOBS.DATA_RETENTION,
      data: { type: 'payment-receipts' },
    } as Job<{ type?: string }>);

    expect(executedSql[0]).toContain('FROM "orders"');
    expect(executedSql[0]).toContain('"paymentReceiptUrl"');
    expect(prisma.order.updateMany).toHaveBeenCalledWith({
      where: { id: 'ord-rcpt-1', paymentReceiptUrl: 'receipts/r1.webp' },
      data: { paymentReceiptUrl: null },
    });
    expect(storage.delete).toHaveBeenCalledWith('receipts/r1.webp');
  });

  it('cleans chat media using updatedAt cutoff and cleans chat/images|videos|audio subfolders without looping on empty rows', async () => {
    const { processor, prisma, storage, executedSql } = createHarness();
    (processor as any).prisma = {
      ...prisma,
      message: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      conversation: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };
    (processor as any).platformSettings = {
      getSettings: jest.fn().mockResolvedValue({
        retentionArchivedChatsDays: 30,
      }),
    };
    storage.deleteEmptyFolder = jest.fn().mockResolvedValue(undefined);

    (processor as any).prisma.$queryRaw.mockImplementation(
      (query: unknown, ...values: unknown[]) => {
        const sql = flattenSqlText(query, values);
        executedSql.push(sql);
        return Promise.resolve([
          {
            id: 'msg-1',
            mediaUrl: '/media/chat/images/conv-1/pic.webp',
            conversationId: 'conv-1',
          },
        ]);
      },
    );

    await processor.process({
      id: 'job-chats',
      name: CRON_JOBS.DATA_RETENTION,
      data: { type: 'chats' },
    } as Job<{ type?: string }>);

    expect(executedSql[0]).toContain('c."updatedAt" <');
    expect(executedSql[0]).toContain('m."mediaUrl" <> \'\'');
    expect(storage.deleteEmptyFolder).toHaveBeenCalledWith(
      'chat/images/conv-1',
    );
    expect(storage.deleteEmptyFolder).toHaveBeenCalledWith(
      'chat/videos/conv-1',
    );
    expect(storage.deleteEmptyFolder).toHaveBeenCalledWith('chat/audio/conv-1');
  });
});
