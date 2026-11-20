import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DriverShiftStatus,
  DriverStatus,
  Prisma,
  Role,
  SwapRequestStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { DriverErrors } from 'src/common/constants/response.constants';
import { assertDriverManagerOwnsDriver } from 'src/common/drivers/driver-manager-auth.helper';
import {
  AuditLogCreatedEvent,
  DriverStatusChangedEvent,
  ShiftAssignedEvent,
  ShiftDisabledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { DriverShiftAttendanceService } from './driver-shift-attendance.service';
import { DriverShiftPoolsService } from './driver-shift-pools.service';
import { DriverShiftSwapWaitlistService } from './driver-shift-swap-waitlist.service';
import {
  AdminAssignShiftDto,
  AdminBookWeeklyShiftsDto,
  AdminBulkAssignShiftsDto,
  AdminBulkRemoveShiftsDto,
  BookOvertimeShiftDto,
  BookWeeklyShiftsDto,
  ExcuseDriverShiftDto,
  GenerateShiftPoolsDto,
  QueryShiftPoolsDto,
} from './dto/driver-shifts.dto';

@Injectable()
export class DriverShiftsService {
  private readonly poolsService: DriverShiftPoolsService;
  private readonly swapWaitlistService: DriverShiftSwapWaitlistService;
  private readonly attendanceService: DriverShiftAttendanceService;

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    @Optional() poolsService?: DriverShiftPoolsService,
    @Optional() swapWaitlistService?: DriverShiftSwapWaitlistService,
    @Optional() attendanceService?: DriverShiftAttendanceService,
  ) {
    this.poolsService =
      poolsService ??
      new DriverShiftPoolsService(this.prisma, this.platformSettings);
    this.swapWaitlistService =
      swapWaitlistService ??
      new DriverShiftSwapWaitlistService(
        this.prisma,
        this.platformSettings,
        this.eventEmitter,
      );
    this.attendanceService =
      attendanceService ??
      new DriverShiftAttendanceService(
        this.prisma,
        this.platformSettings,
        this.eventEmitter,
      );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIFT POOLS (Delegated to DriverShiftPoolsService)
  // ═══════════════════════════════════════════════════════════════════════════

  generateShiftPools(dto: GenerateShiftPoolsDto) {
    return this.poolsService.generateShiftPools(dto);
  }

  getShiftPools(dto: QueryShiftPoolsDto) {
    return this.poolsService.getShiftPools(dto);
  }

  terminateShiftPool(poolId: string) {
    return this.poolsService.terminateShiftPool(poolId);
  }

  getAvailablePools(zoneId?: string) {
    return this.poolsService.getAvailablePools(zoneId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN SHIFT ASSIGNMENT & TEARDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  private async assertManagesDriver(userId: string, driverId: string) {
    await assertDriverManagerOwnsDriver(this.prisma, userId, driverId);
  }

  async adminAssignShift(dto: AdminAssignShiftDto, actor?: JwtAccessPayload) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, dto.driverId);
    }
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

    if (existing) {
      throw new BadRequestException(DriverErrors.ALREADY_ASSIGNED_TO_POOL);
    }

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

  async adminAssignShiftBulk(
    dto: AdminBulkAssignShiftsDto,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, dto.driverId);
    }
    const shiftPoolIds = [...new Set(dto.shiftPoolIds)];
    if (shiftPoolIds.length !== dto.shiftPoolIds.length) {
      throw new BadRequestException(DriverErrors.SHIFT_POOL_IDS_MUST_BE_UNIQUE);
    }

    const driver = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: { id: true, userId: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const sortedLockPoolIds = [...shiftPoolIds].sort();
    const assignments = await this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id IN (${Prisma.join(sortedLockPoolIds)}) FOR UPDATE`;

      const pools = await tx.shiftPool.findMany({
        where: { id: { in: shiftPoolIds } },
        include: { _count: { select: { driverShifts: true } } },
      });
      if (pools.length !== shiftPoolIds.length) {
        throw new NotFoundException(DriverErrors.SHIFT_POOL_MISSING);
      }

      const existing = await tx.driverShift.findMany({
        where: { driverId: driver.id, shiftPoolId: { in: shiftPoolIds } },
        select: { shiftPoolId: true },
      });
      const alreadyAssigned = new Set(
        existing.map((shift) => shift.shiftPoolId),
      );
      const pendingPools = pools.filter(
        (pool) => !alreadyAssigned.has(pool.id),
      );

      for (const pool of pendingPools) {
        if (pool._count.driverShifts >= pool.maxDrivers) {
          throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
        }
      }

      if (pendingPools.length === 0) return [];

      const created = pendingPools.map((pool) => ({
        id: randomUUID(),
        driverId: driver.id,
        shiftPoolId: pool.id,
        zoneId: pool.zoneId,
        shiftDate: pool.shiftDate,
        startTime: pool.startTime,
        endTime: pool.endTime,
      }));

      await tx.driverShift.createMany({ data: created });
      await tx.shiftPoolWaitlist.deleteMany({
        where: { driverId: driver.id, shiftPoolId: { in: shiftPoolIds } },
      });
      return created;
    });

    for (const shift of assignments) {
      this.eventEmitter.emit(
        EVENTS.SHIFT_ASSIGNED,
        new ShiftAssignedEvent(driver.userId, shift.id),
      );
    }

    return {
      success: true,
      assigned: assignments.length,
      alreadyAssigned: shiftPoolIds.length - assignments.length,
    };
  }

  async adminRemoveDriverBulk(
    dto: AdminBulkRemoveShiftsDto,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, dto.driverId);
    }
    const shiftPoolIds = [...new Set(dto.shiftPoolIds)];
    if (shiftPoolIds.length !== dto.shiftPoolIds.length) {
      throw new BadRequestException(DriverErrors.SHIFT_POOL_IDS_MUST_BE_UNIQUE);
    }

    const driver = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: { id: true, userId: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const sortedLockPoolIds = [...shiftPoolIds].sort();
    const txResult = await this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id IN (${Prisma.join(sortedLockPoolIds)}) FOR UPDATE`;

      const pools = await tx.shiftPool.findMany({
        where: { id: { in: shiftPoolIds } },
        select: { id: true },
      });
      if (pools.length !== shiftPoolIds.length) {
        throw new NotFoundException(DriverErrors.SHIFT_POOL_MISSING);
      }

      const txDriver = await tx.driver.findUnique({
        where: { id: driver.id },
        select: { id: true, userId: true, status: true },
      });
      if (!txDriver) {
        throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
      }

      const shifts = await tx.driverShift.findMany({
        where: { driverId: driver.id, shiftPoolId: { in: shiftPoolIds } },
        select: { id: true, shiftPoolId: true, status: true },
      });

      const removable = shifts.filter(
        (s) =>
          s.status === DriverShiftStatus.SCHEDULED ||
          s.status === DriverShiftStatus.ACTIVE ||
          s.status === DriverShiftStatus.CANCELLED,
      );
      const skippedHistorical = shifts.length - removable.length;

      const activeShifts = removable.filter(
        (s) => s.status === DriverShiftStatus.ACTIVE,
      );
      if (
        activeShifts.length > 0 &&
        txDriver.status === DriverStatus.ON_DELIVERY
      ) {
        throw new BadRequestException(
          DriverErrors.CANNOT_END_WHILE_ON_DELIVERY,
        );
      }

      if (removable.length === 0) {
        return {
          removed: [] as { id: string; shiftPoolId: string | null }[],
          skippedHistorical,
          previousStatus: null as DriverStatus | null,
        };
      }

      let previousStatus: DriverStatus | null = null;
      if (
        activeShifts.length > 0 &&
        txDriver.status !== DriverStatus.OFFLINE &&
        txDriver.status !== DriverStatus.SUSPENDED
      ) {
        previousStatus = txDriver.status;
        await tx.driver.update({
          where: { id: driver.id },
          data: { status: DriverStatus.OFFLINE },
        });
      }

      const removableIds = removable.map((s) => s.id);

      await tx.shiftSwapRequest.updateMany({
        where: {
          driverShiftId: { in: removableIds },
          status: SwapRequestStatus.PENDING,
        },
        data: { status: SwapRequestStatus.CANCELLED },
      });

      await tx.driverShift.deleteMany({
        where: { id: { in: removableIds } },
      });

      return {
        removed: removable.map((s) => ({
          id: s.id,
          shiftPoolId: s.shiftPoolId,
        })),
        skippedHistorical,
        previousStatus,
      };
    });

    if (txResult.previousStatus !== null) {
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          driver.id,
          driver.userId,
          txResult.previousStatus,
          DriverStatus.OFFLINE,
          'Removed from shift group by admin.',
        ),
      );
    }

    if (txResult.removed.length > 0) {
      this.eventEmitter.emit(
        EVENTS.SHIFT_DISABLED,
        new ShiftDisabledEvent(
          driver.userId,
          txResult.removed[0].id,
          'admin',
          txResult.removed.length,
        ),
      );

      const freedPoolIds = [
        ...new Set(
          txResult.removed
            .map((s) => s.shiftPoolId)
            .filter((id): id is string => Boolean(id)),
        ),
      ];
      for (const poolId of freedPoolIds) {
        await this.promoteFromWaitlist(poolId);
      }
    }

    return {
      success: true,
      removed: txResult.removed.length,
      skippedHistorical: txResult.skippedHistorical,
    };
  }

  async adminBookWeeklyShifts(
    dto: AdminBookWeeklyShiftsDto,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, dto.driverId);
    }
    const driver = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    return this.bookWeeklyShiftsForDriver(dto.driverId, dto.shiftPoolIds);
  }

  async removeDriverFromShift(shiftId: string, actor?: JwtAccessPayload) {
    const shift = await this.prisma.driverShift.findUnique({
      where: { id: shiftId },
      include: {
        driver: { include: { user: true } },
        swapRequests: { where: { status: SwapRequestStatus.PENDING } },
      },
    });

    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, shift.driverId);
    }

    if (
      shift.status === DriverShiftStatus.COMPLETED ||
      shift.status === DriverShiftStatus.MISSED
    ) {
      throw new BadRequestException(DriverErrors.CANNOT_REMOVE_HISTORICAL_SHIFT);
    }

    if (shift.status === DriverShiftStatus.ACTIVE) {
      if (shift.driver.status === DriverStatus.ON_DELIVERY) {
        throw new BadRequestException(
          DriverErrors.CANNOT_END_WHILE_ON_DELIVERY,
        );
      }
      if (
        shift.driver.status !== DriverStatus.OFFLINE &&
        shift.driver.status !== DriverStatus.SUSPENDED
      ) {
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

  async excuseShift(
    shiftId: string,
    actor: JwtAccessPayload,
    dto: ExcuseDriverShiftDto,
  ) {
    const shift = await this.prisma.driverShift.findUnique({
      where: { id: shiftId },
      select: {
        id: true,
        driverId: true,
        status: true,
        isExcused: true,
        excuseReason: true,
      },
    });
    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);
    if (actor.role === Role.DRIVER_MANAGER) {
      await this.assertManagesDriver(actor.sub, shift.driverId);
    }

    const updated = await this.prisma.driverShift.update({
      where: { id: shiftId },
      data: dto.isExcused
        ? {
            isExcused: true,
            excuseReason: dto.excuseReason?.trim() || null,
            excusedByUserId: actor.sub,
            excusedAt: new Date(),
          }
        : {
            isExcused: false,
            excuseReason: null,
            excusedByUserId: null,
            excusedAt: null,
          },
    });

    this.eventEmitter.emit(
      EVENTS.AUDIT_LOG_CREATED,
      new AuditLogCreatedEvent(
        actor.sub,
        null,
        null,
        'UPDATE',
        'EXCUSE_DRIVER_SHIFT',
        'DriverShift',
        shiftId,
        {
          isExcused: updated.isExcused,
          excuseReason: updated.excuseReason,
        },
        {
          isExcused: shift.isExcused,
          excuseReason: shift.excuseReason,
        },
      ),
    );

    return updated;
  }

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
      (s) =>
        s.status === DriverShiftStatus.ACTIVE &&
        s.driver.status !== DriverStatus.OFFLINE &&
        s.driver.status !== DriverStatus.SUSPENDED,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DRIVER BOOKING
  // ═══════════════════════════════════════════════════════════════════════════

  async checkShiftsEnabled() {
    return this.poolsService.checkShiftsEnabled();
  }

  async bookWeeklyShifts(userId: string, dto: BookWeeklyShiftsDto) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return this.bookWeeklyShiftsForDriver(driver.id, dto.shiftPoolIds);
  }

  async bookWeeklyShiftsForDriver(driverId: string, shiftPoolIds: string[]) {
    await this.checkShiftsEnabled();

    if (shiftPoolIds.length !== 6) {
      throw new BadRequestException(DriverErrors.INVALID_WEEKLY_SHIFTS);
    }

    const sortedLockPoolIds = [...shiftPoolIds].sort();
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id IN (${Prisma.join(sortedLockPoolIds)}) FOR UPDATE`;

      const pools = await tx.shiftPool.findMany({
        where: { id: { in: shiftPoolIds } },
        include: { _count: { select: { driverShifts: true } } },
      });

      if (pools.length !== 6) {
        throw new BadRequestException(DriverErrors.SHIFT_POOL_MISSING);
      }

      const coveredDays = new Set<number>();
      for (const pool of pools) {
        if (pool._count.driverShifts >= pool.maxDrivers) {
          throw new BadRequestException(DriverErrors.SHIFT_POOL_FULL);
        }
        coveredDays.add(pool.shiftDate.getUTCDay());
      }

      if (coveredDays.size !== 6) {
        throw new BadRequestException(DriverErrors.SHIFTS_MUST_SPAN_6_DAYS);
      }

      if (!coveredDays.has(4)) {
        throw new BadRequestException(DriverErrors.CANNOT_TAKE_THURSDAY_OFF);
      }
      if (!coveredDays.has(5)) {
        throw new BadRequestException(DriverErrors.CANNOT_TAKE_FRIDAY_OFF);
      }

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

      await tx.shiftPoolWaitlist.deleteMany({
        where: { driverId, shiftPoolId: { in: shiftPoolIds } },
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

      await tx.shiftPoolWaitlist.deleteMany({
        where: { driverId, shiftPoolId: pool.id },
      });

      return shift;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SWAP BOARD & WAITLIST (Delegated to DriverShiftSwapWaitlistService)
  // ═══════════════════════════════════════════════════════════════════════════

  offerSwap(userId: string, shiftId: string) {
    return this.swapWaitlistService.offerSwap(userId, shiftId);
  }

  getSwapBoard(userId: string) {
    return this.swapWaitlistService.getSwapBoard(userId);
  }

  acceptSwap(userId: string, swapId: string) {
    return this.swapWaitlistService.acceptSwap(userId, swapId);
  }

  joinWaitlist(userId: string, poolId: string) {
    return this.swapWaitlistService.joinWaitlist(userId, poolId);
  }

  leaveWaitlist(userId: string, poolId: string) {
    return this.swapWaitlistService.leaveWaitlist(userId, poolId);
  }

  getPoolWaitlist(poolId: string) {
    return this.swapWaitlistService.getPoolWaitlist(poolId);
  }

  promoteFromWaitlist(poolId: string) {
    return this.swapWaitlistService.promoteFromWaitlist(poolId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE CRON JOBS (Delegated to DriverShiftAttendanceService)
  // ═══════════════════════════════════════════════════════════════════════════

  handle30MinShiftWarning() {
    return this.attendanceService.handle30MinShiftWarning();
  }

  handle5MinLateCheck() {
    return this.attendanceService.handle5MinLateCheck();
  }
}
