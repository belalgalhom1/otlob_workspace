import { Global, Module } from '@nestjs/common';
import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { DriverGeoSearchService } from './driver-geo-search.service';
import { DriverTrackingService } from './driver-tracking.service';
import { LocationRepository } from './location.repository';

/**
 * Shared geospatial & live driver tracking feature module.
 * Deliberately controller-free and queue-free so API, Worker, and WebSocket
 * processes can all import it without pulling in HTTP routes or BullMQ workers.
 */
@Global()
@Module({
  imports: [PlatformSettingsModule],
  providers: [
    LocationRepository,
    DriverTrackingService,
    DriverGeoSearchService,
  ],
  exports: [
    LocationRepository,
    DriverTrackingService,
    DriverGeoSearchService,
  ],
})
export class LocationModule {}
