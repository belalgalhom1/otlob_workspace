import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
  Inject,
  Optional,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from 'src/infrastructure/prisma/prisma.service';
import { LocationRepository } from 'src/features/location/location.repository';
import { StorageService } from 'src/infrastructure/storage/storage.service';
import { PlatformSettingsService } from 'src/features/platform-settings/platform-settings.service';
import { VendorCacheService } from './helpers/vendor-cache.service';
import { evaluateBranchEffectiveOpen } from './helpers/vendor-schedule.helper';
import {
  CreateVendorDto,
  UpdateVendorDto,
  UpdateVendorStatusDto,
  QueryVendorsDto,
} from './dto/vendor.dto';
import { Prisma } from '@prisma/client';
import { randomBytes, randomUUID } from 'crypto';

import {
  CommonSuccess,
  VendorErrors,
} from 'src/common/constants/response.constants';

@Injectable()
export class VendorsService {
  private readonly logger = new Logger(VendorsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly platformSettings: PlatformSettingsService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
    @Optional() private readonly vendorCache?: VendorCacheService,
    @Optional() private readonly locationRepository?: LocationRepository,
  ) {}

  // ─── Admin: create ────────────────────────────────────────────────────────

  async create(dto: CreateVendorDto) {
    const base =
      dto.storeName
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .slice(0, 80) || 'vendor';

    let slug = base;
    let attempts = 0;

    const settings = await this.platformSettings.getSettings();

    while (attempts < 5) {
      try {
        return await this.prisma.vendor.create({
          data: {
            storeName: dto.storeName,
            storeNameAr: dto.storeNameAr ?? null,
            slug,
            description: dto.description ?? null,
            descriptionAr: dto.descriptionAr ?? null,
            verticalId: dto.verticalId,
            taxId: dto.taxId ?? null,
            commissionRate:
              dto.commissionRate ?? settings.defaultCommissionRate,
            phone: dto.phone ?? null,
            isContracted: dto.isContracted ?? false,
          },
          include: this.vendorIncludes(),
        });
      } catch (error) {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          if (attempts === 4) {
            slug = `${base}-${randomUUID()}`;
          } else {
            slug = `${base}-${randomBytes(3).toString('hex')}`;
          }
          attempts++;
          continue;
        }
        throw error;
      }
    }
    throw new ConflictException(VendorErrors.UNABLE_TO_GENERATE_SLUG);
  }

  // ─── Public / member: list ─────────────────────────────────────────────────

  async findAll(dto: QueryVendorsDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.VendorWhereInput = { deletedAt: null };

    if (dto.status) where.status = dto.status;
    if (dto.verticalId) where.verticalId = dto.verticalId;
    if (dto.search) {
      where.OR = [
        { storeName: { contains: dto.search, mode: 'insensitive' } },
        { storeNameAr: { contains: dto.search, mode: 'insensitive' } },
      ];
    }

    if (dto.minRating) {
      where.rating = { gte: dto.minRating };
    }

    let vendors: any[] = [];
    let total = 0;

    if (
      (dto.lat !== undefined &&
        dto.lng !== undefined &&
        (!dto.sortBy || dto.sortBy === 'distance')) ||
      dto.zoneId
    ) {
      // 1. Resolve target delivery zone (from dto.zoneId or containing/closest zone)
      let targetZoneId: string | null = dto.zoneId ?? null;
      if (!targetZoneId && dto.lat !== undefined && dto.lng !== undefined) {
        try {
          if (this.locationRepository) {
            const containing =
              await this.locationRepository.findContainingActiveZone(
                dto.lng,
                dto.lat,
              );
            targetZoneId = containing?.id ?? null;

            if (!targetZoneId) {
              targetZoneId =
                await this.locationRepository.findClosestActiveZoneId(
                  dto.lng,
                  dto.lat,
                );
            }
          } else {
            const containingZoneRows = await this.prisma.$queryRaw<
              { id: string }[]
            >`
              SELECT id FROM zones
              WHERE ST_Covers(
                  ST_MakeValid("boundary"),
                  ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)
                )
                AND "isActive" = true
              ORDER BY ST_Area("boundary") ASC
              LIMIT 1
            `;
            targetZoneId = containingZoneRows[0]?.id ?? null;

            if (!targetZoneId) {
              const closestZoneRows = await this.prisma.$queryRaw<
                { id: string }[]
              >`
                SELECT id FROM zones
                WHERE "isActive" = true
                ORDER BY ST_Distance(
                  "boundary"::geography,
                  ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)::geography
                ) ASC
                LIMIT 1
              `;
              targetZoneId = closestZoneRows[0]?.id ?? null;
            }
          }
        } catch (err) {
          this.logger.warn(`Zone resolution failed: ${err}`);
        }
      }

      // 2. Fetch best branch per vendor ranked by: inZone -> isOpen -> geodesic distance
      type NearestBranchRow = {
        vendorId: string;
        branchId: string;
        branchName: string;
        branchNameAr: string | null;
        branchAddress: string;
        branchIsOpen: boolean;
        branchIsContracted: boolean | null;
        branchCommissionRate: number | null;
        branchWorkingHours: Prisma.JsonValue;
        branchIsScheduleActive: boolean;
        branchIs24Hours: boolean;
        branchZoneId: string;
        inZone: boolean;
        distanceKm: number;
      };

      let nearestBranches: NearestBranchRow[] = [];
      const hasCoords = dto.lat !== undefined && dto.lng !== undefined;
      try {
        nearestBranches = await this.prisma.$queryRaw<NearestBranchRow[]>`
          WITH ranked_branches AS (
            SELECT
              vb."vendorId",
              vb.id AS "branchId",
              vb.name AS "branchName",
              vb."nameAr" AS "branchNameAr",
              vb.address AS "branchAddress",
              vb."isOpen" AS "branchIsOpen",
              vb."isContracted" AS "branchIsContracted",
              vb."commissionRate" AS "branchCommissionRate",
              vb."workingHours" AS "branchWorkingHours",
              vb."isScheduleActive" AS "branchIsScheduleActive",
              vb."is24Hours" AS "branchIs24Hours",
              vb."zoneId" AS "branchZoneId",
              ${targetZoneId ? Prisma.sql`(vb."zoneId" = ${targetZoneId})` : Prisma.sql`false`} AS "inZone",
              ${hasCoords ? Prisma.sql`ROUND((ST_Distance(vb.location::geography, ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)::geography) / 1000.0)::numeric, 1)::float` : Prisma.sql`0.0::float`} AS "distanceKm",
              ROW_NUMBER() OVER (
                PARTITION BY vb."vendorId"
                ORDER BY
                  (CASE WHEN ${targetZoneId ? Prisma.sql`vb."zoneId" = ${targetZoneId}` : Prisma.sql`false`} THEN 0 ELSE 1 END) ASC,
                  (CASE WHEN vb."isOpen" = true THEN 0 ELSE 1 END) ASC,
                  ${hasCoords ? Prisma.sql`ST_Distance(vb.location::geography, ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)::geography) ASC` : Prisma.sql`vb.id ASC`}
              ) AS rank
            FROM vendor_branches vb
            JOIN vendors v ON v.id = vb."vendorId"
            WHERE v."deletedAt" IS NULL
          )
          SELECT
            "vendorId",
            "branchId",
            "branchName",
            "branchNameAr",
            "branchAddress",
            "branchIsOpen",
            "branchIsContracted",
            "branchCommissionRate",
            "branchWorkingHours",
            "branchIsScheduleActive",
            "branchIs24Hours",
            "branchZoneId",
            "inZone",
            "distanceKm"
          FROM ranked_branches
          WHERE rank = 1
          ORDER BY
            "inZone" DESC,
            "branchIsOpen" DESC,
            "distanceKm" ASC
        `;
      } catch (err) {
        this.logger.warn(`Nearest branch query failed: ${err}`);
      }

      // Fetch all vendors matching where filter
      const matchingVendors = await this.prisma.vendor.findMany({
        where,
        include: this.vendorIncludes(),
      });

      const vendorMap = new Map(matchingVendors.map((v) => [v.id, v]));

      // Merge sorted branches with vendor data
      const sortedVendorsWithBranches: any[] = [];
      for (const branch of nearestBranches) {
        const vendor = vendorMap.get(branch.vendorId);
        if (vendor) {
          sortedVendorsWithBranches.push({
            ...vendor,
            _proximity: {
              distanceKm: branch.distanceKm,
              inCustomerZone: branch.inZone,
              closestBranch: {
                id: branch.branchId,
                name: branch.branchName,
                nameAr: branch.branchNameAr,
                address: branch.branchAddress,
                isOpen: branch.branchIsOpen,
                isContracted: branch.branchIsContracted,
                commissionRate: branch.branchCommissionRate,
                workingHours: branch.branchWorkingHours,
                isScheduleActive: branch.branchIsScheduleActive,
                is24Hours: branch.branchIs24Hours,
                zoneId: branch.branchZoneId,
                distanceKm: branch.distanceKm,
              },
            },
          });
          vendorMap.delete(branch.vendorId);
        }
      }

      // Any remaining matching vendors without branches are appended at the end
      const remainingVendorsWithoutBranches = Array.from(vendorMap.values());
      const combinedSortedVendors = [
        ...sortedVendorsWithBranches,
        ...remainingVendorsWithoutBranches,
      ];

      total = combinedSortedVendors.length;
      vendors = combinedSortedVendors.slice(skip, skip + limit);
    } else {
      const orderBy: Prisma.VendorOrderByWithRelationInput = {};
      if (dto.sortBy) {
        orderBy[dto.sortBy] = dto.sortOrder || 'desc';
      } else {
        orderBy.createdAt = 'desc';
      }

      const [v, t] = await Promise.all([
        this.prisma.vendor.findMany({
          where,
          orderBy,
          skip,
          take: limit,
          include: this.vendorIncludes(),
        }),
        this.prisma.vendor.count({ where }),
      ]);
      vendors = v;
      total = t;
    }

    return {
      vendors: vendors.map((v) => this.mapVendorForApp(v)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async adminFindAll(dto: QueryVendorsDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.VendorWhereInput = { deletedAt: undefined }; // Admins can see deleted vendors

    if (dto.status) where.status = dto.status;
    if (dto.verticalId) where.verticalId = dto.verticalId;
    if (dto.search) {
      where.OR = [
        { storeName: { contains: dto.search, mode: 'insensitive' } },
        { storeNameAr: { contains: dto.search, mode: 'insensitive' } },
      ];
    }

    if (dto.minRating) {
      where.rating = { gte: dto.minRating };
    }

    const orderBy: Prisma.VendorOrderByWithRelationInput = {};
    if (dto.sortBy) {
      orderBy[dto.sortBy] = dto.sortOrder || 'desc';
    } else {
      orderBy.createdAt = 'desc';
    }

    const [vendors, total] = await Promise.all([
      this.prisma.vendor.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        include: this.vendorIncludes(),
      }),
      this.prisma.vendor.count({ where }),
    ]);

    return {
      vendors: vendors.map((v) => this.mapVendorForApp(v)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string, branchId?: string) {
    const cache =
      this.vendorCache ??
      new VendorCacheService(this.prisma, this.cacheManager);
    const mapped = await cache.getOrSetVendorDetailsById(id, async () => {
      const vendor = await this.prisma.vendor.findFirst({
        where: { id, deletedAt: null },
        include: this.vendorDetailsIncludes(),
      });
      if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);
      return this.mapVendorForApp(vendor);
    });
    return branchId ? this.filterVendorMenuForBranch(mapped, branchId) : mapped;
  }

  async findBySlug(slug: string, branchId?: string) {
    const cache =
      this.vendorCache ??
      new VendorCacheService(this.prisma, this.cacheManager);
    const mapped = await cache.getOrSetVendorDetailsBySlug(slug, async () => {
      const vendor = await this.prisma.vendor.findFirst({
        where: { slug, deletedAt: null },
        include: this.vendorDetailsIncludes(),
      });
      if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);
      return this.mapVendorForApp(vendor);
    });
    return branchId ? this.filterVendorMenuForBranch(mapped, branchId) : mapped;
  }

  // ─── Admin: update ────────────────────────────────────────────────────────

  async update(id: string, dto: UpdateVendorDto) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      select: { deletedAt: true, slug: true },
    });
    if (!vendor || vendor.deletedAt)
      throw new NotFoundException(VendorErrors.NOT_FOUND);

    // If storeName changes and no explicit slug change is needed,
    // we do NOT auto-regenerate the slug to avoid breaking existing URLs.
    // Slug is immutable after creation unless the admin explicitly sets it
    // via a dedicated endpoint (not implemented — intentional).

    const updated = await this.prisma.vendor.update({
      where: { id },
      data: {
        ...(dto.storeName !== undefined && { storeName: dto.storeName }),
        ...(dto.storeNameAr !== undefined && { storeNameAr: dto.storeNameAr }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.descriptionAr !== undefined && {
          descriptionAr: dto.descriptionAr,
        }),
        ...(dto.verticalId !== undefined && { verticalId: dto.verticalId }),
        ...(dto.taxId !== undefined && { taxId: dto.taxId }),
        ...(dto.commissionRate !== undefined && {
          commissionRate: dto.commissionRate,
        }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.isContracted !== undefined && {
          isContracted: dto.isContracted,
        }),
      },
      include: this.vendorIncludes(),
    });
    await this.invalidateVendorCaches(id, vendor?.slug);
    return updated;
  }

  async searchDiscovery(dto: QueryVendorsDto) {
    const { search, verticalId, limit = 20 } = dto;
    if (!search) return { results: [] };

    // 1. Find products matching the search
    const products = await this.prisma.product.findMany({
      where: {
        deletedAt: null,
        isActive: true,
        OR: [
          { name: { contains: search, mode: 'insensitive' } },
          { nameAr: { contains: search, mode: 'insensitive' } },
        ],
        vendor: {
          verticalId: verticalId || undefined,
          deletedAt: null,
          rating: dto.minRating ? { gte: dto.minRating } : undefined,
        },
      },
      take: limit * 2,
      include: {
        variants: {
          where: { isActive: true },
          select: { basePrice: true },
        },
        vendor: {
          include: this.vendorIncludes(),
        },
      },
    });

    // 2. Group by vendor
    const vendorMap = new Map<string, any>();

    for (const p of products) {
      if (!vendorMap.has(p.vendorId)) {
        vendorMap.set(p.vendorId, {
          ...this.mapVendorForApp(p.vendor),
          matchingProducts: [],
        });
      }
      const minVariantPrice =
        p.hasVariants && p.variants.length > 0
          ? Math.min(...p.variants.map((v) => Number(v.basePrice)))
          : null;
      vendorMap.get(p.vendorId).matchingProducts.push({
        id: p.id,
        name: p.name,
        nameAr: p.nameAr,
        description: p.description,
        price: minVariantPrice ?? p.basePrice,
        hasVariants: p.hasVariants,
        image: p.imageUrl,
        sellByStrip:
          p.vendor.vertical?.slug?.toLowerCase().includes('pharmacy') ||
          p.vendor.vertical?.slug?.toLowerCase().includes('pharmacies') ||
          p.vendor.vertical?.slug?.includes('صيدلي') ||
          false
            ? p.sellByStrip
            : false,
        stripsPerPackage: p.stripsPerPackage,
      });
    }

    // 3. Also find vendors whose name matches the search directly
    const directVendors = await this.prisma.vendor.findMany({
      where: {
        deletedAt: null,
        verticalId: verticalId || undefined,
        rating: dto.minRating ? { gte: dto.minRating } : undefined,
        OR: [
          { storeName: { contains: search, mode: 'insensitive' } },
          { storeNameAr: { contains: search, mode: 'insensitive' } },
        ],
      },
      take: limit,
      include: this.vendorIncludes(),
    });

    for (const v of directVendors) {
      if (!vendorMap.has(v.id)) {
        vendorMap.set(v.id, {
          ...this.mapVendorForApp(v),
          matchingProducts: [],
        });
      }
    }

    if (dto.lat !== undefined && dto.lng !== undefined && vendorMap.size > 0) {
      try {
        const vendorIds = Array.from(vendorMap.keys());
        const branchDistances = await this.prisma.$queryRaw<
          { vendorId: string; distanceKm: number }[]
        >`
          SELECT
            vb."vendorId",
            ROUND((MIN(ST_Distance(vb.location::geography, ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)::geography)) / 1000.0)::numeric, 1)::float AS "distanceKm"
          FROM vendor_branches vb
          WHERE vb."vendorId" IN (${Prisma.join(vendorIds)})
          GROUP BY vb."vendorId"
        `;
        const distanceMap = new Map(
          branchDistances.map((b) => [b.vendorId, b.distanceKm]),
        );
        const sortedResults = Array.from(vendorMap.values())
          .map((v) => {
            const d = distanceMap.get(v.id);
            if (d !== undefined) {
              v.distanceKm = d;
              const baseMin = Math.max(15, Math.round(15 + d * 2.5));
              const baseMax = baseMin + 10;
              v.deliveryTime = `${baseMin}-${baseMax} دقيقة`;
              v.deliveryTimeEn = `${baseMin}-${baseMax} mins`;
            }
            return v;
          })
          .sort((a, b) => {
            const da = a.distanceKm ?? 9999;
            const db = b.distanceKm ?? 9999;
            return da - db;
          });

        return { results: sortedResults };
      } catch (err) {
        this.logger.warn(`Discovery search proximity sorting failed: ${err}`);
      }
    }

    return {
      results: Array.from(vendorMap.values()),
    };
  }

  async updateStatus(id: string, dto: UpdateVendorStatusDto) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      select: { deletedAt: true, slug: true },
    });
    if (!vendor || vendor.deletedAt)
      throw new NotFoundException(VendorErrors.NOT_FOUND);

    const updated = await this.prisma.vendor.update({
      where: { id },
      data: { status: dto.status },
      include: this.vendorIncludes(),
    });
    await this.invalidateVendorCaches(id, vendor?.slug);
    return updated;
  }

  // ─── Admin: logo & cover image ────────────────────────────────────────────

  async uploadLogo(id: string, file: Express.Multer.File) {
    const logo = await this.replaceVendorAsset(id, file, {
      field: 'logo',
      folder: 'vendors/logos',
      label: 'logo',
    });
    return { logo };
  }

  async uploadCover(id: string, file: Express.Multer.File) {
    const coverImage = await this.replaceVendorAsset(id, file, {
      field: 'coverImage',
      folder: 'vendors/covers',
      label: 'cover',
    });
    return { coverImage };
  }

  private async replaceVendorAsset(
    id: string,
    file: Express.Multer.File,
    opts: { field: 'logo' | 'coverImage'; folder: string; label: string },
  ): Promise<string> {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      select: { deletedAt: true, logo: true, coverImage: true, slug: true },
    });
    if (!vendor || vendor.deletedAt)
      throw new NotFoundException(VendorErrors.NOT_FOUND);

    const url = await this.storage.upload(file, opts.folder);
    this.logger.log(`Vendor ${opts.label} uploaded for ${id}: ${url}`);

    await this.prisma.vendor.update({
      where: { id },
      data: { [opts.field]: url },
    });

    // Delete old asset only AFTER successful DB update to prevent orphans on crash
    const previousUrl = vendor[opts.field];
    if (previousUrl) {
      await this.storage.delete(previousUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete old ${opts.label} for vendor ${id}: ${(err as Error).message}`,
        );
      });
    }

    await this.invalidateVendorCaches(id, vendor.slug);
    return url;
  }

  public async invalidateVendorCaches(id: string, slug?: string) {
    if (this.vendorCache) {
      await this.vendorCache.invalidateVendorDetails(id, slug);
      return;
    }
    await new VendorCacheService(
      this.prisma,
      this.cacheManager,
    ).invalidateVendorDetails(id, slug);
  }

  // ─── Admin: soft delete ───────────────────────────────────────────────────

  async remove(id: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id },
      select: { deletedAt: true, slug: true },
    });
    if (!vendor || vendor.deletedAt)
      throw new NotFoundException(VendorErrors.NOT_FOUND);

    await this.prisma.vendor.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    await this.invalidateVendorCaches(id, vendor.slug);

    return { message: CommonSuccess.RESOURCE_DELETED };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private branchPublicSelect() {
    return {
      id: true,
      name: true,
      nameAr: true,
      address: true,
      phone: true,
      isOpen: true,
      isContracted: true,
      commissionRate: true,
      workingHours: true,
      isScheduleActive: true,
      is24Hours: true,
      zoneId: true,
    };
  }

  private vendorIncludes() {
    return {
      vertical: {
        select: {
          id: true,
          name: true,
          nameAr: true,
          slug: true,
          iconUrl: true,
        },
      },
      branches: {
        select: this.branchPublicSelect(),
      },
      _count: {
        select: {
          orderFulfillments: true,
        },
      },
    };
  }

  private vendorDetailsIncludes() {
    return {
      ...this.vendorIncludes(),
      categories: {
        where: { isActive: true },
        orderBy: { sortOrder: Prisma.SortOrder.asc },
        include: {
          branchAvailability: {
            select: { branchId: true },
          },
        },
      },
      products: {
        where: { isActive: true, deletedAt: null },
        include: {
          branchAvailability: {
            select: { branchId: true },
          },
          variants: {
            where: { isActive: true },
            include: {
              optionGroups: {
                include: {
                  options: {
                    where: { isActive: true },
                    orderBy: { name: Prisma.SortOrder.asc },
                  },
                },
              },
            },
            orderBy: { name: Prisma.SortOrder.asc },
          },
          optionGroups: {
            include: {
              options: {
                where: { isActive: true },
                orderBy: { name: Prisma.SortOrder.asc },
              },
            },
          },
          offers: {
            where: { isActive: true },
            orderBy: [
              { sortOrder: Prisma.SortOrder.asc },
              { createdAt: Prisma.SortOrder.desc },
            ],
            select: {
              id: true,
              variantId: true,
              offerPrice: true,
              originalPrice: true,
              startDate: true,
              endDate: true,
            },
          },
        },
      },
    };
  }

  private mapBranchForApp<
    T extends {
      isOpen?: boolean;
      is24Hours?: boolean | null;
      isScheduleActive?: boolean | null;
      workingHours?: Prisma.JsonValue;
    },
  >(branch: T) {
    const manualIsOpen = branch.isOpen !== false;
    const scheduleEval = evaluateBranchEffectiveOpen({
      isOpen: manualIsOpen,
      is24Hours: branch.is24Hours === true,
      isScheduleActive: branch.isScheduleActive !== false,
      workingHours: branch.workingHours,
    });
    return {
      ...branch,
      isOpen: scheduleEval.isOpen,
      manualIsOpen,
      isClosedBySchedule: scheduleEval.isClosedBySchedule,
    };
  }

  private mapVendorForApp(vendor: {
    id: string;
    status: string;
    storeName: string;
    storeNameAr: string | null;
    slug: string;
    description: string | null;
    descriptionAr: string | null;
    coverImage: string | null;
    logo: string | null;
    rating?: number | null;
    ratingCount?: number | null;
    vertical?: { name: string; nameAr: string | null; slug: string } | null;
    branches?: {
      id: string;
      name: string;
      nameAr: string | null;
      address: string;
      phone: string | null;
      isOpen: boolean;
      isContracted?: boolean | null;
      commissionRate?: number | null;
      workingHours?: Prisma.JsonValue;
      isScheduleActive?: boolean;
      is24Hours?: boolean;
      zoneId?: string | null;
    }[];
    products?: {
      id: string;
      name: string;
      nameAr: string | null;
      description: string | null;
      descriptionAr: string | null;
      basePrice: number | null;
      comparePrice?: number | null;
      stock: number | null;
      tracksStock: boolean;
      imageUrl: string | null;
      categoryId: string | null;
      sellByStrip: boolean;
      stripsPerPackage: number | null;
      hasVariants: boolean;
      variants: unknown[];
      optionGroups: unknown[];
      offers?: unknown[];
      branchAvailabilityMode?: string;
      branchAvailability?: unknown[];
    }[];
  }) {
    const proximity = (vendor as any)._proximity;
    const distanceKm: number | null =
      proximity?.distanceKm ?? (vendor as any).distanceKm ?? null;
    const inCustomerZone: boolean = proximity?.inCustomerZone ?? false;
    const rawClosestBranch = proximity?.closestBranch ?? null;
    const closestBranch = rawClosestBranch
      ? this.mapBranchForApp(rawClosestBranch)
      : null;

    const rawBranches = Array.isArray((vendor as any).branches)
      ? (vendor as any).branches
      : [];
    const branches = rawBranches.map((b: any) => this.mapBranchForApp(b));

    let status = vendor.status;
    let isClosedBySchedule = false;

    if (vendor.status === 'OPEN') {
      if (branches.length > 0 && branches.every((b: any) => !b.isOpen)) {
        status = 'CLOSED';
        isClosedBySchedule = branches.some((b: any) => b.isClosedBySchedule);
      } else if (branches.length === 0 && closestBranch && !closestBranch.isOpen) {
        status = 'CLOSED';
        isClosedBySchedule = closestBranch.isClosedBySchedule;
      }
    }

    let deliveryTime = '20-30 دقيقة';
    let deliveryTimeEn = '20-30 mins';
    if (distanceKm !== null && distanceKm > 0) {
      const baseMin = Math.max(15, Math.round(15 + distanceKm * 2.5));
      const baseMax = baseMin + 10;
      deliveryTime = `${baseMin}-${baseMax} دقيقة`;
      deliveryTimeEn = `${baseMin}-${baseMax} mins`;
    }

    const rawCount = (vendor as any)._count;
    // Map backend fields to what the app expects
    return {
      ...vendor,
      ...(rawCount !== undefined && {
        _count: {
          ...rawCount,
          orders: rawCount.orderFulfillments ?? rawCount.orders ?? 0,
        },
      }),
      status,
      manualStatus: vendor.status,
      isClosedBySchedule,
      id: vendor.id,
      name: vendor.storeName,
      nameAr: vendor.storeNameAr || '',
      vendor: vendor.description || vendor.vertical?.name || '',
      vendorAr: vendor.descriptionAr || vendor.vertical?.nameAr || '',
      rating: vendor.rating ?? 0,
      ratingCount: vendor.ratingCount ?? 0,
      distanceKm,
      inCustomerZone,
      closestBranch,
      branches,
      deliveryTime,
      deliveryTimeEn,
      deliveryFee: '15 ج رسوم توصيل',
      image:
        vendor.coverImage ||
        vendor.logo ||
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop',
      type: vendor.vertical?.slug || 'restaurant',
      tag: status === 'OPEN' ? 'Open' : 'Closed',
      menu:
        vendor.products?.map((p) => {
          const slug = vendor.vertical?.slug?.toLowerCase() || '';
          const name = vendor.vertical?.name?.toLowerCase() || '';
          const nameAr = vendor.vertical?.nameAr || '';
          const vendorSlug = vendor.slug?.toLowerCase() || '';
          const storeName = vendor.storeName?.toLowerCase() || '';
          const isPharmacy =
            slug.includes('pharmacy') ||
            slug.includes('pharmacies') ||
            slug.includes('pharmacies-') ||
            slug.includes('صيدلي') ||
            slug.includes('صيدليات') ||
            slug.includes('medical') ||
            slug.includes('medicine') ||
            slug.includes('pharma') ||
            name.includes('pharmacy') ||
            name.includes('pharmacies') ||
            name.includes('medical') ||
            name.includes('medicine') ||
            name.includes('pharma') ||
            nameAr.includes('صيدلي') ||
            nameAr.includes('صيدليات') ||
            vendorSlug.includes('pharmacy') ||
            vendorSlug.includes('صيدلي') ||
            vendorSlug.includes('صيدليات') ||
            storeName.includes('pharmacy') ||
            storeName.includes('صيدلي') ||
            storeName.includes('صيدليات') ||
            false;
          const pOffers = (p as any).offers as
            | Array<{
                id: string;
                variantId?: string | null;
                offerPrice: number;
                originalPrice?: number | null;
                startDate?: Date | null;
                endDate?: Date | null;
              }>
            | undefined;

          const now = new Date();
          const activeOffers = (pOffers || []).filter((o) => {
            if (o.startDate && new Date(o.startDate) > now) return false;
            if (o.endDate && new Date(o.endDate) < now) return false;
            return true;
          });

          // Product-wide active offer (where variantId is null or undefined)
          const productActiveOffer = activeOffers.find((o) => !o.variantId);

          // Variant-specific active offers mapped by variantId
          const variantOffersMap = new Map<string, (typeof activeOffers)[0]>();
          for (const o of activeOffers) {
            if (o.variantId) {
              variantOffersMap.set(o.variantId, o);
            }
          }

          const basePrice = p.basePrice ? Number(p.basePrice) : 0;
          const rawComparePrice = p.comparePrice
            ? Number(p.comparePrice)
            : null;

          let effectivePrice = basePrice;
          let effectiveComparePrice = rawComparePrice;

          // Discount ratio from product-wide active offer (if present)
          const productDiscountRatio =
            productActiveOffer &&
            productActiveOffer.originalPrice &&
            productActiveOffer.originalPrice > productActiveOffer.offerPrice
              ? (Number(productActiveOffer.originalPrice) -
                  Number(productActiveOffer.offerPrice)) /
                Number(productActiveOffer.originalPrice)
              : 0;

          if (productActiveOffer) {
            effectivePrice = Number(productActiveOffer.offerPrice);
            effectiveComparePrice = productActiveOffer.originalPrice
              ? Number(productActiveOffer.originalPrice)
              : rawComparePrice && rawComparePrice > effectivePrice
                ? rawComparePrice
                : basePrice;
          }

          // Map variants with discount calculations
          const mappedVariants = (p.variants || []).map((v: any) => {
            const vBasePrice = Number(v.basePrice || 0);
            const vRawCompare = v.comparePrice ? Number(v.comparePrice) : null;
            const originalRef =
              vRawCompare && vRawCompare > vBasePrice
                ? vRawCompare
                : vBasePrice;

            let vEffectivePrice = vBasePrice;
            let vEffectiveCompare = vRawCompare;

            // 1. Check for a dedicated variant-specific active offer first!
            const variantOffer = variantOffersMap.get(v.id);
            if (variantOffer) {
              vEffectivePrice = Number(variantOffer.offerPrice);
              vEffectiveCompare = variantOffer.originalPrice
                ? Number(variantOffer.originalPrice)
                : originalRef;
            } else if (productDiscountRatio > 0) {
              // 2. Apply product-wide proportional discount against the variant's
              // selling basePrice so an inflated comparePrice cannot raise the price.
              vEffectivePrice = Math.max(
                0,
                Math.round(vBasePrice * (1 - productDiscountRatio)),
              );
              vEffectiveCompare = originalRef;
            }

            return {
              ...v,
              price: vEffectivePrice,
              basePrice: vBasePrice,
              comparePrice:
                vEffectiveCompare && vEffectiveCompare > vEffectivePrice
                  ? vEffectiveCompare
                  : null,
            };
          });

          // If product has variants, starting price reflects the lowest variant price
          if (p.hasVariants && mappedVariants.length > 0) {
            let minVariant = mappedVariants[0];
            for (const mv of mappedVariants) {
              if (mv.price < minVariant.price) {
                minVariant = mv;
              }
            }
            effectivePrice = minVariant.price;
            effectiveComparePrice = minVariant.comparePrice;
          }

          return {
            id: p.id,
            name: p.name,
            nameAr: p.nameAr || '',
            description: p.description,
            descriptionAr: p.descriptionAr || '',
            price: effectivePrice,
            basePrice: basePrice,
            stock: p.stock,
            tracksStock: p.tracksStock,
            comparePrice:
              effectiveComparePrice && effectiveComparePrice > effectivePrice
                ? effectiveComparePrice
                : null,
            image: p.imageUrl || '',
            category: p.categoryId, // Link to category
            sellByStrip: isPharmacy ? p.sellByStrip : false,
            stripsPerPackage: p.stripsPerPackage,
            hasVariants: p.hasVariants,
            variants: mappedVariants,
            optionGroups: p.optionGroups || [],
            branchAvailabilityMode: p.branchAvailabilityMode,
            branchAvailability: p.branchAvailability,
          };
        }) || [],
    };
  }

  private filterVendorMenuForBranch(
    vendor: Record<string, unknown>,
    branchId: string,
  ) {
    const categories = (vendor.categories as Array<any>) ?? [];
    const products = (vendor.products as Array<any>) ?? [];

    const availableCategories = categories.filter((c) => {
      if (c.branchAvailabilityMode === 'SPECIFIC') {
        const branchIds = (c.branchAvailability ?? []).map(
          (b: any) => b.branchId,
        );
        return branchIds.includes(branchId);
      }
      return true;
    });
    const availableCategoryIds = new Set(availableCategories.map((c) => c.id));

    const availableProducts = products.filter((p) => {
      if (p.categoryId && !availableCategoryIds.has(p.categoryId)) {
        return false;
      }
      if (p.branchAvailabilityMode === 'SPECIFIC') {
        const branchIds = (p.branchAvailability ?? []).map(
          (b: any) => b.branchId,
        );
        return branchIds.includes(branchId);
      }
      return true;
    });

    const productCategoryIds = new Set(
      availableProducts.map((p) => p.categoryId).filter(Boolean),
    );
    const finalCategories = availableCategories.filter((c) =>
      productCategoryIds.has(c.id),
    );

    const availableProductIds = new Set(
      availableProducts.map((p: any) => p.id),
    );
    const filteredMenu = Array.isArray(vendor.menu)
      ? vendor.menu.filter((m: any) => availableProductIds.has(m.id))
      : vendor.menu;

    return {
      ...vendor,
      categories: finalCategories,
      products: availableProducts,
      menu: filteredMenu,
    };
  }
}
