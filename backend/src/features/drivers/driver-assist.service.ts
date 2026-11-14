import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { DriverAssistMatchingService } from './driver-assist-matching.service';
import {
  CustomerErrors,
  DriverErrors,
  OrderErrors,
} from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  DriverAssistAssignedEvent,
  DriverAssistCustomerDecidedEvent,
  DriverAssistDecidedEvent,
  DriverAssistRequestedEvent,
  DriverAssistTimedOutEvent,
} from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  ORDER_ASSIST_CANCELLATION_PORT,
  type OrderAssistCancellationPort,
} from '../../common/orders/order-assist.ports';
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
  private readonly logger = new Logger(DriverAssistService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly platformSettings: PlatformSettingsService,
    private readonly matchingService: DriverAssistMatchingService,
    @Inject(ORDER_ASSIST_CANCELLATION_PORT)
    private readonly ordersState: OrderAssistCancellationPort,
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
      where: {
        status: {
          in: [
            DriverAssistRequestStatus.PENDING,
            DriverAssistRequestStatus.APPROVED,
          ],
        },
      },
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

    if (
      request.status !== DriverAssistRequestStatus.APPROVED &&
      request.status !== DriverAssistRequestStatus.PENDING
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    if (!request.deliveryGroupId) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }

    const groupId = request.deliveryGroupId;

    const candidate = await this.requireEligibleAssistCandidate(dto.driverId);

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

    // Assisting driver gets the same delivery fee as primary driver (charged to customer)
    const assistFee = Number(group?.deliveryFee ?? 0);

    await this.prisma.orderDeliveryGroup.update({
      where: { id: groupId },
      data: { assistFee },
    });

    // Emit proposal + assignment events so customer & driver listeners dispatch
    // durable notifications and real-time socket events asynchronously.
    const { customerUserId, orderNumber } = await this.resolveCustomerUserId(
      request.orderId,
    );

    await this.matchingService.clearOffer(requestId);

    this.eventEmitter.emit(
      EVENTS.DRIVER_ASSIST_ASSIGNED,
      new DriverAssistAssignedEvent(
        requestId,
        request.orderId,
        orderNumber ?? request.order?.orderNumber ?? request.orderId,
        groupId,
        assistFee,
        customerUserId,
        primaryUserId,
        candidate.userId,
      ),
    );

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
      const claimed = await this.prisma.orderDeliveryGroup.updateMany({
        where: { id: deliveryGroupId, assistCustomerApproved: null },
        data: {
          assistCustomerApproved: true,
          assistApprovedAt: new Date(),
        },
      });
      if (claimed.count === 0) {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
      }
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

      const [primaryUserId, assistUserId] = await Promise.all([
        this.resolveUserId(group.primaryDriverId),
        this.resolveUserId(group.assistDriverId),
      ]);
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED,
        new DriverAssistCustomerDecidedEvent(
          orderId,
          deliveryGroupId,
          true,
          assistFee,
          primaryUserId,
          assistUserId,
        ),
      );
    } else {
      // Declined: remove the assistant, cancel the assist request, no charge.
      // The delivery group (and the order, if it was the last active one) is
      // cancelled because the driver cannot complete an oversized delivery alone.
      const claimed = await this.prisma.orderDeliveryGroup.updateMany({
        where: { id: deliveryGroupId, assistCustomerApproved: null },
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
      if (claimed.count === 0) {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
      }

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
      } else {
        try {
          await this.ordersState.recomputeGroupedOrderStatusAfterCancel(
            orderId,
            [group.primaryDriverId, group.assistDriverId],
          );
        } catch (e) {
          this.logWarn(e);
        }
      }

      const [primaryUserId, assistUserId] = await Promise.all([
        this.resolveUserId(group.primaryDriverId),
        this.resolveUserId(group.assistDriverId),
      ]);
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED,
        new DriverAssistCustomerDecidedEvent(
          orderId,
          deliveryGroupId,
          false,
          assistFee,
          primaryUserId,
          assistUserId,
        ),
      );
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
        } else {
          try {
            await this.ordersState.recomputeGroupedOrderStatusAfterCancel(
              g.orderId,
              [g.primaryDriverId, g.assistDriverId],
            );
          } catch (e) {
            this.logWarn(e);
          }
        }

        const [{ customerUserId }, primaryUserId, assistUserId] =
          await Promise.all([
            this.resolveCustomerUserId(g.orderId),
            this.resolveUserId(g.primaryDriverId),
            this.resolveUserId(g.assistDriverId),
          ]);

        this.eventEmitter.emit(
          EVENTS.DRIVER_ASSIST_TIMED_OUT,
          new DriverAssistTimedOutEvent(
            g.orderId,
            g.id,
            customerUserId,
            primaryUserId,
            assistUserId,
          ),
        );
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
    if (order.status === 'PICKED_UP' || order.status === 'PARTIALLY_PICKED_UP') {
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
    if (
      request.status !== DriverAssistRequestStatus.APPROVED &&
      request.status !== DriverAssistRequestStatus.PENDING
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    if (request.deliveryGroupId) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }

    const candidate = await this.requireEligibleAssistCandidate(dto.driverId);

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
        where: { driverId: candidate.id, status: { in: ['DRIVER_ASSIGNED','PREPARING','READY_FOR_PICKUP','PARTIALLY_PICKED_UP','PICKED_UP'] } },
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

      // Assisting driver gets the same delivery fee as primary driver (charged to customer)
      const assistFee = Number(order.deliveryFee ?? 0);

      await tx.order.update({ where: { id: orderId }, data: { assistFee } });

      return { primaryDriverId: order.driverId, assistFee };
    });

    const primaryUserId = await this.resolveUserId(assigned.primaryDriverId);
    const assistFee = assigned.assistFee;

    const { customerUserId, orderNumber } =
      await this.resolveCustomerUserId(orderId);

    await this.matchingService.clearOffer(requestId);

    this.eventEmitter.emit(
      EVENTS.DRIVER_ASSIST_ASSIGNED,
      new DriverAssistAssignedEvent(
        requestId,
        orderId,
        orderNumber ?? orderId,
        null,
        assistFee,
        customerUserId,
        primaryUserId,
        candidate.userId,
      ),
    );

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
      const claimed = await this.prisma.order.updateMany({
        where: { id: orderId, assistCustomerApproved: null },
        data: { assistCustomerApproved: true, assistApprovedAt: new Date(), deliveryFee: { increment: assistFee }, grandTotal: { increment: assistFee } },
      });
      if (claimed.count === 0) {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
      }
      const [primaryUserId, assistUserId] = await Promise.all([
        this.resolveUserId(order.driverId),
        this.resolveUserId(order.assistDriverId),
      ]);
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED,
        new DriverAssistCustomerDecidedEvent(
          orderId,
          null,
          true,
          assistFee,
          primaryUserId,
          assistUserId,
        ),
      );
    } else {
      const claimed = await this.prisma.order.updateMany({
        where: { id: orderId, assistCustomerApproved: null },
        data: { assistDriverId: null, assistDriverShiftId: null, assistFee: null, assistCustomerApproved: false, assistApprovedAt: new Date() },
      });
      if (claimed.count === 0) {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
      }
      await this.prisma.driverAssistRequest.updateMany({ where: { orderId, status: DriverAssistRequestStatus.FULFILLED }, data: { status: DriverAssistRequestStatus.CANCELLED, resolvedAt: new Date() } });
      try {
        await this.ordersState.cancelOrder(null, orderId, 'Customer declined assisted delivery');
      } catch (e) {
        this.logWarn(e);
      }
      const [primaryUserId, assistUserId] = await Promise.all([
        this.resolveUserId(order.driverId),
        this.resolveUserId(order.assistDriverId),
      ]);
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED,
        new DriverAssistCustomerDecidedEvent(
          orderId,
          null,
          false,
          assistFee,
          primaryUserId,
          assistUserId,
        ),
      );
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
        const [{ customerUserId }, primaryUserId, assistUserId] =
          await Promise.all([
            this.resolveCustomerUserId(o.id),
            this.resolveUserId(o.driverId),
            this.resolveUserId(o.assistDriverId),
          ]);
        this.eventEmitter.emit(
          EVENTS.DRIVER_ASSIST_TIMED_OUT,
          new DriverAssistTimedOutEvent(
            o.id,
            null,
            customerUserId,
            primaryUserId,
            assistUserId,
          ),
        );
      } catch (e) { this.logWarn(e); }
    }
  }

  async autoAssignAssistDriver(requestId: string, actor: JwtAccessPayload) {
    const request = await this.findById(requestId);
    if (
      request.status !== DriverAssistRequestStatus.APPROVED &&
      request.status !== DriverAssistRequestStatus.PENDING
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    const bestDriverId = await this.matchingService.findBestCandidate(request);
    return this.assignDriver(requestId, actor, { driverId: bestDriverId });
  }

  async offerAssistToNearest(
    requestId: string,
    actor: JwtAccessPayload,
    limit = 5,
  ) {
    return this.matchingService.offerAssistToNearest(requestId, actor, limit);
  }

  async respondToAssistOffer(
    actor: JwtAccessPayload,
    requestId: string,
    accept: boolean,
  ) {
    const result = await this.matchingService.respondToAssistOffer(
      actor,
      requestId,
      accept,
    );
    if ('declined' in result) {
      return result;
    }
    return this.assignDriver(requestId, actor, {
      driverId: result.acceptedDriverId,
    });
  }

  async getPendingAssistOffers(actor: JwtAccessPayload) {
    return this.matchingService.getPendingAssistOffers(actor);
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

  private async requireEligibleAssistCandidate(driverId: string) {
    const candidate = await this.prisma.driver.findUnique({
      where: { id: driverId },
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
    return candidate;
  }

  private async resolveCustomerUserId(orderId: string): Promise<{
    customerUserId: string | null;
    orderNumber: string | null;
  }> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { customerId: true, orderNumber: true },
    });
    if (!order) {
      return { customerUserId: null, orderNumber: null };
    }
    const customer = await this.prisma.customer.findUnique({
      where: { id: order.customerId },
      select: { userId: true },
    });
    return {
      customerUserId: customer?.userId ?? null,
      orderNumber: order.orderNumber,
    };
  }

  private async resolveUserId(driverId: string | null): Promise<string | null> {
    if (!driverId) return null;
    const d = await this.prisma.driver.findUnique({
      where: { id: driverId },
      select: { userId: true },
    });
    return d?.userId ?? null;
  }

  private logWarn(error: unknown) {
    this.logger.warn(
      `Side-effect failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}
