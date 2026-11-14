import { Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { OrderEarningsCalculator } from '../../../common/orders/order-earnings.calculator';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';
import { OrderAuthorizationHelper } from '../helpers/order-authorization.helper';

export interface RoleProjectionContext {
  canManage?: boolean;
  driverId?: string | null;
  driverTier?: string | null;
  vendorId?: string;
  memberBranchId?: string | null;
  settings?: any;
}

function omitKeys<T extends Record<string, any>>(
  obj: T,
  keys: readonly string[],
): Record<string, any> {
  const copy = { ...obj };
  for (const key of keys) {
    delete copy[key];
  }
  return copy;
}

/**
 * Projects raw order graphs into role-scoped responses (Admin/Customer/Vendor/Driver)
 * so vendor branch isolation, driver payout scopes, and customer financial masking
 * remain centralized in one place.
 */
@Injectable()
export class OrderRoleProjector {
  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly auth: OrderAuthorizationHelper,
    private readonly earnings: OrderEarningsCalculator,
  ) {}

  async projectOrderForRole(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: RoleProjectionContext,
  ): Promise<any> {
    if (!order) return order;

    const canManage =
      ctx?.canManage !== undefined
        ? ctx.canManage
        : await this.auth.canManageOrders(actor.sub, actor.role);
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

  async projectForDriver(
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

    const allFulfillments = Array.isArray(order.vendorFulfillments)
      ? order.vendorFulfillments
      : [];
    const activeFulfillments = allFulfillments.filter(
      (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
    );
    const computedBaselineFulfillments = activeFulfillments.map((f: any) => {
      const contracted =
        f.isContracted ??
        f.vendorBranch?.isContracted ??
        f.vendor?.isContracted ??
        false;
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
        ...f,
        isContracted: contracted,
        commissionRate: commRate,
        commissionAmount: comm,
        cashToPay: toPay,
      };
    });

    const subtotal = Number(order.subtotal ?? 0);
    let isStorePrepaid =
      computedBaselineFulfillments.length > 0
        ? computedBaselineFulfillments.every((f: any) => f.isContracted)
        : false;
    let cashToPayStore =
      computedBaselineFulfillments.length > 0
        ? computedBaselineFulfillments.reduce(
            (sum: number, f: any) => sum + Number(f.cashToPay ?? 0),
            0,
          )
        : 0;

    const settings = ctx?.settings ?? (await this.platformSettings.getSettings());

    const activeDeliveryGroups = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    )
      .filter((g: any) => g.status !== 'CANCELLED')
      .sort((a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0));
    const collectorGroup =
      activeDeliveryGroups.find((g: any) => g.isPaymentCollector === true) ??
      activeDeliveryGroups[0] ??
      null;

    let deliveryFee = Number(order.deliveryFee ?? 0);
    let projectedIsStacked = activeDeliveryGroups.some((g: any) =>
      Boolean(g.isStacked),
    );
    let customDriverEarnings: number | null = null;
    const singleBaselineFulfillment =
      computedBaselineFulfillments.length === 1
        ? computedBaselineFulfillments[0]
        : null;
    let groupVendor = singleBaselineFulfillment?.vendor ?? null;
    let groupVendorBranch = singleBaselineFulfillment?.vendorBranch ?? null;
    let groupPickupLocation =
      order.pickupLocation ??
      singleBaselineFulfillment?.vendorBranch?.location ??
      null;
    let groupPickupAddress =
      order.pickupAddress ??
      singleBaselineFulfillment?.vendorBranch?.address ??
      null;
    let projectedStatus = order.status;
    let projectedDriverId: string | null =
      collectorGroup?.primaryDriverId ??
      activeDeliveryGroups.find((g: any) => g.primaryDriverId)?.primaryDriverId ??
      null;
    let projectedPickedUpAt: Date | string | null =
      collectorGroup?.pickedUpAt ??
      singleBaselineFulfillment?.pickedUpAt ??
      null;
    let projectedPickupImageUrl: string | null =
      collectorGroup?.pickupImageUrl ??
      singleBaselineFulfillment?.pickupImageUrl ??
      null;
    let projectedDeliveryImageUrl: string | null =
      collectorGroup?.deliveryImageUrl ?? null;
    let scopedItems = order.items;
    let scopedFulfillments =
      computedBaselineFulfillments.length > 0
        ? computedBaselineFulfillments
        : order.vendorFulfillments;

    const myDriver =
      ctx?.driverId !== undefined
        ? ctx.driverId
          ? { id: ctx.driverId, tier: ctx.driverTier }
          : null
        : await this.prisma.driver.findUnique({
            where: { userId: actor.sub },
            select: { id: true, tier: true },
          });

    if (order.deliveryGroups && Array.isArray(order.deliveryGroups)) {
      if (myDriver) {
        const myGroups = order.deliveryGroups.filter(
          (g: any) =>
            g.primaryDriverId === myDriver.id ||
            g.assistDriverId === myDriver.id,
        );

        if (myGroups.length > 0) {
          projectedDriverId = myGroups[0]?.primaryDriverId ?? myDriver.id;
          projectedPickedUpAt = myGroups[0]?.pickedUpAt ?? projectedPickedUpAt;
          projectedPickupImageUrl =
            myGroups[0]?.pickupImageUrl ?? projectedPickupImageUrl;
          projectedDeliveryImageUrl =
            myGroups[0]?.deliveryImageUrl ?? projectedDeliveryImageUrl;

          const anyPendingPayment = myGroups.some(
            (g: any) => g.status === 'PENDING_PAYMENT',
          );
          const allDelivered = myGroups.every(
            (g: any) => g.status === 'DELIVERED',
          );
          const allPickedUp = myGroups.every(
            (g: any) => g.status === 'PICKED_UP' || g.status === 'DELIVERED',
          );
          const somePickedUp = myGroups.some(
            (g: any) =>
              g.status === 'PARTIALLY_PICKED_UP' || g.status === 'PICKED_UP',
          );
          const allReady = myGroups.every(
            (g: any) =>
              g.status === 'READY_FOR_PICKUP' ||
              g.status === 'PARTIALLY_PICKED_UP' ||
              g.status === 'PICKED_UP' ||
              g.status === 'DELIVERED',
          );

          if (anyPendingPayment) {
            projectedStatus = 'PENDING_PAYMENT';
          } else if (allDelivered) {
            projectedStatus = 'DELIVERED';
          } else if (allPickedUp) {
            projectedStatus = 'PICKED_UP';
          } else if (somePickedUp) {
            projectedStatus = 'PARTIALLY_PICKED_UP';
          } else if (allReady) {
            projectedStatus = 'READY_FOR_PICKUP';
          } else if (myGroups.some((g: any) => g.status === 'DRIVER_ASSIGNED')) {
            projectedStatus = 'DRIVER_ASSIGNED';
          } else {
            projectedStatus = myGroups[0].status ?? order.status;
          }

          deliveryFee = myGroups.reduce(
            (sum: number, g: any) =>
              sum + (g.deliveryFee != null ? Number(g.deliveryFee) : 0),
            0,
          );
          projectedIsStacked = myGroups.some((g: any) => Boolean(g.isStacked));
          const isMultiVendor = Boolean(activeDeliveryGroups.length > 1);
          customDriverEarnings = myGroups.reduce((sum: number, g: any) => {
            const gFee = g.deliveryFee != null ? Number(g.deliveryFee) : 0;
            const isGroupStacked = Boolean(g.isStacked);
            return (
              sum +
              this.earnings.calculateDriverEarningsForFee(gFee, settings, {
                isStacked: isGroupStacked,
                isMultiVendor,
                driverTier: myDriver?.tier,
              })
            );
          }, 0);

          const allGroupItems = myGroups.flatMap((g: any) =>
            Array.isArray(g.items) ? g.items : [],
          );

          if (order.vendorFulfillments) {
            const fulfillmentIds = new Set(
              allGroupItems.map((it: any) => it.fulfillmentId),
            );
            const myFulfillments = (order.vendorFulfillments as any[]).filter(
              (f) =>
                f.status !== 'REJECTED' &&
                f.status !== 'CANCELLED' &&
                (fulfillmentIds.size === 0 ? true : fulfillmentIds.has(f.id)),
            );

            myFulfillments.sort((a, b) => {
              const seqA =
                allGroupItems.find((it: any) => it.fulfillmentId === a.id)
                  ?.sequence ?? 0;
              const seqB =
                allGroupItems.find((it: any) => it.fulfillmentId === b.id)
                  ?.sequence ?? 0;
              return seqA - seqB;
            });

            for (const f of myFulfillments) {
              f.isContracted =
                f.isContracted ??
                f.vendorBranch?.isContracted ??
                f.vendor?.isContracted ??
                false;
              const commRate = Number(
                f.commissionRate ??
                  f.vendorBranch?.commissionRate ??
                  f.vendor?.commissionRate ??
                  10,
              );
              f.commissionRate = commRate;
              const sub = Number(f.subtotal ?? 0);
              const comm = f.isContracted
                ? Math.round(sub * (commRate / 100))
                : 0;
              f.commissionAmount = comm;
              f.cashToPay = f.isContracted ? Math.max(0, sub - comm) : sub;
            }
            scopedFulfillments = myFulfillments;

            if (Array.isArray(order.items)) {
              scopedItems = order.items.filter(
                (i: any) =>
                  i.rejectedAt == null &&
                  (!i.fulfillmentId ||
                    fulfillmentIds.size === 0 ||
                    fulfillmentIds.has(i.fulfillmentId)),
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

            const liveFulfillments = myFulfillments.filter(
              (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
            );
            const nextUnpicked = liveFulfillments.find(
              (f: any) =>
                f.status !== 'PICKED_UP' &&
                f.status !== 'DELIVERED' &&
                !f.pickedUpAt,
            );
            const anyPicked = liveFulfillments.some(
              (f: any) => f.status === 'PICKED_UP' || Boolean(f.pickedUpAt),
            );
            if (
              projectedStatus !== 'PENDING_PAYMENT' &&
              projectedStatus !== 'DELIVERED' &&
              projectedStatus !== 'PICKED_UP'
            ) {
              if (anyPicked) {
                projectedStatus = 'PARTIALLY_PICKED_UP';
              } else if (
                nextUnpicked &&
                (nextUnpicked.status === 'READY_FOR_PICKUP' ||
                  Boolean(nextUnpicked.readyAt))
              ) {
                projectedStatus = 'READY_FOR_PICKUP';
              } else if (
                liveFulfillments.some(
                  (f: any) =>
                    f.status === 'PREPARING' || Boolean(f.preparingAt),
                )
              ) {
                projectedStatus = 'PREPARING';
              }
            }

            const isCollectorGroup = Boolean(
              collectorGroup &&
                myGroups.some((g: any) => g.id === collectorGroup.id),
            );
            if (isPrepaid || orderPaid) {
              cashToCollect = 0;
            } else if (order.paymentMethod === 'MOBILE_WALLET') {
              cashToCollect = isCollectorGroup
                ? Math.max(0, grandTotal - upfrontAmount)
                : 0;
            } else {
              const allActiveGoodsTotal = activeFulfillments.reduce(
                (sum: number, f: any) => sum + Number(f.subtotal ?? 0),
                0,
              );
              const allActiveFeesTotal = activeDeliveryGroups.reduce(
                (sum: number, g: any) =>
                  sum + (g.deliveryFee != null ? Number(g.deliveryFee) : 0),
                0,
              );
              const rawExtras =
                grandTotal > 0
                  ? grandTotal - allActiveGoodsTotal - allActiveFeesTotal
                  : Number(order.serviceFee ?? 0) +
                    Number(order.tax ?? 0) +
                    Number(order.driverBonusFee ?? 0) -
                    Number(order.discount ?? 0);
              const orderLevelExtras = isCollectorGroup
                ? rawExtras - upfrontAmount
                : 0;
              cashToCollect = Math.max(
                0,
                groupSubtotal + deliveryFee + orderLevelExtras,
              );
            }

            const firstFulfillment = myFulfillments[0];
            if (firstFulfillment) {
              groupVendor = firstFulfillment.vendor ?? groupVendor;
              groupVendorBranch =
                firstFulfillment.vendorBranch ?? groupVendorBranch;
              if (firstFulfillment.vendorBranch?.location) {
                groupPickupLocation = firstFulfillment.vendorBranch.location;
              }
              if (firstFulfillment.vendorBranch?.address) {
                groupPickupAddress = firstFulfillment.vendorBranch.address;
              }
              projectedPickedUpAt ??= firstFulfillment.pickedUpAt ?? null;
              projectedPickupImageUrl ??=
                firstFulfillment.pickupImageUrl ?? null;
            }
          }
        }
      }
    }

    const activeAssignedGroups = activeDeliveryGroups.filter(
      (g: any) => g.primaryDriverId,
    );
    const primaryCollectorId =
      collectorGroup?.primaryDriverId ??
      activeAssignedGroups[0]?.primaryDriverId ??
      null;
    const isPrimaryCollector = Boolean(
      myDriver?.id && primaryCollectorId === myDriver.id,
    );

    const isMultiVendor = Boolean(activeDeliveryGroups.length > 1);
    const driverEarnings =
      customDriverEarnings ??
      this.earnings.calculateDriverEarningsForFee(deliveryFee, settings, {
        isStacked: projectedIsStacked,
        isMultiVendor,
        driverTier: myDriver?.tier,
      });

    return {
      ...order,
      driverId: projectedDriverId,
      pickedUpAt: projectedPickedUpAt,
      pickupImageUrl: projectedPickupImageUrl,
      deliveryImageUrl: projectedDeliveryImageUrl,
      driverEarnings,
      deliveryFee,
      isPrimaryCollector,
      status: projectedStatus,
      isStacked: projectedIsStacked,
      vendor: groupVendor,
      vendorBranch: groupVendorBranch,
      pickupLocation: groupPickupLocation,
      pickupAddress: groupPickupAddress,
      items: scopedItems,
      vendorFulfillments: scopedFulfillments,
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
        storePayments:
          scopedFulfillments && scopedFulfillments.length > 0
            ? scopedFulfillments.map((f: any) => ({
                ...omitKeys(this.buildStorePaymentBase(f, false), [
                  'vendorNameEn',
                ]),
                pickupImageUrl: f.pickupImageUrl ?? null,
              }))
            : [],
      },
    };
  }

  async projectForVendor(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: { vendorId?: string; memberBranchId?: string | null },
  ): Promise<any> {
    let vendorId = vendorIdScope ?? ctx?.vendorId;
    let memberBranchId: string | null = ctx?.memberBranchId ?? null;
    const fulfillments = Array.isArray(order.vendorFulfillments)
      ? order.vendorFulfillments
      : [];
    if (actor.role === Role.VENDOR_MEMBER && ctx?.memberBranchId === undefined) {
      const portionVendorIds: string[] = vendorId
        ? [vendorId]
        : Array.from(
            new Set<string>(
              fulfillments
                .map((f: any) => f.vendorId)
                .filter((id: any): id is string => Boolean(id)),
            ),
          );
      const memberships =
        portionVendorIds.length > 0
          ? await this.prisma.vendorMember.findMany({
              where: {
                userId: actor.sub,
                vendorId: { in: portionVendorIds },
              },
              select: { vendorId: true, branchId: true, role: true },
            })
          : await this.prisma.vendorMember.findMany({
              where: { userId: actor.sub },
              take: 1,
              select: { vendorId: true, branchId: true, role: true },
            });
      const membership =
        memberships.find((m) => {
          const effBranch = m.role === 'OWNER' ? null : (m.branchId ?? null);
          if (fulfillments.length === 0) return true;
          return fulfillments.some(
            (f: any) =>
              f.vendorId === m.vendorId &&
              (!effBranch ||
                !f.vendorBranchId ||
                f.vendorBranchId === effBranch),
          );
        }) ??
        memberships[0] ??
        null;
      if (!vendorId) {
        vendorId = membership?.vendorId;
      }
      memberBranchId =
        membership?.role === 'OWNER' ? null : (membership?.branchId ?? null);
    }

    let items = order.items ?? [];
    let vendorSubtotal = Number(order.subtotal ?? 0);
    let commissionRate = 10;
    let isContracted = false;

    let portionStatus: string | null = null;
    let myFulfillmentId: string | null = null;

    if (fulfillments.length > 0 && vendorId) {
      const vendorFulfillments = fulfillments.filter(
        (f: any) =>
          f.vendorId === vendorId &&
          (!memberBranchId ||
            !f.vendorBranchId ||
            f.vendorBranchId === memberBranchId),
      );
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
          portionStatus = 'PICKED_UP';
        } else if (
          myFulfillment.readyAt ||
          myFulfillment.status === 'READY_FOR_PICKUP' ||
          groupStatus === 'READY_FOR_PICKUP'
        ) {
          portionStatus = 'READY_FOR_PICKUP';
        } else if (
          myFulfillment.preparingAt ||
          myFulfillment.status === 'PREPARING'
        ) {
          portionStatus = 'PREPARING';
        } else if (
          groupStatus === 'DRIVER_ASSIGNED' ||
          groupStatus === 'PENDING_PAYMENT'
        ) {
          portionStatus = groupStatus;
        } else {
          portionStatus = rawPortionStatus;
        }

        vendorSubtotal = vendorFulfillments.reduce(
          (sum: number, f: any) => sum + Number(f.subtotal ?? 0),
          0,
        );
        commissionRate = Number(
          myFulfillment.commissionRate ??
            myFulfillment.vendorBranch?.commissionRate ??
            myFulfillment.vendor?.commissionRate ??
            10,
        );
        isContracted =
          myFulfillment.isContracted ??
          myFulfillment.vendorBranch?.isContracted ??
          myFulfillment.vendor?.isContracted ??
          false;
        const myFulfillmentIds = new Set(
          vendorFulfillments.map((f: any) => f.id),
        );
        const directItems = vendorFulfillments.flatMap((f: any) =>
          Array.isArray(f.items) ? f.items : [],
        );
        if (directItems.length > 0) {
          items = directItems;
        } else if (order.items) {
          items = order.items.filter(
            (i: any) =>
              i.rejectedAt == null &&
              (!i.fulfillmentId || myFulfillmentIds.has(i.fulfillmentId)),
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

    const myFulfillmentOnly = fulfillments.filter(
      (f: any) =>
        f.vendorId === vendorId &&
        (!memberBranchId ||
          !f.vendorBranchId ||
          f.vendorBranchId === memberBranchId),
    );
    const primaryFulfillment =
      myFulfillmentOnly[0] ??
      fulfillments.find((f: any) => f.vendorId === vendorId);

    return {
      ...order,
      vendorId: vendorId ?? primaryFulfillment?.vendorId ?? null,
      vendorBranchId: primaryFulfillment?.vendorBranchId ?? null,
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
      vendor: primaryFulfillment?.vendor ?? null,
      vendorBranch: primaryFulfillment?.vendorBranch ?? null,
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

  projectForCustomer(order: any): any {
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    const cashToPayAtDoor = isPrepaid ? 0 : Math.max(0, grandTotal - upfrontAmount);

    const sanitized: any = { ...order };
    if (Array.isArray(sanitized.items)) {
      sanitized.items = sanitized.items.filter(
        (i: any) => i.rejectedAt == null,
      );
    }
    if (sanitized.vendor) {
      sanitized.vendor = omitKeys(sanitized.vendor, [
        'commissionRate',
        'walletBalance',
      ]);
    }
    if (sanitized.vendorBranch) {
      sanitized.vendorBranch = omitKeys(sanitized.vendorBranch, [
        'commissionRate',
      ]);
    }
    let fulfillmentSummary: any = null;
    if (sanitized.vendorFulfillments) {
      const allGroupItems = (order.deliveryGroups ?? []).flatMap((g: any) =>
        Array.isArray(g.items) ? g.items : [],
      );

      sanitized.vendorFulfillments = sanitized.vendorFulfillments.map((f: any) => {
        const safeF: any = omitKeys(f, ['commissionRate']);
        if (safeF.vendor) {
          safeF.vendor = omitKeys(safeF.vendor, [
            'commissionRate',
            'walletBalance',
          ]);
        }
        if (safeF.vendorBranch) {
          safeF.vendorBranch = omitKeys(safeF.vendorBranch, ['commissionRate']);
        }
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
        const seqA =
          allGroupItems.find((it: any) => it.fulfillmentId === a.id)?.sequence ??
          0;
        const seqB =
          allGroupItems.find((it: any) => it.fulfillmentId === b.id)?.sequence ??
          0;
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
          ? (allGroupItems.find(
              (it: any) => it.fulfillmentId === activeFulfillment.id,
            )?.sequence ?? 1)
          : totalStops,
        currentStopBranchName:
          activeFulfillment?.vendorBranch?.nameAr ??
          activeFulfillment?.vendorBranch?.name ??
          activeFulfillment?.vendor?.storeNameAr ??
          activeFulfillment?.vendor?.storeName ??
          null,
        isFullyCollected: completedStops >= totalStops,
      };

      if (!sanitized.vendor && sanitized.vendorFulfillments.length === 1) {
        sanitized.vendor = sanitized.vendorFulfillments[0].vendor ?? null;
        if (
          !sanitized.vendorBranch &&
          sanitized.vendorFulfillments[0].vendorBranch
        ) {
          sanitized.vendorBranch = sanitized.vendorFulfillments[0].vendorBranch;
        }
      } else if (sanitized.vendorFulfillments.length > 1) {
        sanitized.vendor = null;
        sanitized.vendorBranch = null;
      }
    }

    const activeDeliveryGroups = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    )
      .filter((g: any) => g.status !== 'CANCELLED')
      .sort((a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0));
    const collectorGroup =
      activeDeliveryGroups.find((g: any) => g.isPaymentCollector === true) ??
      activeDeliveryGroups[0] ??
      null;
    const primaryDriver =
      collectorGroup?.primaryDriver ??
      activeDeliveryGroups.find((g: any) => g.primaryDriver)?.primaryDriver ??
      null;

    return {
      ...sanitized,
      driver: primaryDriver ?? null,
      fulfillmentSummary,
      financials: {
        viewRole: 'CUSTOMER',
        cashToPayAtDoor,
        isPrepaid,
      },
    };
  }

  async enrichWithAdminHelpers(
    order: any,
    prefetchedSettings?: any,
  ): Promise<any> {
    if (!order) return order;
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    const cashToCollect = isPrepaid ? 0 : Math.max(0, grandTotal - upfrontAmount);

    const activeDeliveryGroups = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    )
      .filter((g: any) => g.status !== 'CANCELLED')
      .sort((a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0));
    const collectorGroup =
      activeDeliveryGroups.find((g: any) => g.isPaymentCollector === true) ??
      activeDeliveryGroups[0] ??
      null;
    const isStacked = activeDeliveryGroups.some((g: any) =>
      Boolean(g.isStacked),
    );

    const fulfillments = Array.isArray(order.vendorFulfillments)
      ? order.vendorFulfillments
      : [];
    const activeFulfillmentsCount = fulfillments.filter(
      (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
    ).length;
    const settings =
      prefetchedSettings ?? (await this.platformSettings.getSettings());
    const deliveryFee = Number(order.deliveryFee ?? 0);
    const isMultiVendor = Boolean(
      activeDeliveryGroups.length > 1 || activeFulfillmentsCount > 1,
    );
    const driverEarnings =
      activeDeliveryGroups.length > 0
        ? activeDeliveryGroups.reduce((sum: number, g: any) => {
            const gFee = g.deliveryFee != null ? Number(g.deliveryFee) : 0;
            return (
              sum +
              this.earnings.calculateDriverEarningsForFee(gFee, settings, {
                isStacked: Boolean(g.isStacked),
                isMultiVendor,
                driverTier: g.primaryDriver?.tier ?? order.driver?.tier,
              })
            );
          }, 0)
        : this.earnings.calculateDriverEarningsForFee(deliveryFee, settings, {
            isStacked: Boolean(order.isStacked),
            isMultiVendor: false,
            driverTier: order.driver?.tier,
          });

    const isMultiVendorOrder = Boolean(
      order.isMultiVendor ||
        fulfillments.length > 1 ||
        activeDeliveryGroups.length > 1,
    );

    const storePayments = fulfillments.map((f: any) => ({
      ...this.buildStorePaymentBase(f, true),
      status: f.status,
    }));
    const activeStorePayments = storePayments.filter(
      (sp: any) => sp.status !== 'REJECTED' && sp.status !== 'CANCELLED',
    );

    let vendor: any = null;
    let vendorBranch: any = null;
    let resolvedIsStorePrepaid = false;
    let resolvedCashToPayStore = 0;

    if (activeStorePayments.length > 0) {
      resolvedCashToPayStore = activeStorePayments.reduce(
        (sum: number, sp: any) => sum + sp.cashToPay,
        0,
      );
      resolvedIsStorePrepaid = activeStorePayments.every(
        (sp: any) => sp.isContracted,
      );
    }

    if (isMultiVendorOrder && fulfillments.length > 1) {
      const storeNamesAr = this.formatFulfillmentNames(fulfillments, true);
      const storeNamesEn = this.formatFulfillmentNames(fulfillments, false);

      vendor = {
        id: 'multi-vendor',
        isMultiVendor: true,
        storeName: storeNamesEn.join(' + ') || 'Multi-Vendor',
        storeNameAr: storeNamesAr.join(' + ') || 'طلب متعدد المتاجر',
        logo: null,
      };
      vendorBranch = null;
    } else if (fulfillments.length === 1) {
      vendor = fulfillments[0].vendor ?? null;
      vendorBranch = fulfillments[0].vendorBranch ?? null;
    }

    const primaryDriver =
      collectorGroup?.primaryDriver ??
      activeDeliveryGroups.find((g: any) => g.primaryDriver)?.primaryDriver ??
      null;

    return {
      ...order,
      isMultiVendor: isMultiVendorOrder,
      isStacked,
      driverEarnings,
      deliveryFee,
      vendorId: fulfillments.length === 1 ? fulfillments[0].vendorId : null,
      vendorBranchId:
        fulfillments.length === 1 ? fulfillments[0].vendorBranchId : null,
      vendor,
      vendorBranch,
      driverId:
        collectorGroup?.primaryDriverId ??
        activeDeliveryGroups.find((g: any) => g.primaryDriverId)
          ?.primaryDriverId ??
        null,
      driver: primaryDriver,
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

  private buildStorePaymentBase(f: any, respectTerminalStatus: boolean) {
    const isCancelledOrRejected =
      respectTerminalStatus &&
      (f.status === 'REJECTED' || f.status === 'CANCELLED');
    const contracted =
      f.isContracted ??
      f.vendorBranch?.isContracted ??
      f.vendor?.isContracted ??
      false;
    const commRate = Number(
      f.commissionRate ??
        f.vendorBranch?.commissionRate ??
        f.vendor?.commissionRate ??
        10,
    );
    const sub = Number(f.subtotal ?? 0);
    const comm = isCancelledOrRejected
      ? 0
      : contracted
        ? Math.round(sub * (commRate / 100))
        : 0;
    const toPay = isCancelledOrRejected
      ? 0
      : contracted
        ? Math.max(0, sub - comm)
        : sub;
    return {
      fulfillmentId: f.id,
      vendorId: f.vendorId,
      vendorName:
        f.vendor?.storeNameAr ?? f.vendor?.storeName ?? f.vendor?.name ?? 'Store',
      vendorNameEn:
        f.vendor?.storeName ?? f.vendor?.storeNameAr ?? f.vendor?.name ?? 'Store',
      branchName: f.vendorBranch?.nameAr ?? f.vendorBranch?.name ?? '',
      address: f.vendorBranch?.address ?? f.vendor?.address ?? '',
      phone:
        f.vendorBranch?.phone ?? f.vendor?.phone ?? f.vendor?.user?.phone ?? '',
      subtotal: sub,
      isContracted: contracted,
      commissionRate: commRate,
      commissionAmount: comm,
      cashToPay: toPay,
      pickedUpAt: f.pickedUpAt ?? null,
    };
  }

  private formatFulfillmentNames(
    fulfillments: any[],
    preferAr: boolean,
  ): string[] {
    const countsByVendor = new Map<string, number>();
    for (const f of fulfillments) {
      if (f?.vendorId) {
        countsByVendor.set(
          f.vendorId,
          (countsByVendor.get(f.vendorId) ?? 0) + 1,
        );
      }
    }
    const labels: string[] = [];
    for (const f of fulfillments) {
      const storeName = preferAr
        ? (f.vendor?.storeNameAr ?? f.vendor?.storeName ?? f.vendor?.name)
        : (f.vendor?.storeName ?? f.vendor?.storeNameAr ?? f.vendor?.name);
      if (!storeName) continue;
      const isRepeatedVendor =
        f.vendorId && (countsByVendor.get(f.vendorId) ?? 0) > 1;
      const branchName = preferAr
        ? (f.vendorBranch?.nameAr ?? f.vendorBranch?.name)
        : (f.vendorBranch?.name ?? f.vendorBranch?.nameAr);
      const label =
        isRepeatedVendor && branchName
          ? `${String(storeName).trim()} (${String(branchName).trim()})`
          : String(storeName).trim();
      if (!labels.includes(label)) {
        labels.push(label);
      }
    }
    return labels;
  }
}
