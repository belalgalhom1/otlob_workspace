import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
  ConflictException,
  OnModuleInit,
  Inject,
  Optional,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../../infrastructure/storage/storage.service';
import { VendorCacheService } from '../helpers/vendor-cache.service';
import { assertVendorExists } from '../helpers/vendor-lookup.helper';
import { Prisma, ProductBranchAvailabilityMode } from '@prisma/client';
import {
  CreateProductDto,
  UpdateProductDto,
  CreateProductVariantDto,
  UpdateProductVariantDto,
  CreateOptionGroupDto,
  UpdateOptionGroupDto,
  CreateProductOptionDto,
  UpdateProductOptionDto,
  QueryProductsDto,
} from './dto/product.dto';
import {
  CommonSuccess,
  ProductErrors,
} from '../../../common/constants/response.constants';

// Detail include builder for single product fetch
function buildProductDetailInclude(includeInactive = false) {
  return {
    category: { select: { id: true, name: true, nameAr: true } },
    variants: {
      ...(includeInactive ? {} : { where: { isActive: true } }),
      orderBy: { name: 'asc' as const },
      include: {
        optionGroups: {
          include: {
            options: {
              ...(includeInactive ? {} : { where: { isActive: true } }),
              orderBy: { name: 'asc' as const },
            },
          },
        },
      },
    },
    optionGroups: {
      include: {
        options: {
          ...(includeInactive ? {} : { where: { isActive: true } }),
          orderBy: { name: 'asc' as const },
        },
      },
    },
    branchAvailability: {
      select: {
        branchId: true,
        branch: { select: { id: true, name: true, nameAr: true } },
      },
      orderBy: { createdAt: 'asc' as const },
    },
    _count: { select: { favoritedBy: true } },
  };
}

// Lightweight list include builder to prevent N+1 query payload bloat
function buildProductListInclude(includeInactive = false) {
  return {
    category: { select: { id: true, name: true, nameAr: true } },
    variants: {
      ...(includeInactive ? {} : { where: { isActive: true } }),
      orderBy: { name: 'asc' as const },
      select: {
        id: true,
        name: true,
        nameAr: true,
        imageUrl: true,
        basePrice: true,
        comparePrice: true,
        stock: true,
        tracksStock: true,
        isActive: true,
      },
    },
    branchAvailability: { select: { branchId: true } },
    _count: { select: { favoritedBy: true } },
  };
}

const PRODUCT_DETAIL_INCLUDE = buildProductDetailInclude(false);

@Injectable()
export class ProductsService implements OnModuleInit {
  private readonly logger = new Logger(ProductsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
    @Optional() private readonly vendorCache?: VendorCacheService,
  ) {}

  async onModuleInit() {
    // Ensure product_variants.imageUrl column exists and sanitize any existing
    // empty string SKUs to NULL so they do not collide with unique constraints.
    try {
      await this.prisma.$executeRawUnsafe?.(
        'ALTER TABLE "product_variants" ADD COLUMN IF NOT EXISTS "imageUrl" TEXT;',
      );
      await this.prisma.product.updateMany({
        where: { sku: '' },
        data: { sku: null },
      });
      await this.prisma.productVariant.updateMany({
        where: { sku: '' },
        data: { sku: null },
      });
    } catch (err) {
      this.logger.warn(
        `Failed to run startup product schema/SKU maintenance: ${err}`,
      );
    }
  }

  // ─── List products ────────────────────────────────────────────────────────

  async findAll(vendorId: string, dto: QueryProductsDto) {
    await assertVendorExists(this.prisma, vendorId);

    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.ProductWhereInput = { vendorId, deletedAt: null };

    if (dto.categoryId !== undefined) where.categoryId = dto.categoryId;
    if (dto.isActive !== undefined) where.isActive = dto.isActive;
    if (dto.isFeatured !== undefined) where.isFeatured = dto.isFeatured;
    if (dto.search) {
      where.OR = [
        { name: { contains: dto.search, mode: 'insensitive' } },
        { nameAr: { contains: dto.search, mode: 'insensitive' } },
      ];
    }

    if (dto.branchId) {
      await this.assertBranchBelongsToVendor(dto.branchId, vendorId);
      where.AND = [
        {
          OR: [
            { branchAvailabilityMode: ProductBranchAvailabilityMode.ALL },
            { branchAvailability: { some: { branchId: dto.branchId } } },
          ],
        },
        {
          OR: [
            { categoryId: null },
            {
              category: {
                OR: [
                  { branchAvailabilityMode: ProductBranchAvailabilityMode.ALL },
                  { branchAvailability: { some: { branchId: dto.branchId } } },
                ],
              },
            },
          ],
        },
      ];
    }

    const [products, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: buildProductListInclude(dto.includeInactive ?? false),
      }),
      this.prisma.product.count({ where }),
    ]);

    return {
      products,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // ─── Get single product ───────────────────────────────────────────────────

  async findOne(
    vendorId: string,
    productId: string,
    includeInactive = false,
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      include: buildProductDetailInclude(includeInactive),
    });

    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);
    return product;
  }

  // ─── Get single product by id (no vendor scope — for cart/order use) ──────

  async findById(productId: string) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, deletedAt: null },
      include: PRODUCT_DETAIL_INCLUDE,
    });
    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);
    return product;
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async create(vendorId: string, dto: CreateProductDto) {
    await assertVendorExists(this.prisma, vendorId);

    // Validate: simple product needs basePrice
    if (!dto.hasVariants && !dto.basePrice) {
      throw new BadRequestException(ProductErrors.PRICE_REQUIRED);
    }

    if (dto.categoryId) {
      await this.assertCategoryBelongsToVendor(dto.categoryId, vendorId);
    }

    const sku = dto.sku?.trim() ? dto.sku.trim() : null;
    if (sku) {
      await this.assertSkuAvailable(sku);
    }

    const availability = await this.resolveBranchAvailability(
      vendorId,
      dto.branchAvailabilityMode,
      dto.branchIds,
    );

    const product = await this.prisma.$transaction(async (tx) => {
      const created = await tx.product.create({
        data: {
          vendorId,
          categoryId: dto.categoryId ?? null,
          name: dto.name,
          nameAr: dto.nameAr ?? null,
          description: dto.description ?? null,
          descriptionAr: dto.descriptionAr ?? null,
          hasVariants:
            (dto.hasVariants ?? false) || Boolean(dto.variants?.length),
          basePrice: dto.basePrice ?? null,
          comparePrice: dto.comparePrice ?? null,
          sku,
          stock: dto.stock ?? null,
          tracksStock: dto.tracksStock ?? true,
          isActive: dto.isActive ?? true,
          isFeatured: dto.isFeatured ?? false,
          sellByStrip: dto.sellByStrip ?? false,
          stripsPerPackage: dto.stripsPerPackage ?? null,
          branchAvailabilityMode: availability.mode,
        },
      });

      if (availability.branchIds.length > 0) {
        await tx.productBranchAvailability.createMany({
          data: availability.branchIds.map((branchId) => ({
            productId: created.id,
            branchId,
          })),
        });
      }

      // Create option groups + options for simple products
      if (dto.optionGroups?.length) {
        await this.createOptionGroups(tx, created.id, null, dto.optionGroups);
      }

      // Create variants + their option groups
      if (dto.variants?.length) {
        for (const variantDto of dto.variants) {
          await this.createVariantWithOptions(tx, created.id, variantDto);
        }
      }

      return created;
    });

    this.logger.log(`Product created: ${product.id} for vendor ${vendorId}`);
    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, product.id, true);
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  async update(vendorId: string, productId: string, dto: UpdateProductDto) {
    const exists = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { id: true },
    });
    if (!exists) throw new NotFoundException(ProductErrors.NOT_FOUND);

    if (dto.categoryId !== undefined && dto.categoryId !== null) {
      await this.assertCategoryBelongsToVendor(dto.categoryId, vendorId);
    }

    const sku =
      dto.sku !== undefined
        ? dto.sku?.trim()
          ? dto.sku.trim()
          : null
        : undefined;

    if (sku) {
      await this.assertSkuAvailable(sku, productId);
    }

    const availability = await this.resolveBranchAvailabilityForUpdate(
      vendorId,
      productId,
      dto.branchAvailabilityMode,
      dto.branchIds,
    );

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.product.update({
          where: {
            id: productId,
            ...(dto.version !== undefined && { version: dto.version }),
          },
          data: {
            ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
            ...(dto.name !== undefined && { name: dto.name }),
            ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
            ...(dto.description !== undefined && {
              description: dto.description,
            }),
            ...(dto.descriptionAr !== undefined && {
              descriptionAr: dto.descriptionAr,
            }),
            ...(dto.hasVariants !== undefined && {
              hasVariants: dto.hasVariants,
            }),
            ...(dto.basePrice !== undefined && { basePrice: dto.basePrice }),
            ...(dto.comparePrice !== undefined && {
              comparePrice: dto.comparePrice,
            }),
            ...(sku !== undefined && { sku }),
            ...(dto.stock !== undefined && { stock: dto.stock }),
            ...(dto.tracksStock !== undefined && {
              tracksStock: dto.tracksStock,
            }),
            ...(dto.isActive !== undefined && { isActive: dto.isActive }),
            ...(dto.isFeatured !== undefined && {
              isFeatured: dto.isFeatured,
            }),
            ...(dto.sellByStrip !== undefined && {
              sellByStrip: dto.sellByStrip,
            }),
            ...(dto.stripsPerPackage !== undefined && {
              stripsPerPackage: dto.stripsPerPackage,
            }),
            ...(availability && {
              branchAvailabilityMode: availability.mode,
            }),
            version: { increment: 1 },
          },
        });

        if (availability) {
          await tx.productBranchAvailability.deleteMany({
            where: { productId },
          });
          if (availability.branchIds.length > 0) {
            await tx.productBranchAvailability.createMany({
              data: availability.branchIds.map((branchId) => ({
                productId,
                branchId,
              })),
            });
          }
        }
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new ConflictException(ProductErrors.CONCURRENT_MODIFICATION);
      }
      throw error;
    }

    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  // ─── Upload product image ─────────────────────────────────────────────────

  async uploadImage(
    vendorId: string,
    productId: string,
    file: Express.Multer.File,
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { imageUrl: true },
    });
    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);

    const imageUrl = await this.storage.upload(file, 'products/images');

    await this.prisma.product.update({
      where: { id: productId },
      data: { imageUrl },
    });

    if (product.imageUrl) {
      await this.storage.delete(product.imageUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete old product image for ${productId}: ${(err as Error).message}`,
        );
      });
    }

    this.logger.log(`Image uploaded for product ${productId}: ${imageUrl}`);
    await this.invalidateVendorCaches(vendorId);
    return { imageUrl };
  }

  // ─── Soft delete ──────────────────────────────────────────────────────────

  async remove(vendorId: string, productId: string) {
    const exists = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { id: true, sku: true },
    });
    if (!exists) throw new NotFoundException(ProductErrors.NOT_FOUND);

    await this.prisma.product.update({
      where: { id: productId },
      data: {
        deletedAt: new Date(),
        isActive: false,
        sku: exists.sku ? `${exists.sku}#deleted#${Date.now()}` : null,
      },
    });

    this.logger.log(`Product soft-deleted: ${productId}`);
    await this.invalidateVendorCaches(vendorId);
    return { message: CommonSuccess.RESOURCE_DELETED };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VARIANTS
  // ═══════════════════════════════════════════════════════════════════════════

  async addVariant(
    vendorId: string,
    productId: string,
    dto: CreateProductVariantDto,
  ) {
    const product = await this.findOne(vendorId, productId);

    const sku = dto.sku?.trim() ? dto.sku.trim() : null;
    if (sku) {
      await this.assertVariantSkuAvailable(sku);
    }

    const variant = await this.prisma.$transaction(async (tx) => {
      if (!product.hasVariants) {
        await tx.product.update({
          where: { id: productId },
          data: { hasVariants: true },
        });
      }

      const created = await tx.productVariant.create({
        data: {
          productId,
          name: dto.name,
          nameAr: dto.nameAr ?? null,
          sku,
          basePrice: dto.basePrice,
          comparePrice: dto.comparePrice ?? null,
          stock: dto.stock ?? null,
          tracksStock: dto.tracksStock ?? true,
          isActive: dto.isActive ?? true,
        },
      });

      if (dto.optionGroups?.length) {
        await this.createOptionGroups(tx, null, created.id, dto.optionGroups);
      }

      return created;
    });

    this.logger.log(`Variant ${variant.id} added to product ${productId}`);
    await this.invalidateVendorCaches(vendorId);
    const updatedProduct = await this.findOne(vendorId, productId, true);
    return {
      ...updatedProduct,
      createdVariantId: variant.id,
    };
  }

  async updateVariant(
    vendorId: string,
    productId: string,
    variantId: string,
    dto: UpdateProductVariantDto,
  ) {
    const existingVariant = await this.assertVariantBelongsToProduct(
      variantId,
      productId,
      vendorId,
    );

    const sku =
      dto.sku !== undefined
        ? dto.sku?.trim()
          ? dto.sku.trim()
          : null
        : undefined;

    if (sku) {
      await this.assertVariantSkuAvailable(sku, variantId);
    }

    const clearImage =
      dto.imageUrl !== undefined &&
      (dto.imageUrl === null || dto.imageUrl.trim() === '');

    try {
      await this.prisma.productVariant.update({
        where: {
          id: variantId,
          ...(dto.version !== undefined && { version: dto.version }),
        },
        data: {
          ...(dto.name !== undefined && { name: dto.name }),
          ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
          ...(clearImage
            ? { imageUrl: null }
            : dto.imageUrl !== undefined && { imageUrl: dto.imageUrl }),
          ...(sku !== undefined && { sku }),
          ...(dto.basePrice !== undefined && { basePrice: dto.basePrice }),
          ...(dto.comparePrice !== undefined && {
            comparePrice: dto.comparePrice,
          }),
          ...(dto.stock !== undefined && { stock: dto.stock }),
          ...(dto.tracksStock !== undefined && {
            tracksStock: dto.tracksStock,
          }),
          ...(dto.isActive !== undefined && { isActive: dto.isActive }),
          version: { increment: 1 },
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new ConflictException(ProductErrors.CONCURRENT_MODIFICATION);
      }
      throw error;
    }

    if (clearImage && existingVariant.imageUrl) {
      await this.storage.delete(existingVariant.imageUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete cleared variant image for ${variantId}: ${(err as Error).message}`,
        );
      });
    }

    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  async uploadVariantImage(
    vendorId: string,
    productId: string,
    variantId: string,
    file: Express.Multer.File,
  ) {
    const existingVariant = await this.assertVariantBelongsToProduct(
      variantId,
      productId,
      vendorId,
    );

    const imageUrl = await this.storage.upload(file, 'products/variants');

    await this.prisma.productVariant.update({
      where: { id: variantId },
      data: {
        imageUrl,
        version: { increment: 1 },
      },
    });

    if (existingVariant.imageUrl) {
      await this.storage.delete(existingVariant.imageUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete old variant image for ${variantId}: ${(err as Error).message}`,
        );
      });
    }

    this.logger.log(
      `Image uploaded for product ${productId} variant ${variantId}: ${imageUrl}`,
    );
    await this.invalidateVendorCaches(vendorId);
    return { imageUrl };
  }

  async removeVariantImage(
    vendorId: string,
    productId: string,
    variantId: string,
  ) {
    const existingVariant = await this.assertVariantBelongsToProduct(
      variantId,
      productId,
      vendorId,
    );

    await this.prisma.productVariant.update({
      where: { id: variantId },
      data: {
        imageUrl: null,
        version: { increment: 1 },
      },
    });

    if (existingVariant.imageUrl) {
      await this.storage.delete(existingVariant.imageUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete removed variant image for ${variantId}: ${(err as Error).message}`,
        );
      });
    }

    this.logger.log(
      `Image removed for product ${productId} variant ${variantId}`,
    );
    await this.invalidateVendorCaches(vendorId);
    return { imageUrl: null };
  }

  async removeVariant(vendorId: string, productId: string, variantId: string) {
    const existingVariant = await this.assertVariantBelongsToProduct(
      variantId,
      productId,
      vendorId,
    );

    await this.prisma.$transaction(async (tx) => {
      await tx.productVariant.delete({ where: { id: variantId } });

      const remainingVariants = await tx.productVariant.count({
        where: { productId },
      });

      if (remainingVariants === 0) {
        const parentProduct = await tx.product.findUnique({
          where: { id: productId },
          select: { basePrice: true },
        });
        await tx.product.update({
          where: { id: productId },
          data: {
            hasVariants: false,
            ...(parentProduct?.basePrice == null
              ? { basePrice: existingVariant.basePrice }
              : {}),
            version: { increment: 1 },
          },
        });
      }
    });

    if (existingVariant.imageUrl) {
      await this.storage.delete(existingVariant.imageUrl).catch((err) => {
        this.logger.warn(
          `Failed to delete variant image on delete for ${variantId}: ${(err as Error).message}`,
        );
      });
    }

    this.logger.log(`Variant ${variantId} deleted from product ${productId}`);
    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTION GROUPS
  // ═══════════════════════════════════════════════════════════════════════════

  async addOptionGroup(
    vendorId: string,
    productId: string,
    dto: CreateOptionGroupDto,
    variantId?: string,
  ) {
    await this.assertVendorProductScope(vendorId, productId, variantId);

    const minSelect = dto.minSelect ?? 0;
    const maxSelect = dto.maxSelect ?? 1;
    this.assertValidSelectionRange(minSelect, maxSelect);

    const group = await this.prisma.$transaction(async (tx) => {
      const created = await tx.productOptionGroup.create({
        data: {
          productId: variantId ? null : productId,
          variantId: variantId ?? null,
          name: dto.name,
          nameAr: dto.nameAr ?? null,
          isRequired: dto.isRequired ?? false,
          minSelect,
          maxSelect,
        },
      });

      if (dto.options?.length) {
        await tx.productOption.createMany({
          data: dto.options.map((o) => ({
            groupId: created.id,
            name: o.name,
            nameAr: o.nameAr ?? null,
            priceAdded: o.priceAdded ?? 0,
            isActive: o.isActive ?? true,
          })),
        });
      }

      return created;
    });

    this.logger.log(`Option group ${group.id} added to product ${productId}`);
    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  async updateOptionGroup(
    vendorId: string,
    productId: string,
    groupId: string,
    dto: UpdateOptionGroupDto,
  ) {
    const existingGroup = await this.assertGroupBelongsToProduct(
      groupId,
      productId,
      vendorId,
    );

    const effectiveMin = dto.minSelect ?? existingGroup.minSelect;
    const effectiveMax = dto.maxSelect ?? existingGroup.maxSelect;
    this.assertValidSelectionRange(effectiveMin, effectiveMax);

    await this.prisma.productOptionGroup.update({
      where: { id: groupId },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
        ...(dto.isRequired !== undefined && { isRequired: dto.isRequired }),
        ...(dto.minSelect !== undefined && { minSelect: dto.minSelect }),
        ...(dto.maxSelect !== undefined && { maxSelect: dto.maxSelect }),
      },
    });

    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  async removeOptionGroup(
    vendorId: string,
    productId: string,
    groupId: string,
  ) {
    await this.assertGroupBelongsToProduct(groupId, productId, vendorId);
    await this.prisma.productOptionGroup.delete({ where: { id: groupId } });
    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  async addOption(
    vendorId: string,
    productId: string,
    groupId: string,
    dto: CreateProductOptionDto,
  ) {
    await this.assertGroupBelongsToProduct(groupId, productId, vendorId);

    await this.prisma.productOption.create({
      data: {
        groupId,
        name: dto.name,
        nameAr: dto.nameAr ?? null,
        priceAdded: dto.priceAdded ?? 0,
        isActive: dto.isActive ?? true,
      },
    });

    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  async updateOption(
    vendorId: string,
    productId: string,
    groupId: string,
    optionId: string,
    dto: UpdateProductOptionDto,
  ) {
    await this.assertGroupBelongsToProduct(groupId, productId, vendorId);
    await this.assertOptionBelongsToGroup(optionId, groupId);

    await this.prisma.productOption.update({
      where: { id: optionId },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.nameAr !== undefined && { nameAr: dto.nameAr }),
        ...(dto.priceAdded !== undefined && { priceAdded: dto.priceAdded }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });

    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  async removeOption(
    vendorId: string,
    productId: string,
    groupId: string,
    optionId: string,
  ) {
    await this.assertGroupBelongsToProduct(groupId, productId, vendorId);
    await this.assertOptionBelongsToGroup(optionId, groupId);
    await this.prisma.productOption.delete({ where: { id: optionId } });
    await this.invalidateVendorCaches(vendorId);
    return this.findOne(vendorId, productId, true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  private assertValidSelectionRange(minSelect: number, maxSelect: number) {
    if (minSelect > maxSelect) {
      throw new BadRequestException(ProductErrors.INVALID_OPTION_GROUP_RANGE);
    }
  }

  private async createOptionGroups(
    tx: Prisma.TransactionClient,
    productId: string | null,
    variantId: string | null,
    groups: CreateOptionGroupDto[],
  ) {
    for (const g of groups) {
      const minSelect = g.minSelect ?? 0;
      const maxSelect = g.maxSelect ?? 1;
      this.assertValidSelectionRange(minSelect, maxSelect);

      const group = await tx.productOptionGroup.create({
        data: {
          productId,
          variantId,
          name: g.name,
          nameAr: g.nameAr ?? null,
          isRequired: g.isRequired ?? false,
          minSelect,
          maxSelect,
        },
      });

      if (g.options?.length) {
        await tx.productOption.createMany({
          data: g.options.map((o) => ({
            groupId: group.id,
            name: o.name,
            nameAr: o.nameAr ?? null,
            priceAdded: o.priceAdded ?? 0,
            isActive: o.isActive ?? true,
          })),
        });
      }
    }
  }

  private async createVariantWithOptions(
    tx: Prisma.TransactionClient,
    productId: string,
    dto: CreateProductVariantDto,
  ) {
    const sku = dto.sku?.trim() ? dto.sku.trim() : null;
    if (sku) {
      await this.assertVariantSkuAvailable(sku);
    }

    const variant = await tx.productVariant.create({
      data: {
        productId,
        name: dto.name,
        nameAr: dto.nameAr ?? null,
        sku,
        basePrice: dto.basePrice,
        comparePrice: dto.comparePrice ?? null,
        stock: dto.stock ?? null,
        tracksStock: dto.tracksStock ?? true,
        isActive: dto.isActive ?? true,
      },
    });

    if (dto.optionGroups?.length) {
      await this.createOptionGroups(tx, null, variant.id, dto.optionGroups);
    }
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
        throw new BadRequestException(
          ProductErrors.BRANCH_AVAILABILITY_INVALID,
        );
      }
      return { mode: ProductBranchAvailabilityMode.ALL, branchIds: [] };
    }

    if (uniqueBranchIds.length === 0) {
      throw new BadRequestException(ProductErrors.BRANCHES_REQUIRED);
    }

    const branches = await this.prisma.vendorBranch.findMany({
      where: {
        id: { in: uniqueBranchIds },
        vendorId,
      },
      select: { id: true },
    });
    if (branches.length !== uniqueBranchIds.length) {
      throw new BadRequestException(ProductErrors.BRANCH_NOT_IN_VENDOR);
    }

    return {
      mode: ProductBranchAvailabilityMode.SPECIFIC,
      branchIds: uniqueBranchIds,
    };
  }

  private async resolveBranchAvailabilityForUpdate(
    vendorId: string,
    productId: string,
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
      const existing = await this.prisma.productBranchAvailability.findMany({
        where: { productId },
        select: { branchId: true },
      });
      if (existing.length === 0) {
        throw new BadRequestException(ProductErrors.BRANCHES_REQUIRED);
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
      throw new BadRequestException(ProductErrors.BRANCH_NOT_IN_VENDOR);
    }
  }

  private async assertCategoryBelongsToVendor(
    categoryId: string,
    vendorId: string,
  ) {
    const cat = await this.prisma.menuCategory.findFirst({
      where: { id: categoryId, vendorId },
      select: { id: true },
    });
    if (!cat) throw new NotFoundException(ProductErrors.CATEGORY_NOT_FOUND);
  }

  private async assertSkuAvailable(sku: string, excludeId?: string) {
    const existing = await this.prisma.product.findFirst({
      where: { sku },
      select: { id: true },
    });
    if (existing && existing.id !== excludeId) {
      throw new ConflictException(ProductErrors.SKU_TAKEN);
    }
  }

  private async assertVariantSkuAvailable(sku: string, excludeId?: string) {
    const existing = await this.prisma.productVariant.findUnique({
      where: { sku },
      select: { id: true },
    });
    if (existing && existing.id !== excludeId) {
      throw new ConflictException(ProductErrors.SKU_TAKEN);
    }
  }

  private async assertVariantBelongsToProduct(
    variantId: string,
    productId: string,
    vendorId: string,
  ) {
    // Also validate vendor scope via product
    const product = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { id: true },
    });
    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);

    const variant = await this.prisma.productVariant.findFirst({
      where: { id: variantId, productId },
      select: { id: true, imageUrl: true, basePrice: true },
    });
    if (!variant) throw new NotFoundException(ProductErrors.VARIANT_NOT_FOUND);
    return variant;
  }

  private async assertVendorProductScope(
    vendorId: string,
    productId: string,
    variantId?: string,
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { id: true },
    });
    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);

    if (variantId) {
      const variant = await this.prisma.productVariant.findFirst({
        where: { id: variantId, productId },
        select: { id: true },
      });
      if (!variant)
        throw new NotFoundException(ProductErrors.VARIANT_NOT_FOUND);
    }
  }

  private async assertGroupBelongsToProduct(
    groupId: string,
    productId: string,
    vendorId: string,
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, vendorId, deletedAt: null },
      select: { id: true },
    });
    if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);

    const group = await this.prisma.productOptionGroup.findFirst({
      where: {
        id: groupId,
        OR: [{ productId }, { variant: { productId } }],
      },
      select: { id: true, minSelect: true, maxSelect: true },
    });
    if (!group)
      throw new NotFoundException(ProductErrors.OPTION_GROUP_NOT_FOUND);
    return group;
  }

  private async assertOptionBelongsToGroup(optionId: string, groupId: string) {
    const option = await this.prisma.productOption.findFirst({
      where: { id: optionId, groupId },
      select: { id: true },
    });
    if (!option) throw new NotFoundException(ProductErrors.OPTION_NOT_FOUND);
  }

  private async invalidateVendorCaches(vendorId: string) {
    await (
      this.vendorCache ?? new VendorCacheService(this.prisma, this.cacheManager)
    ).invalidateVendorDetails(vendorId);
  }
}
