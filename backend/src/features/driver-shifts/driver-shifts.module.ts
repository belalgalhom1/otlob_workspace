import { Module } from '@nestjs/common';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { DriverShiftAttendanceService } from './driver-shift-attendance.service';
import { DriverShiftPoolsService } from './driver-shift-pools.service';
import { DriverShiftSwapWaitlistService } from './driver-shift-swap-waitlist.service';
import { DriverShiftsController } from './driver-shifts.controller';
import { DriverShiftsService } from './driver-shifts.service';

@Module({
  imports: [PlatformSettingsModule],
  controllers: [DriverShiftsController],
  providers: [
    DriverShiftPoolsService,
    DriverShiftSwapWaitlistService,
    DriverShiftAttendanceService,
    DriverShiftsService,
  ],
  exports: [
    DriverShiftPoolsService,
    DriverShiftSwapWaitlistService,
    DriverShiftAttendanceService,
    DriverShiftsService,
  ],
})
export class DriverShiftsModule {}
