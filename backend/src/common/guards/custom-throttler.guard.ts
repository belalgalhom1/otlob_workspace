import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';

@Injectable()
export class CustomThrottlerGuard extends ThrottlerGuard {
  protected getTracker(req: Record<string, unknown>): Promise<string> {
    const request = req as unknown as {
      user?: { sub: string };
      ips?: string[];
      ip: string;
    };
    if (request.user?.sub) {
      return Promise.resolve(`user-${request.user.sub}`);
    }

    // Prefer Express calculated IP (backed by app.set('trust proxy', 1) & Nginx X-Forwarded-For),
    // falling back to X-Real-IP only if Express IP is unavailable.
    // Never trust client-controlled req.ips[0] (which allows header spoofing rate limiter bypass).
    const clientIp =
      request.ip ||
      (req.headers as Record<string, string>)?.['x-real-ip'] ||
      'unknown';
    return Promise.resolve(clientIp);
  }
}
