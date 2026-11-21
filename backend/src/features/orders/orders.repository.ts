import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  Logger,
  Optional,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  OrderErrors,
  CustomerErrors,
} from '../../common/constants/response.constants';
import {
  DeliveryGroupStatus,
  DeliveryIncidentResponsibility,
  DeliveryIncidentType,
  DispatchStatus,
  DriverStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  Prisma,
} from '@prisma/client';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { EVENTS } from '../../common/events/event-names';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { StockService } from './helpers/stock.service';
import {
  OrderActorSnapshot,
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
  sanitizeCancelReason,
} from './helpers/order-actor.helper';
import { OrderGeoRepository } from './repositories/order-geo.repository';
import {
  ORDER_INCLUDE,
  OrderFilters,
  OrderQueriesRepository,
} from './repositories/order-queries.repository';

export { ORDER_INCLUDE } from './repositories/order-queries.repository';
export type { OrderFilters } from './repositories/order-queries.repository';

export interface CreateOrderData {
  orderNumber: string;
  clientOrderKey?: string | null;
  customerId: string;
  customerUserId?: string;
  vendorId: string | null;
  vendorBranchId: string | null;
  zoneId: string | null;
  paymentMethod: string;
  deliveryAddress: string;
  deliveryLng: number;
  deliveryLat: number;
  subtotal: number;
  deliveryFee: number;
  goldSurchargeAmount?: number;
  driverBonusFee: number;
  serviceFee: number;
  tax: number;
  discount?: number;
  coinsUsed?: number;
  coinsEarned?: number;
  grandTotal: number;
  upfrontAmount: number;
  specialRequest: string | null;
  type: string;
  distanceKm: number;
  pickupAddress: string | null;
  pickupLng: number | null;
  pickupLat: number | null;
  itemDetails: string | null;
  requestedVehicleType: string | null;
  isContracted?: boolean;
  commissionRate?: number;
  /**
   * Authoritative per-customer concurrency gate, enforced inside the create
   * transaction (the pre-tx check in checkout-service is only a fast path).
   * Omitted = no in-tx re-check (legacy callers).
   */
  activeOrderPolicy?: {
    maxActive: number;
    requirePriorDelivery: boolean;
  } | null;
}

export interface OrderItemData {
  productId: string | null;
  variantId: string | null;
  productName: string;
  variantName: string | null;
  unitPrice: number;
  quantity: number;
  selectedUnit: string | null;
  baseUnitPrice: number;
  totalPrice: number;
  specialRequest: string | null;
  options: Array<{
    optionId: string;
    optionName: string;
    groupName: string | null;
    priceAdded: number;
  }>;
}

@Injectable()
export class OrdersRepository {
  private readonly logger = new Logger(OrdersRepository.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly outbox: OutboxService,
    @Optional() private readonly stockService?: StockService,
    @Optional() private readonly queriesRepo?: OrderQueriesRepository,
    @Optional() private readonly geoRepo?: OrderGeoRepository,
    @Optional() private readonly driverWorkloadHelper?: DriverWorkloadHelper,
  ) {}

  private get stock(): StockService {
    return this.stockService ?? new StockService();
  }

  private get queries(): OrderQueriesRepository {
    return this.queriesRepo ?? new OrderQueriesRepository(this.prisma);
  }

  private get geo(): OrderGeoRepository {
    return this.geoRepo ?? new OrderGeoRepository(this.prisma);
  }

  private get driverWorkload(): DriverWorkloadHelper {
    return this.driverWorkloadHelper ?? new DriverWorkloadHelper();
  }

  findById(orderId: string) {
    return this.queries.findById(orderId);
  }

  findMany(filters: OrderFilters) {
    return this.queries.findMany(filters);
  }

  /**
   * Look up an already-created order by its client idempotency key.
   *
   * Used before checkout cart validation so a network retry whose original
   * request already cleared the cart still receives the original order instead
   * of failing with `cart.error.is_empty`.
   */
  async findByClientOrderKeyForUser(clientOrderKey: string, userId: string) {
    const existing = await this.prisma.order.findUnique({
      where: { clientOrderKey },
      select: {
        id: true,
        customer: { select: { userId: true } },
      },
    });
    if (!existing) return null;
    if (existing.customer.userId !== userId) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    }
    return this.findById(existing.id);
  }

  async createOrder(
    data: CreateOrderData,
    items: OrderItemData[],
    actorUserId: string,
  ) {
    // Application-level guard: monetary magnitudes are all unsigned. Since the
    // coin ledger (SPENT/REFUNDED) and payout math all derive from these order
    // fields, this keeps every wallet/coin amount non-negative by construction.
    if (
      data.subtotal < 0 ||
      data.deliveryFee < 0 ||
      data.driverBonusFee < 0 ||
      data.serviceFee < 0 ||
      data.tax < 0 ||
      (data.discount ?? 0) < 0 ||
      (data.coinsUsed ?? 0) < 0 ||
      (data.coinsEarned ?? 0) < 0 ||
      data.grandTotal < 0 ||
      data.upfrontAmount < 0
    ) {
      throw new BadRequestException(OrderErrors.INVALID_AMOUNT);
    }

    return this.prisma.$transaction(async (tx) => {
      // Serialize concurrent checkouts for the same customer: the pre-tx
      // limit check can pass twice for two racing requests. The advisory
      // xact lock (auto-released at commit) forces them sequential, and the
      // recount below then sees the first tx's committed row.
      if (data.activeOrderPolicy) {
        const { maxActive, requirePriorDelivery } = data.activeOrderPolicy;
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('order-place:' || ${data.customerId}::text))`;
        const liveActiveCount = await tx.order.count({
          where: {
            customerId: data.customerId,
            status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
          },
        });
        if (liveActiveCount > 0 && liveActiveCount >= maxActive) {
          throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
        }
        if (requirePriorDelivery && liveActiveCount > 0) {
          const hasCompletedOrder = await tx.order.findFirst({
            where: {
              customerId: data.customerId,
              status: OrderStatus.DELIVERED,
            },
            select: { id: true },
          });
          if (!hasCompletedOrder) {
            throw new BadRequestException(
              OrderErrors.MAX_ACTIVE_ORDERS_REACHED,
            );
          }
        }
      }

      // Re-validate the vendor inside the same tx: status/contract/commission
      // can flip between estimate and create (vendor closes, contract
      // toggles). Failing closed forces the client to re-estimate.
      let resolvedIsContracted = data.isContracted ?? false;
      let resolvedCommissionRate = data.commissionRate ?? 0;

      if (data.vendorId) {
        const liveVendor = await tx.vendor.findUnique({
          where: { id: data.vendorId },
          select: {
            status: true,
            isContracted: true,
            commissionRate: true,
          },
        });
        if (!liveVendor || liveVendor.status !== 'OPEN') {
          throw new BadRequestException(OrderErrors.VENDOR_NOT_ACCEPTING);
        }

        const liveBranch = data.vendorBranchId
          ? await tx.vendorBranch.findUnique({
              where: { id: data.vendorBranchId },
              select: { isContracted: true, commissionRate: true },
            })
          : null;

        if (data.isContracted === undefined) {
          resolvedIsContracted =
            liveBranch?.isContracted != null
              ? liveBranch.isContracted
              : liveVendor.isContracted;
        }
        if (data.commissionRate === undefined) {
          if (liveBranch?.commissionRate != null) {
            resolvedCommissionRate = Number(liveBranch.commissionRate);
          } else if (liveVendor.commissionRate != null) {
            resolvedCommissionRate = Number(liveVendor.commissionRate);
          } else {
            const settingsRow = await tx.platformSetting.findFirst({
              select: { defaultCommissionRate: true },
            });
            resolvedCommissionRate = Number(
              settingsRow?.defaultCommissionRate ?? 10,
            );
          }
        }
      }

      // Generate the UUID in-process so the INSERT can return it to the caller
      // without a second round-trip (the old flow re-read the row via
      // findFirst just to learn the id the database had generated).
      const orderId = randomUUID();

      // Raw SQL required for geometry field. ON CONFLICT (clientOrderKey) makes
      // creation idempotent: a re-submitted Idempotency-Key inserts 0 rows and
      // the existing order is returned instead of a duplicate.
      const inserted = await tx.$executeRaw`
        INSERT INTO orders (
          id, "orderNumber", "clientOrderKey", type, "customerId", "zoneId",
          status, "paymentMethod", "paymentStatus",
          "pickupAddress", "pickupLocation",
          "deliveryAddress", "deliveryLocation",
          subtotal, "deliveryFee", "goldSurchargeAmount", "driverBonusFee", "serviceFee", tax, discount, "coinsUsed", "coinsEarned", "grandTotal", "upfrontAmount",
          "itemDetails", "requestedVehicleType",
          "specialRequest", "distanceKm", "updatedAt"
        ) VALUES (
          ${orderId},
          ${data.orderNumber},
          ${data.clientOrderKey ?? null},
          ${data.type}::"OrderType",
          ${data.customerId},
          ${data.zoneId ?? null},
          ${Prisma.sql`'PENDING'::"OrderStatus"`},
          ${data.paymentMethod}::"PaymentMethod",
          ${data.grandTotal <= 0 ? Prisma.sql`'PAID'::"PaymentStatus"` : Prisma.sql`'PENDING'::"PaymentStatus"`},
          ${data.pickupAddress ?? null},
          ${
            data.pickupLng != null && data.pickupLat != null
              ? Prisma.sql`ST_SetSRID(ST_MakePoint(${data.pickupLng}, ${data.pickupLat}), 4326)`
              : Prisma.sql`NULL`
          },
          ${data.deliveryAddress},
          ST_SetSRID(ST_MakePoint(${data.deliveryLng}, ${data.deliveryLat}), 4326),
          ${Math.round(data.subtotal)},
          ${Math.round(data.deliveryFee)},
          ${Math.round(data.goldSurchargeAmount ?? 0)},
          ${Math.round(data.driverBonusFee)},
          ${Math.round(data.serviceFee)},
          ${Math.round(data.tax)},
          ${Math.round(data.discount ?? 0)},
          ${Math.round(data.coinsUsed ?? 0)},
          ${Math.round(data.coinsEarned ?? 0)},
          ${Math.round(data.grandTotal)},
          ${Math.round(data.upfrontAmount)},
          ${data.itemDetails ?? null},
          ${data.requestedVehicleType ? Prisma.sql`${data.requestedVehicleType}::"VehicleType"` : Prisma.sql`NULL`},
          ${data.specialRequest ?? null},
          ${data.distanceKm ?? null},
          NOW()
        )
        ON CONFLICT ("clientOrderKey") DO NOTHING
      `;

      if (inserted === 0) {
        // The caller re-used an Idempotency-Key that already created an order.
        // Clashing inserts serialize on the unique arbiter, so by the time this
        // INSERT resolves the winning row is committed and visible here. We
        // short-circuit coins/items/events and hand back the existing order.
        const existing = await tx.order.findUnique({
          where: { clientOrderKey: data.clientOrderKey! },
          select: { id: true, orderNumber: true, customerId: true },
        });
        if (!existing) {
          throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
        }
        if (existing.customerId !== data.customerId) {
          throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
        }
        return {
          id: existing.id,
          orderNumber: existing.orderNumber,
          created: false,
        };
      }

      const created = {
        id: orderId,
        orderNumber: data.orderNumber,
        created: true,
      };

      if (data.coinsUsed && data.coinsUsed > 0) {
        const result = await tx.customer.updateMany({
          where: { id: data.customerId, coinBalance: { gte: data.coinsUsed } },
          data: { coinBalance: { decrement: data.coinsUsed } },
        });

        if (result.count === 0) {
          throw new BadRequestException(
            CustomerErrors.INSUFFICIENT_COIN_BALANCE,
          );
        }

        // We need the new balance for the transaction record
        const customer = await tx.customer.findUnique({
          where: { id: data.customerId },
          select: { coinBalance: true },
        });

        await tx.customerCoinTransaction.create({
          data: {
            customerId: data.customerId,
            orderId: created.id,
            type: 'SPENT',
            amount: data.coinsUsed,
            balanceAfter: customer!.coinBalance,
            description: `Used coins for order ${data.orderNumber}`,
          },
        });
      }

      let singleFulfillmentId: string | null = null;
      if (data.type === 'STANDARD' && data.vendorId) {
        singleFulfillmentId = randomUUID();
        await tx.orderVendorFulfillment.create({
          data: {
            id: singleFulfillmentId,
            orderId: created.id,
            vendorId: data.vendorId,
            vendorBranchId: data.vendorBranchId ?? null,
            status: OrderVendorFulfillmentStatus.PENDING,
            subtotal: Math.round(data.subtotal),
            commissionRate: resolvedCommissionRate,
            isContracted: resolvedIsContracted,
          },
        });
      }

      const groupId = randomUUID();
      await tx.orderDeliveryGroup.create({
        data: {
          id: groupId,
          orderId: created.id,
          sequence: 1,
          status: DeliveryGroupStatus.PENDING,
          distanceKm: data.distanceKm,
          deliveryFee: Math.round(data.deliveryFee),
          goldSurchargeAmount: Math.round(data.goldSurchargeAmount ?? 0),
          isPaymentCollector: true,
        },
      });

      if (singleFulfillmentId) {
        await tx.orderDeliveryGroupItem.create({
          data: {
            deliveryGroupId: groupId,
            fulfillmentId: singleFulfillmentId,
            sequence: 1,
          },
        });
      }

      const orderItemsData: Prisma.OrderItemCreateManyInput[] = [];
      const orderItemOptionsData: Prisma.OrderItemOptionCreateManyInput[] = [];

      for (const item of items) {
        const orderItemId = randomUUID();
        orderItemsData.push({
          id: orderItemId,
          orderId: created.id,
          fulfillmentId: singleFulfillmentId,
          productId: item.productId,
          variantId: item.variantId,
          productName: item.productName,
          variantName: item.variantName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          selectedUnit: item.selectedUnit,
          baseUnitPrice: item.baseUnitPrice,
          totalPrice: item.totalPrice,
          specialRequest: item.specialRequest,
        });

        if (item.options.length > 0) {
          for (const opt of item.options) {
            orderItemOptionsData.push({
              orderItemId: orderItemId,
              optionId: opt.optionId,
              optionName: opt.optionName,
              groupName: opt.groupName,
              priceAdded: opt.priceAdded,
            });
          }
        }
      }

      if (orderItemsData.length > 0) {
        await tx.orderItem.createMany({ data: orderItemsData });
      }
      if (orderItemOptionsData.length > 0) {
        await tx.orderItemOption.createMany({ data: orderItemOptionsData });
      }

      // Aggregate stock decrements by distinct variant/product id. The old loop
      // issued 2 round-trips (pre-check read + guarded UPDATE) per line item;
      // with N cart lines that is O(2N) in the hot create-path. Following the
      // aggregation we only hit the database once per distinct tracked id.
      // Quantities are normalized to stock units first: strip lines consume
      // whole packages (ceil), because stock is tracked in packages.
      await this.stock.decrementForItems(tx, items);

      const actorSnapshot = await resolveOrderActorSnapshot(
        this.prisma,
        actorUserId,
        {
          orderId: created.id,
        },
      );
      await recordOrderStatusEventIdempotent(tx, {
        orderId: created.id,
        eventKey: `order_created:${created.id}`,
        status: OrderStatus.PENDING,
        createdBy: actorUserId,
        actor: actorSnapshot,
      });

      await this.outbox.record(tx, {
        aggregateType: 'ORDER',
        aggregateId: created.id,
        version: 0,
        eventType: EVENTS.ORDER_CREATED,
        jobName: EVENT_JOBS.ORDER_CREATED,
        dedupeKey: `notify:order_created:${created.id}`,
        payload: {
          orderId: created.id,
          orderNumber: created.orderNumber,
          customerId: data.customerId,
          customerUserId: data.customerUserId ?? actorUserId,
          actorUserId,
          vendorId: data.vendorId ?? null,
          vendorIds: data.vendorId ? [data.vendorId] : [],
          grandTotal: data.grandTotal,
          paymentMethod: data.paymentMethod,
          orderType: data.type,
          revision: 0,
        },
      });

      return created;
    });
  }

  async cancelOrder(
    orderId: string,
    actorUserId: string,
    reason: string,
    expectedOldStatus: OrderStatus,
    coinsUsed: number,
    customerId: string,
    orderNumber: string,
    driverIds: string[],
    actorMeta?: {
      actor?: OrderActorSnapshot | null;
      vendorId?: string | null;
      driverIncidents?: Array<{
        deliveryGroupId: string;
        driverId: string;
        responsibility: DeliveryIncidentResponsibility;
        reason?: string | null;
      }>;
    },
  ) {
    const cleanReason = sanitizeCancelReason(reason);
    const actorSnapshot =
      actorMeta?.actor ??
      (await resolveOrderActorSnapshot(this.prisma, actorUserId, {
        orderId,
        vendorId: actorMeta?.vendorId ?? null,
      }));
    const cancelledAt = new Date();

    // Revision written by THIS cancellation. Read inside the transaction so the
    // event carries the version this call produced even when another transition
    // commits before the post-commit aggregate read below.
    const written = { revision: null as number | null };

    await this.prisma.$transaction(async (tx) => {
      const updatedCount = await tx.order.updateMany({
        where: { id: orderId, status: expectedOldStatus },
        data: {
          status: OrderStatus.CANCELLED,
          revision: { increment: 1 },
          cancelledByUserId: actorSnapshot.actorUserId,
          cancelledByRole: actorSnapshot.actorRole,
          cancelledByName: actorSnapshot.actorName,
          cancelledByNameAr: actorSnapshot.actorNameAr,
          cancelledByAvatar: actorSnapshot.actorAvatar,
          cancelReason: cleanReason,
          cancelledAt,
        },
      });

      if (updatedCount.count === 0) {
        // Another process already transitioned this order. If it is already
        // cancelled this is an idempotent re-cancel and must NOT refund twice.
        const current = await tx.order.findUnique({
          where: { id: orderId },
          select: { status: true },
        });
        if (current?.status === OrderStatus.CANCELLED) {
          return;
        }
        throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
      }

      written.revision =
        (
          await tx.order.findUnique({
            where: { id: orderId },
            select: { revision: true },
          })
        )?.revision ?? null;

      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        eventKey: `order_cancelled:${orderId}`,
        status: OrderStatus.CANCELLED,
        note: cleanReason,
        createdBy: actorUserId,
        actor: actorSnapshot,
      });

      // Refund coins atomically with the status change so a crash or a retry
      // cannot leave the order cancelled without a refund, or refund it twice.
      // The customer row lock serializes concurrent cancels of different
      // orders for the same customer; the findFirst guard + unique ledger
      // key make retries idempotent.
      if (coinsUsed > 0) {
        await tx.$executeRaw`SELECT id FROM customers WHERE id = ${customerId} FOR UPDATE`;
        // A portion rejection may already have refunded part of the coins.
        // Refund only the remainder so partial rejection + cancellation never
        // pays the customer back twice (nor skips coins they are still owed).
        // The ledger has a unique (orderId, type) row, so the refund is a
        // single accumulating REFUNDED row rather than one row per event.
        const refunded = await tx.customerCoinTransaction.aggregate({
          where: { orderId, type: 'REFUNDED' },
          _sum: { amount: true },
        });
        const alreadyRefunded = Number(refunded._sum.amount ?? 0);
        const coinsToRefund = Math.max(0, coinsUsed - alreadyRefunded);
        if (coinsToRefund > 0) {
          const customer = await tx.customer.update({
            where: { id: customerId },
            data: { coinBalance: { increment: coinsToRefund } },
            select: { coinBalance: true },
          });
          // Accumulate into the single REFUNDED row (mirroring the rejection
          // path), so a prior partial refund and this full-cancel remainder
          // land on the same ledger entry instead of colliding on the unique
          // (orderId, type) key.
          await tx.customerCoinTransaction.upsert({
            where: { orderId_type: { orderId, type: 'REFUNDED' } },
            create: {
              customerId,
              orderId,
              type: 'REFUNDED',
              amount: coinsToRefund,
              balanceAfter: customer.coinBalance,
              description: `Refund for cancelled order ${orderNumber}`,
            },
            update: {
              amount: { increment: coinsToRefund },
              balanceAfter: customer.coinBalance,
            },
          });
        }
      }

      // Cancel every delivery that is not already finished, and cancel the
      // vendor portions that were still live. Without this a cancelled order
      // left live groups behind: their drivers stayed ON_DELIVERY and the
      // dispatch handoff could still fan out for a cancelled order.
      if (actorMeta?.driverIncidents && actorMeta.driverIncidents.length > 0) {
        await tx.driverDeliveryIncident.createMany({
          data: actorMeta.driverIncidents.map((inc) => ({
            orderId,
            deliveryGroupId: inc.deliveryGroupId,
            driverId: inc.driverId,
            incidentType: DeliveryIncidentType.ORDER_CANCELLED,
            responsibility: inc.responsibility,
            reason: inc.reason ?? cleanReason ?? null,
            reportedByUserId:
              actorUserId && actorUserId !== 'system' ? actorUserId : null,
            occurredAt: cancelledAt,
          })),
        });
      }

      await tx.orderDeliveryGroup.updateMany({
        where: {
          orderId,
          status: {
            notIn: [
              DeliveryGroupStatus.CANCELLED,
              DeliveryGroupStatus.DELIVERED,
            ],
          },
        },
        data: { status: DeliveryGroupStatus.CANCELLED },
      });
      await tx.orderVendorFulfillment.updateMany({
        where: {
          orderId,
          status: {
            in: [
              OrderVendorFulfillmentStatus.PENDING,
              OrderVendorFulfillmentStatus.ACCEPTED,
              OrderVendorFulfillmentStatus.PREPARING,
              OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
            ],
          },
        },
        data: { status: OrderVendorFulfillmentStatus.CANCELLED },
      });

      // Free every driver that was carrying this order — multi-vendor orders
      // hand their groups to different drivers (primary and assistant), and a
      // cancelled group must not leave any of them stuck ON_DELIVERY.
      for (const driverId of driverIds) {
        if (
          (await this.driverWorkload.countActiveUnits(
            tx,
            driverId,
            orderId,
          )) === 0
        ) {
          await tx.driver.update({
            where: { id: driverId },
            data: { status: DriverStatus.ONLINE },
          });
        }
      }

      // Restore stock consumed at checkout. Increments cannot fail (no guard
      // predicate), so this is safe inside the same transaction: a crash or
      // retry that re-runs cancel either restores once (first run) or no-ops
      // (idempotent early return above on already-CANCELLED).
      //
      // Rejected portions already had their stock restored when the vendor
      // rejected them, so those rows must be skipped here or the stock would
      // be credited twice.
      const cancelledItems = await tx.orderItem.findMany({
        where: { orderId, rejectedAt: null },
        select: {
          productId: true,
          variantId: true,
          quantity: true,
          selectedUnit: true,
        },
      });
      await this.stock.restoreForItems(tx, cancelledItems);

      // Always abort any active dispatch attempts
      await tx.orderDispatch.updateMany({
        where: { orderId, status: DispatchStatus.PENDING },
        data: { status: DispatchStatus.CANCELLED },
      });

      if (written.revision != null) {
        await this.outbox.record(tx, {
          aggregateType: 'ORDER',
          aggregateId: orderId,
          version: written.revision,
          eventType: EVENTS.ORDER_CANCELLED,
          jobName: EVENT_JOBS.ORDER_CANCELLED,
          dedupeKey: `notify:order_cancelled:${orderId}`,
          payload: {
            orderId,
            orderNumber,
            customerId,
            reason,
            cancelledByUserId: actorUserId,
            driverIds,
            revision: written.revision,
          },
        });
      }
    });

    // Read the response-shaped aggregate AFTER commit — the ORDER_INCLUDE tree
    // is read-only data and does not need to hold the transaction open.
    const updated = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });
    if (!updated) throw new Error(OrderErrors.NOT_FOUND);

    // Report the revision this call wrote, not one a concurrent transition may
    // have produced between commit and the aggregate read.
    if (written.revision != null) updated.revision = written.revision;

    return updated;
  }

  async updateStatus(
    orderId: string,
    status: OrderStatus,
    actorUserId: string,
    note?: string,
    extraData?: Prisma.OrderUpdateInput,
    expectedOldStatus?: OrderStatus,
    options?: {
      eventKey?: string | null;
      actor?: OrderActorSnapshot | null;
      skipStatusEvent?: boolean;
      fulfillmentId?: string | null;
      deliveryGroupId?: string | null;
    },
  ) {
    const actorSnapshot = options?.skipStatusEvent
      ? null
      : (options?.actor ??
        (await resolveOrderActorSnapshot(this.prisma, actorUserId, {
          orderId,
          fulfillmentId: options?.fulfillmentId ?? null,
        })));
    // Revision written by THIS transition. Captured inside the transaction so
    // the event identity can never collide with a transition that commits
    // between this commit and the post-commit aggregate read.
    const written = { revision: null as number | null };

    await this.prisma.$transaction(async (tx) => {
      if (expectedOldStatus) {
        const count = await tx.order.updateMany({
          where: { id: orderId, status: expectedOldStatus },
          data: { status, revision: { increment: 1 }, ...extraData },
        });
        if (count.count === 0) {
          throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
        }
      } else {
        await tx.order.update({
          where: { id: orderId },
          data: { status, revision: { increment: 1 }, ...extraData },
        });
      }

      written.revision =
        (
          await tx.order.findUnique({
            where: { id: orderId },
            select: { revision: true },
          })
        )?.revision ?? null;

      if (!options?.skipStatusEvent) {
        const eventKey =
          options?.eventKey ??
          (written.revision != null
            ? `order_status:${orderId}:${status}:rev_${written.revision}`
            : null);
        await recordOrderStatusEventIdempotent(tx, {
          orderId,
          fulfillmentId: options?.fulfillmentId ?? null,
          deliveryGroupId: options?.deliveryGroupId ?? null,
          eventKey,
          status,
          note: note ?? null,
          createdBy: actorUserId,
          actor: actorSnapshot,
        });
      }

      if (written.revision != null) {
        const orderRow = await tx.order.findUnique({
          where: { id: orderId },
          select: { orderNumber: true, customerId: true },
        });
        await this.outbox.record(tx, {
          aggregateType: 'ORDER',
          aggregateId: orderId,
          version: written.revision,
          eventType: EVENTS.ORDER_STATUS_CHANGED,
          jobName: EVENT_JOBS.ORDER_STATUS_CHANGED,
          dedupeKey: `notify:order_status:${orderId}:${written.revision}`,
          payload: {
            orderId,
            orderNumber: orderRow?.orderNumber ?? '',
            oldStatus: expectedOldStatus ?? null,
            newStatus: status,
            status,
            note: note ?? null,
            actorUserId,
            revision: written.revision,
          },
        });
      }
    });

    // Read the response-shaped aggregate AFTER commit. The write transaction
    // must stay tight; the ORDER_INCLUDE tree (11+ relations) is read-only
    // data that belongs outside the transaction. We also verify existence here
    // so a missing row surfaces the same NotFound as before.
    const updated = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });

    if (!updated) throw new Error(OrderErrors.NOT_FOUND);

    // Report the revision this call wrote, not one a concurrent transition may
    // have produced between commit and the aggregate read.
    if (written.revision != null) updated.revision = written.revision;

    return updated;
  }

  async assignDriver(
    orderId: string,
    driverId: string,
    driverShiftId: string | null,
    actorUserId: string,
    nextStatus: OrderStatus = OrderStatus.DRIVER_ASSIGNED,
    maxActiveOrders: number = 1,
    deliveryGroupId?: string,
    reassignMeta?: {
      previousDriverResponsibility?: DeliveryIncidentResponsibility;
      reassignmentReason?: string | null;
    },
  ) {
    // Revision written by THIS assignment. Captured inside the transaction so
    // the event carries the value this call produced even when another
    // transition commits before the post-commit aggregate read.
    const written = { revision: null as number | null };

    await this.prisma.$transaction(async (tx) => {
      // Serialize concurrent assignments/acceptances for THE SAME driver, then
      // enforce the max-active-orders cap inside the transaction. The caller
      // may pre-check in a service, but only this row lock makes it airtight:
      // a driver who accepted another order between the pre-check and here is
      // detected and rejected instead of being double-booked.
      await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      const activeCount = await this.driverWorkload.countActiveUnits(
        tx,
        driverId,
        orderId,
      );
      if (activeCount >= maxActiveOrders) {
        throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
      }

      const currentOrder = await tx.order.findUnique({
        where: { id: orderId },
        select: { status: true },
      });

      const activeGroups = await tx.orderDeliveryGroup.findMany({
        where: {
          orderId,
          status: { not: DeliveryGroupStatus.CANCELLED },
        },
        select: {
          id: true,
          status: true,
          primaryDriverId: true,
          assistDriverId: true,
          items: {
            select: {
              fulfillment: { select: { status: true } },
            },
          },
        },
        orderBy: { sequence: 'asc' },
      });

      const targetGroup = deliveryGroupId
        ? activeGroups.find((g) => g.id === deliveryGroupId)
        : (activeGroups.find((g) => !g.primaryDriverId) ?? activeGroups[0]);
      if (!targetGroup) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }

      // If there's an existing driver on this group that is different, release them if they have no other active work
      if (
        targetGroup.primaryDriverId &&
        targetGroup.primaryDriverId !== driverId
      ) {
        const prevId = targetGroup.primaryDriverId;
        await tx.driverDeliveryIncident.create({
          data: {
            orderId,
            deliveryGroupId: targetGroup.id,
            driverId: prevId,
            incidentType: DeliveryIncidentType.DRIVER_REASSIGNED,
            responsibility:
              reassignMeta?.previousDriverResponsibility ??
              DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM,
            reason: reassignMeta?.reassignmentReason?.trim() || null,
            reportedByUserId:
              actorUserId && actorUserId !== 'system' ? actorUserId : null,
            occurredAt: new Date(),
          },
        });
        const hasSiblingActiveInOrder = activeGroups.some(
          (g) =>
            g.id !== targetGroup.id &&
            g.status !== DeliveryGroupStatus.DELIVERED &&
            (g.primaryDriverId === prevId || g.assistDriverId === prevId),
        );
        if (
          !hasSiblingActiveInOrder &&
          (await this.driverWorkload.countActiveUnits(tx, prevId, orderId)) ===
            0
        ) {
          await tx.driver.update({
            where: { id: prevId },
            data: { status: DriverStatus.ONLINE },
          });
        }
      }

      // Cancel any pending dispatches for the target delivery group
      await tx.orderDispatch.updateMany({
        where: {
          deliveryGroupId: targetGroup.id,
          status: DispatchStatus.PENDING,
        },
        data: { status: DispatchStatus.CANCELLED },
      });

      const groupLiveFulfillments = targetGroup.items
        .map((it) => it.fulfillment)
        .filter((f) => f.status !== 'CANCELLED' && f.status !== 'REJECTED');
      const allGroupReady =
        groupLiveFulfillments.length > 0 &&
        groupLiveFulfillments.every((f) => f.status === 'READY_FOR_PICKUP');
      const anyGroupPreparingOrReady = groupLiveFulfillments.some(
        (f) => f.status === 'PREPARING' || f.status === 'READY_FOR_PICKUP',
      );

      const groupNextStatus =
        nextStatus === OrderStatus.PENDING_PAYMENT
          ? DeliveryGroupStatus.PENDING_PAYMENT
          : allGroupReady ||
              targetGroup.status === DeliveryGroupStatus.READY_FOR_PICKUP
            ? DeliveryGroupStatus.READY_FOR_PICKUP
            : anyGroupPreparingOrReady ||
                targetGroup.status === DeliveryGroupStatus.PREPARING
              ? DeliveryGroupStatus.PREPARING
              : DeliveryGroupStatus.DRIVER_ASSIGNED;

      const allOrderLiveFulfillments = activeGroups.flatMap((g) =>
        g.items
          .map((it) => it.fulfillment)
          .filter((f) => f.status !== 'CANCELLED' && f.status !== 'REJECTED'),
      );
      const allOrderReady =
        allOrderLiveFulfillments.length > 0 &&
        allOrderLiveFulfillments.every((f) => f.status === 'READY_FOR_PICKUP');
      const anyOrderPreparingOrReady = allOrderLiveFulfillments.some(
        (f) => f.status === 'PREPARING' || f.status === 'READY_FOR_PICKUP',
      );

      const currentOrderStatus = currentOrder?.status;
      let resolvedOrderStatus: OrderStatus = nextStatus;
      if (
        currentOrderStatus === OrderStatus.PARTIALLY_PICKED_UP ||
        currentOrderStatus === OrderStatus.PICKED_UP
      ) {
        resolvedOrderStatus = currentOrderStatus;
      } else if (nextStatus === OrderStatus.PENDING_PAYMENT) {
        resolvedOrderStatus = OrderStatus.PENDING_PAYMENT;
      } else if (
        allOrderReady ||
        currentOrderStatus === OrderStatus.READY_FOR_PICKUP
      ) {
        resolvedOrderStatus = OrderStatus.READY_FOR_PICKUP;
      } else if (
        anyOrderPreparingOrReady ||
        currentOrderStatus === OrderStatus.PREPARING
      ) {
        resolvedOrderStatus = OrderStatus.PREPARING;
      }

      const assignedDriver =
        typeof tx.driver?.findUnique === 'function'
          ? await tx.driver.findUnique({
              where: { id: driverId },
              select: { tier: true },
            })
          : null;

      await tx.orderDeliveryGroup.update({
        where: { id: targetGroup.id },
        data: {
          primaryDriverId: driverId,
          primaryDriverShiftId: driverShiftId,
          ...(assignedDriver?.tier
            ? { primaryDriverTierSnapshot: assignedDriver.tier }
            : {}),
          isStacked: activeCount > 0,
          status: groupNextStatus,
          assignedByUserId: actorUserId,
          assignedAt: new Date(),
        },
      });

      written.revision = (
        await tx.order.update({
          where: { id: orderId },
          data: {
            ...(currentOrderStatus !== resolvedOrderStatus
              ? { status: resolvedOrderStatus }
              : {}),
            revision: { increment: 1 },
          },
          select: { revision: true },
        })
      ).revision;

      const assignActor = await resolveOrderActorSnapshot(
        this.prisma,
        actorUserId,
        {
          orderId,
        },
      );
      await recordOrderStatusEventIdempotent(tx, {
        orderId,
        deliveryGroupId: targetGroup.id,
        eventKey: `driver_assigned:${orderId}:${targetGroup.id}:${driverId}:rev_${written.revision}`,
        status: resolvedOrderStatus,
        createdBy: actorUserId,
        actor: assignActor,
        note: `Driver manually assigned by admin. ${resolvedOrderStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`.trim(),
      });

      await tx.driver.update({
        where: { id: driverId },
        data: { status: DriverStatus.ON_DELIVERY },
      });
    });

    // Response shaping happens after the write transaction commits.
    const updated = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });

    if (!updated) throw new Error(OrderErrors.NOT_FOUND);

    // Report the revision this call wrote, not one a concurrent transition may
    // have produced between commit and the aggregate read.
    if (written.revision != null) updated.revision = written.revision;

    return updated;
  }

  async freeDriver(driverId: string) {
    if (
      (await this.driverWorkload.countActiveUnits(this.prisma, driverId)) === 0
    ) {
      return this.prisma.driver.update({
        where: { id: driverId },
        data: { status: DriverStatus.ONLINE },
      });
    }
  }

  async clearCart(customerId: string, vendorId: string) {
    return this.prisma.cart.deleteMany({ where: { customerId, vendorId } });
  }

  getVendorUserIds(
    vendorId: string | null,
    branchId?: string | null,
  ): Promise<string[]> {
    return this.queries.getVendorUserIds(vendorId, branchId);
  }

  getOrderVendorUserIds(
    orderId: string,
    orderVendorId: string | null,
    orderBranchId?: string | null,
  ): Promise<string[]> {
    return this.queries.getOrderVendorUserIds(
      orderId,
      orderVendorId,
      orderBranchId,
    );
  }

  getZoneAtLocation(lng: number, lat: number) {
    return this.geo.getZoneAtLocation(lng, lat);
  }

  getNearestOpenBranchLocation(
    vendorId: string,
    toLng: number,
    toLat: number,
    zoneId?: string,
    productIds: string[] = [],
  ) {
    return this.geo.getNearestOpenBranchLocation(
      vendorId,
      toLng,
      toLat,
      zoneId,
      productIds,
    );
  }

  getOpenBranchesWithProductAvailability(
    vendorId: string,
    toLng: number,
    toLat: number,
    zoneId?: string,
    productIds: string[] = [],
  ) {
    return this.geo.getOpenBranchesWithProductAvailability(
      vendorId,
      toLng,
      toLat,
      zoneId,
      productIds,
    );
  }

  getDistanceKm(
    fromLng: number,
    fromLat: number,
    toLng: number,
    toLat: number,
  ): Promise<number> {
    return this.geo.getDistanceKm(fromLng, fromLat, toLng, toLat);
  }

  async generateOrderNumber(): Promise<string> {
    try {
      const rows = await this.prisma.$queryRaw<Array<{ nextval: bigint }>>`
        SELECT nextval('order_number_seq')
      `;
      const seq = rows[0].nextval.toString().padStart(6, '0');
      return `ORD-${seq}`;
    } catch (e) {
      this.logger.warn(
        `Failed to use database sequence 'order_number_seq', using fallback: ${e}`,
      );
      // Fallback: ORD- + last 6 digits of timestamp + 4 random digits
      const timestamp = Date.now().toString().slice(-6);
      const random = Math.floor(1000 + Math.random() * 9000).toString();
      return `ORD-${timestamp}${random}`;
    }
  }
}
