import { Global, Module } from '@nestjs/common';
import { QueueModule } from '../../infrastructure/queue/queue.module';
import { MediaService } from './media.service';

@Global()
@Module({
  imports: [QueueModule],
  providers: [MediaService],
  exports: [MediaService],
})
export class MediaModule {}
