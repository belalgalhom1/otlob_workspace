import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsArray,
  ArrayMinSize,
  ArrayMaxSize,
  IsNotEmpty,
  IsInt,
  Min,
  Max,
  MaxLength,
  IsIn,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { DriverStatus, DriverBreakReason, VehicleType } from '@prisma/client';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDriverDto {
  @ApiProperty({ example: 'Ahmed Hassan' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;

  @ApiProperty({ example: '28901234567890', required: false })
  @IsString()
  @IsOptional()
  nationalId?: string;

  @ApiProperty({ example: 'DL-123456', required: false })
  @IsString()
  @IsOptional()
  licenseNumber?: string;

  @ApiProperty({ enum: VehicleType, default: VehicleType.MOTORCYCLE })
  @IsEnum(VehicleType)
  @IsOptional()
  vehicleType?: VehicleType;

  @ApiProperty({ example: 'ABC-123', required: false })
  @IsString()
  @IsOptional()
  vehiclePlate?: string;
}

export class UpdateDriverProfileDto {
  @ApiProperty({ example: 'Ahmed Hassan', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  name?: string;

  @ApiProperty({ example: '28901234567890', required: false })
  @IsString()
  @IsOptional()
  nationalId?: string;

  @ApiProperty({ example: 'DL-654321', required: false })
  @IsString()
  @IsOptional()
  licenseNumber?: string;
}

export class UpdateDriverStatusDto {
  @ApiProperty({
    enum: [DriverStatus.ONLINE, DriverStatus.OFFLINE],
    description:
      'Deprecated: online status is fully shift-driven (shift start flips ONLINE, shift end flips OFFLINE). Manual flips are rejected.',
  })
  @IsIn([DriverStatus.ONLINE, DriverStatus.OFFLINE], {
    message: 'Status must be ONLINE or OFFLINE',
  })
  @IsNotEmpty()
  status!: DriverStatus;
}

export class StartBreakDto {
  @ApiProperty({ enum: DriverBreakReason, required: false })
  @IsEnum(DriverBreakReason)
  @IsOptional()
  reason?: DriverBreakReason;

  @ApiProperty({
    example: 'Need 15 minutes for prayer',
    required: false,
    description: 'Free-text note shown to the reviewing admin',
  })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  note?: string;

  @ApiProperty({
    example: 15,
    required: false,
    description:
      'Requested break length in minutes. Capped by maxSingleBreakMinutes; omit for up to the cap',
  })
  @IsInt()
  @Min(1)
  @Max(480)
  @IsOptional()
  @Type(() => Number)
  requestedMinutes?: number;
}

export class UpdateDriverLocationDto {
  @ApiProperty({
    example: [31.2357, 30.0444],
    description: '[longitude, latitude]',
  })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(2)
  @IsNumber({}, { each: true })
  location!: [number, number];
}

export class CreateDriverShiftDto {
  @ApiProperty({ example: '2026-05-10T08:00:00Z' })
  @IsString()
  @IsNotEmpty()
  startTime!: string;

  @ApiProperty({ example: '2026-05-10T20:00:00Z' })
  @IsString()
  @IsNotEmpty()
  endTime!: string;

  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsString()
  @IsOptional()
  zoneId?: string;
}

export class QueryDriversDto {
  @ApiProperty({ enum: DriverStatus, required: false })
  @IsEnum(DriverStatus)
  @IsOptional()
  status?: DriverStatus;

  @ApiProperty({ example: 'ahmed', required: false })
  @IsString()
  @IsOptional()
  search?: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', required: false })
  @IsString()
  @IsOptional()
  zoneId?: string;

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

export class QueryDriverWalletDto {
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

export class AdminCreateDriverDto {
  @ApiProperty({ example: 'driver@example.com' })
  @IsString()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: '+201000000000' })
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @ApiProperty({ example: 'Password123!' })
  @IsString()
  @IsNotEmpty()
  password!: string;

  @ApiProperty({ example: 'Ahmed Hassan' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;

  @ApiProperty({ example: '28901234567890', required: false })
  @IsString()
  @IsOptional()
  nationalId?: string;

  @ApiProperty({ example: 'DL-123456', required: false })
  @IsString()
  @IsOptional()
  licenseNumber?: string;

  @ApiProperty({ enum: VehicleType, default: VehicleType.MOTORCYCLE })
  @IsEnum(VehicleType)
  @IsOptional()
  vehicleType?: VehicleType;

  @ApiProperty({ example: 'ABC-123', required: false })
  @IsString()
  @IsOptional()
  vehiclePlate?: string;

  @ApiProperty({ enum: DriverStatus, required: false })
  @IsEnum(DriverStatus)
  @IsOptional()
  status?: DriverStatus;

  @ApiProperty({ example: 'BRONZE', required: false })
  @IsString()
  @IsOptional()
  tier?: string;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  isApproved?: boolean;
}

export class AdminUpdateDriverDto {
  @ApiProperty({ example: 'Ahmed Hassan', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  name?: string;

  @ApiProperty({ example: '28901234567890', required: false })
  @IsString()
  @IsOptional()
  nationalId?: string;

  @ApiProperty({ example: 'DL-654321', required: false })
  @IsString()
  @IsOptional()
  licenseNumber?: string;

  @ApiProperty({ enum: VehicleType, required: false })
  @IsEnum(VehicleType)
  @IsOptional()
  vehicleType?: VehicleType;

  @ApiProperty({ example: 'XYZ-789', required: false })
  @IsString()
  @IsOptional()
  vehiclePlate?: string;

  @ApiProperty({ enum: DriverStatus, required: false })
  @IsEnum(DriverStatus)
  @IsOptional()
  status?: DriverStatus;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  isApproved?: boolean;
}
