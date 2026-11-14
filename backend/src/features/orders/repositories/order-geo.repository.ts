import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';

export interface NearestBranchLocationResult {
  id: string;
  zoneId: string | null;
  lng: number;
  lat: number;
  isContracted: boolean | null;
  commissionRate?: number | null;
  name?: string;
  nameAr?: string | null;
  address?: string | null;
  phone?: string | null;
}

/**
 * PostGIS spatial lookups required during order placement & quote calculation.
 */
@Injectable()
export class OrderGeoRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getZoneAtLocation(lng: number, lat: number) {
    const rows = await this.prisma.$queryRaw<
      Array<{
        id: string;
        baseDeliveryFeeOverride: number | null;
        minOrderAmountOverride: number | null;
      }>
    >`
      SELECT id, "baseDeliveryFeeOverride", "minOrderAmountOverride"
      FROM zones
      WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326))
        AND "isActive" = true
      ORDER BY ST_Area(boundary) ASC
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  async getNearestOpenBranchLocation(
    vendorId: string,
    toLng: number,
    toLat: number,
    zoneId?: string,
    productIds: string[] = [],
  ): Promise<NearestBranchLocationResult | null> {
    const zoneFilter = zoneId
      ? Prisma.sql`
        AND ST_Contains(
          (SELECT boundary FROM zones WHERE id = ${zoneId} AND "isActive" = true),
          "location"
        )`
      : Prisma.empty;
    // Prefer the nearest branch that can actually fulfil every cart line.
    // ALL products pass; SPECIFIC products need a matching availability row.
    const availabilityFilter =
      productIds.length > 0
        ? Prisma.sql`
          AND NOT EXISTS (
            SELECT 1
            FROM products p
            LEFT JOIN menu_categories c ON c.id = p."categoryId"
            WHERE p.id IN (${Prisma.join(productIds)})
              AND (
                (
                  p."branchAvailabilityMode" = 'SPECIFIC'
                  AND NOT EXISTS (
                    SELECT 1
                    FROM product_branch_availability pba
                    WHERE pba."productId" = p.id
                      AND pba."branchId" = vendor_branches.id
                  )
                )
                OR
                (
                  c."branchAvailabilityMode" = 'SPECIFIC'
                  AND NOT EXISTS (
                    SELECT 1
                    FROM category_branch_availability cba
                    WHERE cba."categoryId" = c.id
                      AND cba."branchId" = vendor_branches.id
                  )
                )
              )
          )`
        : Prisma.empty;
    const rows = await this.prisma.$queryRaw<
      Array<{
        id: string;
        zoneId: string | null;
        isContracted: boolean | null;
        commissionRate: number | null;
        lng: number;
        lat: number;
      }>
    >`
      SELECT
        id,
        name,
        "nameAr",
        address,
        phone,
        "zoneId",
        "isContracted",
        "commissionRate",
        ST_X(location::geometry) AS lng,
        ST_Y(location::geometry) AS lat
      FROM vendor_branches
      WHERE "vendorId"::text = ${vendorId}::text
        AND "isOpen" = true
        ${zoneFilter}
        ${availabilityFilter}
      ORDER BY
        ST_Distance(
          location::geography,
          ST_SetSRID(ST_MakePoint(${toLng}, ${toLat}), 4326)::geography
        ) ASC
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  async getDistanceKm(
    fromLng: number,
    fromLat: number,
    toLng: number,
    toLat: number,
  ): Promise<number> {
    const rows = await this.prisma.$queryRaw<Array<{ km: number }>>`
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint(${fromLng}, ${fromLat}), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${toLng}, ${toLat}), 4326)::geography
      ) / 1000 AS km
    `;
    return Number(rows[0]?.km ?? 3);
  }
}
