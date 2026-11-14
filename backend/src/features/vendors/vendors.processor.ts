import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger, OnModuleInit, Optional } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { QUEUES, CRON_JOBS } from '../../infrastructure/queue/queues.constants';
import { Prisma, VendorStatus } from '@prisma/client';
import { VendorCacheService } from './helpers/vendor-cache.service';
import { isVendorScheduleOpen } from './helpers/vendor-schedule.helper';

@Processor(QUEUES.VENDORS, { concurrency: 5 })
export class VendorsProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(VendorsProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(QUEUES.VENDORS) private readonly queue: Queue,
    @Optional() private readonly vendorCache?: VendorCacheService,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling Vendors domain cron jobs...');
    await this.queue.add(
      CRON_JOBS.VENDOR_SCHEDULE,
      {},
      { repeat: { pattern: '*/5 * * * *' }, jobId: CRON_JOBS.VENDOR_SCHEDULE },
    );
  }

  async process(job: Job): Promise<any> {
    switch (job.name) {
      case CRON_JOBS.VENDOR_SCHEDULE:
        return this.handleVendorWorkingHours();
      default:
        this.logger.warn(`Unknown vendor job: ${job.name}`);
    }
  }

  private async handleVendorWorkingHours(): Promise<void> {
    try {
      const vendors = await this.prisma.vendor.findMany({
        where: {
          isScheduleActive: true,
          deletedAt: null,
          status: { in: [VendorStatus.OPEN, VendorStatus.CLOSED] },
          workingHours: { not: Prisma.DbNull },
        },
        select: { id: true, status: true, workingHours: true },
      });

      let opened = 0;
      let closed = 0;

      const toOpenIds: string[] = [];
      const toCloseIds: string[] = [];

      for (const vendor of vendors) {
        const shouldBeOpen = isVendorScheduleOpen(vendor.workingHours);

        if (shouldBeOpen && vendor.status === VendorStatus.CLOSED) {
          toOpenIds.push(vendor.id);
          opened++;
        } else if (!shouldBeOpen && vendor.status === VendorStatus.OPEN) {
          toCloseIds.push(vendor.id);
          closed++;
        }
      }

      if (toOpenIds.length > 0) {
        await this.prisma.vendor.updateMany({
          where: { id: { in: toOpenIds } },
          data: { status: VendorStatus.OPEN },
        });
      }

      if (toCloseIds.length > 0) {
        await this.prisma.vendor.updateMany({
          where: { id: { in: toCloseIds } },
          data: { status: VendorStatus.CLOSED },
        });
      }

      if (toOpenIds.length > 0 || toCloseIds.length > 0) {
        await this.vendorCache?.invalidateManyVendorDetails([
          ...toOpenIds,
          ...toCloseIds,
        ]);
      }

      if (opened > 0 || closed > 0) {
        this.logger.log(
          `🏪 Vendor schedule: ${opened} opened, ${closed} closed`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to process vendor working hours',
        (error as Error).stack,
      );
    }
  }
}
