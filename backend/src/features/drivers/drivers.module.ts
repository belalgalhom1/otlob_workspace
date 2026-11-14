import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';

import { DriversController } from './drivers.controller';
import { DriverManagersController } from './driver-managers.controller';
import { OrderAssistDecisionController } from './order-assist-decision.controller';
import { DriversService } from './drivers.service';
import { DriverBreaksService } from './driver-breaks.service';
import { DriverShiftExecutionService } from './driver-shift-execution.service';
import { DriverAdminService } from './driver-admin.service';
import { DriversRepository } from './drivers.repository';
import { DriverAssistService } from './driver-assist.service';
import { DriverAssistMatchingService } from './driver-assist-matching.service';
import { DriverManagersService } from './driver-managers.service';

import { AuthModule } from '../auth/auth.module';
import { DriverShiftsModule } from '../driver-shifts/driver-shifts.module';

@Module({
  imports: [AuthModule, DriverShiftsModule, OrdersModule],
  controllers: [
    DriversController,
    DriverManagersController,
    OrderAssistDecisionController,
  ],
  providers: [
    DriversService,
    DriverBreaksService,
    DriverShiftExecutionService,
    DriverAdminService,
    DriversRepository,
    DriverAssistService,
    DriverAssistMatchingService,
    DriverManagersService,
  ],
  exports: [
    DriversService,
    DriverBreaksService,
    DriverShiftExecutionService,
    DriverAdminService,
    DriversRepository,
    DriverAssistService,
    DriverAssistMatchingService,
    DriverManagersService,
  ],
})
export class DriversModule {}
