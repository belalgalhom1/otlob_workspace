import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsUUID,
  IsArray,
  IsOptional,
  IsBoolean,
  IsInt,
  IsPositive,
  IsString,
  MaxLength,
} from 'class-validator';

export class AssignDriversToManagerDto {
  @ApiProperty({
    example: 'a0000000-0000-0000-0000-000000000001',
    description: 'User ID of the driver manager',
  })
  @IsUUID()
  driverManagerUserId!: string;

  @ApiProperty({
    example: ['b0000000-0000-0000-0000-000000000002'],
    description: 'List of driver IDs to assign to this manager',
    required: false,
    type: [String],
  })
  @IsArray()
  @IsUUID('all', { each: true })
  @IsOptional()
  driverIds?: string[];

  @ApiProperty({
    example: false,
    description: 'Whether this manager should manage all drivers in the system',
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  manageAllDrivers?: boolean;
}

export class UnassignDriversFromManagerDto {
  @ApiProperty({
    example: ['b0000000-0000-0000-0000-000000000002'],
    description: 'List of driver IDs to unassign from this manager',
    type: [String],
  })
  @IsArray()
  @IsUUID('all', { each: true })
  driverIds!: string[];
}

export class ProcessDriverManagerPayoutDto {
  @ApiPropertyOptional({
    example: 500,
    description:
      'Amount in EGP to deduct and transfer to the driver manager. Omit when settleFullBalance is true to zero out the full positive balance.',
  })
  @IsInt()
  @IsPositive()
  @IsOptional()
  amount?: number;

  @ApiPropertyOptional({
    example: true,
    description:
      'When true, transfers the full current positive walletBalance and resets it to 0.',
  })
  @IsBoolean()
  @IsOptional()
  settleFullBalance?: boolean;

  @ApiPropertyOptional({
    example: '/media/receipts/abc.webp',
    description: 'Uploaded transfer screenshot URL',
  })
  @IsString()
  @MaxLength(1000)
  @IsOptional()
  receiptUrl?: string;

  @ApiPropertyOptional({
    example: 'Transferred via InstaPay - Ref #8821',
    description: 'Optional payout description or transfer reference note',
  })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({
    example: 'dm-payout-2026-11-28-01',
    description: 'Optional idempotency key to prevent duplicate payouts',
  })
  @IsString()
  @MaxLength(120)
  @IsOptional()
  idempotencyKey?: string;
}
