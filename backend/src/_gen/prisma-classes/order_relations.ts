import { Role } from '@prisma/client';
import { OrderVendorFulfillment } from './order_vendor_fulfillment';
import { OrderDeliveryGroup } from './order_delivery_group';
import { OrderReview } from './order_review';
import { DriverWalletTransaction } from './driver_wallet_transaction';
import { OrderDispatch } from './order_dispatch';
import { OrderItem } from './order_item';
import { OrderStatusEvent } from './order_status_event';
import { Customer } from './customer';
import { Driver } from './driver';
import { Vendor } from './vendor';
import { VendorBranch } from './vendor_branch';
import { Zone } from './zone';
import { SupportTicket } from './support_ticket';
import { VendorWalletTransaction } from './vendor_wallet_transaction';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderCancelledByDto {
  @ApiPropertyOptional({ type: String })
  userId?: string | null;

  @ApiProperty({ type: String })
  name!: string;

  @ApiPropertyOptional({ type: String })
  nameAr?: string | null;

  @ApiPropertyOptional({ enum: Role, enumName: 'Role' })
  role?: Role | null;

  @ApiPropertyOptional({ type: String })
  avatar?: string | null;

  @ApiPropertyOptional({ type: String })
  vendorId?: string | null;

  @ApiPropertyOptional({ type: String })
  reason?: string | null;

  @ApiPropertyOptional({ type: Date })
  cancelledAt?: Date | null;

  @ApiProperty({ type: Boolean })
  isSystem!: boolean;
}

export class OrderRelations {
  @ApiProperty({ isArray: true, type: () => DriverWalletTransaction })
  driverTransactions: DriverWalletTransaction[];

  @ApiProperty({ isArray: true, type: () => OrderDispatch })
  dispatches: OrderDispatch[];

  @ApiProperty({ isArray: true, type: () => OrderItem })
  items: OrderItem[];

  @ApiProperty({ isArray: true, type: () => OrderStatusEvent })
  statusEvents: OrderStatusEvent[];

  @ApiProperty({ type: () => Customer })
  customer: Customer;

  @ApiPropertyOptional({ type: () => Driver })
  driver?: Driver;

  @ApiPropertyOptional({ type: () => Vendor })
  vendor?: Vendor;

  @ApiPropertyOptional({ type: () => VendorBranch })
  vendorBranch?: VendorBranch;

  @ApiPropertyOptional({ type: () => Zone })
  zone?: Zone;

  @ApiProperty({ isArray: true, type: () => SupportTicket })
  supportTickets: SupportTicket[];

  @ApiProperty({ isArray: true, type: () => VendorWalletTransaction })
  vendorTransactions: VendorWalletTransaction[];

  @ApiPropertyOptional({ isArray: true, type: () => OrderReview })
  reviews?: OrderReview[];

  @ApiPropertyOptional({ isArray: true, type: () => OrderVendorFulfillment })
  vendorFulfillments?: OrderVendorFulfillment[];

  @ApiPropertyOptional({ isArray: true, type: () => OrderDeliveryGroup })
  deliveryGroups?: OrderDeliveryGroup[];

  @ApiPropertyOptional({ type: Object })
  fulfillmentSummary?: {
    totalStops: number;
    completedStops: number;
    currentStopSequence: number;
    currentStopBranchName: string | null;
    isFullyCollected: boolean;
  };

  @ApiPropertyOptional({ type: () => OrderCancelledByDto })
  cancelledBy?: OrderCancelledByDto | null;
}