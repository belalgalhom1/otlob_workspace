import { Global, Module } from '@nestjs/common';
import { PlatformSettingsController } from './platform-settings.controller';
import { PlatformSettingsService } from './platform-settings.service';
import { DeliveryFeeCalculator } from './delivery-fee.calculator';

@Global()
@Module({
  controllers: [PlatformSettingsController],
  providers: [PlatformSettingsService, DeliveryFeeCalculator],
  exports: [PlatformSettingsService, DeliveryFeeCalculator],
})
export class PlatformSettingsModule {}
