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
  DeliveryIncidentResponsibility,
  DeliveryIncidentType,
  DriverAssistReason,
  DriverAssistRequestStatus,
  DriverShiftStatus,
  DriverStatus,
  OrderStatus,
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
  DeliveryGroupStatus.PARTIALLY_PICKED_UP,
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
    const driver = await this.requireDriverForActor(actor.sub);
    return this.requestAssistForDriver(driver, orderId, deliveryGroupId, dto);
  }

  private async requireDriverForActor(userId: string): Promise<{
    id: string;
    userId: string;
  }> {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true, userId: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  private async requestAssistForDriver(
    driver: { id: string; userId: string },
    orderId: string,
    deliveryGroupId: string,
    dto: RequestAssistDto,
  ) {
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
      group.order.status === OrderStatus.CANCELLED ||
      group.order.status === OrderStatus.DELIVERED
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
    const driver = await this.requireDriverForActor(actor.sub);

    const rows = await this.prisma.driverAssistRequest.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
      include: this.includeShape(),
    });
    return rows.map((r) => this.formatAssistRequest(r));
  }

  async listForOrder(orderId: string) {
    const rows = await this.prisma.driverAssistRequest.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
      include: this.includeShape(),
    });
    return rows.map((r) => this.formatAssistRequest(r));
  }

  async listPending() {
    const rows = await this.prisma.driverAssistRequest.findMany({
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
    return rows.map((r) => this.formatAssistRequest(r));
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

  async requestAssistForOrder(
    actor: JwtAccessPayload,
    orderId: string,
    dto: RequestAssistDto,
  ) {
    const driver = await this.requireDriverForActor(actor.sub);

    const group = await this.prisma.orderDeliveryGroup.findFirst({
      where: {
        orderId,
        primaryDriverId: driver.id,
        status: {
          notIn: [DeliveryGroupStatus.CANCELLED, DeliveryGroupStatus.DELIVERED],
        },
      },
      orderBy: { sequence: 'asc' },
      select: { id: true },
    });
    if (!group) {
      throw new NotFoundException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }
    return this.requestAssistForDriver(driver, orderId, group.id, dto);
  }

  async customerDecideAssistForOrder(
    actor: JwtAccessPayload,
    orderId: string,
    approved: boolean,
  ) {
    const group = await this.prisma.orderDeliveryGroup.findFirst({
      where: {
        orderId,
        assistDriverId: { not: null },
        assistCustomerApproved: null,
        status: { not: DeliveryGroupStatus.CANCELLED },
      },
      orderBy: { sequence: 'asc' },
      select: { id: true },
    });
    if (!group) {
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_NOT_ASSIGNED);
    }
    return this.customerDecideAssist(actor, orderId, group.id, approved);
  }

  async assignDriver(
    requestId: string,
    actor: JwtAccessPayload,
    dto: AssignAssistDriverDto,
  ) {
    const request = await this.findById(requestId);

    if (
      request.status !== DriverAssistRequestStatus.APPROVED &&
      request.status !== DriverAssistRequestStatus.PENDING
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const groupId = request.deliveryGroupId;
    const candidate = await this.requireEligibleAssistCandidate(dto.driverId);

    const assigned = await this.prisma.$transaction(async (tx) => {
      if (typeof tx.$executeRaw === 'function') {
        await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${candidate.id} FOR UPDATE`;
      }

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
      if (group.primaryDriverId === candidate.id) {
        throw new BadRequestException(
          DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED,
        );
      }

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

      const activeShift = await tx.driverShift.findFirst({
        where: { driverId: candidate.id, status: DriverShiftStatus.ACTIVE },
        select: { id: true },
        orderBy: { startTime: 'desc' },
      });

      const assistFee = Number(group.deliveryFee ?? 0);
      const claimed = await tx.orderDeliveryGroup.updateMany({
        where: { id: groupId, assistDriverId: null },
        data: {
          assistDriverId: candidate.id,
          assistDriverShiftId: activeShift?.id ?? null,
          assignedByUserId: actor.sub,
          assignedAt: new Date(),
          assistFee,
        },
      });
      if (claimed.count === 0) {
        throw new ConflictException(
          DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED,
        );
      }

      await tx.driver.update({
        where: { id: candidate.id },
        data: { status: DriverStatus.ON_DELIVERY },
      });

      await tx.driverAssistRequest.update({
        where: { id: requestId },
        data: {
          status: DriverAssistRequestStatus.FULFILLED,
          assignedDriverId: candidate.id,
          resolvedAt: new Date(),
        },
      });

      return { primaryDriverId: group.primaryDriverId, assistFee };
    });

    const primaryUserId = await this.resolveUserId(assigned.primaryDriverId);
    const assistFee = assigned.assistFee;

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
    if (!customer)
      throw new NotFoundException(CustomerErrors.CUSTOMER_NOT_FOUND);

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
        status: true,
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
    if (!approved && ASSIGNMENT_CLOSED_STATUSES.includes(group.status)) {
      throw new BadRequestException(
        DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED,
      );
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
      const tornDown = await this.teardownAssistOnGroup({
        orderId,
        deliveryGroupId,
        primaryDriverId: group.primaryDriverId,
        assistDriverId: group.assistDriverId,
        failureReason: 'Customer declined assisted delivery',
      });
      if (!tornDown) {
        throw new ConflictException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
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

  async autoDeclineExpiredAssistDecisions() {
    const settings = await this.platformSettings.getSettings();
    const timeoutSecs = Number(settings.assistDecisionTimeoutSecs ?? 120);
    const cutoff = new Date(Date.now() - timeoutSecs * 1000);

    const expired = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        assistDriverId: { not: null },
        assistCustomerApproved: null,
        assignedAt: { not: null, lt: cutoff },
        status: { notIn: ASSIGNMENT_CLOSED_STATUSES },
      },
      select: {
        id: true,
        orderId: true,
        primaryDriverId: true,
        assistDriverId: true,
        assistFee: true,
      },
      take: 100,
    });

    for (const g of expired) {
      try {
        const tornDown = await this.teardownAssistOnGroup({
          orderId: g.orderId,
          deliveryGroupId: g.id,
          primaryDriverId: g.primaryDriverId,
          assistDriverId: g.assistDriverId,
          failureReason: 'Assist decision timed out',
        });
        if (!tornDown) continue;

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

  private async teardownAssistOnGroup(params: {
    orderId: string;
    deliveryGroupId: string;
    primaryDriverId: string | null;
    assistDriverId: string | null;
    failureReason: string;
  }): Promise<boolean> {
    const claimed = await this.prisma.orderDeliveryGroup.updateMany({
      where: { id: params.deliveryGroupId, assistCustomerApproved: null },
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
    if (claimed.count === 0) return false;

    await this.prisma.driverAssistRequest.updateMany({
      where: {
        deliveryGroupId: params.deliveryGroupId,
        status: DriverAssistRequestStatus.FULFILLED,
      },
      data: {
        status: DriverAssistRequestStatus.CANCELLED,
        resolvedAt: new Date(),
      },
    });

    if (
      params.assistDriverId &&
      typeof this.prisma.driverDeliveryIncident?.create === 'function'
    ) {
      const isCustomerDecline = params.failureReason
        .toLowerCase()
        .includes('customer declined');
      await this.prisma.driverDeliveryIncident.create({
        data: {
          orderId: params.orderId,
          deliveryGroupId: params.deliveryGroupId,
          driverId: params.assistDriverId,
          incidentType: DeliveryIncidentType.DRIVER_UNASSIGNED,
          responsibility: isCustomerDecline
            ? DeliveryIncidentResponsibility.CUSTOMER
            : DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM,
          reason: params.failureReason,
          reportedByUserId: null,
          occurredAt: new Date(),
        },
      });
    }

    try {
      await this.ordersState.cancelDeliveryGroupAfterAssistFailure(
        params.orderId,
        params.deliveryGroupId,
        params.failureReason,
        [params.primaryDriverId, params.assistDriverId],
      );
    } catch (e) {
      this.logWarn(e);
    }

    return true;
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
    return this.formatAssistRequest(request);
  }

  private includeShape() {
    return {
      driver: {
        select: {
          id: true,
          userId: true,
          name: true,
          avatar: true,
          vehicleType: true,
          status: true,
          user: { select: { name: true, phone: true, avatar: true } },
        },
      },
      assignedDriver: {
        select: {
          id: true,
          userId: true,
          name: true,
          avatar: true,
          vehicleType: true,
          status: true,
          user: { select: { name: true, phone: true, avatar: true } },
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
          deliveryFee: true,
          assistFee: true,
        },
      },
    } satisfies Prisma.DriverAssistRequestInclude;
  }

  private formatAssistRequest<
    T extends {
      driver?: {
        avatar?: string | null;
        user?: { avatar?: string | null } | null;
      } | null;
      assignedDriver?: {
        avatar?: string | null;
        user?: { avatar?: string | null } | null;
      } | null;
      deliveryGroup?: {
        deliveryFee?: unknown;
        assistFee?: unknown;
      } | null;
    },
  >(r: T): T & { proposedAssistFee: number } {
    return {
      ...r,
      ...(r.driver
        ? {
            driver: {
              ...r.driver,
              avatar: r.driver.avatar ?? r.driver.user?.avatar ?? null,
            },
          }
        : {}),
      ...(r.assignedDriver
        ? {
            assignedDriver: {
              ...r.assignedDriver,
              avatar:
                r.assignedDriver.avatar ??
                r.assignedDriver.user?.avatar ??
                null,
            },
          }
        : {}),
      proposedAssistFee: Number(
        r.deliveryGroup?.assistFee ?? r.deliveryGroup?.deliveryFee ?? 0,
      ),
    };
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
