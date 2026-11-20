import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverShiftStatus, DriverStatus } from '@prisma/client';
import { DriverErrors } from 'src/common/constants/response.constants';
import { DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { LocationRepository } from '../location/location.repository';
import { DriverBreaksService } from './driver-breaks.service';
import { requireDriverByUserId } from './driver-lookup.helper';
import { DriversRepository } from './drivers.repository';
import { CreateDriverShiftDto } from './dto/driver.dto';

@Injectable()
export class DriverShiftExecutionService {
  private readonly logger = new Logger(DriverShiftExecutionService.name);

  constructor(
    private readonly driversRepository: DriversRepository,
    private readonly storage: StorageService,
    private readonly locationRepository: LocationRepository,
    private readonly driverTracking: DriverTrackingService,
    private readonly driverBreaksService: DriverBreaksService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async createShift(userId: string, dto: CreateDriverShiftDto) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);

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
    const driver = await requireDriverByUserId(this.driversRepository, userId);
    return this.driversRepository.findShiftsByDriver(driver.id);
  }

  async deleteMyShift(userId: string) {
    const driver = await this.driversRepository.findByUserIdWithUser(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    throw new BadRequestException(
      'Drivers cannot cancel assigned shifts. Please contact your manager or support.',
    );
  }

  async startShift(
    userId: string,
    shiftId: string,
    file?: Express.Multer.File,
    latitude?: number,
    longitude?: number,
  ) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
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

    const now = new Date();
    const EARLY_START_WINDOW_MS = 15 * 60 * 1000;
    if (
      shift.startTime &&
      now.getTime() < shift.startTime.getTime() - EARLY_START_WINDOW_MS
    ) {
      throw new BadRequestException(DriverErrors.SHIFT_TOO_EARLY);
    }
    if (shift.endTime && now.getTime() > shift.endTime.getTime()) {
      throw new BadRequestException(DriverErrors.SHIFT_ALREADY_ENDED);
    }

    if (!file) {
      throw new BadRequestException(DriverErrors.START_PHOTO_REQUIRED);
    }

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

    // Late start > 5 minutes after scheduled start demotes tier as penalty.
    try {
      const checkTime = new Date();
      const lateStartThreshold = shift.startTime
        ? new Date(shift.startTime.getTime() + 5 * 60 * 1000)
        : null;
      if (lateStartThreshold && checkTime > lateStartThreshold) {
        const fullDriver = await this.driversRepository.findById(driver.id);
        if (fullDriver) {
          let newTier = fullDriver.tier;
          if (newTier === 'GOLD') newTier = 'SILVER';
          else if (newTier === 'SILVER') newTier = 'BRONZE';
          if (newTier !== fullDriver.tier) {
            await this.driversRepository.update(fullDriver.id, {
              tier: newTier,
            });
          }
        }
      }
    } catch (e: unknown) {
      this.logger.error(
        `Failed to apply late start penalty: ${e instanceof Error ? e.message : String(e)}`,
      );
    }

    await this.driversRepository
      .updateShift(shiftId, { startPhotoUrl: photoUrl })
      .catch((e: unknown) =>
        this.logger.error(
          `Failed to save shift start photo: ${e instanceof Error ? e.message : String(e)}`,
        ),
      );

    const fresh = await this.driversRepository.findById(driver.id);
    if (fresh && fresh.status === DriverStatus.OFFLINE) {
      await this.driversRepository.updateStatus(driver.id, DriverStatus.ONLINE);
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

    if (
      typeof latitude === 'number' &&
      typeof longitude === 'number' &&
      Number.isFinite(latitude) &&
      Number.isFinite(longitude)
    ) {
      await this.driverTracking.trackDriverLocation(
        driver.id,
        longitude,
        latitude,
      );
      await this.driversRepository.updateLastLocation(
        driver.id,
        longitude,
        latitude,
      );
    }

    return startedShift;
  }

  async endShift(userId: string, shiftId: string) {
    const driver = await requireDriverByUserId(this.driversRepository, userId);
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

    return this.finalizeShift({
      driverId: driver.id,
      userId,
      shiftId,
      reason: 'Shift ended.',
      throwOnInactive: true,
    });
  }

  async endShiftBySystem(driverId: string, shiftId: string) {
    // Never end a shift while mid-delivery: leave ACTIVE for the next sweep.
    const driverById = await this.driversRepository.findById(driverId);
    if (!driverById || driverById.status === DriverStatus.ON_DELIVERY) {
      return;
    }

    const shift = await this.driversRepository.findShiftById(shiftId, driverId);
    if (!shift || shift.status !== DriverShiftStatus.ACTIVE) {
      return;
    }

    return this.finalizeShift({
      driverId,
      userId: driverById.userId,
      shiftId,
      reason: 'Shift ended by system.',
      throwOnInactive: false,
    });
  }

  private async finalizeShift(params: {
    driverId: string;
    userId: string;
    shiftId: string;
    reason: string;
    throwOnInactive: boolean;
  }) {
    const openBreak = await this.driversRepository.findActiveBreak(
      params.driverId,
    );
    if (openBreak) {
      await this.driverBreaksService.finishBreak(openBreak.id, false);
    }
    const pendingBreak = await this.driversRepository.findPendingBreak(
      params.driverId,
    );
    if (pendingBreak) {
      await this.driversRepository.cancelBreak(pendingBreak.id);
    }

    const [totalDeliveries, totalEarnings] = await Promise.all([
      this.driversRepository.countDeliveredOrdersInShift(params.shiftId),
      this.driversRepository.sumShiftEarnings(params.shiftId),
    ]);

    let updatedShift;
    try {
      updatedShift = await this.driversRepository.endShiftSafely(
        params.shiftId,
        {
          status: DriverShiftStatus.COMPLETED,
          actualEnd: new Date(),
          totalDeliveries,
          totalEarnings,
        },
      );
    } catch {
      if (params.throwOnInactive) {
        throw new BadRequestException(DriverErrors.SHIFT_NOT_ACTIVE);
      }
      return undefined;
    }

    const endedStatus = (await this.driversRepository.findById(params.driverId))
      ?.status;
    if (endedStatus && endedStatus !== DriverStatus.OFFLINE) {
      await this.driversRepository.updateStatus(
        params.driverId,
        DriverStatus.OFFLINE,
      );
      const pos = await this.driverTracking.getDriverLocation(params.driverId);
      if (pos) {
        await this.driversRepository.updateLastLocation(
          params.driverId,
          pos.lng,
          pos.lat,
        );
      }
      await this.driverTracking.removeDriverLocation(params.driverId);
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          params.driverId,
          params.userId,
          endedStatus,
          DriverStatus.OFFLINE,
          params.reason,
        ),
      );
    }

    const fullDriver = await this.driversRepository.findById(params.driverId);
    if (
      fullDriver &&
      updatedShift.rejectedDispatches === 0 &&
      updatedShift.expiredDispatches === 0
    ) {
      let newTier = fullDriver.tier;
      if (newTier === 'BRONZE') newTier = 'SILVER';
      else if (newTier === 'SILVER') newTier = 'GOLD';

      if (newTier !== fullDriver.tier) {
        await this.driversRepository.update(fullDriver.id, { tier: newTier });
      }
    }

    return updatedShift;
  }
}
