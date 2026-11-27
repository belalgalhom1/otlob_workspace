import {
  Injectable,
  NotFoundException,
  Logger,
  BadRequestException,
  Inject,
  Optional,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { LocationRepository } from '../../location/location.repository';
import { VendorCacheService } from '../helpers/vendor-cache.service';
import { assertVendorExists } from '../helpers/vendor-lookup.helper';
import {
  evaluateBranchEffectiveOpen,
  isVendorScheduleOpen,
} from '../helpers/vendor-schedule.helper';
import {
  CreateVendorBranchDto,
  UpdateVendorBranchDto,
} from './dto/vendor-branch.dto';
import {
  VendorBranchErrors,
  ZoneErrors,
  CommonSuccess,
} from '../../../common/constants/response.constants';
import * as crypto from 'crypto';

@Injectable()
export class VendorBranchesService {
  private readonly logger = new Logger(VendorBranchesService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
    @Optional() private readonly vendorCache?: VendorCacheService,
    @Optional() private readonly locationRepository?: LocationRepository,
  ) {}

  // ─── List all branches of a vendor ────────────────────────────────────────

  async findAll(vendorId: string) {
    await assertVendorExists(this.prisma, vendorId);

    // Raw SQL to include the PostGIS location as GeoJSON — same pattern as
    // addresses and zones in this codebase.
    const rows = await this.prisma.$queryRaw<any[]>`
      SELECT
        vb.id,
        vb.name,
        vb."nameAr",
        vb.address,
        vb.phone,
        vb."isOpen",
        vb."isContracted",
        vb."commissionRate",
        vb."workingHours",
        vb."isScheduleActive",
        vb."is24Hours",
        vb."vendorId",
        vb."zoneId",
        vb."createdAt",
        vb."updatedAt",
        ST_AsGeoJSON(vb.location)::json AS location,
        json_build_object(
          'id',   z.id,
          'name', z.name
        ) AS zone
      FROM vendor_branches vb
      LEFT JOIN zones z ON z.id = vb."zoneId"
      WHERE vb."vendorId" = ${vendorId}
      ORDER BY vb."createdAt" ASC
    `;

    return rows.map((row) => this.enrichBranchScheduleStatus(row));
  }

  // ─── Get single branch ────────────────────────────────────────────────────

  async findOne(vendorId: string, branchId: string) {
    const rows = await this.prisma.$queryRaw<any[]>`
      SELECT
        vb.id,
        vb.name,
        vb."nameAr",
        vb.address,
        vb.phone,
        vb."isOpen",
        vb."isContracted",
        vb."commissionRate",
        vb."workingHours",
        vb."isScheduleActive",
        vb."is24Hours",
        vb."vendorId",
        vb."zoneId",
        vb."createdAt",
        vb."updatedAt",
        ST_AsGeoJSON(vb.location)::json AS location,
        json_build_object(
          'id',   z.id,
          'name', z.name
        ) AS zone
      FROM vendor_branches vb
      LEFT JOIN zones z ON z.id = vb."zoneId"
      WHERE vb.id = ${branchId}
        AND vb."vendorId" = ${vendorId}
    `;

    if (!rows.length) throw new NotFoundException(VendorBranchErrors.NOT_FOUND);
    return this.enrichBranchScheduleStatus(rows[0]);
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async create(vendorId: string, dto: CreateVendorBranchDto) {
    await assertVendorExists(this.prisma, vendorId);

    const [lat, lng] = dto.location;
    const resolvedZoneId = await this.resolveValidZoneForLocation(
      dto.location,
      dto.zoneId,
    );

    const id = crypto.randomUUID();
    const is24Hours = dto.is24Hours ?? false;
    const isScheduleActive = dto.isScheduleActive ?? true;
    const workingHoursJson = is24Hours
      ? JSON.stringify([])
      : dto.workingHours !== undefined
        ? JSON.stringify(dto.workingHours)
        : null;
    const initialIsOpen =
      dto.isOpen !== undefined
        ? dto.isOpen
        : is24Hours
          ? true
          : isScheduleActive && dto.workingHours !== undefined
            ? isVendorScheduleOpen(dto.workingHours)
            : true;

    await this.prisma.$executeRaw`
      INSERT INTO vendor_branches (
        id, "vendorId", name, "nameAr", address, phone, "isOpen", "isContracted", "commissionRate",
        "workingHours", "isScheduleActive", "is24Hours",
        location, "zoneId", "updatedAt"
      ) VALUES (
        ${id},
        ${vendorId},
        ${dto.name},
        ${dto.nameAr ?? null},
        ${dto.address},
        ${dto.phone ?? null},
        ${initialIsOpen},
        ${dto.isContracted ?? null},
        ${dto.commissionRate ?? null},
        CAST(${workingHoursJson} AS jsonb),
        ${isScheduleActive},
        ${is24Hours},
        ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326),
        ${resolvedZoneId},
        NOW()
      )
    `;

    this.logger.log(`Branch ${id} created for vendor ${vendorId}`);
    await this.invalidateZonesCache(vendorId);
    return this.findOne(vendorId, id);
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  async update(vendorId: string, branchId: string, dto: UpdateVendorBranchDto) {
    const branch = await this.findOne(vendorId, branchId); // 404 if not found

    let finalZoneId = dto.zoneId !== undefined ? dto.zoneId : branch.zoneId;
    const existingCoords = branch.location?.coordinates;
    const finalLocation: [number, number] | undefined =
      dto.location !== undefined
        ? dto.location
        : Array.isArray(existingCoords) && existingCoords.length >= 2
          ? [existingCoords[1], existingCoords[0]]
          : undefined;

    if (
      finalLocation &&
      (dto.zoneId !== undefined || dto.location !== undefined)
    ) {
      finalZoneId = await this.resolveValidZoneForLocation(
        finalLocation,
        finalZoneId,
      );
    }

    // Update location via raw SQL when provided; otherwise keep existing.
    if (dto.location) {
      const [lat, lng] = dto.location;
      await this.prisma.$executeRaw`
        UPDATE vendor_branches
        SET location = ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326),
            "updatedAt" = NOW()
        WHERE id = ${branchId} AND "vendorId" = ${vendorId}
      `;
    }

    // Update the remaining scalar fields through Prisma ORM.
    const hasScalarChanges = Object.entries(dto).some(
      ([key, value]) => key !== 'location' && value !== undefined,
    );

    if (hasScalarChanges || finalZoneId !== branch.zoneId) {
      const isManualOpenToggleOnly =
        dto.isOpen !== undefined &&
        dto.workingHours === undefined &&
        dto.isScheduleActive === undefined &&
        dto.is24Hours === undefined;

      const scheduleSettingsChanged =
        dto.workingHours !== undefined ||
        dto.isScheduleActive !== undefined ||
        dto.is24Hours !== undefined;

      const nextIs24Hours =
        dto.is24Hours !== undefined
          ? dto.is24Hours
          : branch.is24Hours === true;
      const nextIsScheduleActive =
        dto.isScheduleActive !== undefined
          ? dto.isScheduleActive
          : isManualOpenToggleOnly
            ? false
            : dto.workingHours !== undefined
              ? true
              : branch.isScheduleActive !== false;
      const nextWorkingHours =
        dto.workingHours !== undefined ? dto.workingHours : branch.workingHours;

      let computedIsOpen: boolean | undefined = dto.isOpen;
      if (computedIsOpen === undefined && scheduleSettingsChanged) {
        if (nextIs24Hours) {
          computedIsOpen = true;
        } else if (nextIsScheduleActive && nextWorkingHours) {
          computedIsOpen = isVendorScheduleOpen(nextWorkingHours);
        }
      }

      await this.prisma.vendorBranch.update({
        where: { id: branchId },
        data: {
          ...(dto.name !== undefined && { name: dto.name }),
          ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
          ...(dto.address !== undefined && { address: dto.address }),
          ...(dto.phone !== undefined && { phone: dto.phone }),
          ...(computedIsOpen !== undefined && { isOpen: computedIsOpen }),
          ...(dto.isContracted !== undefined && {
            isContracted: dto.isContracted,
          }),
          ...(dto.commissionRate !== undefined && {
            commissionRate: dto.commissionRate,
          }),
          ...(dto.workingHours !== undefined && {
            workingHours: dto.workingHours,
          }),
          ...(dto.workingHours !== undefined &&
            dto.isScheduleActive === undefined && {
              isScheduleActive: true,
            }),
          ...(isManualOpenToggleOnly && {
            isScheduleActive: false,
          }),
          ...(dto.isScheduleActive !== undefined && {
            isScheduleActive: dto.isScheduleActive,
          }),
          ...(dto.is24Hours !== undefined && {
            is24Hours: dto.is24Hours,
          }),
          ...(finalZoneId !== undefined && {
            zoneId: finalZoneId,
          }),
        },
      });
    }

    await this.invalidateZonesCache(vendorId);
    return this.findOne(vendorId, branchId);
  }

  private enrichBranchScheduleStatus(row: any) {
    const evalResult = evaluateBranchEffectiveOpen({
      isOpen: row.isOpen !== false,
      is24Hours: row.is24Hours === true,
      isScheduleActive: row.isScheduleActive !== false,
      workingHours: row.workingHours,
    });
    return {
      ...row,
      effectiveIsOpen: evalResult.isOpen,
      isClosedBySchedule: evalResult.isClosedBySchedule,
    };
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  async remove(vendorId: string, branchId: string) {
    await this.findOne(vendorId, branchId);

    await this.prisma.vendorBranch.delete({ where: { id: branchId } });

    this.logger.log(`Branch ${branchId} deleted from vendor ${vendorId}`);
    await this.invalidateZonesCache(vendorId);
    return { message: CommonSuccess.RESOURCE_DELETED };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private async invalidateZonesCache(vendorId: string) {
    if (this.vendorCache) {
      await this.vendorCache.invalidateVendorDetails(vendorId);
      return;
    }
    await new VendorCacheService(
      this.prisma,
      this.cacheManager,
    ).invalidateVendorDetails(vendorId);
  }

  private async resolveValidZoneForLocation(
    location: [number, number],
    requestedZoneId?: string,
  ): Promise<string> {
    const [lat, lng] = location;

    // 1. If a specific zone was requested, check if it contains the location
    if (requestedZoneId) {
      let containsRequested = false;
      if (this.locationRepository) {
        containsRequested = await this.locationRepository.isPointInZone(
          requestedZoneId,
          lng,
          lat,
          { activeOnly: true },
        );
      } else {
        const result = await this.prisma.$queryRaw<Array<{ id: string }>>`
          SELECT id FROM zones
          WHERE id = ${requestedZoneId}
            AND ST_Covers(
              ST_MakeValid("boundary"),
              ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)
            )
            AND "isActive" = true
          LIMIT 1
        `;
        containsRequested = result.length > 0;
      }

      if (containsRequested) {
        return requestedZoneId;
      }
      this.logger.warn(
        `Requested zone ${requestedZoneId} does not contain location [${lat}, ${lng}]. Checking other active zones...`,
      );
    }

    // 2. Auto-detect which active zone contains the location
    let detectedZoneId: string | null = null;
    if (this.locationRepository) {
      const zone = await this.locationRepository.findContainingActiveZone(
        lng,
        lat,
      );
      detectedZoneId = zone?.id ?? null;
    } else {
      const autoZone = await this.prisma.$queryRaw<Array<{ id: string }>>`
        SELECT id FROM zones
        WHERE ST_Covers(
            ST_MakeValid("boundary"),
            ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)
          )
          AND "isActive" = true
        ORDER BY ST_Area("boundary") ASC
        LIMIT 1
      `;
      detectedZoneId = autoZone[0]?.id ?? null;
    }

    if (!detectedZoneId) {
      throw new BadRequestException(ZoneErrors.INVALID_LOCATION_FOR_ZONE);
    }

    if (requestedZoneId && requestedZoneId !== detectedZoneId) {
      this.logger.log(
        `Auto-reassigned branch from requested zone ${requestedZoneId} to containing zone ${detectedZoneId}`,
      );
    }

    return detectedZoneId;
  }
}
