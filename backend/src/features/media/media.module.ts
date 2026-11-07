import { Global, Module } from '@nestjs/common';
import { QueueModule } from '../../infrastructure/queue/queue.module';
import { MediaService } from './media.service';
import { MediaProcessor } from './media.processor';

@Global()
@Module({
  imports: [QueueModule],
  providers: [MediaService, MediaProcessor],
  exports: [MediaService],
})
export class MediaModule {}
