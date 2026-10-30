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
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!customer)
      return { orders: [], total: 0, page: 1, limit: 20, totalPages: 0 };
    const result = await this.ordersRepository.findMany({ ...dto, customerId: customer.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.projectOrderForRole(o, actor)),
    );
    return result;
  }

  async getVendorOrders(
    actor: JwtAccessPayload,
    vendorId: string,
    dto: QueryOrdersDto,
  ) {
    const [isMember, canManage] = await Promise.all([
      this.prisma.vendorMember.findUnique({
        where: { vendorId_userId: { vendorId, userId: actor.sub } },
        select: { id: true },
      }),
      this.canManageOrders(actor.sub, actor.role),
    ]);

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
    }

    const result = await this.ordersRepository.findMany({ ...dto, vendorId });
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.projectOrderForRole(o, actor, vendorId)),
    );
    return result;
  }

  async getMyOrdersAsDriver(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const result = await this.ordersRepository.findMany({ ...dto, driverId: driver.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.projectOrderForRole(o, actor)),
    );
    return result;
  }

  async getOne(actor: JwtAccessPayload, orderId: string) {
    const order = await this.ordersRepository.findById(orderId);

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
        select: { id: true },
      }),
      order.vendorId
        ? this.prisma.vendorMember.findUnique({
            where: {
              vendorId_userId: { vendorId: order.vendorId, userId: actor.sub },
            },
            select: { id: true },
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

    let isPortionVendorStaff = !!vendorMember;
    let matchingVendorId = order.vendorId ?? undefined;
    if (!isCustomerOwner && !driverOwnsDelivery && !isPortionVendorStaff) {
      const portionVendorIds = Array.from(
        new Set(
          (((order as any).vendorFulfillments ?? []) as Array<{
            vendorId: string;
          }>).map((f) => f.vendorId),
        ),
      );
      if (portionVendorIds.length > 0) {
        const found = await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub, vendorId: { in: portionVendorIds } },
          select: { vendorId: true },
        });
        if (found) {
          isPortionVendorStaff = true;
          matchingVendorId = found.vendorId;
        }
      }
    }

    const isOwner =
      isCustomerOwner || driverOwnsDelivery || isPortionVendorStaff;

    if (!isOwner) throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    return this.projectOrderForRole(order, actor, matchingVendorId);
  }

  async adminFindAll(dto: QueryOrdersDto) {
    const result = await this.ordersRepository.findMany(dto);
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.enrichWithAdminHelpers(o)),
    );
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE PROJECTIONS (High-throughput in-memory data masking)
  // ═══════════════════════════════════════════════════════════════════════════

  async projectOrderForRole(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
  ): Promise<any> {
    if (!order) return order;

    if (await this.canManageOrders(actor.sub, actor.role)) {
      return this.enrichWithAdminHelpers(order);
    }

    if (actor.role === Role.DRIVER) {
      return this.projectForDriver(order, actor);
    }

    if (actor.role === Role.VENDOR_MEMBER) {
      return this.projectForVendor(order, actor, vendorIdScope);
    }

    if (actor.role === Role.CUSTOMER) {
      return this.projectForCustomer(order);
    }

    return order;
  }

  private async projectForDriver(order: any, actor: JwtAccessPayload): Promise<any> {
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
    let subtotal = Number(order.subtotal ?? 0);
    const singleStoreCommRate = Number(
      order.vendorBranch?.commissionRate ??
      order.vendor?.commissionRate ??
      10,
    );
    const singleStoreComm = isStorePrepaid ? Math.round(subtotal * (singleStoreCommRate / 100)) : 0;
    let cashToPayStore = isStorePrepaid ? Math.max(0, subtotal - singleStoreComm) : subtotal;

    const settings = await this.platformSettings.getSettings();
    const rate = Number(settings?.deliveryCommissionRate ?? 20);

    let deliveryFee = Number(order.deliveryFee ?? 0);
    let groupVendor = order.vendor;
    let groupVendorBranch = order.vendorBranch;
    let groupPickupLocation = order.pickupLocation;
    let groupPickupAddress = order.pickupAddress;
    let projectedStatus = order.status;
    let scopedItems = order.items;
    let scopedFulfillments = order.vendorFulfillments;

    if (order.deliveryGroups && Array.isArray(order.deliveryGroups)) {
      const myDriver = await this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      });
      if (myDriver) {
        // Collect all groups assigned to this driver (or if the driver is assigned at order level, all groups)
        const myGroups = order.deliveryGroups.filter(
          (g: any) =>
            g.primaryDriverId === myDriver.id ||
            g.assistDriverId === myDriver.id ||
            (order.driverId === myDriver.id && !g.primaryDriverId),
        );

        if (myGroups.length > 0) {
          const anyPendingPayment = myGroups.some((g: any) => g.status === 'PENDING_PAYMENT');
          const allDelivered = myGroups.every((g: any) => g.status === 'DELIVERED');
          const allPickedUp = myGroups.every((g: any) => g.status === 'PICKED_UP' || g.status === 'DELIVERED');
          const allReady = myGroups.every((g: any) => g.status === 'READY_FOR_PICKUP' || g.status === 'PICKED_UP' || g.status === 'DELIVERED');

          if (anyPendingPayment) {
            projectedStatus = 'PENDING_PAYMENT';
          } else if (allDelivered) {
            projectedStatus = 'DELIVERED';
          } else if (allPickedUp) {
            projectedStatus = 'PICKED_UP';
          } else if (allReady) {
            projectedStatus = 'READY_FOR_PICKUP';
          } else if (myGroups.some((g: any) => g.status === 'DRIVER_ASSIGNED')) {
            projectedStatus = 'DRIVER_ASSIGNED';
          } else {
            projectedStatus = myGroups[0].status ?? order.status;
          }

          deliveryFee = myGroups.reduce(
            (sum: number, g: any) => sum + (g.deliveryFee != null ? Number(g.deliveryFee) : 0),
            0,
          );

          const allGroupItems = myGroups.flatMap((g: any) =>
            Array.isArray(g.items) ? g.items : [],
          );

          if (order.vendorFulfillments) {
            const fulfillmentIds = new Set(allGroupItems.map((it: any) => it.fulfillmentId));
            const myFulfillments = (order.vendorFulfillments as any[]).filter((f) =>
              fulfillmentIds.size === 0 ? true : fulfillmentIds.has(f.id),
            );

            myFulfillments.sort((a, b) => {
              const seqA = allGroupItems.find((it: any) => it.fulfillmentId === a.id)?.sequence ?? 0;
              const seqB = allGroupItems.find((it: any) => it.fulfillmentId === b.id)?.sequence ?? 0;
              return seqA - seqB;
            });

            for (const f of myFulfillments) {
              f.isContracted = f.vendorBranch?.isContracted ?? f.vendor?.isContracted ?? false;
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
            }
            scopedFulfillments = myFulfillments;

            if (Array.isArray(order.items)) {
              scopedItems = order.items.filter(
                (i: any) =>
                  i.rejectedAt == null &&
                  (!i.fulfillmentId || fulfillmentIds.size === 0 || fulfillmentIds.has(i.fulfillmentId)),
              );
            }

            cashToPayStore = 0;
            let allContracted = myFulfillments.length > 0;
            let groupSubtotal = 0;
            for (const f of myFulfillments) {
              groupSubtotal += Number(f.subtotal ?? 0);
              cashToPayStore += Number(f.cashToPay ?? 0);
              if (!f.isContracted) allContracted = false;
            }
            isStorePrepaid = allContracted;

            // Total cash to collect at door: sum of all assigned stores' goods + total delivery fee - upfront
            const firstSequence = Math.min(
              ...order.deliveryGroups.map((g: any) => Number(g.sequence ?? 0)),
            );
            const isFirstGroup = myGroups.some((g: any) => Number(g.sequence ?? 0) === firstSequence);
            cashToCollect =
              isPrepaid || orderPaid
                ? 0
                : Math.max(
                    0,
                    groupSubtotal +
                      deliveryFee -
                      (isFirstGroup ? upfrontAmount : 0),
                  );

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
      }
    }
    const driverEarnings = Math.max(0, Math.round(deliveryFee * (1 - rate / 100)));

    return {
      ...order,
      status: projectedStatus,
      vendor: groupVendor,
      vendorBranch: groupVendorBranch,
      pickupLocation: groupPickupLocation,
      pickupAddress: groupPickupAddress,
      items: scopedItems,
      vendorFulfillments: scopedFulfillments,
      grandTotal: cashToCollect,
      total: cashToCollect,
      serviceFee: 0,
      tax: 0,
      discount: 0,
      financials: {
        viewRole: 'DRIVER',
        cashToCollect,
        isPrepaid: isPrepaid || orderPaid,
        cashToPayStore,
        isStorePrepaid,
        driverEarnings,
        storePayments: (scopedFulfillments && scopedFulfillments.length > 0)
          ? scopedFulfillments.map((f: any) => {
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
                branchName: f.vendorBranch?.nameAr ?? f.vendorBranch?.name ?? '',
                address: f.vendorBranch?.address ?? f.vendor?.address ?? '',
                phone: f.vendorBranch?.phone ?? f.vendor?.phone ?? f.vendor?.user?.phone ?? '',
                subtotal: sub,
                isContracted: contracted,
                commissionRate: commRate,
                commissionAmount: comm,
                cashToPay: toPay,
                pickedUpAt: f.pickedUpAt ?? null,
                pickupImageUrl: f.pickupImageUrl ?? null,
              };
            })
          : [{
              vendorId: order.vendorId,
              vendorName: order.vendor?.storeNameAr ?? order.vendor?.storeName ?? order.vendor?.name ?? 'Store',
              branchName: order.vendorBranch?.nameAr ?? order.vendorBranch?.name ?? '',
              address: order.vendorBranch?.address ?? order.vendor?.address ?? '',
              phone: order.vendorBranch?.phone ?? order.vendor?.phone ?? order.vendor?.user?.phone ?? '',
              subtotal: subtotal,
              isContracted: isStorePrepaid,
              commissionRate: singleStoreCommRate,
              commissionAmount: singleStoreComm,
              cashToPay: cashToPayStore,
              pickedUpAt: order.pickedUpAt ?? null,
              pickupImageUrl: order.pickupImageUrl ?? null,
            }],
      },
    };
  }

  private async projectForVendor(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
  ): Promise<any> {
    let vendorId = vendorIdScope;
    if (!vendorId) {
      if (order.vendorId) {
        vendorId = order.vendorId;
      } else {
        const membership = await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub },
          select: { vendorId: true },
        });
        vendorId = membership?.vendorId;
      }
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
      const myFulfillment = order.vendorFulfillments.find(
        (f: any) => f.vendorId === vendorId,
      );
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

        vendorSubtotal = Number(myFulfillment.subtotal ?? 0);
        commissionRate = Number(myFulfillment.commissionRate ?? commissionRate);
        if (myFulfillment.vendorBranch?.isContracted != null) {
          isContracted = myFulfillment.vendorBranch.isContracted;
        }
        if (myFulfillment.items && myFulfillment.items.length > 0) {
          items = myFulfillment.items;
        } else if (order.items) {
          items = order.items.filter(
            (i: any) =>
              i.rejectedAt == null && i.fulfillmentId === myFulfillment.id,
          );
        }
      }
    }

    const commissionAmount = isContracted
      ? Math.round(vendorSubtotal * (commissionRate / 100))
      : 0;
    const netPayout = isContracted
      ? Math.max(0, vendorSubtotal - commissionAmount)
      : vendorSubtotal;

    // Strict Vendor Isolation: Only expose the vendor's own fulfillment.
    // Strip other stores and delivery groups to prevent any cross-vendor data leakage.
    const myFulfillmentOnly = (order.vendorFulfillments ?? []).filter(
      (f: any) => f.vendorId === vendorId,
    );

    return {
      ...order,
      // The caller's own portion drives the vendor-facing status; the raw
      // aggregate stays available as `orderStatus`.
      status: portionStatus ?? order.status,
      orderStatus: order.status,
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
      deliveryGroups: [],
      vendor: order.vendorFulfillments?.find((f: any) => f.vendorId === vendorId)?.vendor ?? order.vendor,
      vendorBranch: order.vendorFulfillments?.find((f: any) => f.vendorId === vendorId)?.vendorBranch ?? order.vendorBranch,
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

      if (!sanitized.vendor && sanitized.vendorFulfillments.length > 0) {
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
    const rate = Number(settings?.deliveryCommissionRate ?? 20);
    const deliveryFee = Number(order.deliveryFee ?? 0);
    const driverEarnings = Math.max(0, Math.round(deliveryFee * (1 - rate / 100)));

    let vendor = order.vendor;
    let vendorBranch = order.vendorBranch;
    if (!vendor && order.vendorFulfillments?.length > 0) {
      vendor = order.vendorFulfillments[0].vendor;
      vendorBranch ??= order.vendorFulfillments[0].vendorBranch;
    }

    return {
      ...order,
      vendor,
      vendorBranch,
      financials: {
        viewRole: 'ADMIN',
        cashToCollect,
        isPrepaid,
        cashToPayStore,
        isStorePrepaid,
        driverEarnings,
      },
    };
  }

  private async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.SUPER_ADMIN || role === Role.ADMIN) {
      return true;
    }
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!(
      user?.permissions.includes(Permission.MANAGE_ORDERS) ||
      user?.permissions.includes(Permission.MANAGE_DRIVERS)
    );
  }
}
