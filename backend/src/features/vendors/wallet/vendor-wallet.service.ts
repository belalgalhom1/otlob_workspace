import { Injectable, NotFoundException } from '@nestjs/common';
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

    const where = this.buildWhere(vendorId, dto);

    const [transactions, total] = await Promise.all([
      this.prisma.vendorWalletTransaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          order: {
            select: {
              id: true,
              orderNumber: true,
              vendorBranchId: true,
              vendorBranch: {
                select: { id: true, name: true, nameAr: true },
              },
            },
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

  /**
   * Aggregate wallet statistics for the same filters as the transaction list.
   * Amounts are signed in the ledger (credits positive, debits negative), so
   * the totals are derived from the sign rather than hard-coded types. This
   * keeps new transaction types working without changing the query.
   */
  async getSummary(vendorId: string, dto: QueryVendorWalletDto) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, deletedAt: null },
      select: { id: true, walletBalance: true },
    });
    if (!vendor) throw new NotFoundException(VendorErrors.NOT_FOUND);

    const where = this.buildWhere(vendorId, dto);

    const [creditAgg, debitAgg, groups] = await Promise.all([
      this.prisma.vendorWalletTransaction.aggregate({
        where: { ...where, amount: { gt: 0 } },
        _sum: { amount: true },
        _count: { _all: true },
      }),
      this.prisma.vendorWalletTransaction.aggregate({
        where: { ...where, amount: { lt: 0 } },
        _sum: { amount: true },
        _count: { _all: true },
      }),
      this.prisma.vendorWalletTransaction.groupBy({
        by: ['type'],
        where,
        _sum: { amount: true },
        _count: { _all: true },
      }),
    ]);

    const totalCredits = creditAgg._sum.amount ?? 0;
    const totalDebits = Math.abs(debitAgg._sum.amount ?? 0);

    return {
      walletBalance: vendor.walletBalance,
      totalCredits,
      totalDebits,
      netChange: totalCredits - totalDebits,
      // Sum the per-type counts so zero-amount rows are included too.
      // (creditAgg/debitAgg only count strictly positive/negative amounts.)
      transactionCount: groups.reduce(
        (sum, g) => sum + (g._count._all ?? 0),
        0,
      ),
      byType: groups
        .map((g) => ({
          type: g.type,
          count: g._count._all ?? 0,
          total: g._sum.amount ?? 0,
        }))
        .sort((a, b) => Math.abs(b.total) - Math.abs(a.total)),
      from: dto.from ?? null,
      to: dto.to ?? null,
    };
  }

  private buildWhere(
    vendorId: string,
    dto: QueryVendorWalletDto,
  ): Prisma.VendorWalletTransactionWhereInput {
    const where: Prisma.VendorWalletTransactionWhereInput = { vendorId };

    if (dto.type) where.type = dto.type;

    if (dto.branchId) {
      where.order = {
        OR: [
          { vendorBranchId: dto.branchId },
          { fulfillments: { some: { vendorBranchId: dto.branchId } } },
        ],
      };
    }

    if (dto.from || dto.to) {
      // Date-only filters mean whole app-timezone days; full ISO instants
      // pass through untouched.
      where.createdAt = {};
      if (dto.from) where.createdAt.gte = parseDateStart(dto.from);
      if (dto.to) where.createdAt.lte = parseDateEnd(dto.to);
    }

    return where;
  }
}
