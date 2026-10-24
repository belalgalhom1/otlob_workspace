import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DriverErrors } from '../../common/constants/response.constants';

@Injectable()
export class DriverManagersService {
  constructor(private readonly prisma: PrismaService) {}

  private async getManager(userId: string) {
    let manager = await this.prisma.driverManager.findUnique({
      where: { userId },
      select: { id: true, walletBalance: true },
    });
    if (!manager) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { role: true },
      });
      if (user && user.role === 'DRIVER_MANAGER') {
        manager = await this.prisma.driverManager.create({
          data: { userId },
          select: { id: true, walletBalance: true },
        });
      }
    }
    if (!manager) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }
    return manager;
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
}
