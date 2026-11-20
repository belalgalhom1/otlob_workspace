import { Role } from '@prisma/client';
import { Order } from './order';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderActorSummaryDto {
  @ApiPropertyOptional({ type: String })
  id?: string | null;

  @ApiProperty({ type: String })
  name!: string;

  @ApiPropertyOptional({ type: String })
  nameAr?: string | null;

  @ApiPropertyOptional({ enum: Role, enumName: 'Role' })
  role?: Role | null;

  @ApiPropertyOptional({ type: String })
  avatar?: string | null;

  @ApiPropertyOptional({ type: String })
  vendorId?: string | null;

  @ApiProperty({ type: Boolean })
  isSystem!: boolean;
}

export class OrderStatusEventRelations {
  @ApiProperty({ type: () => Order })
  order: Order;

  @ApiPropertyOptional({ type: () => OrderActorSummaryDto })
  actor?: OrderActorSummaryDto | null;
}
