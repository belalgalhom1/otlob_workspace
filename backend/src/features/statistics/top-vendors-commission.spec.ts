import { StatisticsAnalyticsRepository } from './statistics-analytics.repository';

function flattenRawQuery(query: unknown): string {
  if (typeof query === 'string') return query;
  if (query && typeof query === 'object' && 'strings' in (query as any)) {
    return ((query as any).strings as string[]).join(' ? ');
  }
  return String(query);
}

describe('StatisticsAnalyticsRepository.getTopVendors commission support', () => {
  it('computes and returns totalCommission in date-filtered getTopVendors query', async () => {
    const executedSql: string[] = [];
    const prisma: any = {
      $queryRaw: jest
        .fn()
        .mockImplementationOnce((query: unknown) => {
          executedSql.push(flattenRawQuery(query));
          return Promise.resolve([
            {
              vendorId: 'v-1',
              totalOrders: 2,
              totalRevenue: 180,
              totalCommission: 18,
            },
            {
              vendorId: 'v-2',
              totalOrders: 1,
              totalRevenue: 90,
              totalCommission: 0,
            },
          ]);
        })
        .mockImplementationOnce((query: unknown) => {
          executedSql.push(flattenRawQuery(query));
          return Promise.resolve([
            { productId: 'p-1', vendorId: 'v-1', totalOrders: 3 },
          ]);
        }),
      vendor: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'v-1',
            storeName: 'Pharmacy One',
            storeNameAr: 'صيدلية واحد',
            logo: null,
            coverImage: null,
            walletBalance: 341,
            commissionRate: 10,
            isContracted: true,
          },
          {
            id: 'v-2',
            storeName: 'Non Contracted Store',
            storeNameAr: 'متجر غير متعاقد',
            logo: null,
            coverImage: null,
            walletBalance: 0,
            commissionRate: 10,
            isContracted: false,
          },
        ]),
      },
      product: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'p-1',
            name: 'Panadol',
            nameAr: 'بنادول',
            imageUrl: null,
          },
        ]),
      },
    };

    const repo = new StatisticsAnalyticsRepository(prisma);
    const result = await repo.getTopVendors(20, '2026-11-27', '2026-11-27');

    expect(executedSql[0]).toContain('AS "totalCommission"');
    expect(executedSql[0]).toContain('f."isContracted"');
    expect(executedSql[0]).toContain('f."commissionRate"');

    expect(result).toHaveLength(2);
    expect(result[0]).toMatchObject({
      id: 'v-1',
      totalOrders: 2,
      totalRevenue: 180,
      totalCommission: 18,
      commissionRate: 10,
      isContracted: true,
    });
    expect(result[1]).toMatchObject({
      id: 'v-2',
      totalOrders: 1,
      totalRevenue: 90,
      totalCommission: 0,
      isContracted: false,
    });
  });

  it('aggregates and returns totalCommission from vendor_statistics when no date range is provided', async () => {
    const executedSql: string[] = [];
    const prisma: any = {
      $queryRaw: jest
        .fn()
        .mockImplementationOnce((query: unknown) => {
          executedSql.push(flattenRawQuery(query));
          return Promise.resolve([
            {
              vendorId: 'v-1',
              totalOrders: 15,
              totalRevenue: 1500,
              totalCommission: 150,
            },
          ]);
        })
        .mockImplementationOnce(() => Promise.resolve([])),
      vendor: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'v-1',
            storeName: 'Burger House',
            storeNameAr: 'برجر هاوس',
            logo: '/media/logo.png',
            coverImage: null,
            walletBalance: 1350,
            commissionRate: 10,
            isContracted: true,
          },
        ]),
      },
      product: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    const repo = new StatisticsAnalyticsRepository(prisma);
    const result = await repo.getTopVendors(20);

    expect(executedSql[0]).toContain('FROM vendor_statistics');
    expect(executedSql[0]).toContain('SUM("totalCommission")');
    expect(result[0]).toMatchObject({
      id: 'v-1',
      totalOrders: 15,
      totalRevenue: 1500,
      totalCommission: 150,
    });
  });
});
