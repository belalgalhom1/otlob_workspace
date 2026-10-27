import { Module } from '@nestjs/common';

import { TicketsController } from './tickets.controller';
import { TicketsService } from './tickets.service';

import { ChatModule } from '../chat/chat.module';
import { DriversModule } from '../drivers/drivers.module';

@Module({
  imports: [ChatModule, DriversModule],
  controllers: [TicketsController],
  providers: [TicketsService],
  exports: [TicketsService],
})
export class TicketsModule {}
