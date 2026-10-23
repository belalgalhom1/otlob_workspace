import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AddCartItemDto, UpdateCartItemDto } from './dto/cart.dto';
import {
  Prisma,
  MessageType,
  ProductBranchAvailabilityMode,
} from '@prisma/client';
import { CartErrors } from 'src/common/constants/response.constants';
import {
  CustomerErrors,
  ProductErrors,
  OrderErrors,
  ChatErrors,
} from 'src/common/constants/response.constants';

import { createHash } from 'crypto';

type CartProduct = Prisma.ProductGetPayload<{
  include: {
    variants: {
      where: { isActive: true };
      include: {
        optionGroups: {
          include: { options: { where: { isActive: true } } };
        };
      };
    };
    optionGroups: {
      include: { options: { where: { isActive: true } } };
    };
  };
}>;

type CartItemInclude = {
  id: string;
  productId: string | null;
  variantId: string | null;
  quantity: number;
  selectedUnit: string;
  specialRequest: string | null;
  customName: string | null;
  customPrice: number | null;
  customImageUrl: string | null;
  product: {
    id?: string;
    basePrice: number;
    comparePrice?: number | null;
    name: string | null;
    nameAr?: string | null;
    isActive: boolean;
    sellByStrip: boolean;
    stripsPerPackage: number | null;
    stock: number | null;
    tracksStock: boolean;
    imageUrl: string | null;
    hasVariants: boolean;
    offers?: {
      id?: string;
      variantId?: string | null;
      offerPrice: number;
      originalPrice?: number | null;
      isActive: boolean;
      startDate: Date | null;
      endDate: Date | null;
    }[];
  } | null;
  variant: {
    id?: string;
    basePrice: number;
    comparePrice?: number | null;
    name: string | null;
    nameAr?: string | null;
    isActive: boolean;
    stock: number | null;
    tracksStock: boolean;
  } | null;
  selectedOptions: {
    option: {
      id: string;
      name: string;
      nameAr: string | null;
      priceAdded: number;
      group?: { id: string; name: string } | null;
    };
  }[];
};

type CartInclude = {
  id: string;
  vendorId: string;
  items: CartItemInclude[];
  vendor: { isContracted: boolean; commissionRate: number | null } | null;
};

@Injectable()
export class CartService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Get or create cart for vendor ────────────────────────────────────────

  async getCart(userId: string, vendorId: string) {
    const customer = await this.getCustomer(userId);

    const cart = await this.prisma.cart.findUnique({
      where: { customerId_vendorId: { customerId: customer.id, vendorId } },
      include: this.cartIncludes(),
    });

    if (!cart) {
      return this.buildEmptyCart(vendorId);
    }

    return this.formatCart(cart);
  }

  // ─── Get all carts for the customer (one per vendor) ──────────────────────

  async getMyCarts(userId: string) {
    const customer = await this.getCustomer(userId);

    const carts = await this.prisma.cart.findMany({
      where: { customerId: customer.id },
      include: this.cartIncludes(),
      orderBy: { updatedAt: 'desc' },
    });

    return carts.map((c) => this.formatCart(c));
  }

  // ─── Add item to cart ─────────────────────────────────────────────────────

  async addItem(userId: string, vendorId: string, dto: AddCartItemDto) {
    const customer = await this.getCustomer(userId);

    if (!customer.canOrder) {
      throw new ForbiddenException(CustomerErrors.CANNOT_ORDER);
    }

    const selectedUnit = dto.selectedUnit ?? 'package';

    let customPrice: number | null = null;
    let customName: string | null = null;
    let customImageUrl: string | null = null;
    let finalProductId: string | null = dto.productId ?? null;

    if (dto.offerMessageId) {
      const message = await this.prisma.message.findUnique({
        where: { id: dto.offerMessageId },
        include: { conversation: { include: { participants: true } } },
      });

      if (
        !message ||
        message.type !== MessageType.PRODUCT ||
        message.conversation.vendorId !== vendorId
      ) {
        throw new BadRequestException(OrderErrors.INVALID_OFFER_MESSAGE);
      }

      const isParticipant = message.conversation.participants.some(
        (p) => p.userId === userId,
      );
      if (!isParticipant) {
        throw new ForbiddenException(ChatErrors.NOT_A_PARTICIPANT);
      }

      // Chat metadata is untrusted input: validate shape and ranges before
      // anything touches the cart. Prices are minor units (Int, >= 0).
      const meta = message.metadata as Record<string, any>;
      const metaProduct = meta?.product as Record<string, any> | undefined;
      const metaPrice = Number(metaProduct?.price);
      const metaName = metaProduct?.name;
      if (
        !metaProduct ||
        typeof metaName !== 'string' ||
        metaName.trim().length === 0 ||
        metaName.length > 200 ||
        !Number.isInteger(metaPrice) ||
        metaPrice < 0 ||
        metaPrice > 10_000_000
      ) {
        throw new BadRequestException(OrderErrors.INVALID_OFFER_MESSAGE);
      }
      customPrice = metaPrice;
      customName = metaName.trim();
      customImageUrl =
        typeof metaProduct.imageUrl === 'string'
          ? metaProduct.imageUrl.slice(0, 500)
          : null;
      if (typeof metaProduct.productId === 'string' && metaProduct.productId) {
        finalProductId = metaProduct.productId;
      }
    }

    if (!finalProductId && !dto.offerMessageId) {
      throw new BadRequestException(OrderErrors.PRODUCT_ID_REQUIRED);
    }

    // Pure-custom lines (no catalog product) accept no variant/options:
    // option rows would otherwise attach orphan charges and variant stock
    // would be checked against the wrong line at checkout.
    if (!finalProductId) {
      if (dto.variantId) {
        throw new BadRequestException(CartErrors.INVALID_OPTION);
      }
      if (dto.optionIds?.length) {
        throw new BadRequestException(CartErrors.INVALID_OPTION);
      }
    }

    let product: CartProduct | null = null;

    if (finalProductId) {
      product = await this.prisma.product.findFirst({
        where: {
          id: finalProductId,
          vendorId,
          isActive: true,
          deletedAt: null,
        },
        include: {
          variants: {
            where: { isActive: true },
            include: {
              optionGroups: {
                include: { options: { where: { isActive: true } } },
              },
            },
          },
          optionGroups: {
            include: { options: { where: { isActive: true } } },
          },
        },
      });

      if (!product) throw new NotFoundException(ProductErrors.NOT_FOUND);

      // Validate variant if provided
      if (dto.variantId) {
        const variant = product.variants.find((v) => v.id === dto.variantId);
        if (!variant)
          throw new NotFoundException(ProductErrors.VARIANT_NOT_FOUND);
      } else if (product.hasVariants) {
        throw new BadRequestException(OrderErrors.VARIANT_SELECTION_REQUIRED);
      }

      // Always validate (even with no options): required groups must fail
      // closed instead of silently passing.
      if (finalProductId && product) {
        this.validateOptions(product, dto.optionIds ?? [], dto.variantId);
      }
    }

    const optionHash = dto.optionIds?.length
      ? createHash('sha256')
          .update((dto.variantId ?? '') + [...dto.optionIds].sort().join(','))
          .digest('hex')
      : null;

    await this.prisma.$transaction(async (tx) => {
      // Upsert cart
      const cart = await tx.cart.upsert({
        where: { customerId_vendorId: { customerId: customer.id, vendorId } },
        create: { customerId: customer.id, vendorId },
        update: { updatedAt: new Date() },
      });

      // Find existing item manually: merge key must include the variant,
      // otherwise two variants with colliding hashes would merge.
      let existingItem: any = null;
      if (finalProductId) {
        existingItem = await tx.cartItem.findFirst({
          where: {
            cartId: cart.id,
            productId: finalProductId,
            variantId: dto.variantId ?? null,
            optionHash: optionHash ?? '',
            selectedUnit,
            customPrice: customPrice ?? null, // Match custom price exactly to avoid grouping custom offers with regular ones
          },
        });
      } else {
        // Pure custom product
        existingItem = await tx.cartItem.findFirst({
          where: {
            cartId: cart.id,
            productId: null,
            customName: customName,
            customPrice: customPrice ?? null,
          },
        });
      }

      if (existingItem) {
        await tx.cartItem.update({
          where: { id: existingItem.id },
          data: {
            quantity: { increment: dto.quantity ?? 1 },
            specialRequest: dto.specialRequest ?? undefined,
            updatedAt: new Date(),
          },
        });
      } else {
        try {
          await tx.cartItem.create({
            data: {
              cartId: cart.id,
              productId: finalProductId,
              variantId: dto.variantId ?? null,
              customName,
              customPrice,
              customImageUrl,
              quantity: dto.quantity ?? 1,
              selectedUnit,
              specialRequest: dto.specialRequest ?? null,
              optionHash: optionHash ?? '',
              selectedOptions: {
                create: (dto.optionIds ?? []).map((optionId) => ({
                  optionId,
                })),
              },
            },
          });
        } catch (e: any) {
          // Lost a concurrent insert race against the merge unique index:
          // the other request created the line, so merge into it instead.
          if (
            e instanceof Prisma.PrismaClientKnownRequestError &&
            e.code === 'P2002'
          ) {
            const winner = finalProductId
              ? await tx.cartItem.findFirst({
                  where: {
                    cartId: cart.id,
                    productId: finalProductId,
                    variantId: dto.variantId ?? null,
                    optionHash: optionHash ?? '',
                    selectedUnit,
                    customPrice: customPrice ?? null,
                  },
                })
              : await tx.cartItem.findFirst({
                  where: {
                    cartId: cart.id,
                    productId: null,
                    customName,
                    customPrice: customPrice ?? null,
                  },
                });
            if (winner) {
              await tx.cartItem.update({
                where: { id: winner.id },
                data: {
                  quantity: { increment: dto.quantity ?? 1 },
                  specialRequest: dto.specialRequest ?? undefined,
                  updatedAt: new Date(),
                },
              });
            } else {
              throw e;
            }
          } else {
            throw e;
          }
        }
      }
    });

    return this.getCart(userId, vendorId);
  }

  // ─── Update cart item ─────────────────────────────────────────────────────

  async updateItem(
    userId: string,
    vendorId: string,
    cartItemId: string,
    dto: UpdateCartItemDto,
  ) {
    const customer = await this.getCustomer(userId);
    const cartItem = await this.assertCartItemOwnership(
      customer.id,
      vendorId,
      cartItemId,
    );

    // updateItem previously wrote quantity/options/unit with zero validation.
    // Re-resolve the catalog row (vendor-scoped, active-only) and validate
    // the resulting option set exactly like addItem does.
    if (cartItem.productId) {
      const product = await this.prisma.product.findFirst({
        where: {
          id: cartItem.productId,
          vendorId,
          isActive: true,
          deletedAt: null,
        },
        include: {
          variants: {
            where: { isActive: true },
            include: {
              optionGroups: {
                include: { options: { where: { isActive: true } } },
              },
            },
          },
          optionGroups: {
            include: { options: { where: { isActive: true } } },
          },
        },
      });
      if (!product)
        throw new BadRequestException(CartErrors.PRODUCT_UNAVAILABLE);

      const mergedOptionIds =
        dto.optionIds !== undefined
          ? dto.optionIds
          : (
              await this.prisma.cartItemOption.findMany({
                where: { cartItemId },
                select: { optionId: true },
              })
            ).map((o) => o.optionId);

      this.validateOptions(
        product as CartProduct,
        mergedOptionIds,
        cartItem.variantId ?? undefined,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      const newOptionHash =
        dto.optionIds !== undefined
          ? dto.optionIds.length
            ? createHash('sha256')
                .update(
                  (cartItem.variantId ?? '') +
                    [...dto.optionIds].sort().join(','),
                )
                .digest('hex')
            : null
          : cartItem.optionHash;

      await tx.cartItem.update({
        where: { id: cartItemId },
        data: {
          quantity: dto.quantity,
          selectedUnit: dto.selectedUnit ?? cartItem.selectedUnit,
          specialRequest: dto.specialRequest ?? cartItem.specialRequest,
          optionHash: newOptionHash ?? '',
          updatedAt: new Date(),
        },
      });

      if (dto.optionIds !== undefined) {
        // Replace all options
        await tx.cartItemOption.deleteMany({ where: { cartItemId } });

        if (dto.optionIds.length) {
          await tx.cartItemOption.createMany({
            data: dto.optionIds.map((optionId) => ({ cartItemId, optionId })),
          });
        }
      }

      await tx.cart.update({
        where: { id: cartItem.cartId },
        data: { updatedAt: new Date() },
      });
    });

    return this.getCart(userId, vendorId);
  }

  // ─── Remove cart item ─────────────────────────────────────────────────────

  async removeItem(userId: string, vendorId: string, cartItemId: string) {
    const customer = await this.getCustomer(userId);
    const cartItem = await this.assertCartItemOwnership(
      customer.id,
      vendorId,
      cartItemId,
    );

    await this.prisma.cartItem.delete({ where: { id: cartItemId } });

    // If cart is now empty, delete it
    const remaining = await this.prisma.cartItem.count({
      where: { cartId: cartItem.cartId },
    });

    if (remaining === 0) {
      await this.prisma.cart.delete({ where: { id: cartItem.cartId } });
      return { cleared: true };
    }

    return this.getCart(userId, vendorId);
  }

  // ─── Clear entire cart ────────────────────────────────────────────────────

  async clearCart(userId: string, vendorId: string) {
    const customer = await this.getCustomer(userId);

    await this.prisma.cart.deleteMany({
      where: { customerId: customer.id, vendorId },
    });

    return { cleared: true };
  }

  // ─── Validate and snapshot cart for checkout ──────────────────────────────
  // Called by OrdersService — returns validated line items with current prices

  async validateForCheckout(userId: string, vendorId: string) {
    const customer = await this.getCustomer(userId);

    if (!customer.canOrder) {
      throw new ForbiddenException(CustomerErrors.CANNOT_ORDER);
    }

    const cart = await this.prisma.cart.findUnique({
      where: { customerId_vendorId: { customerId: customer.id, vendorId } },
      include: this.cartIncludes(),
    });

    if (!cart || cart.items.length === 0) {
      throw new BadRequestException(CartErrors.IS_EMPTY);
    }

    const formatted = this.formatCart(cart);

    const variantQuantities = new Map<string, number>();
    const productQuantities = new Map<string, number>();

    // First pass: aggregate quantities
    for (const item of formatted.items) {
      if (item.variantId) {
        variantQuantities.set(
          item.variantId,
          (variantQuantities.get(item.variantId) ?? 0) + item.quantity,
        );
      } else if (item.productId) {
        productQuantities.set(
          item.productId,
          (productQuantities.get(item.productId) ?? 0) + item.quantity,
        );
      }
    }

    // Second pass: Validate existence, active status, and aggregated stock.
    // Option groups are re-resolved fresh (batched) so deactivated options,
    // changed group rules, or a product that gained variants after add all
    // fail closed here — the single point where correctness is mandatory.
    const checkoutProductIds = [
      ...new Set(
        formatted.items
          .map((item) => item.productId)
          .filter((id): id is string => !!id),
      ),
    ];
    const checkoutProducts =
      checkoutProductIds.length > 0
        ? await this.prisma.product.findMany({
            where: { id: { in: checkoutProductIds } },
            include: {
              variants: {
                where: { isActive: true },
                include: {
                  optionGroups: {
                    include: { options: { where: { isActive: true } } },
                  },
                },
              },
              optionGroups: {
                include: { options: { where: { isActive: true } } },
              },
            },
          })
        : [];
    const checkoutProductById = new Map(
      checkoutProducts.map((p) => [p.id, p as CartProduct]),
    );

    for (const item of formatted.items) {
      if (!item.product || !item.product.isActive) {
        throw new BadRequestException(CartErrors.PRODUCT_UNAVAILABLE);
      }
      if (item.variantId && !item.variant?.isActive) {
        throw new BadRequestException(CartErrors.VARIANT_UNAVAILABLE);
      }

      if (item.productId) {
        const catalogProduct = checkoutProductById.get(item.productId);
        if (!catalogProduct) {
          throw new BadRequestException(CartErrors.PRODUCT_UNAVAILABLE);
        }
        if (!item.variantId && catalogProduct.hasVariants) {
          throw new BadRequestException(
            OrderErrors.VARIANT_SELECTION_REQUIRED,
          );
        }
        this.validateOptions(
          catalogProduct,
          item.options.map((o) => o.id),
          item.variantId ?? undefined,
        );
      }

      if (item.variantId) {
        const variantQty = variantQuantities.get(item.variantId) ?? 0;
        if (item.variant?.tracksStock && item.variant.stock != null) {
          if (item.variant.stock < variantQty) {
            throw new BadRequestException(CartErrors.NOT_ENOUGH_STOCK);
          }
        }
      } else {
        const productQty = productQuantities.get(item.productId!) ?? 0;
        if (item.product.tracksStock && item.product.stock != null) {
          const stripsPerPackage =
            item.selectedUnit === 'strip' &&
            item.product.sellByStrip === true &&
            Number(item.product.stripsPerPackage ?? 0) > 0
              ? Number(item.product.stripsPerPackage)
              : 1;
          const effectiveStock = item.product.stock * stripsPerPackage;
          if (effectiveStock < productQty) {
            throw new BadRequestException(CartErrors.NOT_ENOUGH_STOCK);
          }
        }
      }
    }

    return {
      customerId: customer.id,
      coinBalance: customer.coinBalance,
      cart: formatted,
    };
  }

  /**
   * A product is branch-available when it is either marked ALL or has an
   * explicit availability row for the branch that will fulfil the order.
   * Checkout resolves that branch from the delivery location, so this check
   * must run after branch resolution rather than inside cart validation.
   */
  async assertItemsAvailableAtBranch(
    items: Array<{ productId?: string | null }>,
    branchId: string,
  ) {
    const productIds = [
      ...new Set(
        items
          .map((item) => item.productId)
          .filter((id): id is string => Boolean(id)),
      ),
    ];
    if (productIds.length === 0) return;

    const unavailable = await this.prisma.product.findMany({
      where: {
        id: { in: productIds },
        OR: [
          {
            branchAvailabilityMode: ProductBranchAvailabilityMode.SPECIFIC,
            branchAvailability: { none: { branchId } },
          },
          {
            category: {
              branchAvailabilityMode: ProductBranchAvailabilityMode.SPECIFIC,
              branchAvailability: { none: { branchId } },
            },
          },
        ],
      },
      select: { id: true, name: true },
    });

    if (unavailable.length > 0) {
      throw new BadRequestException(
        OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private async getCustomer(userId: string) {
    const customer = await this.prisma.customer.findUnique({
      where: { userId },
      select: { id: true, canOrder: true, coinBalance: true },
    });

    if (!customer) {
      // Auto-create customer profile
      return this.prisma.customer.create({
        data: { userId },
        select: { id: true, canOrder: true, coinBalance: true },
      });
    }

    return customer;
  }

  private async assertCartItemOwnership(
    customerId: string,
    vendorId: string,
    cartItemId: string,
  ) {
    const cart = await this.prisma.cart.findUnique({
      where: { customerId_vendorId: { customerId, vendorId } },
      select: { id: true },
    });

    if (!cart) throw new NotFoundException(CartErrors.NOT_FOUND);

    const cartItem = await this.prisma.cartItem.findFirst({
      where: { id: cartItemId, cartId: cart.id },
    });

    if (!cartItem) throw new NotFoundException(CartErrors.ITEM_NOT_FOUND);
    return cartItem;
  }

  private validateOptions(
    product: CartProduct,
    optionIds: string[],
    variantId?: string,
  ) {
    // Collect all valid option IDs for this product/variant
    const groups = variantId
      ? (product.variants.find((v) => v.id === variantId)?.optionGroups ?? [])
      : product.optionGroups;

    const validOptionIds = new Set<string>(
      groups.flatMap((g) => g.options.map((o) => o.id)),
    );

    for (const id of optionIds) {
      if (!validOptionIds.has(id)) {
        throw new BadRequestException(CartErrors.INVALID_OPTION);
      }
    }

    this.validateOptionGroups(groups, optionIds);
  }

  /**
   * Per-group cardinality gate: required groups must have at least
   * max(1 when required, minSelect) picks, no group may exceed maxSelect.
   * Runs on raw option IDs so add/update/checkout share one rule.
   */
  private validateOptionGroups(
    groups: Array<{
      id: string;
      isRequired: boolean;
      minSelect: number;
      maxSelect: number;
      options: Array<{ id: string }>;
    }>,
    optionIds: string[],
  ) {
    const picked = new Set(optionIds);
    // Duplicate IDs in one request count once (checkbox semantics).
    const picksByGroup = new Map<string, number>();
    const groupByOptionId = new Map<string, string>();
    for (const g of groups) {
      picksByGroup.set(g.id, 0);
      for (const o of g.options) groupByOptionId.set(o.id, g.id);
    }
    for (const id of picked) {
      const groupId = groupByOptionId.get(id);
      if (groupId) picksByGroup.set(groupId, picksByGroup.get(groupId)! + 1);
    }

    for (const g of groups) {
      const count = picksByGroup.get(g.id) ?? 0;
      const minimum = g.isRequired ? Math.max(1, g.minSelect) : g.minSelect;
      if (count < minimum) {
        throw new BadRequestException(CartErrors.REQUIRED_OPTION_MISSING);
      }
      if (count > g.maxSelect) {
        throw new BadRequestException(CartErrors.TOO_MANY_OPTIONS);
      }
    }
  }

  private cartIncludes() {
    return {
      items: {
        orderBy: { createdAt: 'asc' as const },
        include: {
          product: {
            select: {
              id: true,
              name: true,
              nameAr: true,
              imageUrl: true,
              basePrice: true,
              comparePrice: true,
              sellByStrip: true,
              stripsPerPackage: true,
              isActive: true,
              hasVariants: true,
              stock: true,
              tracksStock: true,
              offers: {
                where: { isActive: true },
                select: {
                  id: true,
                  variantId: true,
                  offerPrice: true,
                  originalPrice: true,
                  isActive: true,
                  startDate: true,
                  endDate: true,
                },
              },
            },
          },
          variant: {
            select: {
              id: true,
              name: true,
              nameAr: true,
              basePrice: true,
              comparePrice: true,
              isActive: true,
              stock: true,
              tracksStock: true,
            },
          },
          selectedOptions: {
            include: {
              option: {
                select: {
                  id: true,
                  name: true,
                  nameAr: true,
                  priceAdded: true,
                  group: { select: { id: true, name: true } },
                },
              },
            },
          },
        },
      },
      vendor: {
        select: {
          id: true,
          storeName: true,
          storeNameAr: true,
          logo: true,
          coverImage: true,
          status: true,
          commissionRate: true,
          isContracted: true,
        },
      },
    };
  }

  private formatCart(cartRaw: unknown) {
    const cart = cartRaw as CartInclude;
    let subtotal = 0;
    const now = new Date();

    const items = cart.items.map((item) => {
      const activeOffers = (item.product?.offers || []).filter((o) => {
        if (!o.isActive) return false;
        if (o.startDate && new Date(o.startDate) > now) return false;
        if (o.endDate && new Date(o.endDate) < now) return false;
        return true;
      });

      const productActiveOffer = activeOffers.find((o) => !o.variantId);

      const discountRatio =
        productActiveOffer &&
        productActiveOffer.originalPrice &&
        Number(productActiveOffer.originalPrice) >
          Number(productActiveOffer.offerPrice)
          ? (Number(productActiveOffer.originalPrice) -
              Number(productActiveOffer.offerPrice)) /
            Number(productActiveOffer.originalPrice)
          : 0;

      let basePrice = 0;
      let originalBasePrice = 0;

      if (item.customPrice !== null) {
        basePrice = Number(item.customPrice);
        originalBasePrice = basePrice;
      } else if (item.variant) {
        const vBase = Number(item.variant.basePrice || 0);
        const vCompare = (item.variant as any).comparePrice
          ? Number((item.variant as any).comparePrice)
          : null;
        const vOriginal = vCompare && vCompare > vBase ? vCompare : vBase;

        // Check if an active offer specifically targets this variant
        const variantOffer = activeOffers.find(
          (o) => o.variantId === item.variantId,
        );

        if (variantOffer) {
          basePrice = Number(variantOffer.offerPrice);
          originalBasePrice = variantOffer.originalPrice
            ? Number(variantOffer.originalPrice)
            : vOriginal;
        } else if (discountRatio > 0) {
          basePrice = Math.max(0, Math.round(vOriginal * (1 - discountRatio)));
          originalBasePrice = vOriginal;
        } else if (vCompare && vCompare > vBase) {
          basePrice = vBase;
          originalBasePrice = vCompare;
        } else {
          basePrice = vBase;
          originalBasePrice = vBase;
        }
      } else if (item.product) {
        const pBase = Number(item.product.basePrice ?? 0);
        const pCompare = item.product.comparePrice
          ? Number(item.product.comparePrice)
          : null;

        if (productActiveOffer) {
          basePrice = Number(productActiveOffer.offerPrice);
          originalBasePrice = productActiveOffer.originalPrice
            ? Number(productActiveOffer.originalPrice)
            : pCompare && pCompare > basePrice
              ? pCompare
              : pBase;
        } else if (pCompare && pCompare > pBase) {
          basePrice = pBase;
          originalBasePrice = pCompare;
        } else {
          basePrice = pBase;
          originalBasePrice = pBase;
        }
      }

      // When the customer selected "strip", the package price (and compare
      // price) is divided by the strips per package so totals reflect the
      // actual per-strip rate.
      const sellByStrip =
        item.selectedUnit === 'strip' &&
        item.product?.sellByStrip === true &&
        Number(item.product?.stripsPerPackage ?? 0) > 0;
      const stripDivider = sellByStrip
        ? Number(item.product?.stripsPerPackage)
        : 1;

      const optionsTotal = item.selectedOptions.reduce(
        (sum, so) => sum + Number(so.option.priceAdded),
        0,
      );

      const unitPrice = basePrice / stripDivider + optionsTotal;
      const compareUnitPrice =
        originalBasePrice > basePrice
          ? originalBasePrice / stripDivider + optionsTotal
          : null;
      const totalPrice = unitPrice * item.quantity;

      subtotal += totalPrice;

      const resolvedVariant = item.variant
        ? {
            ...item.variant,
            price: basePrice,
            comparePrice:
              originalBasePrice > basePrice ? originalBasePrice : null,
          }
        : null;

      // Ensure item.product is never null (e.g. for custom negotiated items from chat)
      const resolvedProduct = item.product
        ? {
            ...item.product,
            comparePrice: compareUnitPrice,
          }
        : {
            id: item.productId ?? item.id,
            name: item.customName ?? 'Custom Item',
            nameAr: item.customName ?? 'طلب مخصص',
            imageUrl: item.customImageUrl,
            basePrice: item.customPrice ?? 0,
            comparePrice: null,
            isActive: true,
            hasVariants: false,
            stock: null,
            tracksStock: false,
            offers: [],
          };

      return {
        id: item.id,
        productId: item.productId,
        variantId: item.variantId,
        product: resolvedProduct,
        variant: resolvedVariant,
        options: item.selectedOptions.map((so) => ({
        ...so.option,
        groupName: so.option.group?.name ?? null,
      })),
        quantity: item.quantity,
        selectedUnit: item.selectedUnit,
        specialRequest: item.specialRequest,
        customName: item.customName,
        customPrice: item.customPrice,
        customImageUrl: item.customImageUrl,
        unitPrice,
        totalPrice,
      };
    });

    const isContracted = cart.vendor?.isContracted ?? false;
    const commissionRate = Number(cart.vendor?.commissionRate ?? 10);
    const serviceFee = !isContracted
      ? Math.round(subtotal * (commissionRate / 100))
      : 0;

    return {
      id: cart.id,
      vendorId: cart.vendorId,
      vendor: cart.vendor,
      items,
      subtotal: Math.round(subtotal * 100) / 100,
      serviceFee,
      itemCount: items.reduce((sum, i) => sum + i.quantity, 0),
    };
  }

  private buildEmptyCart(vendorId: string) {
    return {
      id: null,
      vendorId,
      vendor: null,
      items: [],
      subtotal: 0,
      serviceFee: 0,
      itemCount: 0,
    };
  }
  async rebuildCartFromOrder(order: any) {
    const customerId = order.customerId;
    const vendorId = order.vendorId;

    if (!vendorId) return;

    const items = order.items || order.orderItems || [];

    await this.prisma.$transaction(async (tx) => {
      const cart = await tx.cart.upsert({
        where: { customerId_vendorId: { customerId, vendorId } },
        create: { customerId, vendorId },
        update: { updatedAt: new Date() },
      });

      for (const item of items) {
        const optionIds = (item.selectedOptions || [])
          .map((so: any) => so.optionId)
          .filter(Boolean)
          .sort();
        const optionHash = createHash('md5')
          .update(optionIds.join(','))
          .digest('hex');

        await tx.cartItem.create({
          data: {
            cartId: cart.id,
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
            specialRequest: item.specialRequest,
            optionHash,
            selectedOptions: {
              create: (item.selectedOptions || [])
                .filter((so: any) => so.optionId)
                .map((so: any) => ({
                  optionId: so.optionId,
                })),
            },
          },
        });
      }
    });
  }
}
