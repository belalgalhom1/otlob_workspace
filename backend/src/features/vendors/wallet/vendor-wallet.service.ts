import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { QueryVendorWalletDto } from './dto/vendor-wallet.dto';
import { VendorErrors } from 'src/common/constants/response.constants';
import { Prisma } from '@prisma/client';
import {
  parseDateEnd,
  parseDateStart,
} from 'src/common/utils/timezone';

@Injectable()
export class VendorWalletService {
  private readonly logger = new Logger(VendorWalletService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns the current wallet balance for the vendor.
   * Balance is maintained on the Vendor row itself and is the
   * authoritative source — transactions contain balanceAfter snapshots
   * for historical accuracy but the Vendor.walletBalance is always current.
   */
  async getBalance(vendorId: string) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, deletedAt: null },
      select: { id: true, walletBalance: true },
    });

    if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);

    return { walletBalance: vendor.walletBalance };
  }

  /**
   * Paginated transaction history with optional type and date range filters.
   * Transactions are read-only from the API — they are created internally
   * by order processing logic only.
   */
  async listTransactions(vendorId: string, dto: QueryVendorWalletDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    // Confirm vendor exists first so we return 404 rather than an empty list.
    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, deletedAt: null },
      select: { id: true, walletBalance: true },
    });
    if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);

    const where: Prisma.VendorWalletTransactionWhereInput = { vendorId };

    if (dto.type) where.type = dto.type;

    if (dto.from || dto.to) {
      // Date-only filters mean whole app-timezone days; full ISO instants
      // pass through untouched.
      where.createdAt = {};
      if (dto.from) where.createdAt.gte = parseDateStart(dto.from);
      if (dto.to) where.createdAt.lte = parseDateEnd(dto.to);
    }

    const [transactions, total] = await Promise.all([
      this.prisma.vendorWalletTransaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          order: {
            select: { id: true, orderNumber: true },
          },
        },
      }),
      this.prisma.vendorWalletTransaction.count({ where }),
    ]);

    return {
      walletBalance: vendor.walletBalance,
      transactions,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
