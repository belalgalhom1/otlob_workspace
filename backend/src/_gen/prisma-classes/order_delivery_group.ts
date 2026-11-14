import { DeliveryGroupStatus } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Driver } from './driver';
import { OrderDeliveryGroupItem } from './order_delivery_group_item';

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
  primaryDriverShiftId?: string;

  @ApiPropertyOptional({ type: String })
  assistDriverId?: string;

  @ApiPropertyOptional({ type: String })
  assistDriverShiftId?: string;

  @ApiPropertyOptional({ type: Number })
  assistFee?: number;

  @ApiPropertyOptional({ type: Boolean })
  assistCustomerApproved?: boolean;

  @ApiPropertyOptional({ type: Date })
  assistApprovedAt?: Date;

  @ApiProperty({ type: Boolean })
  isStacked: boolean = false;

  @ApiProperty({ type: Boolean })
  isPaymentCollector: boolean = false;

  @ApiPropertyOptional({ type: String })
  assignedByUserId?: string;

  @ApiPropertyOptional({ type: Date })
  assignedAt?: Date;

  @ApiPropertyOptional({ type: Number })
  distanceKm?: number;

  @ApiProperty({ type: Number })
  deliveryFee: number;

  @ApiPropertyOptional({ type: Number })
  estimatedPrepTime?: number;

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

  @ApiPropertyOptional({ isArray: true, type: () => OrderDeliveryGroupItem })
  items?: OrderDeliveryGroupItem[];
}
