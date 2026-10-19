import { Module, forwardRef } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';

import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';
import { DriversRepository } from './drivers.repository';
import { DriverAssistService } from './driver-assist.service';

import { AuthModule } from '../auth/auth.module';
import { SocketModule } from '../../infrastructure/socket/socket.module';
import { DriverShiftsModule } from '../driver-shifts/driver-shifts.module';

@Module({
  imports: [AuthModule, SocketModule, DriverShiftsModule, forwardRef(() => OrdersModule)],
  controllers: [DriversController],
  providers: [DriversService, DriversRepository, DriverAssistService],
  exports: [DriversService, DriversRepository, DriverAssistService],
})
export class DriversModule {}
