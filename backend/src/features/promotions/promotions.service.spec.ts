import { NotFoundException } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import {
  PromotionErrors,
  VendorVerticalErrors,
} from '../../common/constants/response.constants';

describe('PromotionsService (vertical-scoped banners)', () => {
  const makePrisma = () => ({
    promotion: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    vendorVertical: {
      findUnique: jest.fn(),
    },
  });

  it('includes vertical metadata in findAllActive and supports verticalId/verticalSlug filters', async () => {
    const prisma = makePrisma();
    prisma.promotion.findMany.mockResolvedValue([]);
    const service = new PromotionsService(prisma as any);

    await service.findAllActive({ verticalSlug: 'restaurants' });

    expect(prisma.promotion.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          isActive: true,
          vertical: { slug: 'restaurants' },
        }),
        include: {
          vertical: {
            select: { id: true, name: true, nameAr: true, slug: true },
          },
        },
      }),
    );

    prisma.promotion.findMany.mockClear();
    await service.findAllActive({ verticalId: 'vert-1' });
    expect(prisma.promotion.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          isActive: true,
          verticalId: 'vert-1',
        }),
      }),
    );
  });

  it('validates verticalId exists when creating a promotion', async () => {
    const prisma = makePrisma();
    prisma.vendorVertical.findUnique.mockResolvedValue(null);
    const service = new PromotionsService(prisma as any);

    await expect(
      service.create({ title: 'Promo', verticalId: 'missing-vertical' }),
    ).rejects.toThrow(new NotFoundException(VendorVerticalErrors.NOT_FOUND));
    expect(prisma.promotion.create).not.toHaveBeenCalled();

    prisma.vendorVertical.findUnique.mockResolvedValue({ id: 'vert-1' });
    prisma.promotion.create.mockResolvedValue({
      id: 'promo-1',
      verticalId: 'vert-1',
    });

    const created = await service.create({
      title: 'Restaurants Deal',
      verticalId: 'vert-1',
    });
    expect(created).toEqual({ id: 'promo-1', verticalId: 'vert-1' });
    expect(prisma.promotion.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ verticalId: 'vert-1' }),
      }),
    );
  });

  it('allows clearing verticalId back to null on update and throws when promotion missing', async () => {
    const prisma = makePrisma();
    prisma.promotion.findUnique.mockResolvedValue(null);
    const service = new PromotionsService(prisma as any);

    await expect(service.update('missing', { verticalId: null })).rejects.toThrow(
      new NotFoundException(PromotionErrors.NOT_FOUND),
    );

    prisma.promotion.findUnique.mockResolvedValue({
      id: 'promo-1',
      imageUrl: 'old.png',
      verticalId: 'vert-1',
    });
    prisma.promotion.update.mockResolvedValue({
      id: 'promo-1',
      imageUrl: 'old.png',
      verticalId: null,
    });

    const updated = await service.update('promo-1', { verticalId: null });
    expect(updated.verticalId).toBeNull();
    expect(prisma.vendorVertical.findUnique).not.toHaveBeenCalled();
  });
});
