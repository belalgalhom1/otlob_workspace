import { OrderStatus, Prisma, Role } from '@prisma/client';

export interface OrderActorSnapshot {
  actorUserId: string | null;
  actorRole: Role | null;
  actorName: string;
  actorNameAr: string | null;
  actorAvatar: string | null;
  actorVendorId: string | null;
  isSystem: boolean;
}

export interface OrderActorSummary {
  id: string | null;
  name: string;
  nameAr: string | null;
  role: Role | null;
  avatar: string | null;
  vendorId: string | null;
  isSystem: boolean;
}

export interface OrderCancelledBySummary {
  userId: string | null;
  name: string;
  nameAr: string | null;
  role: Role | null;
  avatar: string | null;
  vendorId: string | null;
  reason: string | null;
  cancelledAt: Date | string | null;
  isSystem: boolean;
}

export interface FulfillmentLabelSource {
  vendor?: {
    storeName?: string | null;
    storeNameAr?: string | null;
  } | null;
  vendorBranch?: {
    name?: string | null;
    nameAr?: string | null;
  } | null;
}

export interface EventActorVendorInfo {
  id?: string | null;
  storeName?: string | null;
  storeNameAr?: string | null;
  logo?: string | null;
  coverImage?: string | null;
}

export function resolveVendorDisplayLogo(
  vendor?: { logo?: string | null; coverImage?: string | null } | null,
): string | null {
  if (!vendor) return null;
  const logo = typeof vendor.logo === 'string' ? vendor.logo.trim() : '';
  if (logo.length > 0 && logo.toLowerCase() !== 'null' && logo.toLowerCase() !== 'undefined') {
    return logo;
  }
  const cover =
    typeof vendor.coverImage === 'string' ? vendor.coverImage.trim() : '';
  if (cover.length > 0 && cover.toLowerCase() !== 'null' && cover.toLowerCase() !== 'undefined') {
    return cover;
  }
  return null;
}

export function resolveDriverDisplayAvatar(
  driver?: {
    avatar?: string | null;
    user?: { avatar?: string | null } | null;
  } | null,
): string | null {
  if (!driver) return null;
  const candidates = [driver.avatar, driver.user?.avatar];
  for (const raw of candidates) {
    if (typeof raw !== 'string') continue;
    const trimmed = raw.trim();
    const lower = trimmed.toLowerCase();
    if (trimmed.length > 0 && lower !== 'null' && lower !== 'undefined') {
      return trimmed;
    }
  }
  return null;
}

export interface EventActorUserInfo {
  id?: string | null;
  name?: string | null;
  role?: Role | null;
  avatar?: string | null;
  driver?: { name?: string | null; avatar?: string | null } | null;
  vendorMemberships?: Array<{
    vendorId: string;
    vendor?: EventActorVendorInfo | null;
  }> | null;
}

export interface StatusEventLike {
  status?: string | null;
  note?: string | null;
  createdBy?: string | null;
  fulfillmentId?: string | null;
  actorUserId?: string | null;
  actorRole?: Role | null;
  actorName?: string | null;
  actorNameAr?: string | null;
  actorAvatar?: string | null;
  actorVendorId?: string | null;
  actorUser?: EventActorUserInfo | null;
  actorVendor?: EventActorVendorInfo | null;
  fulfillment?:
    (FulfillmentLabelSource & { vendor?: EventActorVendorInfo | null }) | null;
}

interface PrismaLike {
  user?: {
    findUnique?: (args: unknown) => Promise<EventActorUserInfo | null>;
  };
  orderVendorFulfillment?: {
    findUnique?: (
      args: unknown,
    ) => Promise<{ vendor?: EventActorVendorInfo | null } | null>;
    findFirst?: (
      args: unknown,
    ) => Promise<{ vendor?: EventActorVendorInfo | null } | null>;
  };
}

interface TxLike {
  orderStatusEvent?: {
    create?: (args: {
      data: Prisma.OrderStatusEventUncheckedCreateInput;
    }) => Promise<unknown>;
    createMany?: (args: {
      data: Prisma.OrderStatusEventUncheckedCreateInput[];
      skipDuplicates?: boolean;
    }) => Promise<{ count: number }>;
  };
}

const GENERIC_CANCEL_PLACEHOLDERS = new Set([
  'cancelled by user',
  'canceled by user',
  'cancelled by admin',
  'canceled by admin',
  'cancelled by vendor',
  'canceled by vendor',
]);

export function sanitizeCancelReason(reason?: string | null): string | null {
  const trimmed = reason?.trim();
  if (!trimmed) return null;
  if (GENERIC_CANCEL_PLACEHOLDERS.has(trimmed.toLowerCase())) {
    return null;
  }
  return trimmed;
}

export function systemActorSnapshot(): OrderActorSnapshot {
  return {
    actorUserId: null,
    actorRole: null,
    actorName: 'System',
    actorNameAr: 'النظام',
    actorAvatar: null,
    actorVendorId: null,
    isSystem: true,
  };
}

export function formatFulfillmentStoreLabel(
  fulfillment?: FulfillmentLabelSource | null,
): string | null {
  if (!fulfillment) return null;
  const storeName =
    fulfillment.vendor?.storeName?.trim() ||
    fulfillment.vendor?.storeNameAr?.trim() ||
    '';
  const branchName =
    fulfillment.vendorBranch?.name?.trim() ||
    fulfillment.vendorBranch?.nameAr?.trim() ||
    '';
  if (
    storeName &&
    branchName &&
    branchName.toLowerCase() !== storeName.toLowerCase()
  ) {
    return `${storeName} (${branchName})`;
  }
  return storeName || branchName || null;
}

export function formatFulfillmentStoreLabelAr(
  fulfillment?: FulfillmentLabelSource | null,
): string | null {
  if (!fulfillment) return null;
  const storeName =
    fulfillment.vendor?.storeNameAr?.trim() ||
    fulfillment.vendor?.storeName?.trim() ||
    '';
  const branchName =
    fulfillment.vendorBranch?.nameAr?.trim() ||
    fulfillment.vendorBranch?.name?.trim() ||
    '';
  if (
    storeName &&
    branchName &&
    branchName.toLowerCase() !== storeName.toLowerCase()
  ) {
    return `${storeName} (${branchName})`;
  }
  return storeName || branchName || null;
}

export async function resolveOrderActorSnapshot(
  prisma: unknown,
  actorUserId?: string | null,
  options?: {
    fallbackRole?: Role | null;
    vendorId?: string | null;
    fulfillmentId?: string | null;
    orderId?: string | null;
  },
): Promise<OrderActorSnapshot> {
  if (!actorUserId || actorUserId === 'system') {
    return systemActorSnapshot();
  }

  const client = prisma as PrismaLike | null | undefined;
  try {
    const user = await client?.user?.findUnique?.({
      where: { id: actorUserId },
      select: {
        id: true,
        name: true,
        role: true,
        avatar: true,
        driver: { select: { name: true, avatar: true } },
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

    if (!user) {
      return {
        actorUserId,
        actorRole: options?.fallbackRole ?? null,
        actorName: roleFallbackLabel(options?.fallbackRole),
        actorNameAr: roleFallbackLabelAr(options?.fallbackRole),
        actorAvatar: null,
        actorVendorId: options?.vendorId ?? null,
        isSystem: false,
      };
    }

    const role: Role = user.role ?? options?.fallbackRole ?? Role.CUSTOMER;
    let vendor: EventActorVendorInfo | null = null;

    if (role === Role.VENDOR_MEMBER) {
      if (
        options?.fulfillmentId &&
        client?.orderVendorFulfillment?.findUnique
      ) {
        const ff = await client.orderVendorFulfillment.findUnique({
          where: { id: options.fulfillmentId },
          select: {
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
        });
        vendor = ff?.vendor ?? null;
      }

      const memberships = Array.isArray(user.vendorMemberships)
        ? user.vendorMemberships
        : [];
      if (!vendor && options?.vendorId) {
        vendor =
          memberships.find((m) => m.vendorId === options.vendorId)?.vendor ??
          null;
      }
      if (
        !vendor &&
        options?.orderId &&
        client?.orderVendorFulfillment?.findFirst
      ) {
        const ff = await client.orderVendorFulfillment.findFirst({
          where: {
            orderId: options.orderId,
            ...(memberships.length > 0
              ? { vendorId: { in: memberships.map((m) => m.vendorId) } }
              : {}),
          },
          select: {
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
        });
        vendor = ff?.vendor ?? null;
      }
      if (!vendor && memberships.length > 0) {
        vendor = memberships[0].vendor ?? null;
      }

      if (vendor) {
        return {
          actorUserId: user.id ?? actorUserId,
          actorRole: Role.VENDOR_MEMBER,
          actorName: vendor.storeName || user.name || 'Vendor',
          actorNameAr: vendor.storeNameAr || vendor.storeName || null,
          actorAvatar: resolveVendorDisplayLogo(vendor) ?? user.avatar ?? null,
          actorVendorId: vendor.id ?? null,
          isSystem: false,
        };
      }
    }

    if (role === Role.DRIVER) {
      return {
        actorUserId: user.id ?? actorUserId,
        actorRole: Role.DRIVER,
        actorName: user.driver?.name || user.name || 'Driver',
        actorNameAr: null,
        actorAvatar: user.driver?.avatar ?? user.avatar ?? null,
        actorVendorId: null,
        isSystem: false,
      };
    }

    return {
      actorUserId: user.id ?? actorUserId,
      actorRole: role,
      actorName: user.name || roleFallbackLabel(role),
      actorNameAr: null,
      actorAvatar: user.avatar ?? null,
      actorVendorId: null,
      isSystem: false,
    };
  } catch {
    return {
      actorUserId,
      actorRole: options?.fallbackRole ?? null,
      actorName: roleFallbackLabel(options?.fallbackRole),
      actorNameAr: roleFallbackLabelAr(options?.fallbackRole),
      actorAvatar: null,
      actorVendorId: options?.vendorId ?? null,
      isSystem: false,
    };
  }
}

export interface RecordOrderStatusEventInput {
  orderId: string;
  fulfillmentId?: string | null;
  deliveryGroupId?: string | null;
  eventKey?: string | null;
  status: OrderStatus;
  note?: string | null;
  createdBy?: string | null;
  actor?: OrderActorSnapshot | null;
}

export async function recordOrderStatusEventIdempotent(
  tx: unknown,
  input: RecordOrderStatusEventInput,
): Promise<{ created: boolean; record?: unknown }> {
  const client = tx as TxLike | null | undefined;
  const repo = client?.orderStatusEvent;
  if (!repo?.create && !repo?.createMany) return { created: false };

  const actor = input.actor;
  const createdByValue = input.createdBy ?? actor?.actorUserId ?? 'system';

  const data: Prisma.OrderStatusEventUncheckedCreateInput = {
    orderId: input.orderId,
    status: input.status,
    note: input.note ?? null,
    createdBy: createdByValue,
    ...(input.fulfillmentId ? { fulfillmentId: input.fulfillmentId } : {}),
    ...(input.deliveryGroupId
      ? { deliveryGroupId: input.deliveryGroupId }
      : {}),
    ...(input.eventKey ? { eventKey: input.eventKey } : {}),
    ...(actor
      ? {
          actorUserId: actor.actorUserId,
          actorRole: actor.actorRole,
          actorName: actor.actorName,
          actorNameAr: actor.actorNameAr,
          actorAvatar: actor.actorAvatar,
          actorVendorId: actor.actorVendorId,
        }
      : {}),
  };

  // Prefer createMany({ skipDuplicates: true }) (PostgreSQL INSERT ... ON
  // CONFLICT DO NOTHING) whenever available so duplicate eventKeys never raise
  // 23505/P2002 and poison an enclosing Postgres $transaction with 25P02.
  if (typeof repo.createMany === 'function') {
    const res = await repo.createMany({
      data: [data],
      skipDuplicates: true,
    });
    return { created: (res?.count ?? 0) > 0 };
  }

  try {
    const record = await repo.create!({ data });
    return { created: true, record };
  } catch (err: unknown) {
    if (
      typeof err === 'object' &&
      err !== null &&
      (err as { code?: string }).code === 'P2002'
    ) {
      return { created: false };
    }
    throw err;
  }
}

export function roleFallbackLabel(role?: Role | null): string {
  switch (role) {
    case Role.CUSTOMER:
      return 'Customer';
    case Role.VENDOR_MEMBER:
      return 'Vendor';
    case Role.DRIVER:
      return 'Driver';
    case Role.DRIVER_MANAGER:
      return 'Driver Manager';
    case Role.ADMIN:
      return 'Admin';
    case Role.SUPER_ADMIN:
      return 'Super Admin';
    default:
      return 'System';
  }
}

export function roleFallbackLabelAr(role?: Role | null): string {
  switch (role) {
    case Role.CUSTOMER:
      return 'العميل';
    case Role.VENDOR_MEMBER:
      return 'المتجر';
    case Role.DRIVER:
      return 'المندوب';
    case Role.DRIVER_MANAGER:
      return 'مشرف المناديب';
    case Role.ADMIN:
      return 'الإدارة';
    case Role.SUPER_ADMIN:
      return 'الإدارة العليا';
    default:
      return 'النظام';
  }
}

export function normalizeLegacyEventNote(ev: StatusEventLike): string | null {
  const rawNote = ev?.note?.trim() ?? '';
  if (!rawNote) return null;

  if (ev?.status === OrderStatus.CANCELLED && !sanitizeCancelReason(rawNote)) {
    return null;
  }

  const storeLabel = formatFulfillmentStoreLabel(ev?.fulfillment);
  if (storeLabel && ev?.fulfillmentId) {
    if (/^Delivery \d+: vendor portion ready for pickup$/i.test(rawNote)) {
      return `${storeLabel}: vendor portion ready for pickup`;
    }
    if (/^Delivery \d+: vendor portion started preparing$/i.test(rawNote)) {
      return `${storeLabel}: vendor portion started preparing`;
    }
    if (rawNote === `Driver picked up fulfillment stop ${ev.fulfillmentId}`) {
      return `Driver picked up from ${storeLabel}`;
    }
  }

  return rawNote;
}

export function resolveEventActorSummary(
  ev: StatusEventLike,
  userLookup?: Map<string, EventActorUserInfo>,
): OrderActorSummary {
  const isSystemCreatedBy =
    !ev?.actorUserId && (!ev?.createdBy || ev.createdBy === 'system');
  if (isSystemCreatedBy) {
    return {
      id: null,
      name: 'System',
      nameAr: 'النظام',
      role: null,
      avatar: null,
      vendorId: null,
      isSystem: true,
    };
  }

  const uid: string | null =
    ev?.actorUserId ??
    (ev?.createdBy !== 'system' ? ev?.createdBy : null) ??
    null;
  const user =
    ev?.actorUser ?? (uid ? userLookup?.get(uid) : undefined) ?? null;
  const vendor = ev?.actorVendor ?? ev?.fulfillment?.vendor ?? null;
  const role: Role | null = ev?.actorRole ?? user?.role ?? null;

  if (role === Role.VENDOR_MEMBER || vendor) {
    const storeName =
      vendor?.storeName ?? ev?.actorName ?? user?.name ?? 'Vendor';
    const storeNameAr = vendor?.storeNameAr ?? ev?.actorNameAr ?? null;
    const avatar =
      resolveVendorDisplayLogo(vendor) ??
      ev?.actorAvatar ??
      user?.avatar ??
      null;
    return {
      id: uid,
      name: storeName,
      nameAr: storeNameAr,
      role: Role.VENDOR_MEMBER,
      avatar,
      vendorId: ev?.actorVendorId ?? vendor?.id ?? null,
      isSystem: false,
    };
  }

  if (role === Role.DRIVER) {
    return {
      id: uid,
      name: user?.driver?.name ?? ev?.actorName ?? user?.name ?? 'Driver',
      nameAr: ev?.actorNameAr ?? null,
      role: Role.DRIVER,
      avatar: user?.driver?.avatar ?? ev?.actorAvatar ?? user?.avatar ?? null,
      vendorId: null,
      isSystem: false,
    };
  }

  const resolvedName = ev?.actorName ?? user?.name ?? roleFallbackLabel(role);
  return {
    id: uid,
    name: resolvedName,
    nameAr:
      ev?.actorNameAr ??
      (resolvedName === roleFallbackLabel(role)
        ? roleFallbackLabelAr(role)
        : null),
    role,
    avatar: ev?.actorAvatar ?? user?.avatar ?? null,
    vendorId: ev?.actorVendorId ?? null,
    isSystem: false,
  };
}
