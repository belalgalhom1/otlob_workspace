import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsBoolean,
  IsArray,
  ArrayMinSize,
  ArrayMaxSize,
  IsNumber,
  IsUUID,
  MaxLength,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateVendorBranchDto {
  @ApiProperty({ example: 'Maadi Branch' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  @ApiProperty({ example: 'فرع المعادي', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  nameAr?: string;

  @ApiProperty({ example: '9th Street, Maadi, Cairo' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  address!: string;

  @ApiProperty({ example: '+201234567890', required: false })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: [29.9602, 31.2569], minItems: 2, maxItems: 2 })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(2)
  @IsNumber({}, { each: true })
  @IsNotEmpty()
  location!: [number, number];

  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsUUID()
  @IsOptional()
  zoneId?: string;

  @ApiProperty({ example: true, required: false, default: true })
  @IsBoolean()
  @IsOptional()
  isOpen?: boolean;

  @ApiProperty({
    example: true,
    required: false,
    description:
      'Contracted status override for this branch. If null/undefined, falls back to vendor.isContracted.',
  })
  @IsBoolean()
  @IsOptional()
  isContracted?: boolean;

  @ApiProperty({
    example: 10,
    required: false,
    description:
      'Commission rate override for this branch in percent (e.g. 10 for 10%). If null/undefined, falls back to vendor.commissionRate.',
  })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  commissionRate?: number;
}

export class UpdateVendorBranchDto {
  @ApiProperty({ example: 'Updated Branch Name', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  name?: string;

  @ApiProperty({ example: 'اسم الفرع المحدث', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  nameAr?: string;

  @ApiProperty({ example: 'Updated Address', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  address?: string;

  @ApiProperty({ example: '+201234567890', required: false })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({
    example: [29.9602, 31.2569],
    minItems: 2,
    maxItems: 2,
    required: false,
  })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(2)
  @IsNumber({}, { each: true })
  @IsOptional()
  location?: [number, number];

  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsUUID()
  @IsOptional()
  zoneId?: string;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  isOpen?: boolean;

  @ApiProperty({
    example: true,
    required: false,
    description:
      'Contracted status override for this branch. If null/undefined, falls back to vendor.isContracted.',
  })
  @IsBoolean()
  @IsOptional()
  isContracted?: boolean;

  @ApiProperty({
    example: 10,
    required: false,
    description:
      'Commission rate override for this branch in percent (e.g. 10 for 10%). If null/undefined, falls back to vendor.commissionRate.',
  })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  commissionRate?: number;
}
