import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
  UnauthorizedException,
  Inject,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { JWT_ACCESS_SERVICE } from 'src/common/constants/jwt.constants';

import { CommonErrors } from 'src/common/constants/response.constants';

@Injectable()
export class GuestGuard implements CanActivate {
  constructor(
    @Inject(JWT_ACCESS_SERVICE) private accessTokenService: JwtService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractTokenFromHeader(request);

    if (!token) return true;

    try {
      const payload = await this.accessTokenService.verifyAsync(token);
      // Allow unverified users to access verification endpoints
      if (payload && !payload.verified && request.path.includes('/verify')) {
        return true;
      }
      throw new ForbiddenException(CommonErrors.FORBIDDEN);
    } catch (error) {
      if (error instanceof ForbiddenException) throw error;
      // A token was presented but could not be verified (expired/malformed).
      // Don't silently downgrade an authenticated request to guest access;
      // force the client to re-authenticate instead of treating it as a guest.
      throw new UnauthorizedException(CommonErrors.UNAUTHORIZED);
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const authHeader = request.headers.authorization;
    if (!authHeader) return undefined;

    const [type, token] = authHeader.split(' ');
    if (type !== 'Bearer') return undefined;

    return token;
  }
}
