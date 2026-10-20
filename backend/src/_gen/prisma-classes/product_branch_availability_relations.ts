import { Product } from './product';
import { VendorBranch } from './vendor_branch';
import { ApiProperty } from '@nestjs/swagger';

export class ProductBranchAvailabilityRelations {
  @ApiProperty({ type: () => Product })
  product: Product;

  @ApiProperty({ type: () => VendorBranch })
  branch: VendorBranch;
}
