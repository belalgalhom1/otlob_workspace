import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import sharp from 'sharp';
import { QUEUES, MEDIA_JOBS } from '../../infrastructure/queue/queues.constants';
import {
  MEDIA_PRESETS,
  MediaPreset,
  MediaPresetName,
} from './media.constants';

export interface ProcessedImageResult {
  mainBuffer: Buffer;
  thumbBuffer: Buffer;
  width?: number;
  height?: number;
  thumbWidth?: number;
  thumbHeight?: number;
}

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);

  constructor(
    @InjectQueue(QUEUES.MEDIA) private readonly mediaQueue: Queue,
  ) {}

  detectPreset(folder: string): MediaPresetName {
    const f = (folder || '').toLowerCase();
    if (f.includes('avatar')) return 'avatar';
    if (f.includes('product')) return 'product';
    if (f.includes('banner') || f.includes('cover')) return 'banner';
    if (f.includes('categor') || f.includes('vertical')) return 'category';
    if (f.includes('chat') || f.includes('message')) return 'chat_image';
    if (f.includes('receipt') || f.includes('document') || f.includes('delivery'))
      return 'document';
    return 'default';
  }

  getPreset(name?: MediaPresetName): MediaPreset {
    if (name && MEDIA_PRESETS[name]) {
      return MEDIA_PRESETS[name];
    }
    return MEDIA_PRESETS.default;
  }

  async processImage(
    buffer: Buffer,
    presetName: MediaPresetName = 'default',
  ): Promise<ProcessedImageResult> {
    const preset = this.getPreset(presetName);

    // 1. Process Main Image: auto-orient via rotate(), resize within bounds, convert to WebP
    const mainPipeline = sharp(buffer)
      .rotate()
      .resize({
        width: preset.maxWidth,
        height: preset.maxHeight,
        fit: preset.fit,
        withoutEnlargement: true,
      })
      .webp({ quality: preset.quality, effort: 4 });

    const [mainBuffer, mainMeta] = await Promise.all([
      mainPipeline.toBuffer(),
      mainPipeline.metadata(),
    ]);

    // 2. Process Thumbnail: auto-orient, thumbnail resize, WebP
    const thumbPipeline = sharp(buffer)
      .rotate()
      .resize({
        width: preset.thumb.width,
        height: preset.thumb.height,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({ quality: preset.thumb.quality, effort: 4 });

    const [thumbBuffer, thumbMeta] = await Promise.all([
      thumbPipeline.toBuffer(),
      thumbPipeline.metadata(),
    ]);

    return {
      mainBuffer,
      thumbBuffer,
      width: mainMeta.width,
      height: mainMeta.height,
      thumbWidth: thumbMeta.width,
      thumbHeight: thumbMeta.height,
    };
  }

  async enqueueImageOptimization(
    filePath: string,
    presetName: MediaPresetName = 'default',
  ): Promise<void> {
    try {
      await this.mediaQueue.add(
        MEDIA_JOBS.OPTIMIZE_IMAGE,
        { filePath, presetName },
        { priority: 3 },
      );
    } catch (err: unknown) {
      this.logger.warn(`Failed to enqueue image optimization: ${(err as Error).message}`);
    }
  }

  async enqueueThumbnailGeneration(
    filePath: string,
    thumbPath: string,
    presetName: MediaPresetName = 'default',
  ): Promise<void> {
    try {
      await this.mediaQueue.add(
        MEDIA_JOBS.GENERATE_THUMBNAIL,
        { filePath, thumbPath, presetName },
        { priority: 2 },
      );
    } catch (err: unknown) {
      this.logger.warn(`Failed to enqueue thumbnail generation: ${(err as Error).message}`);
    }
  }
}
