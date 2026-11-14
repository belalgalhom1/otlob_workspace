import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { Prisma, StatisticPeriod } from '@prisma/client';

/**
 * Write-side repository for statistics idempotency markers and atomic bucket
 * upserts. Read/analytics queries live in StatisticsAnalyticsRepository.
 */
@Injectable()
export class StatisticsRepository {
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
    return result === 1;
  }

  async purgeProcessingMarkers(olderThan: Date): Promise<number> {
    const result = await this.prisma.statProcessingMarker.deleteMany({
      where: { createdAt: { lt: olderThan } },
    });
    return result.count;
  }

  // ─── Vendor stats — atomic upsert ─────────────────────────────────────────

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
}
