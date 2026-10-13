import { Driver } from './driver';
import { DriverShift } from './driver_shift';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DriverBreakRelations {
  @ApiProperty({ type: () => Driver })
  driver: Driver;

  @ApiPropertyOptional({ type: () => DriverShift })
  shift?: DriverShift;
}
