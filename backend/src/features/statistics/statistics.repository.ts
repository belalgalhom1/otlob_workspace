import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { Prisma, StatisticPeriod, VendorTransactionType } from '@prisma/client';

export interface StatPeriodRange {
  period: StatisticPeriod;
  startDate: Date;
  endDate: Date;
}

@Injectable()
export class StatisticsRepository {
  private readonly logger = new Logger(StatisticsRepository.name);

  constructor(private readonly prisma: PrismaService) {}

  // ─── Idempotency markers (DB-anchored exactly-once) ──────────────────────
  // The worker claims a sourceKey and applies the upserts in the SAME
  // transaction. Inserting the marker is atomic with the `+=` writes, so a
  // re-delivered job finds the key already present and skips — no double count.

  async claimProcessingMarker(
    sourceKey: string,
    client?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const db = client ?? this.prisma;
    const result = await db.$executeRaw`
      INSERT INTO stat_processing_markers ("sourceKey", "createdAt")
      VALUES (${sourceKey}, NOW())
      ON CONFLICT ("sourceKey") DO NOTHING
    `;
    // rowCount === 1 means our INSERT won the conflict: we own the claim.
    // rowCount === 0 means another delivery already processed this event.
    return result === 1;
  }

  async purgeProcessingMarkers(olderThan: Date): Promise<number> {
    const result = await this.prisma.statProcessingMarker.deleteMany({
      where: { createdAt: { lt: olderThan } },
    });
    return result.count;
  }

  // ─── Period helpers ───────────────────────────────────────────────────────

  // Only the finest grain (DAILY) is materialized by the incremental worker.
  // WEEKLY/MONTHLY/YEARLY are never stored: the read path re-buckets the exact
  // whole-day DAILY rows on demand. This keeps a single source of truth and
  // cuts per-event writes from 5 statements to 2 (one marker + one DAILY upsert).
  getPeriodsForDate(date: Date): StatPeriodRange[] {
    const d = new Date(date);
    const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const dayEnd = new Date(
      d.getFullYear(),
      d.getMonth(),
      d.getDate(),
      23,
      59,
      59,
      999,
    );

    return [
      { period: StatisticPeriod.DAILY, startDate: dayStart, endDate: dayEnd },
    ];
  }

  // ─── Vendor stats — atomic upsert ─────────────────────────────────────────
  // Uses INSERT … ON CONFLICT DO UPDATE to avoid race conditions

  async upsertVendorStat(
    vendorId: string,
    period: StatisticPeriod,
    startDate: Date,
    endDate: Date,
    increment: {
      totalOrders?: number;
      totalRevenue?: number;
      totalCommission?: number;
      totalTax?: number;
      completedOrders?: number;
      cancelledOrders?: number;
    },
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.prisma;
    const to = increment.totalOrders ?? 0;
    const tr = increment.totalRevenue ?? 0;
    const tc = increment.totalCommission ?? 0;
    const tt = increment.totalTax ?? 0;
    const co = increment.completedOrders ?? 0;
    const ca = increment.cancelledOrders ?? 0;

    await db.$executeRaw`
      INSERT INTO vendor_statistics (
        id, "vendorId", period, "startDate", "endDate",
        "totalOrders", "totalRevenue", "totalCommission", "totalTax",
        "completedOrders", "cancelledOrders", "updatedAt"
      )
      VALUES (
        gen_random_uuid(),
        ${vendorId},
        ${period}::"StatisticPeriod",
        ${startDate},
        ${endDate},
        ${to}, ${tr}, ${tc}, ${tt}, ${co}, ${ca},
        NOW()
      )
      ON CONFLICT ("vendorId", period, "startDate")
      DO UPDATE SET
        "totalOrders"      = vendor_statistics."totalOrders"      + EXCLUDED."totalOrders",
        "totalRevenue"     = vendor_statistics."totalRevenue"     + EXCLUDED."totalRevenue",
        "totalCommission"  = vendor_statistics."totalCommission"  + EXCLUDED."totalCommission",
        "totalTax"         = vendor_statistics."totalTax"         + EXCLUDED."totalTax",
        "completedOrders"  = vendor_statistics."completedOrders"  + EXCLUDED."completedOrders",
        "cancelledOrders"  = vendor_statistics."cancelledOrders"  + EXCLUDED."cancelledOrders",
        "updatedAt"        = NOW()
    `;
  }

  async getVendorStats(
    vendorId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    // If no range is given, synthesize one covering `limit` buckets ending
    // "today" so the preset DAILY/WEEKLY/MONTHLY UI taps return ~`limit` rows.
    if (!from || !to) {
      ({ from, to } = this.buildDefaultRange(period, limit));
    }
    return this.aggregateVendorStats(vendorId, period, from, to);
  }

  // ─── Driver stats — atomic upsert ─────────────────────────────────────────

  async upsertDriverStat(
    driverId: string,
    period: StatisticPeriod,
    startDate: Date,
    endDate: Date,
    increment: {
      totalOrders?: number;
      totalEarnings?: number;
      completedOrders?: number;
      cancelledOrders?: number;
      onlineHours?: number;
      totalDispatchesReceived?: number;
      dispatchesAccepted?: number;
      dispatchesRejected?: number;
      dispatchesExpired?: number;
    },
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.prisma;
    const to = increment.totalOrders ?? 0;
    const te = increment.totalEarnings ?? 0;
    const co = increment.completedOrders ?? 0;
    const ca = increment.cancelledOrders ?? 0;
    const oh = increment.onlineHours ?? 0;
    const tdr = increment.totalDispatchesReceived ?? 0;
    const da = increment.dispatchesAccepted ?? 0;
    const dr = increment.dispatchesRejected ?? 0;
    const de = increment.dispatchesExpired ?? 0;

    await db.$executeRaw`
      INSERT INTO driver_statistics (
        id, "driverId", period, "startDate", "endDate",
        "totalOrders", "totalEarnings",
        "completedOrders", "cancelledOrders", "onlineHours",
        "totalDispatchesReceived", "dispatchesAccepted",
        "dispatchesRejected", "dispatchesExpired",
        "updatedAt"
      )
      VALUES (
        gen_random_uuid(),
        ${driverId},
        ${period}::"StatisticPeriod",
        ${startDate},
        ${endDate},
        ${to}, ${te}, ${co}, ${ca}, ${oh}, ${tdr}, ${da}, ${dr}, ${de},
        NOW()
      )
      ON CONFLICT ("driverId", period, "startDate")
      DO UPDATE SET
        "totalOrders"              = driver_statistics."totalOrders"              + EXCLUDED."totalOrders",
        "totalEarnings"            = driver_statistics."totalEarnings"            + EXCLUDED."totalEarnings",
        "completedOrders"          = driver_statistics."completedOrders"          + EXCLUDED."completedOrders",
        "cancelledOrders"          = driver_statistics."cancelledOrders"          + EXCLUDED."cancelledOrders",
        "onlineHours"              = driver_statistics."onlineHours"              + EXCLUDED."onlineHours",
        "totalDispatchesReceived"  = driver_statistics."totalDispatchesReceived"  + EXCLUDED."totalDispatchesReceived",
        "dispatchesAccepted"       = driver_statistics."dispatchesAccepted"       + EXCLUDED."dispatchesAccepted",
        "dispatchesRejected"       = driver_statistics."dispatchesRejected"       + EXCLUDED."dispatchesRejected",
        "dispatchesExpired"        = driver_statistics."dispatchesExpired"        + EXCLUDED."dispatchesExpired",
        "updatedAt"                = NOW()
    `;
  }

  async getDriverStats(
    driverId: string,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    if (!from || !to) {
      ({ from, to } = this.buildDefaultRange(period, limit));
    }
    return this.aggregateDriverStats(driverId, period, from, to);
  }

  // ─── Analytics leaderboards ───────────────────────────────────────────────

  async getTopDrivers(limit = 20) {
    return this.prisma.driver.findMany({
      orderBy: { totalOrders: 'desc' },
      take: limit,
      select: {
        id: true,
        totalOrders: true,
        walletBalance: true,
        tier: true,
        status: true,
        user: {
          select: { name: true, phone: true, avatar: true },
        },
        shifts: {
          select: { actualStart: true, actualEnd: true },
          where: { actualEnd: { not: null } },
          orderBy: { actualStart: 'desc' },
          take: 50,
        },
      },
    });
  }

  async getTopCustomers(limit = 20) {
    const rawCustomers = await this.prisma.$queryRaw<
      Array<{ customerId: string; totalOrders: number; totalSpent: number }>
    >`
      SELECT "customerId", COUNT(id)::int as "totalOrders", SUM("grandTotal")::int as "totalSpent"
      FROM orders
      WHERE status = 'DELIVERED'
      GROUP BY "customerId"
      ORDER BY "totalSpent" DESC, "totalOrders" DESC
      LIMIT ${limit}
    `;

    if (rawCustomers.length === 0) return [];

    const customers = await this.prisma.customer.findMany({
      where: { id: { in: rawCustomers.map((c) => c.customerId) } },
      select: {
        id: true,
        coinBalance: true,
        user: {
          select: { name: true, phone: true, avatar: true },
        },
      },
    });
    const byId = new Map(customers.map((c) => [c.id, c]));

    return rawCustomers.map((c) => ({
      ...byId.get(c.customerId),
      totalOrders: c.totalOrders,
      totalSpent: c.totalSpent,
    }));
  }

  async getTopVendors(limit = 20) {
    const topVendorStats = await this.prisma.$queryRaw<
      Array<{ vendorId: string; totalOrders: number; totalRevenue: number }>
    >`
      SELECT "vendorId", SUM("totalOrders")::int as "totalOrders", SUM("totalRevenue")::int as "totalRevenue"
      FROM vendor_statistics
      WHERE period = 'DAILY'
      GROUP BY "vendorId"
      ORDER BY "totalOrders" DESC
      LIMIT ${limit}
    `;

    if (topVendorStats.length === 0) return [];

    const vendorIds = topVendorStats.map((v) => v.vendorId);

    const [vendors, topProducts] = await Promise.all([
      this.prisma.vendor.findMany({
        where: { id: { in: vendorIds } },
        select: {
          id: true,
          storeName: true,
          storeNameAr: true,
          logo: true,
          walletBalance: true,
        },
      }),
      // Most-ordered product per vendor in one pass (no per-vendor query).
      this.prisma.$queryRaw<
        Array<{ productId: string; vendorId: string; totalOrders: number }>
      >`
        SELECT "productId", "vendorId", "totalOrders" FROM (
          SELECT
            oi."productId",
            o."vendorId" AS "vendorId",
            SUM(oi.quantity)::int AS "totalOrders",
            ROW_NUMBER() OVER (
              PARTITION BY o."vendorId"
              ORDER BY SUM(oi.quantity)::int DESC
            ) AS rn
          FROM order_items oi
          JOIN orders o ON o.id = oi."orderId"
          WHERE o."vendorId" IN (${Prisma.join(vendorIds)})
            AND o.status = 'DELIVERED'
            AND oi."productId" IS NOT NULL
          GROUP BY oi."productId", o."vendorId"
        ) ranked
        WHERE rn = 1
      `,
    ]);

    const vendorById = new Map(vendors.map((v) => [v.id, v]));
    const topProductByVendor = new Map(topProducts.map((p) => [p.vendorId, p]));

    const productNames = await this.prisma.product.findMany({
      where: {
        id: {
          in: [...topProductByVendor.values()].map((p) => p.productId),
        },
      },
      select: { id: true, name: true, nameAr: true, imageUrl: true },
    });
    const productById = new Map(productNames.map((p) => [p.id, p]));

    return topVendorStats.map((v) => {
      const top = topProductByVendor.get(v.vendorId);
      const topProduct = top
        ? (() => {
            const p = productById.get(top.productId);
            return p ? { ...p, totalOrders: top.totalOrders } : null;
          })()
        : null;
      return {
        ...vendorById.get(v.vendorId),
        totalOrders: v.totalOrders,
        totalRevenue: v.totalRevenue,
        topProduct,
      };
    });
  }

  async getTopProducts(limit = 20) {
    const rawProducts = await this.prisma.$queryRaw<
      Array<{ productId: string; totalOrders: number }>
    >`
      SELECT oi."productId", SUM(oi.quantity)::int as "totalOrders"
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      WHERE o.status = 'DELIVERED' AND oi."productId" IS NOT NULL
      GROUP BY oi."productId"
      ORDER BY "totalOrders" DESC
      LIMIT ${limit}
    `;

    return Promise.all(
      rawProducts.map(async (rp) => {
        const product = await this.prisma.product.findUnique({
          where: { id: rp.productId },
          select: { name: true, nameAr: true, imageUrl: true },
        });
        return {
          ...product,
          totalOrders: rp.totalOrders,
        };
      }),
    );
  }

  // ─── App stats — atomic upsert ────────────────────────────────────────────

  async upsertAppStat(
    period: StatisticPeriod,
    startDate: Date,
    endDate: Date,
    increment: {
      totalOrders?: number;
      totalAdminRevenue?: number;
      totalDeliveryFees?: number;
      activeCustomers?: number;
      activeDrivers?: number;
    },
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.prisma;
    const to = increment.totalOrders ?? 0;
    const tar = increment.totalAdminRevenue ?? 0;
    const tdf = increment.totalDeliveryFees ?? 0;
    const ac = increment.activeCustomers ?? 0;
    const ad = increment.activeDrivers ?? 0;

    await db.$executeRaw`
      INSERT INTO app_statistics (
        id, period, "startDate", "endDate",
        "totalOrders", "totalAdminRevenue", "totalDeliveryFees",
        "activeCustomers", "activeDrivers",
        "updatedAt"
      )
      VALUES (
        gen_random_uuid(),
        ${period}::"StatisticPeriod",
        ${startDate},
        ${endDate},
        ${to}, ${tar}, ${tdf}, ${ac}, ${ad},
        NOW()
      )
      ON CONFLICT (period, "startDate")
      DO UPDATE SET
        "totalOrders"        = app_statistics."totalOrders"        + EXCLUDED."totalOrders",
        "totalAdminRevenue"  = app_statistics."totalAdminRevenue"  + EXCLUDED."totalAdminRevenue",
        "totalDeliveryFees"  = app_statistics."totalDeliveryFees"  + EXCLUDED."totalDeliveryFees",
        "updatedAt"          = NOW()
    `;
  }

  async getAppStats(
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    if (!from || !to) {
      ({ from, to } = this.buildDefaultRange(period, limit));
    }
    return this.aggregateAppStats(period, from, to);
  }

  // ─── Exact range aggregation ─────────────────────────────────────────────
  // For a custom range we cannot trust pre-aggregated WEEKLY/MONTHLY buckets
  // (boundary buckets would include data outside the requested window). The
  // DAILY buckets are whole-day and exact, so we take only the DAILY rows whose
  // entire day falls inside [from, to] and re-bucket them in memory into the
  // requested granularity. Two partial days are excluded entirely (never summed
  // whole), so every returned bucket is exact.

  private buildRange(from: string, to: string): { from: Date; to: Date } {
    // Days are stored as @db.Date and Prisma returns them at UTC midnight.
    // Use an exclusive upper bound (start of the day after `to`) so the window
    // is exactly the whole days [from, to] regardless of the server timezone.
    const fromDate = new Date(`${from}T00:00:00.000Z`);
    const toDate = new Date(`${to}T00:00:00.000Z`);
    toDate.setUTCDate(toDate.getUTCDate() + 1);
    return { from: fromDate, to: toDate };
  }

  /** Synthesize a [from, to] window for the "last N buckets" preset reads. */
  private buildDefaultRange(
    period: StatisticPeriod,
    limit: number,
  ): { from: string; to: string } {
    const buckets = Math.max(1, limit);
    const to = new Date();
    // Approx span per requested bucket; the aggregation re-buckets to the
    // exact requested granularity regardless, so an over-cover window is fine.
    const daysPerBucket =
      period === StatisticPeriod.DAILY
        ? 1
        : period === StatisticPeriod.WEEKLY
          ? 7
          : 31;
    const from = new Date(to);
    from.setUTCDate(to.getUTCDate() - buckets * daysPerBucket);
    const fmt = (d: Date) =>
      `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(
        d.getUTCDate(),
      ).padStart(2, '0')}`;
    return { from: fmt(from), to: fmt(to) };
  }

  private groupKey(date: Date, period: StatisticPeriod): string {
    const d = date;
    switch (period) {
      case StatisticPeriod.DAILY:
        return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(
          d.getUTCDate(),
        ).padStart(2, '0')}`;
      case StatisticPeriod.WEEKLY: {
        const dow = d.getUTCDay();
        const diffToMonday = dow === 0 ? -6 : 1 - dow;
        const monday = new Date(d);
        monday.setUTCDate(d.getUTCDate() + diffToMonday);
        return `${monday.getUTCFullYear()}-${String(
          monday.getUTCMonth() + 1,
        ).padStart(2, '0')}-${String(monday.getUTCDate()).padStart(2, '0')}`;
      }
      case StatisticPeriod.MONTHLY:
        return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
      case StatisticPeriod.YEARLY:
        return `${d.getUTCFullYear()}`;
      default:
        return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(
          d.getUTCDate(),
        ).padStart(2, '0')}`;
    }
  }

  private groupBounds(
    key: string,
    period: StatisticPeriod,
  ): { startDate: Date; endDate: Date } {
    if (period === StatisticPeriod.MONTHLY) {
      const [y, m] = key.split('-').map(Number);
      return {
        startDate: new Date(Date.UTC(y, m - 1, 1)),
        endDate: new Date(Date.UTC(y, m, 0, 23, 59, 59, 999)),
      };
    }
    if (period === StatisticPeriod.YEARLY) {
      const y = Number(key.split('-')[0]);
      return {
        startDate: new Date(Date.UTC(y, 0, 1)),
        endDate: new Date(Date.UTC(y, 11, 31, 23, 59, 59, 999)),
      };
    }
    if (period === StatisticPeriod.WEEKLY) {
      const [y, m, day] = key.split('-').map(Number);
      const start = new Date(Date.UTC(y, m - 1, day));
      const end = new Date(start);
      end.setUTCDate(start.getUTCDate() + 6);
      end.setUTCHours(23, 59, 59, 999);
      return { startDate: start, endDate: end };
    }
    const [y, m, day] = key.split('-').map(Number);
    return {
      startDate: new Date(Date.UTC(y, m - 1, day)),
      endDate: new Date(Date.UTC(y, m - 1, day, 23, 59, 59, 999)),
    };
  }

  private async aggregateVendorStats(
    vendorId: string,
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);
    const days = await this.prisma.vendorStatistic.findMany({
      where: {
        vendorId,
        period: StatisticPeriod.DAILY,
        startDate: { gte: fromDate, lt: toDate },
      },
    });
    const groups = new Map<
      string,
      {
        totalOrders: number;
        totalRevenue: number;
        totalCommission: number;
        totalTax: number;
        completedOrders: number;
        cancelledOrders: number;
      }
    >();
    for (const day of days) {
      const key = this.groupKey(day.startDate, period);
      const g = groups.get(key) ?? {
        totalOrders: 0,
        totalRevenue: 0,
        totalCommission: 0,
        totalTax: 0,
        completedOrders: 0,
        cancelledOrders: 0,
      };
      g.totalOrders += day.totalOrders;
      g.totalRevenue += day.totalRevenue;
      g.totalCommission += day.totalCommission;
      g.totalTax += day.totalTax;
      g.completedOrders += day.completedOrders;
      g.cancelledOrders += day.cancelledOrders;
      groups.set(key, g);
    }
    return [...groups.entries()]
      .map(([key, g]) => {
        const { startDate, endDate } = this.groupBounds(key, period);
        return { period, startDate, endDate, ...g };
      })
      .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
  }

  private async aggregateDriverStats(
    driverId: string,
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);
    const days = await this.prisma.driverStatistic.findMany({
      where: {
        driverId,
        period: StatisticPeriod.DAILY,
        startDate: { gte: fromDate, lt: toDate },
      },
    });
    const groups = new Map<
      string,
      {
        totalOrders: number;
        totalEarnings: number;
        completedOrders: number;
        cancelledOrders: number;
        onlineHours: number;
        totalDispatchesReceived: number;
        dispatchesAccepted: number;
        dispatchesRejected: number;
        dispatchesExpired: number;
      }
    >();
    for (const day of days) {
      const key = this.groupKey(day.startDate, period);
      const g = groups.get(key) ?? {
        totalOrders: 0,
        totalEarnings: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        onlineHours: 0,
        totalDispatchesReceived: 0,
        dispatchesAccepted: 0,
        dispatchesRejected: 0,
        dispatchesExpired: 0,
      };
      g.totalOrders += day.totalOrders;
      g.totalEarnings += day.totalEarnings;
      g.completedOrders += day.completedOrders;
      g.cancelledOrders += day.cancelledOrders;
      g.onlineHours += day.onlineHours ?? 0;
      g.totalDispatchesReceived += day.totalDispatchesReceived;
      g.dispatchesAccepted += day.dispatchesAccepted;
      g.dispatchesRejected += day.dispatchesRejected;
      g.dispatchesExpired += day.dispatchesExpired;
      groups.set(key, g);
    }
    return [...groups.entries()]
      .map(([key, g]) => {
        const { startDate, endDate } = this.groupBounds(key, period);
        return { period, startDate, endDate, ...g };
      })
      .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
  }

  private async aggregateAppStats(
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);

    // Additive metrics come from the exact whole-day DAILY rows.
    const [days, activeRows] = await Promise.all([
      this.prisma.appStatistic.findMany({
        where: {
          period: StatisticPeriod.DAILY,
          startDate: { gte: fromDate, lt: toDate },
        },
      }),
      // activeCustomers/activeDrivers are DISTINCT counts — they cannot be
      // summed across days. Compute them per requested bucket straight from
      // `orders` so weekly/monthly/today values are always exact.
      this.computeActiveCounts(period, fromDate, toDate),
    ]);

    const activeByKey = new Map(
      activeRows.map((r) => [this.groupKey(r.startDate, period), r]),
    );

    const groups = new Map<
      string,
      {
        totalOrders: number;
        totalAdminRevenue: number;
        totalDeliveryFees: number;
        activeCustomers: number;
        activeDrivers: number;
      }
    >();
    for (const day of days) {
      const key = this.groupKey(day.startDate, period);
      const g = groups.get(key) ?? {
        totalOrders: 0,
        totalAdminRevenue: 0,
        totalDeliveryFees: 0,
        activeCustomers: 0,
        activeDrivers: 0,
      };
      g.totalOrders += day.totalOrders;
      g.totalAdminRevenue += day.totalAdminRevenue;
      g.totalDeliveryFees += day.totalDeliveryFees;
      groups.set(key, g);
    }
    // Merge the exact distinct counts into their bucket (any bucket that has
    // orders but no additive row yet, and vice-versa, still appears).
    for (const [key, active] of activeByKey) {
      const g = groups.get(key) ?? {
        totalOrders: 0,
        totalAdminRevenue: 0,
        totalDeliveryFees: 0,
        activeCustomers: 0,
        activeDrivers: 0,
      };
      g.activeCustomers = active.activeCustomers;
      g.activeDrivers = active.activeDrivers;
      groups.set(key, g);
    }
    return [...groups.entries()]
      .map(([key, g]) => {
        const { startDate, endDate } = this.groupBounds(key, period);
        return { period, startDate, endDate, ...g };
      })
      .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
  }

  // ─── Vendor wallet ────────────────────────────────────────────────────────

  async creditVendorWallet(
    vendorId: string,
    amount: number,
    type: string,
    orderId: string | null,
    description: string,
    client?: Prisma.TransactionClient,
    options: { skipLock?: boolean } = {},
  ) {
    const run = async (tx: Prisma.TransactionClient) => {
      // settleOrder acquires the vendor lock once at the top of its transaction
      // and passes skipLock: true so we don't re-lock the same row per call.
      if (!options.skipLock) {
        await tx.$executeRaw`SELECT id FROM vendors WHERE id = ${vendorId} FOR UPDATE`;
      }

      if (orderId) {
        const existing = await tx.vendorWalletTransaction.findFirst({
          where: { orderId, type: type as VendorTransactionType },
        });
        if (existing) return existing.balanceAfter;
      }

      const vendor = await tx.vendor.update({
        where: { id: vendorId },
        data: { walletBalance: { increment: amount } },
        select: { walletBalance: true },
      });

      await tx.vendorWalletTransaction.create({
        data: {
          vendorId,
          orderId,
          type: type as VendorTransactionType,
          amount,
          balanceAfter: vendor.walletBalance,
          description,
        },
      });

      return vendor.walletBalance;
    };

    return client ? run(client) : this.prisma.$transaction(run);
  }

  async debitVendorWallet(
    vendorId: string,
    amount: number,
    type: string,
    orderId: string | null,
    description: string,
    client?: Prisma.TransactionClient,
    options: { skipLock?: boolean } = {},
  ) {
    const run = async (tx: Prisma.TransactionClient) => {
      if (!options.skipLock) {
        await tx.$executeRaw`SELECT id FROM vendors WHERE id = ${vendorId} FOR UPDATE`;
      }

      if (orderId) {
        const existing = await tx.vendorWalletTransaction.findFirst({
          where: { orderId, type: type as VendorTransactionType },
        });
        if (existing) return existing.balanceAfter;
      }

      const vendor = await tx.vendor.update({
        where: { id: vendorId },
        data: { walletBalance: { decrement: amount } },
        select: { walletBalance: true },
      });

      await tx.vendorWalletTransaction.create({
        data: {
          vendorId,
          orderId,
          type: type as VendorTransactionType,
          amount: -amount,
          balanceAfter: vendor.walletBalance,
          description,
        },
      });

      return vendor.walletBalance;
    };

    return client ? run(client) : this.prisma.$transaction(run);
  }

  // ─── Active counts (distinct, computed on demand) ─────────────────────────
  // activeCustomers/activeDrivers are DISTINCT counts per period, so they can
  // never be `+=` incremented nor summed across days. Reads compute them
  // directly from `orders`, grouped to the requested granularity (see
  // aggregateAppStats) — no stored pre-aggregate row to drift from the truth.

  async computeActiveCounts(
    period: StatisticPeriod,
    from: Date,
    to: Date,
  ): Promise<
    Array<{
      startDate: Date;
      endDate: Date;
      activeCustomers: number;
      activeDrivers: number;
    }>
  > {
    const trunc = {
      [StatisticPeriod.DAILY]: 'day',
      [StatisticPeriod.WEEKLY]: 'week',
      [StatisticPeriod.MONTHLY]: 'month',
      [StatisticPeriod.YEARLY]: 'year',
    }[period];

    const rows = await this.prisma.$queryRaw<
      Array<{ key: string; activeCustomers: bigint; activeDrivers: bigint }>
    >`
      SELECT
        to_char(date_trunc(${trunc}::text, "createdAt" AT TIME ZONE 'UTC'), 'YYYY-MM-DD') AS key,
        COUNT(DISTINCT "customerId")::bigint AS "activeCustomers",
        COUNT(DISTINCT "driverId")::bigint AS "activeDrivers"
      FROM orders
      WHERE "createdAt" >= ${from} AND "createdAt" < ${to}
        AND "deletedAt" IS NULL
        AND "customerId" IS NOT NULL
      GROUP BY 1
      ORDER BY 1 ASC
    `;

    return rows.map((row) => {
      const { startDate, endDate } = this.groupBounds(row.key, period);
      return {
        startDate,
        endDate,
        activeCustomers: Number(row.activeCustomers),
        activeDrivers: Number(row.activeDrivers),
      };
    });
  }
}
