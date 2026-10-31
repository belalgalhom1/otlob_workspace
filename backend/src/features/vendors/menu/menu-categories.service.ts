import {
  Injectable,
  NotFoundException,
  Logger,
  ForbiddenException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { ProductBranchAvailabilityMode } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { StorageService } from '../../../infrastructure/storage/storage.service';
import {
  CreateMenuCategoryDto,
  UpdateMenuCategoryDto,
  ReorderCategoriesDto,
} from './dto/menu-category.dto';
import {
  CommonSuccess,
  VendorErrors,
} from '../../../common/constants/response.constants';

export const MenuCategoryErrors = {
  NOT_FOUND: 'menu_category.error.not_found',
  BELONGS_TO_OTHER_VENDOR: 'menu_category.error.belongs_to_other_vendor',
};

@Injectable()
export class MenuCategoriesService {
  private readonly logger = new Logger(MenuCategoriesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {}

  // ─── List all categories for a vendor ─────────────────────────────────────
  // Public — customers browse menus, so active-only filtering is available.

  async findAll(vendorId: string, activeOnly = false, branchId?: string) {
    await this.assertVendorExists(vendorId);

    const where: Prisma.MenuCategoryWhereInput = { vendorId };
    if (activeOnly) where.isActive = true;

    if (branchId) {
      await this.assertBranchBelongsToVendor(branchId, vendorId);
      where.AND = [
        {
          OR: [
            { branchAvailabilityMode: ProductBranchAvailabilityMode.ALL },
            { branchAvailability: { some: { branchId } } },
          ],
        },
      ];
    }

    return this.prisma.menuCategory.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
      include: {
        _count: { select: { products: { where: { deletedAt: null } } } },
        branchAvailability: {
          select: {
            branchId: true,
            branch: { select: { id: true, name: true, nameAr: true } },
          },
        },
      },
    });
  }

  // ─── Get single category ───────────────────────────────────────────────────

  async findOne(vendorId: string, categoryId: string) {
    await this.assertVendorExists(vendorId);

    const category = await this.prisma.menuCategory.findFirst({
      where: { id: categoryId, vendorId },
      include: {
        _count: { select: { products: { where: { deletedAt: null } } } },
        branchAvailability: {
          select: {
            branchId: true,
            branch: { select: { id: true, name: true, nameAr: true } },
          },
        },
      },
    });

    if (!category) throw new NotFoundException(MenuCategoryErrors.NOT_FOUND);
    return category;
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async create(vendorId: string, dto: CreateMenuCategoryDto) {
    await this.assertVendorExists(vendorId);

    // Auto-assign sortOrder to end of list if not provided
    let sortOrder = dto.sortOrder;
    if (sortOrder === undefined) {
      const last = await this.prisma.menuCategory.aggregate({
        where: { vendorId },
        _max: { sortOrder: true },
      });
      sortOrder = (last._max.sortOrder ?? -1) + 1;
    }

    const availability = await this.resolveBranchAvailability(
      vendorId,
      dto.branchAvailabilityMode,
      dto.branchIds,
    );

    const category = await this.prisma.menuCategory.create({
      data: {
        vendorId,
        name: dto.name,
        nameAr: dto.nameAr ?? null,
        description: dto.description ?? null,
        descriptionAr: dto.descriptionAr ?? null,
        sortOrder,
        isActive: dto.isActive ?? true,
        branchAvailabilityMode: availability.mode,
        ...(availability.branchIds.length > 0
          ? {
              branchAvailability: {
                createMany: {
                  data: availability.branchIds.map((branchId) => ({ branchId })),
                },
              },
            }
          : {}),
      },
      include: {
        _count: { select: { products: { where: { deletedAt: null } } } },
        branchAvailability: {
          select: {
            branchId: true,
            branch: { select: { id: true, name: true, nameAr: true } },
          },
        },
      },
    });

    await this.invalidateVendorCaches(vendorId);
    return category;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  async update(
    vendorId: string,
    categoryId: string,
    dto: UpdateMenuCategoryDto,
  ) {
    await this.findOne(vendorId, categoryId); // 404 if not found

    const availability = await this.resolveBranchAvailabilityForUpdate(
      vendorId,
      categoryId,
      dto.branchAvailabilityMode,
      dto.branchIds,
    );

    const updated = await this.prisma.$transaction(async (tx) => {
      if (availability) {
        await tx.categoryBranchAvailability.deleteMany({
          where: { categoryId },
        });
        if (availability.branchIds.length > 0) {
          await tx.categoryBranchAvailability.createMany({
            data: availability.branchIds.map((branchId) => ({
              categoryId,
              branchId,
            })),
          });
        }
      }

      return tx.menuCategory.update({
        where: { id: categoryId },
        data: {
          ...(dto.name !== undefined && { name: dto.name }),
          ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
          ...(dto.description !== undefined && { description: dto.description }),
          ...(dto.descriptionAr !== undefined && {
            descriptionAr: dto.descriptionAr,
          }),
          ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
          ...(dto.isActive !== undefined && { isActive: dto.isActive }),
          ...(availability && { branchAvailabilityMode: availability.mode }),
        },
        include: {
          _count: { select: { products: { where: { deletedAt: null } } } },
          branchAvailability: {
            select: {
              branchId: true,
              branch: { select: { id: true, name: true, nameAr: true } },
            },
          },
        },
      });
    });

    this.logger.log(`Menu category updated: ${categoryId}`);
    await this.invalidateVendorCaches(vendorId);
    return updated;
  }

  // ─── Bulk reorder ─────────────────────────────────────────────────────────
  // Accepts an array of { id, sortOrder } — updates all in a transaction.

  async reorder(vendorId: string, dto: ReorderCategoriesDto) {
    await this.assertVendorExists(vendorId);

    // Verify all IDs belong to this vendor
    const ids = dto.items.map((i) => i.id);
    const categories = await this.prisma.menuCategory.findMany({
      where: { id: { in: ids }, vendorId },
      select: { id: true },
    });

    if (categories.length !== ids.length) {
      throw new ForbiddenException(MenuCategoryErrors.BELONGS_TO_OTHER_VENDOR);
    }

    await this.prisma.$transaction(
      dto.items.map(({ id, sortOrder }) =>
        this.prisma.menuCategory.update({
          where: { id },
          data: { sortOrder },
        }),
      ),
    );

    this.logger.log(
      `Reordered ${ids.length} categories for vendor ${vendorId}`,
    );
    await this.invalidateVendorCaches(vendorId);
    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  // Products whose category is deleted get categoryId set to null (onDelete: SetNull in schema).

  async remove(vendorId: string, categoryId: string) {
    await this.findOne(vendorId, categoryId);

    await this.prisma.menuCategory.delete({ where: { id: categoryId } });

    await this.invalidateVendorCaches(vendorId);
    return { message: CommonSuccess.RESOURCE_DELETED };
  }

  // ─── Upload Icon ──────────────────────────────────────────────────────────

  async uploadIcon(
    vendorId: string,
    categoryId: string,
    file: Express.Multer.File,
  ) {
    const category = await this.findOne(vendorId, categoryId);

    if (category.iconUrl) {
      await this.storage.delete(category.iconUrl);
    }

    const iconUrl = await this.storage.upload(file, 'vendors/categories/icons');
    this.logger.log(`Icon uploaded for category ${categoryId}: ${iconUrl}`);

    await this.prisma.menuCategory.update({
      where: { id: categoryId },
      data: { iconUrl },
    });

    await this.invalidateVendorCaches(vendorId);
    return { iconUrl };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private async invalidateVendorCaches(vendorId: string) {
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

  private async resolveBranchAvailability(
    vendorId: string,
    mode?: ProductBranchAvailabilityMode,
    branchIds?: string[],
  ): Promise<{
    mode: ProductBranchAvailabilityMode;
    branchIds: string[];
  }> {
    const uniqueBranchIds = [...new Set(branchIds ?? [])];
    const resolvedMode =
      mode ??
      (uniqueBranchIds.length > 0
        ? ProductBranchAvailabilityMode.SPECIFIC
        : ProductBranchAvailabilityMode.ALL);

    if (resolvedMode === ProductBranchAvailabilityMode.ALL) {
      if (uniqueBranchIds.length > 0) {
        throw new BadRequestException('Branch IDs must be empty when mode is ALL');
      }
      return { mode: ProductBranchAvailabilityMode.ALL, branchIds: [] };
    }

    if (uniqueBranchIds.length === 0) {
      throw new BadRequestException('At least one branch must be selected for SPECIFIC mode');
    }

    const branches = await this.prisma.vendorBranch.findMany({
      where: {
        id: { in: uniqueBranchIds },
        vendorId,
      },
      select: { id: true },
    });
    if (branches.length !== uniqueBranchIds.length) {
      throw new BadRequestException('One or more selected branches do not belong to this vendor');
    }

    return {
      mode: ProductBranchAvailabilityMode.SPECIFIC,
      branchIds: uniqueBranchIds,
    };
  }

  private async resolveBranchAvailabilityForUpdate(
    vendorId: string,
    categoryId: string,
    mode?: ProductBranchAvailabilityMode,
    branchIds?: string[],
  ): Promise<{
    mode: ProductBranchAvailabilityMode;
    branchIds: string[];
  } | null> {
    if (mode === undefined && branchIds === undefined) return null;

    if (
      mode === ProductBranchAvailabilityMode.SPECIFIC &&
      branchIds === undefined
    ) {
      const existing = await this.prisma.categoryBranchAvailability.findMany({
        where: { categoryId },
        select: { branchId: true },
      });
      if (existing.length === 0) {
        throw new BadRequestException('At least one branch must be selected for SPECIFIC mode');
      }
      return this.resolveBranchAvailability(
        vendorId,
        ProductBranchAvailabilityMode.SPECIFIC,
        existing.map((row) => row.branchId),
      );
    }

    return this.resolveBranchAvailability(vendorId, mode, branchIds);
  }

  private async assertBranchBelongsToVendor(
    branchId: string,
    vendorId: string,
  ) {
    const branch = await this.prisma.vendorBranch.findFirst({
      where: { id: branchId, vendorId },
      select: { id: true },
    });
    if (!branch) {
      throw new BadRequestException('Branch does not belong to this vendor');
    }
  }
}
