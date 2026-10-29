import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  QUEUES,
  REVIEW_JOBS,
} from '../../infrastructure/queue/queues.constants';

@Processor(QUEUES.REVIEWS, { concurrency: 5 })
export class ReviewsProcessor extends WorkerHost {
  private readonly logger = new Logger(ReviewsProcessor.name);

  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    this.logger.debug(`Processing reviews job ${job.name} (id: ${job.id})`);

    switch (job.name) {
      case REVIEW_JOBS.UPDATE_RATINGS:
        return this.handleUpdateRatings(job);
      default:
        this.logger.warn(`Unknown job name: ${job.name}`);
        return { ignored: true, reason: 'unknown_job_name' };
    }
  }

  /**
   * Recomputed SET (idempotent) — safe to retry. Ratings are derived from the
   * full aggregate over all reviews, so repeated runs converge to the same value.
   */
  private async handleUpdateRatings(
    job: Job<{ vendorId: string | null; driverId: string | null }>,
  ) {
    const { vendorId, driverId } = job.data;

    if (vendorId) {
      const agg = await this.prisma.orderReview.aggregate({
        where: {
          OR: [
            { vendorId },
            {
              order: {
                vendorFulfillments: {
                  some: { vendorId },
                },
              },
            },
          ],
          vendorRating: { not: null },
        },
        _avg: { vendorRating: true },
        _count: { _all: true },
      });

      await this.prisma.vendor.update({
        where: { id: vendorId },
        data: {
          rating: agg._avg.vendorRating || 0,
          ratingCount: agg._count._all,
        },
      });

      this.logger.log(
        `Vendor ${vendorId} rating updated: ${agg._avg.vendorRating} (${agg._count._all} reviews)`,
      );
    }

    if (driverId) {
      const agg = await this.prisma.orderReview.aggregate({
        where: {
          OR: [
            { driverId },
            {
              order: {
                deliveryGroups: {
                  some: { primaryDriverId: driverId },
                },
              },
            },
          ],
          driverRating: { not: null },
        },
        _avg: { driverRating: true },
        _count: { _all: true },
      });

      const convertedRating = agg._avg.driverRating
        ? Math.round(agg._avg.driverRating * 100)
        : 500;

      // Keep the tier in sync with the rolling customer rating. New drivers
      // start on SILVER; a strong record promotes to GOLD, a poor one drops
      // to BRONZE (which also reduces the delivery fee by 2).
      const newTier =
        agg._count._all === 0
          ? 'SILVER'
          : convertedRating >= 450
            ? 'GOLD'
            : convertedRating >= 400
              ? 'SILVER'
              : 'BRONZE';

      await this.prisma.driver.update({
        where: { id: driverId },
        data: {
          rating: convertedRating,
          ratingCount: agg._count._all,
          tier: newTier,
        },
      });

      this.logger.log(
        `Driver ${driverId} rating updated: ${convertedRating} (${agg._count._all} reviews)`,
      );
    }

    return { updated: true };
  }
}
