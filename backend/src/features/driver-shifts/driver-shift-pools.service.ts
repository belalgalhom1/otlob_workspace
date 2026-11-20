import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';
import { DriverShiftStatus, Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { DriverErrors } from 'src/common/constants/response.constants';
import {
  endOfUtcDateOnly,
  parseUtcDateOnly,
  wallToUtc,
} from 'src/common/utils/timezone';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  GenerateShiftPoolsDto,
  QueryShiftPoolsDto,
} from './dto/driver-shifts.dto';

const MAX_GENERATE_SHIFT_POOL_RANGE_MS = 366 * 24 * 60 * 60 * 1000;

@Injectable()
export class DriverShiftPoolsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async checkShiftsEnabled(): Promise<void> {
    const settings = await this.platformSettings.getSettings();
    if (!settings.driverShiftsEnabled) {
      throw new BadRequestException(DriverErrors.SHIFTS_DISABLED);
    }
  }

  async generateShiftPools(dto: GenerateShiftPoolsDto) {
    let current = parseUtcDateOnly(dto.startDate);
    const end = parseUtcDateOnly(dto.endDate);

    if (
      Number.isNaN(current.getTime()) ||
      Number.isNaN(end.getTime()) ||
      current > end ||
      end.getTime() - current.getTime() > MAX_GENERATE_SHIFT_POOL_RANGE_MS
    ) {
      throw new BadRequestException(DriverErrors.INVALID_START_END_DATE);
    }

    const batchId = randomUUID();
    const pools: Prisma.ShiftPoolCreateManyInput[] = [];
    const [startHour, startMin] = dto.startTime.split(':').map(Number);
    const [endHour, endMin] = dto.endTime.split(':').map(Number);
    if (
      !Number.isFinite(startHour) ||
      !Number.isFinite(startMin) ||
      !Number.isFinite(endHour) ||
      !Number.isFinite(endMin)
    ) {
      throw new BadRequestException(DriverErrors.INVALID_START_END_DATE);
    }

    while (current <= end) {
      const curYear = current.getUTCFullYear();
      const curMonth = current.getUTCMonth() + 1;
      const curDay = current.getUTCDate();

      const shiftStart = wallToUtc(
        curYear,
        curMonth,
        curDay,
        startHour,
        startMin,
      );
      let shiftEnd = wallToUtc(curYear, curMonth, curDay, endHour, endMin);

      if (shiftEnd <= shiftStart) {
        shiftEnd = new Date(shiftEnd.getTime() + 24 * 60 * 60 * 1000);
      }

      pools.push({
        id: randomUUID(),
        batchId,
        title: dto.title?.trim() || null,
        titleAr: dto.titleAr?.trim() || null,
        zoneId:
          dto.zoneId && dto.zoneId.trim().length > 0 ? dto.zoneId.trim() : null,
        shiftDate: new Date(Date.UTC(curYear, curMonth - 1, curDay)),
        startTime: shiftStart,
        endTime: shiftEnd,
        maxDrivers: dto.maxDrivers,
        updatedAt: new Date(),
      });

      current = new Date(current.getTime() + 24 * 60 * 60 * 1000);
    }

    const created = await this.prisma.shiftPool.createMany({
      data: pools,
    });

    return { count: created.count };
  }

  async getShiftPools(dto: QueryShiftPoolsDto) {
    const where: Prisma.ShiftPoolWhereInput = {};
    if (dto.date) {
      where.shiftDate = {
        gte: parseUtcDateOnly(dto.date),
        lte: endOfUtcDateOnly(dto.date),
      };
    } else if (dto.startDate || dto.endDate) {
      where.shiftDate = {
        ...(dto.startDate ? { gte: parseUtcDateOnly(dto.startDate) } : {}),
        ...(dto.endDate ? { lte: endOfUtcDateOnly(dto.endDate) } : {}),
      };
    }
    if (dto.zoneId) where.zoneId = dto.zoneId;

    const page = dto.page;
    const limit = dto.limit;
    const usePaging = page !== undefined && limit !== undefined;

    const [total, pools] = await this.prisma.$transaction([
      this.prisma.shiftPool.count({ where }),
      this.prisma.shiftPool.findMany({
        where,
        include: {
          zone: true,
          driverShifts: {
            include: {
              driver: {
                select: {
                  id: true,
                  name: true,
                  avatar: true,
                  user: {
                    select: {
                      id: true,
                      name: true,
                      phone: true,
                      email: true,
                      avatar: true,
                    },
                  },
                },
              },
            },
          },
          _count: {
            select: { driverShifts: true, waitlist: true },
          },
        },
        orderBy: [
          { createdAt: 'desc' },
          { shiftDate: 'asc' },
          { startTime: 'asc' },
        ],
        ...(usePaging ? { skip: (page - 1) * limit, take: limit } : {}),
      }),
    ]);

    const items = pools.map((pool) => ({
      ...pool,
      bookedDrivers: pool._count.driverShifts,
      waitlistCount: pool._count.waitlist,
      isFull: pool._count.driverShifts >= pool.maxDrivers,
    }));

    return {
      items,
      total,
      page: page ?? 1,
      limit: limit ?? total,
      totalPages: usePaging ? Math.max(1, Math.ceil(total / limit)) : 1,
    };
  }

  async terminateShiftPool(poolId: string) {
    const shifts = await this.prisma.driverShift.findMany({
      where: { shiftPoolId: poolId },
      select: { id: true, status: true },
    });

    const assigned = shifts.filter(
      (s) =>
        s.status === DriverShiftStatus.SCHEDULED ||
        s.status === DriverShiftStatus.ACTIVE,
    );
    if (assigned.length > 0) {
      throw new BadRequestException(
        DriverErrors.CANNOT_DELETE_POOL_WITH_ASSIGNED_DRIVERS,
      );
    }

    const historicalShifts = shifts.filter(
      (s) =>
        s.status === DriverShiftStatus.COMPLETED ||
        s.status === DriverShiftStatus.MISSED,
    );
    const cancelledShifts = shifts.filter(
      (s) => s.status === DriverShiftStatus.CANCELLED,
    );

    if (cancelledShifts.length > 0) {
      await this.prisma.driverShift.deleteMany({
        where: { id: { in: cancelledShifts.map((s) => s.id) } },
      });
    }

    if (historicalShifts.length > 0) {
      await this.prisma.shiftPool.update({
        where: { id: poolId },
        data: { maxDrivers: 0 },
      });
      return {
        success: true,
        deleted: false,
        message:
          'Pool contained past completed shifts. It was disabled, and all active/future shifts were killed.',
      };
    }

    await this.prisma.shiftPool.delete({ where: { id: poolId } });
    return {
      success: true,
      deleted: true,
      message:
        'Shift pool completely deleted and all active drivers kicked offline.',
    };
  }

  async getAvailablePools(zoneId?: string) {
    await this.checkShiftsEnabled();

    const now = new Date();
    const pools = await this.prisma.shiftPool.findMany({
      where: {
        startTime: { gt: now },
        zoneId: zoneId || undefined,
      },
      include: {
        _count: { select: { driverShifts: true } },
        zone: true,
      },
      orderBy: { startTime: 'asc' },
    });

    return pools
      .filter((pool) => pool._count.driverShifts < pool.maxDrivers)
      .map((pool) => ({
        id: pool.id,
        batchId: pool.batchId,
        title: pool.title,
        titleAr: pool.titleAr,
        shiftDate: pool.shiftDate,
        startTime: pool.startTime,
        endTime: pool.endTime,
        zoneId: pool.zoneId,
        zone: pool.zone,
        maxDrivers: pool.maxDrivers,
        bookedDrivers: pool._count.driverShifts,
      }));
  }
}
