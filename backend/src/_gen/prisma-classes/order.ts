import {
  OrderType,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  Role,
  VehicleType,
} from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class Order {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  orderNumber: string;

  @ApiPropertyOptional({ type: String })
  clientOrderKey?: string;

  @ApiProperty({ enum: OrderType, enumName: 'OrderType' })
  type: OrderType = OrderType.STANDARD;

  @ApiProperty({ type: String })
  customerId: string;

  @ApiPropertyOptional({ type: String })
  vendorId?: string;

  @ApiPropertyOptional({ type: String })
  vendorBranchId?: string;

  @ApiPropertyOptional({ type: String })
  driverId?: string;

  @ApiPropertyOptional({ type: String })
  zoneId?: string;

  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' })
  status: OrderStatus = OrderStatus.PENDING;

  @ApiProperty({ type: Number })
  revision: number = 0;

  @ApiProperty({ enum: PaymentMethod, enumName: 'PaymentMethod' })
  paymentMethod: PaymentMethod;

  @ApiProperty({ enum: PaymentStatus, enumName: 'PaymentStatus' })
  paymentStatus: PaymentStatus = PaymentStatus.PENDING;

  @ApiProperty({ type: String })
  deliveryAddress: string;

  @ApiPropertyOptional({ type: String })
  pickupAddress?: string;

  @ApiPropertyOptional({ type: String })
  itemDetails?: string;

  @ApiPropertyOptional({ enum: VehicleType, enumName: 'VehicleType' })
  requestedVehicleType?: VehicleType;

  @ApiProperty({ type: Number })
  subtotal: number;

  @ApiProperty({ type: Number })
  deliveryFee: number;

  @ApiProperty({ type: Number })
  goldSurchargeAmount: number = 0;

  @ApiProperty({ type: Number })
  driverBonusFee: number;

  @ApiProperty({ type: Number })
  serviceFee: number;

  @ApiProperty({ type: Number })
  tax: number;

  @ApiProperty({ type: Number })
  discount: number;

  @ApiProperty({ type: Number })
  coinsUsed: number;

  @ApiProperty({ type: Number })
  coinsEarned: number;

  @ApiProperty({ type: Number })
  grandTotal: number;

  @ApiProperty({ type: Number })
  upfrontAmount: number;

  @ApiPropertyOptional({ type: String })
  specialRequest?: string;

  @ApiPropertyOptional({ type: Number })
  distanceKm?: number;

  @ApiPropertyOptional({ type: Date })
  deletedAt?: Date;

  @ApiProperty({ type: Date })
  createdAt: Date;

  @ApiProperty({ type: Date })
  updatedAt: Date;

  @ApiPropertyOptional({ type: String })
  paymentReceiptUrl?: string;

  @ApiPropertyOptional({ type: Date })
  actualDeliveryTime?: Date;

  @ApiPropertyOptional({ type: Date })
  settledAt?: Date;

  @ApiProperty({ type: Number })
  settledGoldBonusAmount: number = 0;

  @ApiProperty({ type: Number })
  settledGoldPlatformRetainedAmount: number = 0;

  @ApiProperty({ type: Number })
  settledBronzeDriverDeduction: number = 0;

  @ApiProperty({ type: Number })
  settledBronzeSupervisorDeduction: number = 0;

  @ApiPropertyOptional({ type: Number })
  settledBronzeDriverDeductionRate?: number;

  @ApiPropertyOptional({ type: Number })
  settledBronzeSupervisorDeductionRate?: number;

  @ApiPropertyOptional({ type: String })
  cancelledByUserId?: string;

  @ApiPropertyOptional({ enum: Role, enumName: 'Role' })
  cancelledByRole?: Role;

  @ApiPropertyOptional({ type: String })
  cancelledByName?: string;

  @ApiPropertyOptional({ type: String })
  cancelledByNameAr?: string;

  @ApiPropertyOptional({ type: String })
  cancelledByAvatar?: string;

  @ApiPropertyOptional({ type: String })
  cancelReason?: string;

  @ApiPropertyOptional({ type: Date })
  cancelledAt?: Date;
}
