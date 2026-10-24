import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Permission, Role } from '@prisma/client';
import { PermissionsGuard } from './permissions.guard';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';

describe('PermissionsGuard', () => {
  let guard: PermissionsGuard;
  let reflector: jest.Mocked<Reflector>;
  let prisma: { user: { findUnique: jest.Mock } };

  beforeEach(() => {
    reflector = {
      getAllAndOverride: jest.fn(),
    } as any;

    prisma = {
      user: {
        findUnique: jest.fn(),
      },
    };

    guard = new PermissionsGuard(reflector, prisma as unknown as PrismaService);
  });

  function createMockContext(user?: any): ExecutionContext {
    return {
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
    } as unknown as ExecutionContext;
  }

  it('allows access when no permissions are required', async () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);
    const ctx = createMockContext();
    expect(await guard.canActivate(ctx)).toBe(true);
  });

  it('throws UnauthorizedException when user is not authenticated', async () => {
    reflector.getAllAndOverride.mockReturnValue([Permission.MANAGE_DRIVERS]);
    const ctx = createMockContext(undefined);
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('allows SUPER_ADMIN unconditionally', async () => {
    reflector.getAllAndOverride.mockReturnValue([Permission.MANAGE_DRIVERS]);
    const ctx = createMockContext({ sub: 'user-1', role: Role.SUPER_ADMIN });
    expect(await guard.canActivate(ctx)).toBe(true);
  });

  it('allows DRIVER_MANAGER for default MANAGE_DRIVERS permission', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce([Permission.MANAGE_DRIVERS]) // required permissions
      .mockReturnValueOnce('all'); // mode
    prisma.user.findUnique.mockResolvedValue({ permissions: [] });

    const ctx = createMockContext({ sub: 'dm-1', role: Role.DRIVER_MANAGER });
    expect(await guard.canActivate(ctx)).toBe(true);
  });

  it('allows DRIVER_MANAGER for default MANAGE_ORDERS permission', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce([Permission.MANAGE_ORDERS])
      .mockReturnValueOnce('all');
    prisma.user.findUnique.mockResolvedValue({ permissions: [] });

    const ctx = createMockContext({ sub: 'dm-1', role: Role.DRIVER_MANAGER });
    expect(await guard.canActivate(ctx)).toBe(true);
  });

  it('allows DRIVER_MANAGER for custom assigned permission', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce([Permission.MANAGE_TICKETS])
      .mockReturnValueOnce('all');
    prisma.user.findUnique.mockResolvedValue({ permissions: [Permission.MANAGE_TICKETS] });

    const ctx = createMockContext({ sub: 'dm-1', role: Role.DRIVER_MANAGER });
    expect(await guard.canActivate(ctx)).toBe(true);
  });

  it('denies DRIVER_MANAGER for unauthorized permission', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce([Permission.MANAGE_SETTINGS])
      .mockReturnValueOnce('all');
    prisma.user.findUnique.mockResolvedValue({ permissions: [] });

    const ctx = createMockContext({ sub: 'dm-1', role: Role.DRIVER_MANAGER });
    await expect(guard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
  });

  it('denies other roles such as CUSTOMER or DRIVER', async () => {
    reflector.getAllAndOverride.mockReturnValue([Permission.MANAGE_ORDERS]);
    const ctx = createMockContext({ sub: 'cust-1', role: Role.CUSTOMER });
    await expect(guard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
  });
});
