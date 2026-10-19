import { Global, Module } from '@nestjs/common';
import { LocationRepository } from './location.repository';
import { PlatformSettingsModule } from '../../features/platform-settings/platform-settings.module';

@Global()
@Module({
  imports: [PlatformSettingsModule],
  providers: [LocationRepository],
  exports: [LocationRepository],
})
export class LocationModule {}
