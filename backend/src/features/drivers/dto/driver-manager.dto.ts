import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsArray, IsOptional, IsBoolean } from 'class-validator';

export class AssignDriversToManagerDto {
  @ApiProperty({
    example: 'a0000000-0000-0000-0000-000000000001',
    description: 'User ID of the driver manager',
  })
  @IsUUID()
  driverManagerUserId!: string;

  @ApiProperty({
    example: ['b0000000-0000-0000-0000-000000000002'],
    description: 'List of driver IDs to assign to this manager',
    required: false,
    type: [String],
  })
  @IsArray()
  @IsUUID('all', { each: true })
  @IsOptional()
  driverIds?: string[];

  @ApiProperty({
    example: false,
    description: 'Whether this manager should manage all drivers in the system',
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  manageAllDrivers?: boolean;
}

export class UnassignDriversFromManagerDto {
  @ApiProperty({
    example: ['b0000000-0000-0000-0000-000000000002'],
    description: 'List of driver IDs to unassign from this manager',
    type: [String],
  })
  @IsArray()
  @IsUUID('all', { each: true })
  driverIds!: string[];
}
