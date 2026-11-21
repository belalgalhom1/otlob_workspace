import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
  ReviewTargetType,
} from '@prisma/client';
import {
  OrderErrors,
  ReviewErrors,
  CustomerErrors,
  DriverErrors,
} from '../../common/constants/response.constants';
import { EVENTS, ReviewSubmittedEvent } from '../../common/events';

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

    const order = await this.prisma.order.findFirst({
      where: { id: orderId, customerId: customer.id },
      include: {
        reviews: true,
        vendorFulfillments: {
          select: { id: true, vendorId: true, status: true },
        },
        deliveryGroups: {
          select: {
            id: true,
            sequence: true,
            status: true,
            primaryDriverId: true,
          },
          orderBy: { sequence: 'asc' },
        },
      },
    });

    if (!order) throw new NotFoundException(OrderErrors.NOT_FOUND);
    if (order.status !== OrderStatus.DELIVERED) {
      throw new BadRequestException(ReviewErrors.NOT_DELIVERED);
    }

    const deliveredFulfillments = order.vendorFulfillments.filter(
      (f) =>
        f.status !== OrderVendorFulfillmentStatus.REJECTED &&
        f.status !== OrderVendorFulfillmentStatus.CANCELLED,
    );
    const deliveredGroups = order.deliveryGroups.filter(
      (g) =>
        g.status === DeliveryGroupStatus.DELIVERED && g.primaryDriverId != null,
    );

    const existingFulfillmentIds = new Set(
      order.reviews
        .map((r) => r.fulfillmentId)
        .filter((id): id is string => Boolean(id)),
    );
    const existingGroupIds = new Set(
      order.reviews
        .map((r) => r.deliveryGroupId)
        .filter((id): id is string => Boolean(id)),
    );

    const rowsToCreate: Array<{
      orderId: string;
      customerId: string;
      targetType: ReviewTargetType;
      fulfillmentId?: string;
      deliveryGroupId?: string;
      vendorId?: string;
      driverId?: string;
      rating: number;
      comment?: string;
    }> = [];

    if (dto.fulfillmentRatings?.length) {
      for (const entry of dto.fulfillmentRatings) {
        const fulfillment = deliveredFulfillments.find(
          (f) => f.id === entry.fulfillmentId,
        );
        if (!fulfillment) {
          throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
        }
        if (
          existingFulfillmentIds.has(fulfillment.id) ||
          rowsToCreate.some((r) => r.fulfillmentId === fulfillment.id)
        ) {
          throw new BadRequestException(ReviewErrors.ALREADY_RATED);
        }
        rowsToCreate.push({
          orderId,
          customerId: customer.id,
          targetType: ReviewTargetType.VENDOR_FULFILLMENT,
          fulfillmentId: fulfillment.id,
          vendorId: fulfillment.vendorId,
          rating: entry.rating,
          comment: entry.comment ?? dto.comment,
        });
      }
    } else if (dto.vendorRating !== undefined) {
      if (deliveredFulfillments.length === 0) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }
      const targets = deliveredFulfillments.filter(
        (f) => !existingFulfillmentIds.has(f.id),
      );
      if (targets.length === 0) {
        throw new BadRequestException(ReviewErrors.ALREADY_RATED);
      }
      for (const target of targets) {
        rowsToCreate.push({
          orderId,
          customerId: customer.id,
          targetType: ReviewTargetType.VENDOR_FULFILLMENT,
          fulfillmentId: target.id,
          vendorId: target.vendorId,
          rating: dto.vendorRating,
          comment: dto.comment,
        });
      }
    }

    if (dto.deliveryGroupRatings?.length) {
      for (const entry of dto.deliveryGroupRatings) {
        const group = deliveredGroups.find(
          (g) => g.id === entry.deliveryGroupId,
        );
        if (!group || !group.primaryDriverId) {
          throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
        }
        if (
          existingGroupIds.has(group.id) ||
          rowsToCreate.some((r) => r.deliveryGroupId === group.id)
        ) {
          throw new BadRequestException(ReviewErrors.ALREADY_RATED);
        }
        rowsToCreate.push({
          orderId,
          customerId: customer.id,
          targetType: ReviewTargetType.DELIVERY_GROUP,
          deliveryGroupId: group.id,
          driverId: group.primaryDriverId,
          rating: entry.rating,
          comment: entry.comment ?? dto.comment,
        });
      }
    } else if (dto.driverRating !== undefined) {
      if (deliveredGroups.length === 0) {
        throw new BadRequestException(OrderErrors.INVALID_TRANSITION);
      }
      const targets = deliveredGroups.filter(
        (g) => !existingGroupIds.has(g.id) && Boolean(g.primaryDriverId),
      );
      if (targets.length === 0) {
        throw new BadRequestException(ReviewErrors.ALREADY_RATED);
      }
      for (const target of targets) {
        rowsToCreate.push({
          orderId,
          customerId: customer.id,
          targetType: ReviewTargetType.DELIVERY_GROUP,
          deliveryGroupId: target.id,
          driverId: target.primaryDriverId!,
          rating: dto.driverRating,
          comment: dto.comment,
        });
      }
    }

    if (rowsToCreate.length === 0) {
      throw new BadRequestException(ReviewErrors.ALREADY_RATED);
    }

    try {
      await this.prisma.orderReview.createMany({ data: rowsToCreate });
    } catch (e: unknown) {
      const code =
        typeof e === 'object' && e !== null && 'code' in e
          ? (e as { code?: string }).code
          : undefined;
      if (code === 'P2002') {
        throw new BadRequestException(ReviewErrors.ALREADY_RATED);
      }
      throw e;
    }

    const ratedVendorIds = Array.from(
      new Set(rowsToCreate.map((r) => r.vendorId).filter(Boolean)),
    ) as string[];
    const ratedDriverIds = Array.from(
      new Set(rowsToCreate.map((r) => r.driverId).filter(Boolean)),
    ) as string[];

    for (const vId of ratedVendorIds) {
      this.eventEmitter.emit(
        EVENTS.REVIEW_SUBMITTED,
        new ReviewSubmittedEvent(vId, null),
      );
    }

    for (const dId of ratedDriverIds) {
      this.eventEmitter.emit(
        EVENTS.REVIEW_SUBMITTED,
        new ReviewSubmittedEvent(null, dId),
      );
    }
  }

  async getVendorReviews(
    vendorId: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const skip = (page - 1) * limit;
    const whereClause = {
      vendorId,
      targetType: ReviewTargetType.VENDOR_FULFILLMENT,
    };

    const [rows, total] = await Promise.all([
      this.prisma.orderReview.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          customer: {
            select: {
              user: { select: { id: true, name: true, avatar: true } },
            },
          },
          fulfillment: {
            select: {
              id: true,
              vendorBranch: { select: { id: true, name: true, nameAr: true } },
            },
          },
        },
      }),
      this.prisma.orderReview.count({
        where: whereClause,
      }),
    ]);

    const data = rows.map((r) => ({
      ...r,
      vendorRating: r.rating,
    }));

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
      driverId,
      targetType: ReviewTargetType.DELIVERY_GROUP,
    };

    const [rows, total] = await Promise.all([
      this.prisma.orderReview.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          customer: {
            select: {
              user: { select: { id: true, name: true, avatar: true } },
            },
          },
        },
      }),
      this.prisma.orderReview.count({
        where: whereClause,
      }),
    ]);

    const data = rows.map((r) => ({
      ...r,
      driverRating: r.rating,
    }));

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
