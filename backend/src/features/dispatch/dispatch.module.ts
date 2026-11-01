import { Module, forwardRef } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { QUEUES } from '../../infrastructure/queue/queues.constants';

import { DispatchService } from './dispatch.service';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [
    PlatformSettingsModule,
    forwardRef(() => OrdersModule),
    BullModule.registerQueue({ name: QUEUES.ORDERS }),
  ],
  providers: [DispatchService],
  exports: [DispatchService],
})
export class DispatchModule {}
