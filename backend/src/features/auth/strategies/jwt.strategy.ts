import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../../infrastructure/redis/redis.service';
import { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { AuthErrors } from '../../../common/constants/response.constants';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    private redis: RedisService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
  }

  async validate(payload: JwtAccessPayload): Promise<JwtAccessPayload> {
    if (!payload?.sub || !payload?.sid) {
      throw new UnauthorizedException(AuthErrors.USER_NOT_FOUND);
    }

    // Fast sub-millisecond RAM check in Redis for banned users or revoked sessions
    const [isBanned, isRevokedSession, isRevokedUser] = await Promise.all([
      this.redis.get(`banned:user:${payload.sub}`),
      this.redis.get(`revoked:session:${payload.sid}`),
      this.redis.get(`revoked:user:${payload.sub}`),
    ]);

    if (isBanned) {
      throw new UnauthorizedException(AuthErrors.BANNED);
    }

    if (isRevokedSession || isRevokedUser) {
      throw new UnauthorizedException(AuthErrors.SESSION_EXPIRED);
    }

    return {
      sub: payload.sub,
      sid: payload.sid,
      role: payload.role,
      verified: payload.verified,
    };
  }
}
