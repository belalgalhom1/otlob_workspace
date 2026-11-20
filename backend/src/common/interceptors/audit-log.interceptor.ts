import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { Role, AuditActionType, Prisma } from '@prisma/client';
import { JwtAccessPayload } from '../interfaces/jwt-payload.interface';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { EVENTS } from '../events/event-names';
import { AuditLogCreatedEvent } from '../events';

@Injectable()
export class AuditLogInterceptor implements NestInterceptor {
  private readonly logger = new Logger(AuditLogInterceptor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  private static readonly SENSITIVE_KEY_REGEX =
    /(password|secret|token|otp|pin|auth|credential|cvv|cardnumber|nationalid|licensenumber|apikey|privatekey)/i;

  private redactSensitiveFields(obj: unknown): unknown {
    if (!obj || typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) {
      return obj.map((item) => this.redactSensitiveFields(item));
    }

    const redacted = { ...(obj as Record<string, unknown>) };

    for (const key of Object.keys(redacted)) {
      const cleanKey = key.replace(/[^a-zA-Z0-9]/g, '');
      if (AuditLogInterceptor.SENSITIVE_KEY_REGEX.test(cleanKey)) {
        redacted[key] = '[REDACTED]';
      } else if (typeof redacted[key] === 'object' && redacted[key] !== null) {
        redacted[key] = this.redactSensitiveFields(redacted[key]);
      }
    }
    return redacted;
  }

  private shouldAudit(
    user: JwtAccessPayload | undefined,
    method: string,
    entityType: string,
    cleanPath: string,
  ): boolean {
    if (['GET', 'OPTIONS', 'HEAD'].includes(method)) return false;
    if (!user || !user.role) return false;

    // Fee-estimate POST routes perform read-only pricing calculations.
    if (entityType === 'Orders' && cleanPath.endsWith('-estimate')) {
      return false;
    }

    const adminOrVendorRoles: Role[] = [
      Role.VENDOR_MEMBER,
      Role.ADMIN,
      Role.SUPER_ADMIN,
    ];
    if (adminOrVendorRoles.includes(user.role)) return true;

    // Customer mutations on Orders (placing/cancelling/receipt upload) are audited;
    // high-volume non-order actions (cart, favorites, fcm tokens) remain skipped.
    return user.role === Role.CUSTOMER && entityType === 'Orders';
  }

  private buildOrderAuditDetails(order: Record<string, any>): {
    vendorId: string | null;
    facts: Record<string, unknown>;
  } {
    const fulfillments = Array.isArray(order.vendorFulfillments)
      ? (order.vendorFulfillments as Array<Record<string, any>>)
      : [];
    const distinctVendorIds = Array.from(
      new Set(
        fulfillments
          .map((f) => f.vendorId)
          .filter(
            (id): id is string => typeof id === 'string' && id.length > 0,
          ),
      ),
    );
    if (
      distinctVendorIds.length === 0 &&
      typeof order.vendorId === 'string' &&
      order.vendorId.length > 0
    ) {
      distinctVendorIds.push(order.vendorId);
    }

    const vendorNamesEn = fulfillments
      .map((f) => f.vendor?.storeName)
      .filter(Boolean);
    const vendorNamesAr = fulfillments
      .map((f) => f.vendor?.storeNameAr ?? f.vendor?.storeName)
      .filter(Boolean);
    const fallbackVendor = order.vendor as Record<string, any> | undefined;
    if (vendorNamesEn.length === 0 && fallbackVendor?.storeName) {
      vendorNamesEn.push(fallbackVendor.storeName);
    }
    if (
      vendorNamesAr.length === 0 &&
      (fallbackVendor?.storeNameAr || fallbackVendor?.storeName)
    ) {
      vendorNamesAr.push(
        fallbackVendor?.storeNameAr ?? fallbackVendor?.storeName,
      );
    }

    const deliveryGroupsCount = Array.isArray(order.deliveryGroups)
      ? order.deliveryGroups.length
      : Number(order.deliveryGroupsCount ?? 0);
    const isMulti =
      Boolean(order.isMultiVendor) ||
      distinctVendorIds.length > 1 ||
      fulfillments.length > 1 ||
      deliveryGroupsCount > 1;

    const facts: Record<string, unknown> = {
      Order: order.orderNumber ?? order.id ?? '—',
      Status: String(order.status ?? 'PENDING'),
      Total: `${Number(order.grandTotal ?? 0)} EGP`,
      Payment: order.paymentMethod
        ? String(order.paymentMethod).replace(/_/g, ' ')
        : '—',
      Vendor: this.bi(
        vendorNamesEn.length > 0 ? vendorNamesEn.join(' + ') : null,
        vendorNamesAr.length > 0 ? vendorNamesAr.join(' + ') : null,
      ),
    };

    if (isMulti) {
      facts.Stores = String(
        Math.max(distinctVendorIds.length, fulfillments.length, 1),
      );
      facts.Deliveries = String(Math.max(deliveryGroupsCount, 1));
    }

    return {
      // Multi-vendor orders span independent vendors: keep vendorId null so no
      // single store's audit feed leaks another store's order details.
      vendorId: distinctVendorIds.length === 1 ? distinctVendorIds[0] : null,
      facts,
    };
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<{
      method: string;
      url: string;
      body: unknown;
      params: Record<string, string>;
      user?: JwtAccessPayload;
    }>();
    const { method, url, body, params, user } = req;
    const cleanPath = url.split('?')[0];

    // Pre-handler snapshot: for updates/deletes we must read the row BEFORE
    // the handler mutates/removes it, otherwise old values are lost forever.
    // A few indexed PK lookups (~ms); failures simply skip enrichment.
    const controllerClass = context.getClass();
    const entityType =
      controllerClass && controllerClass.name
        ? controllerClass.name.replace('Controller', '')
        : (() => {
            const segs = cleanPath.split('/').filter(Boolean);
            return segs.length > 1 ? segs[1] : 'Unknown';
          })();
    const shouldAuditRequest = this.shouldAudit(
      user,
      method,
      entityType,
      cleanPath,
    );
    const targetId = this.extractTargetId(url, params);
    const needsPreSnapshot =
      shouldAuditRequest &&
      ((['PUT', 'PATCH', 'DELETE'].includes(method) &&
        (Boolean(targetId) || entityType === 'PlatformSettings')) ||
        (entityType === 'Orders' && Boolean(targetId)));
    const prework = needsPreSnapshot
      ? this.snapshotEntity(entityType, targetId, url, body).catch(() => null)
      : Promise.resolve(null);

    return from(prework).pipe(
      switchMap((snapshot) =>
        next.handle().pipe(
          tap((response) => {
            try {
              if (!shouldAuditRequest || !user) return;

              // Determine action type
              let actionType: AuditActionType = AuditActionType.OTHER;
              if (method === 'POST') actionType = AuditActionType.CREATE;
              else if (method === 'PUT' || method === 'PATCH')
                actionType = AuditActionType.UPDATE;
              else if (method === 'DELETE') actionType = AuditActionType.DELETE;

              let entityId = 'unknown';
              if (params && params.id) {
                entityId = params.id;
              } else if (response && (response as Record<string, unknown>).id) {
                entityId = (response as Record<string, unknown>).id as string;
              }
              if ((!entityId || entityId === 'unknown') && targetId) {
                entityId = targetId;
              }

              const createdOrderDetails =
                entityType === 'Orders' &&
                !snapshot &&
                response &&
                typeof response === 'object'
                  ? this.buildOrderAuditDetails(
                      response as Record<string, unknown>,
                    )
                  : null;

              const tokenVendorId =
                (user as JwtAccessPayload & { vendorId?: string }).vendorId ||
                null;
              const vendorId =
                snapshot?.vendorId !== undefined
                  ? snapshot.vendorId
                  : createdOrderDetails !== null
                    ? createdOrderDetails.vendorId
                    : tokenVendorId;
              const sessionId = user.sid || null;
              const redactedBody = body
                ? this.redactSensitiveFields(body)
                : null;

              // Merge human facts (zone, driver, totals...) into newValues
              // under the reserved `_facts` key so the audit UI can render
              // a professional summary. Raw diff rendering skips `_` keys.
              let newValues: unknown = redactedBody ?? Prisma.DbNull;
              const facts = snapshot?.facts ?? createdOrderDetails?.facts;
              if (facts && Object.keys(facts).length > 0) {
                const base =
                  newValues &&
                  typeof newValues === 'object' &&
                  !Array.isArray(newValues)
                    ? { ...(newValues as Record<string, unknown>) }
                    : {};
                newValues = { ...base, _facts: facts };
              }

              if (entityType === 'Orders') {
                const orderNum =
                  facts && typeof facts.Order === 'string'
                    ? ` (${facts.Order})`
                    : '';
                this.logger.log(
                  `[AUDIT] ${actionType} Orders/${entityId}${orderNum} by ${user.role}:${user.sub} via ${method} ${cleanPath}`,
                );
              }

              // Log it (fire and forget)
              this.eventEmitter.emit(
                EVENTS.AUDIT_LOG_CREATED,
                new AuditLogCreatedEvent(
                  user.sub,
                  vendorId,
                  sessionId,
                  actionType,
                  `${method} ${cleanPath}`,
                  entityType,
                  String(entityId),
                  newValues,
                  snapshot
                    ? this.redactSensitiveFields(snapshot.oldValues)
                    : Prisma.DbNull,
                ),
              );
            } catch (err) {
              this.logger.error(
                'AuditLogInterceptor error',
                err instanceof Error ? err.stack : String(err),
              );
            }
          }),
        ),
      ),
    );
  }

  /**
   * Deepest resource id for the request: explicit `:id` param first, else
   * the LAST UUID-like token in the path (nested routes address the deepest
   * resource, e.g. `.../variants/:variantId`), else any other route param.
   */
  private extractTargetId(
    url: string,
    params?: Record<string, string>,
  ): string | null {
    if (params?.id) return params.id;
    const tokens =
      url
        .split('?')[0]
        .match(/[0-9a-fA-F]{8}-[0-9a-fA-F-]{10,}|[0-9a-fA-F-]{20,}/g) ?? [];
    if (tokens.length > 0) return tokens[tokens.length - 1];
    if (params) {
      for (const value of Object.values(params)) {
        if (typeof value === 'string' && value.length >= 8) return value;
      }
    }
    return null;
  }

  private fmtDate(value: unknown): string {
    try {
      const d = value instanceof Date ? value : new Date(value as string);
      const p = (n: number) => String(n).padStart(2, '0');
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
    } catch {
      return '';
    }
  }

  private fmtTime(value: unknown): string {
    try {
      const d = value instanceof Date ? value : new Date(value as string);
      const p = (n: number) => String(n).padStart(2, '0');
      return `${p(d.getHours())}:${p(d.getMinutes())}`;
    } catch {
      return '';
    }
  }

  private iso(value: unknown): string {
    try {
      const d = value instanceof Date ? value : new Date(value as string);
      return d.toISOString();
    } catch {
      return String(value ?? '');
    }
  }

  /**
   * Bilingual display value for audit facts/diffs: `{ en, ar }`. Falls back
   * to English when no Arabic value exists so the client can pick by locale.
   */
  private bi(en: unknown, ar?: unknown): { en: string; ar: string } {
    const e = en === null || en === undefined || en === '' ? '—' : String(en);
    const a = ar === null || ar === undefined || ar === '' ? e : String(ar);
    return { en: e, ar: a };
  }

  /**
   * Pre-change snapshot + human facts for the admin-managed entities.
   * Returns null when nothing resolvable (caller falls back to raw logging).
   */
  private async snapshotEntity(
    entityType: string,
    targetId: string | null,
    url: string,
    body?: unknown,
  ): Promise<{
    oldValues: Record<string, unknown>;
    facts: Record<string, unknown>;
    vendorId?: string | null;
  } | null> {
    const path = url.split('?')[0];
    // Settings edits address the singleton row (no id in path): snapshot
    // the previous values of exactly the keys being changed.
    if (entityType === 'PlatformSettings') {
      if (!body || typeof body !== 'object' || Array.isArray(body)) {
        return null;
      }
      const keys = Object.keys(body as Record<string, unknown>)
        .filter((k) => /^[A-Za-z][A-Za-z0-9]*$/.test(k))
        .slice(0, 15);
      if (keys.length === 0) return null;
      const select = Object.fromEntries(keys.map((k) => [k, true]));
      const current = await this.prisma.platformSetting.findUnique({
        where: { id: 'default' },

        select: select as any,
      });
      if (!current) return null;
      const oldValues: Record<string, unknown> = {};
      const facts: Record<string, string> = {};
      for (const key of keys) {
        const value = (current as Record<string, unknown>)[key];
        oldValues[key] = value;
        facts[key] = String(value ?? '—');
      }
      return { oldValues, facts };
    }
    if (!targetId) return null;
    switch (entityType) {
      case 'DriverShifts': {
        if (path.includes('/pools/')) {
          const pool = await this.prisma.shiftPool.findUnique({
            where: { id: targetId },
            include: {
              zone: { select: { name: true, nameAr: true } },
              _count: { select: { driverShifts: true } },
            },
          });
          if (!pool) return null;
          return {
            oldValues: {
              zoneId: pool.zoneId,
              shiftDate: this.iso(pool.shiftDate),
              startTime: this.iso(pool.startTime),
              endTime: this.iso(pool.endTime),
              maxDrivers: pool.maxDrivers,
            },
            facts: {
              Zone: this.bi(pool.zone?.name, pool.zone?.nameAr),
              Date: this.fmtDate(pool.shiftDate),
              Window: `${this.fmtTime(pool.startTime)} - ${this.fmtTime(pool.endTime)}`,
              'Max drivers': String(pool.maxDrivers),
              'Assigned drivers': String(pool._count.driverShifts),
            },
          };
        }
        const shift = await this.prisma.driverShift.findUnique({
          where: { id: targetId },
          include: {
            driver: { select: { name: true } },
            zone: { select: { name: true, nameAr: true } },
          },
        });
        if (!shift) return null;
        return {
          oldValues: {
            driverId: shift.driverId,
            zoneId: shift.zoneId,
            shiftDate: this.iso(shift.shiftDate),
            startTime: this.iso(shift.startTime),
            endTime: this.iso(shift.endTime),
            status: shift.status,
          },
          facts: {
            Driver: shift.driver?.name ?? shift.driverId.slice(0, 8),
            Zone: this.bi(shift.zone?.name, shift.zone?.nameAr),
            Date: this.fmtDate(shift.shiftDate),
            Window: `${this.fmtTime(shift.startTime)} - ${this.fmtTime(shift.endTime)}`,
            Status: String(shift.status),
          },
        };
      }
      case 'Drivers': {
        const driver = await this.prisma.driver.findUnique({
          where: { id: targetId },
          include: { user: { select: { name: true, phone: true } } },
        });
        if (!driver) return null;
        const vehicle = `${driver.vehicleType}${driver.vehiclePlate ? ` (${driver.vehiclePlate})` : ''}`;
        return {
          oldValues: {
            name: driver.name,
            status: driver.status,
            vehicleType: driver.vehicleType,
            vehiclePlate: driver.vehiclePlate,
            isApproved: driver.isApproved,
          },
          facts: {
            Name: driver.name,
            Phone: driver.user?.phone ?? '—',
            Status: String(driver.status),
            Vehicle: vehicle,
            Approved: driver.isApproved ? 'Yes' : 'No',
          },
        };
      }
      case 'Vendors': {
        const branch = await this.prisma.vendorBranch.findUnique({
          where: { id: targetId },
          include: {
            vendor: { select: { storeName: true, storeNameAr: true } },
            zone: { select: { name: true, nameAr: true } },
          },
        });
        if (branch) {
          return {
            oldValues: {
              name: this.bi(branch.name, branch.nameAr),
              address: branch.address,
              phone: branch.phone,
              isOpen: branch.isOpen,
              zoneId: branch.zoneId,
            },
            facts: {
              Branch: this.bi(branch.name, branch.nameAr),
              Vendor: this.bi(
                branch.vendor?.storeName,
                branch.vendor?.storeNameAr,
              ),
              Zone: this.bi(branch.zone?.name, branch.zone?.nameAr),
              Address: branch.address ?? '—',
              Open: branch.isOpen ? 'Yes' : 'No',
            },
          };
        }
        const vendor = await this.prisma.vendor.findUnique({
          where: { id: targetId },
        });
        if (vendor) {
          return {
            oldValues: {
              storeName: this.bi(vendor.storeName, vendor.storeNameAr),
              status: vendor.status,
              phone: vendor.phone,
            },
            facts: {
              Store: this.bi(vendor.storeName, vendor.storeNameAr),
              Status: String(vendor.status),
              Phone: vendor.phone ?? '—',
            },
          };
        }
        const product = await this.prisma.product.findUnique({
          where: { id: targetId },
          include: {
            vendor: { select: { storeName: true, storeNameAr: true } },
            category: { select: { name: true, nameAr: true } },
          },
        });
        if (product) {
          return {
            oldValues: {
              name: this.bi(product.name, product.nameAr),
              basePrice: product.basePrice,
              isActive: product.isActive,
            },
            facts: {
              Product: this.bi(product.name, product.nameAr),
              Vendor: this.bi(
                product.vendor?.storeName,
                product.vendor?.storeNameAr,
              ),
              Category: this.bi(
                product.category?.name,
                product.category?.nameAr,
              ),
              Price:
                product.basePrice != null ? String(product.basePrice) : '—',
            },
          };
        }
        const category = await this.prisma.menuCategory.findUnique({
          where: { id: targetId },
        });
        if (category) {
          return {
            oldValues: {
              name: this.bi(category.name, category.nameAr),
              isActive: category.isActive,
            },
            facts: { Category: this.bi(category.name, category.nameAr) },
          };
        }
        return null;
      }
      case 'Orders': {
        if (path.includes('/vendor-decisions/')) {
          const fulfillment =
            await this.prisma.orderVendorFulfillment.findUnique({
              where: { id: targetId },
              select: {
                id: true,
                vendorId: true,
                status: true,
                subtotal: true,
                vendor: { select: { storeName: true, storeNameAr: true } },
                order: {
                  select: {
                    orderNumber: true,
                    status: true,
                    grandTotal: true,
                    paymentMethod: true,
                  },
                },
              },
            });
          if (!fulfillment) return null;
          return {
            vendorId: fulfillment.vendorId,
            oldValues: {
              status: fulfillment.status,
              orderStatus: fulfillment.order?.status,
            },
            facts: {
              Order: fulfillment.order?.orderNumber ?? targetId,
              Status: String(fulfillment.status),
              'Order status': String(fulfillment.order?.status ?? '—'),
              Subtotal: `${fulfillment.subtotal} EGP`,
              Total: `${fulfillment.order?.grandTotal ?? 0} EGP`,
              Payment: fulfillment.order?.paymentMethod
                ? String(fulfillment.order.paymentMethod).replace(/_/g, ' ')
                : '—',
              Vendor: this.bi(
                fulfillment.vendor?.storeName ?? null,
                fulfillment.vendor?.storeNameAr ??
                  fulfillment.vendor?.storeName ??
                  null,
              ),
            },
          };
        }

        const order = await this.prisma.order.findUnique({
          where: { id: targetId },
          include: {
            vendorFulfillments: {
              select: {
                vendorId: true,
                vendor: { select: { storeName: true, storeNameAr: true } },
              },
            },
            deliveryGroups: { select: { id: true } },
          },
        });
        if (!order) return null;
        const details = this.buildOrderAuditDetails(order);
        return {
          vendorId: details.vendorId,
          oldValues: { status: order.status },
          facts: details.facts,
        };
      }
      case 'Users': {
        const user = await this.prisma.user.findUnique({
          where: { id: targetId },
          select: { name: true, email: true, phone: true, role: true },
        });
        if (!user) return null;
        return {
          oldValues: {
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role,
          },
          facts: {
            Name: user.name,
            Email: user.email ?? '—',
            Phone: user.phone ?? '—',
            Role: String(user.role),
          },
        };
      }
      case 'Promotions': {
        const promo = await this.prisma.promotion.findUnique({
          where: { id: targetId },
        });
        if (!promo) return null;
        return {
          oldValues: {
            title: this.bi(promo.title, promo.titleAr),
            isActive: promo.isActive,
          },
          facts: { Promotion: this.bi(promo.title, promo.titleAr) },
        };
      }
      case 'Zones': {
        const zone = await this.prisma.zone.findUnique({
          where: { id: targetId },
        });
        if (!zone) return null;
        return {
          oldValues: {
            name: this.bi(zone.name, zone.nameAr),
            isActive: zone.isActive,
          },
          facts: { Zone: this.bi(zone.name, zone.nameAr) },
        };
      }
      case 'Tickets': {
        const ticket = await this.prisma.supportTicket.findUnique({
          where: { id: targetId },
        });
        if (!ticket) return null;
        return {
          oldValues: { status: ticket.status, category: ticket.category },
          facts: {
            Ticket: ticket.ticketNumber,
            Subject: ticket.subject,
            Status: String(ticket.status),
            Category: String(ticket.category),
          },
        };
      }
      case 'VendorBranches': {
        const branch = await this.prisma.vendorBranch.findUnique({
          where: { id: targetId },
          include: {
            vendor: { select: { storeName: true, storeNameAr: true } },
            zone: { select: { name: true, nameAr: true } },
          },
        });
        if (!branch) return null;
        return {
          oldValues: {
            name: this.bi(branch.name, branch.nameAr),
            address: branch.address,
            phone: branch.phone,
            isOpen: branch.isOpen,
            zoneId: branch.zoneId,
          },
          facts: {
            Branch: this.bi(branch.name, branch.nameAr),
            Vendor: this.bi(
              branch.vendor?.storeName,
              branch.vendor?.storeNameAr,
            ),
            Zone: this.bi(branch.zone?.name, branch.zone?.nameAr),
            Address: branch.address ?? '—',
            Open: branch.isOpen ? 'Yes' : 'No',
          },
        };
      }
      case 'Products': {
        // Nested variant/option routes address the deepest resource; if it
        // is a variant, show the variant in the context of its product.
        const variant = await this.prisma.productVariant
          .findUnique({
            where: { id: targetId },
            include: {
              product: {
                select: {
                  name: true,
                  nameAr: true,
                  vendor: { select: { storeName: true, storeNameAr: true } },
                },
              },
            },
          })
          .catch(() => null);
        if (variant) {
          return {
            oldValues: { name: this.bi(variant.name, variant.nameAr) },
            facts: {
              Variant: this.bi(variant.name, variant.nameAr),
              Product: this.bi(variant.product?.name, variant.product?.nameAr),
              Vendor: this.bi(
                variant.product?.vendor?.storeName,
                variant.product?.vendor?.storeNameAr,
              ),
            },
          };
        }
        const product = await this.prisma.product.findUnique({
          where: { id: targetId },
          include: {
            vendor: { select: { storeName: true, storeNameAr: true } },
            category: { select: { name: true, nameAr: true } },
          },
        });
        if (!product) return null;
        return {
          oldValues: {
            name: this.bi(product.name, product.nameAr),
            basePrice: product.basePrice,
            isActive: product.isActive,
          },
          facts: {
            Product: this.bi(product.name, product.nameAr),
            Vendor: this.bi(
              product.vendor?.storeName,
              product.vendor?.storeNameAr,
            ),
            Category: this.bi(product.category?.name, product.category?.nameAr),
            Price: product.basePrice != null ? String(product.basePrice) : '—',
          },
        };
      }
      case 'MenuCategories': {
        const category = await this.prisma.menuCategory.findUnique({
          where: { id: targetId },
          include: {
            vendor: { select: { storeName: true, storeNameAr: true } },
          },
        });
        if (!category) return null;
        return {
          oldValues: {
            name: this.bi(category.name, category.nameAr),
            isActive: category.isActive,
          },
          facts: {
            Category: this.bi(category.name, category.nameAr),
            Vendor: this.bi(
              category.vendor?.storeName,
              category.vendor?.storeNameAr,
            ),
          },
        };
      }
      case 'VendorMembers': {
        const member = await this.prisma.vendorMember.findUnique({
          where: { id: targetId },
          include: {
            user: { select: { name: true } },
            vendor: { select: { storeName: true, storeNameAr: true } },
            branch: { select: { name: true, nameAr: true } },
          },
        });
        if (!member) return null;
        return {
          oldValues: { role: member.role },
          facts: {
            Member: member.user?.name ?? member.userId.slice(0, 8),
            Vendor: this.bi(
              member.vendor?.storeName,
              member.vendor?.storeNameAr,
            ),
            Branch: this.bi(member.branch?.name, member.branch?.nameAr),
            Role: String(member.role),
          },
        };
      }
      case 'VendorWallet': {
        const vendor = await this.prisma.vendor.findUnique({
          where: { id: targetId },
        });
        if (!vendor) return null;
        return {
          oldValues: { walletBalance: vendor.walletBalance },
          facts: {
            Store: this.bi(vendor.storeName, vendor.storeNameAr),
            'Wallet balance': String(vendor.walletBalance),
          },
        };
      }
      case 'VendorVerticals': {
        const vertical = await this.prisma.vendorVertical.findUnique({
          where: { id: targetId },
        });
        if (!vertical) return null;
        return {
          oldValues: {
            name: this.bi(vertical.name, vertical.nameAr),
            isActive: vertical.isActive,
          },
          facts: { Vertical: this.bi(vertical.name, vertical.nameAr) },
        };
      }
      case 'Conversations': {
        const convo = await this.prisma.conversation.findUnique({
          where: { id: targetId },
          include: {
            order: { select: { orderNumber: true } },
            vendor: { select: { storeName: true, storeNameAr: true } },
          },
        });
        if (!convo) return null;
        return {
          oldValues: { status: convo.status },
          facts: {
            Type: String(convo.type),
            Order: convo.order?.orderNumber ?? '—',
            Vendor: this.bi(convo.vendor?.storeName, convo.vendor?.storeNameAr),
            Status: String(convo.status),
          },
        };
      }
      case 'Messages': {
        const message = await this.prisma.message.findUnique({
          where: { id: targetId },
        });
        if (!message) return null;
        const text = (message.text ?? '').trim();
        return {
          oldValues: { text: message.text },
          facts: {
            Message:
              text.length > 80
                ? `${text.slice(0, 80)}…`
                : text.length === 0
                  ? '—'
                  : text,
            Type: String(message.type),
          },
        };
      }
      case 'Customers': {
        const customer = await this.prisma.customer.findUnique({
          where: { id: targetId },
          include: { user: { select: { name: true, phone: true } } },
        });
        if (!customer) return null;
        return {
          oldValues: { canOrder: customer.canOrder },
          facts: {
            Name: customer.user?.name ?? customer.userId.slice(0, 8),
            Phone: customer.user?.phone ?? '—',
            'Can order': customer.canOrder ? 'Yes' : 'No',
          },
        };
      }
      case 'Notifications': {
        const notification = await this.prisma.notification.findUnique({
          where: { id: targetId },
        });
        if (!notification) return null;
        return {
          oldValues: { isRead: notification.isRead },
          facts: {
            Title: this.bi(notification.title, notification.titleAr),
            Type: String(notification.type),
          },
        };
      }
      case 'Wallet': {
        if (path.includes('/topups/')) {
          const topup = await this.prisma.walletTopUpRequest.findUnique({
            where: { id: targetId },
            include: { driver: { select: { name: true } } },
          });
          if (!topup) return null;
          return {
            oldValues: { status: topup.status },
            facts: {
              Driver: topup.driver?.name ?? topup.driverId.slice(0, 8),
              Amount: String(topup.amount),
              Status: String(topup.status),
            },
          };
        }
        if (path.includes('/platform')) {
          const wallet = await this.prisma.mobileWallet.findUnique({
            where: { id: targetId },
          });
          if (!wallet) return null;
          return {
            oldValues: {
              number: wallet.number,
              isActive: wallet.isActive,
            },
            facts: {
              Wallet: wallet.number,
              Type: String(wallet.type),
            },
          };
        }
        // Manual vendor/driver wallet transaction: snapshot the owner.
        const driver = await this.prisma.driver
          .findUnique({
            where: { id: targetId },
            include: { user: { select: { name: true, phone: true } } },
          })
          .catch(() => null);
        if (driver) {
          return {
            oldValues: { walletBalance: driver.walletBalance },
            facts: {
              Name: driver.name,
              Phone: driver.user?.phone ?? '—',
              'Wallet balance': String(driver.walletBalance),
            },
          };
        }
        const vendor = await this.prisma.vendor.findUnique({
          where: { id: targetId },
        });
        if (!vendor) return null;
        return {
          oldValues: { walletBalance: vendor.walletBalance },
          facts: {
            Store: this.bi(vendor.storeName, vendor.storeNameAr),
            'Wallet balance': String(vendor.walletBalance),
          },
        };
      }
      default:
        return null;
    }
  }
}
