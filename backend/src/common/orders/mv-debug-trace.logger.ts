import { Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

const nestLogger = new Logger('MvDebugTrace');
const LOG_DIR = path.resolve(process.cwd(), 'logs');
const LOG_FILE = path.join(LOG_DIR, 'mv-debug-trace.txt');

/**
 * Temporary end-to-end Multi-Vendor Order backend debug tracer.
 *
 * Logs every step of a multi-vendor / multi-stop order lifecycle both to the
 * NestJS console (`[MV-TRACE]`) and to `backend/logs/mv-debug-trace.txt`.
 */
export function mvDebugTrace(
  step: string,
  message: string,
  data?: Record<string, unknown>,
): void {
  try {
    const ts = new Date().toISOString();
    const payload =
      data && Object.keys(data).length > 0 ? ` | ${safeStringify(data)}` : '';
    const line = `[${ts}] [BACKEND] [${step}] ${message}${payload}`;

    nestLogger.log(`[MV-TRACE] [${step}] ${message}${payload}`);

    fs.mkdirSync(LOG_DIR, { recursive: true });
    fs.appendFileSync(LOG_FILE, `${line}\n`, { encoding: 'utf8' });
  } catch {
    // Never let temporary debug file I/O break request/queue processing
  }
}

function safeStringify(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}
