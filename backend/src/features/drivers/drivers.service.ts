import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriversRepository } from './drivers.repository';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { LocationRepository } from '../../infrastructure/location/location.repository';
import {
  RegisterDriverDto,
  UpdateDriverProfileDto,
  UpdateDriverStatusDto,
  StartBreakDto,
  CreateDriverShiftDto,
  QueryDriversDto,
  QueryDriverWalletDto,
} from './dto/driver.dto';
import {
  DriverStatusChangedEvent,
  DriverBreakDecidedEvent,
  ShiftDisabledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { DriverErrors } from 'src/common/constants/response.constants';
import {
  DriverStatus,
  DriverShiftStatus,
  DriverBreakReason,
  Role,
} from '@prisma/client';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { DriverShiftsService } from '../driver-shifts/driver-shifts.service';

@Injectable()
export class DriversService {
  private readonly logger = new Logger(DriversService.name);

  constructor(
    private readonly driversRepository: DriversRepository,
    private readonly storage: StorageService,
    private readonly eventEmitter: EventEmitter2,
    private readonly locationRepository: LocationRepository,
    private readonly socketService: SocketService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly driverShiftsService: DriverShiftsService,
  ) {}

  // ─── Register ─────────────────────────────────────────────────────────────

  async register(userId: string, dto: RegisterDriverDto) {
    const existing = await this.driversRepository.findByUserId(userId);
    if (existing) throw new ConflictException(DriverErrors.PROFILE_EXISTS);

    // Upgrade user role to DRIVER
    await this.driversRepository.updateUserRole(userId, Role.DRIVER);

    const driver = await this.driversRepository.create({
      userId,
      name: dto.name,
      nationalId: dto.nationalId ?? null,
      licenseNumber: dto.licenseNumber ?? null,
      vehicleType: dto.vehicleType ?? 'MOTORCYCLE',
      vehiclePlate: dto.vehiclePlate ?? null,
    });

    this.logger.log(`Driver registered: ${driver.id} for user ${userId}`);
    return driver;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  async getMyProfile(userId: string) {
    const driver = await this.driversRepository.findByUserIdWithUser(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  async updateProfile(userId: string, dto: UpdateDriverProfileDto) {
    const driver = await this.assertDriver(userId);
    return this.driversRepository.update(driver.id, {
      ...(dto.name !== undefined && { name: dto.name }),
      ...(dto.nationalId !== undefined && { nationalId: dto.nationalId }),
      ...(dto.licenseNumber !== undefined && {
        licenseNumber: dto.licenseNumber,
      }),
    });
  }

  async uploadAvatar(userId: string, file: Express.Multer.File) {
    const driver = await this.assertDriver(userId);

    if (driver.avatar) {
      await this.storage.delete(driver.avatar);
    }

    const avatarUrl = await this.storage.upload(file, 'drivers/avatars');
    await this.driversRepository.updateAvatar(driver.id, avatarUrl);
    return { avatar: avatarUrl };
  }

  // ─── Status ───────────────────────────────────────────────────────────────

  async updateStatus(userId: string, dto: UpdateDriverStatusDto) {
    const driver = await this.assertDriver(userId);

    if (driver.status === DriverStatus.SUSPENDED) {
      throw new ForbiddenException(DriverErrors.ACCOUNT_SUSPENDED);
    }

    if (!driver.isApproved) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }

    const activeStatuses: DriverStatus[] = [
      DriverStatus.ON_DELIVERY,
      DriverStatus.BUSY,
    ];
    if (
      activeStatuses.includes(driver.status) &&
      dto.status === DriverStatus.OFFLINE
    ) {
      throw new BadRequestException(DriverErrors.CANNOT_GO_OFFLINE_ON_DELIVERY);
    }

    // Breaks are tracked sessions, not plain status flips — force the
    // dedicated endpoints so every break is recorded with limits enforced.
    if (dto.status === DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.BREAK_USE_ENDPOINTS);
    }
    if (driver.status === DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.BREAK_USE_ENDPOINTS);
    }

    // Online/offline is fully shift-driven: starting a shift flips the
    // driver ONLINE, ending it flips OFFLINE. Manual flips are rejected so
    // drivers can never go online/offline on their own.
    if (
      dto.status === DriverStatus.ONLINE ||
      dto.status === DriverStatus.OFFLINE
    ) {
      throw new BadRequestException(DriverErrors.STATUS_MANAGED_BY_SHIFT);
    }

    const oldStatus = driver.status;
    await this.driversRepository.updateStatus(driver.id, dto.status);

    // NOTE: manual ONLINE/OFFLINE is rejected above, so the old
    // offline-cleanup branches are gone. Shift end paths settle breaks,
    // persist the last location and drop live tracking themselves
    // (see endShift / endShiftBySystem).

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(driver.id, userId, oldStatus, dto.status),
    );

    this.logger.log(`Driver ${driver.id} status: ${oldStatus} → ${dto.status}`);
    return { status: dto.status };
  }

  // ─── Breaks ───────────────────────────────────────────────────────────────
  // Strict approval: driver requests (PENDING) → admin with MANAGE_DRIVERS
  // approves (APPROVED, driver ON_BREAK) or rejects. Driver ends (ENDED);
  // watchdog auto-ends over-limit breaks and rejects stale requests.

  async startBreak(userId: string, dto?: StartBreakDto) {
    const driver = await this.assertDriver(userId);
    // Fresh re-read: guards must see current status, and everything below
    // uses the fresh row so no stale snapshot leaks downstream.
    const fresh = await this.assertCanBreak(driver.id);

    const pendingBreak =
      await this.driversRepository.findPendingBreak(fresh.id);
    if (pendingBreak) {
      throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
    }

    // Single cached settings read serves the kill-switch and the quota below.
    const settings = await this.platformSettings.getSettings();
    if (!settings.breaksEnabled) {
      throw new BadRequestException(DriverErrors.BREAKS_DISABLED);
    }

    const activeShift =
      await this.driversRepository.findActiveShiftForDriver(fresh.id);

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
    let brk;
    try {
      brk = await this.driversRepository.createBreak({
        driverId: fresh.id,
        shiftId: activeShift ? activeShift.id : null,
        reason,
        note: dto?.note,
        requestedMinutes: dto?.requestedMinutes,
      });
    } catch (e: any) {
      // Lost a concurrent request race against the partial unique index.
      if (e?.code === 'P2002') {
        throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
      }
      throw e;
    }

    this.logger.log(
      `Driver ${fresh.id} requested break ${brk.id} (${reason}) — pending approval`,
    );
    return brk;
  }

  async cancelBreakRequest(userId: string) {
    const driver = await this.assertDriver(userId);
    const pending = await this.driversRepository.findPendingBreak(driver.id);
    if (!pending) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    return this.driversRepository.cancelBreak(pending.id);
  }

  async approveBreak(breakId: string, reviewerId: string) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
    if (brk.status !== 'PENDING') {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }

    const driver = await this.driversRepository.findById(brk.driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    // Kill-switch: a disabled system drains (ends/cancels allowed) but no
    // new breaks start — not even via approval. Grant stays an override.
    const settings = await this.platformSettings.getSettings();
    if (!settings.breaksEnabled) {
      throw new BadRequestException(DriverErrors.BREAKS_DISABLED);
    }

    // State may have changed since the request — re-validate before flipping.
    const fresh = await this.assertCanBreak(driver.id);

    const approved = await this.driversRepository.approveBreak(
      breakId,
      reviewerId,
      fresh.status,
    );
    if (!approved) {
      // Lost a concurrent approval race.
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }

    const oldStatus = fresh.status;
    // Conditional flip: if the driver accepted a dispatch (or got suspended)
    // after validation, abort and put the request back to PENDING.
    const flipped = await this.driversRepository.flipDriverToBreak(driver.id);
    if (!flipped) {
      await this.driversRepository.revertBreakToPending(breakId);
      throw new BadRequestException(DriverErrors.CANNOT_BREAK_ON_DELIVERY);
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        driver.id,
        driver.userId,
        oldStatus,
        DriverStatus.ON_BREAK,
        'Break approved.',
      ),
    );

    this.logger.log(`Break ${breakId} approved by ${reviewerId}`);
    // Fire-and-forget: the driver listener notifies async via the events
    // queue, so the decision response never waits on insert/socket/push.
    this.eventEmitter.emit(
      EVENTS.DRIVER_BREAK_DECIDED,
      new DriverBreakDecidedEvent(
        approved.driverId,
        driver.userId,
        approved.id,
        'approved',
      ),
    );
    return approved;
  }

  async rejectBreak(breakId: string, reviewerId: string) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
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

  async getPendingBreaks() {
    return this.driversRepository.findPendingBreaks();
  }

  // ─── Admin break controls ─────────────────────────────────────────────────
  // MANAGE_DRIVERS (SUPER_ADMIN bypasses via PermissionsGuard).

  /** Force-end an ACTIVE break early (driver back ONLINE, minutes kept). */
  async adminEndBreak(breakId: string, reviewerId: string) {
    const brk = await this.driversRepository.findBreakById(breakId);
    if (!brk) throw new NotFoundException(DriverErrors.BREAK_NOT_FOUND);
    if (brk.status !== 'APPROVED' || brk.endedAt) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    const ended = await this.finishBreak(breakId, false, 'ended_by_admin');
    if (!ended) {
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }
    this.logger.log(`Break ${breakId} force-ended by admin ${reviewerId}`);
    return ended;
  }

  /**
   * Grant a break manually without a driver request (admin override).
   * Safety guards still enforced; per-shift quota caps bypassed by design.
   * Any PENDING request is superseded (cancelled).
   */
  async adminGrantBreak(
    driverId: string,
    reviewerId: string,
    dto?: StartBreakDto,
  ) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const fresh = await this.assertCanBreak(driver.id);

    const pending = await this.driversRepository.findPendingBreak(driver.id);
    if (pending) {
      await this.driversRepository.cancelBreak(pending.id);
    }

    const activeShift =
      await this.driversRepository.findActiveShiftForDriver(driver.id);
    const reason = dto?.reason ?? DriverBreakReason.REST;

    let created;
    try {
      created = await this.driversRepository.createBreak({
        driverId: fresh.id,
        shiftId: activeShift ? activeShift.id : null,
        reason,
        note: dto?.note,
        requestedMinutes: dto?.requestedMinutes,
      });
    } catch (e: any) {
      if (e?.code === 'P2002') {
        throw new ConflictException(DriverErrors.ALREADY_ON_BREAK);
      }
      throw e;
    }
    const approved = await this.driversRepository.approveBreak(
      created.id,
      reviewerId,
      fresh.status,
    );
    if (!approved) {
      // Driver cancelled in the split second between create and approve.
      throw new BadRequestException(DriverErrors.BREAK_NOT_PENDING);
    }

    const oldStatus = fresh.status;
    const flipped = await this.driversRepository.flipDriverToBreak(driver.id);
    if (!flipped) {
      await this.driversRepository.revertBreakToPending(created.id);
      throw new BadRequestException(DriverErrors.CANNOT_BREAK_ON_DELIVERY);
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        driver.id,
        driver.userId,
        oldStatus,
        DriverStatus.ON_BREAK,
        'Break granted by admin.',
      ),
    );

    this.logger.log(
      `Break ${created.id} granted to driver ${driver.id} by admin ${reviewerId}`,
    );
    this.eventEmitter.emit(
      EVENTS.DRIVER_BREAK_DECIDED,
      new DriverBreakDecidedEvent(
        approved.driverId,
        driver.userId,
        approved.id,
        'granted',
      ),
    );
    return approved;
  }

  async endBreak(userId: string) {
    const driver = await this.assertDriver(userId);
    const activeBreak =
      await this.driversRepository.findActiveBreak(driver.id);
    if (!activeBreak || driver.status !== DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    const ended = await this.finishBreak(activeBreak.id, false);
    if (!ended) {
      // Watchdog or admin closed it concurrently.
      throw new BadRequestException(DriverErrors.NOT_ON_BREAK);
    }
    return ended;
  }

  async getMyBreaks(userId: string) {
    const driver = await this.assertDriver(userId);
    return this.driversRepository.findBreaksByDriver(driver.id);
  }

  async getActiveBreak(userId: string) {
    const driver = await this.assertDriver(userId);
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
    // Pause/resume: restore the pre-break status (ONLINE, or OFFLINE for
    // breaks granted while clocked out). OFFLINE restore also evicts geo,
    // mirroring PATCH me/status.
    const restoreTo =
      brk.prevStatus === DriverStatus.OFFLINE
        ? DriverStatus.OFFLINE
        : DriverStatus.ONLINE;
    if (driver && driver.status === DriverStatus.ON_BREAK) {
      await this.driversRepository.updateStatus(brk.driverId, restoreTo);
      if (restoreTo === DriverStatus.OFFLINE) {
        const pos = await this.locationRepository.getDriverLocation(
          brk.driverId,
        );
        if (pos) {
          await this.driversRepository.updateLastLocation(
            brk.driverId,
            pos.lng,
            pos.lat,
          );
        }
        await this.locationRepository.removeDriverLocation(brk.driverId);
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
      // Shift may have been deleted meanwhile (SetNull skips this when the
      // relation is already gone, but the id can be stale) — minutes must
      // never fail the break close.
      try {
        await this.driversRepository.incrementShiftBreakMinutes(
          brk.shiftId,
          durationMinutes,
        );
      } catch (e) {
        this.logger.warn(
          `Break ${breakId}: skipped shift minute accrual (${(e as Error).message})`,
        );
      }
    }

    return updated;
  }

  /** Cron entrypoint: auto-end over-limit breaks, reject stale requests. */
  async autoEndExpiredBreaks() {
    const settings = await this.platformSettings.getSettings();
    // Per-break effective cap: requested minutes tightened by the system cap.
    // Null request = up to the cap.
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
        // finishBreak emits the auto_ended notice itself (driver row in hand,
        // zero extra queries on this hot path).
        const ended = await this.finishBreak(b.id, true, 'auto_ended');
        if (ended) {
          this.logger.log(`Auto-ended break ${b.id} (limit reached)`);
        }
      } catch (e) {
        this.logger.error(
          `Failed to auto-end break ${b.id}`,
          (e as Error).stack,
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
        const rejected = await this.driversRepository.rejectBreak(b.id, 'system');
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
          (e as Error).stack,
        );
      }
    }
    return { ended: expired.length, rejected: stale.length };
  }

  // ─── Shifts ───────────────────────────────────────────────────────────────

  async createShift(userId: string, dto: CreateDriverShiftDto) {
    const driver = await this.assertDriver(userId);

    const startTime = new Date(dto.startTime);
    const endTime = new Date(dto.endTime);

    if (endTime <= startTime) {
      throw new BadRequestException(DriverErrors.END_TIME_BEFORE_START);
    }

    const overlap = await this.driversRepository.findOverlappingShift(
      driver.id,
      startTime,
      endTime,
    );
    if (overlap) throw new ConflictException(DriverErrors.SHIFT_OVERLAPS);

    return this.driversRepository.createShift({
      driverId: driver.id,
      zoneId: dto.zoneId ?? null,
      startTime,
      endTime,
    });
  }

  async getMyShifts(userId: string) {
    const driver = await this.assertDriver(userId);
    return this.driversRepository.findShiftsByDriver(driver.id);
  }

  async deleteMyShift(userId: string, shiftId: string) {
    const driver = await this.driversRepository.findByUserIdWithUser(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const shift = await this.driversRepository.findShiftById(
      shiftId,
      driver.id,
    );
    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);

    if (
      shift.status === DriverShiftStatus.ACTIVE &&
      driver.status !== DriverStatus.ON_DELIVERY
    ) {
      await this.driversRepository.update(driver.id, {
        status: DriverStatus.OFFLINE,
      });
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          driver.id,
          driver.user.id,
          driver.status,
          DriverStatus.OFFLINE,
          'Shift deleted by driver.',
        ),
      );
    }

    // Deleting a shift must not orphan break rows: settle the active break
    // (minutes kept) and drop any pending request for this driver.
    const openBreak = await this.driversRepository.findActiveBreak(driver.id);
    if (openBreak) {
      await this.finishBreak(openBreak.id, false);
    }
    const pendingBreak =
      await this.driversRepository.findPendingBreak(driver.id);
    if (pendingBreak) {
      await this.driversRepository.cancelBreak(pendingBreak.id);
    }

    await this.driversRepository.deleteShift(shiftId);

    this.eventEmitter.emit(
      EVENTS.SHIFT_DISABLED,
      new ShiftDisabledEvent(driver.user.id, shift.id, 'self'),
    );

    // The freed seat goes to the pool's waitlist, if any.
    if (shift.shiftPoolId) {
      await this.driverShiftsService.promoteFromWaitlist(shift.shiftPoolId);
    }

    return { success: true, removed: 1 };
  }

  async startShift(
    userId: string,
    shiftId: string,
    file?: Express.Multer.File,
    latitude?: number,
    longitude?: number,
  ) {
    const driver = await this.assertDriver(userId);
    if (driver.status === DriverStatus.SUSPENDED) {
      throw new ForbiddenException(DriverErrors.ACCOUNT_SUSPENDED);
    }
    if (!driver.isApproved) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }
    const shift = await this.driversRepository.findShiftById(
      shiftId,
      driver.id,
    );

    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);
    if (shift.status !== DriverShiftStatus.SCHEDULED) {
      throw new BadRequestException(DriverErrors.SHIFT_NOT_SCHEDULED);
    }

    // A selfie is mandatory to start a shift (shown in the shift list).
    if (!file) {
      throw new BadRequestException(DriverErrors.START_PHOTO_REQUIRED);
    }

    // The driver must physically be inside the shift's zone.
    if (shift.zoneId) {
      if (latitude == null || longitude == null) {
        throw new BadRequestException(DriverErrors.NOT_IN_SHIFT_ZONE);
      }
      const insideZone = await this.locationRepository.isPointInZone(
        shift.zoneId,
        longitude,
        latitude,
      );
      if (!insideZone) {
        throw new BadRequestException(DriverErrors.NOT_IN_SHIFT_ZONE);
      }
    }

    // Upload first (no DB changes yet); the orphan is deleted below if the
    // atomic start loses a concurrent race.
    const photoUrl = await this.storage.upload(file, 'drivers/shift-starts');

    let startedShift;
    try {
      startedShift = await this.driversRepository.startShiftSafely(
        shiftId,
        driver.id,
      );

      if (!startedShift) {
        throw new BadRequestException(DriverErrors.SHIFT_NOT_SCHEDULED);
      }
    } catch (error) {
      await this.storage.delete(photoUrl).catch(() => null);
      if ((error as Error).message === 'ACTIVE_SHIFT_EXISTS') {
        throw new BadRequestException(DriverErrors.ACTIVE_SHIFT_EXISTS);
      }
      throw error;
    }

    // Persist the start selfie (best-effort: the shift is already started).
    await this.driversRepository
      .updateShift(shiftId, { startPhotoUrl: photoUrl })
      .catch((e: unknown) =>
        this.logger.error(`Failed to save shift start photo: ${e}`),
      );

    // Starting a shift takes the driver ONLINE directly — there is no
    // manual online/offline anymore.
    const fresh = await this.driversRepository.findById(driver.id);
    if (fresh && fresh.status === DriverStatus.OFFLINE) {
      await this.driversRepository.updateStatus(
        driver.id,
        DriverStatus.ONLINE,
      );
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          driver.id,
          userId,
          DriverStatus.OFFLINE,
          DriverStatus.ONLINE,
          'Shift started.',
        ),
      );
    }

    return startedShift;
  }

  async endShift(userId: string, shiftId: string) {
    const driver = await this.assertDriver(userId);
    const shift = await this.driversRepository.findShiftById(
      shiftId,
      driver.id,
    );

    if (!shift) throw new NotFoundException(DriverErrors.SHIFT_NOT_FOUND);
    if (shift.status !== DriverShiftStatus.ACTIVE) {
      throw new BadRequestException(DriverErrors.SHIFT_NOT_ACTIVE);
    }
    if (driver.status === DriverStatus.ON_DELIVERY) {
      throw new BadRequestException(DriverErrors.CANNOT_END_WHILE_ON_DELIVERY);
    }

    // Closing the shift closes any open break so minutes are accounted,
    // and drops any unapproved request tied to this driver.
    const openBreak = await this.driversRepository.findActiveBreak(driver.id);
    if (openBreak) {
      await this.finishBreak(openBreak.id, false);
    }
    const pendingBreak =
      await this.driversRepository.findPendingBreak(driver.id);
    if (pendingBreak) {
      await this.driversRepository.cancelBreak(pendingBreak.id);
    }

    const [totalDeliveries, totalEarnings] = await Promise.all([
      this.driversRepository.countDeliveredOrdersInShift(shiftId),
      this.driversRepository.sumShiftEarnings(shiftId),
    ]);

    let updatedShift;
    try {
      updatedShift = await this.driversRepository.endShiftSafely(shiftId, {
        status: DriverShiftStatus.COMPLETED,
        actualEnd: new Date(),
        totalDeliveries,
        totalEarnings,
      });
    } catch (e) {
      throw new BadRequestException(DriverErrors.SHIFT_NOT_ACTIVE);
    }

    // Ending the shift takes the driver OFFLINE directly — there is no
    // manual online/offline anymore. (ON_DELIVERY is rejected above, and
    // breaks were already settled, so the flip is safe.)
    const endedStatus = (await this.driversRepository.findById(driver.id))
      ?.status;
    if (endedStatus && endedStatus !== DriverStatus.OFFLINE) {
      await this.driversRepository.updateStatus(driver.id, DriverStatus.OFFLINE);
      const pos = await this.locationRepository.getDriverLocation(driver.id);
      if (pos) {
        await this.driversRepository.updateLastLocation(
          driver.id,
          pos.lng,
          pos.lat,
        );
      }
      await this.locationRepository.removeDriverLocation(driver.id);
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          driver.id,
          userId,
          endedStatus,
          DriverStatus.OFFLINE,
          'Shift ended.',
        ),
      );
    }

    // Tier Promotion Logic
    const fullDriver = await this.driversRepository.findById(driver.id);
    if (fullDriver) {
      // Must have started on time (i.e. no MISSED status or cron demotion, which is implicitly true if we are here and it was ACTIVE)
      // Check 0 rejected and 0 expired
      if (
        updatedShift.rejectedDispatches === 0 &&
        updatedShift.expiredDispatches === 0
      ) {
        let newTier = fullDriver.tier;
        if (newTier === 'BRONZE') newTier = 'SILVER';
        else if (newTier === 'SILVER') newTier = 'GOLD';

        if (newTier !== fullDriver.tier) {
          await this.driversRepository.update(fullDriver.id, {
            tier: newTier,
          });
        }
      }
    }

    return updatedShift;
  }

  async endShiftBySystem(driverId: string, shiftId: string) {
    // Never end a shift while the driver is mid-delivery: the driver stays
    // ON_DELIVERY until the order completes, so leave the shift ACTIVE and let
    // the next cron pass end it once they are free. Ending it here (with the
    // driver forced OFFLINE by the sweep) would conflict with the live order.
    const driverById = await this.driversRepository.findById(driverId);
    if (!driverById || driverById.status === DriverStatus.ON_DELIVERY) {
      return;
    }

    const shift = await this.driversRepository.findShiftById(shiftId, driverId);
    if (!shift || shift.status !== DriverShiftStatus.ACTIVE) {
      return;
    }

    const openBreak = await this.driversRepository.findActiveBreak(driverId);
    if (openBreak) {
      await this.finishBreak(openBreak.id, false);
    }
    const pendingBreak =
      await this.driversRepository.findPendingBreak(driverId);
    if (pendingBreak) {
      await this.driversRepository.cancelBreak(pendingBreak.id);
    }

    const [totalDeliveries, totalEarnings] = await Promise.all([
      this.driversRepository.countDeliveredOrdersInShift(shiftId),
      this.driversRepository.sumShiftEarnings(shiftId),
    ]);

    let updatedShift;
    try {
      updatedShift = await this.driversRepository.endShiftSafely(shiftId, {
        status: DriverShiftStatus.COMPLETED,
        actualEnd: new Date(),
        totalDeliveries,
        totalEarnings,
      });
    } catch (e) {
      return;
    }

    // System-ended shifts also take the driver OFFLINE (ON_DELIVERY already
    // returned early above, breaks already settled).
    const sysStatus = (await this.driversRepository.findById(driverId))
      ?.status;
    if (sysStatus && sysStatus !== DriverStatus.OFFLINE) {
      await this.driversRepository.updateStatus(
        driverId,
        DriverStatus.OFFLINE,
      );
      const sysPos = await this.locationRepository.getDriverLocation(driverId);
      if (sysPos) {
        await this.driversRepository.updateLastLocation(
          driverId,
          sysPos.lng,
          sysPos.lat,
        );
      }
      await this.locationRepository.removeDriverLocation(driverId);
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          driverId,
          driverById.userId,
          sysStatus,
          DriverStatus.OFFLINE,
          'Shift ended by system.',
        ),
      );
    }

    // Tier Promotion Logic
    const fullDriver = await this.driversRepository.findById(driverId);
    if (fullDriver) {
      if (
        updatedShift.rejectedDispatches === 0 &&
        updatedShift.expiredDispatches === 0
      ) {
        let newTier = fullDriver.tier;
        if (newTier === 'BRONZE') newTier = 'SILVER';
        else if (newTier === 'SILVER') newTier = 'GOLD';

        if (newTier !== fullDriver.tier) {
          await this.driversRepository.update(fullDriver.id, {
            tier: newTier,
          });
        }
      }
    }

    return updatedShift;
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  async getWalletBalance(userId: string) {
    const driver = await this.assertDriver(userId);
    return { walletBalance: driver.walletBalance };
  }

  async getWalletTransactions(userId: string, dto: QueryDriverWalletDto) {
    const driver = await this.assertDriver(userId);
    const { page = 1, limit = 20 } = dto;

    const result = await this.driversRepository.getWalletTransactions(
      driver.id,
      page,
      limit,
    );

    return { walletBalance: driver.walletBalance, ...result };
  }

  // ─── Admin ────────────────────────────────────────────────────────────────

  async adminCreateDriver(userId: string, adminId: string, dto: any) {
    // Note: DTO type is cast as any here to avoid cyclic imports if not careful,
    // but better to import AdminCreateDriverDto.
    const existing = await this.driversRepository.findByUserId(userId);
    if (existing) throw new ConflictException(DriverErrors.PROFILE_EXISTS);

    // Create the driver profile
    const driver = await this.driversRepository.create({
      userId,
      name: dto.name,
      nationalId: dto.nationalId ?? null,
      licenseNumber: dto.licenseNumber ?? null,
      vehicleType: dto.vehicleType ?? 'MOTORCYCLE',
      vehiclePlate: dto.vehiclePlate ?? null,
    });

    if (dto.status || dto.tier || dto.isApproved !== undefined) {
      const updateData: any = {
        status: dto.status ?? DriverStatus.OFFLINE,
        tier: dto.tier ?? 'SILVER',
      };

      if (dto.isApproved !== undefined) {
        updateData.isApproved = dto.isApproved;
        if (dto.isApproved) {
          updateData.approvedAt = new Date();
          updateData.approvedById = adminId;
        }
      }

      await this.driversRepository.update(driver.id, updateData);
    }

    // Log the action
    await this.logAdminAction(
      adminId,
      'CREATE',
      'Driver',
      driver.id,
      null,
      dto,
    );

    this.logger.log(`Admin ${adminId} created driver ${driver.id}`);
    return this.driversRepository.findById(driver.id);
  }

  async adminUpdateDriver(driverId: string, adminId: string, dto: any) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const oldValues = { ...driver };

    // Break machine guard: admins cannot flip ON_BREAK directly (use the
    // approve/grant endpoints), and moving a driver off ON_BREAK must close
    // the active break so no orphan APPROVED row survives.
    if (dto.status !== undefined) {
      if (dto.status === DriverStatus.ON_BREAK) {
        throw new BadRequestException(DriverErrors.BREAK_USE_ENDPOINTS);
      }
      if (
        driver.status === DriverStatus.ON_BREAK &&
        dto.status !== DriverStatus.ON_BREAK
      ) {
        const openBreak =
          await this.driversRepository.findActiveBreak(driverId);
        if (openBreak) {
          await this.finishBreak(openBreak.id, false);
        }
      }
    }

    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.nationalId !== undefined) updateData.nationalId = dto.nationalId;
    if (dto.licenseNumber !== undefined)
      updateData.licenseNumber = dto.licenseNumber;
    if (dto.vehicleType !== undefined) updateData.vehicleType = dto.vehicleType;
    if (dto.vehiclePlate !== undefined)
      updateData.vehiclePlate = dto.vehiclePlate;
    if (dto.status !== undefined) updateData.status = dto.status;
    if (dto.tier !== undefined) updateData.tier = dto.tier;
    if (dto.isApproved !== undefined) {
      updateData.isApproved = dto.isApproved;
      if (dto.isApproved) {
        updateData.approvedAt = new Date();
        updateData.approvedById = adminId;
      }
    }

    await this.driversRepository.update(driverId, updateData);

    // Log the action
    await this.logAdminAction(
      adminId,
      'UPDATE',
      'Driver',
      driverId,
      oldValues,
      updateData,
    );

    this.logger.log(`Admin ${adminId} updated driver ${driverId}`);
    return this.driversRepository.findById(driverId);
  }

  private async logAdminAction(
    adminId: string,
    actionType: any,
    entityType: string,
    entityId: string,
    oldValues: any,
    newValues: any,
  ) {
    // We emit an event or write to AuditLog directly.
    // Since we don't have AuditLog repository injected here, let's use Prisma directly or emit an event.
    // The codebase seems to have an AuditLog model. Let's emit an event if there's an audit listener, or just use Prisma if available.
    // Actually, it's safer to emit an event if audit log service handles it, or not log if it breaks.
    // Wait, the prompt says "Add audit logging".
    try {
      this.eventEmitter.emit('audit.log.created', {
        userId: adminId,
        actionType,
        action: `${actionType}_DRIVER_PROFILE`,
        entityType,
        entityId,
        oldValues,
        newValues,
      });
    } catch (e) {
      this.logger.error('Failed to log admin action', e);
    }
  }

  async adminFindAll(dto: QueryDriversDto) {
    const result = await this.driversRepository.findAll({
      status: dto.status,
      search: dto.search,
      zoneId: dto.zoneId,
      page: dto.page ?? 1,
      limit: dto.limit ?? 20,
    });

    const ids = (result.drivers as any[]).map((d) => d.id);
    const [liveMap, persistedMap] = await Promise.all([
      this.locationRepository.getLiveDriverLocations(ids),
      this.locationRepository.getPersistedDriverLocations(ids),
    ]);

    return {
      ...result,
      drivers: (result.drivers as any[]).map((d) => {
        const { lastLocation, ...rest } = d;
        const loc = liveMap.get(d.id) ?? persistedMap.get(d.id) ?? null;
        return {
          ...rest,
          location: loc ? [loc.lng, loc.lat] : null,
          locationIsLive: liveMap.has(d.id),
        };
      }),
    };
  }

  async adminGetDriverLocation(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const [location, activeOrder] = await Promise.all([
      this.locationRepository.getDriverLocationWithState(driverId),
      this.locationRepository.getDriverActiveOrder(driverId),
    ]);

    return {
      driverId: driver.id,
      status: driver.status,
      latitude: location?.lat ?? null,
      longitude: location?.lng ?? null,
      isLive: location?.isLive ?? false,
      activeOrderId: activeOrder?.orderId ?? null,
    };
  }

  async adminFindOne(driverId: string) {
    const driver = await this.driversRepository.findOneAdmin(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  async adminSuspend(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    this.socketService.disconnectUser(driver.userId);
    await this.locationRepository.removeDriverLocation(driver.id);

    const openBreak = await this.driversRepository.findActiveBreak(driverId);
    if (openBreak) {
      await this.finishBreak(openBreak.id, false);
    }
    const pendingBreak =
      await this.driversRepository.findPendingBreak(driverId);
    if (pendingBreak) {
      await this.driversRepository.cancelBreak(pendingBreak.id);
    }

    const result = await this.driversRepository.updateStatus(
      driverId,
      DriverStatus.SUSPENDED,
    );

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        driver.id,
        driver.userId,
        driver.status,
        DriverStatus.SUSPENDED,
      ),
    );

    return result;
  }

  async adminUnsuspend(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const result = await this.driversRepository.updateStatus(
      driverId,
      DriverStatus.OFFLINE,
    );

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        driver.id,
        driver.userId,
        driver.status,
        DriverStatus.OFFLINE,
      ),
    );

    return result;
  }

  async adminCreateShift(driverId: string, dto: CreateDriverShiftDto) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const startTime = new Date(dto.startTime);
    const endTime = new Date(dto.endTime);

    if (endTime <= startTime) {
      throw new BadRequestException(DriverErrors.END_TIME_BEFORE_START);
    }

    const overlap = await this.driversRepository.findOverlappingShift(
      driver.id,
      startTime,
      endTime,
    );
    if (overlap) throw new ConflictException(DriverErrors.SHIFT_OVERLAPS);

    return this.driversRepository.createShift({
      driverId: driver.id,
      zoneId: dto.zoneId ?? null,
      startTime,
      endTime,
    });
  }

  async adminGetShifts(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return this.driversRepository.findShiftsByDriver(driver.id);
  }

  async adminGetBreaks(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return this.driversRepository.findBreaksByDriver(driver.id, 50);
  }

  // ─── Internal helper used by dispatch ────────────────────────────────────

  async getDriverByUserId(userId: string) {
    const driver = await this.driversRepository.findByUserId(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  private async assertDriver(userId: string) {
    const driver = await this.driversRepository.findByUserId(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  /**
   * Shared safety gate for request / approve / grant: the driver must be
   * breakable right now (approved, not suspended, not busy/delivering/on
   * break, no live order, no pending dispatch, no other active break).
   */
  private async assertCanBreak(driverId: string) {
    const driver = await this.driversRepository.findById(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

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
