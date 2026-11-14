import { Module } from '@nestjs/common';
import { DispatchService } from './dispatch.service';
import { DispatchRepository } from './dispatch.repository';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { OrderSharedModule } from '../../common/orders/order-shared.module';
import { DISPATCH_PORT } from '../../common/orders/order-dispatch.ports';

@Module({
  imports: [PlatformSettingsModule, OrderSharedModule],
  providers: [
    DispatchService,
    DispatchRepository,
    {
      provide: DISPATCH_PORT,
      useExisting: DispatchService,
    },
  ],
  exports: [DispatchService, DispatchRepository, DISPATCH_PORT],
})
export class DispatchModule {}
