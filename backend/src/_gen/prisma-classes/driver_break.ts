import { DriverBreakReason, DriverBreakStatus, DriverStatus } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DriverBreak {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  driverId: string;

  @ApiPropertyOptional({ type: String })
  shiftId?: string;

  @ApiProperty({ enum: DriverBreakReason, enumName: 'DriverBreakReason' })
  reason: DriverBreakReason = DriverBreakReason.REST;

  @ApiPropertyOptional({ type: String })
  note?: string;

  @ApiPropertyOptional({ type: Number })
  requestedMinutes?: number;

  @ApiProperty({ enum: DriverBreakStatus, enumName: 'DriverBreakStatus' })
  status: DriverBreakStatus = DriverBreakStatus.PENDING;

  @ApiPropertyOptional({ enum: DriverStatus, enumName: 'DriverStatus' })
  prevStatus?: DriverStatus;

  @ApiProperty({ type: Date })
  startedAt: Date;

  @ApiPropertyOptional({ type: Date })
  endedAt?: Date;

  @ApiPropertyOptional({ type: Number })
  durationMinutes?: number;

  @ApiProperty({ type: Boolean })
  autoEnded: boolean;

  @ApiPropertyOptional({ type: String })
  reviewedById?: string;

  @ApiPropertyOptional({ type: Date })
  reviewedAt?: Date;

  @ApiProperty({ type: Date })
  createdAt: Date;
}
