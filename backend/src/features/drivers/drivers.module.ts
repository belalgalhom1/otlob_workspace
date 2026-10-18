import { Module } from '@nestjs/common';

import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';
import { DriversRepository } from './drivers.repository';
import { DriverAssistService } from './driver-assist.service';

import { AuthModule } from '../auth/auth.module';
import { SocketModule } from '../../infrastructure/socket/socket.module';
import { DriverShiftsModule } from '../driver-shifts/driver-shifts.module';

@Module({
  imports: [AuthModule, SocketModule, DriverShiftsModule],
  controllers: [DriversController],
  providers: [DriversService, DriversRepository, DriverAssistService],
  exports: [DriversService, DriversRepository, DriverAssistService],
})
export class DriversModule {}
