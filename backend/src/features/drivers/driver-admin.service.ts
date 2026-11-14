import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverStatus, Role } from '@prisma/client';
import { DriverErrors } from 'src/common/constants/response.constants';
import { AuditLogCreatedEvent, DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { DriverBreaksService } from './driver-breaks.service';
import { requireDriverById } from './driver-lookup.helper';
import { DriverManagersService } from './driver-managers.service';
import { DriversRepository } from './drivers.repository';
import { CreateDriverShiftDto, QueryDriversDto } from './dto/driver.dto';

@Injectable()
export class DriverAdminService {
  private readonly logger = new Logger(DriverAdminService.name);

  constructor(
    private readonly driversRepository: DriversRepository,
    private readonly prisma: PrismaService,
    private readonly driverManagersService: DriverManagersService,
    private readonly driverTracking: DriverTrackingService,
    private readonly driverBreaksService: DriverBreaksService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async adminCreateDriver(userId: string, adminId: string, dto: any) {
    const existing = await this.driversRepository.findByUserId(userId);
    if (existing) throw new ConflictException(DriverErrors.PROFILE_EXISTS);

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

    if (dto.driverManagerUserId) {
      const dm = await this.ensureManagerRecord(dto.driverManagerUserId);
      if (dm) {
        await this.prisma.driverManagerAssignment.create({
          data: {
            driverManagerId: dm.id,
            driverId: driver.id,
          },
        });
      }
    }

    this.logAdminAction(adminId, 'CREATE', 'Driver', driver.id, null, dto);

    this.logger.log(`Admin ${adminId} created driver ${driver.id}`);
    return this.driversRepository.findById(driver.id);
  }

  async adminUpdateDriver(driverId: string, adminId: string, dto: any) {
    const driver = await requireDriverById(this.driversRepository, driverId);

    const actor = await this.prisma.user.findUnique({
      where: { id: adminId },
      select: { role: true },
    });
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(adminId, driverId);
    }

    const oldValues = { ...driver };

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
          await this.driverBreaksService.finishBreak(openBreak.id, false);
        }
      }
    }

    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.nationalId !== undefined) updateData.nationalId = dto.nationalId;
    if (dto.licenseNumber !== undefined) {
      updateData.licenseNumber = dto.licenseNumber;
    }
    if (dto.vehicleType !== undefined) updateData.vehicleType = dto.vehicleType;
    if (dto.vehiclePlate !== undefined) {
      updateData.vehiclePlate = dto.vehiclePlate;
    }
    if (dto.status !== undefined) updateData.status = dto.status;
    if (dto.tier !== undefined) updateData.tier = dto.tier;
    if (dto.isApproved !== undefined) {
      updateData.isApproved = dto.isApproved;
      if (dto.isApproved) {
        updateData.approvedAt = new Date();
        updateData.approvedById = adminId;
      }
    }

    if (dto.driverManagerUserId !== undefined) {
      if (!dto.driverManagerUserId) {
        await this.prisma.driverManagerAssignment.deleteMany({
          where: { driverId },
        });
      } else {
        const dm = await this.ensureManagerRecord(dto.driverManagerUserId);
        if (dm) {
          await this.prisma.driverManagerAssignment.upsert({
            where: { driverId },
            create: {
              driverId,
              driverManagerId: dm.id,
            },
            update: {
              driverManagerId: dm.id,
            },
          });
        }
      }
    }

    await this.driversRepository.update(driverId, updateData);

    this.logAdminAction(
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

  async adminFindAll(dto: QueryDriversDto, actor?: JwtAccessPayload) {
    let allowedDriverIds: string[] | undefined;
    if (actor?.role === Role.DRIVER_MANAGER) {
      allowedDriverIds =
        await this.driverManagersService.getManagedDriverIds(actor.sub);
    }

    const result = await this.driversRepository.findAll({
      status: dto.status,
      search: dto.search,
      zoneId: dto.zoneId,
      driverIds: allowedDriverIds,
      page: dto.page ?? 1,
      limit: dto.limit ?? 20,
    });

    const ids = (result.drivers as any[]).map((d) => d.id);
    const [liveMap, persistedMap] = await Promise.all([
      this.driverTracking.getLiveDriverLocations(ids),
      this.driverTracking.getPersistedDriverLocations(ids),
    ]);

    return {
      ...result,
      drivers: (result.drivers as any[]).map((d) => {
        const { managerAssignment, ...rest } = d;
        delete rest.lastLocation;
        const liveInfo = liveMap.get(d.id);
        const persistedInfo = persistedMap.get(d.id);
        const loc = liveInfo
          ? { lng: liveInfo.lng, lat: liveInfo.lat }
          : (persistedInfo ?? null);
        return {
          ...rest,
          driverManager: managerAssignment?.driverManager
            ? {
                id: managerAssignment.driverManager.id,
                userId: managerAssignment.driverManager.userId,
                name: managerAssignment.driverManager.user?.name,
                phone: managerAssignment.driverManager.user?.phone,
              }
            : null,
          location: loc ? [loc.lng, loc.lat] : null,
          locationIsLive: liveInfo?.isFresh ?? false,
        };
      }),
    };
  }

  async adminGetDriverLocation(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);

    const [location, activeOrder] = await Promise.all([
      this.driverTracking.getDriverLocationWithState(driverId),
      this.driverTracking.getDriverActiveOrder(driverId),
    ]);

    return {
      driverId: driver.id,
      status: driver.status,
      latitude: location?.lat ?? null,
      longitude: location?.lng ?? null,
      isLive: location?.isLive ?? false,
      activeOrderId:
        activeOrder?.orderId ??
        (await this.driversRepository.findActiveOrderForDriver(driverId))?.id ??
        null,
    };
  }

  async adminFindOne(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await this.driversRepository.findOneAdmin(driverId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    if (actor?.role === Role.DRIVER_MANAGER) {
      return {
        ...driver,
        nationalId: driver.nationalId
          ? '***' + driver.nationalId.slice(-4)
          : null,
        licenseNumber: driver.licenseNumber
          ? '***' + driver.licenseNumber.slice(-4)
          : null,
      };
    }
    return driver;
  }

  async adminSuspend(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);

    await this.driverTracking.removeDriverLocation(driver.id);

    const openBreak = await this.driversRepository.findActiveBreak(driverId);
    if (openBreak) {
      await this.driverBreaksService.finishBreak(openBreak.id, false);
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

  async adminUnsuspend(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);
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

  async adminCreateShift(
    driverId: string,
    dto: CreateDriverShiftDto,
    actor?: JwtAccessPayload,
  ) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);

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

  async adminGetShifts(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);
    return this.driversRepository.findShiftsByDriver(driver.id);
  }

  async adminGetBreaks(driverId: string, actor?: JwtAccessPayload) {
    await this.assertManagedIfManager(driverId, actor);
    const driver = await requireDriverById(this.driversRepository, driverId);
    return this.driversRepository.findBreaksByDriver(driver.id, 50);
  }

  private async assertManagedIfManager(
    driverId: string,
    actor?: JwtAccessPayload,
  ): Promise<void> {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(actor.sub, driverId);
    }
  }

  private async ensureManagerRecord(managerUserId: string) {
    let dm = await this.prisma.driverManager.findUnique({
      where: { userId: managerUserId },
    });
    if (!dm) {
      const dmUser = await this.prisma.user.findUnique({
        where: { id: managerUserId },
        select: { role: true },
      });
      if (dmUser?.role === Role.DRIVER_MANAGER) {
        dm = await this.prisma.driverManager.create({
          data: { userId: managerUserId },
        });
      }
    }
    return dm;
  }

  private logAdminAction(
    adminId: string,
    actionType: string,
    entityType: string,
    entityId: string,
    oldValues: unknown,
    newValues: unknown,
  ) {
    try {
      this.eventEmitter.emit(
        EVENTS.AUDIT_LOG_CREATED,
        new AuditLogCreatedEvent(
          adminId,
          null,
          null,
          actionType,
          `${actionType}_DRIVER_PROFILE`,
          entityType,
          entityId,
          newValues,
          oldValues,
        ),
      );
    } catch (e) {
      this.logger.error('Failed to log admin action', e);
    }
  }
}
