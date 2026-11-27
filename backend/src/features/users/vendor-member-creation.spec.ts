import { NotFoundException } from '@nestjs/common';
import { Role, VendorMemberRole } from '@prisma/client';
import { AuthService } from '../auth/auth.service';
import { UsersService } from './users.service';

describe('Vendor member assignment on user creation & update', () => {
  describe('AuthService.register', () => {
    function buildAuthService(tx: any) {
      const prisma: any = {
        $transaction: jest.fn((fn: (t: any) => Promise<any>) => fn(tx)),
        user: {
          findFirst: jest.fn().mockResolvedValue(null),
        },
        session: {
          create: jest.fn().mockResolvedValue({ id: 'sess-1' }),
          update: jest.fn().mockResolvedValue({ id: 'sess-1' }),
        },
      };
      const accessJwt: any = {
        signAsync: jest.fn().mockResolvedValue('access-token'),
      };
      const refreshJwt: any = {
        signAsync: jest.fn().mockResolvedValue('refresh-token'),
      };
      const otpService: any = {
        deleteOtp: jest.fn().mockResolvedValue(undefined),
        generateOtp: jest.fn().mockResolvedValue('123456'),
      };
      const eventEmitter: any = { emit: jest.fn() };
      const config: any = {
        get: jest.fn().mockReturnValue('15m'),
        getOrThrow: jest.fn().mockReturnValue('7d'),
      };
      const socketService: any = { disconnectUser: jest.fn() };
      const redis: any = {
        set: jest.fn().mockResolvedValue(undefined),
        get: jest.fn().mockResolvedValue(null),
      };
      const driverTracking: any = {};

      return new AuthService(
        prisma,
        accessJwt,
        refreshJwt,
        otpService,
        eventEmitter,
        config,
        socketService,
        redis,
        driverTracking,
      );
    }

    it('creates vendorMember atomically when admin creates VENDOR_MEMBER with vendorId', async () => {
      const tx = {
        user: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({
            id: 'u-vendor-1',
            email: 'staff@vendor.com',
            phone: '+201000000001',
            password: 'hash',
            name: 'Staff User',
            role: Role.VENDOR_MEMBER,
            isEmailVerified: true,
            isPhoneVerified: true,
          }),
        },
        vendor: {
          findFirst: jest.fn().mockResolvedValue({ id: 'vendor-1' }),
        },
        vendorMember: {
          create: jest.fn().mockResolvedValue({ id: 'vm-1' }),
        },
      };

      const auth = buildAuthService(tx);
      const res = await auth.register(
        {
          email: 'staff@vendor.com',
          password: 'Password123!',
          name: 'Staff User',
          phone: '+201000000001',
          role: Role.VENDOR_MEMBER,
          vendorId: 'vendor-1',
          vendorRole: 'MANAGER',
        },
        true,
      );

      expect(tx.vendor.findFirst).toHaveBeenCalledWith({
        where: { id: 'vendor-1', deletedAt: null },
        select: { id: true },
      });
      expect(tx.vendorMember.create).toHaveBeenCalledWith({
        data: {
          userId: 'u-vendor-1',
          vendorId: 'vendor-1',
          role: VendorMemberRole.MANAGER,
        },
      });
      expect(res.user.id).toBe('u-vendor-1');
    });

    it('throws NotFoundException when admin creates VENDOR_MEMBER with non-existent vendorId', async () => {
      const tx = {
        user: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({
            id: 'u-vendor-2',
            email: 'staff2@vendor.com',
            phone: '+201000000002',
            password: 'hash',
            name: 'Staff User 2',
            role: Role.VENDOR_MEMBER,
          }),
        },
        vendor: {
          findFirst: jest.fn().mockResolvedValue(null),
        },
        vendorMember: {
          create: jest.fn(),
        },
      };

      const auth = buildAuthService(tx);
      await expect(
        auth.register(
          {
            email: 'staff2@vendor.com',
            password: 'Password123!',
            name: 'Staff User 2',
            phone: '+201000000002',
            role: Role.VENDOR_MEMBER,
            vendorId: 'missing-vendor',
            vendorRole: 'STAFF',
          },
          true,
        ),
      ).rejects.toBeInstanceOf(NotFoundException);

      expect(tx.vendorMember.create).not.toHaveBeenCalled();
    });

    it('does not create vendorMember on self-registration (isAdminCreated = false)', async () => {
      const tx = {
        user: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({
            id: 'u-public-1',
            email: 'public@vendor.com',
            phone: '+201000000003',
            password: 'hash',
            name: 'Public User',
            role: Role.VENDOR_MEMBER,
          }),
        },
        vendor: {
          findFirst: jest.fn(),
        },
        vendorMember: {
          create: jest.fn(),
        },
      };

      const auth = buildAuthService(tx);
      await auth.register(
        {
          email: 'public@vendor.com',
          password: 'Password123!',
          name: 'Public User',
          phone: '+201000000003',
          role: Role.VENDOR_MEMBER,
          vendorId: 'vendor-1',
          vendorRole: 'OWNER',
        },
        false,
      );

      expect(tx.vendor.findFirst).not.toHaveBeenCalled();
      expect(tx.vendorMember.create).not.toHaveBeenCalled();
    });
  });

  describe('UsersService.adminUpdate', () => {
    it('throws NotFoundException if updated vendorId does not exist', async () => {
      const tx = {
        user: {
          update: jest.fn().mockResolvedValue({
            id: 'u-1',
            role: Role.VENDOR_MEMBER,
          }),
        },
        vendor: {
          findFirst: jest.fn().mockResolvedValue(null),
        },
        vendorMember: {
          findMany: jest.fn().mockResolvedValue([]),
          deleteMany: jest.fn(),
          create: jest.fn(),
        },
        session: {
          deleteMany: jest.fn(),
        },
      };
      const prisma: any = {
        user: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'u-1',
            role: Role.VENDOR_MEMBER,
          }),
        },
        $transaction: jest.fn((fn: (t: any) => Promise<any>) => fn(tx)),
      };
      const service = new UsersService(
        prisma,
        {} as any,
        { set: jest.fn() } as any,
        { disconnectUser: jest.fn() } as any,
        {} as any,
      );

      await expect(
        service.adminUpdate(
          { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
          'u-1',
          { vendorId: 'missing-vendor', vendorRole: 'STAFF' },
        ),
      ).rejects.toBeInstanceOf(NotFoundException);

      expect(tx.vendorMember.deleteMany).not.toHaveBeenCalled();
      expect(tx.vendorMember.create).not.toHaveBeenCalled();
    });
  });
});
