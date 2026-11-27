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
      const branches = await this.prisma.vendorBranch.findMany({
        where: {
          isScheduleActive: true,
          vendor: {
            deletedAt: null,
            status: { in: [VendorStatus.OPEN, VendorStatus.CLOSED] },
          },
          OR: [{ is24Hours: true }, { workingHours: { not: Prisma.DbNull } }],
        },
        select: {
          id: true,
          vendorId: true,
          isOpen: true,
          is24Hours: true,
          workingHours: true,
        },
      });

      let opened = 0;
      let closed = 0;

      const toOpenIds: string[] = [];
      const toCloseIds: string[] = [];
      const affectedVendorIds = new Set<string>();

      for (const branch of branches) {
        const shouldBeOpen = branch.is24Hours
          ? true
          : isVendorScheduleOpen(branch.workingHours);

        if (shouldBeOpen && !branch.isOpen) {
          toOpenIds.push(branch.id);
          affectedVendorIds.add(branch.vendorId);
          opened++;
        } else if (!shouldBeOpen && branch.isOpen) {
          toCloseIds.push(branch.id);
          affectedVendorIds.add(branch.vendorId);
          closed++;
        }
      }

      if (toOpenIds.length > 0) {
        await this.prisma.vendorBranch.updateMany({
          where: { id: { in: toOpenIds } },
          data: { isOpen: true },
        });
      }

      if (toCloseIds.length > 0) {
        await this.prisma.vendorBranch.updateMany({
          where: { id: { in: toCloseIds } },
          data: { isOpen: false },
        });
      }

      if (affectedVendorIds.size > 0) {
        await this.vendorCache?.invalidateManyVendorDetails(
          Array.from(affectedVendorIds),
        );
      }

      if (opened > 0 || closed > 0) {
        this.logger.log(
          `🏪 Branch schedule: ${opened} opened, ${closed} closed`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to process branch working hours',
        (error as Error).stack,
      );
    }
  }
}
