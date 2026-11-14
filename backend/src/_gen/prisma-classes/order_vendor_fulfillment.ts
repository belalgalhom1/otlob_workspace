import { OrderVendorFulfillmentStatus } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Vendor } from './vendor';
import { VendorBranch } from './vendor_branch';
import { OrderItem } from './order_item';

export class OrderVendorFulfillment {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  orderId: string;

  @ApiProperty({ type: String })
  vendorId: string;

  @ApiPropertyOptional({ type: String })
  vendorBranchId?: string;

  @ApiProperty({ enum: OrderVendorFulfillmentStatus, enumName: 'OrderVendorFulfillmentStatus' })
  status: OrderVendorFulfillmentStatus = OrderVendorFulfillmentStatus.PENDING;

  @ApiPropertyOptional({ type: String })
  stage?: string;

  @ApiProperty({ type: Number })
  subtotal: number;

  @ApiProperty({ type: Number })
  commissionRate: number;

  @ApiProperty({ type: Boolean })
  isContracted: boolean = false;

  @ApiPropertyOptional({ type: Number })
  estimatedPrepTime?: number;

  @ApiPropertyOptional({ type: String })
  rejectionCode?: string;

  @ApiPropertyOptional({ type: String })
  rejectionReason?: string;

  @ApiPropertyOptional({ type: String })
  rejectionReasonAr?: string;

  @ApiPropertyOptional({ type: String })
  decidedByUserId?: string;

  @ApiPropertyOptional({ type: Date })
  decidedAt?: Date;

  @ApiPropertyOptional({ type: Date })
  preparingAt?: Date;

  @ApiPropertyOptional({ type: Date })
  readyAt?: Date;

  @ApiPropertyOptional({ type: String })
  pickupImageUrl?: string;

  @ApiPropertyOptional({ type: Date })
  pickedUpAt?: Date;

  @ApiPropertyOptional({ type: String })
  pickedUpByDriverId?: string;

  @ApiPropertyOptional({ type: Date })
  deliveredAt?: Date;

  @ApiPropertyOptional({ type: Date })
  createdAt?: Date;

  @ApiPropertyOptional({ type: Date })
  updatedAt?: Date;

  @ApiPropertyOptional({ type: () => Vendor })
  vendor?: Vendor;

  @ApiPropertyOptional({ type: () => VendorBranch })
  vendorBranch?: VendorBranch;

  @ApiPropertyOptional({ isArray: true, type: () => OrderItem })
  items?: OrderItem[];
}
