import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  WalletErrors,
  DriverErrors,
  CommonErrors,
} from 'src/common/constants/response.constants';
import {
  CreateMobileWalletDto,
  CreateWalletTopUpDto,
  ReviewWalletTopUpDto,
  ProcessManualTransactionDto,
} from './dto/wallet.dto';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  VendorTransactionType,
  WalletTransactionType,
  Prisma,
  Role,
} from '@prisma/client';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { CommonSuccess } from 'src/common/constants/response.constants';
import {
  DriverStatusChangedEvent,
  WalletTopUpReviewedEvent,
  WalletTopUpSubmittedEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { DriverStatus } from '@prisma/client';
import { DriverManagersService } from '../drivers/driver-managers.service';
import {
  DRIVER_WALLET_TX_SELECT,
  sanitizeDriverWalletTransactionForDriver,
} from './helpers/driver-wallet-tx.helper';

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly storage: StorageService,
    private readonly driverManagersService: DriverManagersService,
  ) {}

  // ─── Admin: Manage Platform Wallets ───────────────────────────────────────

  async createPlatformWallet(dto: CreateMobileWalletDto) {
    return this.prisma.mobileWallet.create({
      data: {
        number: dto.number,
        type: dto.type,
        isActive: dto.isActive ?? true,
        isPlatform: true,
      },
    });
  }

  async getPlatformWallets(includeInactive = false) {
    return this.prisma.mobileWallet.findMany({
      where: {
        isPlatform: true,
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updatePlatformWallet(id: string, dto: Partial<CreateMobileWalletDto>) {
    const wallet = await this.prisma.mobileWallet.findUnique({
      where: { id, isPlatform: true },
    });
    if (!wallet)
      throw new NotFoundException(WalletErrors.PLATFORM_WALLET_NOT_FOUND);

    return this.prisma.mobileWallet.update({
      where: { id },
      data: dto,
    });
  }

  // ─── Driver: Personal Wallets ─────────────────────────────────────────────

  async addDriverWallet(driverUserId: string, dto: CreateMobileWalletDto) {
    const driver = await this.getDriver(driverUserId);
    return this.prisma.mobileWallet.create({
      data: {
        number: dto.number,
        type: dto.type,
        isActive: dto.isActive ?? true,
        isPlatform: false,
        driverId: driver.id,
      },
    });
  }

  async getDriverWallets(driverUserId: string) {
    const driver = await this.getDriver(driverUserId);
    return this.prisma.mobileWallet.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ─── Driver: Top-Up Requests ──────────────────────────────────────────────

  async submitTopUpRequest(driverUserId: string, dto: CreateWalletTopUpDto) {
    const driver = await this.getDriver(driverUserId, true);

    const platformWallet = await this.prisma.mobileWallet.findUnique({
      where: { id: dto.platformWalletId, isPlatform: true, isActive: true },
    });
    if (!platformWallet)
      throw new NotFoundException(
        WalletErrors.PLATFORM_WALLET_NOT_FOUND_OR_INACTIVE,
      );

    // Prevent duplicate PENDING requests for the same driver — approving two
    // requests would credit the wallet twice for the same top-up.
    const existingPending = await this.prisma.walletTopUpRequest.findFirst({
      where: { driverId: driver.id, status: 'PENDING' },
    });
    if (existingPending) {
      throw new BadRequestException(WalletErrors.DUPLICATE_PENDING_REQUEST);
    }

    try {
      const request = await this.prisma.walletTopUpRequest.create({
        data: {
          driverId: driver.id,
          platformWalletId: platformWallet.id,
          amount: dto.amount,
          receiptUrl: dto.receiptUrl,
          status: 'PENDING',
        },
      });

      const driverName =
        (driver as { user?: { name?: string | null }; name?: string | null })
          .user?.name ||
        (driver as { name?: string | null }).name ||
        'Driver';

      this.eventEmitter.emit(
        EVENTS.WALLET_TOPUP_SUBMITTED,
        new WalletTopUpSubmittedEvent(
          request.id,
          driver.id,
          driver.userId,
          driverName,
          request.amount,
          platformWallet.type,
          platformWallet.number,
          request.receiptUrl,
        ),
      );

      return request;
    } catch (e: any) {
      // Lost a concurrent submit race against the partial unique index:
      // a PENDING request already exists.
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new BadRequestException(WalletErrors.DUPLICATE_PENDING_REQUEST);
      }
      throw e;
    }
  }

  async getMyTopUpRequests(driverUserId: string) {
    const driver = await this.getDriver(driverUserId);
    return this.prisma.walletTopUpRequest.findMany({
      where: { driverId: driver.id },
      include: {
        platformWallet: true,
        approvedBy: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async uploadReceipt(file: Express.Multer.File) {
    const receiptUrl = await this.storage.upload(file, 'receipts');
    return { receiptUrl, message: CommonSuccess.RESOURCE_UPDATED };
  }

  // ─── Admin: Review Top-Ups ────────────────────────────────────────────────

  async getPendingTopUpRequests() {
    const requests = await this.prisma.walletTopUpRequest.findMany({
      where: { status: 'PENDING' },
      include: {
        driver: {
          include: {
            user: {
              select: { id: true, name: true, phone: true, avatar: true },
            },
          },
        },
        platformWallet: true,
        approvedBy: { select: { id: true, name: true, role: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
    return requests.map((r: any) => ({
      ...r,
      driver: r.driver
        ? {
            ...r.driver,
            avatar: r.driver.avatar ?? r.driver.user?.avatar ?? null,
          }
        : r.driver,
    }));
  }

  async getTopUpRequestById(requestId: string) {
    const request: any = await this.prisma.walletTopUpRequest.findUnique({
      where: { id: requestId },
      include: {
        driver: {
          include: {
            user: {
              select: { id: true, name: true, phone: true, avatar: true },
            },
          },
        },
        platformWallet: true,
        approvedBy: { select: { id: true, name: true, role: true } },
      },
    });

    if (!request) throw new NotFoundException(WalletErrors.REQUEST_NOT_FOUND);

    return {
      ...request,
      driver: request.driver
        ? {
            ...request.driver,
            avatar:
              request.driver.avatar ?? request.driver.user?.avatar ?? null,
          }
        : request.driver,
    };
  }

  async reviewTopUpRequest(
    actorUserId: string,
    requestId: string,
    dto: ReviewWalletTopUpDto,
  ) {
    const request = await this.prisma.walletTopUpRequest.findUnique({
      where: { id: requestId },
      include: {
        platformWallet: { select: { type: true, number: true } },
      },
    });

    if (!request) throw new NotFoundException(WalletErrors.REQUEST_NOT_FOUND);
    if (request.status !== 'PENDING')
      throw new BadRequestException(WalletErrors.REQUEST_ALREADY_PROCESSED);

    const trimmedNotes = dto.notes?.trim() || null;

    const { updated, unlockNotification, driverSummary } =
      await this.prisma.$transaction(async (tx) => {
        const updatedCount = await tx.walletTopUpRequest.updateMany({
          where: { id: requestId, status: 'PENDING' },
          data: {
            status: dto.status,
            approvedById: actorUserId,
            notes: trimmedNotes,
            reviewedAt: new Date(),
          },
        });

        if (updatedCount.count === 0) {
          throw new BadRequestException(WalletErrors.REQUEST_ALREADY_PROCESSED);
        }

        const updated = await tx.walletTopUpRequest.findUnique({
          where: { id: requestId },
        });

        let unlockNotification: {
          driverId: string;
          userId: string;
          prevStatus: DriverStatus;
          nextStatus: DriverStatus;
        } | null = null;
        let driverSummary: {
          userId: string;
          name: string;
          newBalance: number | null;
        } = {
          userId: '',
          name: 'Driver',
          newBalance: null,
        };

        if (dto.status === 'APPROVED') {
          await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${request.driverId} FOR UPDATE`;

          const lockedDriver = await tx.driver.findUnique({
            where: { id: request.driverId },
            select: {
              id: true,
              userId: true,
              name: true,
              status: true,
              hasUnpaidCommission: true,
              ordersSinceSettlement: true,
              user: { select: { name: true } },
            },
          });

          const updatedDriver = await tx.driver.update({
            where: { id: request.driverId },
            data: { walletBalance: { increment: request.amount } },
            select: { walletBalance: true, userId: true, status: true },
          });

          driverSummary = {
            userId: lockedDriver?.userId ?? updatedDriver.userId ?? '',
            name:
              (lockedDriver as { user?: { name?: string | null } } | null)?.user
                ?.name ??
              lockedDriver?.name ??
              'Driver',
            newBalance: updatedDriver.walletBalance,
          };

          const settings = await tx.platformSetting.findFirst({
            select: {
              maxNegativeDriverBalance: true,
              driverSettlementOrderThreshold: true,
            },
          });
          const maxNegative = Number(settings?.maxNegativeDriverBalance ?? 500);
          const rawThreshold = settings?.driverSettlementOrderThreshold ?? 10;
          const settlementThreshold = Number.isFinite(Number(rawThreshold))
            ? Math.max(0, Number(rawThreshold))
            : 10;
          const newBalance = Number(updatedDriver.walletBalance ?? 0);
          const exceedsMaxNegative = newBalance < -maxNegative;
          const thresholdStillDue =
            settlementThreshold > 0 &&
            Number(lockedDriver?.ordersSinceSettlement ?? 0) >=
              settlementThreshold &&
            newBalance < 0;
          const isStillLocked = exceedsMaxNegative || thresholdStillDue;
          const isStillInDebt = newBalance < 0;

          let nextStatus = lockedDriver?.status ?? DriverStatus.OFFLINE;
          let statusUpdate: { status?: DriverStatus } = {};
          if (
            !exceedsMaxNegative &&
            lockedDriver?.status === DriverStatus.SUSPENDED &&
            lockedDriver?.hasUnpaidCommission
          ) {
            statusUpdate = { status: DriverStatus.OFFLINE };
            nextStatus = DriverStatus.OFFLINE;
          }

          // Restart the settlement cycle only once the debt is cleared (balance >= 0),
          // so partial payments do not prematurely reset ordersSinceSettlement.
          const cycleData = isStillInDebt ? {} : { ordersSinceSettlement: 0 };

          await tx.driver.update({
            where: { id: request.driverId },
            data: {
              hasUnpaidCommission: isStillLocked,
              ...cycleData,
              ...statusUpdate,
            },
          });

          await tx.driverWalletTransaction.create({
            data: {
              driverId: request.driverId,
              type: 'ADJUSTMENT',
              amount: request.amount,
              balanceAfter: updatedDriver.walletBalance,
              description: 'Approved Top-up transfer',
              note: trimmedNotes,
              referenceId: request.id,
              idempotencyKey: `topup:${request.id}`,
            },
          });

          if (lockedDriver?.hasUnpaidCommission && !isStillLocked) {
            unlockNotification = {
              driverId: lockedDriver.id,
              userId: lockedDriver.userId,
              prevStatus: lockedDriver.status,
              nextStatus,
            };
          }
        } else {
          const driverRow = await tx.driver?.findUnique?.({
            where: { id: request.driverId },
            select: {
              userId: true,
              name: true,
              walletBalance: true,
              user: { select: { name: true } },
            },
          });
          driverSummary = {
            userId: driverRow?.userId ?? '',
            name:
              (driverRow as { user?: { name?: string | null } } | null)?.user
                ?.name ??
              driverRow?.name ??
              'Driver',
            newBalance: driverRow?.walletBalance ?? null,
          };
        }

        return { updated, unlockNotification, driverSummary };
      });

    if (unlockNotification) {
      this.eventEmitter.emit(
        EVENTS.DRIVER_STATUS_CHANGED,
        new DriverStatusChangedEvent(
          unlockNotification.driverId,
          unlockNotification.userId,
          unlockNotification.prevStatus,
          unlockNotification.nextStatus,
          'UNPAID_COMMISSION_SETTLED',
        ),
      );
    }

    const reqWithWallet = request;

    if (driverSummary.userId) {
      this.eventEmitter.emit(
        EVENTS.WALLET_TOPUP_REVIEWED,
        new WalletTopUpReviewedEvent(
          request.id,
          request.driverId,
          driverSummary.userId,
          driverSummary.name,
          actorUserId,
          dto.status,
          request.amount,
          trimmedNotes,
          driverSummary.newBalance,
          reqWithWallet.platformWallet?.type ?? null,
          reqWithWallet.platformWallet?.number ?? null,
          Boolean(unlockNotification),
        ),
      );
    }

    return {
      message: CommonSuccess.RESOURCE_UPDATED,
      data: updated,
    };
  }

  // ─── Admin: Manual Transactions ───────────────────────────────────────────

  async processVendorTransaction(
    vendorId: string,
    dto: ProcessManualTransactionDto,
  ) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
    });
    if (!vendor) throw new NotFoundException(WalletErrors.VENDOR_NOT_FOUND);

    const type = this.normalizeVendorType(dto.type);
    if (
      !Object.values(VendorTransactionType).includes(
        type as VendorTransactionType,
      )
    ) {
      throw new BadRequestException(WalletErrors.INVALID_TRANSACTION_TYPE);
    }

    const { orderId, referenceId } = await this.resolveOrderRelation(
      dto.referenceId,
      vendorId,
      'vendor',
    );

    if (dto.idempotencyKey?.startsWith('settle:')) {
      throw new BadRequestException(WalletErrors.INVALID_TRANSACTION_TYPE);
    }
    const effectiveIdempotencyKey =
      dto.idempotencyKey ?? `admin:vendor:${vendorId}:${randomUUID()}`;

    // Idempotency: a retried/double-submitted request with the same key must
    // not create a second ledger row (or move the balance twice).
    if (dto.idempotencyKey) {
      const existing = await this.prisma.vendorWalletTransaction.findUnique({
        where: {
          vendorId_idempotencyKey: {
            vendorId,
            idempotencyKey: dto.idempotencyKey,
          },
        },
      });
      if (existing) {
        return {
          message: CommonSuccess.RESOURCE_UPDATED,
          data: existing,
        };
      }
    }

    // Guard: never allow vendor wallet balance to drop below zero (prevents overdraft debt).
    if (dto.amount < 0) {
      if (Number(vendor.walletBalance ?? 0) + dto.amount < 0) {
        throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
      }
    }

    return this.prisma.$transaction(async (tx) => {
      // Explicit row lock first to serialize concurrent manual adjustments and retries.
      const lockedRows: any = await tx.$queryRaw`
        SELECT "walletBalance" FROM "vendors" WHERE "id" = ${vendorId} FOR UPDATE
      `;
      if (dto.idempotencyKey) {
        const existingInTx = await tx.vendorWalletTransaction.findUnique({
          where: {
            vendorId_idempotencyKey: {
              vendorId,
              idempotencyKey: dto.idempotencyKey,
            },
          },
        });
        if (existingInTx) {
          return {
            message: CommonSuccess.RESOURCE_UPDATED,
            data: existingInTx,
          };
        }
      }

      if (dto.amount < 0) {
        const currentBalance = Number(lockedRows?.[0]?.walletBalance ?? 0);
        if (currentBalance + dto.amount < 0) {
          throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
        }
      }

      const updatedVendor = await tx.vendor.update({
        where: { id: vendorId },
        data: { walletBalance: { increment: dto.amount } },
        select: { walletBalance: true },
      });

      if (dto.amount < 0 && Number(updatedVendor.walletBalance) < 0) {
        throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
      }

      return tx.vendorWalletTransaction.create({
        data: {
          vendorId,
          type: type as VendorTransactionType,
          amount: dto.amount,
          balanceAfter: updatedVendor.walletBalance,
          description: dto.description || 'Manual Admin Transaction',
          orderId,
          referenceId,
          idempotencyKey: effectiveIdempotencyKey,
        },
      });
    });
  }

  async processDriverTransaction(
    driverId: string,
    dto: ProcessManualTransactionDto,
    actor?: any,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { id: driverId },
    });
    if (!driver) throw new NotFoundException(WalletErrors.DRIVER_NOT_FOUND);

    if (actor?.role === Role.DRIVER_MANAGER) {
      // A driver manager may only touch the drivers assigned to them, not any
      // driver in the platform.
      await this.driverManagersService.assertManagesDriver(actor.sub, driverId);
      const normalized = (dto.type || '').toString().toUpperCase();
      // Driver managers cannot adjust wallets - they can ONLY penalize / punish (deduct from wallet)
      if (normalized !== 'PENALTY') {
        throw new ForbiddenException(CommonErrors.FORBIDDEN);
      }
      if (dto.amount === 0) {
        throw new BadRequestException(WalletErrors.PENALTY_MUST_BE_POSITIVE);
      }
      // Force deduction (minus from wallet)
      dto.amount = -Math.abs(dto.amount);
    } else if ((dto.type || '').toString().toUpperCase() === 'PENALTY') {
      if (dto.amount === 0) {
        throw new BadRequestException(WalletErrors.PENALTY_MUST_BE_POSITIVE);
      }
      // Penalties are always deductions
      dto.amount = -Math.abs(dto.amount);
    }

    const type = this.normalizeDriverType(dto.type);
    if (
      !Object.values(WalletTransactionType).includes(
        type as WalletTransactionType,
      )
    ) {
      throw new BadRequestException(WalletErrors.INVALID_TRANSACTION_TYPE);
    }

    const { orderId, referenceId } = await this.resolveOrderRelation(
      dto.referenceId,
      driverId,
      'driver',
    );

    // Guard: never push a driver below the configured negative-balance floor
    // (prevents runaway debt from a mistaken/abusive manual debit).
    if (dto.amount < 0) {
      const settings = await this.prisma.platformSetting.findFirst();
      const maxNegative = Number(settings?.maxNegativeDriverBalance ?? 500);
      const projected = Number(driver.walletBalance ?? 0) + dto.amount;
      if (projected < -maxNegative) {
        throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
      }
    }

    if (dto.idempotencyKey?.startsWith('settle:')) {
      throw new BadRequestException(WalletErrors.INVALID_TRANSACTION_TYPE);
    }
    const effectiveIdempotencyKey =
      dto.idempotencyKey ?? `admin:driver:${driverId}:${randomUUID()}`;

    if (dto.idempotencyKey) {
      const existing = await this.prisma.driverWalletTransaction.findUnique({
        where: {
          driverId_idempotencyKey: {
            driverId,
            idempotencyKey: dto.idempotencyKey,
          },
        },
      });
      if (existing) {
        return {
          message: CommonSuccess.RESOURCE_UPDATED,
          data: existing,
        };
      }
    }

    return this.prisma.$transaction(async (tx) => {
      // Explicit row lock first to serialize concurrent manual adjustments and retries.
      const lockedRows: any = await tx.$queryRaw`
        SELECT "walletBalance" FROM "drivers" WHERE "id" = ${driverId} FOR UPDATE
      `;
      if (dto.idempotencyKey) {
        const existingInTx = await tx.driverWalletTransaction.findUnique({
          where: {
            driverId_idempotencyKey: {
              driverId,
              idempotencyKey: dto.idempotencyKey,
            },
          },
        });
        if (existingInTx) {
          return {
            message: CommonSuccess.RESOURCE_UPDATED,
            data: existingInTx,
          };
        }
      }

      if (dto.amount < 0) {
        const currentBalance = Number(lockedRows?.[0]?.walletBalance ?? 0);
        const settings = await tx.platformSetting.findFirst({
          select: { maxNegativeDriverBalance: true },
        });
        const maxNegative = Number(settings?.maxNegativeDriverBalance ?? 500);
        if (currentBalance + dto.amount < -maxNegative) {
          throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
        }
      }

      const updatedDriver = await tx.driver.update({
        where: { id: driverId },
        data: { walletBalance: { increment: dto.amount } },
        select: { walletBalance: true },
      });

      if (dto.amount < 0) {
        const settings = await tx.platformSetting.findFirst({
          select: { maxNegativeDriverBalance: true },
        });
        const maxNegative = Number(settings?.maxNegativeDriverBalance ?? 500);
        if (Number(updatedDriver.walletBalance) < -maxNegative) {
          throw new BadRequestException(WalletErrors.NEGATIVE_BALANCE_EXCEEDED);
        }
      }

      const trimmedNote = (dto.note ?? dto.description)?.trim() || null;

      return tx.driverWalletTransaction.create({
        data: {
          driverId,
          type: type as WalletTransactionType,
          amount: dto.amount,
          balanceAfter: updatedDriver.walletBalance,
          description: trimmedNote || 'Manual Admin Transaction',
          note: trimmedNote,
          isManualAdjustment: true,
          orderId,
          referenceId,
          idempotencyKey: effectiveIdempotencyKey,
        },
      });
    });
  }

  // ─── Transaction History ──────────────────────────────────────────────────

  async getVendorTransactions(vendorId: string, skip = 0, take = 50) {
    return this.prisma.vendorWalletTransaction.findMany({
      where: { vendorId },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    });
  }

  async getDriverTransactions(userId: string, skip = 0, take = 50) {
    const driver = await this.getDriver(userId);
    const transactions = await this.prisma.driverWalletTransaction.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      select: {
        ...DRIVER_WALLET_TX_SELECT,
        order: { select: { id: true, orderNumber: true } },
      },
    });
    return transactions.map((tx) =>
      sanitizeDriverWalletTransactionForDriver(tx),
    );
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /**
   * An admin-provided reference must never be stuffed into the orderId FK
   * unless it is a real order that belongs to the wallet owner. Anything else
   * is stored as a free-form reference so it cannot mark an unrelated order as
   * settled or attach a bogus ledger row to it.
   */
  private async resolveOrderRelation(
    reference: string | undefined,
    ownerId: string,
    ownerType: 'vendor' | 'driver',
  ): Promise<{ orderId: string | null; referenceId: string | null }> {
    if (!reference) return { orderId: null, referenceId: null };

    const order = await this.prisma.order.findUnique({
      where: { id: reference },
      select: {
        id: true,
        vendorFulfillments: { select: { vendorId: true } },
        deliveryGroups: {
          select: { primaryDriverId: true, assistDriverId: true },
        },
      },
    });

    if (
      order &&
      (ownerType === 'vendor'
        ? order.vendorFulfillments.some((f) => f.vendorId === ownerId)
        : order.deliveryGroups.some(
            (g) =>
              g.primaryDriverId === ownerId || g.assistDriverId === ownerId,
          ))
    ) {
      return { orderId: order.id, referenceId: null };
    }

    return { orderId: null, referenceId: reference };
  }

  private async getDriver(userId: string, includeUser = false) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      ...(includeUser
        ? { include: { user: { select: { id: true, name: true } } } }
        : {}),
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  private normalizeDriverType(type: string) {
    const map: Record<string, string> = {
      TOP_UP: 'ADJUSTMENT',
      REFUND: 'ADJUSTMENT',
      CASH_COLLECTION: 'CASH_COLLECTED',
    };
    return map[type] ?? type;
  }

  private normalizeVendorType(type: string) {
    const map: Record<string, string> = {
      TOP_UP: 'ADJUSTMENT',
      PENALTY: 'ADJUSTMENT',
      CASH_COLLECTION: 'CASH_COLLECTED',
    };
    return map[type] ?? type;
  }
}
