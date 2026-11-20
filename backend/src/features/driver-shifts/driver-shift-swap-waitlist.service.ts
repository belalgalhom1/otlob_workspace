import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DriverShiftStatus,
  SwapRequestStatus,
} from '@prisma/client';
import { DriverErrors } from 'src/common/constants/response.constants';
import { SHIFT_WARNING_WINDOW_MS } from 'src/common/drivers/driver-shift.helper';
import { ShiftSpotAvailableEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

@Injectable()
export class DriverShiftSwapWaitlistService {
  private readonly logger = new Logger(DriverShiftSwapWaitlistService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  private async checkShiftsEnabled(): Promise<void> {
    const settings = await this.platformSettings.getSettings();
    if (!settings.driverShiftsEnabled) {
      throw new BadRequestException(DriverErrors.SHIFTS_DISABLED);
    }
  }

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
    if (shift.startTime.getTime() - now.getTime() < SHIFT_WARNING_WINDOW_MS) {
      throw new BadRequestException(DriverErrors.SWAP_TOO_CLOSE);
    }

    const existingSwap = await this.prisma.shiftSwapRequest.findFirst({
      where: { driverShiftId: shiftId },
    });

    if (existingSwap?.status === SwapRequestStatus.PENDING) {
      throw new BadRequestException(DriverErrors.ALREADY_ON_SWAP_BOARD);
    }

    // `driverShiftId` is @unique on ShiftSwapRequest; if a prior swap on this
    // shift was ACCEPTED or CANCELLED, reopen it cleanly instead of failing with P2002.
    if (
      existingSwap &&
      typeof this.prisma.shiftSwapRequest.update === 'function'
    ) {
      return this.prisma.shiftSwapRequest.update({
        where: { id: existingSwap.id },
        data: {
          offeredByDriverId: driverId,
          status: SwapRequestStatus.PENDING,
        },
      });
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
          status: DriverShiftStatus.SCHEDULED,
          driver: { vehicleType: me.vehicleType },
          startTime: { gt: new Date() },
        },
      },
      include: {
        driverShift: {
          include: {
            driver: {
              select: {
                name: true,
                avatar: true,
                vehicleType: true,
                user: { select: { avatar: true } },
              },
            },
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

    return this.prisma.$transaction(async (tx) => {
      if (typeof tx.$executeRaw === 'function') {
        await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;
      }

      const swap = await tx.shiftSwapRequest.findUnique({
        where: { id: swapId },
        include: { driverShift: { include: { driver: true } } },
      });

      if (
        !swap ||
        swap.status !== SwapRequestStatus.PENDING ||
        swap.driverShift.status !== DriverShiftStatus.SCHEDULED ||
        swap.driverShift.startTime <= new Date()
      ) {
        throw new BadRequestException(DriverErrors.SWAP_NOT_AVAILABLE);
      }

      if (swap.offeredByDriverId === driverId) {
        throw new BadRequestException(DriverErrors.CANNOT_ACCEPT_OWN_SWAP);
      }

      if (me.vehicleType !== swap.driverShift.driver.vehicleType) {
        throw new BadRequestException(DriverErrors.VEHICLE_MISMATCH);
      }

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

      const claimed = await tx.shiftSwapRequest.updateMany({
        where: { id: swapId, status: SwapRequestStatus.PENDING },
        data: { status: SwapRequestStatus.ACCEPTED },
      });
      if (claimed.count === 0) {
        throw new BadRequestException(DriverErrors.SWAP_NOT_AVAILABLE);
      }

      if (
        swap.driverShift.shiftPoolId &&
        typeof tx.shiftPoolWaitlist?.deleteMany === 'function'
      ) {
        await tx.shiftPoolWaitlist.deleteMany({
          where: {
            driverId,
            shiftPoolId: swap.driverShift.shiftPoolId,
          },
        });
      }

      return tx.driverShift.update({
        where: { id: swap.driverShiftId },
        data: { driverId },
      });
    });
  }

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
            user: {
              select: { id: true, name: true, phone: true, avatar: true },
            },
          },
        },
      },
    });

    return entries.map((entry, index) => ({
      id: entry.id,
      position: index + 1,
      joinedAt: entry.createdAt,
      driverId: entry.driverId,
      driver: entry.driver
        ? {
            ...entry.driver,
            avatar: entry.driver.avatar ?? entry.driver.user?.avatar ?? null,
          }
        : entry.driver,
    }));
  }

  async promoteFromWaitlist(poolId: string): Promise<void> {
    try {
      const promotedList = await this.prisma.$transaction(async (tx) => {
        if (typeof tx.$executeRaw === 'function') {
          await tx.$executeRaw`SELECT 1 FROM shift_pools WHERE id = ${poolId} FOR UPDATE`;
        }

        const pool = await tx.shiftPool.findUnique({
          where: { id: poolId },
          include: { _count: { select: { driverShifts: true } } },
        });
        if (!pool) return [];
        if (pool.startTime && pool.startTime <= new Date()) {
          return [];
        }

        const availableSeats = pool.maxDrivers - pool._count.driverShifts;
        if (availableSeats <= 0) return [];

        const entries = await tx.shiftPoolWaitlist.findMany({
          where: { shiftPoolId: poolId },
          orderBy: { createdAt: 'asc' },
          include: { driver: { select: { id: true, userId: true } } },
        });
        if (entries.length === 0) return [];

        const entryDriverIds = entries.map((e) => e.driverId);
        let existingShifts: Array<{
          driverId: string;
          shiftPoolId: string | null;
          status: DriverShiftStatus;
          startTime: Date;
          endTime: Date;
        }> | null = null;

        if (typeof tx.driverShift?.findMany === 'function') {
          existingShifts = await tx.driverShift.findMany({
            where: { driverId: { in: entryDriverIds } },
            select: {
              driverId: true,
              shiftPoolId: true,
              status: true,
              startTime: true,
              endTime: true,
            },
          });
        }

        const promoted: Array<{ shiftId: string; driverUserId: string }> = [];

        for (const entry of entries) {
          if (promoted.length >= availableSeats) break;

          let alreadyBooked = false;
          let overlapping = false;

          if (existingShifts !== null) {
            alreadyBooked = existingShifts.some(
              (s) =>
                s.driverId === entry.driverId && s.shiftPoolId === poolId,
            );
            if (!alreadyBooked) {
              overlapping = existingShifts.some(
                (s) =>
                  s.driverId === entry.driverId &&
                  (s.status === DriverShiftStatus.SCHEDULED ||
                    s.status === DriverShiftStatus.ACTIVE) &&
                  s.startTime < pool.endTime &&
                  s.endTime > pool.startTime,
              );
            }
          } else {
            const bookedRow = await tx.driverShift.findFirst({
              where: { driverId: entry.driverId, shiftPoolId: poolId },
            });
            alreadyBooked = Boolean(bookedRow);
            if (!alreadyBooked) {
              const overlapRow = await tx.driverShift.findFirst({
                where: {
                  driverId: entry.driverId,
                  status: {
                    in: [DriverShiftStatus.SCHEDULED, DriverShiftStatus.ACTIVE],
                  },
                  startTime: { lt: pool.endTime },
                  endTime: { gt: pool.startTime },
                },
              });
              overlapping = Boolean(overlapRow);
            }
          }

          if (alreadyBooked) {
            await tx.shiftPoolWaitlist.delete({ where: { id: entry.id } });
            continue;
          }
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
          promoted.push({
            shiftId: shift.id,
            driverUserId: entry.driver.userId,
          });
        }

        return promoted;
      });

      for (const item of promotedList) {
        this.eventEmitter.emit(
          EVENTS.SHIFT_SPOT_AVAILABLE,
          new ShiftSpotAvailableEvent(item.driverUserId, poolId),
        );
      }
    } catch (e) {
      this.logger.error('Failed to promote from waitlist', e);
    }
  }
}
