import { ApiProperty } from '@nestjs/swagger';

export class OrderDeliveryGroupItem {
  @ApiProperty({ type: String })
  id: string;

  @ApiProperty({ type: String })
  deliveryGroupId: string;

  @ApiProperty({ type: String })
  fulfillmentId: string;

  @ApiProperty({ type: Number })
  sequence: number;
}
