import { Injectable } from '@nestjs/common';
import { OrderType, Role } from '@prisma/client';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { OrderEarningsCalculator } from '../../../common/orders/order-earnings.calculator';
import {
  allocateOrderCashCollection,
  computeIsMultiVendorOrder,
} from '../../../common/orders/order-financials.helper';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';
import { resolveVendorDisplayLogo } from '../helpers/order-actor.helper';
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
      const resolvedCtx =
        ctx?.settings !== undefined
          ? ctx
          : Number(order.driverBonusFee ?? 0) > 0 &&
              typeof this.platformSettings?.getSettings === 'function'
            ? { ...ctx, settings: await this.platformSettings.getSettings() }
            : ctx;
      return this.projectForCustomer(order, resolvedCtx);
    }

    return order;
  }

  async projectForDriver(
    order: any,
    actor: JwtAccessPayload,
    ctx?: {
      driverId?: string | null;
      driverTier?: string | null;
      settings?: any;
    },
  ): Promise<any> {
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    // Customer marking PAID is only a transfer claim until the collector driver
    // confirms COMPLETED — keep cashToCollect / grandTotal non-zero until then
    // so the driver confirmation dialog displays the actual amount due.
    const orderPaid = order.paymentStatus === 'COMPLETED';
    const isOrderSettledPrepaid =
      isPrepaid || (order.paymentMethod === 'MOBILE_WALLET' && orderPaid);
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    let projectedUpfrontAmount = upfrontAmount;
    let cashToCollect = isOrderSettledPrepaid
      ? 0
      : Math.max(0, grandTotal - upfrontAmount);

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

    const settings =
      ctx?.settings ?? (await this.platformSettings.getSettings());

    const activeDeliveryGroups = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    )
      .filter((g: any) => g.status !== 'CANCELLED')
      .sort(
        (a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
      );
    const collectorGroup =
      activeDeliveryGroups.find((g: any) => g.isPaymentCollector === true) ??
      activeDeliveryGroups[0] ??
      null;

    const effectiveDriverSettings =
      order.settledAt && order.settledBronzeDriverDeductionRate != null
        ? {
            ...settings,
            bronzeTierDeductionAmount: order.settledBronzeDriverDeductionRate,
          }
        : settings;

    let deliveryFee = Number(order.deliveryFee ?? 0);
    let projectedIsStacked = activeDeliveryGroups.some((g: any) =>
      Boolean(g.isStacked),
    );
    let customDriverEarnings: number | null = null;
    let projectedGoldBonusAmount = 0;
    let projectedBronzeDeductionAmount = 0;
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
      activeDeliveryGroups.find((g: any) => g.primaryDriverId)
        ?.primaryDriverId ??
      null;
    let isPrimaryDriver = true;
    let isAssistDriver = false;
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
    let activeDeliveryGroupId: string | null = collectorGroup?.id ?? null;
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
          const openMyGroups = myGroups.filter(
            (g: any) => g.status !== 'DELIVERED' && g.status !== 'CANCELLED',
          );
          const nonCancelledClosed = myGroups.filter(
            (g: any) => g.status !== 'CANCELLED',
          );
          const scopedGroups =
            openMyGroups.length > 0
              ? openMyGroups
              : nonCancelledClosed.length > 0
                ? nonCancelledClosed
                : myGroups;

          const activeGroup =
            scopedGroups.find((g: any) => g.status === 'PENDING_PAYMENT') ??
            scopedGroups.find((g: any) => g.status === 'PICKED_UP') ??
            scopedGroups.find((g: any) => g.status === 'PARTIALLY_PICKED_UP') ??
            scopedGroups.find((g: any) => g.status === 'READY_FOR_PICKUP') ??
            scopedGroups[0];

          activeDeliveryGroupId = activeGroup?.id ?? activeDeliveryGroupId;
          projectedDriverId = activeGroup?.primaryDriverId ?? myDriver.id;
          isAssistDriver = Boolean(
            activeGroup &&
            activeGroup.assistDriverId === myDriver.id &&
            activeGroup.primaryDriverId !== myDriver.id,
          );
          isPrimaryDriver = !isAssistDriver;
          projectedPickedUpAt = activeGroup?.pickedUpAt ?? projectedPickedUpAt;
          projectedPickupImageUrl =
            activeGroup?.pickupImageUrl ?? projectedPickupImageUrl;
          projectedDeliveryImageUrl =
            activeGroup?.deliveryImageUrl ?? projectedDeliveryImageUrl;

          if (openMyGroups.length > 0 && activeGroup) {
            projectedStatus = activeGroup.status ?? order.status;
          } else {
            const allDelivered = scopedGroups.every(
              (g: any) => g.status === 'DELIVERED',
            );
            projectedStatus = allDelivered
              ? 'DELIVERED'
              : (activeGroup?.status ?? order.status);
          }

          deliveryFee = scopedGroups.reduce(
            (sum: number, g: any) =>
              sum + (g.deliveryFee != null ? Number(g.deliveryFee) : 0),
            0,
          );
          projectedIsStacked = scopedGroups.some((g: any) =>
            Boolean(g.isStacked),
          );
          const isMultiVendor = computeIsMultiVendorOrder({
            orderIsMultiVendor: order.isMultiVendor,
            activeGroupsCount: activeDeliveryGroups.length,
            activeFulfillmentsCount: activeFulfillments.length,
          });
          const hasExplicitGroupGold = activeDeliveryGroups.some(
            (ag: any) => Number(ag.goldSurchargeAmount ?? 0) > 0,
          );
          const fallbackCollectorId = collectorGroup?.id ?? activeDeliveryGroups[0]?.id;

          customDriverEarnings = scopedGroups.reduce((sum: number, g: any) => {
            const gFee = g.deliveryFee != null ? Number(g.deliveryFee) : 0;
            const gGoldSurcharge = hasExplicitGroupGold
              ? Number(g.goldSurchargeAmount ?? 0)
              : g.id === fallbackCollectorId
                ? Number(order.goldSurchargeAmount ?? 0)
                : 0;
            if (
              g.assistDriverId === myDriver.id &&
              g.primaryDriverId !== myDriver.id
            ) {
              const assistAmt = Number(g.assistFee ?? 0);
              return sum + (assistAmt > 0 ? assistAmt : Math.max(0, gFee - gGoldSurcharge));
            }
            const isGroupStacked = Boolean(g.isStacked);
            const gTier = g.primaryDriverTierSnapshot ?? myDriver?.tier;
            const gCtx = {
              isStacked: isGroupStacked,
              isMultiVendor,
              driverTier: gTier,
              distanceKm:
                g.distanceKm != null
                  ? Number(g.distanceKm)
                  : Number(order.distanceKm ?? 0),
              isStandardOrder: order.type === 'STANDARD',
              goldSurcharge: gGoldSurcharge,
            };
            if (typeof this.earnings.calculateDriverEarningsBreakdown === 'function') {
              const bd = this.earnings.calculateDriverEarningsBreakdown(
                gFee,
                effectiveDriverSettings,
                gCtx,
              );
              projectedGoldBonusAmount +=
                order.settledAt && g.settledGoldBonusAmount != null
                  ? Number(g.settledGoldBonusAmount)
                  : bd.goldBonus;
              projectedBronzeDeductionAmount +=
                order.settledAt && g.settledBronzeDriverDeduction != null
                  ? Number(g.settledBronzeDriverDeduction)
                  : bd.bronzeDeduction;
              return sum + bd.netEarnings;
            }
            return (
              sum +
              this.earnings.calculateDriverEarningsForFee(
                gFee,
                effectiveDriverSettings,
                gCtx,
              )
            );
          }, 0);

          const groupItemMetaByFulfillmentId = new Map<
            string,
            {
              deliveryGroupId: string;
              stopSequence: number;
              groupSequence: number;
            }
          >();
          for (const g of scopedGroups) {
            const gSeq = Number(g.sequence ?? 0);
            const gItems = Array.isArray(g.items) ? g.items : [];
            for (const it of gItems) {
              if (!it?.fulfillmentId) continue;
              groupItemMetaByFulfillmentId.set(it.fulfillmentId, {
                deliveryGroupId: g.id,
                stopSequence: Number(it.sequence ?? 0),
                groupSequence: gSeq,
              });
            }
          }
          const activeGroupItems = Array.isArray(activeGroup?.items)
            ? activeGroup.items
            : [];
          const activeGroupFulfillmentIds = new Set(
            activeGroupItems.map((it: any) => it.fulfillmentId).filter(Boolean),
          );

          if (order.vendorFulfillments) {
            const fulfillmentIds = new Set(groupItemMetaByFulfillmentId.keys());
            const myFulfillments = (order.vendorFulfillments as any[]).filter(
              (f) =>
                f.status !== 'REJECTED' &&
                f.status !== 'CANCELLED' &&
                (fulfillmentIds.size === 0 ? true : fulfillmentIds.has(f.id)),
            );

            myFulfillments.sort((a, b) => {
              const metaA = groupItemMetaByFulfillmentId.get(a.id);
              const metaB = groupItemMetaByFulfillmentId.get(b.id);
              const isActiveA =
                a.id && activeGroupFulfillmentIds.has(a.id) ? 0 : 1;
              const isActiveB =
                b.id && activeGroupFulfillmentIds.has(b.id) ? 0 : 1;
              if (isActiveA !== isActiveB) return isActiveA - isActiveB;
              if ((metaA?.groupSequence ?? 0) !== (metaB?.groupSequence ?? 0)) {
                return (
                  (metaA?.groupSequence ?? 0) - (metaB?.groupSequence ?? 0)
                );
              }
              return (metaA?.stopSequence ?? 0) - (metaB?.stopSequence ?? 0);
            });

            for (const f of myFulfillments) {
              const meta = groupItemMetaByFulfillmentId.get(f.id);
              if (meta) {
                f.deliveryGroupId = meta.deliveryGroupId;
                f.stopSequence = meta.stopSequence;
              }
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
            const statusFulfillments =
              activeGroupFulfillmentIds.size > 0
                ? liveFulfillments.filter((f: any) =>
                    activeGroupFulfillmentIds.has(f.id),
                  )
                : liveFulfillments;
            const nextUnpicked = statusFulfillments.find(
              (f: any) =>
                f.status !== 'PICKED_UP' &&
                f.status !== 'DELIVERED' &&
                !f.pickedUpAt,
            );
            const anyPicked = statusFulfillments.some(
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
                statusFulfillments.some(
                  (f: any) =>
                    f.status === 'PREPARING' || Boolean(f.preparingAt),
                )
              ) {
                projectedStatus = 'PREPARING';
              }
            }

            const isCollectorGroup = Boolean(
              !isAssistDriver &&
              collectorGroup &&
              scopedGroups.some((g: any) => g.id === collectorGroup.id),
            );
            projectedUpfrontAmount = isCollectorGroup ? upfrontAmount : 0;
            if (isAssistDriver || isOrderSettledPrepaid) {
              cashToCollect = 0;
            } else {
              const subtotalByFulfillmentId = new Map<string, number>();
              for (const f of activeFulfillments) {
                if (f?.id) {
                  subtotalByFulfillmentId.set(f.id, Number(f.subtotal ?? 0));
                }
              }
              const goodsByGroup = new Map<string, number>();
              for (const g of activeDeliveryGroups) {
                let gGoods = 0;
                const gItems = Array.isArray(g.items) ? g.items : [];
                for (const it of gItems) {
                  if (it?.fulfillmentId) {
                    gGoods +=
                      subtotalByFulfillmentId.get(it.fulfillmentId) ?? 0;
                  }
                }
                goodsByGroup.set(g.id, gGoods);
              }
              const allActiveGoodsTotal = activeFulfillments.reduce(
                (sum: number, f: any) => sum + Number(f.subtotal ?? 0),
                0,
              );
              const allActiveFeesTotal = activeDeliveryGroups.reduce(
                (sum: number, g: any) =>
                  sum + (g.deliveryFee != null ? Number(g.deliveryFee) : 0),
                0,
              );
              const customerBonusFee = settings?.driverBonusPaidByCustomer
                ? Number(order.driverBonusFee ?? 0)
                : 0;
              const effectiveOrderTotal =
                order.grandTotal != null
                  ? grandTotal
                  : Math.max(
                      0,
                      allActiveGoodsTotal +
                        allActiveFeesTotal +
                        Number(order.serviceFee ?? 0) +
                        Number(order.tax ?? 0) +
                        customerBonusFee -
                        Number(order.discount ?? 0),
                    );
              const { allocations } = allocateOrderCashCollection({
                groups: activeDeliveryGroups,
                goodsByGroup,
                grandTotal: effectiveOrderTotal,
                upfrontAmount,
                paymentMethod: order.paymentMethod,
                isOrderSettledPrepaid,
              });
              cashToCollect = scopedGroups.reduce(
                (sum: number, g: any) =>
                  sum + (allocations.get(g.id)?.doorCashToCollect ?? 0),
                0,
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

    const isMultiVendor = computeIsMultiVendorOrder({
      orderIsMultiVendor: order.isMultiVendor,
      activeGroupsCount: activeDeliveryGroups.length,
      activeFulfillmentsCount: activeFulfillments.length,
    });
    const orderGoldSurcharge = Number(order.goldSurchargeAmount ?? 0);
    const fallbackDriverCtx = {
      isStacked: projectedIsStacked,
      isMultiVendor,
      driverTier:
        collectorGroup?.primaryDriverTierSnapshot ?? myDriver?.tier,
      distanceKm: Number(order.distanceKm ?? 0),
      isStandardOrder: order.type === 'STANDARD',
      goldSurcharge: orderGoldSurcharge,
    };
    let driverEarnings: number;
    if (customDriverEarnings != null) {
      driverEarnings = customDriverEarnings;
    } else if (
      typeof this.earnings.calculateDriverEarningsBreakdown === 'function'
    ) {
      const bd = this.earnings.calculateDriverEarningsBreakdown(
        deliveryFee,
        effectiveDriverSettings,
        fallbackDriverCtx,
      );
      projectedGoldBonusAmount =
        order.settledAt && order.settledGoldBonusAmount != null
          ? Number(order.settledGoldBonusAmount)
          : bd.goldBonus;
      projectedBronzeDeductionAmount =
        order.settledAt && order.settledBronzeDriverDeduction != null
          ? Number(order.settledBronzeDriverDeduction)
          : bd.bronzeDeduction;
      driverEarnings = bd.netEarnings;
    } else {
      driverEarnings = this.earnings.calculateDriverEarningsForFee(
        deliveryFee,
        effectiveDriverSettings,
        fallbackDriverCtx,
      );
    }

    const normalizedScopedItems = Array.isArray(scopedItems)
      ? scopedItems.map((i: any) => this.normalizeItemImage(i))
      : scopedItems;
    const normalizedScopedFulfillments = this.normalizeFulfillmentsItems(
      scopedFulfillments,
      normalizedScopedItems,
    );

    return {
      ...order,
      driverId: projectedDriverId,
      activeDeliveryGroupId,
      pickedUpAt: projectedPickedUpAt,
      pickupImageUrl: projectedPickupImageUrl,
      deliveryImageUrl: projectedDeliveryImageUrl,
      driverEarnings,
      deliveryFee,
      isPrimaryDriver,
      isAssistDriver,
      isPrimaryCollector,
      viewingDriverId: myDriver?.id ?? projectedDriverId,
      status: projectedStatus,
      isStacked: projectedIsStacked,
      vendor: this.normalizeVendorProjection(
        groupVendor ??
          (normalizedScopedFulfillments?.length === 1
            ? (order.vendor ?? null)
            : null),
      ),
      vendorBranch: groupVendorBranch,
      pickupLocation: groupPickupLocation,
      pickupAddress: groupPickupAddress,
      items: normalizedScopedItems,
      vendorFulfillments: normalizedScopedFulfillments,
      grandTotal: cashToCollect,
      total: cashToCollect,
      cashToCollect,
      upfrontAmount: projectedUpfrontAmount,
      serviceFee: 0,
      tax: 0,
      discount: 0,
      financials: {
        viewRole: 'DRIVER',
        isPrimaryDriver,
        isAssistDriver,
        isPrimaryCollector,
        cashToCollect,
        isPrepaid: isOrderSettledPrepaid,
        cashToPayStore: isAssistDriver ? 0 : cashToPayStore,
        isStorePrepaid,
        driverEarnings,
        goldBonusAmount: projectedGoldBonusAmount,
        bronzeDeductionAmount: projectedBronzeDeductionAmount,
        deliveryFee,
        storePayments:
          scopedFulfillments && scopedFulfillments.length > 0
            ? scopedFulfillments.map((f: any) => ({
                ...omitKeys(this.buildStorePaymentBase(f, false), [
                  'vendorNameEn',
                ]),
                ...(isAssistDriver ? { cashToPay: 0 } : {}),
                deliveryGroupId: f.deliveryGroupId ?? null,
                stopSequence: f.stopSequence ?? null,
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
    if (
      actor.role === Role.VENDOR_MEMBER &&
      ctx?.memberBranchId === undefined
    ) {
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
    let sortedVendorFulfillments: any[] = [];

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
      sortedVendorFulfillments = [...vendorFulfillments].sort(
        (a: any, b: any) =>
          (statusRank[String(a.status)] ?? 99) -
          (statusRank[String(b.status)] ?? 99),
      );
      const myFulfillment = sortedVendorFulfillments[0];
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

        const activeVendorFulfillments = vendorFulfillments.filter(
          (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
        );
        const isAllDeadPortion =
          vendorFulfillments.length > 0 &&
          activeVendorFulfillments.length === 0;
        const subtotalBasis =
          activeVendorFulfillments.length > 0
            ? activeVendorFulfillments
            : vendorFulfillments;

        vendorSubtotal = isAllDeadPortion
          ? 0
          : subtotalBasis.reduce(
              (sum: number, f: any) => sum + Number(f.subtotal ?? 0),
              0,
            );
        const totalCalculatedCommission = isAllDeadPortion
          ? 0
          : subtotalBasis.reduce((sum: number, f: any) => {
              const fContracted =
                f.isContracted ??
                f.vendorBranch?.isContracted ??
                f.vendor?.isContracted ??
                false;
              if (!fContracted) return sum;
              const fRate = Number(
                f.commissionRate ??
                  f.vendorBranch?.commissionRate ??
                  f.vendor?.commissionRate ??
                  10,
              );
              return sum + Math.round(Number(f.subtotal ?? 0) * (fRate / 100));
            }, 0);
        commissionRate =
          vendorSubtotal > 0 && totalCalculatedCommission > 0
            ? Number(
                ((totalCalculatedCommission / vendorSubtotal) * 100).toFixed(2),
              )
            : Number(
                myFulfillment.commissionRate ??
                  myFulfillment.vendorBranch?.commissionRate ??
                  myFulfillment.vendor?.commissionRate ??
                  10,
              );
        isContracted = subtotalBasis.some(
          (f: any) =>
            f.isContracted ??
            f.vendorBranch?.isContracted ??
            f.vendor?.isContracted ??
            false,
        );
        const myFulfillmentIds = new Set(subtotalBasis.map((f: any) => f.id));
        const directItems = subtotalBasis
          .flatMap((f: any) => (Array.isArray(f.items) ? f.items : []))
          .filter((i: any) => i.rejectedAt == null);
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

    const activeFulfillmentsForCommission = fulfillments.filter(
      (f: any) =>
        f.vendorId === vendorId &&
        (!memberBranchId ||
          !f.vendorBranchId ||
          f.vendorBranchId === memberBranchId) &&
        f.status !== 'REJECTED' &&
        f.status !== 'CANCELLED',
    );
    const allVendorFulfillments = fulfillments.filter(
      (f: any) =>
        f.vendorId === vendorId &&
        (!memberBranchId ||
          !f.vendorBranchId ||
          f.vendorBranchId === memberBranchId),
    );
    const allVendorPortionsDead =
      allVendorFulfillments.length > 0 &&
      activeFulfillmentsForCommission.length === 0;
    const commissionAmount = allVendorPortionsDead
      ? 0
      : activeFulfillmentsForCommission.length > 0
        ? activeFulfillmentsForCommission.reduce((sum: number, f: any) => {
            const fContracted =
              f.isContracted ??
              f.vendorBranch?.isContracted ??
              f.vendor?.isContracted ??
              false;
            if (!fContracted) return sum;
            const fRate = Number(
              f.commissionRate ??
                f.vendorBranch?.commissionRate ??
                f.vendor?.commissionRate ??
                10,
            );
            return sum + Math.round(Number(f.subtotal ?? 0) * (fRate / 100));
          }, 0)
        : isContracted
          ? Math.round(vendorSubtotal * (commissionRate / 100))
          : 0;
    const netPayout = Math.max(0, vendorSubtotal - commissionAmount);

    const myFulfillmentOnly = fulfillments.filter(
      (f: any) =>
        f.vendorId === vendorId &&
        (!memberBranchId ||
          !f.vendorBranchId ||
          f.vendorBranchId === memberBranchId),
    );
    const primaryFulfillment =
      sortedVendorFulfillments[0] ??
      myFulfillmentOnly[0] ??
      fulfillments.find((f: any) => f.vendorId === vendorId);

    const myVendorFulfillmentIds = new Set(
      myFulfillmentOnly.map((f: any) => f.id).filter(Boolean),
    );
    const activeGroupsCount = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    ).filter((g: any) => g.status !== 'CANCELLED').length;
    const isOrderMultiVendor = computeIsMultiVendorOrder({
      orderIsMultiVendor: order.isMultiVendor,
      activeGroupsCount,
      activeFulfillmentsCount: fulfillments.length,
    });
    const scopedStatusEvents = Array.isArray(order.statusEvents)
      ? order.statusEvents.filter((ev: any) => {
          if (ev.fulfillmentId) {
            return myVendorFulfillmentIds.has(ev.fulfillmentId);
          }
          if (isOrderMultiVendor) {
            // Keep multi-vendor vendor feeds isolated from other stores' notes/cancellations,
            // while still preserving whole-order placement and whole-order cancellation actor events.
            return (
              (ev.status === 'PENDING' && !ev.deliveryGroupId) ||
              ev.status === 'CANCELLED'
            );
          }
          return true;
        })
      : order.statusEvents;

    const deliveryGroups = Array.isArray(order.deliveryGroups)
      ? order.deliveryGroups
      : [];
    const nonCancelledGroups = deliveryGroups.filter(
      (g: any) => g.status !== 'CANCELLED',
    );
    const portionGroup =
      nonCancelledGroups.find(
        (g: any) =>
          Array.isArray(g.items) &&
          g.items.some((it: any) =>
            myVendorFulfillmentIds.has(it?.fulfillmentId),
          ),
      ) ??
      nonCancelledGroups.find((g: any) => g.isPaymentCollector === true) ??
      nonCancelledGroups.find(
        (g: any) => g.primaryDriver || g.primaryDriverId,
      ) ??
      nonCancelledGroups[0] ??
      null;
    const normalizedDriver = this.normalizeDriverProjection(
      portionGroup?.primaryDriver ?? null,
    );
    const normalizedItems = Array.isArray(items)
      ? items.map((i: any) => this.normalizeItemImage(i))
      : items;
    const normalizedFulfillments = this.normalizeFulfillmentsItems(
      myFulfillmentOnly,
      normalizedItems,
    );

    return {
      ...order,
      statusEvents: scopedStatusEvents,
      vendorId: vendorId ?? primaryFulfillment?.vendorId ?? null,
      vendorBranchId: primaryFulfillment?.vendorBranchId ?? null,
      status: portionStatus ?? order.status,
      orderStatus: order.status,
      myFulfillmentId,
      myFulfillmentStatus: portionStatus,
      items: normalizedItems,
      subtotal: vendorSubtotal,
      deliveryFee: 0,
      serviceFee: 0,
      tax: 0,
      driverBonusFee: 0,
      discount: 0,
      grandTotal: vendorSubtotal,
      total: vendorSubtotal,
      vendorFulfillments: normalizedFulfillments,
      deliveryGroups: [],
      driverId: portionGroup?.primaryDriverId ?? normalizedDriver?.id ?? null,
      driver: normalizedDriver,
      vendor: this.normalizeVendorProjection(primaryFulfillment?.vendor ?? null),
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

  projectForCustomer(order: any, ctx?: RoleProjectionContext): any {
    const isPrepaid =
      order.paymentMethod !== 'CASH_ON_DELIVERY' &&
      order.paymentMethod !== 'MOBILE_WALLET';
    const grandTotal = Number(order.grandTotal ?? 0);
    const upfrontAmount = Number(order.upfrontAmount ?? 0);
    const cashToPayAtDoor = isPrepaid
      ? 0
      : Math.max(0, grandTotal - upfrontAmount);
    const driverBonusPaidByCustomer = Boolean(
      order.driverBonusPaidByCustomer ??
      ctx?.settings?.driverBonusPaidByCustomer ??
      false,
    );
    const customerDriverBonusFee = driverBonusPaidByCustomer
      ? Number(order.driverBonusFee ?? 0)
      : 0;

    const sanitized: any = omitKeys(order, [
      'goldSurchargeAmount',
      'settledGoldBonusAmount',
      'settledGoldPlatformRetainedAmount',
      'settledBronzeDriverDeduction',
      'settledBronzeSupervisorDeduction',
      'settledBronzeDriverDeductionRate',
      'settledBronzeSupervisorDeductionRate',
    ]);
    if (Array.isArray(sanitized.deliveryGroups)) {
      sanitized.deliveryGroups = sanitized.deliveryGroups.map((g: any) =>
        omitKeys(g, [
          'goldSurchargeAmount',
          'primaryDriverTierSnapshot',
          'settledGoldBonusAmount',
          'settledGoldPlatformRetainedAmount',
          'settledBronzeDriverDeduction',
          'settledBronzeSupervisorDeduction',
          'settledPrimaryManagerId',
        ]),
      );
    }
    if (Array.isArray(sanitized.items)) {
      sanitized.items = sanitized.items
        .filter((i: any) => i.rejectedAt == null)
        .map((i: any) => this.normalizeItemImage(i));
    }
    if (sanitized.vendor) {
      sanitized.vendor = this.normalizeVendorProjection(
        omitKeys(sanitized.vendor, ['commissionRate', 'walletBalance']),
      );
    }
    if (sanitized.vendorBranch) {
      sanitized.vendorBranch = omitKeys(sanitized.vendorBranch, [
        'commissionRate',
      ]);
    }
    let fulfillmentSummary: any = null;
    if (
      Array.isArray(sanitized.vendorFulfillments) &&
      sanitized.vendorFulfillments.length > 0
    ) {
      const allGroupItems = (order.deliveryGroups ?? []).flatMap((g: any) =>
        Array.isArray(g.items) ? g.items : [],
      );

      sanitized.vendorFulfillments = sanitized.vendorFulfillments.map(
        (f: any) => {
          const safeF: any = omitKeys(f, ['commissionRate']);
          if (safeF.vendor) {
            safeF.vendor = omitKeys(safeF.vendor, [
              'commissionRate',
              'walletBalance',
            ]);
          }
          if (safeF.vendorBranch) {
            safeF.vendorBranch = omitKeys(safeF.vendorBranch, [
              'commissionRate',
            ]);
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
        },
      );

      sanitized.vendorFulfillments.sort((a: any, b: any) => {
        const seqA =
          allGroupItems.find((it: any) => it.fulfillmentId === a.id)
            ?.sequence ?? 0;
        const seqB =
          allGroupItems.find((it: any) => it.fulfillmentId === b.id)
            ?.sequence ?? 0;
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

      if (order.type == null || order.type === OrderType.STANDARD) {
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
      }

      if (!sanitized.vendor && sanitized.vendorFulfillments.length === 1) {
        sanitized.vendor = this.normalizeVendorProjection(
          sanitized.vendorFulfillments[0].vendor ?? null,
        );
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
      .sort(
        (a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
      );
    const collectorGroup =
      activeDeliveryGroups.find((g: any) => g.isPaymentCollector === true) ??
      activeDeliveryGroups[0] ??
      null;
    const primaryDriver =
      collectorGroup?.primaryDriver ??
      activeDeliveryGroups.find((g: any) => g.primaryDriver)?.primaryDriver ??
      null;

    if (sanitized.vendorFulfillments) {
      sanitized.vendorFulfillments = this.normalizeFulfillmentsItems(
        sanitized.vendorFulfillments,
        sanitized.items ?? [],
      );
    }

    return {
      ...sanitized,
      driverBonusPaidByCustomer,
      customerDriverBonusFee,
      driver: this.normalizeDriverProjection(primaryDriver ?? null),
      fulfillmentSummary,
      financials: {
        viewRole: 'CUSTOMER',
        cashToPayAtDoor,
        isPrepaid,
        driverBonusPaidByCustomer,
        customerDriverBonusFee,
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
    const cashToCollect = isPrepaid
      ? 0
      : Math.max(0, grandTotal - upfrontAmount);

    const activeDeliveryGroups = (
      Array.isArray(order.deliveryGroups) ? order.deliveryGroups : []
    )
      .filter((g: any) => g.status !== 'CANCELLED')
      .sort(
        (a: any, b: any) => Number(a.sequence ?? 0) - Number(b.sequence ?? 0),
      );
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
    const effectiveSettings =
      order.settledAt && order.settledBronzeDriverDeductionRate != null
        ? {
            ...settings,
            bronzeTierDeductionAmount: order.settledBronzeDriverDeductionRate,
          }
        : settings;
    const deliveryFee = Number(order.deliveryFee ?? 0);
    const isMultiVendor = computeIsMultiVendorOrder({
      orderIsMultiVendor: order.isMultiVendor,
      activeGroupsCount: activeDeliveryGroups.length,
      activeFulfillmentsCount,
    });
    const hasExplicitGroupGold = activeDeliveryGroups.some(
      (ag: any) => Number(ag.goldSurchargeAmount ?? 0) > 0,
    );
    const adminCollectorId = collectorGroup?.id ?? activeDeliveryGroups[0]?.id;
    let projectedGoldBonusAmount = 0;
    let projectedGoldPlatformRetained = 0;
    let projectedBronzeDriverDeduction = 0;

    const driverEarnings =
      activeDeliveryGroups.length > 0
        ? activeDeliveryGroups.reduce((sum: number, g: any) => {
            const gFee = g.deliveryFee != null ? Number(g.deliveryFee) : 0;
            const gGoldSurcharge = hasExplicitGroupGold
              ? Number(g.goldSurchargeAmount ?? 0)
              : g.id === adminCollectorId
                ? Number(order.goldSurchargeAmount ?? 0)
                : 0;
            const gTier =
              g.primaryDriverTierSnapshot ??
              g.primaryDriver?.tier ??
              order.driver?.tier;
            const gCtx = {
              isStacked: Boolean(g.isStacked),
              isMultiVendor,
              driverTier: gTier,
              distanceKm:
                g.distanceKm != null
                  ? Number(g.distanceKm)
                  : Number(order.distanceKm ?? 0),
              isStandardOrder: order.type === 'STANDARD',
              goldSurcharge: gGoldSurcharge,
            };
            if (
              typeof this.earnings.calculateDriverEarningsBreakdown ===
              'function'
            ) {
              const bd = this.earnings.calculateDriverEarningsBreakdown(
                gFee,
                effectiveSettings,
                gCtx,
              );
              projectedGoldBonusAmount += bd.goldBonus;
              projectedGoldPlatformRetained += bd.platformRetainedGoldSurcharge;
              projectedBronzeDriverDeduction += bd.bronzeDeduction;
              return sum + bd.netEarnings;
            }
            return (
              sum +
              this.earnings.calculateDriverEarningsForFee(
                gFee,
                effectiveSettings,
                gCtx,
              )
            );
          }, 0)
        : (() => {
            const ctx = {
              isStacked: Boolean(order.isStacked),
              isMultiVendor: false,
              driverTier:
                collectorGroup?.primaryDriverTierSnapshot ??
                order.driver?.tier,
              distanceKm: Number(order.distanceKm ?? 0),
              isStandardOrder: order.type === 'STANDARD',
              goldSurcharge: Number(order.goldSurchargeAmount ?? 0),
            };
            if (
              typeof this.earnings.calculateDriverEarningsBreakdown ===
              'function'
            ) {
              const bd = this.earnings.calculateDriverEarningsBreakdown(
                deliveryFee,
                effectiveSettings,
                ctx,
              );
              projectedGoldBonusAmount = bd.goldBonus;
              projectedGoldPlatformRetained = bd.platformRetainedGoldSurcharge;
              projectedBronzeDriverDeduction = bd.bronzeDeduction;
              return bd.netEarnings;
            }
            return this.earnings.calculateDriverEarningsForFee(
              deliveryFee,
              effectiveSettings,
              ctx,
            );
          })();

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
      vendor = this.normalizeVendorProjection(fulfillments[0].vendor ?? null);
      vendorBranch = fulfillments[0].vendorBranch ?? null;
    }

    const primaryDriver =
      collectorGroup?.primaryDriver ??
      activeDeliveryGroups.find((g: any) => g.primaryDriver)?.primaryDriver ??
      null;

    const normalizedOrderItems = Array.isArray(order.items)
      ? order.items.map((i: any) => this.normalizeItemImage(i))
      : order.items;
    const normalizedAdminFulfillments = this.normalizeFulfillmentsItems(
      fulfillments,
      normalizedOrderItems,
    );

    return {
      ...order,
      items: normalizedOrderItems,
      vendorFulfillments: normalizedAdminFulfillments,
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
      driver: this.normalizeDriverProjection(primaryDriver),
      financials: {
        viewRole: 'ADMIN',
        cashToCollect,
        isPrepaid,
        cashToPayStore: resolvedCashToPayStore,
        isStorePrepaid: resolvedIsStorePrepaid,
        driverEarnings,
        deliveryFee,
        goldSurchargeAmount: Number(order.goldSurchargeAmount ?? 0),
        goldBonusAmount: order.settledAt
          ? Number(order.settledGoldBonusAmount ?? projectedGoldBonusAmount)
          : projectedGoldBonusAmount,
        goldPlatformRetainedAmount: order.settledAt
          ? Number(
              order.settledGoldPlatformRetainedAmount ??
                projectedGoldPlatformRetained,
            )
          : projectedGoldPlatformRetained,
        bronzeDriverDeduction: order.settledAt
          ? Number(
              order.settledBronzeDriverDeduction ??
                projectedBronzeDriverDeduction,
            )
          : projectedBronzeDriverDeduction,
        bronzeSupervisorDeduction: order.settledAt
          ? Number(order.settledBronzeSupervisorDeduction ?? 0)
          : 0,
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
      vendorLogo: resolveVendorDisplayLogo(f.vendor),
      vendorName:
        f.vendor?.storeNameAr ??
        f.vendor?.storeName ??
        f.vendor?.name ??
        'Store',
      vendorNameEn:
        f.vendor?.storeName ??
        f.vendor?.storeNameAr ??
        f.vendor?.name ??
        'Store',
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

  private normalizeVendorProjection(vendor: any) {
    if (!vendor || typeof vendor !== 'object') return vendor ?? null;
    const resolvedLogo = resolveVendorDisplayLogo(vendor);
    if (resolvedLogo == null || vendor.logo === resolvedLogo) return vendor;
    return {
      ...vendor,
      logo: resolvedLogo,
    };
  }

  private normalizeDriverProjection(driver: any) {
    if (!driver || typeof driver !== 'object') return null;
    const resolvedAvatar = driver.avatar ?? driver.user?.avatar ?? null;
    return {
      ...driver,
      avatar: resolvedAvatar,
      ...(driver.user
        ? {
            user: {
              ...driver.user,
              avatar: driver.user.avatar ?? resolvedAvatar,
            },
          }
        : {}),
    };
  }

  private normalizeItemImage(item: any) {
    if (!item || typeof item !== 'object') return item;
    const imageUrl = item.imageUrl ?? item.product?.imageUrl ?? null;
    if (item.imageUrl === imageUrl) return item;
    return {
      ...item,
      imageUrl,
    };
  }

  private normalizeFulfillmentsItems(fulfillments: any[], orderItems: any[]) {
    if (!Array.isArray(fulfillments)) return fulfillments;
    return fulfillments.map((f: any) => {
      if (!f || typeof f !== 'object') return f;
      const rawItems =
        Array.isArray(f.items) && f.items.length > 0
          ? f.items
          : Array.isArray(orderItems)
            ? orderItems.filter(
                (i: any) => i?.rejectedAt == null && i?.fulfillmentId === f.id,
              )
            : [];
      return {
        ...f,
        ...(f.vendor !== undefined
          ? { vendor: this.normalizeVendorProjection(f.vendor) }
          : {}),
        items: rawItems
          .filter((i: any) => i?.rejectedAt == null)
          .map((i: any) => this.normalizeItemImage(i)),
      };
    });
  }
}
