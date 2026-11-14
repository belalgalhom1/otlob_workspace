import { Global, Module } from '@nestjs/common';

import { StatisticsController } from './statistics.controller';
import { StatisticsService } from './statistics.service';
import { StatisticsRepository } from './statistics.repository';
import { StatisticsAnalyticsRepository } from './statistics-analytics.repository';

@Global()
@Module({
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
