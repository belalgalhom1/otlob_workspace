import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsNumber,
  IsOptional,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class RouteCoordinateDto {
  @ApiProperty({ example: 30.0444, description: 'Latitude in decimal degrees' })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({
    example: 31.2357,
    description: 'Longitude in decimal degrees',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;
}

export class ComputeRouteDto {
  @ApiProperty({
    type: [RouteCoordinateDto],
    description:
      'Ordered driving waypoints (origin, optional stops, destination).',
    minItems: 2,
    maxItems: 12,
  })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(12)
  @ValidateNested({ each: true })
  @Type(() => RouteCoordinateDto)
  waypoints!: RouteCoordinateDto[];
}

export class QueryOrderRouteDto {
  @ApiPropertyOptional({
    description:
      'Include the live assigned driver location as the route origin when available (default: true).',
    default: true,
    type: Boolean,
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return undefined;
    if (typeof value === 'boolean') return value;
    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      if (normalized === 'false' || normalized === '0') return false;
      if (normalized === 'true' || normalized === '1') return true;
    }
    return Boolean(value);
  })
  @IsBoolean()
  includeDriver?: boolean;
}

export class OrderRouteResponseDto {
  @ApiPropertyOptional({
    example: '11111111-1111-4111-8111-111111111111',
    nullable: true,
  })
  orderId?: string | null;

  @ApiPropertyOptional({ example: 'PENDING', nullable: true })
  orderStatus?: string | null;

  @ApiProperty({
    example: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    description: 'Google Encoded Polyline string (precision 5).',
  })
  encodedPolyline!: string;

  @ApiProperty({
    type: [RouteCoordinateDto],
    description: 'Decoded road-following coordinates in traversal order.',
  })
  coordinates!: RouteCoordinateDto[];

  @ApiProperty({
    type: [RouteCoordinateDto],
    description: 'Ordered waypoints used to compute the route.',
  })
  waypoints!: RouteCoordinateDto[];

  @ApiProperty({
    example: 3420,
    description: 'Total route distance in meters.',
  })
  distanceMeters!: number;

  @ApiProperty({
    example: 540,
    description: 'Estimated driving duration in seconds (0 when fallback).',
  })
  durationSeconds!: number;

  @ApiProperty({
    example: true,
    description:
      'True when geometry follows real driving roads; false only when fallback straight chord is returned.',
  })
  isRoadRoute!: boolean;

  @ApiProperty({
    example: 'osrm',
    enum: ['osrm', 'fallback'],
  })
  source!: string;

  @ApiPropertyOptional({
    type: RouteCoordinateDto,
    nullable: true,
    description:
      'Live assigned driver location included as route origin when available.',
  })
  driverLocation?: RouteCoordinateDto | null;

  @ApiPropertyOptional({
    type: RouteCoordinateDto,
    nullable: true,
    description: 'Resolved route destination point.',
  })
  destination?: RouteCoordinateDto | null;
}
