import { Type } from 'class-transformer';
import {
  IsString,
  IsNotEmpty,
  IsArray,
  ArrayMinSize,
  ArrayMaxSize,
  IsOptional,
  IsInt,
  Min,
  Max,
  MaxLength,
  IsDateString,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GenerateShiftPoolsDto {
  @ApiProperty({ example: '2026-05-10' })
  @IsDateString()
  @IsNotEmpty()
  startDate!: string;

  @ApiProperty({ example: '2026-05-16' })
  @IsDateString()
  @IsNotEmpty()
  endDate!: string;

  @ApiProperty({ example: '08:00' })
  @IsString()
  @IsNotEmpty()
  startTime!: string;

  @ApiProperty({ example: '16:00' })
  @IsString()
  @IsNotEmpty()
  endTime!: string;

  @ApiProperty({ example: 50 })
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  maxDrivers!: number;

  @ApiProperty({ example: 'zone-uuid', required: false })
  @IsString()
  @IsOptional()
  zoneId?: string;

  @ApiProperty({ example: 'Morning Shift', required: false, maxLength: 100 })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  title?: string;

  @ApiProperty({ example: 'وردية الصباح', required: false, maxLength: 100 })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  titleAr?: string;
}

export class BookWeeklyShiftsDto {
  @ApiProperty({
    example: [
      'pool-id-1',
      'pool-id-2',
      'pool-id-3',
      'pool-id-4',
      'pool-id-5',
      'pool-id-6',
    ],
  })
  @IsArray()
  @ArrayMinSize(6)
  @ArrayMaxSize(6)
  @IsString({ each: true })
  shiftPoolIds!: string[];
}

export class BookOvertimeShiftDto {
  @ApiProperty({ example: 'pool-id' })
  @IsString()
  @IsNotEmpty()
  shiftPoolId!: string;
}

export class JoinWaitlistDto {
  @ApiProperty({ example: 'pool-id' })
  @IsString()
  @IsNotEmpty()
  shiftPoolId!: string;
}

export class QueryShiftPoolsDto {
  @ApiProperty({ example: '2026-05-10', required: false })
  @IsDateString()
  @IsOptional()
  date?: string;

  @ApiProperty({ example: '2026-05-10', required: false })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiProperty({ example: '2026-05-16', required: false })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiProperty({ example: 'zone-uuid', required: false })
  @IsString()
  @IsOptional()
  zoneId?: string;

  @ApiProperty({ example: 1, required: false })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  page?: number;

  @ApiProperty({ example: 20, required: false })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  limit?: number;
}

export class AdminAssignShiftDto {
  @ApiProperty({ example: 'pool-id' })
  @IsString()
  @IsNotEmpty()
  shiftPoolId!: string;

  @ApiProperty({ example: 'driver-id' })
  @IsString()
  @IsNotEmpty()
  driverId!: string;
}

export class AdminBulkAssignShiftsDto {
  @ApiProperty({ example: 'driver-id' })
  @IsString()
  @IsNotEmpty()
  driverId!: string;

  @ApiProperty({ example: ['pool-id-1', 'pool-id-2'], type: [String] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @IsString({ each: true })
  shiftPoolIds!: string[];
}

export class AdminBulkRemoveShiftsDto {
  @ApiProperty({ example: 'driver-id' })
  @IsString()
  @IsNotEmpty()
  driverId!: string;

  @ApiProperty({ example: ['pool-id-1', 'pool-id-2'], type: [String] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  shiftPoolIds!: string[];
}

export class AdminBookWeeklyShiftsDto {
  @ApiProperty({ example: 'driver-id' })
  @IsString()
  @IsNotEmpty()
  driverId!: string;

  @ApiProperty({
    example: [
      'pool-id-1',
      'pool-id-2',
      'pool-id-3',
      'pool-id-4',
      'pool-id-5',
      'pool-id-6',
    ],
  })
  @IsArray()
  @ArrayMinSize(6)
  @ArrayMaxSize(6)
  @IsString({ each: true })
  shiftPoolIds!: string[];
}

export class ExcuseDriverShiftDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  isExcused!: boolean;

  @ApiPropertyOptional({
    example: 'Approved medical absence',
    maxLength: 500,
  })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  excuseReason?: string;
}
