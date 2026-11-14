import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { CommonErrors } from '../../common/constants/response.constants';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  StatisticPeriod,
  DriverStatus,
  Role,
} from '@prisma/client';
import { DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  QUEUES,
  STATS_JOBS,
} from '../../infrastructure/queue/queues.constants';
import {
  StatisticsRepository,
  type StatPeriodRange,
  type VendorProductSalesOptions,
} from './statistics.repository';
import { StatisticsAnalyticsRepository } from './statistics-analytics.repository';
import { enqueueStatsJob } from '../../common/queues/stats-queue.helper';

export type { StatPeriodRange, VendorProductSalesOptions };

@Injectable()
export class StatisticsService {
  private readonly logger = new Logger(StatisticsService.name);

  constructor(
    private readonly statsRepository: StatisticsRepository,
    private readonly analyticsRepository: StatisticsAnalyticsRepository,
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    @InjectQueue(QUEUES.STATS) private readonly statsQueue: Queue,
  ) {}

  // ─── Record cancelled order ───────────────────────────────────────────────

  async recordCancellation(
    orderId: string,
    vendorId: string | null,
    driverId: string | null,
  ): Promise<void> {
    const periods = this.statsRepository.getPeriodsForDate(new Date());

    await Promise.all([
      enqueueStatsJob(this.statsQueue, {
        name: STATS_JOBS.UPDATE_APP,
        sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_APP}`,
        data: { increment: { totalOrders: 1 } },
        periods,
      }),
      ...(vendorId
        ? [
            enqueueStatsJob(this.statsQueue, {
              name: STATS_JOBS.UPDATE_VENDOR,
              sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_VENDOR}`,
              data: {
                vendorId,
                increment: { totalOrders: 1, cancelledOrders: 1 },
              },
              periods,
            }),
          ]
        : []),
      ...(driverId
        ? [
            enqueueStatsJob(this.statsQueue, {
              name: STATS_JOBS.UPDATE_DRIVER,
              sourceKey: `cancel:${orderId}:${STATS_JOBS.UPDATE_DRIVER}`,
              data: {
                driverId,
                increment: { totalOrders: 1, cancelledOrders: 1 },
              },
              periods,
            }),
          ]
        : []),
    ]).catch((err: unknown) =>
      this.logger.error(
        `Failed to record cancellation stats: ${err instanceof Error ? err.message : String(err)}`,
      ),
    );
  }

  // ─── Dispatch counters ────────────────────────────────────────────────────

  async recordDispatchSent(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await enqueueStatsJob(this.statsQueue, {
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-sent:${dispatchId}:${driverId}`,
      data: { driverId, increment: { totalDispatchesReceived: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchAccepted(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await enqueueStatsJob(this.statsQueue, {
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-accepted:${dispatchId}`,
      data: { driverId, increment: { dispatchesAccepted: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchRejected(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await enqueueStatsJob(this.statsQueue, {
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-rejected:${dispatchId}:${driverId}`,
      data: { driverId, increment: { dispatchesRejected: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  async recordDispatchExpired(
    dispatchId: string,
    driverId: string,
  ): Promise<void> {
    await enqueueStatsJob(this.statsQueue, {
      name: STATS_JOBS.UPDATE_DRIVER,
      sourceKey: `dispatch-expired:${dispatchId}:${driverId}`,
      data: { driverId, increment: { dispatchesExpired: 1 } },
      periods: this.statsRepository.getPeriodsForDate(new Date()),
    });
  }

  // ─── Online hours ─────────────────────────────────────────────────────────

  // Statuses that count as "on the clock".
  private static readonly ONLINE_STATUSES = new Set<DriverStatus>([
    DriverStatus.ONLINE,
    DriverStatus.BUSY,
    DriverStatus.ON_DELIVERY,
  ]);

  // Online-session start key lives in Redis so the tracker is accurate even
  // with multiple API/worker instances (PM2 cluster mode) sharing one store.
  private static readonly ONLINE_SINCE_KEY_PREFIX = 'stats:onlineSince:';
  // Safety TTL: a stale key (e.g. missed offline event or process restart)
  // self-cleans, while a real shift far exceeds this duration anyway.
  private static readonly ONLINE_SINCE_TTL_SECONDS = 7 * 24 * 60 * 60;

  @OnEvent(EVENTS.DRIVER_STATUS_CHANGED)
  async handleDriverStatusChanged(event: DriverStatusChangedEvent) {
    const wasOnline = StatisticsService.ONLINE_STATUSES.has(
      event.oldStatus as DriverStatus,
    );
    const isOnline = StatisticsService.ONLINE_STATUSES.has(
      event.newStatus as DriverStatus,
    );

    const key = `${StatisticsService.ONLINE_SINCE_KEY_PREFIX}${event.driverId}`;

    if (!wasOnline && isOnline) {
      await this.redisService
        .set(
          key,
          String(Date.now()),
          StatisticsService.ONLINE_SINCE_TTL_SECONDS,
        )
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record online-session start for driver ${event.driverId}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
      return;
    }

    if (wasOnline && !isOnline) {
      const startedAtMs = await this.redisService.getdel(key);
      if (!startedAtMs) {
        this.logger.warn(
          `Online-session start missing for driver ${event.driverId} (${event.oldStatus} → ${event.newStatus}); skipping onlineHours accrual.`,
        );
        return;
      }

      const hours = Math.max(0, (Date.now() - Number(startedAtMs)) / 3_600_000);
      if (hours <= 0) return;

      const periods = this.statsRepository.getPeriodsForDate(
        new Date(Number(startedAtMs)),
      );
      await enqueueStatsJob(this.statsQueue, {
        name: STATS_JOBS.UPDATE_DRIVER,
        sourceKey: `online:${event.driverId}:${startedAtMs}`,
        data: {
          driverId: event.driverId,
          increment: { onlineHours: Math.round(hours * 100) / 100 },
        },
        periods,
      }).catch((err: unknown) =>
        this.logger.error(
          `Failed to record online hours for driver ${event.driverId}: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
    }
  }

  // ─── Read stats ───────────────────────────────────────────────────────────

  async getVendorStats(
    vendorId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    return this.analyticsRepository.getVendorStats(
      vendorId,
      period,
      limit,
      from,
      to,
    );
  }

  async getDriverStats(
    driverId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      const managed = await this.resolveManagedDriverIds(actor);
      if (!managed || !managed.includes(driverId)) {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
    }
    return this.analyticsRepository.getDriverStats(
      driverId,
      period,
      limit,
      from,
      to,
    );
  }

  /**
   * Statistics for every driver a manager is responsible for. A driver manager
   * is scoped to their assignments (or every driver when `manageAllDrivers`),
   * while a super admin gets the whole fleet.
   */
  async getAllManagedDriverStats(
    actor: JwtAccessPayload,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    const driverIds = await this.resolveManagedDriverIds(actor);
    return this.analyticsRepository.getManagedDriversStats(
      driverIds,
      period,
      limit,
      from,
      to,
    );
  }

  private async resolveManagedDriverIds(
    actor: JwtAccessPayload,
  ): Promise<string[] | null> {
    if (actor.role === Role.SUPER_ADMIN) return null;

    const manager = await this.prisma.driverManager.findUnique({
      where: { userId: actor.sub },
      select: { id: true, manageAllDrivers: true },
    });
    if (!manager) return [];

    if (manager.manageAllDrivers) {
      const drivers = await this.prisma.driver.findMany({
        where: { deletedAt: null },
        select: { id: true },
      });
      return drivers.map((d) => d.id);
    }

    const assignments = await this.prisma.driverManagerAssignment.findMany({
      where: { driverManagerId: manager.id },
      select: { driverId: true },
    });
    return assignments.map((a) => a.driverId);
  }

  async getMyDriverStats(
    userId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!driver) return [];
    return this.analyticsRepository.getDriverStats(
      driver.id,
      period,
      limit,
      from,
      to,
    );
  }

  async getAppStats(
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    return this.analyticsRepository.getAppStats(period, limit, from, to);
  }

  async getVendorProductSales(
    vendorId: string,
    opts: VendorProductSalesOptions = {},
  ) {
    return this.analyticsRepository.getVendorProductSales(vendorId, opts);
  }

  async getMostOrderedProduct(vendorId: string) {
    return this.analyticsRepository.getMostOrderedProduct(vendorId);
  }

  // ─── Analytics Leaderboards ───────────────────────────────────────────────

  async getTopDrivers(limit: number, from?: string, to?: string) {
    return this.analyticsRepository.getTopDrivers(limit, from, to);
  }

  async getTopCustomers(limit: number, from?: string, to?: string) {
    return this.analyticsRepository.getTopCustomers(limit, from, to);
  }

  async getTopVendors(limit: number, from?: string, to?: string) {
    return this.analyticsRepository.getTopVendors(limit, from, to);
  }

  async getTopProducts(limit: number, from?: string, to?: string) {
    return this.analyticsRepository.getTopProducts(limit, from, to);
  }
}
