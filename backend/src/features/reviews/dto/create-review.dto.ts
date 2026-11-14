import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class FulfillmentRatingInputDto {
  @ApiProperty({ example: 'uuid-fulfillment' })
  @IsUUID()
  fulfillmentId!: string;

  @ApiProperty({ example: 5, minimum: 1, maximum: 5 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @ApiPropertyOptional({ example: 'Great food!' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

export class DeliveryGroupRatingInputDto {
  @ApiProperty({ example: 'uuid-delivery-group' })
  @IsUUID()
  deliveryGroupId!: string;

  @ApiProperty({ example: 5, minimum: 1, maximum: 5 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @ApiPropertyOptional({ example: 'Fast delivery!' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

export class CreateReviewDto {
  @ApiPropertyOptional({
    type: [FulfillmentRatingInputDto],
    description: 'Per-store/branch portion ratings for this order',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => FulfillmentRatingInputDto)
  fulfillmentRatings?: FulfillmentRatingInputDto[];

  @ApiPropertyOptional({
    type: [DeliveryGroupRatingInputDto],
    description: 'Per-driver/delivery-group ratings for this order',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DeliveryGroupRatingInputDto)
  deliveryGroupRatings?: DeliveryGroupRatingInputDto[];

  @ApiPropertyOptional({ example: 5, description: 'Rating out of 5 (single-store shorthand)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  vendorRating?: number;

  @ApiPropertyOptional({ example: 5, description: 'Rating out of 5 (single-driver shorthand)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  driverRating?: number;

  @ApiPropertyOptional({ example: 'Great food!' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;

  // Ensure at least one rating input is provided when neither arrays nor shorthand ratings are present.
  @ValidateIf(
    (o) =>
      (!o.fulfillmentRatings || o.fulfillmentRatings.length === 0) &&
      (!o.deliveryGroupRatings || o.deliveryGroupRatings.length === 0) &&
      o.vendorRating === undefined &&
      o.driverRating === undefined,
  )
  @IsInt({
    message:
      'At least one vendor portion rating or delivery driver rating must be provided',
  })
  driverRatingRequiredCheck?: number;
}
