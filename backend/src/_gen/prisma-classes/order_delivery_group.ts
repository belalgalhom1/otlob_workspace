import { DeliveryGroupStatus } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Driver } from './driver';

export class OrderDeliveryGroup {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  orderId: string;

  @ApiProperty({ type: Number })
  sequence: number;

  @ApiProperty({ enum: DeliveryGroupStatus, enumName: 'DeliveryGroupStatus' })
  status: DeliveryGroupStatus = DeliveryGroupStatus.PENDING;

  @ApiPropertyOptional({ type: String })
  primaryDriverId?: string;

  @ApiPropertyOptional({ type: String })
  assistDriverId?: string;

  @ApiPropertyOptional({ type: Number })
  distanceKm?: number;

  @ApiProperty({ type: Number })
  deliveryFee: number;

  @ApiPropertyOptional({ type: String })
  pickupImageUrl?: string;

  @ApiPropertyOptional({ type: String })
  deliveryImageUrl?: string;

  @ApiPropertyOptional({ type: Date })
  pickedUpAt?: Date;

  @ApiPropertyOptional({ type: Date })
  deliveredAt?: Date;

  @ApiPropertyOptional({ type: () => Driver })
  primaryDriver?: Driver;

  @ApiPropertyOptional({ type: () => Driver })
  assistDriver?: Driver;
}
