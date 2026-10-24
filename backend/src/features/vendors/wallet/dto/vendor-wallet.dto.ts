import {
  IsOptional,
  IsEnum,
  IsInt,
  Min,
  Max,
  IsDateString,
  IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';
import { VendorTransactionType } from '@prisma/client';
import { ApiProperty } from '@nestjs/swagger';

export class QueryVendorWalletDto {
  @ApiProperty({ enum: VendorTransactionType, required: false })
  @IsEnum(VendorTransactionType)
  @IsOptional()
  type?: VendorTransactionType;

  @ApiProperty({ example: 'uuid', required: false, description: 'Filter transactions by vendor branch ID' })
  @IsUUID()
  @IsOptional()
  branchId?: string;

  @ApiProperty({ example: '2023-01-01', required: false })
  @IsDateString()
  @IsOptional()
  from?: string;

  @ApiProperty({ example: '2023-12-31', required: false })
  @IsDateString()
  @IsOptional()
  to?: string;

  @ApiProperty({ example: 1, required: false, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiProperty({ example: 20, required: false, default: 20, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
