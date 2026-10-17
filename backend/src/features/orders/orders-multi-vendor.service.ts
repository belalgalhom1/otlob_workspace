import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { randomUUID } from 'crypto';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CartService } from '../cart/cart.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { OrdersRepository, OrderItemData } from './orders.repository';
import {
  OrderGroupingService,
  VendorStop,
  GroupingResult,
} from './order-grouping.service';
import { CustomerErrors } from '../../common/constants/response.constants';
import { OrderErrors } from '../../common/constants/response.constants';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';

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
  distanceKm: number;
  routeKm: number;
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
  private readonly logger = new Logger(OrdersMultiVendorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cartService: CartService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly ordersRepository: OrdersRepository,
    private readonly grouping: OrderGroupingService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // ─── Fee estimate ─────────────────────────────────────────────────────────

  /**
   * Price a multi-vendor checkout without writing anything, so the customer
   * sees the real per-delivery breakdown before committing.
   */
  async estimate(
    actor: JwtAccessPayload,
    dto: PlaceMultiVendorOrderDto,
  ) {
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
        deliveryFee: this.feeFor(plan, g.firstPickupToCustomerKm, g.sequence - 1),
        distanceKm: this.round2(g.firstPickupToCustomerKm),
        routeKm: this.round2(g.routeKm),
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
          return { id: existing.id, orderNumber: existing.orderNumber, created: false };
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
          ${plan.grandTotal <= 0 ? 'PAID'::"PaymentStatus" : 'PENDING'::"PaymentStatus"},
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
          return { id: orderId, orderNumber, created: false };
        }
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
        await tx.orderItem.createMany({
          data: portion.items.map((item) => ({
            id: randomUUID(),
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

        const options = portion.items.flatMap((item) =>
          item.options.map((o) => ({
            id: randomUUID(),
            orderItemId: '',
            optionId: o.optionId,
            optionName: o.optionName,
            groupName: o.groupName,
            priceAdded: Math.round(o.priceAdded),
          })),
        );
        if (options.length > 0) {
          const createdItems = await tx.orderItem.findMany({
            where: { orderId, fulfillmentId },
            select: { id: true },
            orderBy: { createdAt: 'asc' },
          });
          options.forEach((o, i) => {
            o.orderItemId = createdItems[i]?.id ?? createdItems[0].id;
          });
          await tx.orderItemOption.createMany({ data: options });
        }
      }

      // Delivery groups — one per planned route, each with its own fee.
      for (const group of plan.grouping.groups) {
        const groupId = randomUUID();
        await tx.orderDeliveryGroup.create({
          data: {
            id: groupId,
            orderId,
            sequence: group.sequence,
            status: 'PENDING',
            distanceKm: this.round2(group.routeKm),
            deliveryFee: this.feeFor(plan, group.firstPickupToCustomerKm, group.sequence - 1),
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
    }

    return this.ordersRepository.findById(created.id);
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
        select: { id: true, status: true, commissionRate: true, isContracted: true, deletedAt: true },
      });
      if (!vendor || vendor.deletedAt || vendor.status !== 'OPEN') {
        throw new BadRequestException(OrderErrors.VENDOR_NOT_ACCEPTING);
      }

      const branch = await this.ordersRepository.getNearestOpenBranchLocation(
        vendorId,
        dto.deliveryLocation[0],
        dto.deliveryLocation[1],
        zone.id,
      );

      portions.push({
        vendorId,
        vendorBranchId: branch?.id ?? null,
        commissionRate: vendor.commissionRate ?? settings.defaultCommissionRate ?? 10,
        subtotal: cart.subtotal,
        items: cart.items.map((i: any) => ({
          productId: i.productId ?? null,
          variantId: i.variantId ?? null,
          productName: i.product?.name ?? 'Unknown Product',
          variantName: i.variant?.name ?? null,
          unitPrice: Math.round(i.unitPrice),
          quantity: i.quantity,
          selectedUnit: i.selectedUnit,
          baseUnitPrice: Math.round(i.unitPrice) - (i.selectedOptions ?? []).reduce((s: number, o: any) => s + Math.round(Number(o.priceAdded)), 0),
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
          vendorBranchId: branch?.id ?? null,
          // No open branch → fall back to the customer point, exactly like the
          // single-vendor path uses fallbackOrderDistanceKm.
          lng: branch?.lng ?? dto.deliveryLocation[0],
          lat: branch?.lat ?? dto.deliveryLocation[1],
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

    // Per-group fee, each floored by the platform minimum, then summed.
    const groupFees = grouping.groups.map((g) =>
      Math.round(
        await this.platformSettings.calculateDeliveryFee(
          g.firstPickupToCustomerKm,
          zone.baseDeliveryFeeOverride ?? null,
          null,
          true,
          settings,
        ),
      ),
    );
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

    const preDiscount = subtotal + deliveryFee + serviceFee + tax + driverBonusFee;
    if (discount > preDiscount) discount = preDiscount;
    const grandTotal = Math.max(0, preDiscount - discount);
    const coinsEarned =
      Number(settings.amountSpentPerCoin) > 0
        ? Math.floor(grandTotal / Number(settings.amountSpentPerCoin))
        : 0;

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
      upfrontAmount: 0,
      driverBonusFee,
    };
  }

  private async serviceFeeFor(
    portions: Array<{ vendorId: string; subtotal: number }>,
    settings: any,
  ): Promise<number> {
    // Mirrors the single-vendor rule: uncontracted vendors pay commission as a
    // service fee; contracted vendors do not.
    const vendors = await this.prisma.vendor.findMany({
      where: { id: { in: portions.map((p) => p.vendorId) } },
      select: { id: true, isContracted: true, commissionRate: true },
    });
    const byId = new Map(vendors.map((v) => [v.id, v]));

    return portions.reduce((sum, p) => {
      const v = byId.get(p.vendorId);
      if (!v || v.isContracted) return sum;
      const rate = Number(v.commissionRate ?? settings.defaultCommissionRate ?? 10);
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