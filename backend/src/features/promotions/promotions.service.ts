import { Injectable, NotFoundException, Optional } from '@nestjs/common';

import { PromotionErrors } from 'src/common/constants/response.constants';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { CreatePromotionDto, UpdatePromotionDto } from './dto/promotions.dto';

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
      },
    });
  }

  async findAllActive() {
    const now = new Date();
    return this.prisma.promotion.findMany({
      where: {
        isActive: true,
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
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
  }

  async findOne(id: string) {
    const promotion = await this.prisma.promotion.findUnique({
      where: { id },
      include: {
        vendor: true,
        product: true,
      },
    });
    if (!promotion) throw new NotFoundException(PromotionErrors.NOT_FOUND);
    return promotion;
  }

  async create(dto: CreatePromotionDto) {
    return this.prisma.promotion.create({
      data: {
        ...dto,
        title: dto.title ?? '',
        imageUrl: dto.imageUrl ?? '',
      },
    });
  }

  async update(id: string, dto: UpdatePromotionDto) {
    const existing = await this.findOne(id);
    const updated = await this.prisma.promotion.update({
      where: { id },
      data: dto,
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
