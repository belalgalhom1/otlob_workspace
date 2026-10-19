import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  CreateZoneDto,
  UpdateZoneDto,
  CheckLocationDto,
  SearchCustomersInPolygonDto,
} from './dto/zone.dto';
import {
  ZoneErrors,
  CommonSuccess,
} from 'src/common/constants/response.constants';
import * as crypto from 'crypto';

export interface ZoneQueryResult {
  id: string;
  name: string;
  nameAr: string | null;
  isActive: boolean;
  baseDeliveryFeeOverride: number | null;
  minOrderAmountOverride: number | null;
  createdAt: Date;
  updatedAt: Date;
  boundary: Record<string, unknown>;
}

export interface ZoneLocationResult {
  id: string;
  name: string;
  nameAr: string | null;
  isActive: boolean;
  baseDeliveryFeeOverride: number | null;
  minOrderAmountOverride: number | null;
}

@Injectable()
export class ZonesService {
  private readonly logger = new Logger(ZonesService.name);

  constructor(private readonly prisma: PrismaService) {}

  async createZone(dto: CreateZoneDto) {
    const id = crypto.randomUUID();

    const geoJson = JSON.stringify({
      type: 'Polygon',
      coordinates: dto.boundary,
    });

    await this.assertValidPolygon(geoJson);

    try {
      await this.prisma.$executeRaw`
        INSERT INTO "zones" (
          "id", "name", "nameAr", "isActive", 
          "baseDeliveryFeeOverride", "minOrderAmountOverride", 
          "boundary", "createdAt", "updatedAt"
        ) VALUES (
          ${id}, 
          ${dto.name}, 
          ${dto.nameAr ?? null}, 
          ${dto.isActive ?? true}, 
          ${dto.baseDeliveryFeeOverride ?? null}, 
          ${dto.minOrderAmountOverride ?? null}, 
          ST_SetSRID(ST_GeomFromGeoJSON(${geoJson}), 4326), 
          NOW(), 
          NOW()
        );
      `;

      return await this.getZoneById(id);
    } catch (error: unknown) {
      throw new BadRequestException(ZoneErrors.INVALID_BOUNDARY);
    }
  }

  /**
   * A self-intersecting (or otherwise malformed) polygon is stored happily by
   * PostGIS but makes ST_Contains/ST_Covers unreliable — interior points get
   * reported as outside — so a driver physically inside the zone is told they
   * are not. Reject such boundaries at write time and force a redraw.
   */
  private async assertValidPolygon(geoJson: string): Promise<void> {
    let valid = false;
    let reason = 'unknown';
    try {
      const rows = await this.prisma.$queryRaw<
        { valid: boolean; reason: string | null }[]
      >`
        SELECT ST_IsValid(g) AS valid, ST_IsValidReason(g) AS reason
        FROM (SELECT ST_SetSRID(ST_GeomFromGeoJSON(${geoJson}), 4326) AS g) t
      `;
      valid = rows[0]?.valid === true;
      reason = rows[0]?.reason ?? 'unknown';
    } catch (error: unknown) {
      reason = (error as Error).message;
    }

    if (!valid) {
      this.logger.warn(`Rejected invalid zone boundary: ${reason}`);
      throw new BadRequestException(ZoneErrors.INVALID_BOUNDARY);
    }
  }

  async getAllZones(): Promise<ZoneQueryResult[]> {
    const zones = await this.prisma.$queryRaw<ZoneQueryResult[]>`
      SELECT 
        "id", "name", "nameAr", "isActive", 
        "baseDeliveryFeeOverride", "minOrderAmountOverride",
        "createdAt", "updatedAt",
        ST_AsGeoJSON("boundary")::json AS boundary
      FROM "zones"
      ORDER BY "createdAt" DESC;
    `;
    return zones;
  }

  async getZoneById(id: string): Promise<ZoneQueryResult> {
    const zones = await this.prisma.$queryRaw<ZoneQueryResult[]>`
      SELECT 
        "id", "name", "nameAr", "isActive", 
        "baseDeliveryFeeOverride", "minOrderAmountOverride",
        "createdAt", "updatedAt",
        ST_AsGeoJSON("boundary")::json AS boundary
      FROM "zones"
      WHERE "id" = ${id};
    `;

    if (!zones || zones.length === 0) {
      throw new NotFoundException(ZoneErrors.NOT_FOUND);
    }

    return zones[0];
  }

  async findZoneByLocation(dto: CheckLocationDto): Promise<ZoneLocationResult> {
    const zones = await this.prisma.$queryRaw<ZoneLocationResult[]>`
      SELECT 
        "id", "name", "nameAr", "isActive",
        "baseDeliveryFeeOverride", "minOrderAmountOverride"
      FROM "zones"
      WHERE ST_Contains("boundary", ST_SetSRID(ST_MakePoint(${dto.longitude}, ${dto.latitude}), 4326))
      AND "isActive" = true
      ORDER BY ST_Area("boundary") ASC
      LIMIT 1;
    `;

    if (!zones || zones.length === 0) {
      throw new NotFoundException(ZoneErrors.NOT_FOUND);
    }

    return zones[0];
  }

  async updateZone(id: string, dto: UpdateZoneDto): Promise<ZoneQueryResult> {
    await this.getZoneById(id);

    const { boundary: _boundary, ...standardFields } = dto;

    let geoJson: string | null = null;
    if (dto.boundary) {
      geoJson = JSON.stringify({
        type: 'Polygon',
        coordinates: dto.boundary,
      });
      await this.assertValidPolygon(geoJson);
    }

    // Geometry + scalar fields must land together: a partial failure used to
    // leave a zone with a new boundary but stale metadata (or vice-versa).
    try {
      await this.prisma.$transaction(async (tx) => {
        if (geoJson) {
          await tx.$executeRaw`
            UPDATE "zones" SET 
              "boundary" = ST_SetSRID(ST_GeomFromGeoJSON(${geoJson}), 4326),
              "updatedAt" = NOW()
            WHERE "id" = ${id};
          `;
        }
        if (Object.keys(standardFields).length > 0) {
          await tx.zone.update({
            where: { id },
            data: standardFields,
          });
        }
        if (!geoJson && Object.keys(standardFields).length > 0) {
          // keep updatedAt fresh even on scalar-only edits
          await tx.$executeRaw`UPDATE "zones" SET "updatedAt" = NOW() WHERE "id" = ${id};`;
        }
      });
    } catch (error: unknown) {
      throw new BadRequestException(ZoneErrors.INVALID_BOUNDARY);
    }

    return this.getZoneById(id);
  }

  async deleteZone(id: string) {
    await this.getZoneById(id);

    // Branches living under a soft-deleted store are invisible in the admin UI.
    // They cannot hold the zone hostage — they are cleaned up with the zone
    // below. Only branches owned by ACTIVE stores are real blockers: report
    // exactly which ones so the caller can act on them instead of seeing a
    // bare "zone has branches" key.
    const blockingBranches = await this.prisma.vendorBranch.findMany({
      where: { zoneId: id },
      select: {
        id: true,
        name: true,
        nameAr: true,
        vendor: {
          select: {
            id: true,
            storeName: true,
            storeNameAr: true,
            deletedAt: true,
          },
        },
      },
    });

    const activeStoreBranches = blockingBranches.filter(
      (b) => b.vendor.deletedAt === null,
    );

    if (activeStoreBranches.length > 0) {
      throw new BadRequestException({
        key: ZoneErrors.ZONE_HAS_BRANCHES,
        errors: {
          branches: activeStoreBranches.map((b) => ({
            id: b.id,
            name: b.name,
            nameAr: b.nameAr,
            vendorId: b.vendor.id,
            vendorName: b.vendor.storeName,
            vendorNameAr: b.vendor.storeNameAr,
          })),
        },
      });
    }

    // Only orphaned branches (soft-deleted stores) reference this zone. Their
    // order/member history is detached before they are dropped alongside the
    // zone so the FK never blocks the delete.
    await this.prisma.$transaction(async (tx) => {
      const orphanBranchIds = blockingBranches.map((b) => b.id);
      if (orphanBranchIds.length > 0) {
        await tx.order.updateMany({
          where: { vendorBranchId: { in: orphanBranchIds } },
          data: { vendorBranchId: null },
        });
        await tx.vendorMember.updateMany({
          where: { branchId: { in: orphanBranchIds } },
          data: { branchId: null },
        });
        await tx.vendorBranch.deleteMany({
          where: { id: { in: orphanBranchIds } },
        });
      }
      await tx.zone.delete({ where: { id } });
    });

    return { message: CommonSuccess.RESOURCE_DELETED };
  }

  async searchCustomersInPolygon(dto: SearchCustomersInPolygonDto) {
    const geoJson = JSON.stringify({
      type: 'Polygon',
      coordinates: dto.polygon,
    });

    try {
      const customers = await this.prisma.$queryRaw`
        SELECT 
          c.id as "customerId", 
          u.name as "customerName", 
          u.email, 
          u.phone,
          c."createdAt" as "registrationDate",
          (SELECT COUNT(*)::int FROM "orders" o WHERE o."customerId" = c.id AND o."deletedAt" IS NULL) as "ordersCount",
          (SELECT MAX("createdAt") FROM "orders" o WHERE o."customerId" = c.id AND o."deletedAt" IS NULL) as "lastOrderDate",
          json_agg(
            json_build_object(
              'id', a.id,
              'label', a.label,
              'address', a.address,
              'isDefault', a."isDefault",
              'location', ST_AsGeoJSON(a."location")::json
            )
          ) as "matchedAddresses"
        FROM "customers" c
        JOIN "users" u ON c."userId" = u.id
        JOIN "addresses" a ON a."customerId" = c.id
        WHERE ST_Within(a."location", ST_SetSRID(ST_GeomFromGeoJSON(${geoJson}), 4326))
        GROUP BY c.id, u.id
      `;

      return {
        count: Array.isArray(customers) ? customers.length : 0,
        customers: customers,
      };
    } catch (error: unknown) {
      this.logger.error('Error searching customers in polygon', error);
      throw new BadRequestException(ZoneErrors.INVALID_POLYGON);
    }
  }
}
