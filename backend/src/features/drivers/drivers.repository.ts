import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  DriverStatus,
  DriverShiftStatus,
  Prisma,
  VehicleType,
  Role,
  WalletTransactionType,
} from '@prisma/client';
import { DriverErrors } from 'src/common/constants/response.constants';

@Injectable()
export class DriversRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(driverId: string) {
    return this.prisma.driver.findUnique({
      where: { id: driverId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
          },
        },
        managerAssignment: {
          include: {
            driverManager: {
              include: {
                user: { select: { id: true, name: true, email: true, phone: true } },
              },
            },
          },
        },
      },
    });
  }

  async findByUserId(userId: string) {
    return this.prisma.driver.findUnique({
      where: { userId },
    });
  }

  async findByUserIdWithUser(userId: string) {
    return this.prisma.driver.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
          },
        },
      },
    });
  }

  async create(data: {
    userId: string;
    name: string;
    nationalId?: string | null;
    licenseNumber?: string | null;
    vehicleType: string;
    vehiclePlate?: string | null;
  }) {
    return this.prisma.driver.create({
      data: {
        userId: data.userId,
        name: data.name,
        nationalId: data.nationalId ?? null,
        licenseNumber: data.licenseNumber ?? null,
        vehicleType: data.vehicleType as VehicleType,
        vehiclePlate: data.vehiclePlate ?? null,
        status: DriverStatus.OFFLINE,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
          },
        },
      },
    });
  }

  async update(driverId: string, data: Prisma.DriverUpdateInput) {
    return this.prisma.driver.update({
      where: { id: driverId },
      data,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
          },
        },
      },
    });
  }

  async updateStatus(driverId: string, status: DriverStatus) {
    return this.prisma.driver.update({
      where: { id: driverId },
      data: { status },
    });
  }

  async updateLastLocation(driverId: string, lng: number, lat: number) {
    await this.prisma.$executeRaw`
      UPDATE drivers
      SET
        "lastLocation" = ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326),
        "lastLocationUpdate" = NOW()
      WHERE id = ${driverId}
    `;
  }

  async updateAvatar(driverId: string, avatarUrl: string) {
    return this.prisma.driver.update({
      where: { id: driverId },
      data: { avatar: avatarUrl },
    });
  }

  async updateUserRole(userId: string, role: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { role: role as Role },
    });
  }

  async findAll(filters: {
    status?: DriverStatus;
    search?: string;
    zoneId?: string;
    driverIds?: string[];
    page: number;
    limit: number;
  }) {
    const { page, limit } = filters;
    const skip = (page - 1) * limit;

    const where: Prisma.DriverWhereInput = { deletedAt: null };
    if (filters.status) where.status = filters.status;
    if (filters.search) {
      const search = filters.search.trim();
      const matchingZones = await this.prisma.zone.findMany({
        where: {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { nameAr: { contains: search, mode: 'insensitive' } },
          ],
        },
        select: { id: true },
      });
      const matchingZoneIds = matchingZones.map((z) => z.id);

      let locationDriverIds: string[] = [];
      if (matchingZoneIds.length > 0) {
        const rows = await this.prisma.$queryRaw<Array<{ id: string }>>`
          SELECT DISTINCT d.id
          FROM drivers d
          JOIN zones z ON z.id IN (${Prisma.join(matchingZoneIds)})
          WHERE d."deletedAt" IS NULL
            AND d."lastLocation" IS NOT NULL
            AND ST_Covers(z.boundary, d."lastLocation")
        `;
        locationDriverIds = rows.map((r) => r.id);
      }

      // Match driver status keywords (English & Arabic)
      const driverStatusKeywords: Record<string, DriverStatus> = {
        online: DriverStatus.ONLINE,
        متصل: DriverStatus.ONLINE,
        متاح: DriverStatus.ONLINE,
        offline: DriverStatus.OFFLINE,
        'غير متصل': DriverStatus.OFFLINE,
        busy: DriverStatus.BUSY,
        مشغول: DriverStatus.BUSY,
        on_delivery: DriverStatus.ON_DELIVERY,
        delivery: DriverStatus.ON_DELIVERY,
        توصيل: DriverStatus.ON_DELIVERY,
        on_break: DriverStatus.ON_BREAK,
        break: DriverStatus.ON_BREAK,
        استراحة: DriverStatus.ON_BREAK,
        suspended: DriverStatus.SUSPENDED,
        معلق: DriverStatus.SUSPENDED,
        موقوف: DriverStatus.SUSPENDED,
      };
      const matchedDriverStatus = driverStatusKeywords[search.toLowerCase()];

      // Match shift status keywords (English & Arabic)
      const shiftStatusKeywords: Record<string, DriverShiftStatus> = {
        scheduled: DriverShiftStatus.SCHEDULED,
        مجدول: DriverShiftStatus.SCHEDULED,
        active: DriverShiftStatus.ACTIVE,
        نشط: DriverShiftStatus.ACTIVE,
        completed: DriverShiftStatus.COMPLETED,
        مكتمل: DriverShiftStatus.COMPLETED,
        cancelled: DriverShiftStatus.CANCELLED,
        ملغي: DriverShiftStatus.CANCELLED,
        missed: DriverShiftStatus.MISSED,
        فائت: DriverShiftStatus.MISSED,
      };
      const matchedShiftStatus = shiftStatusKeywords[search.toLowerCase()];
      const isShiftGenericWord = ['shift', 'shifts', 'شفت', 'شفتات'].includes(search.toLowerCase());

      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { vehiclePlate: { contains: search, mode: 'insensitive' } },
        ...(matchedDriverStatus ? [{ status: matchedDriverStatus }] : []),
        {
          shifts: {
            some: {
              OR: [
                {
                  zone: {
                    OR: [
                      { name: { contains: search, mode: 'insensitive' } },
                      { nameAr: { contains: search, mode: 'insensitive' } },
                    ],
                  },
                },
                {
                  shiftPool: {
                    OR: [
                      { title: { contains: search, mode: 'insensitive' } },
                      { titleAr: { contains: search, mode: 'insensitive' } },
                    ],
                  },
                },
                ...(matchedShiftStatus ? [{ status: matchedShiftStatus }] : []),
              ],
            },
          },
        },
        ...(isShiftGenericWord ? [{ shifts: { some: {} } }] : []),
        ...(locationDriverIds.length > 0 ? [{ id: { in: locationDriverIds } }] : []),
      ];
    }
    if (filters.zoneId && filters.zoneId.trim().length > 0) {
      const trimmedZoneId = filters.zoneId.trim();
      const zoneRows = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT DISTINCT d.id
        FROM drivers d
        LEFT JOIN driver_shifts s ON s."driverId" = d.id AND s."zoneId" = ${trimmedZoneId}
        CROSS JOIN zones z
        WHERE z.id = ${trimmedZoneId}
          AND d."deletedAt" IS NULL
          AND (
            s.id IS NOT NULL
            OR (
              d."lastLocation" IS NOT NULL
              AND ST_Covers(z.boundary, d."lastLocation")
            )
          )
      `;
      const zoneDriverIds = zoneRows.map((r) => r.id);
      where.id = { in: zoneDriverIds };
    }

    if (filters.driverIds) {
      if (where.id && (where.id as any).in) {
        const allowedSet = new Set(filters.driverIds);
        where.id = { in: (where.id as any).in.filter((id: string) => allowedSet.has(id)) };
      } else {
        where.id = { in: filters.driverIds };
      }
    }

    const [drivers, total] = await Promise.all([
      this.prisma.driver.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          user: { select: { id: true, name: true, email: true, phone: true } },
          managerAssignment: {
            include: {
              driverManager: {
                include: {
                  user: { select: { id: true, name: true, email: true, phone: true } },
                },
              },
            },
          },
        },
      }),
      this.prisma.driver.count({ where }),
    ]);

    return {
      drivers,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOneAdmin(driverId: string) {
    return this.prisma.driver.findUnique({
      where: { id: driverId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            isBanned: true,
          },
        },
        _count: { select: { orders: true, shifts: true } },
      },
    });
  }

  // ─── Shifts ───────────────────────────────────────────────────────────────

  async createShift(data: {
    driverId: string;
    zoneId: string | null;
    startTime: Date;
    endTime: Date;
  }) {
    return this.prisma.driverShift.create({
      data: {
        driverId: data.driverId,
        zoneId: data.zoneId,
        shiftDate: data.startTime,
        startTime: data.startTime,
        endTime: data.endTime,
        status: DriverShiftStatus.SCHEDULED,
      },
    });
  }

  async findShiftsByDriver(driverId: string) {
    const [upcoming, past] = await this.prisma.$transaction([
      this.prisma.driverShift.findMany({
        where: {
          driverId,
          status: {
            in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
          },
        },
        orderBy: { startTime: 'asc' },
        include: {
          zone: true,
          shiftPool: {
            select: { batchId: true, title: true, titleAr: true },
          },
        },
      }),
      this.prisma.driverShift.findMany({
        where: {
          driverId,
          status: {
            notIn: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
          },
        },
        orderBy: { startTime: 'desc' },
        take: 20,
        include: {
          zone: true,
          shiftPool: {
            select: { batchId: true, title: true, titleAr: true },
          },
        },
      }),
    ]);

    // Live/active shift is always listed first, then upcoming shifts by time,
    // with history below (stable sort keeps startTime ordering per group).
    upcoming.sort((a, b) => {
      const aActive = a.status === DriverShiftStatus.ACTIVE ? 1 : 0;
      const bActive = b.status === DriverShiftStatus.ACTIVE ? 1 : 0;
      return bActive - aActive;
    });

    return [...upcoming, ...past];
  }

  async findShiftById(shiftId: string, driverId: string) {
    return this.prisma.driverShift.findFirst({
      where: { id: shiftId, driverId },
    });
  }

  async findOverlappingShift(driverId: string, startTime: Date, endTime: Date) {
    return this.prisma.driverShift.findFirst({
      where: {
        driverId,
        status: { in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE] },
        OR: [{ startTime: { lte: endTime }, endTime: { gte: startTime } }],
      },
    });
  }

  async deleteShift(shiftId: string) {
    return this.prisma.driverShift.delete({ where: { id: shiftId } });
  }

  async updateShift(shiftId: string, data: Prisma.DriverShiftUpdateInput) {
    return this.prisma.driverShift.update({
      where: { id: shiftId },
      data,
    });
  }

  async endShiftSafely(shiftId: string, data: Prisma.DriverShiftUpdateInput) {
    return this.prisma.$transaction(async (tx) => {
      const result = await tx.driverShift.updateMany({
        where: { id: shiftId, status: DriverShiftStatus.ACTIVE },
        data,
      });

      if (result.count === 0) {
        throw new Error(DriverErrors.SHIFT_NOT_ACTIVE);
      }

      return tx.driverShift.findUnique({ where: { id: shiftId } });
    });
  }

  async startShiftSafely(shiftId: string, driverId: string) {
    return this.prisma.$transaction(async (tx) => {
      // Check for existing active shift
      const activeShift = await tx.driverShift.findFirst({
        where: { driverId, status: DriverShiftStatus.ACTIVE },
      });
      if (activeShift) {
        throw new Error(DriverErrors.ACTIVE_SHIFT_EXISTS);
      }

      const result = await tx.driverShift.updateMany({
        where: { id: shiftId, driverId, status: DriverShiftStatus.SCHEDULED },
        data: { status: DriverShiftStatus.ACTIVE, actualStart: new Date() },
      });

      if (result.count === 0) {
        return null;
      }

      return tx.driverShift.findUnique({ where: { id: shiftId } });
    });
  }

  async countDeliveredOrdersInShift(shiftId: string): Promise<number> {
    return this.prisma.order.count({
      where: { driverShiftId: shiftId, status: 'DELIVERED' },
    });
  }

  async sumShiftEarnings(shiftId: string): Promise<number> {
    const result = await this.prisma.driverWalletTransaction.aggregate({
      where: {
        driverShiftId: shiftId,
        type: { in: ['DELIVERY_FEE', 'BONUS'] },
      },
      _sum: { amount: true },
    });
    return Number(result._sum.amount ?? 0);
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  async getWalletTransactions(driverId: string, page: number, limit: number) {
    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.driverWalletTransaction.findMany({
        where: { driverId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          order: { select: { id: true, orderNumber: true } },
        },
      }),
      this.prisma.driverWalletTransaction.count({ where: { driverId } }),
    ]);

    return {
      transactions,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async creditWallet(
    driverId: string,
    amount: number,
    type: string,
    orderId: string | null,
    driverShiftId: string | null,
    description: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const driver = await tx.driver.update({
        where: { id: driverId },
        data: { walletBalance: { increment: amount } },
        select: { walletBalance: true },
      });

      await tx.driverWalletTransaction.create({
        data: {
          driverId,
          orderId,
          driverShiftId,
          type: type as WalletTransactionType,
          amount,
          balanceAfter: driver.walletBalance,
          description,
        },
      });

      return driver.walletBalance;
    });
  }

  // ─── Active order lookup for location broadcast ───────────────────────────

  async findActiveOrderForDriver(driverId: string) {
    return this.prisma.order.findFirst({
      where: {
        driverId,
        status: { in: ['DRIVER_ASSIGNED', 'PICKED_UP'] },
      },
      select: {
        id: true,
        customer: { select: { userId: true } },
      },
    });
  }

  // ─── Breaks ───────────────────────────────────────────────────────────────
  // State machine: PENDING (driver requested) → APPROVED (active break,
  // driver ON_BREAK) → ENDED. REJECTED (admin) / CANCELLED (driver/offline).

  async findActiveBreak(driverId: string) {
    return this.prisma.driverBreak.findFirst({
      where: { driverId, status: 'APPROVED', endedAt: null },
      orderBy: { startedAt: 'desc' },
    });
  }

  async findPendingBreak(driverId: string) {
    return this.prisma.driverBreak.findFirst({
      where: { driverId, status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findBreakById(breakId: string) {
    return this.prisma.driverBreak.findUnique({ where: { id: breakId } });
  }

  async findPendingBreaks(take = 50) {
    return this.prisma.driverBreak.findMany({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'asc' },
      take,
      include: {
        driver: {
          select: {
            id: true,
            name: true,
            vehicleType: true,
            status: true,
            user: { select: { name: true, phone: true } },
          },
        },
      },
    });
  }

  async findPendingDispatchForDriver(driverId: string) {
    return this.prisma.orderDispatch.findFirst({
      where: { driverId, status: 'PENDING' },
      select: { id: true },
    });
  }

  async findActiveShiftForDriver(driverId: string) {
    return this.prisma.driverShift.findFirst({
      where: { driverId, status: DriverShiftStatus.ACTIVE },
    });
  }

  async countShiftBreaks(shiftId: string) {
    return this.prisma.driverBreak.count({
      where: { shiftId, status: { in: ['APPROVED', 'ENDED'] } },
    });
  }

  async sumShiftBreakMinutes(shiftId: string) {
    const result = await this.prisma.driverBreak.aggregate({
      where: {
        shiftId,
        status: 'ENDED',
        durationMinutes: { not: null },
      },
      _sum: { durationMinutes: true },
    });
    return Number(result._sum.durationMinutes ?? 0);
  }

  async createBreak(data: {
    driverId: string;
    shiftId: string | null;
    reason: string;
    note?: string | null;
    requestedMinutes?: number | null;
  }) {
    return this.prisma.driverBreak.create({
      data: {
        driverId: data.driverId,
        shiftId: data.shiftId,
        reason: data.reason as any,
        note: data.note?.trim() ? data.note.trim() : null,
        requestedMinutes: data.requestedMinutes ?? null,
        status: 'PENDING',
      },
    });
  }

  async approveBreak(breakId: string, reviewerId: string, prevStatus: string) {
    const now = new Date();
    // Atomic: only a PENDING row flips. A concurrent reviewer gets count 0.
    const result = await this.prisma.driverBreak.updateMany({
      where: { id: breakId, status: 'PENDING' },
      data: {
        status: 'APPROVED',
        startedAt: now,
        prevStatus: prevStatus as any,
        reviewedById: reviewerId,
        reviewedAt: now,
      },
    });
    if (result.count === 0) return null;
    return this.prisma.driverBreak.findUnique({ where: { id: breakId } });
  }

  /**
   * Conditional ON_BREAK flip: succeeds only if the driver hasn't moved to
   * ON_DELIVERY/BUSY/SUSPENDED since validation (closes the approve race
   * where a driver accepts a dispatch mid-approval).
   */
  async flipDriverToBreak(driverId: string) {
    const result = await this.prisma.driver.updateMany({
      where: {
        id: driverId,
        status: { notIn: ['ON_DELIVERY', 'BUSY', 'SUSPENDED', 'ON_BREAK'] },
      },
      data: { status: 'ON_BREAK' },
    });
    return result.count > 0;
  }

  /** Reverts an APPROVED row back to PENDING (lost status-flip race). */
  async revertBreakToPending(breakId: string) {
    await this.prisma.driverBreak.updateMany({
      where: { id: breakId, status: 'APPROVED', endedAt: null },
      data: { status: 'PENDING', reviewedById: null, reviewedAt: null },
    });
  }

  async rejectBreak(breakId: string, reviewerId: string) {
    const now = new Date();
    const result = await this.prisma.driverBreak.updateMany({
      where: { id: breakId, status: 'PENDING' },
      data: {
        status: 'REJECTED',
        endedAt: now,
        reviewedById: reviewerId,
        reviewedAt: now,
      },
    });
    if (result.count === 0) return null;
    return this.prisma.driverBreak.findUnique({ where: { id: breakId } });
  }

  async cancelBreak(breakId: string) {
    const result = await this.prisma.driverBreak.updateMany({
      where: { id: breakId, status: 'PENDING' },
      data: { status: 'CANCELLED', endedAt: new Date() },
    });
    if (result.count === 0) return null;
    return this.prisma.driverBreak.findUnique({ where: { id: breakId } });
  }

  async endBreak(breakId: string, endedAt: Date, durationMinutes: number, autoEnded: boolean) {
    const result = await this.prisma.driverBreak.updateMany({
      where: { id: breakId, status: 'APPROVED', endedAt: null },
      data: { status: 'ENDED', endedAt, durationMinutes, autoEnded },
    });
    if (result.count === 0) return null;
    return this.prisma.driverBreak.findUnique({ where: { id: breakId } });
  }

  /** All open breaks for per-break limit evaluation (tiny set by design). */
  async findOpenBreaks() {
    return this.prisma.driverBreak.findMany({
      where: { status: 'APPROVED', endedAt: null },
      select: {
        id: true,
        driverId: true,
        shiftId: true,
        startedAt: true,
        requestedMinutes: true,
      },
    });
  }

  async findStalePendingBreaks(cutoff: Date) {
    return this.prisma.driverBreak.findMany({
      where: { status: 'PENDING', createdAt: { lte: cutoff } },
      select: { id: true },
    });
  }

  async findBreaksByDriver(driverId: string, take = 20) {
    return this.prisma.driverBreak.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
      take,
    });
  }

  async incrementShiftBreakMinutes(shiftId: string, minutes: number) {
    return this.prisma.driverShift.update({
      where: { id: shiftId },
      data: { breakMinutes: { increment: minutes } },
    });
  }
}