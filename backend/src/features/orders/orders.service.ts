import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { OrdersRepository } from './orders.repository';
import { QueryOrdersDto } from './dto/order.dto';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { Role, Permission } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  OrderErrors,
  DriverErrors,
} from '../../common/constants/response.constants';

@Injectable()
export class OrdersService {
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async getMyOrdersAsCustomer(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const [customer, canManage] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      this.canManageOrders(actor.sub, actor.role),
    ]);
    if (!customer)
      return { orders: [], total: 0, page: 1, limit: 20, totalPages: 0 };
    const result = await this.ordersRepository.findMany({ ...dto, customerId: customer.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, undefined, { canManage }),
      ),
    );
    return result;
  }

  async getVendorOrders(
    actor: JwtAccessPayload,
    vendorId: string,
    dto: QueryOrdersDto,
  ) {
    let targetVendorId = vendorId?.trim();
    const canManage = await this.canManageOrders(actor.sub, actor.role);
    let isMember =
      targetVendorId && targetVendorId !== 'my'
        ? await this.prisma.vendorMember.findUnique({
            where: { vendorId_userId: { vendorId: targetVendorId, userId: actor.sub } },
            select: { id: true, vendorId: true, branchId: true, role: true },
          })
        : null;

    if (!isMember) {
      isMember = await this.prisma.vendorMember.findFirst({
        where: { userId: actor.sub },
        select: { id: true, vendorId: true, branchId: true, role: true },
      });
      if (isMember && (!targetVendorId || targetVendorId === 'my' || !canManage)) {
        targetVendorId = isMember.vendorId;
      }
    }

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
    }

    if (!targetVendorId) {
      return { orders: [], total: 0, page: dto.page ?? 1, limit: dto.limit ?? 20, totalPages: 0 };
    }

    const effectiveBranchId =
      !canManage && isMember && isMember.role !== 'OWNER' && isMember.branchId
        ? isMember.branchId
        : undefined;

    const result = await this.ordersRepository.findMany({
      ...dto,
      vendorId: targetVendorId,
      ...(effectiveBranchId ? { branchId: effectiveBranchId } : {}),
    });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, targetVendorId, {
          canManage,
          vendorId: targetVendorId,
          memberBranchId: effectiveBranchId ?? null,
        }),
      ),
    );
    return result;
  }

  async getMyOrdersAsDriver(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const [driver, canManage, settings] = await Promise.all([
      this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true, tier: true },
      }),
      this.canManageOrders(actor.sub, actor.role),
      this.platformSettings.getSettings(),
    ]);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const result = await this.ordersRepository.findMany({ ...dto, driverId: driver.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, undefined, {
          canManage,
          driverId: driver.id,
          driverTier: driver.tier,
          settings,
        }),
      ),
    );
    return result;
  }

  async getOne(actor: JwtAccessPayload, orderId: string) {
    const order = await this.ordersRepository.findById(orderId);

    if (actor.role === Role.DRIVER_MANAGER) {
      const managed = await this.getManagedDriverIdsForUser(actor.sub);
      if (!this.isOrderAssignedToDrivers(order, managed)) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
      }
      return this.enrichWithAdminHelpers(order);
    }

    if (await this.canManageOrders(actor.sub, actor.role)) {
      return this.enrichWithAdminHelpers(order);
    }

    const [customer, driver, vendorMember] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true, tier: true },
      }),
      order.vendorId
        ? this.prisma.vendorMember.findUnique({
            where: {
              vendorId_userId: { vendorId: order.vendorId, userId: actor.sub },
            },
            select: { id: true, vendorId: true, branchId: true, role: true },
          })
        : Promise.resolve(null),
    ]);

    // A multi-vendor order has vendorId = NULL and only mirrors the FIRST
    // delivery's driver, so resolve access through the portions/groups as well:
    // otherwise every other delivery's driver and every portion vendor is
    // locked out of an order they are actively working.
    const deliveryGroups = ((order as any).deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>;

    const driverOwnsDelivery =
      !!driver &&
      (order.driverId === driver.id ||
        deliveryGroups.some(
          (g) =>
            g.primaryDriverId === driver.id || g.assistDriverId === driver.id,
        ));

    const isCustomerOwner = !!customer && order.customerId === customer.id;

    let isPortionVendorStaff = false;
    let matchingVendorId = order.vendorId ?? undefined;
    let memberBranchId: string | null = null;

    if (vendorMember) {
      const effectiveBranch =
        vendorMember.role === 'OWNER' ? null : (vendorMember.branchId ?? null);
      if (
        !effectiveBranch ||
        !(order as any).vendorBranchId ||
        (order as any).vendorBranchId === effectiveBranch
      ) {
        isPortionVendorStaff = true;
        memberBranchId = effectiveBranch;
      }
    }

    if (!isCustomerOwner && !driverOwnsDelivery && !isPortionVendorStaff) {
      const fulfillments = (((order as any).vendorFulfillments ?? []) as Array<{
        vendorId: string;
        vendorBranchId?: string | null;
      }>);
      const portionVendorIds = Array.from(
        new Set(fulfillments.map((f) => f.vendorId)),
      );
      if (portionVendorIds.length > 0) {
        const memberships = await this.prisma.vendorMember.findMany({
          where: { userId: actor.sub, vendorId: { in: portionVendorIds } },
          select: { vendorId: true, branchId: true, role: true },
        });
        const found = memberships.find((m) => {
          const effBranch = m.role === 'OWNER' ? null : (m.branchId ?? null);
          return fulfillments.some(
            (f) =>
              f.vendorId === m.vendorId &&
              (!effBranch || !f.vendorBranchId || f.vendorBranchId === effBranch),
          );
        });
        if (found) {
          isPortionVendorStaff = true;
          matchingVendorId = found.vendorId;
          memberBranchId = found.role === 'OWNER' ? null : (found.branchId ?? null);
        }
      }
    }

    const isOwner =
      isCustomerOwner || driverOwnsDelivery || isPortionVendorStaff;

    if (!isOwner) throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    return this.projectOrderForRole(order, actor, matchingVendorId, {
      driverId: driver?.id,
      driverTier: driver?.tier,
      memberBranchId,
    });
  }

  async adminFindAll(dto: QueryOrdersDto, actor?: JwtAccessPayload) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      const managedDriverIds = await this.getManagedDriverIdsForUser(actor.sub);
      if (managedDriverIds.length === 0) {
        return {
          orders: [],
          total: 0,
          page: dto.page ?? 1,
          limit: dto.limit ?? 20,
          totalPages: 0,
        };
      }
      if (dto.driverId && !managedDriverIds.includes(dto.driverId)) {
        return {
          orders: [],
          total: 0,
          page: dto.page ?? 1,
          limit: dto.limit ?? 20,
          totalPages: 0,
        };
      }
      const result = await this.ordersRepository.findMany({
        ...dto,
        driverIds: dto.driverId ? undefined : managedDriverIds,
      });
      result.orders = await Promise.all(
        result.orders.map((o: any) => this.enrichWithAdminHelpers(o)),
      );
      return result;
    }

    const result = await this.ordersRepository.findMany(dto);
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.enrichWithAdminHelpers(o)),
    );
    return result;
  }

  async getManagedDriverIdsForUser(userId: string): Promise<string[]> {
    const manager = await this.prisma.driverManager.findUnique({
      where: { userId },
      select: { id: true, manageAllDrivers: true },
    });
    if (!manager) return [];
    if (manager.manageAllDrivers) {
      const drivers = await this.prisma.driver.findMany({
        where: { deletedAt: null },
        select: { id: true },
      });
      return drivers.map((d) => d.id);
    }
    const assignments = await this.prisma.driverManagerAssignment.findMany({
      where: { driverManagerId: manager.id },
      select: { driverId: true },
    });
    return assignments.map((a) => a.driverId);
  }

  isOrderAssignedToDrivers(order: any, driverIds: string[]): boolean {
    if (!order || driverIds.length === 0) return false;
    const driverSet = new Set(driverIds);
    if (order.driverId && driverSet.has(order.driverId)) return true;
    if (order.assistDriverId && driverSet.has(order.assistDriverId)) return true;
    const deliveryGroups = (order.deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>;
    return deliveryGroups.some(
      (g) =>
        (g.primaryDriverId && driverSet.has(g.primaryDriverId)) ||
        (g.assistDriverId && driverSet.has(g.assistDriverId)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE PROJECTIONS (High-throughput in-memory data masking)
  // ═══════════════════════════════════════════════════════════════════════════

  private calculateDriverEarningsForFee(
    fee: number,
    settings: any,
    isStacked: boolean,
    isMultiVendor: boolean,
    driverTier?: string | null,
  ): number {
    let share: number;
    if (isStacked) {
      share = Number(settings?.stackedOrderDriverPercentage ?? 50) / 100;
    } else if (isMultiVendor) {
      if (settings?.multiVendorDriverPercentage != null) {
        share = Number(settings.multiVendorDriverPercentage) / 100;
      } else {
        const platformShare =
          Number(
            settings?.multiVendorDeliveryCommissionRate ??
              settings?.deliveryCommissionRate ??
              20,
          ) / 100;
        const supervisorShare =
          Number(
            settings?.multiVendorDriverManagerCommissionRate ??
              settings?.driverManagerCommissionRate ??
              10,
          ) / 100;
        share = Math.max(0, 1 - platformShare - supervisorShare);
      }
    } else {
      const platformShare = Number(settings?.deliveryCommissionRate ?? 20) / 100;
      const supervisorShare = Number(settings?.driverManagerCommissionRate ?? 10) / 100;
      share = Math.max(0, 1 - platformShare - supervisorShare);
    }

    let adjustedFee = Number(fee ?? 0);
    if (driverTier === 'BRONZE') {
      adjustedFee = Math.max(0, adjustedFee - 2);
    }
    return Math.max(0, Math.round(adjustedFee * share));
  }

  async projectOrderForRole(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: {
      canManage?: boolean;
      driverId?: string | null;
      driverTier?: string | null;
      vendorId?: string;
      memberBranchId?: string | null;
      settings?: any;
    },
  ): Promise<any> {
    if (!order) return order;

    const canManage =
      ctx?.canManage !== undefined
        ? ctx.canManage
        : await this.canManageOrders(actor.sub, actor.role);
    if (canManage) {
      return this.enrichWithAdminHelpers(order);
    }

    if (actor.role === Role.DRIVER) {
      return this.projectForDriver(order, actor, ctx);
    }

    if (actor.role === Role.VENDOR_MEMBER) {
      return this.projectForVendor(order, actor, vendorIdScope, ctx);
    }

    if (actor.role === Role.CUSTOMER) {
      return this.projectForCustomer(order);
    }

    return order;
  }

  private async projectForDriver(
    order: any,
    actor: JwtAccessPayload,
    ctx?: { driverId?: string | null; driverTier?: string | null; settings?: any },
  ): Promise<any> {
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const orderPaid =
      order.paymentStatus === 'PAID' || order.paymentStatus === 'COMPLETED';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    let cashToCollect =
      isPrepaid || orderPaid ? 0 : Math.max(0, grandTotal - upfrontAmount);

    let isStorePrepaid =
      order.vendorBranch?.isContracted ??
      order.vendor?.isContracted ??
      false;
    const subtotal = Number(order.subtotal ?? 0);
    const singleStoreCommRate = Number(
      order.vendorBranch?.commissionRate ??
      order.vendor?.commissionRate ??
      10,
    );
    const singleStoreComm = isStorePrepaid ? Math.round(subtotal * (singleStoreCommRate / 100)) : 0;
    let cashToPayStore = isStorePrepaid ? Math.max(0, subtotal - singleStoreComm) : subtotal;

    const settings = ctx?.settings ?? (await this.platformSettings.getSettings());

    let deliveryFee = Number(order.deliveryFee ?? 0);
    let projectedIsStacked = Boolean(order.isStacked);
    let projectedStatus = order.status;
    let scopedItems = order.items;
    let scopedFulfillments = order.vendorFulfillments;
    let scopedSubtotal = subtotal;
    let groupVendor = order.vendor;
    let groupVendorBranch = order.vendorBranch;
    let groupPickupLocation = order.pickupLocation;
    let groupPickupAddress = order.pickupAddress;

    const myDriver =
      ctx?.driverId !== undefined
        ? (ctx.driverId ? { id: ctx.driverId, tier: ctx.driverTier } : null)
        : await this.prisma.driver.findUnique({
            where: { userId: actor.sub },
            select: { id: true, tier: true },
          });

    const allGroups: any[] = Array.isArray(order.deliveryGroups)
      ? order.deliveryGroups
      : [];

    // A driver only ever sees the deliveries assigned to them. On a multi-vendor
    // order the deliveries are independent, so echoing every group let a driver
    // see other drivers' routes and could leave the app stuck on a group that
    // was already completed.
    const myGroups: any[] = myDriver
      ? allGroups
          .filter(
            (g: any) =>
              g.primaryDriverId === myDriver.id ||
              g.assistDriverId === myDriver.id ||
              (order.driverId === myDriver.id && !g.primaryDriverId),
          )
          .sort(
            (a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
          )
      : [];

    const liveGroups = myGroups.filter((g: any) => g.status !== 'CANCELLED');
    const activeMyGroups = liveGroups.filter(
      (g: any) => g.status !== 'DELIVERED',
    );
    // The driver works one delivery at a time. Once a group is delivered the
    // projection moves to the next active group of the same order, so the
    // client can advance automatically instead of leaving the order.
    const currentGroup: any | null = activeMyGroups[0] ?? null;
    const currentDeliveryGroupId: string | null = currentGroup?.id ?? null;
    let customDriverEarnings: number | null = null;

    if (myGroups.length > 0) {
      const orderHasGroupItems = allGroups.some(
        (g: any) => Array.isArray(g.items) && g.items.length > 0,
      );

      if (!currentGroup) {
        // Every delivery assigned to this driver is finished. The order itself
        // may still be live for other drivers, so report this driver's work as
        // done and send no stores/items back — the app then stops showing it as
        // active work instead of leaving the driver on a dead delivery.
        projectedStatus = 'DELIVERED';
        scopedItems = [];
        scopedFulfillments = [];
        scopedSubtotal = 0;
        deliveryFee = 0;
        projectedIsStacked = false;
        customDriverEarnings = 0;
        cashToCollect = 0;
        cashToPayStore = 0;
        isStorePrepaid = false;
      } else {
        const groupItems = (
          Array.isArray(currentGroup.items) ? currentGroup.items : []
        )
          .slice()
          .sort(
            (a: any, b: any) =>
              Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
          );
        const myFulfillmentIds = new Set<string>(
          groupItems
            .map((it: any) => it.fulfillmentId)
            .filter((id: any): id is string => Boolean(id)),
        );
        const allFulfillments: any[] = Array.isArray(order.vendorFulfillments)
          ? order.vendorFulfillments
          : [];

        let myFulfillments = allFulfillments.filter(
          (f: any) =>
            myFulfillmentIds.has(f.id) &&
            f.status !== 'REJECTED' &&
            f.status !== 'CANCELLED',
        );
        // Very old orders can have groups without item links. Only then fall
        // back to every live portion; once links exist, anything outside this
        // group belongs to another delivery and must not leak into this one.
        if (myFulfillments.length === 0 && !orderHasGroupItems) {
          myFulfillments = allFulfillments.filter(
            (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
          );
        }

        const sequenceByFulfillment = new Map<string, number>();
        for (const it of groupItems) {
          if (!it?.fulfillmentId || sequenceByFulfillment.has(it.fulfillmentId)) {
            continue;
          }
          sequenceByFulfillment.set(
            it.fulfillmentId,
            Number(it.sequence ?? 0),
          );
        }
        myFulfillments.sort(
          (a: any, b: any) =>
            (sequenceByFulfillment.get(a.id) ?? 0) -
            (sequenceByFulfillment.get(b.id) ?? 0),
        );

        scopedFulfillments = myFulfillments;

        // Items are strictly scoped to this delivery's portions. Rejected
        // lines are audit rows and never part of the driver's work.
        scopedItems = (Array.isArray(order.items) ? order.items : []).filter(
          (i: any) => {
            if (i.rejectedAt != null) return false;
            if (myFulfillmentIds.size > 0) {
              return i.fulfillmentId != null && myFulfillmentIds.has(i.fulfillmentId);
            }
            // Legacy order with no group links at all: no scoping information
            // exists, so keep the historical behaviour.
            return !orderHasGroupItems;
          },
        );

        // Group state is the authority on dispatch progress. The portions refine
        // it while the driver is collecting the goods.
        const isPicked = (f: any) =>
          Boolean(f.pickedUpAt) ||
          f.status === 'PICKED_UP' ||
          f.status === 'DELIVERED';
        const anyPicked = myFulfillments.some(isPicked);
        const allPicked =
          myFulfillments.length > 0 && myFulfillments.every(isPicked);
        if (currentGroup.status === 'PENDING_PAYMENT') {
          projectedStatus = 'PENDING_PAYMENT';
        } else if (allPicked) {
          projectedStatus = 'PICKED_UP';
        } else if (anyPicked) {
          projectedStatus = 'PARTIALLY_PICKED_UP';
        } else {
          projectedStatus = String(currentGroup.status ?? order.status);
        }

        deliveryFee = Number(currentGroup.deliveryFee ?? 0);
        projectedIsStacked = Boolean(currentGroup.isStacked);
        const isMultiVendorOrder = allGroups.length > 1;
        customDriverEarnings = this.calculateDriverEarningsForFee(
          deliveryFee,
          settings,
          projectedIsStacked,
          isMultiVendorOrder,
          myDriver?.tier,
        );

        cashToPayStore = 0;
        let groupSubtotal = 0;
        let allContracted = myFulfillments.length > 0;
        for (const f of myFulfillments) {
          f.isContracted =
            f.vendorBranch?.isContracted ?? f.vendor?.isContracted ?? false;
          const commRate = Number(
            f.commissionRate ??
              f.vendorBranch?.commissionRate ??
              f.vendor?.commissionRate ??
              10,
          );
          f.commissionRate = commRate;
          const sub = Number(f.subtotal ?? 0);
          const comm = f.isContracted ? Math.round(sub * (commRate / 100)) : 0;
          f.commissionAmount = comm;
          f.cashToPay = f.isContracted ? Math.max(0, sub - comm) : sub;
          groupSubtotal += sub;
          cashToPayStore += Number(f.cashToPay ?? 0);
          if (!f.isContracted) allContracted = false;
        }
        scopedSubtotal = groupSubtotal;
        if (myFulfillments.length > 0) {
          isStorePrepaid = allContracted;
        }

        // Order-level extras (service fee, tax, discount, deposit) are charged
        // exactly once, on the first delivery of the whole order — never again
        // when the same driver moves on to a later group.
        const activeWholeGroups = allGroups.filter(
          (g: any) => g.status !== 'CANCELLED',
        );
        const firstGroupSequence = Math.min(
          ...(activeWholeGroups.length > 0 ? activeWholeGroups : allGroups).map(
            (g: any) => Number(g.sequence ?? 0),
          ),
        );
        const isFirstGroup =
          Number(currentGroup.sequence ?? 0) === firstGroupSequence;
        const orderLevelExtras = isFirstGroup
          ? Number(order.serviceFee ?? 0) +
            Number(order.tax ?? 0) +
            Number(order.driverBonusFee ?? 0) -
            Number(order.discount ?? 0) -
            upfrontAmount
          : 0;
        cashToCollect =
          isPrepaid || orderPaid
            ? 0
            : Math.max(0, groupSubtotal + deliveryFee + orderLevelExtras);

        const firstFulfillment = myFulfillments[0];
        if (firstFulfillment) {
          if (!groupVendor && firstFulfillment.vendor) {
            groupVendor = firstFulfillment.vendor;
          }
          if (!groupVendorBranch && firstFulfillment.vendorBranch) {
            groupVendorBranch = firstFulfillment.vendorBranch;
          }
          if (!groupPickupLocation && firstFulfillment.vendorBranch?.location) {
            groupPickupLocation = firstFulfillment.vendorBranch.location;
          }
          if (!groupPickupAddress && firstFulfillment.vendorBranch?.address) {
            groupPickupAddress = firstFulfillment.vendorBranch.address;
          }
        }
      }
    }

    // Whoever owns the delivery being worked is the collector for that
    // delivery. For a group-less legacy order this is the order's own driver.
    const isPrimaryCollector = Boolean(
      myDriver?.id &&
        (currentGroup
          ? currentGroup.primaryDriverId
            ? currentGroup.primaryDriverId === myDriver.id
            : order.driverId === myDriver.id
          : myGroups.length === 0 && order.driverId === myDriver.id),
    );

    const isMultiVendor = allGroups.length > 1;
    const driverEarnings =
      customDriverEarnings ??
      this.calculateDriverEarningsForFee(
        deliveryFee,
        settings,
        projectedIsStacked,
        isMultiVendor,
        myDriver?.tier,
      );

    const storePayments =
      scopedFulfillments && scopedFulfillments.length > 0
        ? scopedFulfillments.map((f: any) => {
            const contracted =
              f.vendorBranch?.isContracted ?? f.vendor?.isContracted ?? false;
            const commRate = Number(
              f.commissionRate ??
                f.vendorBranch?.commissionRate ??
                f.vendor?.commissionRate ??
                10,
            );
            const sub = Number(f.subtotal ?? 0);
            const comm = contracted ? Math.round(sub * (commRate / 100)) : 0;
            const toPay = contracted ? Math.max(0, sub - comm) : sub;
            return {
              fulfillmentId: f.id,
              vendorId: f.vendorId,
              vendorName:
                f.vendor?.storeNameAr ??
                f.vendor?.storeName ??
                f.vendor?.name ??
                'Store',
              branchName: f.vendorBranch?.nameAr ?? f.vendorBranch?.name ?? '',
              address: f.vendorBranch?.address ?? f.vendor?.address ?? '',
              phone:
                f.vendorBranch?.phone ??
                f.vendor?.phone ??
                f.vendor?.user?.phone ??
                '',
              subtotal: sub,
              isContracted: contracted,
              commissionRate: commRate,
              commissionAmount: comm,
              cashToPay: toPay,
              pickedUpAt: f.pickedUpAt ?? null,
              pickupImageUrl: f.pickupImageUrl ?? null,
            };
          })
        : myGroups.length === 0
          ? [
              {
                vendorId: order.vendorId,
                vendorName:
                  order.vendor?.storeNameAr ??
                  order.vendor?.storeName ??
                  order.vendor?.name ??
                  'Store',
                branchName:
                  order.vendorBranch?.nameAr ?? order.vendorBranch?.name ?? '',
                address: order.vendorBranch?.address ?? order.vendor?.address ?? '',
                phone:
                  order.vendorBranch?.phone ??
                  order.vendor?.phone ??
                  order.vendor?.user?.phone ??
                  '',
                subtotal: subtotal,
                isContracted: isStorePrepaid,
                commissionRate: singleStoreCommRate,
                commissionAmount: singleStoreComm,
                cashToPay: cashToPayStore,
                pickedUpAt: order.pickedUpAt ?? null,
                pickupImageUrl: order.pickupImageUrl ?? null,
              },
            ]
          : [];

    return {
      ...order,
      driverEarnings,
      deliveryFee,
      subtotal: scopedSubtotal,
      isPrimaryCollector,
      status: projectedStatus,
      isStacked: projectedIsStacked,
      vendor: groupVendor,
      vendorBranch: groupVendorBranch,
      pickupLocation: groupPickupLocation,
      pickupAddress: groupPickupAddress,
      items: scopedItems,
      vendorFulfillments: scopedFulfillments,
      // Only this driver's deliveries, plus the one they are working now, so
      // the app can advance group by group without guessing.
      deliveryGroups: myGroups,
      currentDeliveryGroupId,
      grandTotal: cashToCollect,
      total: cashToCollect,
      cashToCollect,
      upfrontAmount: 0,
      serviceFee: 0,
      tax: 0,
      discount: 0,
      financials: {
        viewRole: 'DRIVER',
        isPrimaryCollector,
        cashToCollect,
        isPrepaid: isPrepaid || orderPaid,
        cashToPayStore,
        isStorePrepaid,
        driverEarnings,
        deliveryFee,
        storePayments,
      },
    };
  }

  private async projectForVendor(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: { vendorId?: string; memberBranchId?: string | null },
  ): Promise<any> {
    let vendorId = vendorIdScope ?? ctx?.vendorId;
    let memberBranchId: string | null = ctx?.memberBranchId ?? null;
    if (actor.role === Role.VENDOR_MEMBER && ctx?.memberBranchId === undefined) {
      const membership = await this.prisma.vendorMember.findFirst({
        where: {
          userId: actor.sub,
          ...(vendorId ? { vendorId } : {}),
        },
        select: { vendorId: true, branchId: true, role: true },
      });
      if (!vendorId) {
        vendorId = order.vendorId ?? membership?.vendorId;
      }
      memberBranchId =
        membership?.role === 'OWNER' ? null : (membership?.branchId ?? null);
    } else if (!vendorId && order.vendorId) {
      vendorId = order.vendorId;
    }

    let items = order.items ?? [];
    let vendorSubtotal = Number(order.subtotal ?? 0);
    let commissionRate = Number(
      order.vendorBranch?.commissionRate ??
      order.vendor?.commissionRate ??
      10,
    );
    let isContracted =
      order.vendorBranch?.isContracted ??
      order.vendor?.isContracted ??
      false;

    // Multi-vendor orders are split into portions, and each portion has its own
    // production state. `status` is therefore re-projected to the caller's own
    // portion so the vendor app's tabs, counters and action buttons describe
    // THIS vendor's work instead of the aggregate order (which may already be
    // preparing/delivering because of another vendor).
    let portionStatus: string | null = null;
    let myFulfillmentId: string | null = null;

    if (order.vendorFulfillments && Array.isArray(order.vendorFulfillments) && vendorId) {
      const vendorFulfillments = order.vendorFulfillments.filter(
        (f: any) =>
          f.vendorId === vendorId &&
          (!memberBranchId || !f.vendorBranchId || f.vendorBranchId === memberBranchId),
      );
      // If a global owner has multiple branch fulfillments on the same order,
      // prefer the least-progressed active fulfillment for status/action projection.
      const statusRank: Record<string, number> = {
        PENDING: 1,
        ACCEPTED: 2,
        PREPARING: 3,
        READY_FOR_PICKUP: 4,
        PICKED_UP: 5,
        DELIVERED: 6,
        CANCELLED: 7,
        REJECTED: 7,
      };
      const sortedFulfillments = [...vendorFulfillments].sort(
        (a: any, b: any) =>
          (statusRank[String(a.status)] ?? 99) -
          (statusRank[String(b.status)] ?? 99),
      );
      const myFulfillment = sortedFulfillments[0];
      if (myFulfillment) {
        myFulfillmentId = myFulfillment.id ?? null;

        const aggregateStatus = String(order.status ?? 'PENDING');
        const rawPortionStatus = String(myFulfillment.status ?? 'PENDING');
        const isDeadPortion =
          rawPortionStatus === 'REJECTED' || rawPortionStatus === 'CANCELLED';

        // The delivery that carries this portion is the authority on dispatch
        // progress (driver assigned / payment pending / driver collected), so
        // its state feeds the portion status too.
        const groupForPortion = (order.deliveryGroups ?? []).find((g: any) =>
          (g.items ?? []).some(
            (it: any) => it.fulfillmentId === myFulfillment.id,
          ),
        );
        const groupStatus = groupForPortion?.status
          ? String(groupForPortion.status)
          : null;

        if (isDeadPortion) {
          portionStatus = 'CANCELLED';
        } else if (
          myFulfillment.deliveredAt ||
          aggregateStatus === 'DELIVERED' ||
          groupStatus === 'DELIVERED'
        ) {
          portionStatus = 'DELIVERED';
        } else if (
          myFulfillment.pickedUpAt ||
          myFulfillment.status === 'PICKED_UP' ||
          aggregateStatus === 'PICKED_UP' ||
          groupStatus === 'PICKED_UP'
        ) {
          // The goods are with a driver; only this vendor's delivery matters.
          portionStatus = 'PICKED_UP';
        } else if (
          myFulfillment.readyAt ||
          groupStatus === 'READY_FOR_PICKUP'
        ) {
          portionStatus = 'READY_FOR_PICKUP';
        } else if (myFulfillment.preparingAt) {
          portionStatus = 'PREPARING';
        } else if (
          groupStatus === 'DRIVER_ASSIGNED' ||
          groupStatus === 'PENDING_PAYMENT'
        ) {
          // A driver is committed to this delivery, so the vendor can start
          // preparing even though the aggregate is still LOOKING_FOR_DRIVER
          // while another delivery waits for its own driver.
          portionStatus = groupStatus;
        } else {
          portionStatus = rawPortionStatus;
        }

        vendorSubtotal = vendorFulfillments.reduce(
          (sum: number, f: any) => sum + Number(f.subtotal ?? 0),
          0,
        );
        commissionRate = Number(myFulfillment.commissionRate ?? commissionRate);
        if (myFulfillment.vendorBranch?.isContracted != null) {
          isContracted = myFulfillment.vendorBranch.isContracted;
        }
        const myFulfillmentIds = new Set(vendorFulfillments.map((f: any) => f.id));
        const directItems = vendorFulfillments.flatMap((f: any) =>
          Array.isArray(f.items) ? f.items : [],
        );
        // Only include items that belong to this vendor's fulfillments.
        // Items without a fulfillmentId are legacy rows: accepting them would
        // leak every other store's lines into this vendor's portion.
        const fallbackItems = (
          Array.isArray(order.items) ? order.items : []
        ).filter(
          (i: any) =>
            i.rejectedAt == null &&
            i.fulfillmentId != null &&
            myFulfillmentIds.has(i.fulfillmentId),
        );
        items = directItems.length > 0 ? directItems : fallbackItems;
      }
    }

    const commissionAmount = isContracted
      ? Math.round(vendorSubtotal * (commissionRate / 100))
      : 0;
    const netPayout = isContracted
      ? Math.max(0, vendorSubtotal - commissionAmount)
      : vendorSubtotal;

    // Strict Vendor & Branch Isolation: Only expose the vendor's own fulfillment
    // (and if branch-scoped, only that branch's fulfillment), plus the delivery
    // that actually carries it. Other stores, their routes and their drivers
    // must never leak into a vendor's response.
    const myFulfillmentOnly = (order.vendorFulfillments ?? []).filter(
      (f: any) =>
        f.vendorId === vendorId &&
        (!memberBranchId || !f.vendorBranchId || f.vendorBranchId === memberBranchId),
    );
    const primaryFulfillment =
      myFulfillmentOnly[0] ??
      order.vendorFulfillments?.find((f: any) => f.vendorId === vendorId);

    const myFulfillmentIdSet = new Set(
      myFulfillmentOnly.map((f: any) => f.id),
    );
    const myDeliveryGroups = (order.deliveryGroups ?? [])
      .filter((g: any) =>
        (Array.isArray(g.items) ? g.items : []).some(
          (it: any) =>
            it?.fulfillmentId && myFulfillmentIdSet.has(it.fulfillmentId),
        ),
      )
      .map((g: any) => ({
        id: g.id,
        sequence: g.sequence,
        status: g.status,
        estimatedPrepTime: g.estimatedPrepTime ?? null,
        primaryDriverId: g.primaryDriverId ?? null,
        assistDriverId: g.assistDriverId ?? null,
        items: (Array.isArray(g.items) ? g.items : [])
          .filter(
            (it: any) =>
              it?.fulfillmentId && myFulfillmentIdSet.has(it.fulfillmentId),
          )
          .map((it: any) => ({
            fulfillmentId: it.fulfillmentId,
            sequence: it.sequence ?? 0,
          })),
      }));

    return {
      ...order,
      vendorId: vendorId ?? order.vendorId,
      vendorBranchId: primaryFulfillment?.vendorBranchId ?? order.vendorBranchId,
      // The caller's own portion drives the vendor-facing status; the raw
      // aggregate stays available as `orderStatus`.
      status: portionStatus ?? order.status,
      orderStatus: order.status,
      isMultiVendor:
        (order.vendorFulfillments?.length ?? 0) > 1 ||
        (order.deliveryGroups?.length ?? 0) > 1,
      myFulfillmentId,
      myFulfillmentStatus: portionStatus,
      items,
      subtotal: vendorSubtotal,
      deliveryFee: 0,
      serviceFee: 0,
      tax: 0,
      driverBonusFee: 0,
      discount: 0,
      grandTotal: vendorSubtotal,
      total: vendorSubtotal,
      vendorFulfillments: myFulfillmentOnly,
      deliveryGroups: myDeliveryGroups,
      vendor: primaryFulfillment?.vendor ?? order.vendor,
      vendorBranch: primaryFulfillment?.vendorBranch ?? order.vendorBranch,
      financials: {
        viewRole: 'VENDOR',
        storeSubtotal: vendorSubtotal,
        commissionRate,
        commissionAmount,
        netPayout,
        cashToCollectFromDriver: netPayout,
        isContracted,
        payoutMethod: isContracted ? 'WALLET_SETTLEMENT' : 'CASH_FROM_DRIVER',
      },
    };
  }

  private projectForCustomer(order: any): any {
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    const cashToPayAtDoor = isPrepaid ? 0 : Math.max(0, grandTotal - upfrontAmount);

    const sanitized = { ...order };
    // Rejected portion items are kept in the database for audit but must not
    // reappear as part of the customer's order (totals already exclude them).
    if (Array.isArray(sanitized.items)) {
      sanitized.items = sanitized.items.filter(
        (i: any) => i.rejectedAt == null,
      );
    }
    if (sanitized.vendor) {
      const { commissionRate, walletBalance, ...safeVendor } = sanitized.vendor;
      sanitized.vendor = safeVendor;
    }
    if (sanitized.vendorBranch) {
      const { commissionRate, ...safeBranch } = sanitized.vendorBranch;
      sanitized.vendorBranch = safeBranch;
    }
    let fulfillmentSummary: any = null;
    if (sanitized.vendorFulfillments) {
      const allGroupItems = (order.deliveryGroups ?? []).flatMap((g: any) =>
        Array.isArray(g.items) ? g.items : [],
      );

      sanitized.vendorFulfillments = sanitized.vendorFulfillments.map((f: any) => {
        const { commissionRate, ...safeF } = f;
        const stage =
          f.status === 'REJECTED' || f.status === 'CANCELLED'
            ? f.status
            : f.pickedUpAt || f.status === 'PICKED_UP'
              ? 'PICKED_UP'
              : f.readyAt || f.status === 'READY_FOR_PICKUP'
                ? 'READY_FOR_PICKUP'
                : f.preparingAt || f.status === 'PREPARING'
                  ? 'PREPARING'
                  : f.status;
        return {
          ...safeF,
          stage,
        };
      });

      sanitized.vendorFulfillments.sort((a: any, b: any) => {
        const seqA = allGroupItems.find((it: any) => it.fulfillmentId === a.id)?.sequence ?? 0;
        const seqB = allGroupItems.find((it: any) => it.fulfillmentId === b.id)?.sequence ?? 0;
        return seqA - seqB;
      });

      const liveFulfillments = sanitized.vendorFulfillments.filter(
        (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
      );
      const activeFulfillment = liveFulfillments.find(
        (f: any) => !f.pickedUpAt && f.status !== 'PICKED_UP',
      );
      const totalStops = liveFulfillments.length;
      const completedStops = liveFulfillments.filter(
        (f: any) => Boolean(f.pickedUpAt) || f.status === 'PICKED_UP',
      ).length;

      fulfillmentSummary = {
        totalStops,
        completedStops,
        currentStopSequence: activeFulfillment
          ? allGroupItems.find((it: any) => it.fulfillmentId === activeFulfillment.id)?.sequence ?? 1
          : totalStops,
        currentStopBranchName:
          activeFulfillment?.vendorBranch?.nameAr ??
          activeFulfillment?.vendorBranch?.name ??
          activeFulfillment?.vendor?.storeNameAr ??
          activeFulfillment?.vendor?.storeName ??
          null,
        isFullyCollected: completedStops >= totalStops,
      };

      // Only a single-portion order may borrow its portion's vendor as the
      // order-level vendor. A real multi-vendor order keeps `vendor` null so
      // clients render every portion's store instead of just the first one.
      if (!sanitized.vendor && sanitized.vendorFulfillments.length === 1) {
        sanitized.vendor = sanitized.vendorFulfillments[0].vendor;
        if (!sanitized.vendorBranch && sanitized.vendorFulfillments[0].vendorBranch) {
          sanitized.vendorBranch = sanitized.vendorFulfillments[0].vendorBranch;
        }
      }
    }

    return {
      ...sanitized,
      fulfillmentSummary,
      financials: {
        viewRole: 'CUSTOMER',
        cashToPayAtDoor,
        isPrepaid,
      },
    };
  }

  private async enrichWithAdminHelpers(order: any): Promise<any> {
    if (!order) return order;
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    const cashToCollect = isPrepaid ? 0 : Math.max(0, grandTotal - upfrontAmount);

    const isStorePrepaid =
      order.vendorBranch?.isContracted ??
      order.vendor?.isContracted ??
      false;
    const subtotal = Number(order.subtotal ?? 0);
    const cashToPayStore = isStorePrepaid ? 0 : subtotal;

    const settings = await this.platformSettings.getSettings();
    const deliveryFee = Number(order.deliveryFee ?? 0);
    const isMultiVendor = Boolean(order.deliveryGroups && order.deliveryGroups.length > 1);
    const driverEarnings = this.calculateDriverEarningsForFee(
      deliveryFee,
      settings,
      Boolean(order.isStacked),
      isMultiVendor,
    );

    // A super admin must see EVERYTHING about an order, including lines a
    // vendor has already rejected. The order queries filter rejected items out
    // of each portion (correct for vendors/customers), so merge each portion's
    // items back from the order's own full item list — never leave an admin
    // staring at a portion with no items.
    const allOrderItems: any[] = Array.isArray(order.items) ? order.items : [];
    const rawFulfillments = Array.isArray(order.vendorFulfillments)
      ? order.vendorFulfillments
      : [];
    const fulfillments = rawFulfillments.map((f: any) => {
      const ownItems = allOrderItems.filter(
        (i: any) => i.fulfillmentId === f.id,
      );
      if (ownItems.length === 0) return f;
      const byId = new Map<string, any>();
      for (const item of Array.isArray(f.items) ? f.items : []) {
        byId.set(item.id ?? `${item.productId}-${item.productName}`, item);
      }
      for (const item of ownItems) {
        byId.set(item.id ?? `${item.productId}-${item.productName}`, item);
      }
      return { ...f, items: [...byId.values()] };
    });
    const isMultiVendorOrder = Boolean(
      order.isMultiVendor ||
      fulfillments.length > 1 ||
      (order.deliveryGroups && order.deliveryGroups.length > 1),
    );

    let vendor = order.vendor;
    let vendorBranch = order.vendorBranch;
    let resolvedIsStorePrepaid = isStorePrepaid;
    let resolvedCashToPayStore = cashToPayStore;

    const storePayments = fulfillments.map((f: any) => {
      const contracted = f.vendorBranch?.isContracted ?? f.vendor?.isContracted ?? false;
      const commRate = Number(
        f.commissionRate ??
        f.vendorBranch?.commissionRate ??
        f.vendor?.commissionRate ??
        10,
      );
      const sub = Number(f.subtotal ?? 0);
      const comm = contracted ? Math.round(sub * (commRate / 100)) : 0;
      const toPay = contracted ? Math.max(0, sub - comm) : sub;
      return {
        fulfillmentId: f.id,
        vendorId: f.vendorId,
        vendorName: f.vendor?.storeNameAr ?? f.vendor?.storeName ?? f.vendor?.name ?? 'Store',
        vendorNameEn: f.vendor?.storeName ?? f.vendor?.storeNameAr ?? f.vendor?.name ?? 'Store',
        branchName: f.vendorBranch?.nameAr ?? f.vendorBranch?.name ?? '',
        address: f.vendorBranch?.address ?? f.vendor?.address ?? '',
        phone: f.vendorBranch?.phone ?? f.vendor?.phone ?? f.vendor?.user?.phone ?? '',
        subtotal: sub,
        isContracted: contracted,
        commissionRate: commRate,
        commissionAmount: comm,
        cashToPay: toPay,
        status: f.status,
        pickedUpAt: f.pickedUpAt ?? null,
      };
    });

    if (isMultiVendorOrder && fulfillments.length > 1) {
      const storeNamesAr = fulfillments
        .map((f: any) => f.vendor?.storeNameAr ?? f.vendor?.storeName ?? f.vendor?.name)
        .filter(Boolean);
      const storeNamesEn = fulfillments
        .map((f: any) => f.vendor?.storeName ?? f.vendor?.storeNameAr ?? f.vendor?.name)
        .filter(Boolean);

      vendor = {
        id: 'multi-vendor',
        isMultiVendor: true,
        storeName: storeNamesEn.join(' + ') || 'Multi-Vendor',
        storeNameAr: storeNamesAr.join(' + ') || 'طلب متعدد المتاجر',
        logo: null,
      };
      vendorBranch = null;

      if (storePayments.length > 0) {
        resolvedCashToPayStore = storePayments.reduce((sum: number, sp: any) => sum + sp.cashToPay, 0);
        resolvedIsStorePrepaid = storePayments.every((sp: any) => sp.isContracted);
      }
    } else if (!vendor && fulfillments.length === 1) {
      vendor = fulfillments[0].vendor;
      vendorBranch ??= fulfillments[0].vendorBranch;
      if (storePayments.length === 1) {
        resolvedCashToPayStore = storePayments[0].cashToPay;
        resolvedIsStorePrepaid = storePayments[0].isContracted;
      }
    }

    return {
      ...order,
      isMultiVendor: isMultiVendorOrder,
      // The admin view carries every portion with its complete item list.
      vendorFulfillments: fulfillments,
      driverEarnings,
      deliveryFee,
      vendor,
      vendorBranch,
      financials: {
        viewRole: 'ADMIN',
        cashToCollect,
        isPrepaid,
        cashToPayStore: resolvedCashToPayStore,
        isStorePrepaid: resolvedIsStorePrepaid,
        driverEarnings,
        deliveryFee,
        storePayments,
      },
    };
  }

  private async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.DRIVER_MANAGER) {
      return false;
    }
    if (role === Role.SUPER_ADMIN || role === Role.ADMIN) {
      return true;
    }
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!(
      user?.permissions.includes(Permission.MANAGE_ORDERS) ||
      user?.permissions.includes(Permission.MANAGE_VENDORS)
    );
  }
}
