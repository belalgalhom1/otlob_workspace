import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { WalletService } from './wallet.service';
import { DriversModule } from '../drivers/drivers.module';

@Module({
  imports: [DriversModule],
  controllers: [WalletController],
  providers: [WalletService],
})
export class WalletModule {}
