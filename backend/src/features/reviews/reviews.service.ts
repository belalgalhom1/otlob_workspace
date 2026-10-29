import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { OrderStatus } from '@prisma/client';
import {
  OrderErrors,
  ReviewErrors,
  CustomerErrors,
  DriverErrors,
} from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';

@Injectable()
export class ReviewsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async submitReview(
    actor: JwtAccessPayload,
    orderId: string,
    dto: CreateReviewDto,
  ): Promise<void> {
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
    });
    if (!customer) {
      throw new NotFoundException(CustomerErrors.PROFILE_NOT_FOUND);
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId, customerId: customer.id },
      include: {
        review: true,
        vendorFulfillments: {
          select: { vendorId: true, status: true },
        },
        deliveryGroups: {
          select: { primaryDriverId: true },
        },
      },
    });

    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);
    if (order.status !== OrderStatus.DELIVERED) {
      throw new BadRequestException(ReviewErrors.NOT_DELIVERED);
    }
    if (order.review) {
      throw new BadRequestException(ReviewErrors.ALREADY_RATED);
    }

    const acceptedVendorIds = (order.vendorFulfillments ?? [])
      .filter((f) => f.status === 'ACCEPTED')
      .map((f) => f.vendorId);

    const groupDriverIds = (order.deliveryGroups ?? [])
      .map((g) => g.primaryDriverId)
      .filter(Boolean);

    const effectiveVendorId = order.vendorId ?? (acceptedVendorIds.length > 0 ? acceptedVendorIds[0] : null);
    const effectiveDriverId = order.driverId ?? (groupDriverIds.length > 0 ? groupDriverIds[0] : null);

    await this.prisma.orderReview.create({
      data: {
        orderId,
        customerId: customer.id,
        vendorId: effectiveVendorId,
        driverId: effectiveDriverId,
        vendorRating: dto.vendorRating,
        driverRating: dto.driverRating,
        comment: dto.comment,
      },
    });

    // Emit event so the listener can update aggregates safely for all participating vendors and drivers
    const allVendorIds = Array.from(
      new Set([order.vendorId, ...acceptedVendorIds].filter(Boolean)),
    );

    const allDriverIds = Array.from(
      new Set([order.driverId, ...groupDriverIds].filter(Boolean)),
    );

    for (const vId of allVendorIds) {
      this.eventEmitter.emit(EVENTS.REVIEW_SUBMITTED, {
        vendorId: vId,
        driverId: null,
      });
    }

    for (const dId of allDriverIds) {
      this.eventEmitter.emit(EVENTS.REVIEW_SUBMITTED, {
        vendorId: null,
        driverId: dId,
      });
    }
  }

  async getVendorReviews(
    vendorId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const skip = (page - 1) * limit;
    const whereClause = {
      OR: [
        { vendorId },
        {
          order: {
            vendorFulfillments: {
              some: { vendorId },
            },
          },
        },
      ],
      vendorRating: { not: null },
    };

    const [data, total] = await Promise.all([
      this.prisma.orderReview.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          customer: {
            select: {
              user: {
                select: {
                  name: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.orderReview.count({
        where: whereClause,
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getMyDriverReviews(
    userId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!driver) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }
    return this.getDriverReviews(driver.id, page, limit);
  }

  async getDriverReviews(
    driverId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const skip = (page - 1) * limit;
    const whereClause = {
      OR: [
        { driverId },
        {
          order: {
            deliveryGroups: {
              some: { primaryDriverId: driverId },
            },
          },
        },
      ],
      driverRating: { not: null },
    };

    const [data, total] = await Promise.all([
      this.prisma.orderReview.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          customer: {
            select: {
              user: {
                select: {
                  name: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.orderReview.count({
        where: whereClause,
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
