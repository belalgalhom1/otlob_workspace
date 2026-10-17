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
import { DriverErrors } from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  DriverAssistAssignedEvent,
  DriverAssistDecidedEvent,
  DriverAssistRequestedEvent,
} from '../../common/events';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  DeliveryGroupStatus,
  DriverAssistReason,
  DriverAssistRequestStatus,
  DriverStatus,
  Prisma,
} from '@prisma/client';

export interface RequestAssistDto {
  reason: DriverAssistReason;
  note?: string;
}

export interface DecideAssistDto {
  status: Extract<
    DriverAssistRequestStatus,
    'APPROVED' | 'REJECTED'
  >;
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
      throw new BadRequestException(DriverErrors.ASSIST_DELIVERY_ALREADY_STARTED);
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
        },
      });
      if (!group) throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);

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
            in: ['DRIVER_ASSIGNED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP'],
          },
        },
        select: { id: true },
      });
      if (busy) {
        throw new ConflictException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
      }

      // CAS on assistDriverId so two concurrent admins cannot both win.
      const claimed = await tx.orderDeliveryGroup.updateMany({
        where: { id: groupId, assistDriverId: null },
        data: {
          assistDriverId: candidate.id,
          assignedByUserId: actor.sub,
          assignedAt: new Date(),
        },
      });
      if (claimed.count === 0) {
        throw new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED);
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

  async findById(requestId: string) {
    const request = await this.prisma.driverAssistRequest.findUnique({
      where: { id: requestId },
      include: this.includeShape(),
    });
    if (!request) throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    return request;
  }

  private includeShape() {
    return {
      driver: {
        select: { id: true, userId: true, name: true, vehicleType: true, status: true },
      },
      assignedDriver: {
        select: { id: true, userId: true, name: true, vehicleType: true, status: true },
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
    const recipients = [params.assistUserId, params.primaryUserId].filter(
      (v): v is string => !!v && v !== params.assistUserId,
    );

    for (const userId of recipients) {
      try {
        await this.notifications.create({
          userId,
          title: 'Assisting driver assigned',
          titleAr: 'تم تعيين سائق مساعد',
          body: `A second driver was added to delivery ${params.orderNumber}. You remain the primary driver.`,
          bodyAr: `تمت إضافة سائق ثانٍ للتوصيل ${params.orderNumber}. لا تزال السائق الأساسي.`,
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
    // eslint-disable-next-line no-console
    console.warn('[DriverAssistService] side-effect failed', error);
  }
}