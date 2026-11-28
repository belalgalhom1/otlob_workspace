import { StatisticPeriod } from '@prisma/client';
import { StatisticsAnalyticsRepository } from './statistics-analytics.repository';

function flattenRawQuery(query: unknown): string {
  if (typeof query === 'string') return query;
  if (query && typeof query === 'object' && 'strings' in (query as any)) {
    return ((query as any).strings as string[]).join(' ? ');
  }
  return String(query);
}

describe('StatisticsAnalyticsRepository.getAppStats financial breakdown', () => {
  it('returns totalDeliveryProfit, totalDriverManagerEarnings, and totalVendorCommissions per DAILY bucket', async () => {
    const executedSql: string[] = [];
    const day1 = new Date('2026-11-26T00:00:00.000Z');
    const day2 = new Date('2026-11-27T00:00:00.000Z');

    const prisma: any = {
      appStatistic: {
        findMany: jest.fn().mockResolvedValue([
          {
            period: StatisticPeriod.DAILY,
            startDate: day1,
            endDate: day1,
            totalOrders: 5,
            // e.g. vendor commissions (30) + uncontracted serviceFees (10) + delivery profit (17) = 57
            totalAdminRevenue: 57,
            totalDeliveryFees: 120,
          },
          {
            period: StatisticPeriod.DAILY,
            startDate: day2,
            endDate: day2,
            totalOrders: 3,
            // e.g. vendor commissions (15) + serviceFees (0) + delivery profit (10) = 25
            totalAdminRevenue: 25,
            totalDeliveryFees: 75,
          },
        ]),
      },
      vendorStatistic: {
        findMany: jest.fn().mockResolvedValue([
          { startDate: day1, totalCommission: 20 },
          { startDate: day1, totalCommission: 10 },
          { startDate: day2, totalCommission: 15 },
        ]),
      },
      driverStatistic: {
        findMany: jest.fn().mockResolvedValue([
          { startDate: day1, totalEarnings: 54 },
          { startDate: day1, totalEarnings: 40 },
          { startDate: day2, totalEarnings: 59 },
        ]),
      },
      $queryRaw: jest.fn().mockImplementation((query: unknown) => {
        const sql = flattenRawQuery(query);
        executedSql.push(sql);
        if (sql.includes('activeCustomers')) {
          return Promise.resolve([
            { key: '2026-11-26', activeCustomers: 4n, activeDrivers: 2n },
            { key: '2026-11-27', activeCustomers: 3n, activeDrivers: 1n },
          ]);
        }
        if (sql.includes('driver_manager_wallet_transactions')) {
          return Promise.resolve([
            // e.g. DELIVERY_SHARE (+12) + BRONZE_PENALTY (-3) = 9
            { key: '2026-11-26', totalDriverManagerEarnings: 9n },
            { key: '2026-11-27', totalDriverManagerEarnings: 6n },
          ]);
        }
        if (sql.includes('totalServiceFees')) {
          return Promise.resolve([
            { key: '2026-11-26', totalServiceFees: 10n },
          ]);
        }
        return Promise.resolve([]);
      }),
    };

    const repo = new StatisticsAnalyticsRepository(prisma);
    const result = await repo.getAppStats(
      StatisticPeriod.DAILY,
      30,
      '2026-11-26',
      '2026-11-27',
    );

    const managerSql = executedSql.find((s) =>
      s.includes('driver_manager_wallet_transactions'),
    );
    expect(managerSql).toContain("'DELIVERY_SHARE'");
    expect(managerSql).toContain("'BRONZE_PENALTY'");

    const serviceFeeSql = executedSql.find((s) =>
      s.includes('totalServiceFees'),
    );
    expect(serviceFeeSql).toContain("o.status = 'DELIVERED'");
    expect(serviceFeeSql).toContain('o."deletedAt" IS NULL');
    expect(serviceFeeSql).toContain('o."serviceFee"');

    expect(result).toHaveLength(2);
    expect(result[0]).toMatchObject({
      totalOrders: 5,
      totalAdminRevenue: 57,
      totalDeliveryFees: 120,
      totalVendorCommissions: 30,
      totalDriverEarnings: 94,
      totalDriverManagerEarnings: 9,
      totalDeliveryProfit: 17,
      activeCustomers: 4,
      activeDrivers: 2,
    });
    expect(result[1]).toMatchObject({
      totalOrders: 3,
      totalAdminRevenue: 25,
      totalDeliveryFees: 75,
      totalVendorCommissions: 15,
      totalDriverEarnings: 59,
      totalDriverManagerEarnings: 6,
      totalDeliveryProfit: 10,
      activeCustomers: 3,
      activeDrivers: 1,
    });
  });

  it('aggregates multiple DAILY rows into a single MONTHLY bucket accurately', async () => {
    const day1 = new Date('2026-11-05T00:00:00.000Z');
    const day2 = new Date('2026-11-20T00:00:00.000Z');

    const prisma: any = {
      appStatistic: {
        findMany: jest.fn().mockResolvedValue([
          {
            period: StatisticPeriod.DAILY,
            startDate: day1,
            endDate: day1,
            totalOrders: 10,
            totalAdminRevenue: 100,
            totalDeliveryFees: 200,
          },
          {
            period: StatisticPeriod.DAILY,
            startDate: day2,
            endDate: day2,
            totalOrders: 8,
            totalAdminRevenue: 80,
            totalDeliveryFees: 160,
          },
        ]),
      },
      vendorStatistic: {
        findMany: jest.fn().mockResolvedValue([
          { startDate: day1, totalCommission: 40 },
          { startDate: day2, totalCommission: 25 },
        ]),
      },
      driverStatistic: {
        findMany: jest.fn().mockResolvedValue([
          { startDate: day1, totalEarnings: 140 },
          { startDate: day2, totalEarnings: 92 },
        ]),
      },
      $queryRaw: jest.fn().mockImplementation((query: unknown) => {
        const sql = flattenRawQuery(query);
        if (sql.includes('activeCustomers')) {
          return Promise.resolve([
            { key: '2026-11-01', activeCustomers: 12n, activeDrivers: 5n },
          ]);
        }
        if (sql.includes('driver_manager_wallet_transactions')) {
          return Promise.resolve([
            { key: '2026-11-01', totalDriverManagerEarnings: 28n },
          ]);
        }
        if (sql.includes('totalServiceFees')) {
          return Promise.resolve([
            { key: '2026-11-01', totalServiceFees: 15n },
          ]);
        }
        return Promise.resolve([]);
      }),
    };

    const repo = new StatisticsAnalyticsRepository(prisma);
    const result = await repo.getAppStats(
      StatisticPeriod.MONTHLY,
      12,
      '2026-11-01',
      '2026-11-30',
    );

    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      period: StatisticPeriod.MONTHLY,
      totalOrders: 18,
      totalAdminRevenue: 180,
      totalDeliveryFees: 360,
      totalVendorCommissions: 65,
      totalDriverEarnings: 232,
      totalDriverManagerEarnings: 28,
      // 180 - 65 - 15 = 100
      totalDeliveryProfit: 100,
      activeCustomers: 12,
      activeDrivers: 5,
    });
  });
});
