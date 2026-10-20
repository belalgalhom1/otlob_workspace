import { ApiProperty } from '@nestjs/swagger';

export class ProductBranchAvailability {
  @ApiProperty({ type: String })
  productId: string;

  @ApiProperty({ type: String })
  branchId: string;

  @ApiProperty({ type: Date })
  createdAt: Date;
}
