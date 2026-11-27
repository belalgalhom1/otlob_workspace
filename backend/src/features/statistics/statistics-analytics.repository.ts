import { Injectable } from '@nestjs/common';
import {
  DeliveryIncidentResponsibility,
  Prisma,
  StatisticPeriod,
} from '@prisma/client';
import {
  calculateAcceptanceRate,
  calculateCompletionRate,
  calculateEligibleDispatches,
} from '../../common/drivers/driver-kpi.helper';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  appTimeZone,
  parseDateEnd,
  parseDateStart,
  tzDateKey,
  tzDayEnd,
  tzDayStart,
  tzParts,
} from 'src/common/utils/timezone';
export interface VendorProductSalesOptions {
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
  search?: string;
  branchId?: string;
  sortBy?: 'revenue' | 'quantity' | 'orders' | 'net' | 'name';
  sortOrder?: 'asc' | 'desc';
}

@Injectable()
export class StatisticsAnalyticsRepository {
  constructor(private readonly prisma: PrismaService) {}

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

  /**
   * Aggregated statistics for a set of drivers (a driver manager's managed
   * drivers, or every driver when `driverIds` is null). Returns both the
   * combined totals for the period and a per-driver breakdown so the UI can
   * compare drivers at a glance.
   */
  async getManagedDriversStats(
    driverIds: string[] | null,
    period: StatisticPeriod,
    limit = 30,
    from?: string,
    to?: string,
  ) {
    if (!from || !to) {
      ({ from, to } = this.buildDefaultRange(period, limit));
    }
    return this.aggregateManagedDriversStats(driverIds, period, from, to);
  }

  // ─── Analytics leaderboards ───────────────────────────────────────────────

  private buildOrderRange(
    from?: string,
    to?: string,
  ): { gte?: Date; lte?: Date } | null {
    const gte = from ? parseDateStart(from) : undefined;
    const lte = to ? parseDateEnd(to) : undefined;
    if ((gte && isNaN(gte.getTime())) || (lte && isNaN(lte.getTime()))) {
      return null;
    }
    if (!gte && !lte) return null;
    return { gte, lte };
  }

  private buildCreatedAtSql(range: { gte?: Date; lte?: Date } | null) {
    if (!range) return Prisma.empty;
    return Prisma.sql`${range.gte ? Prisma.sql`AND o."createdAt" >= ${range.gte}` : Prisma.empty} ${range.lte ? Prisma.sql`AND o."createdAt" <= ${range.lte}` : Prisma.empty}`;
  }

  async getTopDrivers(limit = 20, from?: string, to?: string) {
    const range = this.buildOrderRange(from, to);

    const select = {
      id: true,
      name: true,
      avatar: true,
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
        orderBy: { actualStart: 'desc' as const },
        take: 50,
      },
    };

    if (range) {
      const rangeSql = this.buildCreatedAtSql(range);
      const raw = await this.prisma.$queryRaw<
        Array<{ driverId: string; totalOrders: number }>
      >`
        SELECT g."primaryDriverId" AS "driverId", COUNT(DISTINCT g.id)::int AS "totalOrders"
        FROM order_delivery_groups g
        JOIN orders o ON o.id = g."orderId"
        WHERE g.status = 'DELIVERED'
          AND g."primaryDriverId" IS NOT NULL
          AND o."deletedAt" IS NULL
          ${rangeSql}
        GROUP BY g."primaryDriverId"
        ORDER BY "totalOrders" DESC
        LIMIT ${limit}
      `;
      if (raw.length === 0) return [];

      const drivers = await this.prisma.driver.findMany({
        where: { id: { in: raw.map((r) => r.driverId) } },
        select,
      });
      const byId = new Map(drivers.map((d) => [d.id, d]));
      return raw
        .filter((r) => byId.has(r.driverId))
        .map((r) => {
          const d = byId.get(r.driverId)!;
          const coalescedAvatar = d.avatar ?? d.user?.avatar ?? null;
          return {
            ...d,
            name: d.name ?? d.user?.name,
            avatar: coalescedAvatar,
            user: d.user ? { ...d.user, avatar: coalescedAvatar } : d.user,
            totalOrders: r.totalOrders,
          };
        });
    }

    const drivers = await this.prisma.driver.findMany({
      orderBy: { totalOrders: 'desc' },
      take: limit,
      select,
    });
    return drivers.map((d) => {
      const coalescedAvatar = d.avatar ?? d.user?.avatar ?? null;
      return {
        ...d,
        name: d.name ?? d.user?.name,
        avatar: coalescedAvatar,
        user: d.user ? { ...d.user, avatar: coalescedAvatar } : d.user,
      };
    });
  }

  async getTopCustomers(limit = 20, from?: string, to?: string) {
    const range = this.buildOrderRange(from, to);
    const rangeSql = this.buildCreatedAtSql(range);

    const rawCustomers = await this.prisma.$queryRaw<
      Array<{ customerId: string; totalOrders: number; totalSpent: number }>
    >`
      SELECT o."customerId", COUNT(o.id)::int as "totalOrders", SUM(o."grandTotal")::int as "totalSpent"
      FROM orders o
      WHERE o.status = 'DELIVERED'
        AND o."deletedAt" IS NULL
        ${rangeSql}
      GROUP BY o."customerId"
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

    return rawCustomers
      .filter((c) => byId.has(c.customerId))
      .map((c) => ({
        ...byId.get(c.customerId),
        totalOrders: c.totalOrders,
        totalSpent: c.totalSpent,
      }));
  }

  async getTopVendors(limit = 20, from?: string, to?: string) {
    const range = this.buildOrderRange(from, to);
    const rangeSql = this.buildCreatedAtSql(range);

    const topVendorStats = range
      ? await this.prisma.$queryRaw<
          Array<{
            vendorId: string;
            totalOrders: number;
            totalRevenue: number;
            totalCommission: number;
          }>
        >`
          SELECT
            f."vendorId",
            COUNT(DISTINCT f."orderId")::int AS "totalOrders",
            COALESCE(SUM(f.subtotal), 0)::int AS "totalRevenue",
            COALESCE(
              SUM(
                CASE
                  WHEN f."isContracted"
                  THEN ROUND(f.subtotal * f."commissionRate" / 100.0)
                  ELSE 0
                END
              ),
              0
            )::int AS "totalCommission"
          FROM order_vendor_fulfillments f
          JOIN orders o ON o.id = f."orderId"
          WHERE o.status = 'DELIVERED'
            AND f.status::text NOT IN ('PENDING', 'REJECTED', 'CANCELLED')
            AND o."deletedAt" IS NULL
            ${rangeSql}
          GROUP BY f."vendorId"
          ORDER BY "totalOrders" DESC
          LIMIT ${limit}
        `
      : await this.prisma.$queryRaw<
          Array<{
            vendorId: string;
            totalOrders: number;
            totalRevenue: number;
            totalCommission: number;
          }>
        >`
          SELECT
            "vendorId",
            SUM("totalOrders")::int as "totalOrders",
            SUM("totalRevenue")::int as "totalRevenue",
            COALESCE(SUM("totalCommission"), 0)::int as "totalCommission"
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
          coverImage: true,
          walletBalance: true,
          commissionRate: true,
          isContracted: true,
        },
      }),
      // Most-ordered product per vendor in one pass (no per-vendor query).
      this.prisma.$queryRaw<
        Array<{ productId: string; vendorId: string; totalOrders: number }>
      >`
        SELECT "productId", "vendorId", "totalOrders" FROM (
          SELECT
            oi."productId",
            f."vendorId" AS "vendorId",
            SUM(oi.quantity)::int AS "totalOrders",
            ROW_NUMBER() OVER (
              PARTITION BY f."vendorId"
              ORDER BY SUM(oi.quantity)::int DESC
            ) AS rn
          FROM order_items oi
          JOIN order_vendor_fulfillments f ON f.id = oi."fulfillmentId"
          JOIN orders o ON o.id = f."orderId"
          WHERE f."vendorId" IN (${Prisma.join(vendorIds)})
            AND f.status::text NOT IN ('PENDING', 'REJECTED', 'CANCELLED')
            AND o.status = 'DELIVERED'
            AND o."deletedAt" IS NULL
            AND oi."rejectedAt" IS NULL
            AND oi."productId" IS NOT NULL
            ${rangeSql}
          GROUP BY oi."productId", f."vendorId"
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

    return topVendorStats
      .filter((v) => vendorById.has(v.vendorId))
      .map((v) => {
        const top = topProductByVendor.get(v.vendorId);
        const topProduct = top
          ? (() => {
              const p = productById.get(top.productId);
              return p ? { ...p, totalOrders: top.totalOrders } : null;
            })()
          : null;
        const vendor = vendorById.get(v.vendorId)!;
        return {
          ...vendor,
          logo: vendor.logo ?? vendor.coverImage ?? null,
          totalOrders: v.totalOrders,
          totalRevenue: v.totalRevenue,
          totalCommission: v.totalCommission ?? 0,
          topProduct,
        };
      });
  }

  async getTopProducts(limit = 20, from?: string, to?: string) {
    const range = this.buildOrderRange(from, to);
    const rangeSql = this.buildCreatedAtSql(range);

    const rawProducts = await this.prisma.$queryRaw<
      Array<{ productId: string; totalOrders: number }>
    >`
      SELECT oi."productId", SUM(oi.quantity)::int as "totalOrders"
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      WHERE o.status = 'DELIVERED'
        AND o."deletedAt" IS NULL
        AND oi."rejectedAt" IS NULL
        AND oi."productId" IS NOT NULL
        ${rangeSql}
      GROUP BY oi."productId"
      ORDER BY "totalOrders" DESC
      LIMIT ${limit}
    `;

    if (rawProducts.length === 0) return [];

    const products = await this.prisma.product.findMany({
      where: { id: { in: rawProducts.map((rp) => rp.productId) } },
      select: { id: true, name: true, nameAr: true, imageUrl: true },
    });
    const productById = new Map(products.map((p) => [p.id, p]));

    return rawProducts
      .filter((rp) => productById.has(rp.productId))
      .map((rp) => ({
        ...productById.get(rp.productId),
        totalOrders: rp.totalOrders,
      }));
  }

  async getMostOrderedProduct(vendorId: string) {
    // Tiebreaker: 1. Higher quantity sold (totalOrders), 2. More recent activity (lastOrderedAt), 3. Lower productId
    const result = await this.prisma.$queryRaw<
      Array<{ productId: string; totalOrders: number; lastOrderedAt: Date }>
    >`
      SELECT
        oi."productId" AS "productId",
        SUM(oi.quantity)::int AS "totalOrders",
        MAX(o."createdAt") AS "lastOrderedAt"
      FROM order_items oi
      JOIN order_vendor_fulfillments f ON f.id = oi."fulfillmentId"
      JOIN orders o ON o.id = f."orderId"
      WHERE f."vendorId" = ${vendorId}
        AND f.status::text NOT IN ('PENDING', 'REJECTED', 'CANCELLED')
        AND o.status = 'DELIVERED'
        AND o."deletedAt" IS NULL
        AND oi."rejectedAt" IS NULL
        AND oi."productId" IS NOT NULL
      GROUP BY oi."productId"
      ORDER BY "totalOrders" DESC, "lastOrderedAt" DESC, "productId" ASC
      LIMIT 1
    `;

    if (!result || result.length === 0) {
      return null;
    }

    const stats = result[0];
    const product = await this.prisma.product.findUnique({
      where: { id: stats.productId },
      select: {
        id: true,
        name: true,
        nameAr: true,
        imageUrl: true,
      },
    });

    if (!product) {
      return null;
    }

    return {
      vendorId,
      productId: stats.productId,
      totalOrders: stats.totalOrders,
      productName: product.name,
      productNameAr: product.nameAr,
      productImage: product.imageUrl,
    };
  }

  /**
   * Product-level sales report for one vendor.
   *
   * Handles both order shapes:
   *  - legacy/single-vendor: items hang directly off the order (`vendorId`)
   *  - multi-vendor: items belong to an accepted `OrderVendorFulfillment`
   *
   * Only delivered, non-rejected items count. Commission uses the rate captured
   * on the fulfillment (multi-vendor) or the vendor's current rate (single
   * vendor), and is zero for uncontracted vendors — matching settlement, where
   * uncontracted vendors keep the cash directly.
   */
  async getVendorProductSales(
    vendorId: string,
    opts: VendorProductSalesOptions = {},
  ) {
    const page = Math.max(1, opts.page ?? 1);
    const limit = Math.min(100, Math.max(1, opts.limit ?? 20));
    const offset = (page - 1) * limit;

    const search = opts.search?.trim();
    const searchSql = search
      ? Prisma.sql`WHERE (vi."productName" ILIKE ${`%${search}%`} OR vi."productNameAr" ILIKE ${`%${search}%`})`
      : Prisma.empty;

    const rangeSql = Prisma.sql`
      ${opts.from ? Prisma.sql`AND o."createdAt" >= ${parseDateStart(opts.from)}` : Prisma.empty}
      ${opts.to ? Prisma.sql`AND o."createdAt" <= ${parseDateEnd(opts.to)}` : Prisma.empty}
    `;
    const branchFilter = opts.branchId
      ? Prisma.sql`AND f."vendorBranchId" = ${opts.branchId}`
      : Prisma.empty;

    const sortColumns: Record<string, string> = {
      revenue: '"grossRevenue"',
      quantity: '"quantitySold"',
      orders: '"ordersCount"',
      net: '"netRevenue"',
      name: '"productName"',
    };
    const sortColumn = Prisma.raw(
      sortColumns[opts.sortBy ?? 'revenue'] ?? sortColumns.revenue,
    );
    const sortDirection = Prisma.raw(opts.sortOrder === 'asc' ? 'ASC' : 'DESC');

    const cte = Prisma.sql`
      WITH vendor_items AS (
        SELECT
          oi."orderId" AS "orderId",
          oi."productId" AS "productId",
          COALESCE(p.name, oi."productName") AS "productName",
          p."nameAr" AS "productNameAr",
          p."imageUrl" AS "productImage",
          CASE WHEN oi."productId" IS NULL THEN oi."productName" ELSE NULL END AS "customKey",
          oi.quantity AS "quantity",
          oi."totalPrice" AS "totalPrice",
          f."commissionRate"::numeric AS "commissionRate",
          f."isContracted" AS "isContracted"
        FROM order_items oi
        JOIN order_vendor_fulfillments f ON f.id = oi."fulfillmentId"
        JOIN orders o ON o.id = f."orderId"
        LEFT JOIN products p ON p.id = oi."productId"
        WHERE f."vendorId" = ${vendorId}
          AND f.status::text NOT IN ('PENDING', 'REJECTED', 'CANCELLED')
          AND o.status = 'DELIVERED'
          AND o."deletedAt" IS NULL
          AND oi."rejectedAt" IS NULL
          ${rangeSql}
          ${branchFilter}
      )
    `;

    const [rows, totalsRows] = await Promise.all([
      this.prisma.$queryRaw<
        Array<{
          productId: string | null;
          productName: string;
          productNameAr: string | null;
          productImage: string | null;
          quantitySold: number;
          ordersCount: number;
          grossRevenue: number;
          commission: number;
          netRevenue: number;
        }>
      >(Prisma.sql`
        ${cte}
        SELECT
          vi."productId" AS "productId",
          MAX(vi."productName") AS "productName",
          MAX(vi."productNameAr") AS "productNameAr",
          MAX(vi."productImage") AS "productImage",
          SUM(vi."quantity")::int AS "quantitySold",
          COUNT(DISTINCT vi."orderId")::int AS "ordersCount",
          SUM(vi."totalPrice")::int AS "grossRevenue",
          SUM(CASE WHEN vi."isContracted" THEN ROUND(vi."totalPrice" * vi."commissionRate" / 100.0) ELSE 0 END)::int AS "commission",
          (
            SUM(vi."totalPrice") -
            SUM(CASE WHEN vi."isContracted" THEN ROUND(vi."totalPrice" * vi."commissionRate" / 100.0) ELSE 0 END)
          )::int AS "netRevenue"
        FROM vendor_items vi
        ${searchSql}
        GROUP BY vi."productId", vi."customKey"
        ORDER BY ${sortColumn} ${sortDirection}
        LIMIT ${limit} OFFSET ${offset}
      `),
      this.prisma.$queryRaw<
        Array<{
          productCount: number;
          quantitySold: number;
          ordersCount: number;
          grossRevenue: number;
          commission: number;
        }>
      >(Prisma.sql`
        ${cte}
        SELECT
          COUNT(DISTINCT COALESCE(vi."productId", 'custom:' || vi."customKey"))::int AS "productCount",
          COALESCE(SUM(vi."quantity"), 0)::int AS "quantitySold",
          COUNT(DISTINCT vi."orderId")::int AS "ordersCount",
          COALESCE(SUM(vi."totalPrice"), 0)::int AS "grossRevenue",
          COALESCE(SUM(CASE WHEN vi."isContracted" THEN ROUND(vi."totalPrice" * vi."commissionRate" / 100.0) ELSE 0 END), 0)::int AS "commission"
        FROM vendor_items vi
        ${searchSql}
      `),
    ]);

    const totals = totalsRows[0] ?? {
      productCount: 0,
      quantitySold: 0,
      ordersCount: 0,
      grossRevenue: 0,
      commission: 0,
    };

    return {
      products: rows,
      totals: {
        ...totals,
        netRevenue: totals.grossRevenue - totals.commission,
      },
      page,
      limit,
      total: totals.productCount,
      totalPages: Math.ceil(totals.productCount / limit),
      from: opts.from ?? null,
      to: opts.to ?? null,
    };
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
    const fromDate = parseDateStart(from);
    const anchor = new Date(`${to}T00:00:00.000Z`);
    let toDate: Date;
    if (Number.isNaN(anchor.getTime())) {
      toDate = new Date(to);
    } else {
      const next = new Date(
        Date.UTC(
          anchor.getUTCFullYear(),
          anchor.getUTCMonth(),
          anchor.getUTCDate() + 1,
        ),
      );
      const y = next.getUTCFullYear();
      const m = next.getUTCMonth() + 1;
      const d = next.getUTCDate();
      toDate = parseDateStart(
        `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`,
      );
    }
    return { from: fromDate, to: toDate };
  }

  /** Synthesize a [from, to] window for the "last N buckets" preset reads. */
  private buildDefaultRange(
    period: StatisticPeriod,
    limit: number,
  ): { from: string; to: string } {
    const buckets = Math.max(1, limit);
    const todayKey = tzDateKey(new Date());
    const [ty, tm, td] = todayKey.split('-').map(Number);
    const daysPerBucket =
      period === StatisticPeriod.DAILY
        ? 1
        : period === StatisticPeriod.WEEKLY
          ? 7
          : 31;
    const fromBase = new Date(
      Date.UTC(ty, tm - 1, td - buckets * daysPerBucket),
    );
    return { from: tzDateKey(fromBase), to: todayKey };
  }

  private groupKey(date: Date, period: StatisticPeriod): string {
    const d = tzParts(new Date(date));
    const pad2 = (n: number) => String(n).padStart(2, '0');
    switch (period) {
      case StatisticPeriod.DAILY:
        return `${d.year}-${pad2(d.month)}-${pad2(d.day)}`;
      case StatisticPeriod.WEEKLY: {
        const diffToMonday = d.weekday === 0 ? -6 : 1 - d.weekday;
        const monday = new Date(
          Date.UTC(d.year, d.month - 1, d.day + diffToMonday),
        );
        return tzDateKey(monday);
      }
      case StatisticPeriod.MONTHLY:
        return `${d.year}-${pad2(d.month)}`;
      case StatisticPeriod.YEARLY:
        return `${d.year}`;
      default:
        return `${d.year}-${pad2(d.month)}-${pad2(d.day)}`;
    }
  }

  private groupBounds(
    key: string,
    period: StatisticPeriod,
  ): { startDate: Date; endDate: Date } {
    if (period === StatisticPeriod.MONTHLY) {
      const [y, m] = key.split('-').map(Number);
      const next = m === 12 ? { y: y + 1, m: 1 } : { y, m: m + 1 };
      return {
        startDate: tzDayStart(y, m, 1),
        endDate: new Date(tzDayStart(next.y, next.m, 1).getTime() - 1),
      };
    }
    if (period === StatisticPeriod.YEARLY) {
      const y = Number(key.split('-')[0]);
      return {
        startDate: tzDayStart(y, 1, 1),
        endDate: new Date(tzDayStart(y + 1, 1, 1).getTime() - 1),
      };
    }
    if (period === StatisticPeriod.WEEKLY) {
      const [y, m, day] = key.split('-').map(Number);
      const start = tzDayStart(y, m, day);
      const endBase = new Date(Date.UTC(y, m - 1, day + 6));
      const end = tzDayEnd(
        endBase.getUTCFullYear(),
        endBase.getUTCMonth() + 1,
        endBase.getUTCDate(),
      );
      return { startDate: start, endDate: end };
    }
    const [y, m, day] = key.split('-').map(Number);
    return {
      startDate: tzDayStart(y, m, day),
      endDate: tzDayEnd(y, m, day),
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

  private withDriverKpis<
    T extends {
      completedOrders: number;
      dispatchesAccepted: number;
      dispatchesRejected: number;
      dispatchesExpired: number;
      driverFaultCancellations: number;
    },
  >(bucket: T) {
    return {
      ...bucket,
      eligibleDispatches: calculateEligibleDispatches(
        bucket.dispatchesAccepted,
        bucket.dispatchesRejected,
        bucket.dispatchesExpired,
      ),
      acceptanceRate: calculateAcceptanceRate(
        bucket.dispatchesAccepted,
        bucket.dispatchesRejected,
        bucket.dispatchesExpired,
      ),
      completionRate: calculateCompletionRate(
        bucket.completedOrders,
        bucket.driverFaultCancellations,
      ),
    };
  }

  private async aggregateDriverStats(
    driverId: string,
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);
    const [days, faultIncidents] = await Promise.all([
      this.prisma.driverStatistic.findMany({
        where: {
          driverId,
          period: StatisticPeriod.DAILY,
          startDate: { gte: fromDate, lt: toDate },
        },
      }),
      this.prisma.driverDeliveryIncident.findMany({
        where: {
          driverId,
          responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
          occurredAt: { gte: fromDate, lt: toDate },
        },
        select: { deliveryGroupId: true, occurredAt: true },
      }),
    ]);

    type DriverBucket = {
      totalOrders: number;
      totalEarnings: number;
      completedOrders: number;
      cancelledOrders: number;
      driverFaultCancellations: number;
      onlineHours: number;
      totalDispatchesReceived: number;
      dispatchesAccepted: number;
      dispatchesRejected: number;
      dispatchesExpired: number;
    };
    const emptyBucket = (): DriverBucket => ({
      totalOrders: 0,
      totalEarnings: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      driverFaultCancellations: 0,
      onlineHours: 0,
      totalDispatchesReceived: 0,
      dispatchesAccepted: 0,
      dispatchesRejected: 0,
      dispatchesExpired: 0,
    });

    const groups = new Map<string, DriverBucket>();
    for (const day of days) {
      const key = this.groupKey(day.startDate, period);
      const g = groups.get(key) ?? emptyBucket();
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

    const seenFaultGroups = new Set<string>();
    for (const inc of faultIncidents) {
      const key = this.groupKey(inc.occurredAt, period);
      const dedupeKey = `${key}:${inc.deliveryGroupId}`;
      if (seenFaultGroups.has(dedupeKey)) continue;
      seenFaultGroups.add(dedupeKey);
      const g = groups.get(key) ?? emptyBucket();
      g.driverFaultCancellations += 1;
      groups.set(key, g);
    }

    return [...groups.entries()]
      .map(([key, g]) => {
        const { startDate, endDate } = this.groupBounds(key, period);
        return { period, startDate, endDate, ...this.withDriverKpis(g) };
      })
      .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
  }

  private async aggregateManagedDriversStats(
    driverIds: string[] | null,
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);

    const where: Prisma.DriverStatisticWhereInput = {
      period: StatisticPeriod.DAILY,
      startDate: { gte: fromDate, lt: toDate },
    };
    if (driverIds !== null) {
      where.driverId = { in: driverIds };
    }

    const [days, drivers, faultIncidents] = await Promise.all([
      this.prisma.driverStatistic.findMany({ where }),
      this.prisma.driver.findMany({
        where: {
          deletedAt: null,
          ...(driverIds !== null ? { id: { in: driverIds } } : {}),
        },
        select: {
          id: true,
          name: true,
          avatar: true,
          tier: true,
          status: true,
          user: { select: { name: true, phone: true, avatar: true } },
        },
      }),
      this.prisma.driverDeliveryIncident.findMany({
        where: {
          ...(driverIds !== null ? { driverId: { in: driverIds } } : {}),
          responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
          occurredAt: { gte: fromDate, lt: toDate },
        },
        select: { driverId: true, deliveryGroupId: true },
      }),
    ]);

    type DriverBucket = {
      totalOrders: number;
      totalEarnings: number;
      completedOrders: number;
      cancelledOrders: number;
      driverFaultCancellations: number;
      onlineHours: number;
      totalDispatchesReceived: number;
      dispatchesAccepted: number;
      dispatchesRejected: number;
      dispatchesExpired: number;
    };
    const emptyBucket = (): DriverBucket => ({
      totalOrders: 0,
      totalEarnings: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      driverFaultCancellations: 0,
      onlineHours: 0,
      totalDispatchesReceived: 0,
      dispatchesAccepted: 0,
      dispatchesRejected: 0,
      dispatchesExpired: 0,
    });

    const activeDriverIds = new Set(drivers.map((d) => d.id));
    const perDriver = new Map<string, DriverBucket>();
    const totals = emptyBucket();

    for (const day of days) {
      if (!activeDriverIds.has(day.driverId)) continue;
      const bucket = perDriver.get(day.driverId) ?? emptyBucket();
      bucket.totalOrders += day.totalOrders;
      bucket.totalEarnings += day.totalEarnings;
      bucket.completedOrders += day.completedOrders;
      bucket.cancelledOrders += day.cancelledOrders;
      bucket.onlineHours += day.onlineHours ?? 0;
      bucket.totalDispatchesReceived += day.totalDispatchesReceived;
      bucket.dispatchesAccepted += day.dispatchesAccepted;
      bucket.dispatchesRejected += day.dispatchesRejected;
      bucket.dispatchesExpired += day.dispatchesExpired;
      perDriver.set(day.driverId, bucket);

      totals.totalOrders += day.totalOrders;
      totals.totalEarnings += day.totalEarnings;
      totals.completedOrders += day.completedOrders;
      totals.cancelledOrders += day.cancelledOrders;
      totals.onlineHours += day.onlineHours ?? 0;
      totals.totalDispatchesReceived += day.totalDispatchesReceived;
      totals.dispatchesAccepted += day.dispatchesAccepted;
      totals.dispatchesRejected += day.dispatchesRejected;
      totals.dispatchesExpired += day.dispatchesExpired;
    }

    const seenDriverFaults = new Set<string>();
    for (const inc of faultIncidents) {
      if (!activeDriverIds.has(inc.driverId)) continue;
      const dedupeKey = `${inc.driverId}:${inc.deliveryGroupId}`;
      if (seenDriverFaults.has(dedupeKey)) continue;
      seenDriverFaults.add(dedupeKey);
      const bucket = perDriver.get(inc.driverId) ?? emptyBucket();
      bucket.driverFaultCancellations += 1;
      perDriver.set(inc.driverId, bucket);
      totals.driverFaultCancellations += 1;
    }

    const rows = drivers
      .map((driver) => {
        const stats = perDriver.get(driver.id) ?? emptyBucket();
        return {
          driverId: driver.id,
          name: driver.name ?? driver.user?.name ?? null,
          phone: driver.user?.phone ?? null,
          avatar: driver.avatar ?? driver.user?.avatar ?? null,
          tier: driver.tier,
          status: driver.status,
          ...this.withDriverKpis(stats),
        };
      })
      .sort(
        (a, b) =>
          b.totalEarnings - a.totalEarnings ||
          b.totalOrders - a.totalOrders ||
          (a.name ?? '').localeCompare(b.name ?? ''),
      );

    return {
      period,
      from: fromDate,
      to: toDate,
      totals: this.withDriverKpis(totals),
      drivers: rows,
    };
  }

  private async aggregateAppStats(
    period: StatisticPeriod,
    from: string,
    to: string,
  ) {
    const { from: fromDate, to: toDate } = this.buildRange(from, to);

    const [days, activeRows] = await Promise.all([
      this.prisma.appStatistic.findMany({
        where: {
          period: StatisticPeriod.DAILY,
          startDate: { gte: fromDate, lt: toDate },
        },
      }),
      // activeCustomers/activeDrivers are DISTINCT counts — compute straight from orders.
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

  // ─── Active counts (distinct, computed on demand) ─────────────────────────

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

    const tz = appTimeZone();
    const rows = await this.prisma.$queryRaw<
      Array<{ key: string; activeCustomers: bigint; activeDrivers: bigint }>
    >`
      SELECT
        to_char(date_trunc(${trunc}::text, o."createdAt" AT TIME ZONE ${tz}), 'YYYY-MM-DD') AS key,
        COUNT(DISTINCT o."customerId")::bigint AS "activeCustomers",
        COUNT(DISTINCT g."primaryDriverId")::bigint AS "activeDrivers"
      FROM orders o
      LEFT JOIN order_delivery_groups g ON g."orderId" = o.id
      WHERE o."createdAt" >= ${from} AND o."createdAt" < ${to}
        AND o."deletedAt" IS NULL
        AND o."customerId" IS NOT NULL
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
