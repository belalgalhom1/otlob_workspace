import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import { OrderStatus, OrderType, VehicleType } from '@prisma/client';
import { OrderResponseDto } from '../../../common/dto/response-models.dto';
import {
  DriverSearchPhase,
  SearchTerminalReason,
} from '../../dispatch/dispatch-search.types';

export { DriverSearchPhase, SearchTerminalReason };

export class GeoPointDto {
  @ApiProperty({ example: 30.0444 })
  latitude!: number;

  @ApiProperty({ example: 31.2357 })
  longitude!: number;
}

export class NearbyDriverPreviewDto {
  @ApiProperty({ example: 30.0451 })
  latitude!: number;

  @ApiProperty({ example: 31.2362 })
  longitude!: number;

  @ApiProperty({ enum: VehicleType, enumName: 'VehicleType' })
  vehicleType!: VehicleType;

  @ApiProperty({ example: 0.84 })
  distanceKm!: number;
}

export class NearbyDriversResponseDto {
  @ApiProperty({ example: 5 })
  radiusKm!: number;

  @ApiProperty({ example: 3 })
  count!: number;

  @ApiProperty({ type: () => NearbyDriverPreviewDto, isArray: true })
  drivers!: NearbyDriverPreviewDto[];

  @ApiProperty({ example: '2026-11-21T02:00:00.000Z' })
  fetchedAt!: string;
}

export class QueryNearbyDriversDto {
  @ApiProperty({ example: 30.0444 })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @ApiProperty({ example: 31.2357 })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  @ApiPropertyOptional({ enum: VehicleType, enumName: 'VehicleType' })
  @IsEnum(VehicleType)
  @IsOptional()
  vehicleType?: VehicleType;

  @ApiPropertyOptional({
    enum: [OrderType.CUSTOM_DELIVERY, OrderType.RIDE],
    enumName: 'CustomOrderPreviewType',
  })
  @IsEnum(OrderType)
  @IsOptional()
  type?: OrderType;
}

export class OrderSearchStatusDto {
  @ApiProperty()
  orderId!: string;

  @ApiProperty()
  orderNumber!: string;

  @ApiProperty({ enum: OrderType, enumName: 'OrderType' })
  orderType!: OrderType;

  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' })
  orderStatus!: OrderStatus;

  @ApiProperty({ example: 1 })
  revision!: number;

  @ApiProperty({ enum: DriverSearchPhase, enumName: 'DriverSearchPhase' })
  phase!: DriverSearchPhase;

  @ApiProperty({ example: 1 })
  attempt!: number;

  @ApiProperty({ example: 5 })
  maxAttempts!: number;

  @ApiProperty({ example: 3 })
  radiusKm!: number;

  @ApiProperty({ example: 15 })
  maxRadiusKm!: number;

  @ApiProperty({ example: 2 })
  contactedCount!: number;

  @ApiProperty({ example: 4 })
  totalContactedCount!: number;

  @ApiProperty({ example: 1 })
  rejectedCount!: number;

  @ApiProperty({ example: 2 })
  nearbyAvailableCount!: number;

  @ApiProperty({ type: () => NearbyDriverPreviewDto, isArray: true })
  nearbyDrivers!: NearbyDriverPreviewDto[];

  @ApiPropertyOptional({ nullable: true, type: String })
  waveExpiresAt?: string | null;

  @ApiProperty({ example: 30 })
  searchTimeoutSecs!: number;

  @ApiProperty({ example: '2026-11-21T02:00:00.000Z' })
  searchStartedAt!: string;

  @ApiProperty({ example: '2026-11-21T02:00:10.000Z' })
  updatedAt!: string;

  @ApiProperty({ enum: SearchTerminalReason, enumName: 'SearchTerminalReason' })
  terminalReason!: SearchTerminalReason;

  @ApiProperty({ example: false })
  canRetry!: boolean;

  @ApiPropertyOptional({ nullable: true, type: () => GeoPointDto })
  driverLocation?: GeoPointDto | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  driverDistanceKm?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  driverEtaMinutes?: number | null;
}

export class RetrySearchResponseDto {
  @ApiProperty({ type: () => OrderResponseDto })
  order!: OrderResponseDto;

  @ApiProperty({ example: true })
  retried!: boolean;

  @ApiProperty({ example: false })
  alreadySearching!: boolean;

  @ApiProperty({ example: false })
  alreadyAssigned!: boolean;

  @ApiProperty({ type: () => OrderSearchStatusDto })
  searchStatus!: OrderSearchStatusDto;
}
