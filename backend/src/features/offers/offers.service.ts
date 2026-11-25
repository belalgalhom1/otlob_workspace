import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  CreateOfferDto,
  UpdateOfferDto,
} from '../promotions/dto/promotions.dto';
import {
  CommonErrors,
  ProductErrors,
  PromotionErrors,
} from 'src/common/constants/response.constants';
import { VendorCacheService } from '../vendors/helpers/vendor-cache.service';

@Injectable()
export class OffersService {
  constructor(
    private prisma: PrismaService,
    @Optional() private readonly vendorCache?: VendorCacheService,
  ) {}

  async findAllActive(limit = 100) {
    const now = new Date();
    const take = Math.min(Math.max(limit, 1), 200);
    return this.prisma.offer.findMany({
      where: {
        isActive: true,
        AND: [
          {
            OR: [{ startDate: null }, { startDate: { lte: now } }],
          },
          {
            OR: [{ endDate: null }, { endDate: { gte: now } }],
          },
          {
            OR: [{ variantId: null }, { variant: { isActive: true } }],
          },
        ],
        product: {
          isActive: true,
          deletedAt: null,
        },
        vendor: {
          deletedAt: null,
          status: { not: 'SUSPENDED' },
        },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
      take,
      include: {
        vendor: {
          select: { id: true, storeName: true, storeNameAr: true, logo: true },
        },
        product: {
          select: {
            id: true,
            name: true,
            nameAr: true,
            imageUrl: true,
            basePrice: true,
            comparePrice: true,
            hasVariants: true,
          },
        },
        variant: {
          select: {
            id: true,
            name: true,
            nameAr: true,
            imageUrl: true,
            basePrice: true,
            comparePrice: true,
          },
        },
      },
    });
  }

  async findAll(vendorId?: string, limit = 100) {
    const take = Math.min(Math.max(limit, 1), 200);
    return this.prisma.offer.findMany({
      where: vendorId ? { vendorId } : undefined,
      orderBy: { createdAt: 'desc' },
      take,
      include: {
        vendor: {
          select: { id: true, storeName: true, storeNameAr: true, logo: true },
        },
        product: {
          select: {
            id: true,
            name: true,
            nameAr: true,
            imageUrl: true,
            basePrice: true,
            comparePrice: true,
            hasVariants: true,
          },
        },
        variant: {
          select: {
            id: true,
            name: true,
            nameAr: true,
            imageUrl: true,
            basePrice: true,
            comparePrice: true,
          },
        },
      },
    });
  }

  async create(dto: CreateOfferDto) {
    const product = await this.prisma.product.findFirst({
      where: { id: dto.productId, deletedAt: null },
      select: { id: true, vendorId: true },
    });
    if (!product || product.vendorId !== dto.vendorId) {
      throw new NotFoundException(ProductErrors.NOT_FOUND);
    }

    if (dto.offerPrice >= dto.originalPrice) {
      throw new BadRequestException(CommonErrors.VALIDATION_ERROR);
    }

    if (dto.variantId) {
      const variant = await this.prisma.productVariant.findUnique({
        where: { id: dto.variantId },
      });
      if (!variant || variant.productId !== dto.productId) {
        throw new NotFoundException(ProductErrors.VARIANT_NOT_FOUND);
      }
    }

    const offer = await this.prisma.offer.create({
      data: {
        productId: dto.productId,
        variantId: dto.variantId ?? null,
        vendorId: dto.vendorId,
        originalPrice: dto.originalPrice,
        offerPrice: dto.offerPrice,
        sortOrder: dto.sortOrder,
        startDate: dto.startDate,
        endDate: dto.endDate,
      },
    });
    await this.vendorCache?.invalidateVendorDetails(offer.vendorId);
    return offer;
  }

  async update(id: string, dto: UpdateOfferDto) {
    const currentOffer = await this.prisma.offer.findUnique({
      where: { id },
    });
    if (!currentOffer) {
      throw new NotFoundException(PromotionErrors.NOT_FOUND);
    }

    const nextOriginal = dto.originalPrice ?? currentOffer.originalPrice;
    const nextOffer = dto.offerPrice ?? currentOffer.offerPrice;
    if (nextOffer >= nextOriginal) {
      throw new BadRequestException(CommonErrors.VALIDATION_ERROR);
    }

    if (dto.variantId) {
      const variant = await this.prisma.productVariant.findUnique({
        where: { id: dto.variantId },
      });
      if (!variant || variant.productId !== currentOffer.productId) {
        throw new NotFoundException(ProductErrors.VARIANT_NOT_FOUND);
      }
    }

    const updated = await this.prisma.offer.update({
      where: { id },
      data: {
        variantId:
          dto.variantId !== undefined ? (dto.variantId ?? null) : undefined,
        originalPrice: dto.originalPrice,
        offerPrice: dto.offerPrice,
        isActive: dto.isActive,
        sortOrder: dto.sortOrder,
        startDate: dto.startDate,
        endDate: dto.endDate,
      },
    });
    await this.vendorCache?.invalidateVendorDetails(updated.vendorId);
    return updated;
  }

  async remove(id: string) {
    const deleted = await this.prisma.offer.delete({ where: { id } });
    await this.vendorCache?.invalidateVendorDetails(deleted.vendorId);
    return deleted;
  }
}
