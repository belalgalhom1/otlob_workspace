import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CommonErrors } from '../../common/constants/response.constants';
import { DriverErrors } from '../../common/constants/response.constants';

@Injectable()
export class DriverManagersService {
  constructor(private readonly prisma: PrismaService) {}

  private async getManager(userId: string) {
    let manager = await this.prisma.driverManager.findUnique({
      where: { userId },
      select: { id: true, walletBalance: true, manageAllDrivers: true },
    });
    if (!manager) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { role: true },
      });
      if (user && user.role === 'DRIVER_MANAGER') {
        manager = await this.prisma.driverManager.create({
          data: { userId },
          select: { id: true, walletBalance: true, manageAllDrivers: true },
        });
      }
    }
    if (!manager) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }
    return manager;
  }

  async getManagedDriverIds(userId: string): Promise<string[]> {
    const manager = await this.getManager(userId);
    if (manager.manageAllDrivers) {
      const drivers = await this.prisma.driver.findMany({
        where: { deletedAt: null },
        select: { id: true },
      });
      return drivers.map((d) => d.id);
    }
    const assignments = await this.prisma.driverManagerAssignment.findMany({
      where: { driverManagerId: manager.id },
      select: { driverId: true },
    });
    return assignments.map((a) => a.driverId);
  }

  async getManagedDriverUserIds(userId: string): Promise<string[]> {
    const driverIds = await this.getManagedDriverIds(userId);
    if (driverIds.length === 0) return [];
    const drivers = await this.prisma.driver.findMany({
      where: { id: { in: driverIds } },
      select: { userId: true },
    });
    return drivers.map((d) => d.userId).filter((id): id is string => !!id);
  }

  async assertManagesDriver(userId: string, driverId: string) {
    const managed = await this.getManagedDriverIds(userId);
    if (!managed.includes(driverId)) {
      throw new ForbiddenException(CommonErrors.FORBIDDEN);
    }
    return true;
  }

  async getMyWallet(userId: string) {
    const manager = await this.getManager(userId);

    const transactions = await this.prisma.driverManagerWalletTransaction.findMany({
      where: { managerId: manager.id },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    return {
      walletBalance: manager.walletBalance,
      transactions,
    };
  }

  async getTransactions(userId: string, page = 1, limit = 20) {
    const manager = await this.getManager(userId);

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.driverManagerWalletTransaction.findMany({
        where: { managerId: manager.id },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.driverManagerWalletTransaction.count({
        where: { managerId: manager.id },
      }),
    ]);

    return {
      walletBalance: manager.walletBalance,
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async assignDrivers(body: {
    driverManagerUserId: string;
    driverIds?: string[];
    manageAllDrivers?: boolean;
  }) {
    const manager = await this.prisma.driverManager.findUnique({
      where: { userId: body.driverManagerUserId },
    });
    if (!manager) throw new NotFoundException('Driver manager not found');

    if (body.manageAllDrivers) {
      await this.prisma.$transaction(async (tx) => {
        await tx.driverManager.update({
          where: { id: manager.id },
          data: { manageAllDrivers: true },
        });
        await tx.driverManagerAssignment.deleteMany({
          where: { driverManagerId: manager.id },
        });
      });
      return { success: true, manageAllDrivers: true };
    }

    if (!body.driverIds || body.driverIds.length === 0) {
      throw new BadRequestException('driverIds required');
    }

    const existing = await this.prisma.driverManagerAssignment.findMany({
      where: {
        driverId: { in: body.driverIds },
        driverManagerId: { not: manager.id },
      },
    });
    if (existing.length > 0) {
      throw new ForbiddenException(CommonErrors.FORBIDDEN);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.driverManager.update({
        where: { id: manager.id },
        data: { manageAllDrivers: false },
      });
      await tx.driverManagerAssignment.deleteMany({
        where: { driverManagerId: manager.id },
      });
      await tx.driverManagerAssignment.createMany({
        data: (body.driverIds || []).map((driverId) => ({
          driverManagerId: manager.id,
          driverId,
        })),
        skipDuplicates: true,
      });
    });

    return { success: true, assignedCount: body.driverIds.length };
  }

  async getManagerDrivers(driverManagerUserId: string) {
    const manager = await this.prisma.driverManager.findUnique({
      where: { userId: driverManagerUserId },
      include: {
        assignedDrivers: {
          include: {
            driver: {
              include: {
                user: {
                  select: {
                    id: true,
                    name: true,
                    email: true,
                    phone: true,
                    avatar: true,
                  },
                },
              },
            },
          },
        },
      },
    });
    if (!manager) throw new NotFoundException('Driver manager not found');
    if (manager.manageAllDrivers) {
      const drivers = await this.prisma.driver.findMany({
        where: { deletedAt: null },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              avatar: true,
            },
          },
        },
      });
      return { manageAllDrivers: true, drivers };
    }
    return {
      manageAllDrivers: false,
      drivers: manager.assignedDrivers.map((a) => a.driver),
    };
  }
}
