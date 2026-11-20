import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverShiftStatus, SwapRequestStatus } from '@prisma/client';
import { SHIFT_WARNING_WINDOW_MS } from 'src/common/drivers/driver-shift.helper';
import {
  ShiftMissedEvent,
  ShiftReminderEvent,
  ShiftSwapCancelledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { SHIFT_GRACE_MINUTES } from '../drivers/ranking/driver-ranking.calculator';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

@Injectable()
export class DriverShiftAttendanceService {
  private readonly logger = new Logger(DriverShiftAttendanceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async handle30MinShiftWarning(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      if (!settings.driverShiftsEnabled) return;

      const now = new Date();
      const in30Mins = new Date(now.getTime() + SHIFT_WARNING_WINDOW_MS);

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
        const claimed = await this.prisma.driverShift.updateMany({
          where: { id: shift.id, warningSent: false },
          data: { warningSent: true },
        });
        if (claimed.count === 0) continue;

        const pendingSwap = shift.swapRequests.find(
          (s) => s.status === SwapRequestStatus.PENDING,
        );
        if (pendingSwap) {
          if (typeof this.prisma.shiftSwapRequest?.updateMany === 'function') {
            await this.prisma.shiftSwapRequest.updateMany({
              where: { id: pendingSwap.id, status: SwapRequestStatus.PENDING },
              data: { status: SwapRequestStatus.CANCELLED },
            });
          } else {
            await this.prisma.shiftSwapRequest.update({
              where: { id: pendingSwap.id },
              data: { status: SwapRequestStatus.CANCELLED },
            });
          }

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

  async handle5MinLateCheck(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      if (!settings.driverShiftsEnabled) return;

      const now = new Date();
      const graceCutoff = new Date(
        now.getTime() - SHIFT_GRACE_MINUTES * 60 * 1000,
      );

      const lateShifts = await this.prisma.driverShift.findMany({
        where: {
          status: DriverShiftStatus.SCHEDULED,
          startTime: { lte: graceCutoff },
          actualStart: null,
        },
        include: { driver: { include: { user: true } } },
        take: 100,
        orderBy: { startTime: 'asc' },
      });

      for (const shift of lateShifts) {
        const claimed = await this.prisma.driverShift.updateMany({
          where: { id: shift.id, status: DriverShiftStatus.SCHEDULED },
          data: { status: DriverShiftStatus.MISSED },
        });
        if (claimed.count === 0) continue;

        if (typeof this.prisma.shiftSwapRequest?.updateMany === 'function') {
          await this.prisma.shiftSwapRequest.updateMany({
            where: {
              driverShiftId: shift.id,
              status: SwapRequestStatus.PENDING,
            },
            data: { status: SwapRequestStatus.CANCELLED },
          });
        }

        this.eventEmitter.emit(
          EVENTS.SHIFT_MISSED,
          new ShiftMissedEvent(shift.driver.user.id, shift.id, null),
        );
      }
    } catch (e) {
      this.logger.error('Failed in handle5MinLateCheck', e);
    }
  }
}
