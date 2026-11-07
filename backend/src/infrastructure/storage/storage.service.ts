import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

const MIME_TO_EXTENSION: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
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
};

// Validate file signatures (magic bytes) for image uploads to reject spoofed MIME types
function validateImageMagicBytes(buffer: Buffer, mimeType: string): boolean {
  if (!buffer || buffer.length < 12) return false;

  if (mimeType === 'image/jpeg') {
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

  return true;
}

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);

  readonly baseDir = path.join(process.cwd(), 'storage');

  constructor() {
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  async upload(file: Express.Multer.File, folder: string): Promise<string> {
    try {
      const targetDir = path.join(this.baseDir, folder);
      await this.ensureDir(targetDir);

      const mime = (file.mimetype || '').toLowerCase();

      // Magic byte validation for image uploads
      if (mime.startsWith('image/') && !validateImageMagicBytes(file.buffer, mime)) {
        throw new BadRequestException('Invalid image file content');
      }

      // Enforce safe extension derived strictly from validated MIME type
      // Never preserve raw user-supplied extensions (blocks .html, .svg, .php, .sh, .exe)
      const safeExt = MIME_TO_EXTENSION[mime];
      if (!safeExt) {
        throw new BadRequestException('Unsupported or unsafe file type');
      }

      const fileName = `${uuidv4()}${safeExt}`;
      const filePath = path.join(targetDir, fileName);

      await fs.promises.writeFile(filePath, file.buffer);
      this.logger.log(`Uploaded: ${folder}/${fileName}`);

      return `/media/${folder}/${fileName}`;
    } catch (error: unknown) {
      this.logger.error(
        `Upload failed: ${(error as Error).message}`,
        (error as Error).stack,
      );
      throw error;
    }
  }

  async delete(fileUrl: string): Promise<void> {
    try {
      if (!fileUrl) return;

      const relativePath = fileUrl.replace(/^\/media\//, '');
      const filePath = path.normalize(path.join(this.baseDir, relativePath));

      if (!filePath.startsWith(this.baseDir)) {
        this.logger.warn(`Path traversal attempt detected for: ${fileUrl}`);
        return;
      }

      if (fs.existsSync(filePath)) {
        await fs.promises.unlink(filePath);
        this.logger.log(`Deleted: ${relativePath}`);
      } else {
        this.logger.warn(`File not found for deletion: ${filePath}`);
      }
    } catch (error: unknown) {
      this.logger.error(`Delete failed: ${(error as Error).message}`);
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
