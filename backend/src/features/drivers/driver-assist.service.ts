import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';

import { NotificationsService } from '../notifications/notifications.service';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from '../../infrastructure/location/location.repository';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { DriverErrors } from '../../common/constants/response.constants';
import { CustomerErrors } from '../../common/constants/response.constants';
import { OrderErrors } from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  DriverAssistAssignedEvent,
  DriverAssistDecidedEvent,
  DriverAssistRequestedEvent,
} from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { forwardRef, Inject } from '@nestjs/common';
import { OrdersStateService } from '../orders/orders-state.service';
import {
  DeliveryGroupStatus,
  DriverAssistReason,
  DriverAssistRequestStatus,
  DriverShiftStatus,
  DriverStatus,
  Prisma,
} from '@prisma/client';

export interface RequestAssistDto {
  reason: DriverAssistReason;
  note?: string;
}

export interface DecideAssistDto {
  status: Extract<DriverAssistRequestStatus, 'APPROVED' | 'REJECTED'>;
}

export interface AssignAssistDriverDto {
  driverId: string;
}

/**
 * Statuses past which adding a second driver is unsafe: the load is already
 * being lifted, so reassigning now would strand goods mid-route.
 */
const ASSIGNMENT_CLOSED_STATUSES: DeliveryGroupStatus[] = [
  DeliveryGroupStatus.PICKED_UP,
  DeliveryGroupStatus.DELIVERED,
  DeliveryGroupStatus.CANCELLED,
];

/**
 * Persisted extra-driver assistance, modelled on the existing DriverBreak
 * request/approve/reject precedent (conditional `updateMany` CAS + reviewedBy).
 *
 * Authorisation is layered:
 *  - the driver may only request for a group they are the PRIMARY driver of;
 *  - an admin/support user decides the request;
 *  - assigning the assisting driver requires MANAGE_ORDERS **or**
 *    MANAGE_DRIVERS (enforced at the controller with `mode: 'any'`).
 */
@Injectable()
export class DriverAssistService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly notifications: NotificationsService,
    private readonly socket: SocketService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly locationRepository: LocationRepository,
    private readonly redis: RedisService,
    @Inject(forwardRef(() => OrdersStateService))
    private readonly ordersState: OrdersStateService,
  ) {}

  // ─── Driver workflow ───────────────────────────────────────────────────────

  async requestAssist(
    actor: JwtAccessPayload,
    orderId: string,
    deliveryGroupId: string,
    dto: RequestAssistDto,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true, userId: true, name: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const group = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: deliveryGroupId },
      select: {
        id: true,
        orderId: true,
        status: true,
        primaryDriverId: true,
        assistDriverId: true,
        order: { select: { id: true, orderNumber: true, status: true } },
      },
    });
    if (!group || group.orderId !== orderId) {
      throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }

    // A driver may only request assistance for a delivery they actually drive.
    if (group.primaryDriverId !== driver.id) {
      throw new ForbiddenException(DriverErrors.ASSIST_NOT_ON_THIS_DELIVERY);
    }

    // Already resolved with a second pair of hands.
    if (group.assistDriverId) {
      throw new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);
    }

    // Too late / no longer relevant.
    if (ASSIGNMENT_CLOSED_STATUSES.includes(group.status)) {
      throw new BadRequestException(
        DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED,
      );
    }
    if (
      group.order.status === 'CANCELLED' ||
      group.order.status === 'DELIVERED'
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }

    const note = dto.note?.trim() || null;

    try {
      // Partial unique index driver_assist_requests_open_uidx makes a second
      // open request for the same driver+group impossible at the DB level.
      const created = await this.prisma.driverAssistRequest.create({
        data: {
          driverId: driver.id,
          orderId,
          deliveryGroupId,
          reason: dto.reason ?? DriverAssistReason.OTHER,
          note,
          status: DriverAssistRequestStatus.PENDING,
        },
      });

      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_REQUESTED,
        new DriverAssistRequestedEvent(
          created.id,
          driver.userId,
          orderId,
          group.order.orderNumber,
          deliveryGroupId,
          created.reason,
          note,
        ),
      );

      return this.findById(created.id);
    } catch (error: any) {
      if (error?.code === 'P2002') {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_ALREADY_OPEN);
      }
      throw error;
    }
  }

  async myRequests(actor: JwtAccessPayload) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    return this.prisma.driverAssistRequest.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
      include: this.includeShape(),
    });
  }

  async listForOrder(orderId: string) {
    return this.prisma.driverAssistRequest.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
      include: this.includeShape(),
    });
  }

  async listPending() {
    return this.prisma.driverAssistRequest.findMany({
      where: { status: DriverAssistRequestStatus.PENDING },
      orderBy: { createdAt: 'asc' },
      take: 100,
      include: this.includeShape(),
    });
  }

  // ─── Support / admin workflow ──────────────────────────────────────────────

  async decide(
    requestId: string,
    actor: JwtAccessPayload,
    dto: DecideAssistDto,
  ) {
    const request = await this.findById(requestId);

    if (request.status !== DriverAssistRequestStatus.PENDING) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const next =
      dto.status === 'APPROVED'
        ? DriverAssistRequestStatus.APPROVED
        : DriverAssistRequestStatus.REJECTED;

    // CAS: only a still-PENDING row can move, so two reviewers racing produce
    // exactly one winner.
    const claimed = await this.prisma.driverAssistRequest.updateMany({
      where: { id: requestId, status: DriverAssistRequestStatus.PENDING },
      data: {
        status: next,
        reviewedByUserId: actor.sub,
        reviewedAt: new Date(),
        resolvedAt: new Date(),
      },
    });
    if (claimed.count === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_ASSIST_DECIDED,
      new DriverAssistDecidedEvent(
        requestId,
        request.driver.userId,
        request.orderId,
        next === DriverAssistRequestStatus.APPROVED ? 'approved' : 'rejected',
        actor.sub,
        null,
      ),
    );

    return this.findById(requestId);
  }

  /**
   * Attach an assisting driver WITHOUT touching the primary driver.
   *
   * Requires MANAGE_ORDERS or MANAGE_DRIVERS (see controller). All of the
   * following are enforced server-side: request is approved, the group is still
   * assignable, the driver is eligible/available, and the driver is not already
   * on this delivery in either role.
   */
  async assignDriver(
    requestId: string,
    actor: JwtAccessPayload,
    dto: AssignAssistDriverDto,
  ) {
    const request = await this.findById(requestId);

    // Single-vendor (order-level) requests have no delivery group.
    if (!request.deliveryGroupId) {
      return this.assignAssistDriverOrder(requestId, actor, dto);
    }

    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    if (!request.deliveryGroupId) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }

    const groupId = request.deliveryGroupId;

    const candidate = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: {
        id: true,
        userId: true,
        status: true,
        isApproved: true,
        vehicleType: true,
        hasUnpaidCommission: true,
        deletedAt: true,
        tier: true,
      },
    });
    if (!candidate || candidate.deletedAt) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }

    // Eligibility mirrors the existing manual force-assign rules.
    if (candidate.status === DriverStatus.SUSPENDED) {
      throw new BadRequestException(DriverErrors.ACCOUNT_SUSPENDED);
    }
    if (!candidate.isApproved) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }
    if (
      candidate.status !== DriverStatus.ONLINE &&
      candidate.status !== DriverStatus.BUSY
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    if (candidate.hasUnpaidCommission) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }

    const assigned = await this.prisma.$transaction(async (tx) => {
      const group = await tx.orderDeliveryGroup.findUnique({
        where: { id: groupId },
        select: {
          id: true,
          primaryDriverId: true,
          assistDriverId: true,
          status: true,
          deliveryFee: true,
          distanceKm: true,
          orderId: true,
        },
      });
      if (!group)
        throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);

      if (ASSIGNMENT_CLOSED_STATUSES.includes(group.status)) {
        throw new BadRequestException(
          DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED,
        );
      }
      if (group.assistDriverId) {
        throw new ConflictException(
          DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED,
        );
      }
      // Never let one driver occupy both roles on the same delivery.
      if (group.primaryDriverId === candidate.id) {
        throw new BadRequestException(
          DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED,
        );
      }

      const busy = await tx.order.findFirst({
        where: {
          driverId: candidate.id,
          status: {
            in: [
              'DRIVER_ASSIGNED',
              'PREPARING',
              'READY_FOR_PICKUP',
              'PICKED_UP',
            ],
          },
        },
        select: { id: true },
      });
      if (busy) {
        throw new ConflictException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
      }

      // Multi-vendor deliveries never set Order.driverId for non-first groups,
      // so a driver could be the primary/assist of another live delivery group
      // without the order-level check above seeing it. Check group membership
      // too, excluding closed groups.
      const busyGroup = await tx.orderDeliveryGroup.findFirst({
        where: {
          id: { not: groupId },
          OR: [
            { primaryDriverId: candidate.id },
            { assistDriverId: candidate.id },
          ],
          status: {
            notIn: [
              DeliveryGroupStatus.DELIVERED,
              DeliveryGroupStatus.CANCELLED,
            ],
          },
        },
        select: { id: true },
      });
      if (busyGroup) {
        throw new ConflictException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
      }

      // Capture the assisting driver's active shift so settlement can attribute
      // their delivery fee to the correct shift (mirrors the primary driver).
      const activeShift = await tx.driverShift.findFirst({
        where: { driverId: candidate.id, status: DriverShiftStatus.ACTIVE },
        select: { id: true },
        orderBy: { startTime: 'desc' },
      });

      // CAS on assistDriverId so two concurrent admins cannot both win.
      const claimed = await tx.orderDeliveryGroup.updateMany({
        where: { id: groupId, assistDriverId: null },
        data: {
          assistDriverId: candidate.id,
          assistDriverShiftId: activeShift?.id ?? null,
          assignedByUserId: actor.sub,
          assignedAt: new Date(),
        },
      });
      if (claimed.count === 0) {
        throw new ConflictException(
          DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED,
        );
      }

      await tx.driverAssistRequest.update({
        where: { id: requestId },
        data: {
          status: DriverAssistRequestStatus.FULFILLED,
          assignedDriverId: candidate.id,
          resolvedAt: new Date(),
        },
      });

      return { primaryDriverId: group.primaryDriverId };
    });

    const primaryUserId = await this.resolveUserId(assigned.primaryDriverId);

    const group = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: groupId },
      select: { deliveryFee: true, distanceKm: true },
    });

    // Compute the assisting driver's fee (mirrors statistics.service settlement)
    // so the customer can be charged for it and decide before it is finalised.
    const settings = await this.platformSettings.getSettings();
    const primaryTierRow = await this.prisma.driver.findUnique({
      where: { id: assigned.primaryDriverId! },
      select: { tier: true },
    });
    const primaryTier = primaryTierRow?.tier ?? 'GOLD';
    const assistTier = candidate.tier ?? 'GOLD';
    const goldBonus = Number(settings.goldTierBonusPerKm ?? 0);
    const silverBonus = Number(settings.silverTierBonusPerKm ?? 0);
    const bronzeBonus = Number(settings.bronzeTierBonusPerKm ?? 0);
    const tierBonusPerKm = (tier: string): number =>
      tier === 'BRONZE'
        ? bronzeBonus
        : tier === 'SILVER'
          ? silverBonus
          : goldBonus;
    const tierDiffPerKm = tierBonusPerKm(primaryTier) - tierBonusPerKm(assistTier);
    const routeKm = Number(group?.distanceKm ?? 0);
    const primaryFee = Number(group?.deliveryFee ?? 0);
    const driverShare = 1 - Number(settings.deliveryCommissionRate ?? 20) / 100;
    const base = settings.driverShiftsEnabled
      ? Math.max(0, primaryFee - Math.max(0, tierDiffPerKm) * routeKm)
      : primaryFee;
    const assistFee = Math.max(0, Math.round(base * driverShare));

    await this.prisma.orderDeliveryGroup.update({
      where: { id: groupId },
      data: { assistFee },
    });

    // Notify the customer so they can decide whether to accept the assisted
    // delivery (and its fee). The customer's decision is recorded via
    // POST /orders/:orderId/delivery-groups/:groupId/assist/decision.
    const order = await this.prisma.order.findUnique({
      where: { id: request.orderId },
      select: { customerId: true, orderNumber: true },
    });
    const customer = order
      ? await this.prisma.customer.findUnique({
          where: { id: order.customerId },
          select: { userId: true },
        })
      : null;
    if (customer?.userId) {
      const title = 'Assisted delivery proposed';
      const titleAr = 'تم اقتراح توصيل بمساعدة';
      const body = `An assisting driver was added to delivery ${order?.orderNumber ?? request.orderId}. Extra fee: ${assistFee}. Approve or decline.`;
      const bodyAr = `تمت إضافة سائق مساعد للتوصيل ${order?.orderNumber ?? request.orderId}. رسوم إضافية: ${assistFee}. وافق أو ارفض.`;
      try {
        await this.notifications.create({
          userId: customer.userId,
          title,
          titleAr,
          body,
          bodyAr,
          type: 'ORDER_UPDATE',
          data: {
            orderId: request.orderId,
            deliveryGroupId: groupId,
            assistFee,
            action: 'assist_decision',
          },
        });
      } catch (error) {
        this.logWarn(error);
      }
      try {
        await this.socket.emitToUser(customer.userId, 'order.assist.proposed', {
          orderId: request.orderId,
          deliveryGroupId: groupId,
          assistFee,
        });
      } catch (error) {
        this.logWarn(error);
      }
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_ASSIST_ASSIGNED,
      new DriverAssistAssignedEvent(
        requestId,
        request.orderId,
        groupId,
        primaryUserId ?? '',
        candidate.userId,
        actor.sub,
      ),
    );

    // The primary driver keeps the delivery; the assisting driver is added.
    await this.notifyAssistAssignment({
      assistUserId: candidate.userId,
      primaryUserId,
      orderNumber: request.order?.orderNumber ?? request.orderId,
    });

    return this.findById(requestId);
  }

  async cancelByDriver(requestId: string, actor: JwtAccessPayload) {
    const request = await this.findById(requestId);
    if (request.driver.userId !== actor.sub) {
      throw new ForbiddenException(DriverErrors.ASSIST_NOT_ON_THIS_DELIVERY);
    }
    if (request.status !== DriverAssistRequestStatus.PENDING) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const claimed = await this.prisma.driverAssistRequest.updateMany({
      where: { id: requestId, status: DriverAssistRequestStatus.PENDING },
      data: {
        status: DriverAssistRequestStatus.CANCELLED,
        resolvedAt: new Date(),
      },
    });
    if (claimed.count === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    this.eventEmitter.emit(
      EVENTS.DRIVER_ASSIST_DECIDED,
      new DriverAssistDecidedEvent(
        requestId,
        request.driver.userId,
        request.orderId,
        'cancelled',
        actor.sub,
        null,
      ),
    );

    return this.findById(requestId);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  // ─── Customer decision ──────────────────────────────────────────────────────
  /**
   * The customer decides whether to accept an assisted delivery (and its fee).
   * Approve → the customer is charged the assistant's fee (added to the order)
   *            and the assistant is paid from it.
   * Decline  → the assistant is removed and the assist request is cancelled;
   *            no charge, no assistant payout.
   */
  async customerDecideAssist(
    actor: JwtAccessPayload,
    orderId: string,
    deliveryGroupId: string,
    approved: boolean,
  ) {
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true, userId: true },
    });
    if (!customer) throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, customerId: true, orderNumber: true, status: true },
    });
    if (!order || order.customerId !== customer.id) {
      throw new NotFoundException(OrderErrors.NOT_FOUND);
    }

    const group = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: deliveryGroupId },
      select: {
        id: true,
        orderId: true,
        assistDriverId: true,
        assistFee: true,
        assistCustomerApproved: true,
        primaryDriverId: true,
      },
    });
    if (!group || group.orderId !== orderId) {
      throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }
    if (!group.assistDriverId) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }
    if (group.assistCustomerApproved !== null) {
      throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const assistFee = Number(group.assistFee ?? 0);

    if (approved) {
      await this.prisma.orderDeliveryGroup.update({
        where: { id: deliveryGroupId },
        data: {
          assistCustomerApproved: true,
          assistApprovedAt: new Date(),
        },
      });

      // Charge the customer: add the assistant's fee to the order total so the
      // driver collects it (cash) / it becomes part of what is owed.
      if (assistFee > 0) {
        await this.prisma.order.update({
          where: { id: orderId },
          data: {
            deliveryFee: { increment: assistFee },
            grandTotal: { increment: assistFee },
          },
        });
      }

      // Notify drivers that the customer approved.
      const primaryUserId = await this.resolveUserId(group.primaryDriverId);
      const assistUserId = await this.resolveUserId(group.assistDriverId);
      for (const uid of [primaryUserId, assistUserId]) {
        if (!uid) continue;
        try {
          await this.notifications.create({
            userId: uid,
            title: 'Assisted delivery approved',
            titleAr: 'تمت الموافقة على التوصيل بمساعدة',
            body: 'The customer approved the assisted delivery.',
            bodyAr: 'وافق العميل على التوصيل بمساعدة.',
            type: 'ORDER_UPDATE',
            data: { orderId, deliveryGroupId, assistFee },
          });
        } catch (error) {
          this.logWarn(error);
        }
      }
    } else {
      // Declined: remove the assistant, cancel the assist request, no charge.
      // The delivery group (and the order, if it was the last active one) is
      // cancelled because the driver cannot complete an oversized delivery alone.
      await this.prisma.orderDeliveryGroup.update({
        where: { id: deliveryGroupId },
        data: {
          assistDriverId: null,
          assistDriverShiftId: null,
          assignedByUserId: null,
          assignedAt: null,
          assistFee: null,
          assistCustomerApproved: false,
          assistApprovedAt: new Date(),
          status: DeliveryGroupStatus.CANCELLED,
        },
      });

      await this.prisma.driverAssistRequest.updateMany({
        where: { deliveryGroupId, status: DriverAssistRequestStatus.FULFILLED },
        data: { status: DriverAssistRequestStatus.CANCELLED, resolvedAt: new Date() },
      });

      const remaining = await this.prisma.orderDeliveryGroup.count({
        where: { orderId, status: { not: DeliveryGroupStatus.CANCELLED } },
      });
      if (remaining === 0) {
        try {
          await this.ordersState.cancelOrder(
            null,
            orderId,
            'Customer declined assisted delivery',
          );
        } catch (e) {
          this.logWarn(e);
        }
      }

      const primaryUserId = await this.resolveUserId(group.primaryDriverId);
      const assistUserId = await this.resolveUserId(group.assistDriverId);
      for (const uid of [primaryUserId, assistUserId]) {
        if (!uid) continue;
        try {
          await this.notifications.create({
            userId: uid,
            title: 'Assisted delivery declined',
            titleAr: 'رفض العميل التوصيل بمساعدة',
            body: 'The customer declined the assisted delivery.',
            bodyAr: 'رفض العميل التوصيل بمساعدة.',
            type: 'ORDER_UPDATE',
            data: { orderId, deliveryGroupId },
          });
        } catch (error) {
          this.logWarn(error);
        }
      }
    }

    return { approved, assistFee };
  }

  /**
   * Auto-decline assist requests whose customer decision window has expired.
   * Runs from the worker cron (every minute). Uses the configurable
   * `assistDecisionTimeoutSecs` platform setting.
   */
  async autoDeclineExpiredAssistDecisions() {
    const settings = await this.platformSettings.getSettings();
    const timeoutSecs = Number(settings.assistDecisionTimeoutSecs ?? 120);
    const cutoff = new Date(Date.now() - timeoutSecs * 1000);

    const expired = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        assistDriverId: { not: null },
        assistCustomerApproved: null,
        assignedAt: { not: null, lt: cutoff },
      },
      select: {
        id: true,
        orderId: true,
        primaryDriverId: true,
        assistDriverId: true,
        assistFee: true,
      },
    });

    // Also auto-decline order-level (single-vendor) assists.
    await this.autoDeclineExpiredOrderAssists();

    for (const g of expired) {
      try {
        await this.prisma.orderDeliveryGroup.update({
          where: { id: g.id },
          data: {
            assistDriverId: null,
            assistDriverShiftId: null,
            assignedByUserId: null,
            assignedAt: null,
            assistFee: null,
            assistCustomerApproved: false,
            assistApprovedAt: new Date(),
          },
        });

        await this.prisma.driverAssistRequest.updateMany({
          where: { deliveryGroupId: g.id, status: DriverAssistRequestStatus.FULFILLED },
          data: { status: DriverAssistRequestStatus.CANCELLED, resolvedAt: new Date() },
        });

        await this.prisma.orderDeliveryGroup.update({
          where: { id: g.id },
          data: { status: DeliveryGroupStatus.CANCELLED },
        });
        const remaining = await this.prisma.orderDeliveryGroup.count({
          where: { orderId: g.orderId, status: { not: DeliveryGroupStatus.CANCELLED } },
        });
        if (remaining === 0) {
          try {
            await this.ordersState.cancelOrder(null, g.orderId, 'Assist decision timed out');
          } catch (e) {
            this.logWarn(e);
          }
        }

        const order = await this.prisma.order.findUnique({
          where: { id: g.orderId },
          select: { orderNumber: true, customerId: true },
        });
        const customer = order
          ? await this.prisma.customer.findUnique({
              where: { id: order.customerId },
              select: { userId: true },
            })
          : null;

        const primaryUserId = await this.resolveUserId(g.primaryDriverId);
        const assistUserId = await this.resolveUserId(g.assistDriverId);

        const notify = async (userId: string | null, title: string, titleAr: string, body: string, bodyAr: string) => {
          if (!userId) return;
          try {
            await this.notifications.create({
              userId,
              title,
              titleAr,
              body,
              bodyAr,
              type: 'ORDER_UPDATE',
              data: { orderId: g.orderId, deliveryGroupId: g.id },
            });
          } catch (e) {
            this.logWarn(e);
          }
        };

        await notify(
          customer?.userId ?? null,
          'Assisted delivery timed out',
          'انتهت مهلة التوصيل بمساعدة',
          'No response was received; the assisting driver was removed.',
          'لم يتم تلقي رد؛ تمت إزالة السائق المساعد.',
        );
        await notify(primaryUserId, 'Assisted delivery timed out', 'انتهت مهلة التوصيل بمساعدة', 'The assisting driver was removed (no customer response).', 'تمت إزالة السائق المساعد (لا رد من العميل).');
        await notify(assistUserId, 'Assisted delivery timed out', 'انتهت مهلة التوصيل بمساعدة', 'You were unassigned (no customer response).', 'تم إلغاء تعيينك (لا رد من العميل).');
      } catch (error) {
        this.logWarn(error);
      }
    }
  }

  // ─── Single-vendor (order-level) assistance ────────────────────────────────
  // Mirrors the group-level flow but operates on the Order itself, so a
  // single-store delivery that is too large for one driver can also get help.

  async requestAssistOrder(actor: JwtAccessPayload, orderId: string, dto: RequestAssistDto) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true, userId: true, name: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, driverId: true, assistDriverId: true, status: true, orderNumber: true },
    });
    if (!order) throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);

    if (order.driverId !== driver.id) {
      throw new ForbiddenException(DriverErrors.ASSIST_NOT_ON_THIS_DELIVERY);
    }
    if (order.status === 'CANCELLED' || order.status === 'DELIVERED') {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }
    if (order.status === 'PICKED_UP') {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED);
    }
    if (order.assistDriverId) {
      throw new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);
    }

    const note = dto.note?.trim() || null;
    try {
      const created = await this.prisma.driverAssistRequest.create({
        data: {
          driverId: driver.id,
          orderId,
          reason: dto.reason ?? DriverAssistReason.OTHER,
          note,
          status: DriverAssistRequestStatus.PENDING,
        },
      });
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_REQUESTED,
        new DriverAssistRequestedEvent(
          created.id,
          driver.userId,
          orderId,
          order.orderNumber,
          null,
          created.reason,
          note,
        ),
      );
      return this.findById(created.id);
    } catch (error: any) {
      if (error?.code === 'P2002') {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_ALREADY_OPEN);
      }
      throw error;
    }
  }

  async assignAssistDriverOrder(requestId: string, actor: JwtAccessPayload, dto: AssignAssistDriverDto) {
    const request = await this.findById(requestId);
    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    if (request.deliveryGroupId) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }

    const candidate = await this.prisma.driver.findUnique({
      where: { id: dto.driverId },
      select: {
        id: true, userId: true, status: true, isApproved: true,
        vehicleType: true, hasUnpaidCommission: true, deletedAt: true, tier: true,
      },
    });
    if (!candidate || candidate.deletedAt) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    if (candidate.status === DriverStatus.SUSPENDED) throw new BadRequestException(DriverErrors.ACCOUNT_SUSPENDED);
    if (!candidate.isApproved) throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    if (candidate.status !== DriverStatus.ONLINE && candidate.status !== DriverStatus.BUSY) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    if (candidate.hasUnpaidCommission) throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);

    const orderId = request.orderId;
    const assigned = await this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        select: { id: true, driverId: true, assistDriverId: true, status: true, deliveryFee: true, distanceKm: true },
      });
      if (!order) throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
      if (order.assistDriverId) throw new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);
      if (order.driverId === candidate.id) throw new BadRequestException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);
      if (order.status === 'CANCELLED' || order.status === 'DELIVERED') {
        throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED);
      }

      const busy = await tx.order.findFirst({
        where: { driverId: candidate.id, status: { in: ['DRIVER_ASSIGNED','PREPARING','READY_FOR_PICKUP','PICKED_UP'] } },
        select: { id: true },
      });
      if (busy) throw new ConflictException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);

      const activeShift = await tx.driverShift.findFirst({
        where: { driverId: candidate.id, status: DriverShiftStatus.ACTIVE },
        select: { id: true },
        orderBy: { startTime: 'desc' },
      });

      const claimed = await tx.order.updateMany({
        where: { id: orderId, assistDriverId: null },
        data: {
          assistDriverId: candidate.id,
          assistDriverShiftId: activeShift?.id ?? null,
        },
      });
      if (claimed.count === 0) throw new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);

      await tx.driverAssistRequest.update({
        where: { id: requestId },
        data: { status: DriverAssistRequestStatus.FULFILLED, assignedDriverId: candidate.id, resolvedAt: new Date() },
      });

      const settings = await this.platformSettings.getSettings();
      const primaryTierRow = await tx.driver.findUnique({ where: { id: order.driverId! }, select: { tier: true } });
      const primaryTier = primaryTierRow?.tier ?? 'GOLD';
      const assistTier = candidate.tier ?? 'GOLD';
      const goldBonus = Number(settings.goldTierBonusPerKm ?? 0);
      const silverBonus = Number(settings.silverTierBonusPerKm ?? 0);
      const bronzeBonus = Number(settings.bronzeTierBonusPerKm ?? 0);
      const tierBonusPerKm = (t: string) => t === 'BRONZE' ? bronzeBonus : t === 'SILVER' ? silverBonus : goldBonus;
      const tierDiffPerKm = tierBonusPerKm(primaryTier) - tierBonusPerKm(assistTier);
      const routeKm = Number(order.distanceKm ?? 0);
      const primaryFee = Number(order.deliveryFee ?? 0);
      const driverShare = 1 - Number(settings.deliveryCommissionRate ?? 20) / 100;
      const base = settings.driverShiftsEnabled ? Math.max(0, primaryFee - Math.max(0, tierDiffPerKm) * routeKm) : primaryFee;
      const assistFee = Math.max(0, Math.round(base * driverShare));

      await tx.order.update({ where: { id: orderId }, data: { assistFee } });

      return { primaryDriverId: order.driverId, assistFee };
    });

    const primaryUserId = await this.resolveUserId(assigned.primaryDriverId);
    const assistFee = assigned.assistFee;

    const order = await this.prisma.order.findUnique({ where: { id: orderId }, select: { orderNumber: true } });
    const cust = await this.prisma.order.findUnique({ where: { id: orderId }, select: { customerId: true } });
    const customer = cust ? await this.prisma.customer.findUnique({ where: { id: cust.customerId }, select: { userId: true } }) : null;
    if (customer?.userId) {
      try {
        await this.notifications.create({
          userId: customer.userId,
          title: 'Assisted delivery proposed',
          titleAr: 'تم اقتراح توصيل بمساعدة',
          body: `An assisting driver was added. Extra fee: ${assistFee}. Approve or decline.`,
          bodyAr: `تمت إضافة سائق مساعد. رسوم إضافية: ${assistFee}. وافق أو ارفض.`,
          type: 'ORDER_UPDATE',
          data: { orderId, assistFee, action: 'assist_decision' },
        });
      } catch (e) { this.logWarn(e); }
      try { await this.socket.emitToUser(customer.userId, 'order.assist.proposed', { orderId, assistFee }); } catch (e) { this.logWarn(e); }
    }

    const candidate2 = await this.prisma.driver.findUnique({ where: { id: dto.driverId }, select: { userId: true } });
    await this.notifyAssistAssignment({
      assistUserId: candidate2?.userId ?? '',
      primaryUserId,
      orderNumber: order?.orderNumber ?? orderId,
    });

    this.eventEmitter.emit(EVENTS.DRIVER_ASSIST_ASSIGNED, new DriverAssistAssignedEvent(requestId, orderId, null as any, primaryUserId ?? '', dto.driverId, actor.sub));
    return this.findById(requestId);
  }

  async customerDecideAssistOrder(actor: JwtAccessPayload, orderId: string, approved: boolean) {
    const customer = await this.prisma.customer.findUnique({ where: { userId: actor.sub }, select: { id: true } });
    if (!customer) throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, select: { id: true, driverId: true, customerId: true, assistDriverId: true, assistFee: true, assistCustomerApproved: true } });
    if (!order || order.customerId !== customer.id) throw new NotFoundException(OrderErrors.NOT_FOUND);
    if (!order.assistDriverId) throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    if (order.assistCustomerApproved !== null) throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);

    const assistFee = Number(order.assistFee ?? 0);
    if (approved) {
      await this.prisma.order.update({ where: { id: orderId }, data: { assistCustomerApproved: true, assistApprovedAt: new Date(), deliveryFee: { increment: assistFee }, grandTotal: { increment: assistFee } } });
      const primaryUserId = await this.resolveUserId(order.driverId);
      const assistUserId = await this.resolveUserId(order.assistDriverId);
      for (const uid of [primaryUserId, assistUserId]) {
        if (!uid) continue;
        try { await this.notifications.create({ userId: uid, title: 'Assisted delivery approved', titleAr: 'تمت الموافقة', body: 'Customer approved assisted delivery.', bodyAr: 'وافق العميل.', type: 'ORDER_UPDATE', data: { orderId, assistFee } }); } catch (e) { this.logWarn(e); }
      }
    } else {
      await this.prisma.order.update({ where: { id: orderId }, data: { assistDriverId: null, assistDriverShiftId: null, assistFee: null, assistCustomerApproved: false, assistApprovedAt: new Date() } });
      await this.prisma.driverAssistRequest.updateMany({ where: { orderId, status: DriverAssistRequestStatus.FULFILLED }, data: { status: DriverAssistRequestStatus.CANCELLED, resolvedAt: new Date() } });
      try {
        await this.ordersState.cancelOrder(null, orderId, 'Customer declined assisted delivery');
      } catch (e) {
        this.logWarn(e);
      }
      const primaryUserId = await this.resolveUserId(order.driverId);
      const assistUserId = await this.resolveUserId(order.assistDriverId);
      for (const uid of [primaryUserId, assistUserId]) {
        if (!uid) continue;
        try { await this.notifications.create({ userId: uid, title: 'Assisted delivery declined', titleAr: 'رفض العميل', body: 'Customer declined assisted delivery.', bodyAr: 'رفض العميل.', type: 'ORDER_UPDATE', data: { orderId } }); } catch (e) { this.logWarn(e); }
      }
    }
    return { approved, assistFee };
  }

  async autoDeclineExpiredOrderAssists() {
    const settings = await this.platformSettings.getSettings();
    const timeoutSecs = Number(settings.assistDecisionTimeoutSecs ?? 120);
    const cutoff = new Date(Date.now() - timeoutSecs * 1000);
    const expired = await this.prisma.order.findMany({
      where: { assistDriverId: { not: null }, assistCustomerApproved: null, updatedAt: { lt: cutoff } },
      select: { id: true, driverId: true, assistDriverId: true, assistFee: true },
    });
    for (const o of expired) {
      try {
        await this.prisma.order.update({ where: { id: o.id }, data: { assistDriverId: null, assistDriverShiftId: null, assistFee: null, assistCustomerApproved: false, assistApprovedAt: new Date() } });
        await this.prisma.driverAssistRequest.updateMany({ where: { orderId: o.id, status: DriverAssistRequestStatus.FULFILLED }, data: { status: DriverAssistRequestStatus.CANCELLED, resolvedAt: new Date() } });
        try {
          await this.ordersState.cancelOrder(null, o.id, 'Assist decision timed out');
        } catch (e) {
          this.logWarn(e);
        }
      } catch (e) { this.logWarn(e); }
    }
  }

  /**
   * Auto-assign the nearest eligible driver as the assistant (admin one-click).
   * Picks the closest available driver to the primary driver's last known
   * location (falling back to the delivery's pickup branch) and delegates to
   * the normal assign flow, so all eligibility/CAS/fee logic stays identical.
   */
  async autoAssignAssistDriver(requestId: string, actor: JwtAccessPayload) {
    const request = await this.findById(requestId);
    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    const nearest = await this.findNearestEligibleAssistDrivers(request, 1);
    if (nearest.length === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    return this.assignDriver(requestId, actor, { driverId: nearest[0] });
  }

  /**
   * Admin option 1: auto-offer the assist to the top-N nearest eligible drivers
   * simultaneously. Each gets a short-lived offer (socket + push); the first
   * to accept wins (CAS on assistDriverId), the rest are told "already filled".
   */
  async offerAssistToNearest(
    requestId: string,
    actor: JwtAccessPayload,
    limit = 5,
  ) {
    const request = await this.findById(requestId);
    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    const driverIds = await this.findNearestEligibleAssistDrivers(request, limit);
    if (driverIds.length === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }

    const ttlSecs = 15;
    const expiresAt = new Date(Date.now() + ttlSecs * 1000);
    const offerKey = `assist:offer:${requestId}`;
    await this.redis.set(
      offerKey,
      JSON.stringify({ driverIds, expiresAt: expiresAt.toISOString() }),
      ttlSecs,
    );

    for (const driverId of driverIds) {
      const driver = await this.prisma.driver.findUnique({
        where: { id: driverId },
        select: { userId: true },
      });
      if (!driver?.userId) continue;
      try {
        await this.notifications.create({
          userId: driver.userId,
          title: 'Assist offer',
          titleAr: 'عرض مساعدة',
          body: 'A driver needs help with a delivery. Accept to assist.',
          bodyAr: 'سائق يحتاج مساعدة في توصيل. اقبل للمساعدة.',
          type: 'ORDER_UPDATE',
          data: { requestId, orderId: request.orderId, action: 'assist_offer' },
        });
      } catch (e) { this.logWarn(e); }
      try {
        await this.socket.emitToUser(driver.userId, 'assist.offer', {
          requestId,
          orderId: request.orderId,
          expiresAt: expiresAt.toISOString(),
        });
      } catch (e) { this.logWarn(e); }
    }

    return { offered: driverIds, expiresAt: expiresAt.toISOString() };
  }

  /**
   * Driver responds to an assist offer. Accept → assign (CAS ensures exactly
   * one winner). Decline → remove this driver from the offer set.
   */
  async respondToAssistOffer(
    actor: JwtAccessPayload,
    requestId: string,
    accept: boolean,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const request = await this.findById(requestId);
    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const offerKey = `assist:offer:${requestId}`;
    const raw = await this.redis.get(offerKey);
    if (!raw) throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    const offer = JSON.parse(raw);
    if (!offer.driverIds.includes(driver.id)) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }
    if (Date.now() > new Date(offer.expiresAt).getTime()) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }

    if (!accept) {
      const remaining = offer.driverIds.filter((id: string) => id !== driver.id);
      if (remaining.length === 0) {
        await this.redis.del(offerKey);
      } else {
        await this.redis.set(offerKey, JSON.stringify({ ...offer, driverIds: remaining }), 15);
      }
      return { declined: true };
    }

    // Accept: assign via the normal flow (CAS on assistDriverId guarantees one winner).
    return this.assignDriver(requestId, actor, { driverId: driver.id });
  }

  /**
   * HTTP fallback: list pending assist offers for the current driver. The
   * driver app polls this when the socket is down/reconnecting so an offer is
   * never missed.
   */
  async getPendingAssistOffers(actor: JwtAccessPayload) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const keys = await this.redis.scanKeys('assist:offer:*');
    const offers: Array<{ requestId: string; orderId: string; expiresAt: string }> = [];
    for (const key of keys) {
      const raw = await this.redis.get(key);
      if (!raw) continue;
      try {
        const offer = JSON.parse(raw);
        if (!offer.driverIds?.includes(driver.id)) continue;
        if (Date.now() > new Date(offer.expiresAt).getTime()) continue;
        const requestId = key.replace('assist:offer:', '');
        offers.push({ requestId, orderId: offer.orderId, expiresAt: offer.expiresAt });
      } catch {
        // ignore malformed offer
      }
    }
    return offers;
  }

  /**
   * Resolve the primary driver and a target location ("nearest" reference).
   */
  private async resolveAssistTargetLocation(request: {
    deliveryGroupId: string | null;
    orderId: string;
  }): Promise<{ primaryDriverId: string | null; lng: number; lat: number }> {
    let primaryDriverId: string | null = null;
    let targetLng: number | null = null;
    let targetLat: number | null = null;

    if (request.deliveryGroupId) {
      const group = await this.prisma.orderDeliveryGroup.findUnique({
        where: { id: request.deliveryGroupId },
        select: { primaryDriverId: true },
      });
      primaryDriverId = group?.primaryDriverId ?? null;
      if (group?.primaryDriverId) {
        const loc = await this.fetchDriverLocations([group.primaryDriverId]).then((m) => m.get(group.primaryDriverId!));
        if (loc) { targetLng = loc.lng; targetLat = loc.lat; }
      }
      if (targetLng == null) {
        const pickup = await this.locationRepository.getDeliveryGroupPickupLocation(request.deliveryGroupId);
        if (pickup) { targetLng = pickup.lng; targetLat = pickup.lat; }
      }
    } else {
      const order = await this.prisma.order.findUnique({
        where: { id: request.orderId },
        select: { driverId: true, vendorBranchId: true },
      });
      primaryDriverId = order?.driverId ?? null;
      if (order?.driverId) {
        const loc = await this.fetchDriverLocations([order.driverId]).then((m) => m.get(order.driverId!));
        if (loc) { targetLng = loc.lng; targetLat = loc.lat; }
      }
      if (targetLng == null && order?.vendorBranchId) {
        const loc = await this.fetchBranchLocation(order.vendorBranchId);
        if (loc) { targetLng = loc.lng; targetLat = loc.lat; }
      }
    }

    if (targetLng == null || targetLat == null) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    return { primaryDriverId, lng: targetLng, lat: targetLat };
  }

  /**
   * Find the nearest eligible drivers for an assist request, sorted by distance
   * to the resolved target location. Returns up to `limit` driver ids.
   */
  private async findNearestEligibleAssistDrivers(
    request: { deliveryGroupId: string | null; orderId: string },
    limit: number,
  ): Promise<string[]> {
    const { primaryDriverId, lng, lat } = await this.resolveAssistTargetLocation(request);
    const settings = await this.platformSettings.getSettings();

    const candidates = await this.prisma.driver.findMany({
      where: {
        status: { in: [DriverStatus.ONLINE, DriverStatus.BUSY] },
        isApproved: true,
        deletedAt: null,
        hasUnpaidCommission: false,
        NOT: { id: primaryDriverId ?? undefined },
      },
      select: { id: true },
    });

    const busyOrderDrivers = await this.prisma.order.findMany({
      where: {
        status: { in: ['DRIVER_ASSIGNED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP'] },
        driverId: { not: null },
      },
      select: { driverId: true },
    });
    const busyGroupDrivers = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        id: { not: request.deliveryGroupId ?? undefined },
        OR: [{ primaryDriverId: { not: null } }, { assistDriverId: { not: null } }],
        status: { notIn: [DeliveryGroupStatus.DELIVERED, DeliveryGroupStatus.CANCELLED] },
      },
      select: { primaryDriverId: true, assistDriverId: true },
    });
    const busyIds = new Set<string>();
    for (const o of busyOrderDrivers) if (o.driverId) busyIds.add(o.driverId);
    for (const g of busyGroupDrivers) {
      if (g.primaryDriverId) busyIds.add(g.primaryDriverId);
      if (g.assistDriverId) busyIds.add(g.assistDriverId);
    }

    const locations = await this.fetchDriverLocations(candidates.map((c) => c.id));
    const eligible: { id: string; distance: number }[] = [];
    for (const c of candidates) {
      if (busyIds.has(c.id)) continue;
      const ll = locations.get(c.id);
      if (!ll) continue;
      const dist = this.haversineKm(ll.lng, ll.lat, lng, lat);
      if (settings.driverShiftsEnabled) {
        const shift = await this.prisma.driverShift.findFirst({
          where: { driverId: c.id, status: DriverShiftStatus.ACTIVE },
          select: { id: true },
        });
        if (!shift) continue;
      }
      eligible.push({ id: c.id, distance: dist });
    }
    eligible.sort((a, b) => a.distance - b.distance);
    return eligible.slice(0, limit).map((e) => e.id);
  }
  /** Driver id → {lng, lat} from lastLocation (raw: Unsupported geometry). */
  private async fetchDriverLocations(driverIds: string[]): Promise<Map<string, { lng: number; lat: number }>> {
    const map = new Map<string, { lng: number; lat: number }>();
    if (driverIds.length === 0) return map;
    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; lng: number; lat: number }>
    >`
      SELECT id, ST_X("lastLocation"::geometry) AS lng, ST_Y("lastLocation"::geometry) AS lat
      FROM drivers WHERE id IN (${Prisma.join(driverIds)})`;
    for (const r of rows) {
      if (r.lng != null && r.lat != null) map.set(r.id, { lng: Number(r.lng), lat: Number(r.lat) });
    }
    return map;
  }

  /** Branch id → {lng, lat} from location (raw: Unsupported geometry). */
  private async fetchBranchLocation(branchId: string): Promise<{ lng: number; lat: number } | null> {
    const rows = await this.prisma.$queryRaw<
      Array<{ lng: number; lat: number }>
    >`
      SELECT ST_X("location"::geometry) AS lng, ST_Y("location"::geometry) AS lat
      FROM vendor_branches WHERE id = ${branchId}`;
    if (rows[0]?.lng != null && rows[0]?.lat != null) {
      return { lng: Number(rows[0].lng), lat: Number(rows[0].lat) };
    }
    return null;
  }

  private haversineKm(lng1: number, lat1: number, lng2: number, lat2: number): number {
    const R = 6371.0088;
    const toRad = (d: number) => (d * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
  }

  async findById(requestId: string) {
    const request = await this.prisma.driverAssistRequest.findUnique({
      where: { id: requestId },
      include: this.includeShape(),
    });
    if (!request)
      throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    return request;
  }

  private includeShape() {
    return {
      driver: {
        select: {
          id: true,
          userId: true,
          name: true,
          vehicleType: true,
          status: true,
        },
      },
      assignedDriver: {
        select: {
          id: true,
          userId: true,
          name: true,
          vehicleType: true,
          status: true,
        },
      },
      order: { select: { id: true, orderNumber: true, status: true } },
      deliveryGroup: {
        select: {
          id: true,
          sequence: true,
          status: true,
          primaryDriverId: true,
          assistDriverId: true,
        },
      },
    } satisfies Prisma.DriverAssistRequestInclude;
  }

  private async resolveUserId(driverId: string | null): Promise<string | null> {
    if (!driverId) return null;
    const d = await this.prisma.driver.findUnique({
      where: { id: driverId },
      select: { userId: true },
    });
    return d?.userId ?? null;
  }

  private async notifyAssistAssignment(params: {
    assistUserId: string;
    primaryUserId: string | null;
    orderNumber: string;
  }): Promise<void> {
    // Both drivers are notified: the assistant (with their own inbox message)
    // and the primary (who keeps the delivery). Previously the assistant's
    // persisted notification was filtered out, so they only ever received the
    // transient socket event below.
    const targets: {
      userId: string;
      title: string;
      titleAr: string;
      body: string;
      bodyAr: string;
    }[] = [];
    if (params.assistUserId) {
      targets.push({
        userId: params.assistUserId,
        title: 'Assisting a delivery',
        titleAr: 'مساعد في توصيل',
        body: `You were assigned to assist delivery ${params.orderNumber}. You earn the full delivery fee.`,
        bodyAr: `تم تعيينك لمساعدة التوصيل ${params.orderNumber}. تحصل على كامل أجرة التوصيل.`,
      });
    }
    if (params.primaryUserId && params.primaryUserId !== params.assistUserId) {
      targets.push({
        userId: params.primaryUserId,
        title: 'Assisting driver assigned',
        titleAr: 'تم تعيين سائق مساعد',
        body: `A second driver was added to delivery ${params.orderNumber}. You remain the primary driver.`,
        bodyAr: `تمت إضافة سائق ثانٍ للتوصيل ${params.orderNumber}. لا تزال السائق الأساسي.`,
      });
    }

    for (const target of targets) {
      try {
        await this.notifications.create({
          userId: target.userId,
          title: target.title,
          titleAr: target.titleAr,
          body: target.body,
          bodyAr: target.bodyAr,
          type: 'ORDER_UPDATE',
          data: { orderId: params.orderNumber },
        });
      } catch (error) {
        // A notification failure must never fail the assignment itself.
        this.logWarn(error);
      }
    }

    try {
      await this.socket.emitToUser(params.assistUserId, 'order.assigned', {
        role: 'ASSISTING',
      });
    } catch (error) {
      this.logWarn(error);
    }
  }

  private logWarn(error: unknown) {
    console.warn('[DriverAssistService] side-effect failed', error);
  }
}
