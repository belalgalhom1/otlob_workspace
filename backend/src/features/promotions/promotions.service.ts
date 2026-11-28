import { Injectable, NotFoundException, Optional } from '@nestjs/common';

import {
  PromotionErrors,
  VendorVerticalErrors,
} from 'src/common/constants/response.constants';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { CreatePromotionDto, UpdatePromotionDto } from './dto/promotions.dto';

const VERTICAL_SELECT = {
  id: true,
  name: true,
  nameAr: true,
  slug: true,
} as const;

@Injectable()
export class PromotionsService {
  constructor(
    private prisma: PrismaService,
    @Optional() private readonly storage?: StorageService,
  ) {}

  async findAll() {
    return this.prisma.promotion.findMany({
      orderBy: { sortOrder: 'asc' },
      include: {
        vendor: {
          select: { id: true, storeName: true, storeNameAr: true, logo: true },
        },
        product: {
          select: { id: true, name: true, nameAr: true },
        },
        vertical: {
          select: VERTICAL_SELECT,
        },
      },
    });
  }

  async findAllActive(filter?: { verticalId?: string; verticalSlug?: string }) {
    const now = new Date();
    const verticalId = filter?.verticalId?.trim() || undefined;
    const verticalSlug = filter?.verticalSlug?.trim() || undefined;

    return this.prisma.promotion.findMany({
      where: {
        isActive: true,
        ...(verticalId ? { verticalId } : {}),
        ...(verticalSlug ? { vertical: { slug: verticalSlug } } : {}),
        AND: [
          { OR: [{ startDate: null }, { startDate: { lte: now } }] },
          { OR: [{ endDate: null }, { endDate: { gte: now } }] },
          {
            OR: [
              { vendorId: null },
              {
                vendor: {
                  deletedAt: null,
                  status: { not: 'SUSPENDED' },
                },
              },
            ],
          },
          {
            OR: [
              { productId: null },
              {
                product: {
                  deletedAt: null,
                  isActive: true,
                },
              },
            ],
          },
        ],
      },
      include: {
        vertical: {
          select: VERTICAL_SELECT,
        },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
  }

  async findOne(id: string) {
    const promotion = await this.prisma.promotion.findUnique({
      where: { id },
      include: {
        vendor: true,
        product: true,
        vertical: true,
      },
    });
    if (!promotion) throw new NotFoundException(PromotionErrors.NOT_FOUND);
    return promotion;
  }

  private async ensureVerticalExists(verticalId?: string | null) {
    if (!verticalId) return;
    const vertical = await this.prisma.vendorVertical.findUnique({
      where: { id: verticalId },
      select: { id: true },
    });
    if (!vertical) {
      throw new NotFoundException(VendorVerticalErrors.NOT_FOUND);
    }
  }

  async create(dto: CreatePromotionDto) {
    await this.ensureVerticalExists(dto.verticalId);
    return this.prisma.promotion.create({
      data: {
        ...dto,
        title: dto.title ?? '',
        imageUrl: dto.imageUrl ?? '',
      },
      include: {
        vertical: {
          select: VERTICAL_SELECT,
        },
      },
    });
  }

  async update(id: string, dto: UpdatePromotionDto) {
    const existing = await this.findOne(id);
    if (dto.verticalId !== undefined) {
      await this.ensureVerticalExists(dto.verticalId);
    }
    const updated = await this.prisma.promotion.update({
      where: { id },
      data: dto,
      include: {
        vertical: {
          select: VERTICAL_SELECT,
        },
      },
    });
    if (
      updated.imageUrl &&
      existing.imageUrl &&
      existing.imageUrl !== updated.imageUrl
    ) {
      await this.storage?.delete(existing.imageUrl).catch(() => undefined);
    }
    return updated;
  }

  async updateImage(id: string, imageUrl: string) {
    const existing = await this.findOne(id);
    const updated = await this.prisma.promotion.update({
      where: { id },
      data: { imageUrl },
    });
    if (existing.imageUrl && existing.imageUrl !== imageUrl) {
      await this.storage?.delete(existing.imageUrl).catch(() => undefined);
    }
    return updated;
  }

  async remove(id: string) {
    const existing = await this.findOne(id);
    const deleted = await this.prisma.promotion.delete({ where: { id } });
    if (existing.imageUrl) {
      await this.storage?.delete(existing.imageUrl).catch(() => undefined);
    }
    return deleted;
  }
}
