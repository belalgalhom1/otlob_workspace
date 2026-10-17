import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Machine-readable rejection reasons. Kept as a stable enum so analytics and
 * the customer UI can localise them without parsing free text.
 */
export enum VendorRejectionCode {
  OUT_OF_STOCK = 'OUT_OF_STOCK',
  OUT_OF_DELIVERY_RANGE = 'OUT_OF_DELIVERY_RANGE',
  TOO_BUSY = 'TOO_BUSY',
  ITEM_UNAVAILABLE = 'ITEM_UNAVAILABLE',
  ADDRESS_UNREACHABLE = 'ADDRESS_UNREACHABLE',
  ORDER_TOO_LARGE = 'ORDER_TOO_LARGE',
  OTHER = 'OTHER',
}

export class RejectVendorFulfillmentDto {
  @ApiProperty({
    enum: VendorRejectionCode,
    example: VendorRejectionCode.OUT_OF_STOCK,
    description: 'Stable reason code for the rejection',
  })
  @IsEnum(VendorRejectionCode)
  code: VendorRejectionCode;

  @ApiProperty({
    example: 'We ran out of the main ingredient for this dish.',
    maxLength: 500,
    description: 'Human-readable reason shown to the customer',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  reason: string;

  @ApiProperty({
    example: 'نفدت الكمية الأساسية من هذا الطبق.',
    required: false,
    maxLength: 500,
    description: 'Arabic reason, shown to Arabic-speaking customers',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reasonAr?: string;
}