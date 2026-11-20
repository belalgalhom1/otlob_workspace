import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { randomUUID } from 'crypto';
import { OrderStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CartService } from '../cart/cart.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PlaceOrderDto } from './dto/order.dto';
import { OrdersRepository, OrderItemData } from './orders.repository';
import { StockService } from './helpers/stock.service';
import { OrderActivePolicyHelper } from './helpers/order-active-policy.helper';
import { BranchAllocatorHelper } from './helpers/branch-allocator.helper';
import {
  OrderGroupingService,
  VendorStop,
  GroupingResult,
  haversineKm,
} from './order-grouping.service';
import { CustomerErrors } from '../../common/constants/response.constants';
import { OrderErrors } from '../../common/constants/response.constants';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { EVENTS } from '../../common/events/event-names';
import { OrderCreatedEvent } from '../../common/events';
import {
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
} from './helpers/order-actor.helper';

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
  private readonly logger = new Logger(OrdersMultiVendorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cartService: CartService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly activePolicyOrMock: OrderActivePolicyHelper,
    private readonly ordersRepository: OrdersRepository,
    private readonly grouping: OrderGroupingService,
    private readonly eventEmitter: EventEmitter2,
    private readonly outbox: OutboxService,
    @Optional() private readonly stockService?: StockService,
    @Optional() private readonly branchAllocatorHelper?: BranchAllocatorHelper,
  ) {}

  private get stock(): StockService {
    return this.stockService ?? new StockService();
  }

  private get activePolicy(): OrderActivePolicyHelper {
    if (
      this.activePolicyOrMock &&
      typeof (this.activePolicyOrMock as any).validateActiveOrderLimit ===
        'function'
    ) {
      return this.activePolicyOrMock;
    }
    return new OrderActivePolicyHelper(this.prisma, this.platformSettings);
  }

  private get branchAllocator(): BranchAllocatorHelper {
    return (
      this.branchAllocatorHelper ??
      new BranchAllocatorHelper(this.ordersRepository, this.cartService)
    );
  }

  // ─── Fee estimate ─────────────────────────────────────────────────────────

  /**
   * Price a multi-vendor checkout without writing anything, so the customer
   * sees the real per-delivery breakdown before committing.
   */
  async estimate(actor: JwtAccessPayload, dto: PlaceMultiVendorOrderDto) {
    const vendorIds = this.normaliseVendorIds(dto.vendorIds);
    const plan = await this.buildPlan(actor, vendorIds, dto);
    return this.formatEstimate(plan);
  }

  /**
   * Price a single-vendor order whose items span 2+ open branches.
   */
  async estimateSingleVendorMultiBranch(
    actor: JwtAccessPayload,
    dto: PlaceOrderDto,
  ) {
    const plan = await this.buildPlan(
      actor,
      [dto.vendorId],
      this.toMultiVendorDto(dto),
    );
    return this.formatEstimate(plan);
  }

  private formatEstimate(plan: Awaited<ReturnType<OrdersMultiVendorService['buildPlan']>>) {
    const uniqueVendorCount = new Set(plan.portions.map((p) => p.vendorId)).size;
    const distanceKm = this.round2(
      Math.max(
        0,
        ...plan.grouping.groups.map((g) => g.farthestToCustomerKm),
      ),
    );

    return {
      subtotal: plan.subtotal,
      distanceKm,
      deliveryFee: plan.deliveryFee,
      serviceFee: plan.serviceFee,
      driverBonusFee: plan.driverBonusFee,
      driverBonusPaidByCustomer: Boolean(plan.driverBonusPaidByCustomer),
      tax: plan.tax,
      coinsUsed: plan.coinsUsed,
      discount: plan.discount,
      coinsEarned: plan.coinsEarned,
      grandTotal: plan.grandTotal,
      upfrontAmount: plan.upfrontAmount,
      isSplit: plan.grouping.isSplit,
      vendorCount: uniqueVendorCount,
      branchCount: plan.portions.length,
      deliveryCount: plan.grouping.groups.length,
      groups: plan.grouping.groups.map((g) => ({
        sequence: g.sequence,
        vendorIds: g.stops.map((s) => s.vendorId),
        vendorBranchIds: g.stops
          .map((s) => s.vendorBranchId)
          .filter((id): id is string => Boolean(id)),
        deliveryFee: this.feeFor(plan, g.farthestToCustomerKm, g.sequence - 1),
        distanceKm: this.round2(g.farthestToCustomerKm),
        extraVendors: g.extraVendorCount,
        splitReason: g.splitReason,
      })),
    };
  }

  private toMultiVendorDto(dto: PlaceOrderDto): PlaceMultiVendorOrderDto {
    return {
      vendorIds: [dto.vendorId],
      paymentMethod: dto.paymentMethod,
      deliveryAddress: dto.deliveryAddress,
      deliveryLocation: dto.deliveryLocation,
      specialRequest: dto.specialRequest,
      coinsToUse: dto.coinsToUse,
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
    return this.executePlaceOrder(actor, vendorIds, dto, idempotencyKey);
  }

  /**
   * Place a single-vendor order whose items span 2+ open branches using the
   * fulfillment + delivery-group pipeline.
   */
  async placeSingleVendorMultiBranch(
    actor: JwtAccessPayload,
    dto: PlaceOrderDto,
    idempotencyKey?: string,
  ) {
    return this.executePlaceOrder(
      actor,
      [dto.vendorId],
      this.toMultiVendorDto(dto),
      idempotencyKey,
    );
  }

  private async executePlaceOrder(
    actor: JwtAccessPayload,
    vendorIds: string[],
    dto: PlaceMultiVendorOrderDto,
    idempotencyKey?: string,
  ) {
    const clientOrderKey = idempotencyKey?.trim() || null;

    if (clientOrderKey) {
      const existing = await this.ordersRepository.findByClientOrderKeyForUser(
        clientOrderKey,
        actor.sub,
      );
      if (existing) {
        this.logger.log(
          `Multi-vendor order checkout idempotent replay: ${existing.orderNumber ?? existing.id} by user ${actor.sub}`,
        );
        return existing;
      }
    }

    const plan = await this.buildPlan(actor, vendorIds, dto);

    // Same fast-path gate as single-vendor checkout. The authoritative re-check
    // runs inside the transaction below (under the per-customer advisory lock),
    // so two racing checkouts cannot both pass.
    const activeOrderPolicy = await this.activePolicy.validateActiveOrderLimit(
      plan.customerId,
    );

    const orderId = randomUUID();
    const orderNumber = await this.ordersRepository.generateOrderNumber();

    const vendorUserIds = Array.from(
      new Set(
        (
          await Promise.all(
            plan.portions.map((portion) =>
              this.ordersRepository.getVendorUserIds(
                portion.vendorId,
                portion.vendorBranchId,
              ),
            ),
          )
        ).flat(),
      ),
    );

    const created = await this.prisma.$transaction(async (tx) => {
      // Idempotency: the same clientOrderKey can never create a second order.
      if (clientOrderKey) {
        const existing = await tx.order.findUnique({
          where: { clientOrderKey },
          select: { id: true, orderNumber: true, customerId: true },
        });
        if (existing) {
          if (existing.customerId !== plan.customerId) {
            throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
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

      const orderDistanceKm = this.round2(
        Math.max(
          0,
          ...plan.grouping.groups.map((g) => g.farthestToCustomerKm),
        ),
      );

      await tx.$executeRaw`
        INSERT INTO orders (
          id, "orderNumber", "clientOrderKey", type, "customerId",
          "zoneId", status, "paymentMethod", "paymentStatus",
          "deliveryAddress", "deliveryLocation",
          subtotal, "deliveryFee", "driverBonusFee", "serviceFee", tax,
          discount, "coinsUsed", "coinsEarned", "grandTotal", "upfrontAmount",
          "specialRequest", "distanceKm", "updatedAt"
        ) VALUES (
          ${orderId}, ${orderNumber}, ${clientOrderKey}, 'STANDARD'::"OrderType",
          ${plan.customerId}, ${plan.zoneId},
          'PENDING'::"OrderStatus", ${dto.paymentMethod}::"PaymentMethod",
          ${plan.grandTotal <= 0 ? 'PAID' : 'PENDING'}::"PaymentStatus",
          ${dto.deliveryAddress},
          ST_SetSRID(ST_MakePoint(${plan.deliveryLng}, ${plan.deliveryLat}), 4326),
          ${plan.subtotal}, ${plan.deliveryFee}, ${plan.driverBonusFee},
          ${plan.serviceFee}, ${plan.tax}, ${plan.discount},
          ${plan.coinsUsed}, ${plan.coinsEarned}, ${plan.grandTotal}, ${plan.upfrontAmount},
          ${dto.specialRequest ?? null}, ${orderDistanceKm}, NOW()
        )
        ON CONFLICT ("clientOrderKey") DO NOTHING
      `;

      if (clientOrderKey) {
        const inserted = await tx.order.findUnique({
          where: { clientOrderKey },
          select: { id: true, orderNumber: true, customerId: true },
        });
        if (!inserted || inserted.id !== orderId) {
          if (inserted && inserted.customerId !== plan.customerId) {
            throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
          }
          // A concurrent duplicate won the race: return the row that exists
          // rather than the id we generated but never inserted.
          this.logger.log(
            `Multi-vendor order concurrent idempotent replay: ${inserted?.orderNumber ?? inserted?.id ?? orderId} by user ${actor.sub}`,
          );
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
      const stopKey = (vendorId: string, branchId?: string | null) =>
        `${vendorId}:${branchId ?? 'default'}`;
      const fulfillmentIds = new Map<string, string>();
      const plannedPortions = plan.portions.map((portion) => {
        const fulfillmentId = randomUUID();
        fulfillmentIds.set(
          stopKey(portion.vendorId, portion.vendorBranchId),
          fulfillmentId,
        );
        return { portion, fulfillmentId };
      });

      for (const { portion, fulfillmentId } of plannedPortions) {
        await tx.orderVendorFulfillment.create({
          data: {
            id: fulfillmentId,
            orderId,
            vendorId: portion.vendorId,
            vendorBranchId: portion.vendorBranchId,
            status: 'PENDING',
            subtotal: Math.round(portion.subtotal),
            // Capture the rate & contract state now so a later vendor edit cannot
            // change settlement of an order that is already placed.
            commissionRate: portion.commissionRate,
            isContracted: portion.isContracted,
          },
        });
      }

      // Items carry their owning portion (null keeps legacy rows compatible).
      for (const { portion, fulfillmentId } of plannedPortions) {

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
      // later per-portion rejection's restoration cannot inflate inventory.
      await this.stock.decrementForItems(
        tx,
        plan.portions.flatMap((p) => p.items),
      );

      // Delivery groups — one per planned route, each with its own fee.
      const singleVendorId = vendorIds.length === 1 ? vendorIds[0] : null;
      for (const [groupIndex, group] of plan.grouping.groups.entries()) {
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
            isPaymentCollector: groupIndex === 0,
          },
        });

        await tx.orderDeliveryGroupItem.createMany({
          data: group.stops.map((stop, index) => ({
            deliveryGroupId: groupId,
            fulfillmentId: fulfillmentIds.get(
              stopKey(stop.vendorId, stop.vendorBranchId),
            )!,
            sequence: index + 1,
          })),
        });
      }

      const placeActorSnapshot = await resolveOrderActorSnapshot(
        this.prisma,
        actor.sub,
        { orderId },
      );
      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        eventKey: `order_created:${orderId}`,
        status: 'PENDING',
        createdBy: actor.sub,
        actor: placeActorSnapshot,
      });

      await this.outbox.record(tx, {
        aggregateType: 'ORDER',
        aggregateId: orderId,
        version: 0,
        eventType: EVENTS.ORDER_CREATED,
        jobName: EVENT_JOBS.ORDER_CREATED,
        dedupeKey: `notify:order_created:${orderId}`,
        payload: {
          orderId,
          orderNumber,
          customerId: plan.customerId,
          customerUserId: actor.sub,
          actorUserId: actor.sub,
          vendorId: singleVendorId,
          vendorIds,
          vendorUserIds,
          grandTotal: plan.grandTotal,
          paymentMethod: dto.paymentMethod,
          orderType: 'STANDARD',
          revision: 0,
        },
      });

      return { id: orderId, orderNumber, created: true };
    });

    if (created.created) {
      // Notify every vendor's staff that a new order is waiting for their
      // portion decision.
      this.eventEmitter.emit(
        EVENTS.ORDER_CREATED,
        new OrderCreatedEvent(
          created.id,
          created.orderNumber,
          plan.customerId,
          actor.sub,
          vendorIds.length === 1 ? vendorIds[0] : null,
          vendorUserIds,
          plan.grandTotal,
          dto.paymentMethod,
          'STANDARD',
          0,
          vendorIds,
        ),
      );

      this.logger.log(
        `Multi-vendor order placed: ${created.orderNumber} (${plan.portions.length} portions, ${plan.grouping.groups.length} groups, ${vendorUserIds.length} vendor users) by user ${actor.sub}`,
      );

      // Carts for all vendors are cleared best-effort after emitting ORDER_CREATED,
      // matching the single-vendor checkout flow without blocking notifications.
      await Promise.allSettled(
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
    const maxStopsLimit = Number(settings.maxMultiVendorVendors ?? 5);
    if (
      Number.isFinite(maxStopsLimit) &&
      maxStopsLimit >= 1 &&
      vendorIds.length > maxStopsLimit
    ) {
      throw new BadRequestException(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);
    }
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, coinBalance: true },
    });
    if (!customer) {
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    }

    const deliveryLng = Number(dto.deliveryLocation?.[0]);
    const deliveryLat = Number(dto.deliveryLocation?.[1]);
    if (!Number.isFinite(deliveryLng) || !Number.isFinite(deliveryLat)) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const zone = await this.ordersRepository.getZoneAtLocation(
      deliveryLng,
      deliveryLat,
    );
    if (!zone) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const portions: Array<{
      vendorId: string;
      vendorBranchId: string | null;
      commissionRate: number;
      isContracted: boolean;
      subtotal: number;
      items: OrderItemData[];
      stop: VendorStop;
    }> = [];

    for (const vendorId of vendorIds) {
      const { cart } = await this.cartService.validateForCheckout(
        actor.sub,
        vendorId,
      );

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

      const branchPortions = await this.branchAllocator.allocateForVendorCart({
        vendorId,
        deliveryLng,
        deliveryLat,
        zoneId: zone.id,
        cart,
      });

      for (const allocated of branchPortions) {
        portions.push({
          vendorId,
          vendorBranchId: allocated.branch.id,
          commissionRate: Number(
            allocated.branch.commissionRate ??
              vendor.commissionRate ??
              settings.defaultCommissionRate ??
              10,
          ),
          isContracted: vendor.isContracted ?? false,
          subtotal: allocated.subtotal,
          items: this.mapCartItemsToOrderItems(allocated.items),
          stop: {
            vendorId,
            vendorBranchId: allocated.branch.id,
            lng: allocated.branch.lng,
            lat: allocated.branch.lat,
          },
        });
      }
    }

    const allocatedBranchIds = Array.from(
      new Set(
        portions
          .map((p) => p.vendorBranchId)
          .filter((id): id is string => Boolean(id)),
      ),
    );
    if (allocatedBranchIds.length > 0) {
      const branchOverrides = await this.prisma.vendorBranch.findMany({
        where: { id: { in: allocatedBranchIds } },
        select: { id: true, isContracted: true, commissionRate: true },
      });
      const branchOverrideMap = new Map(
        branchOverrides.map((b) => [b.id, b]),
      );
      for (const p of portions) {
        if (!p.vendorBranchId) continue;
        const b = branchOverrideMap.get(p.vendorBranchId);
        if (!b) continue;
        if (b.isContracted != null) {
          p.isContracted = b.isContracted;
        }
        if (b.commissionRate != null) {
          p.commissionRate = Number(b.commissionRate);
        }
      }
    }

    const uniqueVendorCount = new Set(portions.map((p) => p.vendorId)).size;
    const uniqueBranchCount = new Set(
      portions
        .map((p) => p.vendorBranchId)
        .filter((id): id is string => Boolean(id)),
    ).size;
    const effectiveStopCount = Math.max(
      uniqueVendorCount,
      uniqueBranchCount,
      portions.length,
    );
    if (
      Number.isFinite(maxStopsLimit) &&
      maxStopsLimit >= 1 &&
      effectiveStopCount > maxStopsLimit
    ) {
      throw new BadRequestException(OrderErrors.MULTI_VENDOR_LIMIT_EXCEEDED);
    }

    const grouping: GroupingResult = await this.grouping.planForCheckout(
      portions.map((p) => p.stop),
      { lng: deliveryLng, lat: deliveryLat },
    );
    if (grouping.groups.length === 0) {
      throw new BadRequestException(OrderErrors.NO_DELIVERY_GROUPS);
    }

    const maxRadius = Number(settings.maxDeliveryRadiusKm ?? 1500);
    if (
      maxRadius > 0 &&
      grouping.groups.some((g) => g.farthestToCustomerKm > maxRadius)
    ) {
      throw new BadRequestException(CustomerErrors.OUT_OF_DELIVERY_ZONES);
    }

    const subtotal = portions.reduce((s, p) => s + p.subtotal, 0);
    const minOrder = Number(
      zone.minOrderAmountOverride ?? settings.minOrderAmount,
    );
    if (minOrder > 0 && subtotal < minOrder) {
      throw new BadRequestException(OrderErrors.MIN_ORDER_AMOUNT_NOT_MET);
    }

    // Option 1: Calculate delivery fee based on each stop's distance to the customer.
    // When 2+ vendor stops share the same delivery trip (1 driver), their individual
    // distance fees are summed and discounted by multiVendorDeliveryDiscountPercent.
    // For single-stop trips (isolated or split deliveries), no bundle discount applies.
    const discountPercent = Number(
      (settings as any).multiVendorDeliveryDiscountPercent ?? 20,
    );
    const discountMultiplier =
      Math.max(0, Math.min(100, discountPercent)) / 100;
    const minFee = Number(settings.minDeliveryFee ?? 15);

    const groupFees: number[] = [];
    for (const g of grouping.groups) {
      if (g.stops.length <= 1) {
        const stop = g.stops[0];
        const dist = stop
          ? haversineKm(stop, { lng: deliveryLng, lat: deliveryLat })
          : g.farthestToCustomerKm;
        const base = await this.platformSettings.calculateDeliveryFee(
          dist,
          zone.baseDeliveryFeeOverride ?? null,
          null,
          true,
          settings,
        );
        groupFees.push(Math.round(base));
      } else {
        let rawSum = 0;
        for (const stop of g.stops) {
          const stopDist = haversineKm(stop, {
            lng: deliveryLng,
            lat: deliveryLat,
          });
          const stopFee = await this.platformSettings.calculateDeliveryFee(
            stopDist,
            zone.baseDeliveryFeeOverride ?? null,
            null,
            true,
            settings,
          );
          rawSum += stopFee;
        }
        const discounted = Math.round(rawSum * (1 - discountMultiplier));
        groupFees.push(Math.max(minFee, discounted));
      }
    }
    const deliveryFee = groupFees.reduce((a, b) => a + b, 0);

    const serviceFee = this.serviceFeeFor(portions);

    let driverBonusFee = 0;
    if (settings.driverBonusActive) {
      const now = new Date();
      const start = settings.driverBonusStartDate;
      const end = settings.driverBonusEndDate;
      if (
        (!start || now >= start) &&
        (!end || now <= end) &&
        Number(settings.driverBonusAmount ?? 0) > 0
      ) {
        driverBonusFee = Number(settings.driverBonusAmount ?? 0);
      }
    }
    const customerBonusFee = settings.driverBonusPaidByCustomer
      ? driverBonusFee
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
      subtotal + deliveryFee + serviceFee + tax + customerBonusFee;
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
      deliveryLng,
      deliveryLat,
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
      driverBonusPaidByCustomer: Boolean(settings.driverBonusPaidByCustomer),
    };
  }

  private serviceFeeFor(
    portions: Array<{
      subtotal: number;
      commissionRate: number;
      isContracted: boolean;
    }>,
  ): number {
    // Mirrors the single-vendor rule: uncontracted stores charge commission as
    // a service fee; contracted stores absorb commission from subtotal.
    return portions.reduce((sum, p) => {
      if (p.isContracted) return sum;
      return sum + Math.round(p.subtotal * (p.commissionRate / 100));
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

  private mapCartItemsToOrderItems(items: any[]): OrderItemData[] {
    return items.map((i: any) => {
      const rawOptions = i.options ?? i.selectedOptions ?? [];
      return {
        productId: i.productId ?? null,
        variantId: i.variantId ?? null,
        productName: i.product?.name ?? 'Unknown Product',
        variantName: i.variant?.name ?? null,
        unitPrice: Math.round(i.unitPrice),
        quantity: i.quantity,
        selectedUnit: i.selectedUnit,
        baseUnitPrice:
          Math.round(i.unitPrice) -
          rawOptions.reduce(
            (s: number, o: any) => s + Math.round(Number(o.priceAdded)),
            0,
          ),
        totalPrice: Math.round(i.totalPrice),
        specialRequest: i.specialRequest ?? null,
        options: rawOptions.map((o: any) => ({
          optionId: o.id ?? o.optionId,
          optionName: o.name ?? o.optionName,
          groupName: o.groupName ?? null,
          priceAdded: Math.round(Number(o.priceAdded)),
        })),
      };
    });
  }

  private normaliseVendorIds(ids: string[]): string[] {
    const unique = Array.from(new Set((ids ?? []).filter(Boolean)));
    if (unique.length < 2) {
      throw new BadRequestException(OrderErrors.MULTI_VENDOR_NOT_ALLOWED);
    }
    return unique;
  }
}
