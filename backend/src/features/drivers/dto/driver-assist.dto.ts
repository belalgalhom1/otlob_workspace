import {
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { DriverAssistReason } from '@prisma/client';

export class RequestAssistDriverDto {
  @ApiProperty({
    enum: DriverAssistReason,
    example: DriverAssistReason.TOO_HEAVY,
    description: 'Why this delivery needs a second pair of hands',
  })
  @IsEnum(DriverAssistReason)
  reason: DriverAssistReason;

  @ApiProperty({
    example: 'Three heavy crates, cannot be carried safely alone',
    required: false,
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class DecideAssistRequestDto {
  @ApiProperty({
    enum: ['APPROVED', 'REJECTED'],
    example: 'APPROVED',
    description: 'Support decision on the assistance request',
  })
  @IsIn(['APPROVED', 'REJECTED'])
  status: 'APPROVED' | 'REJECTED';
}

export class AssignAssistDriverDto {
  @ApiProperty({
    example: 'c0ffee00-0000-4000-8000-000000000000',
    description:
      'Driver to assign as the assisting driver. The primary driver is kept.',
  })
  @IsUUID()
  driverId: string;
}