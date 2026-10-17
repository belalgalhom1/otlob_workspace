import { Module } from '@nestjs/common';

import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';
import { DriversRepository } from './drivers.repository';
import { DriverAssistService } from './driver-assist.service';

import { AuthModule } from '../auth/auth.module';
import { SocketModule } from '../../infrastructure/socket/socket.module';

@Module({
  imports: [AuthModule, SocketModule],
  controllers: [DriversController],
  providers: [DriversService, DriversRepository, DriverAssistService],
  exports: [DriversService, DriversRepository, DriverAssistService],
})
export class DriversModule {}
