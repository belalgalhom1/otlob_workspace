import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  WalletErrors,
  DriverErrors,
} from 'src/common/constants/response.constants';
import {
  CreateMobileWalletDto,
  CreateWalletTopUpDto,
  ReviewWalletTopUpDto,
  ProcessManualTransactionDto,
} from './dto/wallet.dto';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { VendorTransactionType, WalletTransactionType } from '@prisma/client';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { CommonSuccess } from 'src/common/constants/response.constants';
import { DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { DriverStatus } from '@prisma/client';

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly storage: StorageService,
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
    const driver = await this.getDriver(driverUserId);

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

    const request = await this.prisma.walletTopUpRequest.create({
      data: {
        driverId: driver.id,
        platformWalletId: platformWallet.id,
        amount: dto.amount,
        receiptUrl: dto.receiptUrl,
        status: 'PENDING',
      },
    });

    return request;
  }

  async getMyTopUpRequests(driverUserId: string) {
    const driver = await this.getDriver(driverUserId);
    return this.prisma.walletTopUpRequest.findMany({
      where: { driverId: driver.id },
      include: { platformWallet: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async uploadReceipt(file: Express.Multer.File) {
    const receiptUrl = await this.storage.upload(file, 'receipts');
    return { receiptUrl, message: CommonSuccess.RESOURCE_UPDATED };
  }

  // ─── Admin: Review Top-Ups ────────────────────────────────────────────────

  async getPendingTopUpRequests() {
    return this.prisma.walletTopUpRequest.findMany({
      where: { status: 'PENDING' },
      include: {
        driver: {
          include: { user: { select: { id: true, name: true, phone: true } } },
        },
        platformWallet: true,
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async reviewTopUpRequest(
    actorUserId: string,
    requestId: string,
    dto: ReviewWalletTopUpDto,
  ) {
    const request = await this.prisma.walletTopUpRequest.findUnique({
      where: { id: requestId },
      include: { driver: true },
    });

    if (!request) throw new NotFoundException(WalletErrors.REQUEST_NOT_FOUND);
    if (request.status !== 'PENDING')
      throw new BadRequestException(WalletErrors.REQUEST_ALREADY_PROCESSED);

    const result = await this.prisma.$transaction(async (tx) => {
      const updatedCount = await tx.walletTopUpRequest.updateMany({
        where: { id: requestId, status: 'PENDING' },
        data: { status: dto.status, approvedById: actorUserId },
      });

      if (updatedCount.count === 0) {
        throw new BadRequestException(WalletErrors.REQUEST_ALREADY_PROCESSED);
      }

      const updated = await tx.walletTopUpRequest.findUnique({
        where: { id: requestId },
      });

      if (dto.status === 'APPROVED') {
        // Update driver's total wallet balance FIRST
        const updatedDriver = await tx.driver.update({
          where: { id: request.driverId },
          data: { walletBalance: { increment: request.amount } },
          select: { walletBalance: true, userId: true, status: true },
        });

        // Verify if they still owe too much
        const settings = await tx.platformSetting.findFirst();
        const maxNegative = settings?.maxNegativeDriverBalance ?? 500;
        const isStillNegative = updatedDriver.walletBalance < -maxNegative;

        // Unblock the driver ONLY if they cleared their negative threshold AND were financially locked!
        let statusUpdate = {};
        if (
          !isStillNegative &&
          request.driver?.status === DriverStatus.SUSPENDED &&
          request.driver?.hasUnpaidCommission
        ) {
          statusUpdate = { status: DriverStatus.OFFLINE };
        }

        const cycleData = isStillNegative
          ? {} // Still in debt — do NOT restart the settlement counter so the settle flow stays blocked
          : { ordersSinceSettlement: 0 }; // Restart the settlement cycle only after the debt is cleared

        await tx.driver.update({
          where: { id: request.driverId },
          data: {
            hasUnpaidCommission: isStillNegative, // Keep them locked if they still owe
            ...cycleData,
            ...statusUpdate,
          },
        });

        // Also add a positive wallet transaction for the payment amount
        await tx.driverWalletTransaction.create({
          data: {
            driverId: request.driverId,
            type: 'ADJUSTMENT', // Or we could add a TOP_UP enum
            amount: request.amount,
            balanceAfter: updatedDriver.walletBalance,
            description: 'Approved Top-up transfer',
            referenceId: request.id,
          },
        });
      }

      return updated;
    });

    // Send notifications after transaction succeeds
    if (dto.status === 'APPROVED') {
      const settings = await this.prisma.platformSetting.findFirst();
      const maxNegative = settings?.maxNegativeDriverBalance ?? 500;

      const updatedDriver = await this.prisma.driver.findUnique({
        where: { id: request.driverId },
        select: { walletBalance: true, status: true },
      });

      const isNowUnlocked = (updatedDriver?.walletBalance ?? 0) >= -maxNegative;

      if (request.driver?.hasUnpaidCommission && isNowUnlocked) {
        const wasSuspended = request.driver?.status === DriverStatus.SUSPENDED;
        this.eventEmitter.emit(
          EVENTS.DRIVER_STATUS_CHANGED,
          new DriverStatusChangedEvent(
            request.driver.id,
            request.driver.userId,
            wasSuspended
              ? DriverStatus.SUSPENDED
              : (request.driver?.status ?? DriverStatus.ONLINE),
            updatedDriver?.status ?? DriverStatus.OFFLINE,
            'UNPAID_COMMISSION_SETTLED',
          ),
        );
      }
    }

    return {
      message: CommonSuccess.RESOURCE_UPDATED,
      data: result,
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

    return this.prisma.$transaction(async (tx) => {
      const updatedVendor = await tx.vendor.update({
        where: { id: vendorId },
        data: { walletBalance: { increment: dto.amount } },
        select: { walletBalance: true },
      });

      return tx.vendorWalletTransaction.create({
        data: {
          vendorId,
          type: type as VendorTransactionType,
          amount: dto.amount,
          balanceAfter: updatedVendor.walletBalance,
          description: dto.description || 'Manual Admin Transaction',
          orderId,
          referenceId,
        },
      });
    });
  }

  async processDriverTransaction(
    driverId: string,
    dto: ProcessManualTransactionDto,
  ) {
    const driver = await this.prisma.driver.findUnique({
      where: { id: driverId },
    });
    if (!driver) throw new NotFoundException(WalletErrors.DRIVER_NOT_FOUND);

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

    return this.prisma.$transaction(async (tx) => {
      const updatedDriver = await tx.driver.update({
        where: { id: driverId },
        data: { walletBalance: { increment: dto.amount } },
        select: { walletBalance: true },
      });

      return tx.driverWalletTransaction.create({
        data: {
          driverId,
          type: type as WalletTransactionType,
          amount: dto.amount,
          balanceAfter: updatedDriver.walletBalance,
          description: dto.description || 'Manual Admin Transaction',
          orderId,
          referenceId,
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
    return this.prisma.driverWalletTransaction.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    });
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
      select: { id: true, vendorId: true, driverId: true },
    });

    if (
      order &&
      (ownerType === 'vendor'
        ? order.vendorId === ownerId
        : order.driverId === ownerId)
    ) {
      return { orderId: order.id, referenceId: null };
    }

    return { orderId: null, referenceId: reference };
  }

  private async getDriver(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
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
