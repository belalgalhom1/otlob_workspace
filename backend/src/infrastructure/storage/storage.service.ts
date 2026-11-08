import { Injectable, Logger, BadRequestException, Optional } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';
import { MediaService } from '../../features/media/media.service';
import { MEDIA_PRESETS } from '../../features/media/media.constants';

const NON_IMAGE_MIME_TO_EXTENSION: Record<string, string> = {
  'video/mp4': '.mp4',
  'video/quicktime': '.mov',
  'video/webm': '.webm',
  'video/3gpp': '.3gp',
  'audio/mpeg': '.mp3',
  'audio/ogg': '.ogg',
  'audio/wav': '.wav',
  'audio/webm': '.webm',
  'audio/mp4': '.m4a',
  'audio/aac': '.aac',
  'audio/x-m4a': '.m4a',
  'application/pdf': '.pdf',
};

const ALLOWED_IMAGE_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/gif',
]);

// Validate file signatures (magic bytes) for image uploads to reject spoofed MIME types
function validateImageMagicBytes(buffer: Buffer, mimeType: string): boolean {
  if (!buffer || buffer.length < 12) return false;

  if (mimeType === 'image/jpeg' || mimeType === 'image/jpg') {
    return buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  }
  if (mimeType === 'image/png') {
    return (
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4e &&
      buffer[3] === 0x47 &&
      buffer[4] === 0x0d &&
      buffer[5] === 0x0a &&
      buffer[6] === 0x1a &&
      buffer[7] === 0x0a
    );
  }
  if (mimeType === 'image/gif') {
    return (
      buffer[0] === 0x47 &&
      buffer[1] === 0x49 &&
      buffer[2] === 0x46 &&
      buffer[3] === 0x38
    );
  }
  if (mimeType === 'image/webp') {
    return (
      buffer.toString('ascii', 0, 4) === 'RIFF' &&
      buffer.toString('ascii', 8, 12) === 'WEBP'
    );
  }

  return false;
}

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);

  readonly baseDir = path.join(process.cwd(), 'storage');

  constructor(
    @Optional() private readonly mediaService?: MediaService,
  ) {
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  async upload(file: Express.Multer.File, folder: string): Promise<string> {
    try {
      const targetDir = path.join(this.baseDir, folder);
      await this.ensureDir(targetDir);

      const mime = (file.mimetype || '').toLowerCase();
      const id = uuidv4();

      // Handle Image Files: Convert strictly to WebP & generate thumbnail
      if (mime.startsWith('image/')) {
        if (!ALLOWED_IMAGE_MIMES.has(mime) || !validateImageMagicBytes(file.buffer, mime)) {
          throw new BadRequestException('Invalid or unsupported image file content');
        }

        const presetName = this.mediaService
          ? this.mediaService.detectPreset(folder)
          : 'default';
        const preset =
          (this.mediaService ? this.mediaService.getPreset(presetName) : null) ||
          MEDIA_PRESETS.default;

        const mainFileName = `${id}.webp`;
        const thumbFileName = `${id}_thumb.webp`;
        const mainFilePath = path.join(targetDir, mainFileName);
        const thumbFilePath = path.join(targetDir, thumbFileName);

        // Process Main Image (auto-orient EXIF, resize, WebP encode)
        const mainBuffer = await sharp(file.buffer)
          .rotate()
          .resize({
            width: preset.maxWidth,
            height: preset.maxHeight,
            fit: preset.fit,
            withoutEnlargement: true,
          })
          .webp({ quality: preset.quality, effort: 4 })
          .toBuffer();

        // Process Thumbnail
        const thumbBuffer = await sharp(file.buffer)
          .rotate()
          .resize({
            width: preset.thumb.width,
            height: preset.thumb.height,
            fit: 'inside',
            withoutEnlargement: true,
          })
          .webp({ quality: preset.thumb.quality, effort: 4 })
          .toBuffer();

        await Promise.all([
          fs.promises.writeFile(mainFilePath, mainBuffer),
          fs.promises.writeFile(thumbFilePath, thumbBuffer),
        ]);

        // Enqueue background deep compression to BullMQ media worker without blocking API response
        if (this.mediaService) {
          void this.mediaService.enqueueImageOptimization(mainFilePath, presetName);
        }

        this.logger.log(
          `Uploaded & processed image: ${folder}/${mainFileName} (${mainBuffer.length}B, thumb: ${thumbBuffer.length}B)`,
        );

        return `/media/${folder}/${mainFileName}`;
      }

      // Handle Non-Image Files (Audio, Video, PDF Documents)
      const safeExt = NON_IMAGE_MIME_TO_EXTENSION[mime];
      if (!safeExt) {
        throw new BadRequestException('Unsupported or unsafe file type');
      }

      const fileName = `${id}${safeExt}`;
      const filePath = path.join(targetDir, fileName);

      await fs.promises.writeFile(filePath, file.buffer);
      this.logger.log(`Uploaded media file: ${folder}/${fileName} (${file.buffer.length}B)`);

      return `/media/${folder}/${fileName}`;
    } catch (error: unknown) {
      this.logger.error(
        `Upload failed: ${(error as Error).message}`,
        (error as Error).stack,
      );
      throw error;
    }
  }

  async delete(fileUrl: string): Promise<number> {
    try {
      if (!fileUrl) return 0;

      const relativePath = fileUrl.replace(/^\/media\//, '');
      const filePath = path.normalize(path.join(this.baseDir, relativePath));

      if (!filePath.startsWith(this.baseDir)) {
        this.logger.warn(`Path traversal attempt detected for: ${fileUrl}`);
        return 0;
      }

      let bytesFreed = 0;

      if (fs.existsSync(filePath)) {
        try {
          const stat = await fs.promises.stat(filePath);
          bytesFreed += stat.size;
        } catch {
          // ignore stat error
        }
        await fs.promises.unlink(filePath);
        this.logger.log(`Deleted: ${relativePath}`);
      } else {
        this.logger.warn(`File not found for deletion: ${filePath}`);
      }

      // If WebP image, clean up associated thumbnail
      if (filePath.endsWith('.webp') && !filePath.endsWith('_thumb.webp')) {
        const thumbPath = filePath.replace(/\.webp$/, '_thumb.webp');
        if (fs.existsSync(thumbPath)) {
          try {
            const thumbStat = await fs.promises.stat(thumbPath);
            bytesFreed += thumbStat.size;
          } catch {
            // ignore stat error
          }
          await fs.promises.unlink(thumbPath);
          this.logger.log(`Deleted associated thumbnail: ${path.basename(thumbPath)}`);
        }
      }

      return bytesFreed;
    } catch (error: unknown) {
      this.logger.error(`Delete failed: ${(error as Error).message}`);
      return 0;
    }
  }

  async deleteEmptyFolder(folderPath: string): Promise<void> {
    try {
      if (!folderPath) return;

      const relativePath = folderPath.replace(/^\/media\//, '');
      const targetDir = path.normalize(path.join(this.baseDir, relativePath));

      if (!targetDir.startsWith(this.baseDir)) {
        this.logger.warn(`Path traversal attempt detected for folder: ${folderPath}`);
        return;
      }

      if (fs.existsSync(targetDir)) {
        const files = await fs.promises.readdir(targetDir);
        if (files.length === 0) {
          await fs.promises.rmdir(targetDir);
          this.logger.log(`Removed empty folder: ${relativePath}`);
        }
      }
    } catch (error: unknown) {
      this.logger.warn(`Could not remove empty folder ${folderPath}: ${(error as Error).message}`);
    }
  }

  async ensureDir(dir: string): Promise<void> {
    try {
      await fs.promises.mkdir(dir, { recursive: true });
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        (error as Record<string, unknown>).code === 'EEXIST'
      ) {
        return;
      }
      throw error;
    }
  }
}
