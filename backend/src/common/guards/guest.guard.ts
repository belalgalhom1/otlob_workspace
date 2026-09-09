import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
  Inject,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { JWT_ACCESS_SERVICE } from 'src/common/constants/jwt.constants';

import { CommonErrors } from 'src/common/constants/response.constants';

@Injectable()
export class GuestGuard implements CanActivate {
  private readonly logger = new Logger(GuestGuard.name);
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
      return true;
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
