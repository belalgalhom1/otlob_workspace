import {
  ArrayMinSize,
  ArrayNotEmpty,
  ArrayUnique,
  IsArray,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PaymentMethod } from '@prisma/client';

export class PlaceMultiVendorOrderDto {
  @ApiProperty({
    type: [String],
    example: [
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222',
    ],
    description:
      'Vendors being checked out together. Requires 2 or more — use the single-vendor endpoint for one.',
  })
  @IsArray()
  @ArrayNotEmpty()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  vendorIds: string[];

  @ApiProperty({ enum: PaymentMethod, example: PaymentMethod.CASH_ON_DELIVERY })
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiProperty({ example: '15 El Gomhoria St, Nasr City, Cairo' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  deliveryAddress: string;

  @ApiProperty({
    example: [31.3300, 30.0444],
    description: '[longitude, latitude]',
  })
  @IsArray()
  @ArrayMinSize(2)
  deliveryLocation: [number, number];

  @ApiProperty({ example: 'Please ring the bell twice', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  specialRequest?: string;

  @ApiProperty({ example: 5, required: false })
  @IsOptional()
  @IsInt()
  @Min(1)
  coinsToUse?: number;
}