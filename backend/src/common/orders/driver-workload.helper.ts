import { Injectable } from '@nestjs/common';
import { DeliveryGroupStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DRIVER_ACTIVE_ORDER_STATUSES } from './order-status.constants';

type QueryClient = Prisma.TransactionClient | PrismaService;

/**
 * Counts a driver's active delivery commitments across both grouped deliveries
 * (`OrderDeliveryGroup`) and legacy ungrouped orders (`Order` without groups).
 */
@Injectable()
export class DriverWorkloadHelper {
  async countActiveUnits(
    client: QueryClient,
    driverId: string,
    excludeOrderId?: string,
  ): Promise<number> {
    const orderFilter = excludeOrderId ? { id: { not: excludeOrderId } } : {};
    const groupOrderFilter = excludeOrderId
      ? { orderId: { not: excludeOrderId } }
      : {};

    const [activeGroups, activeLegacyOrders] = await Promise.all([
      client.orderDeliveryGroup.count({
        where: {
          ...groupOrderFilter,
          status: {
            notIn: [
              DeliveryGroupStatus.CANCELLED,
              DeliveryGroupStatus.DELIVERED,
            ],
          },
          OR: [{ primaryDriverId: driverId }, { assistDriverId: driverId }],
        },
      }),
      client.order.count({
        where: {
          driverId,
          ...orderFilter,
          status: { in: DRIVER_ACTIVE_ORDER_STATUSES },
          deliveryGroups: { none: {} },
        },
      }),
    ]);

    return activeGroups + activeLegacyOrders;
  }
}
