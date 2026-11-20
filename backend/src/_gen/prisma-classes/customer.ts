import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CustomerUserSummaryDto {
  @ApiProperty({ type: String })
  id!: string;

  @ApiProperty({ type: String })
  name!: string;

  @ApiPropertyOptional({ type: String })
  phone?: string | null;

  @ApiPropertyOptional({ type: String })
  avatar?: string | null;
}

export class Customer {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  userId: string;

  @ApiProperty({ type: Boolean })
  canOrder: boolean = true;

  @ApiPropertyOptional({ type: Date })
  deletedAt?: Date;

  @ApiProperty({ type: Date })
  createdAt: Date;

  @ApiProperty({ type: Date })
  updatedAt: Date;

  @ApiProperty({ type: Number })
  coinBalance: number;

  @ApiPropertyOptional({ type: () => CustomerUserSummaryDto })
  user?: CustomerUserSummaryDto | null;
}
