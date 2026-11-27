import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class VendorBranch {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  name: string;

  @ApiPropertyOptional({ type: String })
  nameAr?: string;

  @ApiProperty({ type: String })
  address: string;

  @ApiPropertyOptional({ type: String })
  phone?: string;

  @ApiProperty({ type: Boolean })
  isOpen: boolean = true;

  @ApiPropertyOptional({ type: Boolean })
  isContracted?: boolean;

  @ApiPropertyOptional({ type: Number })
  commissionRate?: number;

  @ApiPropertyOptional({ type: Object })
  workingHours?: object;

  @ApiProperty({ type: Boolean })
  isScheduleActive: boolean = true;

  @ApiProperty({ type: Boolean })
  is24Hours: boolean = false;

  @ApiProperty({ type: String })
  vendorId: string;

  @ApiProperty({ type: String })
  zoneId: string;

  @ApiProperty({ type: Date })
  createdAt: Date;

  @ApiProperty({ type: Date })
  updatedAt: Date;
}
