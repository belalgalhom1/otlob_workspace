import { Module } from '@nestjs/common';
import { DispatchService } from './dispatch.service';
import { DispatchLifecycleService } from './dispatch-lifecycle.service';
import { DispatchRepository } from './dispatch.repository';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { OrderSharedModule } from '../../common/orders/order-shared.module';
import { DISPATCH_PORT } from '../../common/orders/order-dispatch.ports';

@Module({
  imports: [PlatformSettingsModule, OrderSharedModule],
  providers: [
    DispatchRepository,
    DispatchLifecycleService,
    DispatchService,
    {
      provide: DISPATCH_PORT,
      useExisting: DispatchService,
    },
  ],
  exports: [
    DispatchService,
    DispatchLifecycleService,
    DispatchRepository,
    DISPATCH_PORT,
  ],
})
export class DispatchModule {}
