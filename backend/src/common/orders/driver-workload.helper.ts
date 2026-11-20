import { Injectable } from '@nestjs/common';
import { DeliveryGroupStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';

type QueryClient = Prisma.TransactionClient | PrismaService;

/**
 * Counts a driver's active delivery commitments across `OrderDeliveryGroup`.
 * Every order (STANDARD, CUSTOM_DELIVERY, RIDE) has at least one group.
 */
@Injectable()
export class DriverWorkloadHelper {
  async countActiveUnits(
    client: QueryClient,
    driverId: string,
    excludeOrderId?: string,
  ): Promise<number> {
    const groupOrderFilter = excludeOrderId
      ? { orderId: { not: excludeOrderId } }
      : {};

    return client.orderDeliveryGroup.count({
      where: {
        ...groupOrderFilter,
        status: {
          notIn: [DeliveryGroupStatus.CANCELLED, DeliveryGroupStatus.DELIVERED],
        },
        OR: [{ primaryDriverId: driverId }, { assistDriverId: driverId }],
      },
    });
  }
}
