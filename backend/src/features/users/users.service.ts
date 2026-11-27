import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
  Logger,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { SocketService } from '../../infrastructure/socket/socket.service';
import {
  UpdateNotificationSettingsDto,
  ChangePasswordDto,
  ChangeEmailDto,
  SetPasswordDto,
  UpdateUserDto,
  QueryUsersDto,
  AdminUpdateUserDto,
  BanUserDto,
} from './dto/user.dto';
import {
  CommonSuccess,
  CommonErrors,
  UserErrors,
  VendorErrors,
} from 'src/common/constants/response.constants';
import { Role, VendorMemberRole, Prisma, DriverStatus } from '@prisma/client';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { DriverManagersService } from '../drivers/driver-managers.service';
import { isValidRegisteredVehicleType } from '../../common/orders/vehicle-eligibility.helper';
import { createUserRevocationMarker } from '../../common/utils/token-revocation.util';

// Fields returned for both self-service and admin reads (no password)
const USER_SELECT = {
  id: true,
  name: true,
  email: true,
  phone: true,
  role: true,
  title: true,
  titleAr: true,
  permissions: true,
  avatar: true,
  language: true,
  isEmailVerified: true,
  isPhoneVerified: true,
  isBanned: true,
  banReason: true,
  autoReplyMessage: true,
  createdAt: true,
  updatedAt: true,
  deletedAt: true,
};

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly redis: RedisService,
    private readonly socketService: SocketService,
    private readonly driverManagersService: DriverManagersService,
    @Optional() private readonly config?: ConfigService,
  ) {}

  private getAccessExpirySeconds(): number {
    const expiry = this.config?.get<string>('JWT_ACCESS_EXPIRATION') ?? '5m';
    const unit = expiry.slice(-1);
    const value = parseInt(expiry.slice(0, -1), 10);
    const secondsPerUnit: Record<string, number> = {
      s: 1,
      m: 60,
      h: 3600,
      d: 86400,
    };
    const total = Number.isFinite(value)
      ? value * (secondsPerUnit[unit] ?? 60)
      : 300;
    return Math.max(300, total);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELF-SERVICE (existing — unchanged)
  // ═══════════════════════════════════════════════════════════════════════════

  async getUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatar: true,
        role: true,
        language: true,
        title: true,
        titleAr: true,
        isEmailVerified: true,
        isPhoneVerified: true,
        autoReplyMessage: true,
        createdAt: true,
        notificationSettings: true,
      },
    });

    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);
    return user;
  }

  async updateUser(userId: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, phone: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    const emailChanged = dto.email && dto.email !== user.email;
    const phoneChanged = dto.phone && dto.phone !== user.phone;

    if (emailChanged) {
      const existingEmail = await this.prisma.user.findFirst({
        where: { email: dto.email },
      });
      if (existingEmail && existingEmail.id !== userId) {
        throw new ConflictException(UserErrors.EMAIL_ALREADY_EXISTS);
      }
    }

    if (phoneChanged) {
      const existingPhone = await this.prisma.user.findFirst({
        where: { phone: dto.phone },
      });
      if (existingPhone && existingPhone.id !== userId) {
        throw new ConflictException(UserErrors.PHONE_ALREADY_EXISTS);
      }
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...dto,
        ...(emailChanged && { isEmailVerified: false }),
        ...(phoneChanged && { isPhoneVerified: false }),
      },
      select: {
        id: true,
        name: true,
        language: true,
        avatar: true,
        email: true,
        phone: true,
        title: true,
        titleAr: true,
        autoReplyMessage: true,
      },
    });

    return updated;
  }

  async uploadAvatar(userId: string, file: Express.Multer.File) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { avatar: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    const avatarUrl = await this.storage.upload(file, 'avatars');

    await this.prisma.user.update({
      where: { id: userId },
      data: { avatar: avatarUrl },
    });
    await this.prisma.driver?.updateMany?.({
      where: { userId },
      data: { avatar: avatarUrl },
    });

    if (user.avatar) {
      await this.storage.delete(user.avatar).catch(() => undefined);
    }

    return { avatar: avatarUrl, message: CommonSuccess.RESOURCE_UPDATED };
  }

  async changeEmail(userId: string, dto: ChangeEmailDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { password: true, email: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);
    if (!user.password)
      throw new BadRequestException(UserErrors.PASSWORD_NOT_SET);

    const isMatch = await bcrypt.compare(dto.currentPassword, user.password);
    if (!isMatch) throw new UnauthorizedException(UserErrors.INVALID_PASSWORD);

    const normalizedNewEmail = dto.newEmail.trim().toLowerCase();
    if (normalizedNewEmail === (user.email ?? '').trim().toLowerCase()) {
      throw new BadRequestException(UserErrors.EMAIL_SAME_AS_OLD);
    }

    const existingEmail = await this.prisma.user.findFirst({
      where: { email: { equals: normalizedNewEmail, mode: 'insensitive' } },
    });
    if (existingEmail && existingEmail.id !== userId) {
      throw new ConflictException(UserErrors.EMAIL_ALREADY_EXISTS);
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { email: normalizedNewEmail, isEmailVerified: false },
    });

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async changePassword(
    userId: string,
    sessionId: string,
    dto: ChangePasswordDto,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { password: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (!user.password) {
      throw new BadRequestException(UserErrors.PASSWORD_NOT_SET);
    }

    const isMatch = await bcrypt.compare(dto.currentPassword, user.password);
    if (!isMatch) throw new UnauthorizedException(UserErrors.INVALID_PASSWORD);

    if (dto.currentPassword === dto.newPassword) {
      throw new BadRequestException(UserErrors.PASSWORD_SAME_AS_OLD);
    }

    const hashed = await bcrypt.hash(dto.newPassword, 10);

    const otherSessions = await this.prisma.session.findMany({
      where: { userId, id: { not: sessionId } },
      select: { id: true },
    });

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { password: hashed },
      }),
      this.prisma.session.deleteMany({
        where: { userId, id: { not: sessionId } },
      }),
    ]);

    const accessTtl = this.getAccessExpirySeconds();
    for (const s of otherSessions) {
      await this.redis.set(`revoked:session:${s.id}`, '1', accessTtl);
      await this.socketService.disconnectSession(s.id);
    }

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async setPassword(userId: string, dto: SetPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { password: true, email: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (user.password) {
      throw new BadRequestException(UserErrors.PASSWORD_ALREADY_SET);
    }

    // A password is useless without a login identity — email is required
    // first because both login and OTP-based recovery are email-driven.
    if (!user.email) {
      throw new BadRequestException(UserErrors.EMAIL_REQUIRED_FIRST);
    }

    const hashed = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashed },
    });

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  async getNotificationSettings(userId: string) {
    const settings = await this.prisma.notificationSetting.findUnique({
      where: { userId },
    });

    if (!settings) {
      return {
        pushEnabled: true,
        orderUpdates: true,
        chatMessages: true,
        promotions: true,
        system: true,
      };
    }

    return settings;
  }

  async updateNotificationSettings(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ) {
    const settings = await this.prisma.notificationSetting.upsert({
      where: { userId },
      create: { userId, ...dto },
      update: { ...dto },
    });

    return settings;
  }

  async deleteAccount(userId: string) {
    await this.prisma.$transaction(async (tx) => {
      const memberships = await tx.vendorMember.findMany({ where: { userId } });
      for (const membership of memberships) {
        if (membership.role === VendorMemberRole.OWNER) {
          await tx.$executeRaw`SELECT 1 FROM vendors WHERE id = ${membership.vendorId} FOR UPDATE`;
          const ownerCount = await tx.vendorMember.count({
            where: {
              vendorId: membership.vendorId,
              role: VendorMemberRole.OWNER,
            },
          });
          if (ownerCount <= 1) {
            throw new BadRequestException(UserErrors.LAST_OWNER_OF_VENDOR);
          }
        }
      }

      await tx.session.deleteMany({ where: { userId } });
      await tx.device.deleteMany({ where: { userId } });
      await tx.account.deleteMany({ where: { userId } });
      await tx.user.update({
        where: { id: userId },
        data: { deletedAt: new Date(), email: null, phone: null },
      });
    });

    await this.redis.set(
      `revoked:user:${userId}`,
      createUserRevocationMarker(),
      this.getAccessExpirySeconds(),
    );
    await this.socketService.disconnectUser(userId);

    return { message: CommonSuccess.OPERATION_SUCCESS };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN — User Management  (MANAGE_USERS permission, enforced at route level)
  // ═══════════════════════════════════════════════════════════════════════════

  async adminFindAll(actor: JwtAccessPayload, dto: QueryUsersDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {};

    where.deletedAt = dto.includeDeleted ? undefined : null;

    if (dto.role !== undefined) {
      where.role = dto.role;
    }

    if (dto.isBanned !== undefined) where.isBanned = dto.isBanned;
    if (dto.search) {
      where.OR = [
        { name: { contains: dto.search, mode: 'insensitive' } },
        { email: { contains: dto.search, mode: 'insensitive' } },
        { phone: { contains: dto.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          ...USER_SELECT,
          vendorMemberships: {
            include: {
              vendor: {
                select: {
                  id: true,
                  storeName: true,
                  logo: true,
                  coverImage: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.user.count({ where }),
    ]);

    return { users, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async adminFindOne(actor: JwtAccessPayload, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        ...USER_SELECT,
        // Last 10 sessions for this user
        sessions: {
          select: {
            id: true,
            ipAddress: true,
            userAgent: true,
            createdAt: true,
            expiresAt: true,
          },
          orderBy: { createdAt: 'desc' as const },
          take: 10,
        },
        // Registered push devices
        devices: {
          select: { id: true, platform: true, lastActive: true },
        },
        // Vendor memberships (if VENDOR_MEMBER)
        vendorMemberships: {
          select: {
            id: true,
            role: true,
            vendor: {
              select: {
                id: true,
                storeName: true,
                logo: true,
                coverImage: true,
              },
            },
          },
        },
        // Customer profile snapshot (if CUSTOMER)
        customer: {
          select: {
            id: true,
            canOrder: true,
            createdAt: true,
            deletedAt: true,
            _count: { select: { orders: true, addresses: true } },
          },
        },
        // Driver profile snapshot (if DRIVER)
        driver: {
          select: {
            id: true,
            avatar: true,
            status: true,
            vehicleType: true,
            rating: true,
            totalOrders: true,
            walletBalance: true,
          },
        },
      },
    });

    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    return user;
  }

  async adminUpdate(
    actor: JwtAccessPayload,
    userId: string,
    dto: AdminUpdateUserDto,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (actor.role === Role.DRIVER_MANAGER) {
      if (user.role !== Role.DRIVER) {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
      // Only the manager this driver is assigned to may edit their profile.
      const driver = await this.prisma.driver.findUnique({
        where: { userId },
        select: { id: true },
      });
      if (!driver) {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
      await this.driverManagersService.assertManagesDriver(
        actor.sub,
        driver.id,
      );
      const allowedFields = [
        'vehicleType',
        'vehiclePlate',
        'licenseNumber',
        'nationalId',
      ] as const;
      const dtoKeys = Object.keys(dto);
      for (const key of dtoKeys) {
        if (!(allowedFields as readonly string[]).includes(key)) {
          throw new ForbiddenException(CommonErrors.FORBIDDEN);
        }
      }
      const driverUpdate: any = {};
      if ((dto as any).vehicleType !== undefined) {
        if (!isValidRegisteredVehicleType((dto as any).vehicleType)) {
          throw new BadRequestException(CommonErrors.VALIDATION_ERROR);
        }
        driverUpdate.vehicleType = (dto as any).vehicleType;
      }
      if ((dto as any).vehiclePlate !== undefined)
        driverUpdate.vehiclePlate = (dto as any).vehiclePlate;
      if ((dto as any).licenseNumber !== undefined)
        driverUpdate.licenseNumber = (dto as any).licenseNumber;
      if ((dto as any).nationalId !== undefined)
        driverUpdate.nationalId = (dto as any).nationalId;
      await this.prisma.driver.updateMany({
        where: { userId },
        data: driverUpdate,
      });
      this.logger.log(
        `Driver manager updated driver vehicle info for user ${userId}`,
      );
      const updatedUser = await this.prisma.user.findUnique({
        where: { id: userId },
        select: USER_SELECT,
      });
      return updatedUser;
    }

    if (actor.role === Role.ADMIN) {
      if (user.role === Role.SUPER_ADMIN) {
        throw new ForbiddenException(UserErrors.CANNOT_MODIFY_SUPER_ADMIN);
      }
      if (dto.role !== undefined && dto.role === Role.SUPER_ADMIN) {
        throw new ForbiddenException(UserErrors.CANNOT_CREATE_SUPER_ADMIN);
      }
      // Self-escalation guard: an ADMIN cannot modify their own role or permissions
      if (
        actor.sub === userId &&
        (dto.role !== undefined || dto.permissions !== undefined)
      ) {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
      // Only SUPER_ADMIN can grant or modify user permissions
      if (dto.permissions !== undefined) {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
    }

    const shouldRevokeSessions =
      dto.password !== undefined ||
      dto.role !== undefined ||
      dto.permissions !== undefined ||
      dto.vendorId !== undefined ||
      dto.vendorRole !== undefined;

    const updated = await this.prisma.$transaction(async (tx) => {
      const normalizedEmail =
        dto.email !== undefined ? dto.email.trim().toLowerCase() : undefined;
      const u = await tx.user.update({
        where: { id: userId },
        data: {
          ...(dto.name !== undefined && { name: dto.name }),
          ...(normalizedEmail !== undefined && { email: normalizedEmail }),
          ...(dto.phone !== undefined && { phone: dto.phone }),
          ...(dto.language !== undefined && { language: dto.language }),
          ...(dto.role !== undefined && { role: dto.role }),
          ...(dto.title !== undefined && { title: dto.title }),
          ...(dto.titleAr !== undefined && { titleAr: dto.titleAr }),
          ...(dto.permissions !== undefined && {
            permissions: dto.permissions,
          }),
          ...(dto.isEmailVerified !== undefined && {
            isEmailVerified: dto.isEmailVerified,
          }),
          ...(dto.isPhoneVerified !== undefined && {
            isPhoneVerified: dto.isPhoneVerified,
          }),
          ...(dto.password !== undefined && {
            password: await bcrypt.hash(dto.password, 10),
          }),
          ...(dto.autoReplyMessage !== undefined && {
            autoReplyMessage: dto.autoReplyMessage,
          }),
        },
        select: USER_SELECT,
      });

      const newRole = dto.role ?? u.role;
      if (newRole !== Role.VENDOR_MEMBER || dto.vendorId) {
        const memberships = await tx.vendorMember.findMany({
          where: { userId },
        });

        for (const membership of memberships) {
          if (membership.role === VendorMemberRole.OWNER) {
            await tx.$executeRaw`SELECT 1 FROM vendors WHERE id = ${membership.vendorId} FOR UPDATE`;
            const ownerCount = await tx.vendorMember.count({
              where: {
                vendorId: membership.vendorId,
                role: VendorMemberRole.OWNER,
              },
            });

            const isStayingOwner =
              newRole === Role.VENDOR_MEMBER &&
              dto.vendorId === membership.vendorId &&
              dto.vendorRole === VendorMemberRole.OWNER;
            if (ownerCount <= 1 && !isStayingOwner) {
              throw new BadRequestException(UserErrors.LAST_OWNER_OF_VENDOR);
            }
          }
        }
      }

      if (newRole !== Role.VENDOR_MEMBER) {
        await tx.vendorMember.deleteMany({
          where: { userId },
        });
      } else {
        if (dto.vendorId) {
          const vendor = await tx.vendor.findFirst({
            where: { id: dto.vendorId, deletedAt: null },
            select: { id: true },
          });
          if (!vendor) {
            throw new NotFoundException(VendorErrors.NOT_FOUND);
          }
          const existingSameVendor = await tx.vendorMember.findFirst({
            where: { userId, vendorId: dto.vendorId },
            select: { branchId: true },
          });
          await tx.vendorMember.deleteMany({
            where: { userId },
          });
          const targetVendorRole =
            (dto.vendorRole as VendorMemberRole) ?? VendorMemberRole.STAFF;
          await tx.vendorMember.create({
            data: {
              userId,
              vendorId: dto.vendorId,
              role: targetVendorRole,
              branchId:
                targetVendorRole === VendorMemberRole.OWNER
                  ? null
                  : (existingSameVendor?.branchId ?? null),
            },
          });
        }
      }
      if (newRole === Role.DRIVER_MANAGER) {
        await tx.driverManager.upsert({
          where: { userId },
          create: { userId },
          update: {},
        });
      }

      if (shouldRevokeSessions) {
        await tx.session.deleteMany({ where: { userId } });
      }

      return u;
    });

    if (shouldRevokeSessions) {
      await this.redis.set(
        `revoked:user:${userId}`,
        createUserRevocationMarker(),
        this.getAccessExpirySeconds(),
      );
      await this.socketService.disconnectUser(userId);
    }

    this.logger.log(`Admin updated user ${userId}`);
    return updated;
  }

  async adminBan(actor: JwtAccessPayload, userId: string, dto: BanUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (user.role === Role.SUPER_ADMIN) {
      throw new ForbiddenException(UserErrors.CANNOT_BAN_SUPER_ADMIN);
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      // Immediately invalidate all active sessions
      await tx.session.deleteMany({ where: { userId } });
      await tx.driver.updateMany({
        where: { userId },
        data: { status: DriverStatus.SUSPENDED },
      });
      return tx.user.update({
        where: { id: userId },
        data: { isBanned: true, banReason: dto.reason ?? null },
        select: USER_SELECT,
      });
    });

    // Invalidate immediately in Redis and disconnect active WebSockets
    await this.redis.set(
      `banned:user:${userId}`,
      dto.reason ?? '1',
      30 * 24 * 3600,
    );
    await this.redis.set(
      `revoked:user:${userId}`,
      createUserRevocationMarker(),
      this.getAccessExpirySeconds(),
    );
    await this.socketService.disconnectUser(userId);

    this.logger.log(
      `Admin banned user ${userId}: ${dto.reason ?? 'no reason'}`,
    );
    return updated;
  }

  async adminUnban(actor: JwtAccessPayload, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (actor.role === Role.ADMIN && user.role === Role.SUPER_ADMIN) {
      throw new ForbiddenException(UserErrors.CANNOT_MODIFY_SUPER_ADMIN);
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { isBanned: false, banReason: null },
      select: USER_SELECT,
    });

    // Remove from Redis blacklist
    await this.redis.del(`banned:user:${userId}`, `revoked:user:${userId}`);

    this.logger.log(`Admin unbanned user ${userId}`);
    return updated;
  }

  async adminGetSessions(actor: JwtAccessPayload, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    return this.prisma.session.findMany({
      where: { userId },
      select: {
        id: true,
        ipAddress: true,
        userAgent: true,
        createdAt: true,
        expiresAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async adminRevokeAllSessions(actor: JwtAccessPayload, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (actor.role === Role.ADMIN && user.role === Role.SUPER_ADMIN) {
      throw new ForbiddenException(UserErrors.CANNOT_MODIFY_SUPER_ADMIN);
    }

    const { count } = await this.prisma.session.deleteMany({
      where: { userId },
    });

    await this.redis.set(
      `revoked:user:${userId}`,
      createUserRevocationMarker(),
      this.getAccessExpirySeconds(),
    );
    await this.socketService.disconnectUser(userId);

    this.logger.log(`Admin revoked ${count} sessions for user ${userId}`);
    return { revoked: count, message: CommonSuccess.OPERATION_SUCCESS };
  }

  async adminRemove(actor: JwtAccessPayload, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    if (user.role === Role.SUPER_ADMIN) {
      throw new ForbiddenException(UserErrors.CANNOT_DELETE_SUPER_ADMIN);
    }

    await this.prisma.$transaction(async (tx) => {
      const memberships = await tx.vendorMember.findMany({ where: { userId } });
      for (const membership of memberships) {
        if (membership.role === VendorMemberRole.OWNER) {
          await tx.$executeRaw`SELECT 1 FROM vendors WHERE id = ${membership.vendorId} FOR UPDATE`;
          const ownerCount = await tx.vendorMember.count({
            where: {
              vendorId: membership.vendorId,
              role: VendorMemberRole.OWNER,
            },
          });
          if (ownerCount <= 1) {
            throw new BadRequestException(UserErrors.LAST_OWNER_OF_VENDOR);
          }
        }
      }

      await tx.session.deleteMany({ where: { userId } });
      await tx.device.deleteMany({ where: { userId } });
      await tx.account.deleteMany({ where: { userId } });
      await tx.driver.updateMany({
        where: { userId },
        data: { status: DriverStatus.SUSPENDED, deletedAt: new Date() },
      });
      await tx.user.update({
        where: { id: userId },
        data: { deletedAt: new Date(), email: null, phone: null },
      });
    });

    await this.redis.set(
      `banned:user:${userId}`,
      'Account deleted',
      30 * 24 * 3600,
    );
    await this.redis.set(
      `revoked:user:${userId}`,
      createUserRevocationMarker(),
      this.getAccessExpirySeconds(),
    );
    await this.socketService.disconnectUser(userId);

    this.logger.log(`Admin soft-deleted user ${userId}`);
    return { message: CommonSuccess.RESOURCE_DELETED };
  }
}
