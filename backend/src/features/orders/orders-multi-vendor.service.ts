import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { randomUUID } from 'crypto';
import { OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CartService } from '../cart/cart.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrdersCheckoutService } from './orders-checkout.service';
import { OrdersRepository, OrderItemData } from './orders.repository';
import {
  OrderGroupingService,
  VendorStop,
  GroupingResult,
} from './order-grouping.service';
import { CustomerErrors } from '../../common/constants/response.constants';
import { OrderErrors } from '../../common/constants/response.constants';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { EVENTS } from '../../common/events/event-names';
import { OrderCreatedEvent } from '../../common/events';

export interface PlaceMultiVendorOrderDto {
  /** 2+ vendors; a single vendor should use the existing POST /orders. */
  vendorIds: string[];
  paymentMethod: string;
  deliveryAddress: string;
  deliveryLocation: [number, number];
  specialRequest?: string;
  coinsToUse?: number;
}

export interface MultiVendorFeeBreakdown {
  /** Sequence the customer sees. */
  sequence: number;
  vendorIds: string[];
  vendorNames: string[];
  deliveryFee: number;
  /** Straight-line distance of the group's farthest pickup to the customer. */
  distanceKm: number;
  /** Vendors beyond the first (each adds half the minimum delivery fee). */
  extraVendors: number;
  splitReason: string;
}

/**
 * Multi-vendor checkout.
 *
 * One customer checkout → exactly ONE `Order` (one charge, one idempotency
 * key) plus:
 *   - one `OrderVendorFulfillment` per vendor (independently fulfillable), and
 *   - one `OrderDeliveryGroup` per planned route (each may have its own driver).
 *
 * Single-vendor / custom-delivery / ride behaviour is untouched: those still go
 * through OrdersCheckoutService.
 */
@Injectable()
export class OrdersMultiVendorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cartService: CartService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly checkoutService: OrdersCheckoutService,
    private readonly ordersRepository: OrdersRepository,
    private readonly grouping: OrderGroupingService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // ─── Fee estimate ─────────────────────────────────────────────────────────

  /**
   * Price a multi-vendor checkout without writing anything, so the customer
   * sees the real per-delivery breakdown before committing.
   */
  async estimate(actor: JwtAccessPayload, dto: PlaceMultiVendorOrderDto) {
    const vendorIds = this.normaliseVendorIds(dto.vendorIds);
    const plan = await this.buildPlan(actor, vendorIds, dto);

    return {
      subtotal: plan.subtotal,
      deliveryFee: plan.deliveryFee,
      serviceFee: plan.serviceFee,
      tax: plan.tax,
      coinsUsed: plan.coinsUsed,
      discount: plan.discount,
      coinsEarned: plan.coinsEarned,
      grandTotal: plan.grandTotal,
      upfrontAmount: plan.upfrontAmount,
      isSplit: plan.grouping.isSplit,
      vendorCount: plan.portions.length,
      deliveryCount: plan.grouping.groups.length,
      groups: plan.grouping.groups.map((g) => ({
        sequence: g.sequence,
        vendorIds: g.stops.map((s) => s.vendorId),
        deliveryFee: this.feeFor(plan, g.farthestToCustomerKm, g.sequence - 1),
        distanceKm: this.round2(g.farthestToCustomerKm),
        extraVendors: g.extraVendorCount,
        splitReason: g.splitReason,
      })),
    };
  }

  // ─── Place ────────────────────────────────────────────────────────────────

  /**
   * Create the single customer order with its vendor portions and delivery
   * groups. All writes happen in one transaction; a failure leaves nothing
   * behind (no orphan order, no partial stock movement, no double charge).
   */
  async placeOrder(
    actor: JwtAccessPayload,
    dto: PlaceMultiVendorOrderDto,
    idempotencyKey?: string,
  ) {
    const vendorIds = this.normaliseVendorIds(dto.vendorIds);
    const clientOrderKey = idempotencyKey?.trim() || null;
    const plan = await this.buildPlan(actor, vendorIds, dto);

    // Same fast-path gate as single-vendor checkout. The authoritative re-check
    // runs inside the transaction below (under the per-customer advisory lock),
    // so two racing checkouts cannot both pass.
    const activeOrderPolicy = await this.checkoutService.validateActiveOrderLimit(
      plan.customerId,
    );

    const orderId = randomUUID();
    const orderNumber = await this.ordersRepository.generateOrderNumber();

    const created = await this.prisma.$transaction(async (tx) => {
      // Idempotency: the same clientOrderKey can never create a second order.
      if (clientOrderKey) {
        const existing = await tx.order.findUnique({
          where: { clientOrderKey },
          select: { id: true, orderNumber: true, customerId: true },
        });
        if (existing) {
          if (existing.customerId !== plan.customerId) {
            throw new BadRequestException(OrderErrors.NOT_AUTHORIZED_VIEW);
          }
          return {
            id: existing.id,
            orderNumber: existing.orderNumber,
            created: false,
          };
        }
      }

      // Serialize concurrent checkouts for the same customer, then re-check the
      // active-order policy against committed rows. Mirrors
      // OrdersRepository.createOrder so the multi-vendor path cannot bypass it.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('order-place:' || ${plan.customerId}::text))`;
      const liveActiveCount = await tx.order.count({
        where: {
          customerId: plan.customerId,
          status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
        },
      });
      if (
        liveActiveCount > 0 &&
        liveActiveCount >= activeOrderPolicy.maxActive
      ) {
        throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
      }
      if (activeOrderPolicy.requirePriorDelivery && liveActiveCount > 0) {
        const hasCompletedOrder = await tx.order.findFirst({
          where: {
            customerId: plan.customerId,
            status: OrderStatus.DELIVERED,
          },
          select: { id: true },
        });
        if (!hasCompletedOrder) {
          throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
        }
      }

      // Re-validate vendor status inside the transaction (mirrors the
      // single-vendor path: never trust the estimate-time snapshot).
      for (const portion of plan.portions) {
        const vendor = await tx.vendor.findUnique({
          where: { id: portion.vendorId },
          select: { status: true, deletedAt: true },
        });
        if (!vendor || vendor.deletedAt || vendor.status !== 'OPEN') {
          throw new BadRequestException(OrderErrors.VENDOR_NOT_ACCEPTING);
        }
      }

      await tx.$executeRaw`
        INSERT INTO orders (
          id, "orderNumber", "clientOrderKey", type, "customerId", "vendorId",
          "vendorBranchId", "zoneId", status, "paymentMethod", "paymentStatus",
          "deliveryAddress", "deliveryLocation",
          subtotal, "deliveryFee", "driverBonusFee", "serviceFee", tax,
          discount, "coinsUsed", "coinsEarned", "grandTotal", "upfrontAmount",
          "specialRequest", "updatedAt"
        ) VALUES (
          ${orderId}, ${orderNumber}, ${clientOrderKey}, 'STANDARD'::"OrderType",
          ${plan.customerId}, NULL, NULL, ${plan.zoneId},
          'PENDING'::"OrderStatus", ${dto.paymentMethod}::"PaymentMethod",
          ${plan.grandTotal <= 0 ? 'PAID' : 'PENDING'}::"PaymentStatus",
          ${dto.deliveryAddress},
          ST_SetSRID(ST_MakePoint(${dto.deliveryLocation[0]}, ${dto.deliveryLocation[1]}), 4326),
          ${plan.subtotal}, ${plan.deliveryFee}, ${plan.driverBonusFee},
          ${plan.serviceFee}, ${plan.tax}, ${plan.discount},
          ${plan.coinsUsed}, ${plan.coinsEarned}, ${plan.grandTotal}, ${plan.upfrontAmount},
          ${dto.specialRequest ?? null}, NOW()
        )
        ON CONFLICT ("clientOrderKey") DO NOTHING
      `;

      if (clientOrderKey) {
        const inserted = await tx.order.findUnique({
          where: { clientOrderKey },
          select: { id: true, orderNumber: true },
        });
        if (!inserted || inserted.id !== orderId) {
          // A concurrent duplicate won the race: return the row that exists
          // rather than the id we generated but never inserted.
          return {
            id: inserted?.id ?? orderId,
            orderNumber: inserted?.orderNumber ?? orderNumber,
            created: false,
          };
        }
      }

      // Coins are money: deduct them inside the same transaction as the order
      // insert and write the SPENT ledger row, exactly like the single-vendor
      // path. Without this the discount was granted but the balance was never
      // touched, so coins could be spent repeatedly.
      if (plan.coinsUsed > 0) {
        const result = await tx.customer.updateMany({
          where: {
            id: plan.customerId,
            coinBalance: { gte: plan.coinsUsed },
          },
          data: { coinBalance: { decrement: plan.coinsUsed } },
        });
        if (result.count === 0) {
          throw new BadRequestException(
            CustomerErrors.INSUFFICIENT_COIN_BALANCE,
          );
        }
        const customer = await tx.customer.findUnique({
          where: { id: plan.customerId },
          select: { coinBalance: true },
        });
        await tx.customerCoinTransaction.create({
          data: {
            customerId: plan.customerId,
            orderId,
            type: 'SPENT',
            amount: plan.coinsUsed,
            balanceAfter: customer!.coinBalance,
            description: `Used coins for order ${orderNumber}`,
          },
        });
      }

      // Vendor portions — the independently fulfillable units.
      const fulfillmentIds = new Map<string, string>();
      for (const portion of plan.portions) {
        const fulfillmentId = randomUUID();
        fulfillmentIds.set(portion.vendorId, fulfillmentId);

        await tx.orderVendorFulfillment.create({
          data: {
            id: fulfillmentId,
            orderId,
            vendorId: portion.vendorId,
            vendorBranchId: portion.vendorBranchId,
            status: 'PENDING',
            subtotal: portion.subtotal,
            // Capture the rate now so a later vendor edit cannot change
            // settlement of an order that is already placed.
            commissionRate: portion.commissionRate,
          },
        });
      }

      // Items carry their owning portion (null keeps legacy rows compatible).
      for (const portion of plan.portions) {
        const fulfillmentId = fulfillmentIds.get(portion.vendorId)!;

        // Allocate an id per item up-front so its options can be attached
        // deterministically (createMany does not preserve/return input order).
        const itemRows = portion.items.map((item) => ({
          ...item,
          id: randomUUID(),
        }));

        await tx.orderItem.createMany({
          data: itemRows.map((item) => ({
            id: item.id,
            orderId,
            fulfillmentId,
            productId: item.productId,
            variantId: item.variantId,
            productName: item.productName,
            variantName: item.variantName,
            unitPrice: Math.round(item.unitPrice),
            quantity: item.quantity,
            selectedUnit: item.selectedUnit,
            baseUnitPrice: Math.round(item.baseUnitPrice),
            totalPrice: Math.round(item.totalPrice),
            specialRequest: item.specialRequest,
          })),
        });

        const options = itemRows.flatMap((item) =>
          item.options.map((o) => ({
            id: randomUUID(),
            orderItemId: item.id,
            optionId: o.optionId,
            optionName: o.optionName,
            groupName: o.groupName,
            priceAdded: Math.round(o.priceAdded),
          })),
        );
        if (options.length > 0) {
          await tx.orderItemOption.createMany({ data: options });
        }
      }

      // Reserved stock must move exactly like the single-vendor path, so a
      // later per-portion rejection's `restoreStock` cannot inflate inventory.
      await this.decrementStock(
        tx,
        plan.portions.flatMap((p) => p.items),
      );

      // Delivery groups — one per planned route, each with its own fee.
      for (const group of plan.grouping.groups) {
        const groupId = randomUUID();
        await tx.orderDeliveryGroup.create({
          data: {
            id: groupId,
            orderId,
            sequence: group.sequence,
            status: 'PENDING',
            distanceKm: this.round2(group.farthestToCustomerKm),
            deliveryFee: this.feeFor(
              plan,
              group.farthestToCustomerKm,
              group.sequence - 1,
            ),
          },
        });

        await tx.orderDeliveryGroupItem.createMany({
          data: group.stops.map((stop, index) => ({
            deliveryGroupId: groupId,
            fulfillmentId: fulfillmentIds.get(stop.vendorId)!,
            sequence: index + 1,
          })),
        });
      }

      await tx.orderStatusEvent.create({
        data: { orderId, status: 'PENDING', createdBy: actor.sub },
      });

      return { id: orderId, orderNumber, created: true };
    });

    if (created.created) {
      // Carts for all vendors are cleared, matching the single-vendor listener.
      await Promise.all(
        vendorIds.map((vendorId) =>
          this.cartService.clearCart(actor.sub, vendorId),
        ),
      );

      // Notify every vendor's staff that a new order is waiting for their
      // portion decision. Without this the multi-vendor checkout emitted no
      // ORDER_CREATED at all, so vendors were never told a portion existed.
      const vendorUserIds = Array.from(
        new Set(
          (
            await Promise.all(
              vendorIds.map((vendorId) =>
                this.ordersRepository.getVendorUserIds(vendorId),
              ),
            )
          ).flat(),
        ),
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_CREATED,
        new OrderCreatedEvent(
          created.id,
          created.orderNumber,
          plan.customerId,
          actor.sub,
          null,
          vendorUserIds,
          plan.grandTotal,
          dto.paymentMethod,
          'STANDARD',
        ),
      );
    }

    return this.ordersRepository.findById(created.id);
  }

  // ─── Stock ────────────────────────────────────────────────────────────────

  /**
   * Batched, guarded stock decrement mirroring OrdersRepository.createOrder:
   * quantities are aggregated per distinct id, strip lines consume whole
   * packages, and a guarded `UPDATE` throws on a concurrent sell-out.
   */
  private async decrementStock(
    tx: Prisma.TransactionClient,
    items: {
      productId: string | null;
      variantId: string | null;
      quantity: number;
      selectedUnit: string | null;
    }[],
  ): Promise<void> {
    const aggregatedVariantQty = new Map<string, number>();
    const aggregatedProductQty = new Map<string, number>();

    for (const item of items) {
      if (item.quantity <= 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
      if (item.variantId) {
        aggregatedVariantQty.set(
          item.variantId,
          (aggregatedVariantQty.get(item.variantId) ?? 0) + item.quantity,
        );
      } else if (item.productId) {
        aggregatedProductQty.set(item.productId, 0);
      }
    }

    const variantIds = [...aggregatedVariantQty.keys()].sort();
    const trackedVariants = variantIds.length
      ? await tx.productVariant.findMany({
          where: { id: { in: variantIds } },
          select: { id: true, tracksStock: true },
        })
      : [];
    const trackedVariantIds = new Set(
      trackedVariants.filter((v) => v.tracksStock).map((v) => v.id),
    );

    for (const [variantId, qty] of aggregatedVariantQty) {
      if (!trackedVariantIds.has(variantId)) continue;
      const rows = await tx.$executeRaw`
        UPDATE product_variants
        SET stock = stock - ${qty}
        WHERE id = ${variantId}
          AND stock IS NOT NULL
          AND stock >= ${qty}
      `;
      if (rows === 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
    }

    const productIds = [...aggregatedProductQty.keys()].sort();
    const trackedProducts = productIds.length
      ? await tx.product.findMany({
          where: { id: { in: productIds } },
          select: {
            id: true,
            tracksStock: true,
            sellByStrip: true,
            stripsPerPackage: true,
          },
        })
      : [];
    const stripDividerById = new Map(
      trackedProducts
        .filter((p) => p.tracksStock)
        .map((p) => [
          p.id,
          p.sellByStrip === true && Number(p.stripsPerPackage ?? 0) > 0
            ? Number(p.stripsPerPackage)
            : 1,
        ]),
    );

    const aggregatedStripQty = new Map<string, number>();
    for (const item of items) {
      if (!item.productId || item.variantId) continue;
      if (item.selectedUnit === 'strip') {
        aggregatedStripQty.set(
          item.productId,
          (aggregatedStripQty.get(item.productId) ?? 0) + item.quantity,
        );
      } else {
        aggregatedProductQty.set(
          item.productId,
          (aggregatedProductQty.get(item.productId) ?? 0) + item.quantity,
        );
      }
    }
    for (const [productId, stripQty] of aggregatedStripQty) {
      const divider = stripDividerById.get(productId) ?? 1;
      const packages = Math.ceil(stripQty / divider);
      aggregatedProductQty.set(
        productId,
        (aggregatedProductQty.get(productId) ?? 0) + packages,
      );
    }

    for (const [productId, qty] of aggregatedProductQty) {
      if (qty <= 0 || !stripDividerById.has(productId)) continue;
      const rows = await tx.$executeRaw`
        UPDATE products
        SET stock = stock - ${qty}
        WHERE id = ${productId}
          AND stock IS NOT NULL
          AND stock >= ${qty}
      `;
      if (rows === 0) {
        throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
      }
    }
  }

  // ─── Planning ─────────────────────────────────────────────────────────────

  private async buildPlan(
    actor: JwtAccessPayload,
    vendorIds: string[],
    dto: PlaceMultiVendorOrderDto,
  ) {
    const settings = await this.platformSettings.getSettings();
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, coinBalance: true },
    });
    if (!customer) {
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    }

    const zone = await this.ordersRepository.getZoneAtLocation(
      dto.deliveryLocation[0],
      dto.deliveryLocation[1],
    );
    if (!zone) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const portions: Array<{
      vendorId: string;
      vendorBranchId: string | null;
      commissionRate: number;
      subtotal: number;
      items: OrderItemData[];
      stop: VendorStop;
    }> = [];

    for (const vendorId of vendorIds) {
      const { cart } = await this.cartService.validateForCheckout(
        actor.sub,
        vendorId,
      );
      if (!cart || cart.items.length === 0) {
        throw new BadRequestException(OrderErrors.EMPTY_CART_FOR_VENDOR);
      }

      const vendor = await this.prisma.vendor.findUnique({
        where: { id: vendorId },
        select: {
          id: true,
          status: true,
          commissionRate: true,
          isContracted: true,
          deletedAt: true,
        },
      });
      if (!vendor || vendor.deletedAt || vendor.status !== 'OPEN') {
        throw new BadRequestException(OrderErrors.VENDOR_NOT_ACCEPTING);
      }

      const productIds = [
        ...new Set(
          cart.items
            .map((item: any) => item.productId)
            .filter((id: string | null): id is string => Boolean(id)),
        ),
      ];
      const branch = await this.ordersRepository.getNearestOpenBranchLocation(
        vendorId,
        dto.deliveryLocation[0],
        dto.deliveryLocation[1],
        zone.id,
        productIds,
      );
      // Every vendor portion needs an open branch inside the zone that can
      // fulfil all of that vendor's cart lines.
      if (!branch) {
        if (productIds.length > 0) {
          const anyOpenBranch =
            await this.ordersRepository.getNearestOpenBranchLocation(
              vendorId,
              dto.deliveryLocation[0],
              dto.deliveryLocation[1],
              zone.id,
            );
          if (anyOpenBranch) {
            throw new BadRequestException(
              OrderErrors.PRODUCT_NOT_AVAILABLE_AT_BRANCH,
            );
          }
        }
        throw new BadRequestException(OrderErrors.NO_OPEN_BRANCH);
      }

      await this.cartService.assertItemsAvailableAtBranch(cart.items, branch.id);

      portions.push({
        vendorId,
        vendorBranchId: branch.id,
        commissionRate:
          branch.commissionRate ??
          vendor.commissionRate ??
          settings.defaultCommissionRate ??
          10,
        subtotal: cart.subtotal,
        items: cart.items.map((i: any) => ({
          productId: i.productId ?? null,
          variantId: i.variantId ?? null,
          productName: i.product?.name ?? 'Unknown Product',
          variantName: i.variant?.name ?? null,
          unitPrice: Math.round(i.unitPrice),
          quantity: i.quantity,
          selectedUnit: i.selectedUnit,
          baseUnitPrice:
            Math.round(i.unitPrice) -
            (i.selectedOptions ?? []).reduce(
              (s: number, o: any) => s + Math.round(Number(o.priceAdded)),
              0,
            ),
          totalPrice: Math.round(i.totalPrice),
          specialRequest: i.specialRequest ?? null,
          options: (i.selectedOptions ?? []).map((o: any) => ({
            optionId: o.id,
            optionName: o.name,
            groupName: o.groupName ?? null,
            priceAdded: Math.round(Number(o.priceAdded)),
          })),
        })),
        stop: {
          vendorId,
          vendorBranchId: branch.id,
          lng: branch.lng,
          lat: branch.lat,
        },
      });
    }

    const grouping: GroupingResult = await this.grouping.planForCheckout(
      portions.map((p) => p.stop),
      { lng: dto.deliveryLocation[0], lat: dto.deliveryLocation[1] },
    );
    if (grouping.groups.length === 0) {
      throw new BadRequestException(OrderErrors.NO_DELIVERY_GROUPS);
    }

    const subtotal = portions.reduce((s, p) => s + p.subtotal, 0);
    const minOrder = Number(settings.minOrderAmount);
    if (minOrder > 0 && subtotal < minOrder) {
      throw new BadRequestException(OrderErrors.MIN_ORDER_AMOUNT_NOT_MET);
    }

    // Per-group fee: the group's farthest pickup to the customer (the long leg,
    // which the customer pays for), plus the fixed extra delivery fee for every
    // extra vendor sharing that same trip. Groups are then summed.
    const extraVendorFee = Number(
      settings.extraVendorDeliveryFee ?? Math.round(Number(settings.minDeliveryFee ?? 0) / 2),
    );
    const groupFees: number[] = [];
    for (const g of grouping.groups) {
      const base = await this.platformSettings.calculateDeliveryFee(
        g.farthestToCustomerKm,
        zone.baseDeliveryFeeOverride ?? null,
        null,
        true,
        settings,
      );
      groupFees.push(Math.round(base + g.extraVendorCount * extraVendorFee));
    }
    const deliveryFee = groupFees.reduce((a, b) => a + b, 0);

    const serviceFee = await this.serviceFeeFor(portions, settings);

    const driverBonusFee =
      settings.driverBonusActive && settings.driverBonusPaidByCustomer
        ? Number(settings.driverBonusAmount ?? 0)
        : 0;

    const tax = Math.round(
      (subtotal + serviceFee) * (Number(settings.defaultTaxRate) / 100),
    );

    let discount = 0;
    let coinsUsed = 0;
    const coinsToUse = dto.coinsToUse ?? 0;
    if (coinsToUse > 0) {
      const balance = Number(customer.coinBalance ?? 0);
      const minCoins = Number(settings.minCoinsToUse ?? 1);
      if (!balance || balance < minCoins) {
        throw new BadRequestException(CustomerErrors.MINIMUM_COINS_REQUIRED);
      }
      if (balance < coinsToUse) {
        throw new BadRequestException(CustomerErrors.INSUFFICIENT_COIN_BALANCE);
      }
      coinsUsed = coinsToUse;
      discount = coinsToUse * (Number(settings.coinValue) || 1);
    }

    // Coins apply to the whole bill (products + delivery + fees + tax), not
    // just the products. When the requested coins exceed the bill, cap the
    // discount at the total and only consume the coins actually needed —
    // mirroring the single-vendor/custom checkout rule.
    const preDiscount =
      subtotal + deliveryFee + serviceFee + tax + driverBonusFee;
    if (discount > preDiscount) {
      discount = preDiscount;
      const coinValue = Number(settings.coinValue) || 1;
      coinsUsed = Math.ceil(discount / coinValue);
    }
    const grandTotal = Math.max(0, preDiscount - discount);
    const coinsEarned =
      Number(settings.amountSpentPerCoin) > 0
        ? Math.floor(grandTotal / Number(settings.amountSpentPerCoin))
        : 0;

    // High-value cash-on-delivery orders require the same upfront deposit as
    // the single-vendor path. It was hardcoded to 0 here, so multi-vendor
    // high-value orders silently skipped the deposit.
    let upfrontAmount = 0;
    if (
      dto.paymentMethod === 'CASH_ON_DELIVERY' &&
      Number(settings.highValueOrderThreshold ?? 0) > 0 &&
      grandTotal >= Number(settings.highValueOrderThreshold)
    ) {
      upfrontAmount = Math.round(
        grandTotal * (Number(settings.highValueUpfrontRate ?? 0) / 100),
      );
    }

    return {
      customerId: customer.id,
      zoneId: zone.id,
      portions,
      grouping,
      groupFees,
      subtotal,
      deliveryFee,
      serviceFee,
      tax,
      discount,
      coinsUsed,
      coinsEarned,
      grandTotal,
      upfrontAmount,
      driverBonusFee,
    };
  }

  private async serviceFeeFor(
    portions: Array<{ vendorId: string; vendorBranchId?: string | null; subtotal: number }>,
    settings: any,
  ): Promise<number> {
    // Mirrors the single-vendor rule: uncontracted vendors pay commission as a
    // service fee; contracted vendors do not.
    const vendors = await this.prisma.vendor.findMany({
      where: { id: { in: portions.map((p) => p.vendorId) } },
      select: { id: true, isContracted: true, commissionRate: true },
    });
    const branchIds = portions
      .map((p) => p.vendorBranchId)
      .filter((id): id is string => Boolean(id));

    const branches = branchIds.length > 0
      ? await this.prisma.vendorBranch.findMany({
          where: { id: { in: branchIds } },
          select: { id: true, isContracted: true, commissionRate: true },
        })
      : [];

    const byId = new Map(vendors.map((v) => [v.id, v]));
    const branchMap = new Map(branches.map((b) => [b.id, b]));

    return portions.reduce((sum, p) => {
      const v = byId.get(p.vendorId);
      const b = p.vendorBranchId ? branchMap.get(p.vendorBranchId) : null;
      const isContracted =
        b?.isContracted != null ? b.isContracted : (v?.isContracted ?? false);
      if (isContracted) return sum;
      const rate = Number(
        b?.commissionRate ??
          v?.commissionRate ??
          settings.defaultCommissionRate ??
          10,
      );
      return sum + Math.round(p.subtotal * (rate / 100));
    }, 0);
  }

  private feeFor(
    plan: { groupFees: number[] },
    _distanceKm: number,
    index: number,
  ): number {
    return plan.groupFees[index] ?? 0;
  }

  private round2(n: number): number {
    return Math.round(n * 100) / 100;
  }

  private normaliseVendorIds(ids: string[]): string[] {
    const unique = Array.from(new Set((ids ?? []).filter(Boolean)));
    if (unique.length < 2) {
      throw new BadRequestException(OrderErrors.MULTI_VENDOR_NOT_ALLOWED);
    }
    return unique;
  }
}
