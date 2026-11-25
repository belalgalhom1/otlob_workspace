import { Module } from '@nestjs/common';
import { OffersService } from './offers.service';
import { OffersController } from './offers.controller';
import { PrismaModule } from '../../infrastructure/prisma/prisma.module';
import { VendorsModule } from '../vendors/vendors.module';

@Module({
  imports: [PrismaModule, VendorsModule],
  controllers: [OffersController],
  providers: [OffersService],
  exports: [OffersService],
})
export class OffersModule {}
