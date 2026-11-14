import { Injectable, NotFoundException } from '@nestjs/common';
import { DeliveryGroupStatus, OrderStatus, Prisma } from '@prisma/client';
import { OrderErrors } from '../../../common/constants/response.constants';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';

export interface OrderFilters {
  status?: OrderStatus;
  vendorId?: string;
  branchId?: string;
  customerId?: string;
  driverId?: string;
  driverIds?: string[];
  page?: number;
  limit?: number;
}

/**
 * Translate an order-level status tab into the equivalent state of ONE
 * vendor's portion.
 *
 * A vendor's order list must be filtered by its own portion, not by the
 * aggregate order status: on a multi-vendor order the aggregate flips as soon
 * as any vendor moves, so filtering on it would drop a vendor's portion from
 * the tab that actually describes it (for example, vendor A accepts while
 * vendor B is still deciding — the order is still PENDING, but B's portion is
 * the only one that belongs in the "New" tab).
 */
export function portionStatusFilter(
  status: OrderStatus,
): Prisma.OrderVendorFulfillmentWhereInput {
  switch (status) {
    case OrderStatus.PENDING:
      return { status: 'PENDING' };
    case OrderStatus.ACCEPTED:
      return {
        status: 'ACCEPTED',
        preparingAt: null,
        readyAt: null,
        pickedUpAt: null,
        deliveredAt: null,
        groups: {
          none: {
            deliveryGroup: {
              status: {
                in: [
                  DeliveryGroupStatus.DRIVER_ASSIGNED,
                  DeliveryGroupStatus.PENDING_PAYMENT,
                  DeliveryGroupStatus.READY_FOR_PICKUP,
                ],
              },
            },
          },
        },
      };
    case OrderStatus.PREPARING:
      return {
        pickedUpAt: null,
        deliveredAt: null,
        readyAt: null,
        OR: [
          { status: 'PREPARING' },
          {
            status: 'ACCEPTED',
            preparingAt: { not: null },
          },
        ],
      };
    case OrderStatus.READY_FOR_PICKUP:
      return {
        pickedUpAt: null,
        deliveredAt: null,
        status: { notIn: ['REJECTED', 'CANCELLED', 'PICKED_UP'] },
        OR: [
          { status: 'READY_FOR_PICKUP' },
          { readyAt: { not: null } },
          {
            groups: {
              some: {
                deliveryGroup: { status: DeliveryGroupStatus.READY_FOR_PICKUP },
              },
            },
          },
        ],
      };
    case OrderStatus.LOOKING_FOR_DRIVER:
      return {
        status: 'ACCEPTED',
        preparingAt: null,
        readyAt: null,
        pickedUpAt: null,
        deliveredAt: null,
        order: { status: OrderStatus.LOOKING_FOR_DRIVER },
      };
    case OrderStatus.DRIVER_ASSIGNED:
      return {
        status: 'ACCEPTED',
        preparingAt: null,
        readyAt: null,
        pickedUpAt: null,
        deliveredAt: null,
        groups: {
          some: {
            deliveryGroup: { status: DeliveryGroupStatus.DRIVER_ASSIGNED },
          },
        },
      };
    case OrderStatus.PENDING_PAYMENT:
      return {
        status: 'ACCEPTED',
        preparingAt: null,
        readyAt: null,
        pickedUpAt: null,
        deliveredAt: null,
        groups: {
          some: {
            deliveryGroup: { status: DeliveryGroupStatus.PENDING_PAYMENT },
          },
        },
      };
    case OrderStatus.PICKED_UP:
    case OrderStatus.PARTIALLY_PICKED_UP:
      return {
        OR: [
          { status: 'PICKED_UP', deliveredAt: null },
          {
            status: { notIn: ['REJECTED', 'CANCELLED'] },
            pickedUpAt: { not: null },
            deliveredAt: null,
          },
        ],
      };
    case OrderStatus.DELIVERED:
      return {
        status: { notIn: ['REJECTED', 'CANCELLED'] },
        OR: [
          { deliveredAt: { not: null } },
          { order: { status: OrderStatus.DELIVERED } },
          {
            groups: {
              some: {
                deliveryGroup: { status: DeliveryGroupStatus.DELIVERED },
              },
            },
          },
        ],
      };
    case OrderStatus.CANCELLED:
      return { status: { in: ['REJECTED', 'CANCELLED'] } };
    default:
      return {
        status: { notIn: ['REJECTED', 'CANCELLED'] },
        deliveredAt: null,
      };
  }
}

export const ORDER_INCLUDE = {
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
  vendorBranch: {
    select: {
      id: true,
      name: true,
      nameAr: true,
      address: true,
      phone: true,
      isContracted: true,
      commissionRate: true,
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
      user: { select: { phone: true } },
      mobileWallets: {
        where: { isActive: true },
      },
    },
  },
  items: {
    include: { selectedOptions: true, product: { select: { imageUrl: true } } },
  },
  vendorFulfillments: {
    orderBy: { createdAt: 'asc' as const },
    include: {
      vendor: {
        select: {
          id: true,
          storeName: true,
          storeNameAr: true,
          logo: true,
          isContracted: true,
          commissionRate: true,
          phone: true,
        },
      },
      vendorBranch: {
        select: {
          id: true,
          name: true,
          nameAr: true,
          address: true,
          phone: true,
          isContracted: true,
          commissionRate: true,
        },
      },
      items: {
        where: { rejectedAt: null },
        select: {
          id: true,
          fulfillmentId: true,
          productId: true,
          productName: true,
          variantName: true,
          quantity: true,
          selectedUnit: true,
          unitPrice: true,
          totalPrice: true,
          specialRequest: true,
          selectedOptions: true,
          product: { select: { imageUrl: true } },
        },
      },
    },
  },
  deliveryGroups: {
    orderBy: { sequence: 'asc' as const },
    include: {
      items: { orderBy: { sequence: 'asc' as const } },
      primaryDriver: {
        select: {
          id: true,
          name: true,
          avatar: true,
          vehicleType: true,
          vehiclePlate: true,
          userId: true,
          user: { select: { phone: true } },
        },
      },
      assistDriver: {
        select: {
          id: true,
          name: true,
          avatar: true,
          vehicleType: true,
          vehiclePlate: true,
          userId: true,
          user: { select: { phone: true } },
        },
      },
    },
  },
  statusEvents: {
    orderBy: { createdAt: 'desc' as const },
    take: 10,
  },
  review: true,
};

/**
 * Read-side order repository handling filtered list queries, full graph fetches,
 * PostGIS coordinate hydration, and vendor notification user resolution.
 */
@Injectable()
export class OrderQueriesRepository {
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

    if ((order as any).vendorFulfillments?.length > 0) {
      const branchIds = Array.from(
        new Set(
          (order as any).vendorFulfillments
            .map((f: any) => f.vendorBranchId)
            .filter((id: any): id is string => Boolean(id)),
        ),
      );
      if (branchIds.length > 0) {
        const branchLocs = await this.prisma.$queryRaw<
          Array<{ id: string; lng: number; lat: number }>
        >`
          SELECT id, ST_X(location::geometry) AS lng, ST_Y(location::geometry) AS lat
          FROM vendor_branches WHERE id IN (${Prisma.join(branchIds)})
        `;
        for (const f of (order as any).vendorFulfillments) {
          if (f.vendorBranch) {
            const bloc = branchLocs.find((b) => b.id === f.vendorBranchId);
            if (bloc && bloc.lng !== null && bloc.lat !== null) {
              f.vendorBranch.lng = bloc.lng;
              f.vendorBranch.lat = bloc.lat;
              f.vendorBranch.location = [bloc.lng, bloc.lat];
            }
          }
        }
      }
      if (!(order as any).pickupLocation) {
        const firstWithLoc = (order as any).vendorFulfillments.find(
          (f: any) => f.vendorBranch?.location,
        );
        if (firstWithLoc) {
          (order as any).pickupLocation = firstWithLoc.vendorBranch.location;
        }
      }
    }

    return order;
  }

  async findMany(filters: OrderFilters) {
    const { page = 1, limit = 20 } = filters;
    const skip = (page - 1) * limit;

    const where: Prisma.OrderWhereInput = { deletedAt: null };
    if (filters.customerId) where.customerId = filters.customerId;

    // A multi-vendor order has vendorId = NULL and only mirrors the FIRST
    // delivery's driver onto the order, so an order-level filter alone would
    // hide it from every other vendor that owns a portion and every other
    // delivery's driver. Match those through the portions/groups too.
    const and: Prisma.OrderWhereInput[] = [];
    const fulfillmentBranchClause: Prisma.OrderVendorFulfillmentWhereInput =
      filters.branchId
        ? { OR: [{ vendorBranchId: filters.branchId }, { vendorBranchId: null }] }
        : {};
    const orderBranchClause: Prisma.OrderWhereInput = filters.branchId
      ? { OR: [{ vendorBranchId: filters.branchId }, { vendorBranchId: null }] }
      : {};

    if (filters.status) {
      if (filters.vendorId) {
        // Vendor tabs are portion-scoped (see portionStatusFilter).
        and.push({
          OR: [
            {
              vendorId: filters.vendorId,
              status: filters.status,
              ...orderBranchClause,
            },
            {
              vendorFulfillments: {
                some: {
                  vendorId: filters.vendorId,
                  ...fulfillmentBranchClause,
                  ...portionStatusFilter(filters.status),
                },
              },
            },
          ],
        });
      } else {
        where.status = filters.status;
      }
    }
    if (filters.vendorId) {
      and.push({
        OR: [
          {
            vendorId: filters.vendorId,
            ...orderBranchClause,
          },
          {
            vendorFulfillments: {
              some: {
                vendorId: filters.vendorId,
                ...fulfillmentBranchClause,
              },
            },
          },
        ],
      });
    }
    if (filters.driverIds !== undefined) {
      if (filters.driverIds.length === 0) {
        return {
          orders: [],
          total: 0,
          page,
          limit,
          totalPages: 0,
        };
      }
      and.push({
        OR: [
          { driverId: { in: filters.driverIds } },
          { assistDriverId: { in: filters.driverIds } },
          {
            deliveryGroups: {
              some: {
                OR: [
                  { primaryDriverId: { in: filters.driverIds } },
                  { assistDriverId: { in: filters.driverIds } },
                ],
              },
            },
          },
        ],
      });
    } else if (filters.driverId) {
      and.push({
        OR: [
          { driverId: filters.driverId },
          { assistDriverId: filters.driverId },
          {
            deliveryGroups: {
              some: {
                OR: [
                  { primaryDriverId: filters.driverId },
                  { assistDriverId: filters.driverId },
                ],
              },
            },
          },
        ],
      });
    }
    if (and.length > 0) where.AND = and;

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
              storeNameAr: true,
              logo: true,
              isContracted: true,
              commissionRate: true,
              rating: true,
              ratingCount: true,
            },
          },
          vendorBranch: {
            select: {
              id: true,
              name: true,
              nameAr: true,
              address: true,
              phone: true,
              isContracted: true,
              commissionRate: true,
            },
          },
          vendorFulfillments: {
            orderBy: { createdAt: 'asc' as const },
            include: {
              vendor: {
                select: {
                  id: true,
                  storeName: true,
                  storeNameAr: true,
                  logo: true,
                  isContracted: true,
                  commissionRate: true,
                  phone: true,
                },
              },
              vendorBranch: {
                select: {
                  id: true,
                  name: true,
                  nameAr: true,
                  address: true,
                  phone: true,
                  isContracted: true,
                  commissionRate: true,
                },
              },
              items: {
                where: { rejectedAt: null },
                select: {
                  id: true,
                  fulfillmentId: true,
                  productId: true,
                  productName: true,
                  variantName: true,
                  quantity: true,
                  selectedUnit: true,
                  unitPrice: true,
                  totalPrice: true,
                  specialRequest: true,
                  selectedOptions: true,
                  product: { select: { imageUrl: true } },
                },
              },
            },
          },
          // The vendor projection needs to know which delivery carries each
          // portion (driver assigned? payment pending?) to show the right
          // per-portion status and action.
          deliveryGroups: {
            orderBy: { sequence: 'asc' as const },
            select: {
              id: true,
              sequence: true,
              status: true,
              deliveryFee: true,
              isStacked: true,
              pickupImageUrl: true,
              deliveryImageUrl: true,
              pickedUpAt: true,
              deliveredAt: true,
              primaryDriverId: true,
              assistDriverId: true,
              items: {
                orderBy: { sequence: 'asc' as const },
                select: { fulfillmentId: true, sequence: true },
              },
              primaryDriver: {
                select: {
                  id: true,
                  name: true,
                  avatar: true,
                  vehicleType: true,
                  vehiclePlate: true,
                  userId: true,
                  user: { select: { phone: true } },
                },
              },
              assistDriver: {
                select: {
                  id: true,
                  name: true,
                  avatar: true,
                  vehicleType: true,
                  vehiclePlate: true,
                  userId: true,
                  user: { select: { phone: true } },
                },
              },
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
          items: {
            include: {
              product: { select: { imageUrl: true } },
              selectedOptions: true,
            },
          },
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

      // Populate fulfillments branch coordinates and fallback pickup location for multi-vendor orders
      const allBranchIds = Array.from(
        new Set(
          orders.flatMap((o: any) =>
            ((o.vendorFulfillments ?? []) as any[])
              .map((f: any) => f.vendorBranchId)
              .filter((id: any): id is string => Boolean(id)),
          ),
        ),
      );
      if (allBranchIds.length > 0) {
        const branchLocs = await this.prisma.$queryRaw<
          Array<{ id: string; lng: number; lat: number }>
        >`
          SELECT id, ST_X(location::geometry) AS lng, ST_Y(location::geometry) AS lat
          FROM vendor_branches WHERE id IN (${Prisma.join(allBranchIds)})
        `;
        for (const order of orders) {
          if ((order as any).vendorFulfillments?.length > 0) {
            for (const f of (order as any).vendorFulfillments) {
              if (f.vendorBranch) {
                const bloc = branchLocs.find((b) => b.id === f.vendorBranchId);
                if (bloc && bloc.lng !== null && bloc.lat !== null) {
                  f.vendorBranch.lng = bloc.lng;
                  f.vendorBranch.lat = bloc.lat;
                  f.vendorBranch.location = [bloc.lng, bloc.lat];
                }
              }
            }
            if (!(order as any).pickupLocation) {
              const firstWithLoc = (order as any).vendorFulfillments.find(
                (f: any) => f.vendorBranch?.location,
              );
              if (firstWithLoc) {
                (order as any).pickupLocation = firstWithLoc.vendorBranch.location;
              }
            }
          }
        }
      }
    }

    return { orders, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getVendorUserIds(
    vendorId: string | null,
    branchId?: string | null,
  ): Promise<string[]> {
    if (!vendorId) return [];
    const members = await this.prisma.vendorMember.findMany({
      where: {
        vendorId,
        ...(branchId
          ? {
              OR: [
                { role: 'OWNER' },
                { branchId: null },
                { branchId },
              ],
            }
          : {}),
      },
      select: { userId: true },
    });
    return Array.from(new Set(members.map((m) => m.userId)));
  }

  /**
   * Vendor-side users to notify about an order's status.
   *
   * Single-vendor orders resolve from the order's own vendor. Multi-vendor
   * orders carry no order-level vendor (`vendorId` is null), so the union of
   * every portion vendor's members (scoped by branch for non-owners) is returned
   * instead — otherwise no vendor would ever receive status/socket updates for
   * its own delivery.
   */
  async getOrderVendorUserIds(
    orderId: string,
    orderVendorId: string | null,
    orderBranchId?: string | null,
  ): Promise<string[]> {
    if (orderVendorId) return this.getVendorUserIds(orderVendorId, orderBranchId);

    const portions = await this.prisma.orderVendorFulfillment.findMany({
      where: { orderId },
      select: { vendorId: true, vendorBranchId: true },
    });
    if (portions.length === 0) return [];

    const orClauses: Prisma.VendorMemberWhereInput[] = portions.map((p) => ({
      vendorId: p.vendorId,
      ...(p.vendorBranchId
        ? {
            OR: [
              { role: 'OWNER' },
              { branchId: null },
              { branchId: p.vendorBranchId },
            ],
          }
        : {}),
    }));

    const members = await this.prisma.vendorMember.findMany({
      where: { OR: orClauses },
      select: { userId: true },
    });
    return Array.from(new Set(members.map((m) => m.userId)));
  }
}
