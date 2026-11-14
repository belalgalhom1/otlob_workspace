import { Global, Module } from '@nestjs/common';

import { StatisticsController } from './statistics.controller';
import { StatisticsService } from './statistics.service';
import { StatisticsRepository } from './statistics.repository';
import { StatisticsAnalyticsRepository } from './statistics-analytics.repository';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';

@Global()
@Module({
  imports: [PlatformSettingsModule],
  controllers: [StatisticsController],
  providers: [
    StatisticsService,
    StatisticsRepository,
    StatisticsAnalyticsRepository,
  ],
  exports: [
    StatisticsService,
    StatisticsRepository,
    StatisticsAnalyticsRepository,
  ],
})
export class StatisticsModule {}
