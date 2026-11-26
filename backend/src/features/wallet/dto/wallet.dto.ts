import {
  IsString,
  IsEnum,
  IsBoolean,
  IsOptional,
  IsInt,
  Min,
  IsUrl,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { WalletType } from '@prisma/client';

export class CreateMobileWalletDto {
  @ApiProperty({ example: '01012345678' })
  @IsString()
  number!: string;

  @ApiProperty({ enum: WalletType })
  @IsEnum(WalletType)
  type!: WalletType;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class CreateWalletTopUpDto {
  @ApiProperty({ example: 'wallet-uuid' })
  @IsString()
  platformWalletId!: string;

  @ApiProperty({ example: 5000 })
  @IsInt()
  @Min(1)
  @Type(() => Number)
  amount!: number;

  @ApiProperty({ example: 'https://storage.com/receipt.jpg' })
  @IsUrl()
  receiptUrl!: string;
}

export class ReviewWalletTopUpDto {
  @ApiProperty({ example: 'APPROVED', enum: ['APPROVED', 'REJECTED'] })
  @IsEnum(['APPROVED', 'REJECTED'])
  status!: 'APPROVED' | 'REJECTED';

  @ApiPropertyOptional({
    example: 'Transfer receipt verified / Receipt amount mismatch',
    description: 'Optional review notes or rejection reason visible to driver',
  })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}

export class ProcessManualTransactionDto {
  @ApiProperty({ example: 5000, description: 'Positive or negative amount' })
  @IsInt()
  @Type(() => Number)
  amount!: number;

  @ApiProperty({ example: 'PAYOUT', description: 'Type of transaction' })
  @IsString()
  type!: string;

  @ApiProperty({ example: 'Bank wire transfer #123456', required: false })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({
    example: 'Bonus for weekend surge deliveries',
    required: false,
    description: 'Driver-facing note for manual wallet adjustments',
  })
  @IsString()
  @IsOptional()
  note?: string;

  @ApiProperty({ example: 'order-123', required: false })
  @IsString()
  @IsOptional()
  referenceId?: string;

  @ApiProperty({ example: 'admin-tx-uuid', required: false })
  @IsString()
  @IsOptional()
  idempotencyKey?: string;
}
