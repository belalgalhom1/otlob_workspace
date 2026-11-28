import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverManagerTransactionType } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import {
  CommonSuccess,
  DriverErrors,
  UserErrors,
  DriverManagerErrors,
} from '../../common/constants/response.constants';
import {
  assertDriverManagerOwnsDriver,
  ensureDriverManagerRecord,
} from '../../common/drivers/driver-manager-auth.helper';
import {
  EVENTS,
  DriverManagerPayoutCompletedEvent,
} from '../../common/events';
import {
  AssignDriversToManagerDto,
  ProcessDriverManagerPayoutDto,
} from './dto/driver-manager.dto';

@Injectable()
export class DriverManagersService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly storage?: StorageService,
    @Optional() private readonly eventEmitter?: EventEmitter2,
  ) {}

  private async getManager(userId: string) {
    const manager = await ensureDriverManagerRecord(this.prisma, userId);
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
    return assertDriverManagerOwnsDriver(this.prisma, userId, driverId, {
      throwNotFoundIfNoManager: true,
    });
  }

  async getMyWallet(userId: string) {
    const manager = await this.getManager(userId);

    const transactions =
      await this.prisma.driverManagerWalletTransaction.findMany({
        where: { managerId: manager.id },
        include: {
          order: { select: { id: true, orderNumber: true } },
          processedBy: { select: { id: true, name: true } },
        },
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

    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (safePage - 1) * safeLimit;
    const [data, total] = await Promise.all([
      this.prisma.driverManagerWalletTransaction.findMany({
        where: { managerId: manager.id },
        include: {
          order: { select: { id: true, orderNumber: true } },
          processedBy: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: safeLimit,
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
        page: safePage,
        limit: safeLimit,
        totalPages: Math.ceil(total / safeLimit),
      },
    };
  }

  async getTransactionsByUserId(userId: string, page = 1, limit = 20) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatar: true,
        role: true,
      },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    const manager = await ensureDriverManagerRecord(this.prisma, userId);
    if (!manager) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);

    const result = await this.getTransactions(userId, page, limit);
    return {
      ...result,
      manager: {
        userId: user.id,
        managerId: manager.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
      },
    };
  }

  async uploadPayoutReceipt(file: Express.Multer.File) {
    if (!this.storage) {
      throw new BadRequestException('Storage service unavailable');
    }
    const receiptUrl = await this.storage.upload(file, 'receipts');
    return { receiptUrl, message: CommonSuccess.RESOURCE_UPDATED };
  }

  async processPayout(
    managerUserId: string,
    dto: ProcessDriverManagerPayoutDto,
    actorUserId: string,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: managerUserId },
      select: { id: true, name: true, role: true },
    });
    if (!user) throw new NotFoundException(UserErrors.USER_NOT_FOUND);

    const manager = await ensureDriverManagerRecord(this.prisma, managerUserId);
    if (!manager) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);

    const trimmedReceiptUrl = (dto.receiptUrl ?? '').trim() || null;
    const trimmedDescription = (dto.description ?? '').trim() || null;
    const idempotencyKey = (dto.idempotencyKey ?? '').trim() || null;
    const settleFull = dto.settleFullBalance === true || dto.amount == null;

    if (!settleFull) {
      const requested = Number(dto.amount);
      if (!Number.isInteger(requested) || requested <= 0) {
        throw new BadRequestException(
          DriverManagerErrors.INVALID_PAYOUT_AMOUNT,
        );
      }
    }

    const result = await this.prisma.$transaction(async (tx) => {
      if (idempotencyKey) {
        const existingTx =
          await tx.driverManagerWalletTransaction.findUnique({
            where: {
              managerId_idempotencyKey: {
                managerId: manager.id,
                idempotencyKey,
              },
            },
            include: {
              processedBy: { select: { id: true, name: true } },
            },
          });
        if (existingTx) {
          const freshManager = await tx.driverManager.findUnique({
            where: { id: manager.id },
            select: { walletBalance: true },
          });
          return {
            duplicate: true,
            transaction: existingTx,
            walletBalance: freshManager?.walletBalance ?? existingTx.balanceAfter,
            paidAmount: Math.abs(existingTx.amount),
          };
        }
      }

      const fresh = await tx.driverManager.findUnique({
        where: { id: manager.id },
        select: { id: true, walletBalance: true },
      });
      if (!fresh) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);

      const payoutAmount = settleFull
        ? fresh.walletBalance
        : Math.round(Number(dto.amount));

      if (payoutAmount <= 0) {
        throw new BadRequestException(
          settleFull
            ? DriverManagerErrors.NO_BALANCE_TO_SETTLE
            : DriverManagerErrors.INVALID_PAYOUT_AMOUNT,
        );
      }

      if (payoutAmount > fresh.walletBalance) {
        throw new BadRequestException(
          DriverManagerErrors.INSUFFICIENT_BALANCE,
        );
      }

      // Atomic guarded decrement to prevent concurrent double-payout races
      const updatedCount = await tx.driverManager.updateMany({
        where: {
          id: manager.id,
          walletBalance: { gte: payoutAmount },
        },
        data: {
          walletBalance: { decrement: payoutAmount },
        },
      });
      if (updatedCount.count === 0) {
        throw new BadRequestException(
          DriverManagerErrors.INSUFFICIENT_BALANCE,
        );
      }

      const after = await tx.driverManager.findUnique({
        where: { id: manager.id },
        select: { walletBalance: true },
      });
      const newBalance = after?.walletBalance ?? fresh.walletBalance - payoutAmount;

      const defaultDescription = settleFull
        ? `Full wallet settlement payout (${payoutAmount} EGP)`
        : `Wallet payout (${payoutAmount} EGP)`;

      const transaction = await tx.driverManagerWalletTransaction.create({
        data: {
          managerId: manager.id,
          type: DriverManagerTransactionType.PAYOUT,
          amount: -payoutAmount,
          balanceAfter: newBalance,
          description: trimmedDescription ?? defaultDescription,
          receiptUrl: trimmedReceiptUrl,
          processedById: actorUserId,
          ...(idempotencyKey ? { idempotencyKey } : {}),
        },
        include: {
          processedBy: { select: { id: true, name: true } },
        },
      });

      return {
        duplicate: false,
        transaction,
        walletBalance: newBalance,
        paidAmount: payoutAmount,
      };
    });

    if (!result.duplicate) {
      this.eventEmitter?.emit(
        EVENTS.DRIVER_MANAGER_PAYOUT_COMPLETED,
        new DriverManagerPayoutCompletedEvent(
          result.transaction.id,
          manager.id,
          user.id,
          user.name ?? 'Driver Manager',
          result.paidAmount,
          result.walletBalance,
          trimmedReceiptUrl,
          trimmedDescription,
          actorUserId,
        ),
      );
    }

    return {
      transaction: result.transaction,
      walletBalance: result.walletBalance,
      paidAmount: result.paidAmount,
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
                    avatar: true,
                    status: true,
                    user: {
                      select: {
                        name: true,
                        phone: true,
                        email: true,
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
          avatar: a.driver.avatar ?? a.driver.user?.avatar ?? null,
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

    if (!dm) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);

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
    const manager = await ensureDriverManagerRecord(
      this.prisma,
      body.driverManagerUserId,
    );
    if (!manager) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);
    const managerId = manager.id;

    if (body.manageAllDrivers) {
      await this.prisma.$transaction(async (tx) => {
        await tx.driverManager.update({
          where: { id: managerId },
          data: { manageAllDrivers: true },
        });
        await tx.driverManagerAssignment.deleteMany({
          where: { driverManagerId: managerId },
        });
      });
      return { success: true, manageAllDrivers: true, assignedCount: 0 };
    }

    const driverIds = body.driverIds ?? [];

    await this.prisma.$transaction(async (tx) => {
      await tx.driverManager.update({
        where: { id: managerId },
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
        where: { driverManagerId: managerId },
      });
      // Insert new assignments
      if (driverIds.length > 0) {
        await tx.driverManagerAssignment.createMany({
          data: driverIds.map((driverId) => ({
            driverManagerId: managerId,
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
    if (!manager) throw new NotFoundException(DriverManagerErrors.NOT_FOUND);

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
