import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReviewTargetType } from '@prisma/client';

class ReviewCustomerUserDto {
  @ApiProperty({ example: 'John Doe' })
  name!: string;
}

class ReviewCustomerDto {
  @ApiProperty({ type: ReviewCustomerUserDto })
  user!: ReviewCustomerUserDto;
}

export class ReviewDto {
  @ApiProperty({ example: 'uuid-1234' })
  id!: string;

  @ApiProperty({ example: 'order-uuid' })
  orderId!: string;

  @ApiProperty({ example: 'customer-uuid' })
  customerId!: string;

  @ApiProperty({ enum: ReviewTargetType })
  targetType!: ReviewTargetType;

  @ApiPropertyOptional({ example: 'fulfillment-uuid' })
  fulfillmentId?: string | null;

  @ApiPropertyOptional({ example: 'delivery-group-uuid' })
  deliveryGroupId?: string | null;

  @ApiPropertyOptional({ example: 'vendor-uuid' })
  vendorId?: string | null;

  @ApiPropertyOptional({ example: 'driver-uuid' })
  driverId?: string | null;

  @ApiProperty({ example: 5, description: 'Rating out of 5' })
  rating!: number;

  @ApiPropertyOptional({ example: 5, description: 'Vendor rating out of 5' })
  vendorRating?: number;

  @ApiPropertyOptional({ example: 4, description: 'Driver rating out of 5' })
  driverRating?: number;

  @ApiPropertyOptional({ example: 'Great service!' })
  comment?: string | null;

  @ApiProperty({ example: '2026-07-29T18:00:00Z' })
  createdAt!: Date;

  @ApiPropertyOptional({ type: ReviewCustomerDto })
  customer?: ReviewCustomerDto;
}

class PaginationMetaDto {
  @ApiProperty({ example: 100 })
  total!: number;

  @ApiProperty({ example: 1 })
  page!: number;

  @ApiProperty({ example: 20 })
  limit!: number;

  @ApiProperty({ example: 5 })
  totalPages!: number;
}

export class PaginatedReviewsResponseDto {
  @ApiProperty({ type: [ReviewDto] })
  data!: ReviewDto[];

  @ApiProperty({ type: PaginationMetaDto })
  meta!: PaginationMetaDto;
}
