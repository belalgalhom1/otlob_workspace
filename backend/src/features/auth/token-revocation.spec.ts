import { UnauthorizedException } from '@nestjs/common';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { SocketGateway } from '../../infrastructure/socket/socket.gateway';
import {
  computeFreshTokenIssuedAtMs,
  createUserRevocationMarker,
  isUserTokenRevoked,
} from '../../common/utils/token-revocation.util';

describe('User token revocation & immediate re-login', () => {
  describe('token-revocation.util', () => {
    it('rejects tokens issued before or at revocation and accepts tokens issued after', () => {
      const revokedAt = 1_750_000_000_000;
      const marker = createUserRevocationMarker(revokedAt);

      expect(
        isUserTokenRevoked(marker, { iatMs: revokedAt - 1_000 }),
      ).toBe(true);
      expect(isUserTokenRevoked(marker, { iatMs: revokedAt })).toBe(true);
      expect(
        isUserTokenRevoked(marker, { iat: Math.floor(revokedAt / 1000) }),
      ).toBe(true);
      expect(isUserTokenRevoked(marker, { iatMs: revokedAt + 1 })).toBe(false);
    });

    it('rejects all tokens for legacy "1" markers and migrates on fresh session creation', () => {
      expect(isUserTokenRevoked('1', { iatMs: Date.now() })).toBe(true);

      const now = 1_750_000_005_000;
      const { iatMs, migratedMarker } = computeFreshTokenIssuedAtMs('1', now);
      expect(iatMs).toBe(now);
      expect(migratedMarker).toBe(String(now - 1));
      // Old tokens stay rejected after migration, new token is accepted.
      expect(isUserTokenRevoked(migratedMarker, { iatMs: now - 1000 })).toBe(
        true,
      );
      expect(isUserTokenRevoked(migratedMarker, { iatMs })).toBe(false);
    });
  });

  describe('JwtStrategy + AuthService re-login after revocation', () => {
    it('accepts a driver access token minted immediately after logoutAll while still rejecting the old token', async () => {
      const redisStore = new Map<string, string>();
      const redis: any = {
        get: jest.fn((key: string) =>
          Promise.resolve(redisStore.get(key) ?? null),
        ),
        set: jest.fn((key: string, value: string) => {
          redisStore.set(key, value);
          return Promise.resolve();
        }),
      };

      const passwordHash = await bcrypt.hash('secret123', 4);
      const prisma: any = {
        user: {
          findUnique: jest.fn().mockResolvedValue({
            role: Role.DRIVER,
            driver: {
              id: 'drv-1',
              status: 'OFFLINE',
              primaryGroups: [],
              assistGroups: [],
            },
          }),
          findFirst: jest.fn().mockResolvedValue({
            id: 'user-drv-1',
            email: 'driver@otlob.test',
            password: passwordHash,
            role: Role.DRIVER,
            isEmailVerified: true,
            isBanned: false,
            avatar: null,
            vendorMemberships: [],
            driver: {
              isApproved: true,
              status: 'OFFLINE',
              avatar: null,
            },
          }),
        },
        driverShift: { findFirst: jest.fn().mockResolvedValue(null) },
        driver: { update: jest.fn().mockResolvedValue({}) },
        session: {
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
          create: jest.fn().mockResolvedValue({}),
        },
        device: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      };

      const signedPayloads: any[] = [];
      const accessJwt: any = {
        signAsync: jest.fn((payload: any) => {
          signedPayloads.push(payload);
          return Promise.resolve(`access-${signedPayloads.length}`);
        }),
      };
      const refreshJwt: any = {
        signAsync: jest.fn().mockResolvedValue('refresh-1'),
      };
      const config: any = {
        get: jest.fn().mockReturnValue('15m'),
        getOrThrow: jest.fn((key: string) =>
          key === 'JWT_ACCESS_SECRET' ? 'test-secret' : '7d',
        ),
      };

      const auth = new AuthService(
        prisma,
        accessJwt,
        refreshJwt,
        {} as any,
        { emit: jest.fn() } as any,
        config,
        { disconnectUser: jest.fn() } as any,
        redis,
        { removeDriverLocation: jest.fn() } as any,
      );

      const strategy = new JwtStrategy(config, redis);

      const oldTokenPayload = {
        sub: 'user-drv-1',
        sid: 'old-session',
        role: Role.DRIVER,
        verified: true,
        iatMs: Date.now() - 10_000,
      };

      // Driver logs out all sessions (or admin revokes sessions / updates password).
      await auth.logoutAll('user-drv-1');

      // Old token MUST be rejected.
      await expect(strategy.validate(oldTokenPayload)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );

      // Driver immediately logs back in.
      const loginResult = await auth.login({
        email: 'driver@otlob.test',
        password: 'secret123',
        app: 'driver',
      });
      expect(loginResult.user.driver.status).toBe('OFFLINE');

      const newTokenPayload = signedPayloads[0];
      expect(newTokenPayload.iatMs).toBeDefined();

      // Freshly logged-in token MUST be accepted immediately.
      await expect(strategy.validate(newTokenPayload)).resolves.toMatchObject({
        sub: 'user-drv-1',
        role: Role.DRIVER,
        verified: true,
      });

      // Old token MUST STILL be rejected after the new login.
      await expect(strategy.validate(oldTokenPayload)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });

  describe('SocketGateway.authenticateSocket', () => {
    it('rejects pre-revocation socket token and accepts post-revocation token', async () => {
      const revokedAt = 1_750_000_000_000;
      const redis: any = {
        get: jest.fn((key: string) =>
          Promise.resolve(
            key === 'revoked:user:user-drv-1' ? String(revokedAt) : null,
          ),
        ),
      };
      const jwtService: any = {
        verify: jest.fn((token: string) =>
          token === 'old-jwt'
            ? {
                sub: 'user-drv-1',
                sid: 's-old',
                role: Role.DRIVER,
                iatMs: revokedAt - 5000,
              }
            : {
                sub: 'user-drv-1',
                sid: 's-new',
                role: Role.DRIVER,
                iatMs: revokedAt + 1,
              },
        ),
      };
      const socketAuthService: any = {
        authorize: jest.fn().mockResolvedValue(true),
      };

      const gateway = new SocketGateway(
        jwtService,
        {} as any,
        socketAuthService,
        redis,
      );

      const makeSocket = (token: string): any => ({
        handshake: { headers: {}, auth: { token }, query: {} },
        data: {},
        join: jest.fn(),
      });

      const oldNext = jest.fn();
      await (gateway as any).authenticateSocket(makeSocket('old-jwt'), oldNext);
      expect(oldNext).toHaveBeenCalledWith(expect.any(Error));

      const newNext = jest.fn();
      await (gateway as any).authenticateSocket(makeSocket('new-jwt'), newNext);
      expect(newNext).toHaveBeenCalledWith();
    });
  });
});
