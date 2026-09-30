import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  CartErrors,
  OrderErrors,
  CustomerErrors,
} from 'src/common/constants/response.constants';
import {
  DispatchStatus,
  DriverStatus,
  OrderStatus,
  Prisma,
} from '@prisma/client';
import { DRIVER_ACTIVE_ORDER_STATUSES } from './orders.constants';

export interface CreateOrderData {
  orderNumber: string;
  clientOrderKey?: string | null;
  customerId: string;
  vendorId: string | null;
  vendorBranchId: string | null;
  zoneId: string | null;
  paymentMethod: string;
  deliveryAddress: string;
  deliveryLng: number;
  deliveryLat: number;
  subtotal: number;
  deliveryFee: number;
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
}

export interface OrderItemData {
  productId: string | null;
  variantId: string | null;
  productName: string;
  variantName: string | null;
  unitPrice: number;
  quantity: number;
  totalPrice: number;
  specialRequest: string | null;
  options: Array<{ optionId: string; optionName: string; priceAdded: number }>;
}

export interface OrderFilters {
  status?: OrderStatus;
  vendorId?: string;
  customerId?: string;
  driverId?: string;
  page?: number;
  limit?: number;
}

const ORDER_INCLUDE = {
  customer: {
    include: {
      user: { select: { id: true, name: true, phone: true, avatar: true } },
    },
  },
  vendor: {
    select: {
      id: true,
      storeName: true,
      storeNameAr: true,
      logo: true,
      commissionRate: true,
      isContracted: true,
      rating: true,
      ratingCount: true,
    },
  },
  driver: {
    select: {
      id: true,
      name: true,
      avatar: true,
      vehicleType: true,
      vehiclePlate: true,
      rating: true,
      ratingCount: true,
      userId: true,
      mobileWallets: {
        where: { isActive: true },
      },
    },
  },
  items: {
    include: { selectedOptions: true, product: { select: { imageUrl: true } } },
  },
  statusEvents: {
    orderBy: { createdAt: 'desc' as const },
    take: 10,
  },
  review: true,
};

@Injectable()
export class OrdersRepository {
  private readonly logger = new Logger(OrdersRepository.name);

  constructor(private readonly prisma: PrismaService) {}

  async findById(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });
    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);

    const locations = await this.prisma.$queryRaw<
      Array<{ lng: number; lat: number; pickupLng: number; pickupLat: number }>
    >`
      SELECT ST_X("deliveryLocation"::geometry) AS lng, ST_Y("deliveryLocation"::geometry) AS lat, ST_X("pickupLocation"::geometry) AS "pickupLng", ST_Y("pickupLocation"::geometry) AS "pickupLat"
      FROM orders WHERE id = ${orderId}
    `;
    if (locations.length > 0) {
      if (locations[0].lng !== null) {
        (order as any).deliveryLocation = [locations[0].lng, locations[0].lat];
      }
      if (locations[0].pickupLng !== null) {
        (order as any).pickupLocation = [
          locations[0].pickupLng,
          locations[0].pickupLat,
        ];
      }
    }

    return order;
  }

  async findMany(filters: OrderFilters) {
    const { page = 1, limit = 20 } = filters;
    const skip = (page - 1) * limit;

    const where: Prisma.OrderWhereInput = { deletedAt: null };
    if (filters.status) where.status = filters.status;
    if (filters.vendorId) where.vendorId = filters.vendorId;
    if (filters.customerId) where.customerId = filters.customerId;
    if (filters.driverId) where.driverId = filters.driverId;

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          customer: {
            include: {
              user: { select: { id: true, name: true, phone: true } },
            },
          },
          vendor: {
            select: {
              id: true,
              storeName: true,
              logo: true,
              rating: true,
              ratingCount: true,
            },
          },
          driver: {
            select: {
              id: true,
              name: true,
              avatar: true,
              vehicleType: true,
              vehiclePlate: true,
              rating: true,
              ratingCount: true,
              user: { select: { id: true, phone: true } },
            },
          },
          items: { include: { product: { select: { imageUrl: true } } } },
          review: true,
        },
      }),
      this.prisma.order.count({ where }),
    ]);

    if (orders.length > 0) {
      const orderIds = orders.map((o) => o.id);
      const locations = await this.prisma.$queryRaw<
        Array<{
          id: string;
          lng: number;
          lat: number;
          pickupLng: number;
          pickupLat: number;
        }>
      >`
        SELECT id, ST_X("deliveryLocation"::geometry) AS lng, ST_Y("deliveryLocation"::geometry) AS lat, ST_X("pickupLocation"::geometry) AS "pickupLng", ST_Y("pickupLocation"::geometry) AS "pickupLat"
        FROM orders WHERE id IN (${Prisma.join(orderIds)})
      `;
      for (const order of orders) {
        const loc = locations.find((l) => l.id === order.id);
        if (loc) {
          if (loc.lng !== null && loc.lat !== null) {
            (order as any).deliveryLocation = [loc.lng, loc.lat];
          }
          if (loc.pickupLng !== null && loc.pickupLat !== null) {
            (order as any).pickupLocation = [loc.pickupLng, loc.pickupLat];
          }
        }
      }
    }

    return { orders, total, page, limit, totalPages: Math.ceil(total / limit) };
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
      // Generate the UUID in-process so the INSERT can return it to the caller
      // without a second round-trip (the old flow re-read the row via
      // findFirst just to learn the id the database had generated).
      const orderId = randomUUID();

      // Raw SQL required for geometry field. ON CONFLICT (clientOrderKey) makes
      // creation idempotent: a re-submitted Idempotency-Key inserts 0 rows and
      // the existing order is returned instead of a duplicate.
      const inserted = await tx.$executeRaw`
        INSERT INTO orders (
          id, "orderNumber", "clientOrderKey", type, "customerId", "vendorId", "vendorBranchId", "zoneId",
          status, "paymentMethod", "paymentStatus",
          "pickupAddress", "pickupLocation",
          "deliveryAddress", "deliveryLocation",
          subtotal, "deliveryFee", "driverBonusFee", "serviceFee", tax, discount, "coinsUsed", "coinsEarned", "grandTotal", "upfrontAmount",
          "itemDetails", "requestedVehicleType",
          "specialRequest", "updatedAt"
        ) VALUES (
          ${orderId},
          ${data.orderNumber},
          ${data.clientOrderKey ?? null},
          ${data.type}::"OrderType",
          ${data.customerId},
          ${data.vendorId},
          ${data.vendorBranchId ?? null},
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

      const orderItemsData: Prisma.OrderItemCreateManyInput[] = [];
      const orderItemOptionsData: Prisma.OrderItemOptionCreateManyInput[] = [];

      for (const item of items) {
        const orderItemId = randomUUID();
        orderItemsData.push({
          id: orderItemId,
          orderId: created.id,
          productId: item.productId,
          variantId: item.variantId,
          productName: item.productName,
          variantName: item.variantName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          totalPrice: item.totalPrice,
          specialRequest: item.specialRequest,
        });

        if (item.options.length > 0) {
          for (const opt of item.options) {
            orderItemOptionsData.push({
              orderItemId: orderItemId,
              optionId: opt.optionId,
              optionName: opt.optionName,
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
          aggregatedProductQty.set(
            item.productId,
            (aggregatedProductQty.get(item.productId) ?? 0) + item.quantity,
          );
        }
      }

      // One batched read to learn which of the referenced variants track stock.
      const variantIds = [...aggregatedVariantQty.keys()];
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
          // Sold out concurrently between check and decrement
          throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
        }
      }

      // Same treatment for product-level tracked stock.
      const productIds = [...aggregatedProductQty.keys()];
      const trackedProducts = productIds.length
        ? await tx.product.findMany({
            where: { id: { in: productIds } },
            select: { id: true, tracksStock: true },
          })
        : [];
      const trackedProductIds = new Set(
        trackedProducts.filter((p) => p.tracksStock).map((p) => p.id),
      );

      for (const [productId, qty] of aggregatedProductQty) {
        if (!trackedProductIds.has(productId)) continue;
        const rows = await tx.$executeRaw`
          UPDATE products
          SET stock = stock - ${qty}
          WHERE id = ${productId}
            AND stock IS NOT NULL
            AND stock >= ${qty}
        `;
        if (rows === 0) {
          // Sold out concurrently between check and decrement
          throw new BadRequestException(OrderErrors.INSUFFICIENT_STOCK);
        }
      }

      await tx.orderStatusEvent.create({
        data: {
          orderId: created.id,
          status: OrderStatus.PENDING,
          createdBy: actorUserId,
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
    driverId: string | null | undefined,
  ) {
    await this.prisma.$transaction(async (tx) => {
      const updatedCount = await tx.order.updateMany({
        where: { id: orderId, status: expectedOldStatus },
        data: { status: OrderStatus.CANCELLED },
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

      await tx.orderStatusEvent.create({
        data: {
          orderId,
          status: OrderStatus.CANCELLED,
          note: reason,
          createdBy: actorUserId,
        },
      });

      // Refund coins atomically with the status change so a crash or a retry
      // cannot leave the order cancelled without a refund, or refund it twice.
      if (coinsUsed > 0) {
        const alreadyRefunded = await tx.customerCoinTransaction.findFirst({
          where: { orderId, type: 'REFUNDED' },
        });
        if (!alreadyRefunded) {
          const customer = await tx.customer.update({
            where: { id: customerId },
            data: { coinBalance: { increment: coinsUsed } },
            select: { coinBalance: true },
          });
          await tx.customerCoinTransaction.create({
            data: {
              customerId,
              orderId,
              type: 'REFUNDED',
              amount: coinsUsed,
              balanceAfter: customer.coinBalance,
              description: `Refund for cancelled order ${orderNumber}`,
            },
          });
        }
      }

      if (driverId) {
        await tx.driver.update({
          where: { id: driverId },
          data: { status: DriverStatus.ONLINE },
        });
      }

      // Always abort any active dispatch attempts
      await tx.orderDispatch.updateMany({
        where: { orderId, status: DispatchStatus.PENDING },
        data: { status: DispatchStatus.CANCELLED },
      });
    });

    // Read the response-shaped aggregate AFTER commit — the ORDER_INCLUDE tree
    // is read-only data and does not need to hold the transaction open.
    const updated = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });
    if (!updated) throw new Error(OrderErrors.NOT_FOUND);

    return updated;
  }

  async updateStatus(
    orderId: string,
    status: OrderStatus,
    actorUserId: string,
    note?: string,
    extraData?: Prisma.OrderUpdateInput,
    expectedOldStatus?: OrderStatus,
  ) {
    await this.prisma.$transaction(async (tx) => {
      if (expectedOldStatus) {
        const count = await tx.order.updateMany({
          where: { id: orderId, status: expectedOldStatus },
          data: { status, ...extraData },
        });
        if (count.count === 0) {
          throw new BadRequestException(OrderErrors.CONCURRENT_STATE_CHANGE);
        }
      } else {
        await tx.order.update({
          where: { id: orderId },
          data: { status, ...extraData },
        });
      }

      await tx.orderStatusEvent.create({
        data: {
          orderId,
          status,
          note: note ?? null,
          createdBy: actorUserId,
        },
      });
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

    return updated;
  }

  async assignDriver(
    orderId: string,
    driverId: string,
    driverShiftId: string | null,
    actorUserId: string,
    nextStatus: OrderStatus = OrderStatus.DRIVER_ASSIGNED,
  ) {
    await this.prisma.$transaction(async (tx) => {
      // Serialize concurrent assignments/acceptances for THE SAME driver, then
      // enforce the single-active-order cap inside the transaction. The caller
      // may pre-check in a service, but only this row lock makes it airtight:
      // a driver who accepted another order between the pre-check and here is
      // detected and rejected instead of being double-booked.
      await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

      const alreadyOnOrder = await tx.order.findFirst({
        where: {
          driverId,
          id: { not: orderId },
          status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
        },
        select: { id: true },
      });
      if (alreadyOnOrder) {
        throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
      }

      // Fetch the current order to check if a driver is already assigned
      const existingOrder = await tx.order.findUnique({
        where: { id: orderId },
        select: { driverId: true },
      });

      // If there's an existing driver that is different, release them
      if (existingOrder?.driverId && existingOrder.driverId !== driverId) {
        await tx.driver.update({
          where: { id: existingOrder.driverId },
          data: { status: DriverStatus.ONLINE },
        });
      }

      // Cancel any pending dispatches
      await tx.orderDispatch.updateMany({
        where: { orderId, status: 'PENDING' },
        data: { status: 'CANCELLED' },
      });

      await tx.order.update({
        where: { id: orderId },
        data: {
          driverId,
          driverShiftId,
          status: nextStatus,
          driverAssignedAt: new Date(),
        },
      });

      await tx.orderStatusEvent.create({
        data: {
          orderId,
          status: nextStatus,
          createdBy: actorUserId,
          note: `Driver manually assigned by admin. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
        },
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

    return updated;
  }

  async cancelPendingDispatches(orderId: string) {
    return this.prisma.orderDispatch.updateMany({
      where: { orderId, status: DispatchStatus.PENDING },
      data: { status: DispatchStatus.CANCELLED },
    });
  }

  async freeDriver(driverId: string) {
    return this.prisma.driver.update({
      where: { id: driverId },
      data: { status: DriverStatus.ONLINE },
    });
  }

  async clearCart(customerId: string, vendorId: string) {
    return this.prisma.cart.deleteMany({ where: { customerId, vendorId } });
  }

  async getVendorUserIds(vendorId: string | null): Promise<string[]> {
    if (!vendorId) return [];
    const members = await this.prisma.vendorMember.findMany({
      where: { vendorId },
      select: { userId: true },
    });
    return members.map((m) => m.userId);
  }

  async getZoneAtLocation(lng: number, lat: number) {
    const rows = await this.prisma.$queryRaw<
      Array<{
        id: string;
        baseDeliveryFeeOverride: number | null;
        minOrderAmountOverride: number | null;
      }>
    >`
      SELECT id, "baseDeliveryFeeOverride", "minOrderAmountOverride"
      FROM zones
      WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326))
        AND "isActive" = true
      ORDER BY ST_Area(boundary) ASC
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  async getNearestOpenBranchLocation(
    vendorId: string,
    toLng: number,
    toLat: number,
  ): Promise<{ id: string; lng: number; lat: number } | null> {
    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; lng: number; lat: number }>
    >`
      SELECT
        id,
        ST_X(location::geometry) AS lng,
        ST_Y(location::geometry) AS lat
      FROM vendor_branches
      WHERE "vendorId"::text = ${vendorId}::text
        AND "isOpen" = true
      ORDER BY ST_Distance(
        location::geography,
        ST_SetSRID(ST_MakePoint(${toLng}, ${toLat}), 4326)::geography
      ) ASC
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  async getDistanceKm(
    fromLng: number,
    fromLat: number,
    toLng: number,
    toLat: number,
  ): Promise<number> {
    const rows = await this.prisma.$queryRaw<Array<{ km: number }>>`
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint(${fromLng}, ${fromLat}), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${toLng}, ${toLat}), 4326)::geography
      ) / 1000 AS km
    `;
    return Number(rows[0]?.km ?? 3);
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
