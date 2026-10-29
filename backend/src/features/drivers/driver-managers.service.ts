import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { CommonErrors, DriverErrors, UserErrors } from '../../common/constants/response.constants';
import { AssignDriversToManagerDto } from './dto/driver-manager.dto';

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

  async listManagers() {
    const users = await this.prisma.user.findMany({
      where: { role: 'DRIVER_MANAGER', deletedAt: null },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatar: true,
        createdAt: true,
        driverManager: {
          select: {
            id: true,
            walletBalance: true,
            manageAllDrivers: true,
            zoneId: true,
            zone: {
              select: {
                id: true,
                name: true,
                nameAr: true,
              },
            },
            assignedDrivers: {
              select: {
                driverId: true,
                driver: {
                  select: {
                    id: true,
                    name: true,
                    status: true,
                    user: {
                      select: {
                        name: true,
                        phone: true,
                        email: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return users.map((u) => {
      const dm = u.driverManager;
      return {
        id: dm?.id ?? null,
        userId: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        avatar: u.avatar,
        walletBalance: dm?.walletBalance ?? 0,
        manageAllDrivers: dm?.manageAllDrivers ?? false,
        zoneId: dm?.zoneId ?? null,
        zone: dm?.zone ?? null,
        assignedCount: dm?.assignedDrivers?.length ?? 0,
        assignedDrivers: (dm?.assignedDrivers ?? []).map((a) => ({
          driverId: a.driverId,
          name: a.driver.name,
          status: a.driver.status,
          phone: a.driver.user?.phone,
        })),
        createdAt: u.createdAt,
      };
    });
  }

  async getManagerDetails(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatar: true,
        role: true,
        createdAt: true,
        driverManager: {
          select: {
            id: true,
            walletBalance: true,
            manageAllDrivers: true,
            zoneId: true,
            zone: {
              select: {
                id: true,
                name: true,
                nameAr: true,
              },
            },
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
        },
      },
    });

    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    let dm: any = user.driverManager;
    if (!dm && user.role === 'DRIVER_MANAGER') {
      dm = await this.prisma.driverManager.create({
        data: { userId: user.id },
        include: {
          zone: {
            select: {
              id: true,
              name: true,
              nameAr: true,
            },
          },
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
    }

    if (!dm) throw new NotFoundException('Driver manager not found');

    let drivers = (dm.assignedDrivers || []).map((a: any) => a.driver);
    if (dm.manageAllDrivers) {
      drivers = await this.prisma.driver.findMany({
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
    }

    return {
      userId: user.id,
      managerId: dm.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
      walletBalance: dm.walletBalance,
      manageAllDrivers: dm.manageAllDrivers,
      zone: dm.zone,
      assignedCount: drivers.length,
      drivers,
    };
  }

  async assignDrivers(body: AssignDriversToManagerDto) {
    let manager = await this.prisma.driverManager.findUnique({
      where: { userId: body.driverManagerUserId },
    });
    if (!manager) {
      const user = await this.prisma.user.findUnique({
        where: { id: body.driverManagerUserId },
        select: { role: true },
      });
      if (user?.role === 'DRIVER_MANAGER') {
        manager = await this.prisma.driverManager.create({
          data: { userId: body.driverManagerUserId },
        });
      }
    }
    if (!manager) throw new NotFoundException('Driver manager not found');

    if (body.manageAllDrivers) {
      await this.prisma.$transaction(async (tx) => {
        await tx.driverManager.update({
          where: { id: manager!.id },
          data: { manageAllDrivers: true },
        });
        await tx.driverManagerAssignment.deleteMany({
          where: { driverManagerId: manager!.id },
        });
      });
      return { success: true, manageAllDrivers: true, assignedCount: 0 };
    }

    const driverIds = body.driverIds ?? [];

    await this.prisma.$transaction(async (tx) => {
      await tx.driverManager.update({
        where: { id: manager!.id },
        data: { manageAllDrivers: false },
      });
      // Delete existing assignments for these drivers from ANY manager (reassigning cleanly)
      if (driverIds.length > 0) {
        await tx.driverManagerAssignment.deleteMany({
          where: { driverId: { in: driverIds } },
        });
      }
      // Delete all prior assignments of this manager
      await tx.driverManagerAssignment.deleteMany({
        where: { driverManagerId: manager!.id },
      });
      // Insert new assignments
      if (driverIds.length > 0) {
        await tx.driverManagerAssignment.createMany({
          data: driverIds.map((driverId) => ({
            driverManagerId: manager!.id,
            driverId,
          })),
          skipDuplicates: true,
        });
      }
    });

    return {
      success: true,
      manageAllDrivers: false,
      assignedCount: driverIds.length,
    };
  }

  async unassignDrivers(driverManagerUserId: string, driverIds: string[]) {
    const manager = await this.prisma.driverManager.findUnique({
      where: { userId: driverManagerUserId },
    });
    if (!manager) throw new NotFoundException('Driver manager not found');

    await this.prisma.driverManagerAssignment.deleteMany({
      where: {
        driverManagerId: manager.id,
        driverId: { in: driverIds },
      },
    });

    return { success: true, unassignedCount: driverIds.length };
  }

  async getManagerDrivers(driverManagerUserId: string) {
    const details = await this.getManagerDetails(driverManagerUserId);
    return {
      manageAllDrivers: details.manageAllDrivers,
      drivers: details.drivers,
    };
  }
}
