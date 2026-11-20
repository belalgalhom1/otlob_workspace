import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DeliveryIncidentResponsibility,
  OrderStatus,
  Role,
} from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { OrdersRepository } from '../orders.repository';
import { OrderAuthorizationHelper } from '../helpers/order-authorization.helper';
import { NON_CANCELLABLE } from './order-state.constants';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { OrderCancelledEvent } from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import {
  DriverErrors,
  OrderErrors,
} from '../../../common/constants/response.constants';
import { resolveOrderActorSnapshot } from '../helpers/order-actor.helper';

/**
 * Owns order cancellation authorization, guardrails, driver collection,
 * repository cancellation, and ORDER_CANCELLED emission.
 */
@Injectable()
export class OrderCancellationService {
  private readonly logger = new Logger(OrderCancellationService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly prisma: PrismaService,
    private readonly authHelper: OrderAuthorizationHelper,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async cancelOrder(
    actor: JwtAccessPayload | null,
    orderId: string,
    reason: string,
    options?: {
      vendorId?: string | null;
      responsibility?: DeliveryIncidentResponsibility;
      responsibleDriverId?: string;
    },
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    }
    const order = await this.ordersRepository.findById(orderId);

    if (NON_CANCELLABLE.includes(order.status)) {
      throw new BadRequestException(OrderErrors.CANNOT_CANCEL_ORDER);
    }

    if (actor) {
      await this.assertCanCancel(actor, order);
    }

    const fulfillments = ((order as any).vendorFulfillments ?? []) as Array<{
      vendorId: string;
    }>;
    const distinctVendorIds = Array.from(
      new Set(fulfillments.map((f) => f.vendorId).filter(Boolean)),
    );
    const singleVendorId =
      distinctVendorIds.length === 1 ? distinctVendorIds[0] : null;

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
    );

    // Collect every primary/assist driver across delivery groups so cancellation clears all of them.
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: { orderId: order.id },
      select: {
        id: true,
        status: true,
        sequence: true,
        isPaymentCollector: true,
        primaryDriverId: true,
        assistDriverId: true,
        primaryDriver: { select: { userId: true } },
      },
      orderBy: { sequence: 'asc' },
    });
    const groupDriverIds = groups
      .flatMap((g) => [g.primaryDriverId, g.assistDriverId])
      .filter((id): id is string => !!id);
    const allDriverIds = Array.from(new Set(groupDriverIds));
    const collectorGroup =
      groups.find((g) => g.isPaymentCollector && g.primaryDriverId) ??
      groups.find((g) => g.primaryDriverId) ??
      null;
    const primaryDriverId =
      collectorGroup?.primaryDriverId ?? allDriverIds[0] ?? null;

    const actorSnapshot = await resolveOrderActorSnapshot(
      this.prisma,
      actor?.sub ?? null,
      {
        fallbackRole: actor?.role ?? null,
        vendorId: options?.vendorId ?? singleVendorId,
        orderId,
      },
    );

    const assignedActiveGroups = groups.filter(
      (g) =>
        Boolean(g.id) &&
        Boolean(g.primaryDriverId) &&
        g.status !== DeliveryGroupStatus.CANCELLED &&
        g.status !== DeliveryGroupStatus.DELIVERED,
    );
    const distinctAssignedDriverIds = Array.from(
      new Set(assignedActiveGroups.map((g) => g.primaryDriverId!)),
    );

    const isAdminActor =
      actor != null &&
      actor.role !== Role.CUSTOMER &&
      actor.role !== Role.VENDOR_MEMBER;

    if (
      isAdminActor &&
      options?.responsibility === DeliveryIncidentResponsibility.DRIVER_AT_FAULT &&
      distinctAssignedDriverIds.length > 0
    ) {
      if (distinctAssignedDriverIds.length > 1 && !options.responsibleDriverId) {
        throw new BadRequestException(DriverErrors.RESPONSIBLE_DRIVER_REQUIRED);
      }
      if (
        options.responsibleDriverId &&
        !distinctAssignedDriverIds.includes(options.responsibleDriverId)
      ) {
        throw new BadRequestException(DriverErrors.RESPONSIBLE_DRIVER_REQUIRED);
      }
    }

    const resolveResponsibility = (
      driverId: string,
    ): DeliveryIncidentResponsibility => {
      if (!actor) {
        return options?.vendorId
          ? DeliveryIncidentResponsibility.VENDOR
          : DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM;
      }
      if (actor.role === Role.CUSTOMER) {
        return DeliveryIncidentResponsibility.CUSTOMER;
      }
      if (actor.role === Role.VENDOR_MEMBER) {
        return DeliveryIncidentResponsibility.VENDOR;
      }
      const chosen =
        options?.responsibility ??
        DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM;
      if (
        chosen === DeliveryIncidentResponsibility.DRIVER_AT_FAULT &&
        options?.responsibleDriverId &&
        options.responsibleDriverId !== driverId
      ) {
        return DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM;
      }
      return chosen;
    };

    const driverIncidents = assignedActiveGroups.map((g) => ({
      deliveryGroupId: g.id,
      driverId: g.primaryDriverId!,
      responsibility: resolveResponsibility(g.primaryDriverId!),
      reason: reason || null,
    }));

    const updatedOrder = await this.ordersRepository.cancelOrder(
      orderId,
      actor?.sub ?? 'system',
      reason,
      order.status,
      order.coinsUsed,
      order.customerId,
      order.orderNumber,
      allDriverIds,
      {
        actor: actorSnapshot,
        vendorId: options?.vendorId ?? singleVendorId,
        ...(driverIncidents.length > 0 ? { driverIncidents } : {}),
      },
    );

    const updatedGroups = (
      ((updatedOrder as any).deliveryGroups ?? []) as Array<{
        primaryDriverId: string | null;
        primaryDriver?: { userId: string } | null;
      }>
    ).filter(Boolean);
    const driverUserId =
      updatedGroups.find((g) => g.primaryDriverId === primaryDriverId)
        ?.primaryDriver?.userId ??
      collectorGroup?.primaryDriver?.userId ??
      null;

    this.eventEmitter.emit(
      EVENTS.ORDER_CANCELLED,
      new OrderCancelledEvent(
        orderId,
        order.orderNumber,
        order.customerId,
        ((updatedOrder as any).customer?.user?.id ??
          order.customer.user.id) as string,
        singleVendorId,
        vendorUserIds,
        primaryDriverId,
        driverUserId,
        reason,
        actor?.sub ?? null,
        allDriverIds,
        updatedOrder.revision,
        actorSnapshot.actorName,
        actorSnapshot.actorNameAr,
        actorSnapshot.actorRole,
        actorSnapshot.actorAvatar,
      ),
    );

    this.logger.log(`Order ${order.orderNumber} cancelled: ${reason}`);
    return this.ordersRepository.findById(orderId);
  }

  private async assertCanCancel(
    actor: JwtAccessPayload,
    order: any,
  ): Promise<void> {
    if (actor.role === Role.CUSTOMER) {
      if (order.customer.userId !== actor.sub) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
      }
      const customerCancellableStatuses: OrderStatus[] = [
        OrderStatus.PENDING,
        OrderStatus.CHANGES_REQUESTED,
        OrderStatus.ACCEPTED,
        OrderStatus.LOOKING_FOR_DRIVER,
      ];
      if (!customerCancellableStatuses.includes(order.status)) {
        throw new BadRequestException(
          OrderErrors.CANNOT_CANCEL_PREPARATION_STARTED,
        );
      }
      return;
    }

    if (actor.role === Role.VENDOR_MEMBER) {
      const vendorIds = new Set<string>();
      for (const f of (order.vendorFulfillments ?? []) as Array<{
        vendorId: string;
      }>) {
        if (f.vendorId) vendorIds.add(f.vendorId);
      }
      const isMember =
        vendorIds.size > 0 &&
        (await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub, vendorId: { in: [...vendorIds] } },
        })) !== null;
      if (!isMember) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
      }
      return;
    }

    if (actor.role === Role.DRIVER) {
      throw new ForbiddenException(OrderErrors.DRIVERS_CANNOT_CANCEL);
    }

    if (actor.role === Role.ADMIN || actor.role === Role.SUPER_ADMIN) {
      const canManage = await this.authHelper.canManageOrders(
        actor.sub,
        actor.role,
      );
      if (!canManage) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
      }
    }
  }
}
