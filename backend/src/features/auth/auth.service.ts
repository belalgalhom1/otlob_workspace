import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  ForbiddenException,
  Inject,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import * as bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import appleSignin from 'apple-signin-auth';
import {
  DriverStatus,
  Role,
  VendorMemberRole,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { DriverStatusChangedEvent, OtpRequestedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { OtpService } from '../otp/otp.service';
import {
  LoginDto,
  RegisterDto,
  SendOtpDto,
  VerifyOtpDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  LogoutDto,
  SocialLoginDto,
} from './dto/auth.dto';
import {
  JwtAccessPayload,
  JwtRefreshPayload,
} from 'src/common/interfaces/jwt-payload.interface';
import {
  AuthErrors,
  CommonSuccess,
  DriverErrors,
  UserErrors,
} from 'src/common/constants/response.constants';
import {
  JWT_ACCESS_SERVICE,
  JWT_REFRESH_SERVICE,
} from 'src/common/constants/jwt.constants';

// In-flight deduplication window (in seconds) to safely absorb simultaneous
// concurrent refresh calls from the same client without re-rotating or desyncing.
const REFRESH_INFLIGHT_TTL_SECONDS = 5;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly googleClient = new OAuth2Client();
  constructor(
    private prisma: PrismaService,
    @Inject(JWT_ACCESS_SERVICE) private accessJwt: JwtService,
    @Inject(JWT_REFRESH_SERVICE) private refreshJwt: JwtService,
    private otpService: OtpService,
    private eventEmitter: EventEmitter2,
    private config: ConfigService,
    private socketService: SocketService,
    private redis: RedisService,
    private driverTracking: DriverTrackingService,
  ) {}

  async register(
    dto: RegisterDto,
    isAdminCreated: boolean = false,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    let user;
    try {
      user = await this.prisma.$transaction(
        async (tx) => {
          const existing = await tx.user.findFirst({
            where: { email: dto.email },
          });

          if (existing) {
            if (existing.isEmailVerified) {
              throw new ConflictException(AuthErrors.USER_EXISTS);
            }
            await tx.user.delete({ where: { id: existing.id } });
          }

          if (dto.phone) {
            const existingPhone = await tx.user.findFirst({
              where: { phone: dto.phone },
            });
            if (existingPhone) {
              throw new ConflictException(UserErrors.PHONE_ALREADY_EXISTS);
            }
          }

          const u = await tx.user.create({
            data: {
              email: dto.email,
              phone: dto.phone ?? null,
              password: hashedPassword,
              name: dto.name,
              role: dto.role ?? Role.CUSTOMER,
              isEmailVerified: isAdminCreated,
              isPhoneVerified: isAdminCreated ? !!dto.phone : false,
            },
          });

          if (dto.role === Role.DRIVER_MANAGER) {
            await tx.driverManager.create({
              data: {
                userId: u.id,
              },
            });
          }

          if (dto.role === Role.VENDOR_MEMBER && dto.vendorId) {
            await tx.vendorMember.create({
              data: {
                userId: u.id,
                vendorId: dto.vendorId,
                role:
                  (dto.vendorRole as VendorMemberRole) ??
                  VendorMemberRole.STAFF,
              },
            });
          }

          return u;
        },
        { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
      );
    } catch (error) {
      // Race backstop: if a concurrent registration won the transaction, the
      // unique constraint on email/phone surfaces as P2002, or the serializable
      // tx aborts with P2034. Convert both to a clean 409 instead of a 500.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        (error.code === 'P2002' || error.code === 'P2034')
      ) {
        const uniqueTarget = String(
          (error.meta as { target?: string | string[] } | undefined)?.target ??
            '',
        );
        if (error.code === 'P2002' && uniqueTarget.includes('phone')) {
          throw new ConflictException(UserErrors.PHONE_ALREADY_EXISTS);
        }
        throw new ConflictException(AuthErrors.USER_EXISTS);
      }
      throw error;
    }

    if (user.email) {
      await this.requestVerification({ contact: user.email, method: 'EMAIL' });
    }

    const tokens = await this.createSession(user.id, user.role, false, meta);
    const { password: _, ...userWithoutPassword } = user;
    return { ...tokens, user: userWithoutPassword };
  }

  async login(
    dto: LoginDto,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    this.logger.log(`Login attempt for: ${dto.email}`);
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email },
      include: {
        vendorMemberships: {
          include: {
            vendor: true,
          },
        },
        driver: {
          select: {
            isApproved: true,
            avatar: true,
          },
        },
      },
    });

    if (!user) {
      this.logger.warn(`Login failed: User not found for ${dto.email}`);
      throw new UnauthorizedException(AuthErrors.INVALID_CREDENTIALS);
    }

    if (user.isBanned) {
      this.logger.warn(`Login failed: User is banned: ${dto.email}`);
      throw new UnauthorizedException(AuthErrors.BANNED);
    }

    if (!user.password) {
      this.logger.warn(
        `Login failed: OAuth account without password for ${dto.email}`,
      );
      throw new UnauthorizedException(AuthErrors.SOCIAL_LOGIN_REQUIRED);
    }

    const isMatch = await bcrypt.compare(dto.password, user.password);
    if (!isMatch) {
      this.logger.warn(`Login failed: Password mismatch for ${dto.email}`);
      throw new UnauthorizedException(AuthErrors.INVALID_CREDENTIALS);
    }

    if (!user.isEmailVerified) {
      this.logger.warn(`Login failed: Email not verified: ${dto.email}`);
      throw new ForbiddenException(AuthErrors.UNVERIFIED);
    }

    if (dto.app === 'driver' && user.role !== Role.DRIVER) {
      this.logger.warn(
        `Login failed: Invalid app access for user ${dto.email}`,
      );
      throw new ForbiddenException(AuthErrors.ONLY_DRIVERS_APP_ALLOWED);
    }

    if (
      dto.app === 'vendor' &&
      user.role !== Role.VENDOR_MEMBER &&
      user.role !== Role.ADMIN &&
      user.role !== Role.SUPER_ADMIN &&
      user.role !== Role.DRIVER_MANAGER
    ) {
      this.logger.warn(
        `Login failed: Non-vendor/admin user ${dto.email} attempted login to Vendor app`,
      );
      throw new ForbiddenException(AuthErrors.ONLY_VENDOR_APP_ALLOWED);
    }

    if (dto.app === 'customer' && user.role === Role.DRIVER) {
      throw new ForbiddenException(AuthErrors.ONLY_DRIVERS_APP_ALLOWED);
    }

    if (
      user.role === Role.DRIVER &&
      (!user.driver || !user.driver.isApproved)
    ) {
      this.logger.warn(`Login failed: Driver pending approval: ${dto.email}`);
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }

    this.logger.log(`Login success: ${dto.email}`);
    const tokens = await this.createSession(user.id, user.role, true, meta);
    const { password: _, ...userWithoutPassword } = user as any;
    const coalescedAvatar =
      userWithoutPassword.avatar ?? userWithoutPassword.driver?.avatar ?? null;
    return {
      ...tokens,
      user: { ...userWithoutPassword, avatar: coalescedAvatar },
    };
  }

  private async verifyGoogleToken(idToken: string): Promise<{
    sub: string;
    email?: string;
    name?: string;
    emailVerified?: boolean;
    exp?: number;
  }> {
    try {
      const googleClientIds =
        this.config.get<string>('GOOGLE_CLIENT_IDS')?.split(',') || [];
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: googleClientIds.map((id) => id.trim()).filter(Boolean),
      });
      const payload = ticket.getPayload();
      if (!payload)
        throw new UnauthorizedException(AuthErrors.NO_PAYLOAD_FOUND);
      return {
        sub: payload.sub,
        email: payload.email,
        name: payload.name,
        emailVerified: payload.email_verified === true,
        exp: payload.exp,
      };
    } catch (error: any) {
      this.logger.error(`Google token verification failed: ${error.message}`);
      throw new UnauthorizedException(AuthErrors.INVALID_GOOGLE_TOKEN);
    }
  }

  private async verifyAppleToken(idToken: string): Promise<{
    sub: string;
    email?: string;
    emailVerified?: boolean;
    exp?: number;
  }> {
    try {
      const appleClientIds =
        this.config.get<string>('APPLE_CLIENT_IDS')?.split(',') || [];
      const payload = await appleSignin.verifyIdToken(idToken, {
        audience: appleClientIds.map((id) => id.trim()).filter(Boolean),
        ignoreExpiration: false,
      });
      return {
        sub: payload.sub,
        email: payload.email,
        // Apple only includes `email` for addresses it has verified at
        // authorization time, and it may omit `email_verified` entirely.
        // Reject only an explicit false; treat true/"true"/absent as verified.
        emailVerified:
          payload.email_verified !== false &&
          payload.email_verified !== 'false',
        exp: payload.exp != null ? Number(payload.exp) : undefined,
      };
    } catch (error: any) {
      this.logger.error(`Apple token verification failed: ${error.message}`);
      throw new UnauthorizedException(AuthErrors.INVALID_APPLE_TOKEN);
    }
  }

  async socialLogin(
    dto: SocialLoginDto,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    this.logger.log(`Social login attempt for: ${dto.provider}`);

    let providerAccountId = dto.providerAccountId;
    let verifiedEmail: string | undefined;
    let name = dto.name;
    let emailVerified = false;

    if (dto.provider === 'GOOGLE') {
      const payload = await this.verifyGoogleToken(dto.idToken);
      providerAccountId = payload.sub;
      verifiedEmail = payload.email;
      name = payload.name || name;
      emailVerified = payload.emailVerified === true;
    } else if (dto.provider === 'APPLE') {
      const payload = await this.verifyAppleToken(dto.idToken);
      providerAccountId = payload.sub;
      verifiedEmail = payload.email;
      emailVerified = payload.emailVerified === true;
    } else {
      throw new BadRequestException(AuthErrors.UNSUPPORTED_SOCIAL_PROVIDER);
    }

    if (!providerAccountId) {
      throw new BadRequestException(
        AuthErrors.SOCIAL_ACCOUNT_VERIFICATION_FAILED,
      );
    }

    if (verifiedEmail && !emailVerified) {
      this.logger.warn(
        `Social login rejected: provider email not verified (${dto.provider})`,
      );
      throw new UnauthorizedException(AuthErrors.SOCIAL_EMAIL_NOT_VERIFIED);
    }

    // 1. Check if Account exists
    const account = await this.prisma.account.findUnique({
      where: {
        provider_providerAccountId: {
          provider: dto.provider,
          providerAccountId: providerAccountId,
        },
      },
      include: {
        user: {
          include: {
            driver: { select: { isApproved: true } },
          },
        },
      },
    });

    let user = account?.user || null;

    // 2. If no account, check if User exists by verifiedEmail to link (NEVER untrusted client email)
    if (!user && verifiedEmail) {
      user = await this.prisma.user.findFirst({
        where: { email: verifiedEmail },
        include: {
          driver: { select: { isApproved: true } },
        },
      });

      if (user) {
        await this.prisma.account.create({
          data: {
            userId: user.id,
            provider: dto.provider,
            providerAccountId: providerAccountId,
          },
        });
        this.logger.log(
          `Linked ${dto.provider} account to existing user ${user.email}`,
        );
      }
    }

    // 3. If still no user, Auto-Register
    if (!user) {
      if (dto.app === 'vendor') {
        throw new ForbiddenException(AuthErrors.ONLY_VENDOR_APP_ALLOWED);
      }
      user = await this.prisma.$transaction(async (tx) => {
        const u = await tx.user.create({
          data: {
            email: verifiedEmail ?? null,
            name: name ?? 'New User',
            role: dto.app === 'driver' ? Role.DRIVER : Role.CUSTOMER,
            isEmailVerified: true,
            accounts: {
              create: {
                provider: dto.provider,
                providerAccountId: providerAccountId,
              },
            },
          },
        });

        if (dto.app === 'driver') {
          await tx.driver.create({
            data: {
              userId: u.id,
              name: u.name,
              vehicleType: 'MOTORCYCLE',
              isApproved: false,
            },
          });
        }

        if (dto.app === 'customer') {
          await tx.customer.create({ data: { userId: u.id } });
        }

        return tx.user.findUniqueOrThrow({
          where: { id: u.id },
          include: { driver: { select: { isApproved: true } } },
        });
      });
      this.logger.log(
        `Auto-registered new user via ${dto.provider}: ${user.email}`,
      );
    }

    // 4. Validate Role / App Access
    if (user.isBanned) {
      this.logger.warn(`Social login failed: User is banned: ${user.email}`);
      throw new UnauthorizedException(AuthErrors.BANNED);
    }

    if (dto.app === 'driver' && user.role !== Role.DRIVER) {
      this.logger.warn(
        `Social login failed: Invalid app access for user ${user.email}`,
      );
      throw new ForbiddenException(AuthErrors.ONLY_DRIVERS_APP_ALLOWED);
    }

    if (
      dto.app === 'vendor' &&
      user.role !== Role.VENDOR_MEMBER &&
      user.role !== Role.ADMIN &&
      user.role !== Role.SUPER_ADMIN &&
      user.role !== Role.DRIVER_MANAGER
    ) {
      throw new ForbiddenException(AuthErrors.ONLY_VENDOR_APP_ALLOWED);
    }

    if (dto.app === 'customer' && user.role === Role.DRIVER) {
      throw new ForbiddenException(AuthErrors.ONLY_DRIVERS_APP_ALLOWED);
    }

    if (
      user.role === Role.DRIVER &&
      (!user.driver || !user.driver.isApproved)
    ) {
      this.logger.warn(
        `Social login failed: Driver pending approval: ${user.email}`,
      );
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }

    // 5. Success
    const tokens = await this.createSession(user.id, user.role, true, meta);
    const { password: _, ...userWithoutPassword } = user as any;
    const coalescedAvatar =
      userWithoutPassword.avatar ?? userWithoutPassword.driver?.avatar ?? null;
    return {
      ...tokens,
      user: { ...userWithoutPassword, avatar: coalescedAvatar },
    };
  }

  async linkSocialAccount(userId: string, dto: SocialLoginDto) {
    let providerAccountId: string | undefined;

    if (dto.provider === 'GOOGLE') {
      const payload = await this.verifyGoogleToken(dto.idToken);
      providerAccountId = payload.sub;
    } else if (dto.provider === 'APPLE') {
      const payload = await this.verifyAppleToken(dto.idToken);
      providerAccountId = payload.sub;
    } else {
      throw new BadRequestException(AuthErrors.UNSUPPORTED_SOCIAL_PROVIDER);
    }

    if (!providerAccountId) {
      throw new BadRequestException(
        AuthErrors.SOCIAL_ACCOUNT_VERIFICATION_FAILED,
      );
    }

    const existing = await this.prisma.account.findUnique({
      where: {
        provider_providerAccountId: {
          provider: dto.provider,
          providerAccountId,
        },
      },
      select: { userId: true },
    });

    if (existing) {
      if (existing.userId === userId) {
        return { message: CommonSuccess.OPERATION_SUCCESS };
      }
      throw new ConflictException(AuthErrors.SOCIAL_ACCOUNT_TAKEN);
    }

    const sameProvider = await this.prisma.account.findFirst({
      where: { userId, provider: dto.provider },
      select: { id: true },
    });
    if (sameProvider) {
      throw new ConflictException(AuthErrors.SOCIAL_PROVIDER_ALREADY_LINKED);
    }

    await this.prisma.account.create({
      data: { userId, provider: dto.provider, providerAccountId },
    });

    this.logger.log(`Linked ${dto.provider} account to user ${userId}`);
    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async unlinkSocialAccount(userId: string, provider: string) {
    if (provider !== 'GOOGLE' && provider !== 'APPLE') {
      throw new BadRequestException(AuthErrors.UNSUPPORTED_SOCIAL_PROVIDER);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { password: true, email: true },
    });
    if (!user) throw new UnauthorizedException(AuthErrors.USER_NOT_FOUND);

    const account = await this.prisma.account.findFirst({
      where: { userId, provider },
      select: { id: true },
    });
    if (!account) {
      throw new NotFoundException(AuthErrors.SOCIAL_PROVIDER_NOT_LINKED);
    }

    const remaining = await this.prisma.account.count({ where: { userId } });

    // Invariant: never strip the user's last sign-in method unless they
    // have a usable fallback — password + email.
    if (remaining <= 1 && !(user.password && user.email)) {
      throw new BadRequestException(AuthErrors.CANNOT_UNLINK_LAST_METHOD);
    }

    await this.prisma.account.delete({ where: { id: account.id } });

    this.logger.log(`Unlinked ${provider} from user ${userId}`);
    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async requestVerification(dto: SendOtpDto) {
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: dto.contact }, { phone: dto.contact }] },
    });
    // Prevent user enumeration: always return success even if contact is not registered
    if (!user) {
      return { message: CommonSuccess.OPERATION_SUCCESS };
    }

    await this.otpService.deleteOtp(dto.contact, 'VERIFICATION');
    const code = await this.otpService.generateOtp(dto.contact, 'VERIFICATION');

    this.eventEmitter.emit(
      EVENTS.AUTH_OTP_REQUESTED,
      new OtpRequestedEvent(dto.contact, code, dto.method, 'VERIFICATION'),
    );

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async verifyContact(dto: VerifyOtpDto) {
    const isPasswordReset = dto.purpose === 'PASSWORD_RESET';

    const isValid = isPasswordReset
      ? await this.otpService.peekOtp(dto.contact, dto.code, 'PASSWORD_RESET')
      : await this.otpService.validateOtp(
          dto.contact,
          dto.code,
          'VERIFICATION',
        );

    if (!isValid) throw new BadRequestException(AuthErrors.OTP_INVALID);

    if (!isPasswordReset) {
      const isEmail = dto.contact.includes('@');
      await this.prisma.user.updateMany({
        where: isEmail ? { email: dto.contact } : { phone: dto.contact },
        data: {
          isEmailVerified: isEmail ? true : undefined,
          isPhoneVerified: !isEmail ? true : undefined,
        },
      });
    }

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: dto.contact }, { phone: dto.contact }] },
    });

    if (!user) {
      return { message: CommonSuccess.OPERATION_SUCCESS };
    }

    const isEmail = dto.contact.includes('@');
    const method = isEmail ? 'EMAIL' : ('SMS' as const);

    await this.otpService.deleteOtp(dto.contact, 'PASSWORD_RESET');
    const code = await this.otpService.generateOtp(
      dto.contact,
      'PASSWORD_RESET',
    );

    this.eventEmitter.emit(
      EVENTS.AUTH_OTP_REQUESTED,
      new OtpRequestedEvent(dto.contact, code, method, 'PASSWORD_RESET'),
    );

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const isValid = await this.otpService.validateOtp(
      dto.contact,
      dto.code,
      'PASSWORD_RESET',
    );
    if (!isValid) throw new BadRequestException(AuthErrors.OTP_INVALID);

    const existingUser = await this.prisma.user.findFirst({
      where: { OR: [{ email: dto.contact }, { phone: dto.contact }] },
    });
    if (!existingUser) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    const user = await this.prisma.user.update({
      where: { id: existingUser.id },
      data: { password: hashedPassword },
      select: { id: true },
    });

    await this.prisma.session.deleteMany({ where: { userId: user.id } });
    const accessTtl = this.getAccessExpirySeconds();
    await this.redis.set(`revoked:user:${user.id}`, '1', accessTtl);
    this.socketService.disconnectUser(user.id);

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async refreshTokens(
    payload: JwtRefreshPayload,
    rawRefreshToken: string,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    const session = await this.prisma.session.findUnique({
      where: { id: payload.sid },
      include: {
        user: {
          select: {
            id: true,
            role: true,
            name: true,
            avatar: true,
            isBanned: true,
            banReason: true,
            isEmailVerified: true,
            permissions: true,
            vendorMemberships: {
              include: {
                vendor: true,
              },
            },
          },
        },
      },
    });

    if (!session || session.userId !== payload.sub) {
      throw new UnauthorizedException(AuthErrors.SESSION_EXPIRED);
    }

    if (session.expiresAt < new Date()) {
      // Opportunistically purge every expired session for this user instead of
      // only the current one, so stale rows don't accumulate until the cron.
      await this.prisma.session.deleteMany({
        where: { userId: payload.sub, expiresAt: { lt: new Date() } },
      });
      throw new UnauthorizedException(AuthErrors.SESSION_EXPIRED);
    }

    const driverProfile = await this.prisma.driver.findUnique({
      where: { userId: payload.sub },
      select: { isApproved: true, avatar: true },
    });

    const user = session.user;

    if (user.isBanned) {
      throw new UnauthorizedException(AuthErrors.BANNED);
    }

    if (
      user.role === Role.DRIVER &&
      (!driverProfile || !driverProfile.isApproved)
    ) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }

    const incomingHash = crypto
      .createHash('sha256')
      .update(rawRefreshToken)
      .digest('hex');

    const isMatch =
      incomingHash.length === session.hashedRt.length &&
      crypto.timingSafeEqual(
        Buffer.from(incomingHash),
        Buffer.from(session.hashedRt),
      );

    const inflightKey = `auth:inflight:${session.id}:${incomingHash}`;

    if (!isMatch) {
      // Check if this specific token was just rotated in-flight by a simultaneous concurrent request
      const cached = await this.getInflightCachedRotation(inflightKey);
      if (cached) {
        try {
          return cached;
        } catch {}
      }

      // Strictly reject superseded or invalid refresh tokens without overwriting
      // stored session hashes, issuing new tokens, or locking out legitimate clients.
      throw new UnauthorizedException(AuthErrors.SESSION_EXPIRED);
    }

    const refreshExpiresIn = this.config.getOrThrow<string>(
      'JWT_REFRESH_EXPIRATION',
    );
    const expiresAt = this.parseExpiry(refreshExpiresIn);

    const accessPayload: JwtAccessPayload = {
      sub: user.id,
      sid: session.id,
      role: user.role,
      verified: user.isEmailVerified,
    };

    const refreshPayload: JwtRefreshPayload = {
      sub: user.id,
      sid: session.id,
    };

    const [access_token, refresh_token] = await Promise.all([
      this.accessJwt.signAsync(accessPayload),
      this.refreshJwt.signAsync(refreshPayload),
    ]);

    const newHashedRt = crypto
      .createHash('sha256')
      .update(refresh_token)
      .digest('hex');

    // Optimistic concurrency update: only rotate if hashedRt still matches incomingHash.
    // This prevents race conditions between simultaneous requests from overwriting each other.
    const updateResult = await this.prisma.session.updateMany({
      where: {
        id: session.id,
        hashedRt: session.hashedRt,
      },
      data: {
        hashedRt: newHashedRt,
        expiresAt,
        ipAddress: meta?.ipAddress ?? session.ipAddress,
        userAgent: meta?.userAgent ?? session.userAgent,
      },
    });

    const { password: _, ...userWithoutPassword } = user as any;
    const coalescedAvatar =
      userWithoutPassword.avatar ?? driverProfile?.avatar ?? null;
    const responsePayload = {
      access_token,
      refresh_token,
      user: { ...userWithoutPassword, avatar: coalescedAvatar },
    };

    if (updateResult.count === 0) {
      // Another concurrent request updated the session while this was signing tokens.
      // Return the cached in-flight tokens or throw if unavailable.
      const cached = await this.getInflightCachedRotation(inflightKey);
      if (cached) {
        try {
          return cached;
        } catch {}
      }
      throw new UnauthorizedException(AuthErrors.SESSION_EXPIRED);
    }

    // Cache the rotation response briefly for in-flight simultaneous requests only
    await this.redis.set(
      inflightKey,
      JSON.stringify(responsePayload),
      REFRESH_INFLIGHT_TTL_SECONDS,
    );

    return responsePayload;
  }

  private async getInflightCachedRotation(
    key: string,
    retries = 2,
    delayMs = 60,
  ): Promise<any | null> {
    for (let i = 0; i <= retries; i++) {
      try {
        const cached = await this.redis.get(key);
        if (cached) {
          try {
            return JSON.parse(cached);
          } catch {
            return null;
          }
        }
      } catch {}
      if (i < retries) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
    return null;
  }

  private async setDriverOfflineAfterLogoutIfNoActiveShift(
    driverId: string,
    userId: string,
    currentStatus: DriverStatus,
  ) {
    const activeShift = await this.prisma.driverShift.findFirst({
      where: { driverId, status: 'ACTIVE' },
      select: { id: true },
    });

    // Logout ends the app session, not the driver's scheduled work shift.
    if (activeShift) return;

    await this.prisma.driver.update({
      where: { id: driverId },
      data: { status: DriverStatus.OFFLINE },
    });
    await this.driverTracking.removeDriverLocation(driverId);
    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(
        driverId,
        userId,
        currentStatus,
        DriverStatus.OFFLINE,
      ),
    );
  }

  async logout(userId: string, sessionId: string, dto?: LogoutDto) {
    const activeGroupWhere = {
      status: {
        notIn: ['CANCELLED', 'DELIVERED'] as any[],
      },
      primaryDriverId: { not: null },
    };
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        role: true,
        driver: {
          select: {
            id: true,
            status: true,
            primaryGroups: {
              where: { status: { notIn: ['CANCELLED', 'DELIVERED'] } },
              select: { id: true },
            },
            assistGroups: {
              where: { status: { notIn: ['CANCELLED', 'DELIVERED'] } },
              select: { id: true },
            },
          },
        },
      },
    });
    void activeGroupWhere;

    // If driver is attempting logout, ensure no deliveries are in progress
    if (user?.role === Role.DRIVER && user.driver) {
      if (
        (user.driver.primaryGroups?.length ?? 0) > 0 ||
        (user.driver.assistGroups?.length ?? 0) > 0
      ) {
        throw new BadRequestException(AuthErrors.CANNOT_LOGOUT_ON_DELIVERY);
      }

      await this.setDriverOfflineAfterLogoutIfNoActiveShift(
        user.driver.id,
        userId,
        user.driver.status,
      );
    }

    await this.prisma.session.deleteMany({
      where: { id: sessionId, userId },
    });

    // Revoke session in Redis for access token lifespan
    const accessTtl = this.getAccessExpirySeconds();
    await this.redis.set(`revoked:session:${sessionId}`, '1', accessTtl);

    this.socketService.disconnectSession(sessionId);

    if (dto?.fcmToken) {
      await this.prisma.device.deleteMany({
        where: { token: dto.fcmToken },
      });
    }

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async logoutAll(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        role: true,
        driver: {
          select: {
            id: true,
            status: true,
            primaryGroups: {
              where: { status: { notIn: ['CANCELLED', 'DELIVERED'] } },
              select: { id: true },
            },
            assistGroups: {
              where: { status: { notIn: ['CANCELLED', 'DELIVERED'] } },
              select: { id: true },
            },
          },
        },
      },
    });

    if (user?.role === Role.DRIVER && user.driver) {
      if (
        (user.driver.primaryGroups?.length ?? 0) > 0 ||
        (user.driver.assistGroups?.length ?? 0) > 0
      ) {
        throw new BadRequestException(AuthErrors.CANNOT_LOGOUT_ON_DELIVERY);
      }

      await this.setDriverOfflineAfterLogoutIfNoActiveShift(
        user.driver.id,
        userId,
        user.driver.status,
      );
    }

    await this.prisma.session.deleteMany({ where: { userId } });
    await this.prisma.device.deleteMany({ where: { userId } });
    const accessTtl = this.getAccessExpirySeconds();
    await this.redis.set(`revoked:user:${userId}`, '1', accessTtl);
    this.socketService.disconnectUser(userId);
    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  private async createSession(
    userId: string,
    role: string,
    verified: boolean,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    const refreshExpiresIn = this.config.getOrThrow<string>(
      'JWT_REFRESH_EXPIRATION',
    );

    const expiresAt = this.parseExpiry(refreshExpiresIn);

    const sessionId = randomUUID();

    const accessPayload: JwtAccessPayload = {
      sub: userId,
      sid: sessionId,
      role: role as Role,
      verified,
    };

    const refreshPayload: JwtRefreshPayload = {
      sub: userId,
      sid: sessionId,
    };

    const [access_token, refresh_token] = await Promise.all([
      this.accessJwt.signAsync(accessPayload),
      this.refreshJwt.signAsync(refreshPayload),
    ]);

    const hashedRt = crypto
      .createHash('sha256')
      .update(refresh_token)
      .digest('hex');

    await this.prisma.session.create({
      data: {
        id: sessionId,
        userId,
        hashedRt,
        expiresAt,
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
    });

    return { access_token, refresh_token };
  }

  private parseExpiry(expiry: string): Date {
    const now = Date.now();
    const unit = expiry.slice(-1);
    const value = parseInt(expiry.slice(0, -1), 10);

    const ms: Record<string, number> = {
      s: 1000,
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
    };

    const multiplier = ms[unit] ?? ms['d'];
    return new Date(now + value * multiplier);
  }

  private getAccessExpirySeconds(): number {
    const accessExp = this.config.get<string>('JWT_ACCESS_EXPIRATION') ?? '5m';
    const now = Date.now();
    const expiryDate = this.parseExpiry(accessExp);
    return Math.max(300, Math.ceil((expiryDate.getTime() - now) / 1000));
  }
}
