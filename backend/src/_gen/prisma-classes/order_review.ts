import { ReviewTargetType } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderReview {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  orderId: string;

  @ApiProperty({ type: String })
  customerId: string;

  @ApiProperty({ enum: ReviewTargetType, enumName: 'ReviewTargetType' })
  targetType: ReviewTargetType;

  @ApiPropertyOptional({ type: String })
  fulfillmentId?: string;

  @ApiPropertyOptional({ type: String })
  deliveryGroupId?: string;

  @ApiPropertyOptional({ type: String })
  vendorId?: string;

  @ApiPropertyOptional({ type: String })
  driverId?: string;

  @ApiProperty({ type: Number })
  rating: number;

  @ApiPropertyOptional({ type: String })
  comment?: string;

  @ApiProperty({ type: Date })
  createdAt: Date;

  @ApiProperty({ type: Date })
  updatedAt: Date;
}
