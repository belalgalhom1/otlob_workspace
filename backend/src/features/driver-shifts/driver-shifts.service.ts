import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { EVENTS } from 'src/common/events/event-names';
import {
  ShiftReminderEvent,
  ShiftMissedEvent,
  ShiftSwapCancelledEvent,
  ShiftDisabledEvent,
  ShiftAssignedEvent,
  ShiftSwapAcceptedEvent,
  ShiftSpotAvailableEvent,
  DriverStatusChangedEvent,
} from 'src/common/events';
import {
  GenerateShiftPoolsDto,
  BookWeeklyShiftsDto,
  BookOvertimeShiftDto,
  QueryShiftPoolsDto,
  AdminAssignShiftDto,
  UpdateShiftPoolDto,
  ShiftReportQueryDto,
} from './dto/driver-shifts.dto';
import { DriverErrors } from 'src/common/constants/response.constants';
import {
  DriverStatus,
  DriverShiftStatus,
  SwapRequestStatus,
  DriverTier,
  Prisma,
} from '@prisma/client';
import {
  endOfDay,
  startOfDay,
  getDay,
  parseISO,
} from 'date-fns';
import { wallToUtc, appTimeZone } from 'src/common/utils/timezone';
import { randomUUID } from 'crypto';

@Injectable()
export class DriverShiftsService {
  private readonly logger = new Logger(DriverShiftsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ADMIN SHIFT MANAGEMENT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  async generateShiftPools(dto: GenerateShiftPoolsDto) {
    const [sYear, sMonth, sDay] = dto.startDate.split('-').map(Number);
    const [eYear, eMonth, eDay] = dto.endDate.split('-').map(Number);
    let current = new Date(Date.UTC(sYear, sMonth - 1, sDay));
    const end = new Date(Date.UTC(eYear, eMonth - 1, eDay));

    if (current > end) {
      throw new BadRequestException(DriverErrors.INVALID_START_END_DATE);
    }

    // Every pool produced by this call shares one batch id so the apps can
    // present a multi-day generation as a single grouped shift.
    const batchId = randomUUID();
    const pools: any[] = [];
    const [startHour, startMin] = dto.startTime.split(':').map(Number);
    const [endHour, endMin] = dto.endTime.split(':').map(Number);

    while (current <= end) {
      const curYear = current.getUTCFullYear();
      const curMonth = current.getUTCMonth() + 1;
      const curDay = current.getUTCDate();

      // Compose wall-clock times in the app timezone from .env (NOT
      // server-local), otherwise every shift drifts by the UTC offset.
      const shiftStart = wallToUtc(
        curYear,
        curMonth,
        curDay,
        startHour,
        startMin,
      );
      let shiftEnd = wallToUtc(
        curYear,
        curMonth,
        curDay,
        endHour,
        endMin,
      );

      // Handle cross-midnight shifts
      if (shiftEnd <= shiftStart) {
        shiftEnd = new Date(shiftEnd.getTime() + 24 * 60 * 60 * 1000);
      }

      pools.push({
        id: randomUUID(),
        batchId,
        title: dto.title?.trim() || null,
        titleAr: dto.titleAr?.trim() || null,
        zoneId: dto.zoneId && dto.zoneId.trim().length > 0 ? dto.zoneId.trim() : null,
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
    const where: any = {};
    if (dto.date) {
      const targetDate = parseISO(dto.date);
      where.shiftDate = {
        gte: startOfDay(targetDate),
        lte: endOfDay(targetDate),
      };
    } else if (dto.startDate || dto.endDate) {
      where.shiftDate = {};
      if (dto.startDate) {
        where.shiftDate.gte = startOfDay(parseISO(dto.startDate));
      }
      if (dto.endDate) {
        where.shiftDate.lte = endOfDay(parseISO(dto.endDate));
      }
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

  async updateShiftPool(poolId: string, dto: UpdateShiftPoolDto) {
    const pool = await this.prisma.shiftPool.findUnique({
      where: { id: poolId },
      include: { _count: { select: { driverShifts: true } } },
    });
    if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);

    const data: Prisma.ShiftPoolUpdateInput = {};

    if (dto.title !== undefined) data.title = dto.title.trim() || null;
    if (dto.titleAr !== undefined) data.titleAr = dto.titleAr.trim() || null;

    if (dto.maxDrivers !== undefined) {
      if (dto.maxDrivers < pool._count.driverShifts) {
        throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
      }
      data.maxDrivers = dto.maxDrivers;
    }

    // Changing the window recomposes wall-clock times on the pool's own day and
    // propagates to every already-booked shift so drivers see the new hours.
    if (dto.startTime || dto.endTime) {
      const [sh, sm] = (dto.startTime ?? this.toHm(pool.startTime)).split(':').map(Number);
      const [eh, em] = (dto.endTime ?? this.toHm(pool.endTime)).split(':').map(Number);
      const day = pool.shiftDate;

      const shiftStart = wallToUtc(
        day.getUTCFullYear(),
        day.getUTCMonth() + 1,
        day.getUTCDate(),
        sh,
        sm,
      );
      let shiftEnd = wallToUtc(
        day.getUTCFullYear(),
        day.getUTCMonth() + 1,
        day.getUTCDate(),
        eh,
        em,
      );
      if (shiftEnd <= shiftStart) {
        shiftEnd = new Date(shiftEnd.getTime() + 24 * 60 * 60 * 1000);
      }
      data.startTime = shiftStart;
      data.endTime = shiftEnd;
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedPool = await tx.shiftPool.update({
        where: { id: poolId },
        data,
      });
      if (data.startTime && data.endTime) {
        await tx.driverShift.updateMany({
          where: { shiftPoolId: poolId },
          data: { startTime: data.startTime, endTime: data.endTime },
        });
      }
      return updatedPool;
    });

    // Raising capacity frees new seats — promote waitlisted drivers into them.
    if (dto.maxDrivers !== undefined && dto.maxDrivers > pool.maxDrivers) {
      await this.promoteFromWaitlist(poolId);
    }

    return updated;
  }

  private toHm(date: Date): string {
    // Reverse the app-timezone wall clock used at generation time.
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: appTimeZone(),
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(date);
    return parts.replace(/\u200E/g, '').trim();
  }

  async terminateShiftPool(poolId: string) {
    const shifts = await this.prisma.driverShift.findMany({
      where: { shiftPoolId: poolId },
      include: { driver: { include: { user: true } } },
    });

    // A pool with live bookings cannot be silently deleted. Require the admin
    // to remove the assigned drivers first so no shift vanishes underneath them.
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

    // COMPLETED or MISSED shifts must be preserved for history/earnings.
    const historicalShifts = shifts.filter(
      (s) => s.status === 'COMPLETED' || s.status === 'MISSED',
    );

    // ACTIVE, SCHEDULED, and CANCELLED shifts will be destroyed.
    const shiftsToKill = shifts.filter(
      (s) =>
        s.status === 'ACTIVE' ||
        s.status === 'SCHEDULED' ||
        s.status === 'CANCELLED',
    );

    if (shiftsToKill.length > 0) {
      // For any driver currently ACTIVE on this shift, force them OFFLINE —
      // but never a driver mid-delivery, matching the guard every other shift
      // teardown path honors.
      const activeShifts = shiftsToKill.filter((s) => s.status === 'ACTIVE');
      const onDelivery = activeShifts.find(
        (s) => s.driver.status === DriverStatus.ON_DELIVERY,
      );
      if (onDelivery) {
        throw new BadRequestException(
          DriverErrors.CANNOT_END_WHILE_ON_DELIVERY,
        );
      }

      if (activeShifts.length > 0) {
        await this.prisma.driver.updateMany({
          where: { id: { in: activeShifts.map((s) => s.driverId) } },
          data: { status: 'OFFLINE' },
        });

        for (const shift of activeShifts) {
          this.eventEmitter.emit(
            EVENTS.DRIVER_STATUS_CHANGED,
            new DriverStatusChangedEvent(
              shift.driverId,
              shift.driver.user.id,
              shift.driver.status,
              'OFFLINE',
              'Shift was forcefully deleted by admin.',
            ),
          );
        }
      }

      // Destroy the shifts
      await this.prisma.driverShift.deleteMany({
        where: { id: { in: shiftsToKill.map((s) => s.id) } },
      });

      // Notify the apps to remove the shift from UI
      for (const shift of shiftsToKill) {
        this.eventEmitter.emit(
          EVENTS.SHIFT_DISABLED,
          new ShiftDisabledEvent(shift.driver.user.id, shift.id),
        );
      }
    }

    if (historicalShifts.length > 0) {
      // Cannot completely delete the pool because of historical records. Just disable it.
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

    // No completed history exists, completely obliterate the pool.
    await this.prisma.shiftPool.delete({ where: { id: poolId } });
    return {
      success: true,
      deleted: true,
      message:
        'Shift pool completely deleted and all active drivers kicked offline.',
    };
  }

  async adminAssignShift(dto: AdminAssignShiftDto) {
    const pool = await this.prisma.shiftPool.findUnique({
      where: { id: dto.shiftPoolId },
      include: { _count: { select: { driverShifts: true } } },
    });

    if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);

    if (pool._count.driverShifts >= pool.maxDrivers) {
      throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
    }

    const existing = await this.prisma.driverShift.findFirst({
      where: {
        driverId: dto.driverId,
        shiftPoolId: dto.shiftPoolId,
      },
    });

    if (existing)
      throw new BadRequestException(DriverErrors.ALREADY_ASSIGNED_TO_POOL);

    const shift = await this.prisma.driverShift.create({
      data: {
        driverId: dto.driverId,
        shiftPoolId: pool.id,
        zoneId: pool.zoneId,
        shiftDate: pool.shiftDate,
        startTime: pool.startTime,
        endTime: pool.endTime,
      },
    });

    // Being assigned clears any waitlist entry the driver had for this pool.
    await this.prisma.shiftPoolWaitlist.deleteMany({
      where: { shiftPoolId: pool.id, driverId: dto.driverId },
    });

    const driver = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: { userId: true },
    });
    if (driver) {
      this.eventEmitter.emit(
        EVENTS.SHIFT_ASSIGNED,
        new ShiftAssignedEvent(driver.userId, shift.id),
      );
    }

    return shift;
  }

  // Remove a single driver from a single shift. Any shift may be removed
  // (SCHEDULED, ACTIVE, COMPLETED or MISSED). An ACTIVE driver is taken
  // offline unless they are mid-delivery, to avoid yanking them out from
  // under a live order; the shift is removed regardless.
  async removeDriverFromShift(shiftId: string) {
    const shift = await this.prisma.driverShift.findUnique({
      where: { id: shiftId },
      include: {
        driver: { include: { user: true } },
        swapRequests: { where: { status: SwapRequestStatus.PENDING } },
      },
    });

    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);

    if (shift.status === DriverShiftStatus.ACTIVE) {
      if (shift.driver.status !== DriverStatus.ON_DELIVERY) {
        await this.prisma.driver.update({
          where: { id: shift.driverId },
          data: { status: DriverStatus.OFFLINE },
        });

        this.eventEmitter.emit(
          EVENTS.DRIVER_STATUS_CHANGED,
          new DriverStatusChangedEvent(
            shift.driverId,
            shift.driver.user.id,
            shift.driver.status,
            DriverStatus.OFFLINE,
            'Removed from shift by admin.',
          ),
        );
      }
    }

    const pendingSwap = shift.swapRequests[0];
    if (pendingSwap) {
      await this.prisma.shiftSwapRequest.update({
        where: { id: pendingSwap.id },
        data: { status: SwapRequestStatus.CANCELLED },
      });
    }

    await this.prisma.driverShift.delete({ where: { id: shiftId } });

    this.eventEmitter.emit(
      EVENTS.SHIFT_DISABLED,
      new ShiftDisabledEvent(shift.driver.user.id, shift.id),
    );

    if (shift.shiftPoolId) {
      await this.promoteFromWaitlist(shift.shiftPoolId);
    }

    return { success: true, removed: 1 };
  }

  // Remove every SCHEDULED/ACTIVE driver from a pool without deleting the pool,
  // freeing capacity for new bookings. Historical shifts are preserved and an
  // ACTIVE driver mid-delivery fails the whole operation to avoid a partial wipe.
  async removeAllDriversFromPool(poolId: string) {
    const pool = await this.prisma.shiftPool.findUnique({
      where: { id: poolId },
    });
    if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);

    const shifts = await this.prisma.driverShift.findMany({
      where: { shiftPoolId: poolId },
      include: { driver: { include: { user: true } } },
    });

    const removable = shifts.filter(
      (s) =>
        s.status === DriverShiftStatus.SCHEDULED ||
        s.status === DriverShiftStatus.ACTIVE,
    );

    const onDelivery = removable.find(
      (s) =>
        s.status === DriverShiftStatus.ACTIVE &&
        s.driver.status === DriverStatus.ON_DELIVERY,
    );
    if (onDelivery) {
      throw new BadRequestException(DriverErrors.CANNOT_END_WHILE_ON_DELIVERY);
    }

    if (removable.length === 0) {
      return { success: true, removed: 0, poolId };
    }

    const activeShifts = removable.filter(
      (s) => s.status === DriverShiftStatus.ACTIVE,
    );
    if (activeShifts.length > 0) {
      await this.prisma.driver.updateMany({
        where: { id: { in: activeShifts.map((s) => s.driverId) } },
        data: { status: DriverStatus.OFFLINE },
      });

      for (const shift of activeShifts) {
        this.eventEmitter.emit(
          EVENTS.DRIVER_STATUS_CHANGED,
          new DriverStatusChangedEvent(
            shift.driverId,
            shift.driver.user.id,
            shift.driver.status,
            DriverStatus.OFFLINE,
            'Removed from shift pool by admin.',
          ),
        );
      }
    }

    await this.prisma.shiftSwapRequest.updateMany({
      where: {
        driverShiftId: { in: removable.map((s) => s.id) },
        status: SwapRequestStatus.PENDING,
      },
      data: { status: SwapRequestStatus.CANCELLED },
    });

    await this.prisma.driverShift.deleteMany({
      where: { id: { in: removable.map((s) => s.id) } },
    });

    for (const shift of removable) {
      this.eventEmitter.emit(
        EVENTS.SHIFT_DISABLED,
        new ShiftDisabledEvent(shift.driver.user.id, shift.id),
      );
    }

    await this.promoteFromWaitlist(poolId);

    return { success: true, removed: removable.length, poolId };
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DRIVER BOOKING
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  async checkShiftsEnabled() {
    const settings = await this.platformSettings.getSettings();
    if (!settings.driverShiftsEnabled) {
      throw new BadRequestException(DriverErrors.SHIFTS_DISABLED);
    }
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

  async bookWeeklyShifts(userId: string, dto: BookWeeklyShiftsDto) {
    await this.checkShiftsEnabled();

    if (dto.shiftPoolIds.length !== 6) {
      throw new BadRequestException(DriverErrors.INVALID_WEEKLY_SHIFTS);
    }

    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const driverId = driver.id;

    return this.prisma.$transaction(async (tx) => {
      // Lock the shift pools to prevent race conditions during booking. The
      // IDs are bound as parameters (never string-interpolated) so a malicious
      // driver cannot inject SQL through shiftPoolIds.
      await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id IN (${Prisma.join(dto.shiftPoolIds)}) FOR UPDATE`;

      const pools = await tx.shiftPool.findMany({
        where: { id: { in: dto.shiftPoolIds } },
        include: { _count: { select: { driverShifts: true } } },
      });

      if (pools.length !== 6) {
        throw new BadRequestException(DriverErrors.SHIFT_POOL_MISSING);
      }

      // Check capacity and day constraint
      const coveredDays = new Set<number>();
      for (const pool of pools) {
        if (pool._count.driverShifts >= pool.maxDrivers) {
          throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
        }
        coveredDays.add(getDay(pool.shiftDate));
      }

      if (coveredDays.size !== 6) {
        throw new BadRequestException(DriverErrors.SHIFTS_MUST_SPAN_6_DAYS);
      }

      // Thursday (4) and Friday (5) cannot be the day off
      if (!coveredDays.has(4)) {
        throw new BadRequestException(DriverErrors.CANNOT_TAKE_THURSDAY_OFF);
      }
      if (!coveredDays.has(5)) {
        throw new BadRequestException(DriverErrors.CANNOT_TAKE_FRIDAY_OFF);
      }

      // Check for existing overlapping shifts
      const existing = await tx.driverShift.findFirst({
        where: {
          driverId,
          status: {
            in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
          },
          OR: pools.map((p) => ({
            AND: [
              { startTime: { lt: p.endTime } },
              { endTime: { gt: p.startTime } },
            ],
          })),
        },
      });

      if (existing) {
        throw new BadRequestException(DriverErrors.OVERLAPPING_SHIFT);
      }

      // Book them
      const creates = pools.map((pool) => ({
        id: randomUUID(),
        driverId,
        shiftPoolId: pool.id,
        zoneId: pool.zoneId,
        shiftDate: pool.shiftDate,
        startTime: pool.startTime,
        endTime: pool.endTime,
      }));

      await tx.driverShift.createMany({ data: creates });

      // Booking directly supersedes any waitlist entry for these pools.
      await tx.shiftPoolWaitlist.deleteMany({
        where: { driverId, shiftPoolId: { in: dto.shiftPoolIds } },
      });

      return { success: true, booked: creates.length };
    });
  }

  async bookOvertimeShift(userId: string, dto: BookOvertimeShiftDto) {
    await this.checkShiftsEnabled();

    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const driverId = driver.id;

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id = ${dto.shiftPoolId} FOR UPDATE`;

      const pool = await tx.shiftPool.findUnique({
        where: { id: dto.shiftPoolId },
        include: { _count: { select: { driverShifts: true } } },
      });

      if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);
      if (pool._count.driverShifts >= pool.maxDrivers) {
        throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
      }

      const existing = await tx.driverShift.findFirst({
        where: {
          driverId,
          status: {
            in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
          },
          startTime: { lt: pool.endTime },
          endTime: { gt: pool.startTime },
        },
      });

      if (existing) {
        throw new BadRequestException(DriverErrors.OVERLAPPING_SHIFT);
      }

      const shift = await tx.driverShift.create({
        data: {
          driverId,
          shiftPoolId: pool.id,
          zoneId: pool.zoneId,
          shiftDate: pool.shiftDate,
          startTime: pool.startTime,
          endTime: pool.endTime,
        },
      });

      // Booking directly supersedes any waitlist entry for this pool.
      await tx.shiftPoolWaitlist.deleteMany({
        where: { driverId, shiftPoolId: pool.id },
      });

      return shift;
    });
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SWAP BOARD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  async offerSwap(userId: string, shiftId: string) {
    await this.checkShiftsEnabled();

    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const driverId = driver.id;

    const shift = await this.prisma.driverShift.findUnique({
      where: { id: shiftId },
    });

    if (!shift || shift.driverId !== driverId) {
      throw new NotFoundException(DriverErrors.NOT_YOUR_SHIFT);
    }

    if (shift.status !== DriverShiftStatus.SCHEDULED) {
      throw new BadRequestException(DriverErrors.ONLY_SCHEDULED_SWAP);
    }

    const now = new Date();
    if (shift.startTime.getTime() - now.getTime() < 30 * 60 * 1000) {
      throw new BadRequestException(DriverErrors.SWAP_TOO_CLOSE);
    }

    const existingSwap = await this.prisma.shiftSwapRequest.findFirst({
      where: { driverShiftId: shiftId, status: SwapRequestStatus.PENDING },
    });

    if (existingSwap) {
      throw new BadRequestException(DriverErrors.ALREADY_ON_SWAP_BOARD);
    }

    return this.prisma.shiftSwapRequest.create({
      data: {
        driverShiftId: shiftId,
        offeredByDriverId: driverId,
      },
    });
  }

  async getSwapBoard(userId: string) {
    await this.checkShiftsEnabled();

    const me = await this.prisma.driver.findUnique({ where: { userId } });
    if (!me) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const driverId = me.id;

    return this.prisma.shiftSwapRequest.findMany({
      where: {
        status: SwapRequestStatus.PENDING,
        offeredByDriverId: { not: driverId },
        driverShift: {
          driver: { vehicleType: me.vehicleType },
          startTime: { gt: new Date() },
        },
      },
      include: {
        driverShift: {
          include: {
            driver: { select: { name: true, vehicleType: true } },
            zone: true,
          },
        },
      },
      orderBy: { driverShift: { startTime: 'asc' } },
    });
  }

  async acceptSwap(userId: string, swapId: string) {
    await this.checkShiftsEnabled();

    const me = await this.prisma.driver.findUnique({ where: { userId } });
    if (!me) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const driverId = me.id;

    // Everything is under one driver-row lock so two drivers accepting the
    // same swap (or one driver accepting while another shift is being booked)
    // are serialized. The guarded updateMany CAS means only one acceptor can
    // ever go from PENDING to ACCEPTED; the loser gets SWAP_NOT_AVAILABLE.
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      const swap = await tx.shiftSwapRequest.findUnique({
        where: { id: swapId },
        include: { driverShift: { include: { driver: true } } },
      });

      if (!swap || swap.status !== SwapRequestStatus.PENDING) {
        throw new BadRequestException(DriverErrors.SWAP_NOT_AVAILABLE);
      }

      if (swap.offeredByDriverId === driverId) {
        throw new BadRequestException(DriverErrors.CANNOT_ACCEPT_OWN_SWAP);
      }

      if (me.vehicleType !== swap.driverShift.driver.vehicleType) {
        throw new BadRequestException(DriverErrors.VEHICLE_MISMATCH);
      }

      // Check overlap against this driver's existing shifts
      const existing = await tx.driverShift.findFirst({
        where: {
          driverId,
          status: {
            in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
          },
          startTime: { lt: swap.driverShift.endTime },
          endTime: { gt: swap.driverShift.startTime },
        },
      });

      if (existing) {
        throw new BadRequestException(DriverErrors.OVERLAPPING_SHIFT);
      }

      // Mark the swap as accepted — CAS so a concurrent acceptor cannot win too
      const claimed = await tx.shiftSwapRequest.updateMany({
        where: { id: swapId, status: SwapRequestStatus.PENDING },
        data: { status: SwapRequestStatus.ACCEPTED },
      });
      if (claimed.count === 0) {
        throw new BadRequestException(DriverErrors.SWAP_NOT_AVAILABLE);
      }

      // Transfer shift
      return tx.driverShift.update({
        where: { id: swap.driverShiftId },
        data: { driverId },
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WAITLIST
  // ═══════════════════════════════════════════════════════════════════════════

  // A driver can only wait for a pool that is already full — a pool with free
  // seats should simply be booked. Joining is idempotent per (pool, driver).
  async joinWaitlist(userId: string, poolId: string) {
    await this.checkShiftsEnabled();

    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const pool = await this.prisma.shiftPool.findUnique({
      where: { id: poolId },
      include: { _count: { select: { driverShifts: true } } },
    });
    if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);

    if (pool.startTime <= new Date()) {
      throw new BadRequestException(DriverErrors.INVALID_START_END_DATE);
    }

    const existingShift = await this.prisma.driverShift.findFirst({
      where: { driverId: driver.id, shiftPoolId: poolId },
    });
    if (existingShift) {
      throw new BadRequestException(DriverErrors.ALREADY_ASSIGNED_TO_POOL);
    }

    if (pool._count.driverShifts < pool.maxDrivers) {
      throw new BadRequestException(DriverErrors.SHIFT_POOL_NOT_FULL);
    }

    await this.prisma.shiftPoolWaitlist.upsert({
      where: {
        shiftPoolId_driverId: { shiftPoolId: poolId, driverId: driver.id },
      },
      create: { shiftPoolId: poolId, driverId: driver.id },
      update: {},
    });

    return { success: true };
  }

  async leaveWaitlist(userId: string, poolId: string) {
    await this.checkShiftsEnabled();

    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    // Idempotent: leaving a waitlist you are not on is not an error.
    await this.prisma.shiftPoolWaitlist.deleteMany({
      where: { shiftPoolId: poolId, driverId: driver.id },
    });

    return { success: true };
  }

  async getPoolWaitlist(poolId: string) {
    const pool = await this.prisma.shiftPool.findUnique({
      where: { id: poolId },
    });
    if (!pool) throw new NotFoundException(DriverErrors.SHIFT_POOL_NOT_FOUND);

    const entries = await this.prisma.shiftPoolWaitlist.findMany({
      where: { shiftPoolId: poolId },
      orderBy: { createdAt: 'asc' },
      include: {
        driver: {
          select: {
            id: true,
            name: true,
            avatar: true,
            tier: true,
            user: { select: { id: true, name: true, phone: true } },
          },
        },
      },
    });

    return entries.map((entry, index) => ({
      id: entry.id,
      position: index + 1,
      joinedAt: entry.createdAt,
      driverId: entry.driverId,
      driver: entry.driver,
    }));
  }

  // Called whenever a seat frees in a pool (driver removed, capacity raised).
  // Promotes the oldest eligible waitlisted driver into the freed seat and
  // notifies them, skipping anyone who would overlap an existing shift.
  async promoteFromWaitlist(poolId: string) {
    try {
      const promoted = await this.prisma.$transaction(async (tx) => {
        // Serialize concurrent promotions on the same pool.
        await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id = ${poolId} FOR UPDATE`;

        const pool = await tx.shiftPool.findUnique({
          where: { id: poolId },
          include: { _count: { select: { driverShifts: true } } },
        });
        if (!pool) return null;
        if (pool._count.driverShifts >= pool.maxDrivers) return null;

        const entries = await tx.shiftPoolWaitlist.findMany({
          where: { shiftPoolId: poolId },
          orderBy: { createdAt: 'asc' },
          include: { driver: { select: { id: true, userId: true } } },
        });

        for (const entry of entries) {
          const alreadyBooked = await tx.driverShift.findFirst({
            where: { driverId: entry.driverId, shiftPoolId: poolId },
          });
          if (alreadyBooked) {
            await tx.shiftPoolWaitlist.delete({ where: { id: entry.id } });
            continue;
          }

          const overlapping = await tx.driverShift.findFirst({
            where: {
              driverId: entry.driverId,
              status: {
                in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
              },
              startTime: { lt: pool.endTime },
              endTime: { gt: pool.startTime },
            },
          });
          if (overlapping) continue;

          const shift = await tx.driverShift.create({
            data: {
              driverId: entry.driverId,
              shiftPoolId: pool.id,
              zoneId: pool.zoneId,
              shiftDate: pool.shiftDate,
              startTime: pool.startTime,
              endTime: pool.endTime,
            },
          });

          await tx.shiftPoolWaitlist.delete({ where: { id: entry.id } });

          return { shiftId: shift.id, driverUserId: entry.driver.userId };
        }

        return null;
      });

      if (promoted) {
        this.eventEmitter.emit(
          EVENTS.SHIFT_SPOT_AVAILABLE,
          new ShiftSpotAvailableEvent(promoted.driverUserId, poolId),
        );
      }
    } catch (e) {
      this.logger.error('Failed to promote from waitlist', e);
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ATTENDANCE CRON JOBS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  async handle30MinShiftWarning() {
    try {
      const settings = await this.platformSettings.getSettings();
      if (!settings.driverShiftsEnabled) return;

      const now = new Date();
      const in30Mins = new Date(now.getTime() + 30 * 60 * 1000);

      // Find shifts starting in <= 30 mins that haven't been warned.
        // Bounded per tick so backlogs drain over successive runs instead of
        // overlapping the next tick.
      const upcomingShifts = await this.prisma.driverShift.findMany({
        where: {
          status: DriverShiftStatus.SCHEDULED,
          warningSent: false,
          startTime: { lte: in30Mins },
        },
        include: { driver: { include: { user: true } }, swapRequests: true },
        take: 100,
        orderBy: { startTime: 'asc' },
      });

      for (const shift of upcomingShifts) {
        // CAS first: only the tick that flips warningSent notifies, so
        // overlapping runs never double-warn the same shift.
        const claimed = await this.prisma.driverShift.updateMany({
          where: { id: shift.id, warningSent: false },
          data: { warningSent: true },
        });
        if (claimed.count === 0) continue;

        // Cancel any pending swap request
        const pendingSwap = shift.swapRequests.find(
          (s) => s.status === SwapRequestStatus.PENDING,
        );
        if (pendingSwap) {
          await this.prisma.shiftSwapRequest.update({
            where: { id: pendingSwap.id },
            data: { status: SwapRequestStatus.CANCELLED },
          });

          this.eventEmitter.emit(
            EVENTS.SHIFT_SWAP_CANCELLED,
            new ShiftSwapCancelledEvent(shift.driver.user.id, shift.id),
          );
        } else {
          this.eventEmitter.emit(
            EVENTS.SHIFT_REMINDER,
            new ShiftReminderEvent(
              shift.driver.user.id,
              shift.id,
              shift.zoneId,
            ),
          );
        }
      }
    } catch (e) {
      this.logger.error('Failed in handle30MinShiftWarning', e);
    }
  }

  async handle5MinLateCheck() {
    try {
      const settings = await this.platformSettings.getSettings();
      if (!settings.driverShiftsEnabled) return;

      const now = new Date();
      const fiveMinsAgo = new Date(now.getTime() - 5 * 60 * 1000);

      // Find shifts that started > 5 mins ago and haven't been started.
      // Bounded per tick so backlogs drain over successive runs.
      const lateShifts = await this.prisma.driverShift.findMany({
        where: {
          status: DriverShiftStatus.SCHEDULED,
          startTime: { lte: fiveMinsAgo },
          actualStart: null,
        },
        include: { driver: { include: { user: true } } },
        take: 100,
        orderBy: { startTime: 'asc' },
      });

      for (const shift of lateShifts) {
        // CAS: only the tick that flips SCHEDULED -> MISSED demotes and
        // notifies, so overlapping runs never double-demote.
        const claimed = await this.prisma.driverShift.updateMany({
          where: { id: shift.id, status: DriverShiftStatus.SCHEDULED },
          data: { status: DriverShiftStatus.MISSED },
        });
        if (claimed.count === 0) continue;

        // Demote tier
        let newTier = shift.driver.tier;
        if (newTier === DriverTier.GOLD) newTier = DriverTier.SILVER;
        else if (newTier === DriverTier.SILVER) newTier = DriverTier.BRONZE;

        if (newTier !== shift.driver.tier) {
          await this.prisma.driver.update({
            where: { id: shift.driverId },
            data: { tier: newTier },
          });

          this.eventEmitter.emit(
            EVENTS.SHIFT_MISSED,
            new ShiftMissedEvent(shift.driver.user.id, shift.id, newTier),
          );
        }
      }
    } catch (e) {
      this.logger.error('Failed in handle5MinLateCheck', e);
    }
  }
}
