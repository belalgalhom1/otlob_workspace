import { Vendor } from './vendor';
import { Product } from './product';
import { ProductVariant } from './product_variant';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OfferRelations {
  @ApiProperty({ type: () => Vendor })
  vendor: Vendor;

  @ApiProperty({ type: () => Product })
  product: Product;

  @ApiPropertyOptional({ type: () => ProductVariant })
  variant?: ProductVariant;
}
