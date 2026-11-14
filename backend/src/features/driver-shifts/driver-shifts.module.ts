import { Module } from '@nestjs/common';
import { DriverShiftsService } from './driver-shifts.service';
import { DriverShiftsController } from './driver-shifts.controller';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';

@Module({
  imports: [PlatformSettingsModule],
  controllers: [DriverShiftsController],
  providers: [DriverShiftsService],
  exports: [DriverShiftsService],
})
export class DriverShiftsModule {}
