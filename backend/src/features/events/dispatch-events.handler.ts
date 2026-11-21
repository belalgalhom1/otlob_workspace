import { Injectable, Logger } from '@nestjs/common';
import {
  DispatchStatus,
  NotificationType,
  OrderType,
  Role,
} from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationsService } from '../notifications/notifications.service';
import { StatisticsService } from '../statistics/statistics.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  DriverAssistRequestedEvent,
  OrderDispatchRespondedEvent,
  OrderDispatchSentEvent,
} from '../../common/events';

const WS = {
  DISPATCH_INCOMING: 'dispatch.incoming',
} as const;

/**
 * Worker-side handler for dispatch & driver-assist notification/statistics side-effects.
 */
@Injectable()
export class DispatchEventsHandler {
  private readonly logger = new Logger(DispatchEventsHandler.name);

  constructor(
    private readonly socketService: SocketService,
    private readonly notificationsService: NotificationsService,
    private readonly statisticsService: StatisticsService,
    private readonly prisma: PrismaService,
  ) {}

  async handleDispatchSent(event: OrderDispatchSentEvent) {
    this.logger.log(
      `Dispatch sent to driver ${event.driverId} for order ${event.orderNumber}`,
    );

    await this.socketService.emitToUser(
      event.driverUserId,
      WS.DISPATCH_INCOMING,
      {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
        orderNumber: event.orderNumber,
        type: event.type,
        estimatedEarnings: event.estimatedEarnings,
        deliveryFee: event.deliveryFee ?? null,
        distanceKm: event.distanceKm,
        expiresAt: event.expiresAt,
        pickupLocationName: event.pickupLocationName,
        dropoffLocationName: event.dropoffLocationName,
        pickupLocationLogo: event.pickupLocationLogo ?? null,
        dropoffCustomerAvatar: event.dropoffCustomerAvatar ?? null,
        isStacked: event.isStacked,
      },
    );

    const distanceLabel = Number(event.distanceKm ?? 0).toFixed(1);
    const isRide = event.type === OrderType.RIDE;
    const isCustomDelivery = event.type === OrderType.CUSTOM_DELIVERY;

    await this.notificationsService.create({
      userId: event.driverUserId,
      title: isRide
        ? 'New Ride Request'
        : isCustomDelivery
          ? 'New Custom Delivery Request'
          : 'New Delivery Request',
      titleAr: isRide
        ? 'طلب رحلة جديد'
        : isCustomDelivery
          ? 'طلب توصيل خاص جديد'
          : 'طلب توصيل جديد',
      body: isRide
        ? `Ride ${event.orderNumber} — ${distanceLabel}km`
        : `Order ${event.orderNumber} — ${distanceLabel}km`,
      bodyAr: isRide
        ? `رحلة ${event.orderNumber} — ${distanceLabel} كم`
        : `طلب ${event.orderNumber} — ${distanceLabel} كم`,
      type: NotificationType.ORDER_UPDATE,
      data: {
        dispatchId: event.dispatchId,
        orderId: event.orderId,
        type: 'DISPATCH',
      },
    });

    await this.statisticsService
      .recordDispatchSent(event.dispatchId, event.driverId)
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to record dispatch-sent stat: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
  }

  async handleDispatchResponded(event: OrderDispatchRespondedEvent) {
    this.logger.log(
      `Dispatch ${event.dispatchId} responded: ${event.status} by driver ${event.driverId}`,
    );

    if (event.status === DispatchStatus.ACCEPTED) {
      await this.statisticsService
        .recordDispatchAccepted(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-accepted stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    } else if (event.status === DispatchStatus.REJECTED) {
      await this.statisticsService
        .recordDispatchRejected(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-rejected stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    } else if (event.status === DispatchStatus.EXPIRED) {
      await this.statisticsService
        .recordDispatchExpired(event.dispatchId, event.driverId)
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to record dispatch-expired stat: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }
  }

  async handleDriverAssistRequested(event: DriverAssistRequestedEvent) {
    const order = await this.prisma.order.findUnique({
      where: { id: event.orderId },
      select: { zoneId: true },
    });
    const zoneId = order?.zoneId ?? null;

    const managerScope = zoneId
      ? { OR: [{ manageAllDrivers: true }, { zoneId }] }
      : { manageAllDrivers: true };

    const recipients = await this.prisma.user.findMany({
      where: {
        OR: [
          { role: { in: [Role.ADMIN, Role.SUPER_ADMIN] } },
          {
            role: Role.DRIVER_MANAGER,
            driverManager: { is: managerScope },
          },
        ],
      },
      select: { id: true },
    });
    if (recipients.length === 0) return { skipped: true };

    await this.notificationsService.createMany(
      recipients.map(({ id }) => ({
        userId: id,
        title: 'Driver assistance requested',
        titleAr: 'طلب مساعدة سائق',
        body: `A driver requested assistance on order ${event.orderNumber}.`,
        bodyAr: `طلب سائق المساعدة في الطلب ${event.orderNumber}.`,
        type: NotificationType.SYSTEM,
        data: {
          requestId: event.requestId,
          orderId: event.orderId,
          deliveryGroupId: event.deliveryGroupId,
          driverUserId: event.driverUserId,
        },
      })),
    );

    return { notified: recipients.length };
  }
}
