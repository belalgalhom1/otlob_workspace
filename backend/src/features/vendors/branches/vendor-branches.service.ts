import {
  Injectable,
  NotFoundException,
  Logger,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import {
  CreateVendorBranchDto,
  UpdateVendorBranchDto,
} from './dto/vendor-branch.dto';
import {
  VendorBranchErrors,
  VendorErrors,
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
  ) {}

  // ─── List all branches of a vendor ────────────────────────────────────────

  async findAll(vendorId: string) {
    await this.assertVendorExists(vendorId);

    // Raw SQL to include the PostGIS location as GeoJSON — same pattern as
    // addresses and zones in this codebase.
    return this.prisma.$queryRaw<any[]>`
      SELECT
        vb.id,
        vb.name,
        vb."nameAr",
        vb.address,
        vb.phone,
        vb."isOpen",
        vb."isContracted",
        vb."commissionRate",
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
    return rows[0];
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async create(vendorId: string, dto: CreateVendorBranchDto) {
    await this.assertVendorExists(vendorId);

    const [lat, lng] = dto.location;
    const resolvedZoneId = await this.resolveValidZoneForLocation(
      dto.location,
      dto.zoneId,
    );

    const id = crypto.randomUUID();

    await this.prisma.$executeRaw`
      INSERT INTO vendor_branches (
        id, "vendorId", name, "nameAr", address, phone, "isOpen", "isContracted", "commissionRate",
        location, "zoneId", "updatedAt"
      ) VALUES (
        ${id},
        ${vendorId},
        ${dto.name},
        ${dto.nameAr ?? null},
        ${dto.address},
        ${dto.phone ?? null},
        ${dto.isOpen ?? true},
        ${dto.isContracted ?? null},
        ${dto.commissionRate ?? null},
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
    const { location, ...scalarFields } = dto;

    if (Object.keys(scalarFields).length > 0 || finalZoneId !== branch.zoneId) {
      await this.prisma.vendorBranch.update({
        where: { id: branchId },
        data: {
          ...(scalarFields.name !== undefined && { name: scalarFields.name }),
          ...(scalarFields.nameAr !== undefined && {
            nameAr: scalarFields.nameAr,
          }),
          ...(scalarFields.address !== undefined && {
            address: scalarFields.address,
          }),
          ...(scalarFields.phone !== undefined && {
            phone: scalarFields.phone,
          }),
          ...(scalarFields.isOpen !== undefined && {
            isOpen: scalarFields.isOpen,
          }),
          ...(scalarFields.isContracted !== undefined && {
            isContracted: scalarFields.isContracted,
          }),
          ...(scalarFields.commissionRate !== undefined && {
            commissionRate: scalarFields.commissionRate,
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
    await this.cacheManager.del(`vendor_details_${vendorId}`);
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      select: { slug: true },
    });
    if (vendor?.slug) {
      await this.cacheManager.del(`vendor_slug_details_${vendor.slug}`);
    }
  }

  private async assertVendorExists(vendorId: string) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, deletedAt: null },
      select: { id: true },
    });
    if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);
  }

  private async resolveValidZoneForLocation(
    location: [number, number],
    requestedZoneId?: string,
  ): Promise<string> {
    const [lat, lng] = location;

    // 1. If a specific zone was requested, check if it contains the location
    if (requestedZoneId) {
      const result = await this.prisma.$queryRaw<any[]>`
        SELECT id FROM zones
        WHERE id = ${requestedZoneId}
        AND ST_Contains(boundary, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326))
        AND "isActive" = true
        LIMIT 1
      `;
      if (result.length > 0) {
        return requestedZoneId;
      }
      this.logger.warn(
        `Requested zone ${requestedZoneId} does not contain location [${lat}, ${lng}]. Checking other active zones...`,
      );
    }

    // 2. Auto-detect which active zone contains the location
    const autoZone = await this.prisma.$queryRaw<any[]>`
      SELECT id FROM zones
      WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326))
      AND "isActive" = true
      ORDER BY ST_Area(boundary) ASC
      LIMIT 1
    `;

    if (!autoZone.length) {
      throw new BadRequestException(ZoneErrors.INVALID_LOCATION_FOR_ZONE);
    }

    if (requestedZoneId && requestedZoneId !== autoZone[0].id) {
      this.logger.log(
        `Auto-reassigned branch from requested zone ${requestedZoneId} to containing zone ${autoZone[0].id}`,
      );
    }

    return autoZone[0].id;
  }
}
