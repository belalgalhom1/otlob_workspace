import { Injectable } from '@nestjs/common';
import { Permission, Role } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';

/**
 * Shared authorization helper for order management roles and permissions.
 */
@Injectable()
export class OrderAuthorizationHelper {
  constructor(private readonly prisma: PrismaService) {}

  async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.DRIVER_MANAGER) return false;
    if (role === Role.SUPER_ADMIN || role === Role.ADMIN) return true;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!(
      user?.permissions.includes(Permission.MANAGE_ORDERS) ||
      user?.permissions.includes(Permission.MANAGE_VENDORS)
    );
  }
}
