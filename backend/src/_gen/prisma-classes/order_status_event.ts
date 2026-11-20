import { OrderStatus, Role } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { OrderActorSummaryDto } from './order_status_event_relations';

export class OrderStatusEvent {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  orderId: string;

  @ApiPropertyOptional({ type: String })
  fulfillmentId?: string;

  @ApiPropertyOptional({ type: String })
  deliveryGroupId?: string;

  @ApiPropertyOptional({ type: String })
  eventKey?: string;

  @ApiProperty({ enum: OrderStatus, enumName: 'OrderStatus' })
  status: OrderStatus;

  @ApiPropertyOptional({ type: String })
  note?: string;

  @ApiPropertyOptional({ type: String })
  createdBy?: string;

  @ApiPropertyOptional({ type: String })
  actorUserId?: string;

  @ApiPropertyOptional({ enum: Role, enumName: 'Role' })
  actorRole?: Role;

  @ApiPropertyOptional({ type: String })
  actorName?: string;

  @ApiPropertyOptional({ type: String })
  actorNameAr?: string;

  @ApiPropertyOptional({ type: String })
  actorAvatar?: string;

  @ApiPropertyOptional({ type: String })
  actorVendorId?: string;

  @ApiPropertyOptional({ type: () => OrderActorSummaryDto })
  actor?: OrderActorSummaryDto | null;

  @ApiProperty({ type: Date })
  createdAt: Date;
}
