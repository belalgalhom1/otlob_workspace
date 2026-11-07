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

    // Prefer trusted X-Real-IP set by Nginx reverse proxy, fallback to Express calculated IP.
    // Never trust client-controlled req.ips[0] (which allows header spoofing rate limiter bypass).
    const clientIp =
      (req.headers as Record<string, string>)?.['x-real-ip'] ||
      request.ip ||
      'unknown';
    return Promise.resolve(clientIp);
  }
}
