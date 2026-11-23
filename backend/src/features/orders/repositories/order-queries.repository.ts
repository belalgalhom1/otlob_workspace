import { Injectable, NotFoundException } from '@nestjs/common';
import { DeliveryGroupStatus, OrderStatus, Prisma, Role } from '@prisma/client';
import { OrderErrors } from '../../../common/constants/response.constants';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import {
  normalizeLegacyEventNote,
  OrderCancelledBySummary,
  resolveEventActorSummary,
  resolveVendorDisplayLogo,
  sanitizeCancelReason,
} from '../helpers/order-actor.helper';

export interface VendorOrderScope {
  vendorId: string;
  branchId?: string | null;
}

export interface OrderFilters {
  status?: OrderStatus;
  vendorId?: string;
  branchId?: string;
  vendorScopes?: VendorOrderScope[];
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
        order: {
          status: { not: OrderStatus.LOOKING_FOR_DRIVER },
        },
        groups: {
          none: {
            deliveryGroup: {
              status: {
                in: [
                  DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                  DeliveryGroupStatus.DRIVER_ASSIGNED,
                  DeliveryGroupStatus.PENDING_PAYMENT,
                  DeliveryGroupStatus.PREPARING,
                  DeliveryGroupStatus.READY_FOR_PICKUP,
                  DeliveryGroupStatus.PARTIALLY_PICKED_UP,
                  DeliveryGroupStatus.PICKED_UP,
                  DeliveryGroupStatus.DELIVERED,
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
        OR: [
          {
            order: { status: OrderStatus.LOOKING_FOR_DRIVER },
            groups: {
              none: {
                deliveryGroup: {
                  status: {
                    in: [
                      DeliveryGroupStatus.DRIVER_ASSIGNED,
                      DeliveryGroupStatus.PENDING_PAYMENT,
                      DeliveryGroupStatus.PREPARING,
                      DeliveryGroupStatus.READY_FOR_PICKUP,
                      DeliveryGroupStatus.PARTIALLY_PICKED_UP,
                      DeliveryGroupStatus.PICKED_UP,
                      DeliveryGroupStatus.DELIVERED,
                      DeliveryGroupStatus.CANCELLED,
                    ],
                  },
                },
              },
            },
          },
          {
            groups: {
              some: {
                deliveryGroup: {
                  status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                },
              },
            },
          },
        ],
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
            deliveryGroup: {
              status: {
                in: [
                  DeliveryGroupStatus.DRIVER_ASSIGNED,
                  DeliveryGroupStatus.PREPARING,
                ],
              },
            },
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

const ORDER_DRIVER_SELECT = {
  id: true,
  name: true,
  avatar: true,
  tier: true,
  vehicleType: true,
  vehiclePlate: true,
  rating: true,
  ratingCount: true,
  userId: true,
  user: { select: { id: true, name: true, phone: true, avatar: true } },
  mobileWallets: {
    where: { isActive: true },
  },
} as const;

const ORDER_ITEMS_INCLUDE = {
  selectedOptions: true,
  product: { select: { imageUrl: true } },
  variant: { select: { imageUrl: true } },
} as const;

const ORDER_VENDOR_FULFILLMENTS_INCLUDE = {
  orderBy: { createdAt: 'asc' as const },
  include: {
    vendor: {
      select: {
        id: true,
        storeName: true,
        storeNameAr: true,
        logo: true,
        coverImage: true,
        isContracted: true,
        commissionRate: true,
        phone: true,
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
} as const;

const ORDER_DELIVERY_GROUPS_INCLUDE = {
  orderBy: { sequence: 'asc' as const },
  include: {
    items: { orderBy: { sequence: 'asc' as const } },
    primaryDriver: { select: ORDER_DRIVER_SELECT },
    assistDriver: { select: ORDER_DRIVER_SELECT },
  },
} as const;

const ORDER_STATUS_EVENTS_INCLUDE = {
  orderBy: [
    { createdAt: 'desc' },
    { id: 'desc' },
  ] satisfies Prisma.OrderStatusEventOrderByWithRelationInput[],
  include: {
    fulfillment: {
      select: {
        id: true,
        vendorId: true,
        vendor: {
          select: {
            id: true,
            storeName: true,
            storeNameAr: true,
            logo: true,
            coverImage: true,
          },
        },
        vendorBranch: {
          select: { id: true, name: true, nameAr: true },
        },
      },
    },
    actorUser: {
      select: {
        id: true,
        name: true,
        role: true,
        avatar: true,
        driver: { select: { id: true, name: true, avatar: true } },
      },
    },
    actorVendor: {
      select: {
        id: true,
        storeName: true,
        storeNameAr: true,
        logo: true,
        coverImage: true,
      },
    },
  },
};

export const ORDER_INCLUDE = {
  customer: {
    include: {
      user: { select: { id: true, name: true, phone: true, avatar: true } },
    },
  },
  cancelledByUser: {
    select: {
      id: true,
      name: true,
      role: true,
      avatar: true,
      driver: { select: { id: true, name: true, avatar: true } },
    },
  },
  items: {
    include: ORDER_ITEMS_INCLUDE,
  },
  vendorFulfillments: ORDER_VENDOR_FULFILLMENTS_INCLUDE,
  deliveryGroups: ORDER_DELIVERY_GROUPS_INCLUDE,
  statusEvents: {
    ...ORDER_STATUS_EVENTS_INCLUDE,
    take: 50,
  },
  assistRequests: {
    orderBy: { createdAt: 'desc' as const },
    take: 5,
  },
  reviews: true,
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

    await Promise.all([
      this.hydrateLocations([order]),
      this.hydrateIdentities([order]),
    ]);
    return order;
  }

  async findMany(filters: OrderFilters) {
    const { page = 1, limit = 20 } = filters;
    const skip = (page - 1) * limit;

    const where: Prisma.OrderWhereInput = { deletedAt: null };
    if (filters.customerId) where.customerId = filters.customerId;

    const and: Prisma.OrderWhereInput[] = [];
    const buildVendorScopeCondition = (
      scope: VendorOrderScope,
      status?: OrderStatus,
    ): Prisma.OrderVendorFulfillmentWhereInput => ({
      vendorId: scope.vendorId,
      ...(scope.branchId
        ? { OR: [{ vendorBranchId: scope.branchId }, { vendorBranchId: null }] }
        : {}),
      ...(status ? portionStatusFilter(status) : {}),
    });
    const fulfillmentBranchClause: Prisma.OrderVendorFulfillmentWhereInput =
      filters.branchId
        ? {
            OR: [
              { vendorBranchId: filters.branchId },
              { vendorBranchId: null },
            ],
          }
        : {};

    const driverIdsFilter =
      filters.driverIds !== undefined
        ? filters.driverIds
        : filters.driverId
          ? [filters.driverId]
          : undefined;

    if (driverIdsFilter !== undefined && driverIdsFilter.length === 0) {
      return {
        orders: [],
        total: 0,
        page,
        limit,
        totalPages: 0,
      };
    }

    const driverStatusFilter =
      driverIdsFilter &&
      filters.status &&
      Object.values(DeliveryGroupStatus).includes(
        filters.status as unknown as DeliveryGroupStatus,
      )
        ? (filters.status as unknown as DeliveryGroupStatus)
        : undefined;

    const hasVendorScopes =
      Array.isArray(filters.vendorScopes) && filters.vendorScopes.length > 0;

    if (filters.status) {
      if (hasVendorScopes) {
        and.push({
          vendorFulfillments: {
            some: {
              OR: filters.vendorScopes!.map((s) =>
                buildVendorScopeCondition(s, filters.status),
              ),
            },
          },
        });
      } else if (filters.vendorId) {
        and.push({
          vendorFulfillments: {
            some: buildVendorScopeCondition(
              { vendorId: filters.vendorId, branchId: filters.branchId },
              filters.status,
            ),
          },
        });
      } else if (!driverStatusFilter) {
        where.status = filters.status;
      }
    }

    if (hasVendorScopes) {
      and.push({
        vendorFulfillments: {
          some: {
            OR: filters.vendorScopes!.map((s) => buildVendorScopeCondition(s)),
          },
        },
      });
    } else if (filters.vendorId) {
      and.push({
        vendorFulfillments: {
          some: buildVendorScopeCondition({
            vendorId: filters.vendorId,
            branchId: filters.branchId,
          }),
        },
      });
    } else if (filters.branchId) {
      and.push({
        vendorFulfillments: {
          some: fulfillmentBranchClause,
        },
      });
    }

    if (driverIdsFilter && driverIdsFilter.length > 0) {
      and.push({
        deliveryGroups: {
          some: {
            ...(driverStatusFilter ? { status: driverStatusFilter } : {}),
            OR: [
              { primaryDriverId: { in: driverIdsFilter } },
              { assistDriverId: { in: driverIdsFilter } },
            ],
          },
        },
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
              user: {
                select: { id: true, name: true, phone: true, avatar: true },
              },
            },
          },
          vendorFulfillments: ORDER_VENDOR_FULFILLMENTS_INCLUDE,
          deliveryGroups: ORDER_DELIVERY_GROUPS_INCLUDE,
          cancelledByUser: ORDER_INCLUDE.cancelledByUser,
          statusEvents: {
            ...ORDER_STATUS_EVENTS_INCLUDE,
            take: 25,
          },
          items: {
            include: ORDER_ITEMS_INCLUDE,
          },
          reviews: true,
        },
      }),
      this.prisma.order.count({ where }),
    ]);

    if (orders.length > 0) {
      await Promise.all([
        this.hydrateLocations(orders),
        this.hydrateIdentities(orders),
      ]);
    }

    return { orders, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  private async hydrateIdentities(orders: any[]): Promise<void> {
    if (orders.length === 0) return;

    const missingUserIds = new Set<string>();
    const uuidRe =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    for (const order of orders) {
      for (const group of (order.deliveryGroups ?? []) as any[]) {
        if (group.primaryDriver) {
          group.primaryDriver.avatar =
            group.primaryDriver.avatar ??
            group.primaryDriver.user?.avatar ??
            null;
        }
        if (group.assistDriver) {
          group.assistDriver.avatar =
            group.assistDriver.avatar ??
            group.assistDriver.user?.avatar ??
            null;
        }
      }

      if (
        order.cancelledByUserId &&
        !order.cancelledByUser &&
        uuidRe.test(order.cancelledByUserId)
      ) {
        missingUserIds.add(order.cancelledByUserId);
      }
      for (const ev of (order.statusEvents ?? []) as any[]) {
        const uid =
          ev.actorUserId ??
          (uuidRe.test(ev.createdBy ?? '') ? ev.createdBy : null);
        if (uid && !ev.actorUser) {
          missingUserIds.add(uid);
        }
      }
      for (const ff of (order.vendorFulfillments ?? []) as any[]) {
        if (ff.decidedByUserId && uuidRe.test(ff.decidedByUserId)) {
          missingUserIds.add(ff.decidedByUserId);
        }
      }
    }

    const userLookup = new Map<string, any>();
    if (missingUserIds.size > 0 && this.prisma?.user?.findMany) {
      const users = await this.prisma.user.findMany({
        where: { id: { in: Array.from(missingUserIds) } },
        select: {
          id: true,
          name: true,
          role: true,
          avatar: true,
          driver: { select: { id: true, name: true, avatar: true } },
          vendorMemberships: {
            select: {
              vendorId: true,
              vendor: {
                select: {
                  id: true,
                  storeName: true,
                  storeNameAr: true,
                  logo: true,
                  coverImage: true,
                },
              },
            },
          },
        },
      });
      for (const u of users) {
        userLookup.set(u.id, u);
      }
    }

    for (const order of orders) {
      const fulfillmentsById = new Map<string, any>();
      for (const ff of (order.vendorFulfillments ?? []) as any[]) {
        if (ff.id) fulfillmentsById.set(ff.id, ff);
      }

      // Deduplicate defensively on read using explicit eventKey or full contextual tuple
      // (never deduplicate by status alone so separate legitimate events are preserved).
      const rawEvents = Array.isArray(order.statusEvents)
        ? order.statusEvents
        : [];
      const sortedAsc = [...rawEvents].sort((a, b) => {
        const ta = new Date(a?.createdAt ?? 0).getTime();
        const tb = new Date(b?.createdAt ?? 0).getTime();
        if (ta !== tb) return ta - tb;
        return String(a?.id ?? '').localeCompare(String(b?.id ?? ''));
      });

      const seenKeys = new Set<string>();
      const deduped: any[] = [];
      for (const ev of sortedAsc) {
        if (!ev) continue;
        if (
          !ev.fulfillment &&
          ev.fulfillmentId &&
          fulfillmentsById.has(ev.fulfillmentId)
        ) {
          ev.fulfillment = fulfillmentsById.get(ev.fulfillmentId);
        }
        const normalizedNote = normalizeLegacyEventNote(ev);
        const actor = resolveEventActorSummary(ev, userLookup);

        // If a historical event was recorded by a vendor member without fulfillmentId,
        // still attach their store identity when available.
        if (
          actor.role === Role.VENDOR_MEMBER &&
          !actor.vendorId &&
          actor.id &&
          userLookup.get(actor.id)?.vendorMemberships?.length
        ) {
          const matchedVendor =
            userLookup
              .get(actor.id)
              .vendorMemberships.find((m: any) =>
                (order.vendorFulfillments ?? []).some(
                  (ff: any) => ff.vendorId === m.vendorId,
                ),
              )?.vendor ??
            userLookup.get(actor.id).vendorMemberships[0]?.vendor;
          if (matchedVendor) {
            actor.vendorId = matchedVendor.id;
            actor.name = matchedVendor.storeName || actor.name;
            actor.nameAr =
              matchedVendor.storeNameAr || matchedVendor.storeName || null;
            actor.avatar =
              resolveVendorDisplayLogo(matchedVendor) ?? actor.avatar;
          }
        }

        const key = ev.eventKey
          ? `k:${ev.eventKey}`
          : `t:${ev.fulfillmentId ?? ''}|${ev.deliveryGroupId ?? ''}|${ev.status ?? ''}|${normalizedNote ?? ''}|${actor.id ?? (actor.isSystem ? 'system' : '')}`;

        if (seenKeys.has(key)) continue;
        seenKeys.add(key);

        deduped.push({
          ...ev,
          note: normalizedNote,
          actor,
          actorUserId: actor.id,
          actorRole: actor.role,
          actorName: actor.name,
          actorNameAr: actor.nameAr,
          actorAvatar: actor.avatar,
          actorVendorId: actor.vendorId,
        });
      }

      // Present newest-first chronologically
      deduped.reverse();
      order.statusEvents = deduped;

      if (order.status === OrderStatus.CANCELLED) {
        order.cancelledBy = this.resolveOrderCancelledBy(
          order,
          deduped,
          userLookup,
        );
      } else {
        order.cancelledBy = null;
      }
    }
  }

  private resolveOrderCancelledBy(
    order: any,
    eventsDesc: any[],
    userLookup: Map<string, any>,
  ): OrderCancelledBySummary {
    const cancelEv = eventsDesc.find(
      (e) => e?.status === OrderStatus.CANCELLED,
    );
    const reason =
      sanitizeCancelReason(order.cancelReason) ??
      sanitizeCancelReason(cancelEv?.note) ??
      null;
    const cancelledAt =
      order.cancelledAt ?? cancelEv?.createdAt ?? order.updatedAt ?? null;

    if (
      order.cancelledByUserId ||
      order.cancelledByName ||
      order.cancelledByUser
    ) {
      const syntheticEv = {
        actorUserId: order.cancelledByUserId ?? null,
        actorRole: order.cancelledByRole ?? order.cancelledByUser?.role ?? null,
        actorName: order.cancelledByName ?? order.cancelledByUser?.name ?? null,
        actorNameAr: order.cancelledByNameAr ?? null,
        actorAvatar:
          order.cancelledByAvatar ??
          order.cancelledByUser?.driver?.avatar ??
          order.cancelledByUser?.avatar ??
          null,
        actorVendorId: null,
        actorUser: order.cancelledByUser ?? null,
        createdBy: order.cancelledByUserId ?? 'system',
      };
      const actor = resolveEventActorSummary(syntheticEv, userLookup);
      if (
        actor.role === Role.VENDOR_MEMBER &&
        actor.id &&
        userLookup.get(actor.id)?.vendorMemberships?.length
      ) {
        const matchedVendor =
          userLookup
            .get(actor.id)
            .vendorMemberships.find((m: any) =>
              (order.vendorFulfillments ?? []).some(
                (ff: any) => ff.vendorId === m.vendorId,
              ),
            )?.vendor ?? userLookup.get(actor.id).vendorMemberships[0]?.vendor;
        if (matchedVendor) {
          actor.vendorId = matchedVendor.id;
          actor.name = matchedVendor.storeName || actor.name;
          actor.nameAr =
            matchedVendor.storeNameAr || matchedVendor.storeName || null;
          actor.avatar = resolveVendorDisplayLogo(matchedVendor) ?? actor.avatar;
        }
      }
      return {
        userId: actor.id,
        name: actor.name,
        nameAr: actor.nameAr,
        role: actor.role,
        avatar: actor.avatar,
        vendorId: actor.vendorId,
        reason,
        cancelledAt,
        isSystem: actor.isSystem,
      };
    }

    if (cancelEv?.actor && !cancelEv.actor.isSystem) {
      return {
        userId: cancelEv.actor.id,
        name: cancelEv.actor.name,
        nameAr: cancelEv.actor.nameAr,
        role: cancelEv.actor.role,
        avatar: cancelEv.actor.avatar,
        vendorId: cancelEv.actor.vendorId,
        reason,
        cancelledAt,
        isSystem: false,
      };
    }

    // Legacy fallback: check whether all/last vendor fulfillment was explicitly rejected by a vendor/admin user
    const rejectedFulfillments = ((order.vendorFulfillments ?? []) as any[])
      .filter((f) => f?.status === 'REJECTED' && f?.decidedByUserId)
      .sort(
        (a, b) =>
          new Date(b.decidedAt ?? 0).getTime() -
          new Date(a.decidedAt ?? 0).getTime(),
      );
    const lastRejected = rejectedFulfillments[0];
    if (lastRejected?.decidedByUserId) {
      const decidedUser = userLookup.get(lastRejected.decidedByUserId);
      const rejectionReason =
        sanitizeCancelReason(lastRejected.rejectionReason) ??
        sanitizeCancelReason(lastRejected.rejectionReasonAr) ??
        reason;
      const role = decidedUser?.role ?? Role.VENDOR_MEMBER;
      if (role === Role.VENDOR_MEMBER && lastRejected.vendor) {
        return {
          userId: lastRejected.decidedByUserId,
          name: lastRejected.vendor.storeName || decidedUser?.name || 'Vendor',
          nameAr:
            lastRejected.vendor.storeNameAr ||
            lastRejected.vendor.storeName ||
            null,
          role: Role.VENDOR_MEMBER,
          avatar:
            resolveVendorDisplayLogo(lastRejected.vendor) ??
            decidedUser?.avatar ??
            null,
          vendorId: lastRejected.vendor.id ?? lastRejected.vendorId ?? null,
          reason: rejectionReason,
          cancelledAt,
          isSystem: false,
        };
      }
      if (decidedUser) {
        return {
          userId: decidedUser.id,
          name: decidedUser.driver?.name ?? decidedUser.name,
          nameAr: null,
          role,
          avatar: decidedUser.driver?.avatar ?? decidedUser.avatar ?? null,
          vendorId: null,
          reason: rejectionReason,
          cancelledAt,
          isSystem: false,
        };
      }
    }

    return {
      userId: null,
      name: 'System',
      nameAr: 'النظام',
      role: null,
      avatar: null,
      vendorId: null,
      reason,
      cancelledAt,
      isSystem: true,
    };
  }

  private async hydrateLocations(orders: any[]): Promise<void> {
    if (orders.length === 0) return;

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
    const locById = new Map(locations.map((l) => [l.id, l]));
    for (const order of orders) {
      const loc = locById.get(order.id);
      if (!loc) continue;
      if (loc.lng !== null && loc.lat !== null) {
        order.deliveryLocation = [loc.lng, loc.lat];
      }
      if (loc.pickupLng !== null && loc.pickupLat !== null) {
        order.pickupLocation = [loc.pickupLng, loc.pickupLat];
      }
    }

    const allBranchIds = Array.from(
      new Set(
        orders.flatMap((o) =>
          ((o.vendorFulfillments ?? []) as any[])
            .map((f: any) => f.vendorBranchId)
            .filter((id: any): id is string => Boolean(id)),
        ),
      ),
    );
    if (allBranchIds.length === 0) return;

    const branchLocs = await this.prisma.$queryRaw<
      Array<{ id: string; lng: number; lat: number }>
    >`
      SELECT id, ST_X(location::geometry) AS lng, ST_Y(location::geometry) AS lat
      FROM vendor_branches WHERE id IN (${Prisma.join(allBranchIds)})
    `;
    const branchLocById = new Map(branchLocs.map((b) => [b.id, b]));
    for (const order of orders) {
      const fulfillments = (order.vendorFulfillments ?? []) as any[];
      if (fulfillments.length === 0) continue;
      for (const f of fulfillments) {
        if (!f.vendorBranch || !f.vendorBranchId) continue;
        const bloc = branchLocById.get(f.vendorBranchId);
        if (bloc && bloc.lng !== null && bloc.lat !== null) {
          f.vendorBranch.lng = bloc.lng;
          f.vendorBranch.lat = bloc.lat;
          f.vendorBranch.location = [bloc.lng, bloc.lat];
        }
      }
      if (!order.pickupLocation) {
        const firstWithLoc = fulfillments.find((f) => f.vendorBranch?.location);
        if (firstWithLoc) {
          order.pickupLocation = firstWithLoc.vendorBranch.location;
        }
      }
    }
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
              OR: [{ role: 'OWNER' }, { branchId: null }, { branchId }],
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
    if (orderVendorId)
      return this.getVendorUserIds(orderVendorId, orderBranchId);

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
