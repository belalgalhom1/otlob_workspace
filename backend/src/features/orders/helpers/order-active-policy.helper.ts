import { BadRequestException, Injectable } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';
import { OrderErrors } from '../../../common/constants/response.constants';

export interface ActiveOrderPolicy {
  maxActive: number;
  requirePriorDelivery: boolean;
}

/**
 * Shared active-order concurrency policy check used across single-vendor,
 * multi-branch, multi-vendor, custom-delivery, and direct checkout flows.
 */
@Injectable()
export class OrderActivePolicyHelper {
  constructor(
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async validateActiveOrderLimit(customerId: string): Promise<ActiveOrderPolicy> {
    const settings = await this.platformSettings.getSettings();

    const policy: ActiveOrderPolicy = {
      maxActive: settings.maxActiveOrdersPerCustomer,
      requirePriorDelivery: settings.requirePriorDeliveryForMultipleOrders,
    };

    const activeCount = await this.prisma.order.count({
      where: {
        customerId,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
      },
    });

    // Fast path: 0 active orders always allowed; the in-tx advisory lock
    // check remains authoritative against concurrent placement races.
    if (activeCount === 0) return policy;

    if (activeCount >= policy.maxActive) {
      throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
    }

    if (policy.requirePriorDelivery) {
      const hasCompletedOrder = await this.prisma.order.findFirst({
        where: {
          customerId,
          status: OrderStatus.DELIVERED,
        },
        select: { id: true },
      });

      if (!hasCompletedOrder) {
        throw new BadRequestException(OrderErrors.MAX_ACTIVE_ORDERS_REACHED);
      }
    }

    return policy;
  }
}
