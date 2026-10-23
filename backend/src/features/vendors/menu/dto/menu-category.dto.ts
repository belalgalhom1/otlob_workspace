import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsBoolean,
  IsInt,
  Min,
  MaxLength,
  IsEnum,
  IsArray,
  ArrayUnique,
  IsUUID,
} from 'class-validator';
import { ProductBranchAvailabilityMode } from '@prisma/client';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateMenuCategoryDto {
  @ApiProperty({ example: 'Main Dishes' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  @ApiProperty({ example: 'الأطباق الرئيسية', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  nameAr?: string;

  @ApiProperty({ example: 'Delicious main courses', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ example: 'أطباق رئيسية لذيذة', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  descriptionAr?: string;

  @ApiProperty({ example: 1, required: false, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  sortOrder?: number;

  @ApiProperty({ example: true, required: false, default: true })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiProperty({ example: 'https://example.com/icon.png', required: false })
  @IsString()
  @IsOptional()
  iconUrl?: string;

  @ApiProperty({
    enum: ProductBranchAvailabilityMode,
    default: ProductBranchAvailabilityMode.ALL,
    required: false,
    description:
      'ALL includes every current and future branch. SPECIFIC uses branchIds.',
  })
  @IsEnum(ProductBranchAvailabilityMode)
  @IsOptional()
  branchAvailabilityMode?: ProductBranchAvailabilityMode;

  @ApiProperty({
    type: [String],
    required: false,
    description:
      'Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch.',
  })
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  @IsOptional()
  branchIds?: string[];
}

export class UpdateMenuCategoryDto {
  @ApiProperty({ example: 'Updated Category Name', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  name?: string;

  @ApiProperty({ example: 'اسم الفئة المحدث', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  nameAr?: string;

  @ApiProperty({ example: 'Updated description', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ example: 'وصف محدث', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  descriptionAr?: string;

  @ApiProperty({ example: 5, required: false })
  @IsInt()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  sortOrder?: number;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiProperty({ example: 'https://example.com/icon.png', required: false })
  @IsString()
  @IsOptional()
  iconUrl?: string;

  @ApiProperty({
    enum: ProductBranchAvailabilityMode,
    required: false,
    description:
      'ALL includes every current and future branch. SPECIFIC uses branchIds.',
  })
  @IsEnum(ProductBranchAvailabilityMode)
  @IsOptional()
  branchAvailabilityMode?: ProductBranchAvailabilityMode;

  @ApiProperty({
    type: [String],
    required: false,
    description:
      'Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch.',
  })
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  @IsOptional()
  branchIds?: string[];
}

export class ReorderCategoriesDto {
  @ApiProperty({
    example: [
      { id: 'uuid-1', sortOrder: 0 },
      { id: 'uuid-2', sortOrder: 1 },
    ],
  })
  @IsNotEmpty()
  items!: { id: string; sortOrder: number }[];
}
