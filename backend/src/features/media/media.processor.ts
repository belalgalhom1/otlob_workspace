import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import sharp from 'sharp';
import {
  QUEUES,
  MEDIA_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { MEDIA_PRESETS, MediaPresetName } from './media.constants';

export interface OptimizeImageJobPayload {
  filePath: string;
  presetName?: MediaPresetName;
}

export interface GenerateThumbnailJobPayload {
  filePath: string;
  thumbPath: string;
  presetName?: MediaPresetName;
}

@Processor(QUEUES.MEDIA, { concurrency: 3 })
export class MediaProcessor extends WorkerHost {
  private readonly logger = new Logger(MediaProcessor.name);

  async process(job: Job): Promise<unknown> {
    switch (job.name) {
      case MEDIA_JOBS.OPTIMIZE_IMAGE:
        return this.handleOptimizeImage(job.data as OptimizeImageJobPayload);
      case MEDIA_JOBS.GENERATE_THUMBNAIL:
        return this.handleGenerateThumbnail(
          job.data as GenerateThumbnailJobPayload,
        );
      default:
        this.logger.warn(`Unknown media job received: ${job.name}`);
        return null;
    }
  }

  private async handleOptimizeImage(
    payload: OptimizeImageJobPayload,
  ): Promise<void> {
    const { filePath, presetName = 'default' } = payload;
    if (!filePath || !fs.existsSync(filePath)) {
      this.logger.warn(`Optimization skipped: file not found at ${filePath}`);
      return;
    }

    try {
      const originalStat = await fs.promises.stat(filePath);
      const originalBytes = originalStat.size;
      const preset = MEDIA_PRESETS[presetName] || MEDIA_PRESETS.default;

      const buffer = await fs.promises.readFile(filePath);
      const optimizedBuffer = await sharp(buffer)
        .rotate()
        .resize({
          width: preset.maxWidth,
          height: preset.maxHeight,
          fit: preset.fit,
          withoutEnlargement: true,
        })
        .webp({ quality: preset.quality, effort: 5 })
        .toBuffer();

      if (optimizedBuffer.length < originalBytes) {
        await fs.promises.writeFile(filePath, optimizedBuffer);
        const savedPercent = (
          ((originalBytes - optimizedBuffer.length) / originalBytes) *
          100
        ).toFixed(1);
        this.logger.log(
          `Optimized: ${path.basename(filePath)} | ${originalBytes}B -> ${optimizedBuffer.length}B (-${savedPercent}%)`,
        );
      }
    } catch (error: unknown) {
      this.logger.error(
        `Failed to optimize image ${filePath}: ${(error as Error).message}`,
        (error as Error).stack,
      );
    }
  }

  private async handleGenerateThumbnail(
    payload: GenerateThumbnailJobPayload,
  ): Promise<void> {
    const { filePath, thumbPath, presetName = 'default' } = payload;
    if (!filePath || !fs.existsSync(filePath)) {
      this.logger.warn(
        `Thumbnail skipped: source file not found at ${filePath}`,
      );
      return;
    }

    if (fs.existsSync(thumbPath)) {
      // Thumbnail already created
      return;
    }

    try {
      const preset = MEDIA_PRESETS[presetName] || MEDIA_PRESETS.default;
      const buffer = await fs.promises.readFile(filePath);

      const thumbBuffer = await sharp(buffer)
        .rotate()
        .resize({
          width: preset.thumb.width,
          height: preset.thumb.height,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: preset.thumb.quality, effort: 4 })
        .toBuffer();

      await fs.promises.mkdir(path.dirname(thumbPath), { recursive: true });
      await fs.promises.writeFile(thumbPath, thumbBuffer);

      this.logger.log(
        `Generated thumbnail: ${path.basename(thumbPath)} (${thumbBuffer.length} bytes)`,
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to generate thumbnail for ${filePath}: ${(error as Error).message}`,
        (error as Error).stack,
      );
    }
  }
}
