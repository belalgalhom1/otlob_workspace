import {
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Permission, Role } from '@prisma/client';
import { ProductsService } from './products.service';
import { VendorsService } from '../vendors.service';
import { CartService } from '../../cart/cart.service';
import { VendorMemberGuard } from '../../../common/guards/vendor-member.guard';
import {
  VENDOR_ADMIN_PERMISSIONS_KEY,
  VENDOR_ID_PARAM_KEY,
  VENDOR_MEMBER_ROLES_KEY,
} from '../../../common/decorators/vendor-member.decorator';
import {
  CartErrors,
  ProductErrors,
} from '../../../common/constants/response.constants';

describe('Products, Variants, OptionGroups & Cart refactoring', () => {
  describe('ProductsService', () => {
    it('flips hasVariants=false and syncs basePrice when the last variant is removed', async () => {
      const tx: any = {
        productVariant: {
          delete: jest.fn().mockResolvedValue({ id: 'var-1' }),
          count: jest.fn().mockResolvedValue(0),
        },
        product: {
          findUnique: jest.fn().mockResolvedValue({ basePrice: null }),
          update: jest.fn().mockResolvedValue({ id: 'prod-1' }),
        },
      };
      const prisma: any = {
        product: {
          findFirst: jest
            .fn()
            .mockResolvedValueOnce({ id: 'prod-1' })
            .mockResolvedValueOnce({ id: 'prod-1', hasVariants: false, variants: [] }),
        },
        productVariant: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'var-1',
            imageUrl: null,
            basePrice: 120,
          }),
        },
        $transaction: jest.fn((fn: any) => fn(tx)),
      };
      const cache: any = {
        get: jest.fn(),
        set: jest.fn(),
        del: jest.fn(),
      };
      const vendorCache: any = {
        invalidateVendorDetails: jest.fn().mockResolvedValue(undefined),
      };

      const service = new ProductsService(
        prisma,
        { delete: jest.fn() } as any,
        cache,
        vendorCache,
      );

      await service.removeVariant('vend-1', 'prod-1', 'var-1');

      expect(tx.product.update).toHaveBeenCalledWith({
        where: { id: 'prod-1' },
        data: {
          hasVariants: false,
          basePrice: 120,
          version: { increment: 1 },
        },
      });
    });

    it('rejects option group where minSelect exceeds maxSelect on add and partial update', async () => {
      const prisma: any = {
        product: {
          findFirst: jest.fn().mockResolvedValue({ id: 'prod-1' }),
        },
        productOptionGroup: {
          findFirst: jest
            .fn()
            .mockResolvedValue({ id: 'grp-1', minSelect: 1, maxSelect: 2 }),
        },
      };
      const service = new ProductsService(
        prisma,
        {} as any,
        {} as any,
        { invalidateVendorDetails: jest.fn() } as any,
      );

      await expect(
        service.addOptionGroup('vend-1', 'prod-1', {
          name: 'Toppings',
          minSelect: 4,
          maxSelect: 2,
        }),
      ).rejects.toThrow(
        new BadRequestException(ProductErrors.INVALID_OPTION_GROUP_RANGE),
      );

      await expect(
        service.updateOptionGroup('vend-1', 'prod-1', 'grp-1', {
          minSelect: 5,
        }),
      ).rejects.toThrow(
        new BadRequestException(ProductErrors.INVALID_OPTION_GROUP_RANGE),
      );
    });
  });

  describe('VendorMemberGuard', () => {
    it('allows ADMIN with route-specific MANAGE_PRODUCTS permission while blocking unpermitted admin routes', async () => {
      const prisma: any = {
        user: {
          findUnique: jest.fn().mockResolvedValue({
            permissions: [Permission.MANAGE_PRODUCTS],
          }),
        },
        vendor: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'vend-1',
            members: [],
          }),
        },
      };

      const reflector = {
        getAllAndOverride: jest.fn((key: string) => {
          if (key === VENDOR_ADMIN_PERMISSIONS_KEY) {
            return [Permission.MANAGE_PRODUCTS];
          }
          if (key === VENDOR_ID_PARAM_KEY) return 'vendorId';
          if (key === VENDOR_MEMBER_ROLES_KEY) return [];
          return undefined;
        }),
      } as unknown as Reflector;

      const guard = new VendorMemberGuard(reflector, prisma);
      const ctx: any = {
        getHandler: jest.fn(),
        getClass: jest.fn(),
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'admin-1', role: Role.ADMIN },
            params: { vendorId: 'vend-1' },
          }),
        }),
      };

      await expect(guard.canActivate(ctx)).resolves.toBe(true);

      // Without route adminPermissions, MANAGE_PRODUCTS alone must not access vendor-member routes.
      (reflector.getAllAndOverride as jest.Mock).mockImplementation(
        (key: string) => {
          if (key === VENDOR_ADMIN_PERMISSIONS_KEY) return [];
          if (key === VENDOR_ID_PARAM_KEY) return 'vendorId';
          if (key === VENDOR_MEMBER_ROLES_KEY) return [];
          return undefined;
        },
      );

      await expect(guard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
    });
  });

  describe('VendorsService discovery & offer pricing', () => {
    it('computes searchDiscovery starting price from active variants and keeps offer discounts anchored on basePrice', async () => {
      const prisma: any = {
        product: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'p1',
              vendorId: 'v1',
              name: 'Qashtouta',
              nameAr: 'قشطوطة',
              description: null,
              basePrice: null,
              comparePrice: null,
              hasVariants: true,
              imageUrl: 'img.png',
              sellByStrip: false,
              stripsPerPackage: null,
              variants: [{ basePrice: 80 }, { basePrice: 55 }],
              vendor: {
                id: 'v1',
                status: 'OPEN',
                storeName: 'Store',
                storeNameAr: null,
                slug: 'store',
                description: null,
                descriptionAr: null,
                workingHours: null,
                coverImage: null,
                logo: null,
                isScheduleActive: false,
                is24Hours: true,
                vertical: { name: 'Sweets', nameAr: 'حلويات', slug: 'sweets' },
              },
            },
          ]),
        },
        vendor: { findMany: jest.fn().mockResolvedValue([]) },
      };

      const service = new VendorsService(
        prisma,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      const searchRes = await service.searchDiscovery({
        search: 'Qash',
      } as any);
      expect(searchRes.results[0].matchingProducts[0].price).toBe(55);
      expect(searchRes.results[0].matchingProducts[0].hasVariants).toBe(true);

      // Variant with basePrice=100, comparePrice=200 and 10% product offer should cost 90, NOT 180.
      const mappedVendor = (service as any).mapVendorForApp({
        id: 'v1',
        status: 'OPEN',
        storeName: 'Store',
        storeNameAr: null,
        slug: 'store',
        description: null,
        descriptionAr: null,
        workingHours: null,
        coverImage: null,
        logo: null,
        isScheduleActive: false,
        vertical: { name: 'Restaurant', nameAr: null, slug: 'restaurant' },
        products: [
          {
            id: 'p2',
            name: 'Pizza',
            nameAr: null,
            description: null,
            descriptionAr: null,
            basePrice: null,
            comparePrice: null,
            stock: null,
            tracksStock: false,
            imageUrl: null,
            categoryId: null,
            sellByStrip: false,
            stripsPerPackage: null,
            hasVariants: true,
            offers: [
              {
                id: 'off-1',
                variantId: null,
                offerPrice: 90,
                originalPrice: 100,
              },
            ],
            variants: [
              {
                id: 'var-l',
                name: 'Large',
                basePrice: 100,
                comparePrice: 200,
              },
            ],
            optionGroups: [],
          },
        ],
      });
      expect(mappedVendor.menu[0].variants[0].price).toBe(90);
      expect(mappedVendor.menu[0].variants[0].comparePrice).toBe(200);
    });
  });

  describe('CartService strip integers & stock checks', () => {
    it('rounds strip unitPrice to integer so totalPrice === unitPrice * quantity and checks variant strip stock', async () => {
      const cartService = new CartService({
        customer: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'c1',
            canOrder: true,
            coinBalance: 0,
          }),
        },
        cart: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'cart-1',
            vendorId: 'v1',
            vendor: { isContracted: true, commissionRate: 10 },
            items: [
              {
                id: 'ci-1',
                productId: 'p-med',
                variantId: 'var-box',
                quantity: 4,
                selectedUnit: 'strip',
                specialRequest: null,
                customName: null,
                customPrice: null,
                customImageUrl: null,
                product: {
                  id: 'p-med',
                  name: 'Med',
                  nameAr: 'دواء',
                  basePrice: null,
                  comparePrice: null,
                  isActive: true,
                  sellByStrip: true,
                  stripsPerPackage: 3,
                  stock: null,
                  tracksStock: false,
                  imageUrl: null,
                  hasVariants: true,
                  offers: [],
                },
                variant: {
                  id: 'var-box',
                  name: 'Box',
                  nameAr: 'علبة',
                  imageUrl: null,
                  basePrice: 50,
                  comparePrice: null,
                  isActive: true,
                  stock: 1, // 1 package = 3 strips, requesting 4 strips -> NOT_ENOUGH_STOCK
                  tracksStock: true,
                },
                selectedOptions: [],
              },
            ],
          }),
        },
        product: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'p-med',
              hasVariants: true,
              variants: [{ id: 'var-box', optionGroups: [] }],
              optionGroups: [],
            },
          ]),
        },
      } as any);

      const formatted = (cartService as any).formatCart({
        id: 'cart-1',
        vendorId: 'v1',
        vendor: { isContracted: true, commissionRate: 10 },
        items: [
          {
            id: 'ci-1',
            productId: 'p-med',
            variantId: 'var-box',
            quantity: 4,
            selectedUnit: 'strip',
            specialRequest: null,
            customName: null,
            customPrice: null,
            customImageUrl: null,
            product: {
              id: 'p-med',
              name: 'Med',
              nameAr: 'دواء',
              basePrice: null,
              comparePrice: null,
              isActive: true,
              sellByStrip: true,
              stripsPerPackage: 3,
              stock: null,
              tracksStock: false,
              imageUrl: null,
              hasVariants: true,
              offers: [],
            },
            variant: {
              id: 'var-box',
              basePrice: 50,
              comparePrice: null,
              name: 'Box',
              isActive: true,
              stock: 2,
              tracksStock: true,
            },
            selectedOptions: [],
          },
        ],
      });

      expect(Number.isInteger(formatted.items[0].unitPrice)).toBe(true);
      expect(formatted.items[0].unitPrice).toBe(17);
      expect(formatted.items[0].totalPrice).toBe(68);
      expect(formatted.subtotal).toBe(68);

      await expect(
        cartService.validateForCheckout('user-1', 'v1'),
      ).rejects.toThrow(new BadRequestException(CartErrors.NOT_ENOUGH_STOCK));
    });
  });
});
