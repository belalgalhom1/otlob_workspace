import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverBreakReason, DriverStatus, Role } from '@prisma/client';
import { DriverErrors } from 'src/common/constants/response.constants';
import {
  DriverBreakDecidedEvent,
  DriverStatusChangedEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { DriverManagersService } from './driver-managers.service';
import {
  requireDriverById,
  requireDriverByUserId,
} from './driver-lookup.helper';
import { DriversRepository } from './drivers.repository';
import { StartBreakDto } from './dto/driver.dto';

@Injectable()
export class DriverBreaksService {
  private readonly logger = new Logger(DriverBreaksService.name);

  constructor(
    private readonly driversRepository: DriversRepository,
    private readonly platformSettings: PlatformSettingsService,
    private readonly driverManagersService: DriverManagersService,
    private readonly driverTracking: DriverTrackingService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async startBreak(userId: string, dto?: StartBreakDto) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    const fresh = await this.assertCanBreak(driver);

    const pendingBreak = await this.driversRepository.findPendingBreak(
      fresh.id,
    );
    if (pendingBreak) {
      throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
    }

    const settings = await this.platformSettings.getSettings();
    if (!settings.breaksEnabled) {
      throw new BadRequestException(DriverErrors.BREAKS_DISABLED);
    }

    const activeShift = await this.driversRepository.findActiveShiftForDriver(
      fresh.id,
    );

    if (activeShift) {
      const [breakCount, usedMinutes] = await Promise.all([
        this.driversRepository.countShiftBreaks(activeShift.id),
        this.driversRepository.sumShiftBreakMinutes(activeShift.id),
      ]);
      if (breakCount >= settings.maxBreaksPerShift) {
        throw new BadRequestException(DriverErrors.BREAK_LIMIT_REACHED);
      }
      if (usedMinutes >= settings.maxBreakMinutesPerShift) {
        throw new BadRequestException(DriverErrors.BREAK_MINUTES_EXHAUSTED);
      }
    }

    const reason = dto?.reason ?? DriverBreakReason.REST;
    const brk = await this.createBreakSafely({
      driverId: fresh.id,
      shiftId: activeShift ? activeShift.id : null,
      reason,
      note: dto?.note,
      requestedMinutes: dto?.requestedMinutes,
    });

    this.logger.log(
      `Driver ${fresh.id} requested break ${brk.id} (${reason}) — pending approval`,
    );
    return brk;
  }

  async cancelBreakRequest(userId: string) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    const pending = await this.driversRepository.findPendingBreak(driver.id);
    if (!pending) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    return this.driversRepository.cancelBreak(pending.id);
  }

  async approveBreak(
    breakId: string,
    reviewerId: string,
    actor?: JwtAccessPayload,
  ) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(
        actor.sub,
        brk.driverId,
      );
    }
    if (brk.status !== 'PENDING') {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }

    const driver = await requireDriverById(
      this.driversRepository,
      brk.driverId,
    );

    const settings = await this.platformSettings.getSettings();
    if (!settings.breaksEnabled) {
      throw new BadRequestException(DriverErrors.BREAKS_DISABLED);
    }

    const fresh = await this.assertCanBreak(driver);
    const approved = await this.activateApprovedBreak({
      driver,
      breakId,
      reviewerId,
      prevStatus: fresh.status,
      statusReason: 'Break approved.',
      decisionAction: 'approved',
    });

    this.logger.log(`Break ${breakId} approved by ${reviewerId}`);
    return approved;
  }

  async rejectBreak(
    breakId: string,
    reviewerId: string,
    actor?: JwtAccessPayload,
  ) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(
        actor.sub,
        brk.driverId,
      );
    }
    if (brk.status !== 'PENDING') {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    const rejected = await this.driversRepository.rejectBreak(
      breakId,
      reviewerId,
    );
    if (!rejected) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    this.logger.log(`Break ${breakId} rejected by ${reviewerId}`);
    const rejectedDriver = await this.driversRepository.findById(
      rejected.driverId,
    );
    if (rejectedDriver) {
      this.eventEmitter.emit(
        EVENTS.DRIVER_BREAK_DECIDED,
        new DriverBreakDecidedEvent(
          rejected.driverId,
          rejectedDriver.userId,
          rejected.id,
          'rejected',
        ),
      );
    }
    return rejected;
  }

  async getPendingBreaks(actor?: JwtAccessPayload) {
    const scopedDriverIds =
      actor?.role === Role.DRIVER_MANAGER
        ? await this.driverManagersService.getManagedDriverIds(actor.sub)
        : undefined;
    return this.driversRepository.findPendingBreaks(50, scopedDriverIds);
  }

  async adminEndBreak(
    breakId: string,
    reviewerId: string,
    actor?: JwtAccessPayload,
  ) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(
        actor.sub,
        brk.driverId,
      );
    }
    if (brk.status !== 'APPROVED' || brk.endedAt) {
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    const ended = await this.finishBreak(breakId, false, 'ended_by_admin');
    if (!ended) {
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    this.logger.log(`Break ${breakId} force-ended by admin ${reviewerId}`);
    return ended;
  }

  async adminGrantBreak(
    driverId: string,
    reviewerId: string,
    dto?: StartBreakDto,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(actor.sub, driverId);
    }
    const driver = await requireDriverById(this.driversRepository, driverId);
    const fresh = await this.assertCanBreak(driver);

    const pending = await this.driversRepository.findPendingBreak(driver.id);
    if (pending) {
      await this.driversRepository.cancelBreak(pending.id);
    }

    const activeShift = await this.driversRepository.findActiveShiftForDriver(
      driver.id,
    );

    const created = await this.createBreakSafely({
      driverId: fresh.id,
      shiftId: activeShift ? activeShift.id : null,
      reason: dto?.reason ?? DriverBreakReason.REST,
      note: dto?.note,
      requestedMinutes: dto?.requestedMinutes,
    });

    const approved = await this.activateApprovedBreak({
      driver,
      breakId: created.id,
      reviewerId,
      prevStatus: fresh.status,
      statusReason: 'Break granted by admin.',
      decisionAction: 'granted',
    });

    this.logger.log(
      `Break ${created.id} granted to driver ${driver.id} by admin ${reviewerId}`,
    );
    return approved;
  }

  async endBreak(userId: string) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    const activeBreak = await this.driversRepository.findActiveBreak(driver.id);
    if (!activeBreak || driver.status !== DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    const ended = await this.finishBreak(activeBreak.id, false);
    if (!ended) {
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    return ended;
  }

  async getMyBreaks(userId: string) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    return this.driversRepository.findBreaksByDriver(driver.id);
  }

  async getActiveBreak(userId: string) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    return this.driversRepository.findActiveBreak(driver.id);
  }

  /** Shared finish path for driver-initiated end, shift end, and the watchdog. */
  async finishBreak(
    breakId: string,
    autoEnded: boolean,
    notifyAction: 'ended_by_admin' | 'auto_ended' | null = null,
  ) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk || brk.status !== 'APPROVED' || brk.endedAt) return null;

    const endedAt = new Date();
    const durationMinutes = Math.max(
      1,
      Math.ceil((endedAt.getTime() - brk.startedAt.getTime()) / 60000),
    );

    const updated = await this.driversRepository.endBreak(
      breakId,
      endedAt,
      durationMinutes,
      autoEnded,
    );
    if (!updated) return null;

    const driver = await this.driversRepository.findById(brk.driverId);
    const restoreTo =
      brk.prevStatus === DriverStatus.OFFLINE
        ? DriverStatus.OFFLINE
        : DriverStatus.ONLINE;
    if (driver && driver.status === DriverStatus.ON_BREAK) {
      await this.driversRepository.updateStatus(brk.driverId, restoreTo);
      if (restoreTo === DriverStatus.OFFLINE) {
        const pos = await this.driverTracking.getDriverLocation(brk.driverId);
        if (pos) {
          await this.driversRepository.updateLastLocation(
            brk.driverId,
            pos.lng,
            pos.lat,
          );
        }
        await this.driverTracking.removeDriverLocation(brk.driverId);
      }
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          brk.driverId,
          driver.userId,
          DriverStatus.ON_BREAK,
          restoreTo,
          autoEnded ? 'Break auto-ended (limit reached).' : 'Break ended.',
        ),
      );
      if (notifyAction) {
        this.eventEmitter.emit(
          EVENTS.DRIVER_BREAK_DECIDED,
          new DriverBreakDecidedEvent(
            brk.driverId,
            driver.userId,
            breakId,
            notifyAction,
          ),
        );
      }
    }

    if (brk.shiftId) {
      try {
        await this.driversRepository.incrementShiftBreakMinutes(
          brk.shiftId,
          durationMinutes,
        );
      } catch (e) {
        this.logger.warn(
          `Break ${breakId}: skipped shift minute accrual (${e instanceof Error ? e.message : String(e)})`,
        );
      }
    }

    return updated;
  }

  /** Cron entrypoint: auto-end over-limit breaks, reject stale requests. */
  async autoEndExpiredBreaks() {
    const settings = await this.platformSettings.getSettings();
    const open = await this.driversRepository.findOpenBreaks();
    const now = Date.now();
    const expired = open.filter((b) => {
      const cap = Math.min(
        b.requestedMinutes ?? settings.maxSingleBreakMinutes,
        settings.maxSingleBreakMinutes,
      );
      return b.startedAt.getTime() + cap * 60000 <= now;
    });
    for (const b of expired) {
      try {
        const ended = await this.finishBreak(b.id, true, 'auto_ended');
        if (ended) {
          this.logger.log(`Auto-ended break ${b.id} (limit reached)`);
        }
      } catch (e) {
        this.logger.error(
          `Failed to auto-end break ${b.id}`,
          e instanceof Error ? e.stack : String(e),
        );
      }
    }

    const staleCutoff = new Date(
      Date.now() - settings.pendingBreakExpiryMins * 60000,
    );
    const stale =
      await this.driversRepository.findStalePendingBreaks(staleCutoff);
    for (const b of stale) {
      try {
        const rejected = await this.driversRepository.rejectBreak(
          b.id,
          'system',
        );
        if (rejected) {
          this.logger.log(`Auto-rejected stale break request ${b.id}`);
          const staleDriver = await this.driversRepository.findById(
            rejected.driverId,
          );
          if (staleDriver) {
            this.eventEmitter.emit(
              EVENTS.DRIVER_BREAK_DECIDED,
              new DriverBreakDecidedEvent(
                rejected.driverId,
                staleDriver.userId,
                rejected.id,
                'request_expired',
              ),
            );
          }
        }
      } catch (e) {
        this.logger.error(
          `Failed to auto-reject break ${b.id}`,
          e instanceof Error ? e.stack : String(e),
        );
      }
    }
    return { ended: expired.length, rejected: stale.length };
  }

  private async createBreakSafely(data: {
    driverId: string;
    shiftId: string | null;
    reason: DriverBreakReason;
    note?: string;
    requestedMinutes?: number;
  }) {
    try {
      return await this.driversRepository.createBreak(data);
    } catch (e: unknown) {
      const code =
        typeof e === 'object' && e !== null && 'code' in e
          ? (e as { code?: string }).code
          : undefined;
      if (code === 'P2002') {
        throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
      }
      throw e;
    }
  }

  private async activateApprovedBreak(params: {
    driver: { id: string; userId: string };
    breakId: string;
    reviewerId: string;
    prevStatus: DriverStatus;
    statusReason: string;
    decisionAction: 'approved' | 'granted';
  }) {
    const approved = await this.driversRepository.approveBreak(
      params.breakId,
      params.reviewerId,
      params.prevStatus,
    );
    if (!approved) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }

    const flipped = await this.driversRepository.flipDriverToBreak(
      params.driver.id,
    );
    if (!flipped) {
      await this.driversRepository.revertBreakToPending(params.breakId);
      throw new BadRequestException(DriverErrors.CANNOT_BREAK_ON_DELIVERY);
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        params.driver.id,
        params.driver.userId,
        params.prevStatus,
        DriverStatus.ON_BREAK,
        params.statusReason,
      ),
    );
    this.eventEmitter.emit(
      EVENTS.DRIVER_BREAK_DECIDED,
      new DriverBreakDecidedEvent(
        approved.driverId,
        params.driver.userId,
        approved.id,
        params.decisionAction,
      ),
    );

    return approved;
  }

  /**
   * Shared safety gate for request / approve / grant: the driver must be
   * breakable right now (approved, not suspended, not busy/delivering/on
   * break, no live order, no pending dispatch, no other active break).
   */
  private async assertCanBreak(
    driverOrId:
      | string
      | {
          id: string;
          userId: string;
          status: DriverStatus;
          isApproved: boolean;
        },
  ) {
    const driver =
      typeof driverOrId === 'string'
        ? await requireDriverById(this.driversRepository, driverOrId)
        : driverOrId;

    if (driver.status === DriverStatus.SUSPENDED) {
      throw new ForbiddenException(DriverErrors.ACCOUNT_SUSPENDED);
    }
    if (!driver.isApproved) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }
    if (
      driver.status === DriverStatus.ON_DELIVERY ||
      driver.status === DriverStatus.BUSY ||
      driver.status === DriverStatus.ON_BREAK
    ) {
      throw new BadRequestException(DriverErrors.CANNOT_BREAK_ON_DELIVERY);
    }

    const [activeBreak, activeOrder, pendingDispatch] = await Promise.all([
      this.driversRepository.findActiveBreak(driver.id),
      this.driversRepository.findActiveOrderForDriver(driver.id),
      this.driversRepository.findPendingDispatchForDriver(driver.id),
    ]);
    if (activeBreak) throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
    if (activeOrder) {
      throw new BadRequestException(DriverErrors.CANNOT_BREAK_ON_DELIVERY);
    }
    if (pendingDispatch) {
      throw new BadRequestException(
        DriverErrors.CANNOT_BREAK_WITH_PENDING_DISPATCH,
      );
    }
    return driver;
  }
}
