import { Controller, Get, Query, Param } from '@nestjs/common';
import { VendorWalletService } from './vendor-wallet.service';
import { QueryVendorWalletDto } from './dto/vendor-wallet.dto';
import { VendorMember } from '../../../common/decorators/vendor-member.decorator';
import { RequirePermissions } from '../../../common/decorators/permissions.decorator';
import { Permission } from '@prisma/client';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ApiStandardResponse } from '../../../common/decorators/api-response.decorator';

@ApiTags('Vendors - Wallet & Transactions')
@ApiBearerAuth()
@Controller('vendors/:vendorId/wallet')
export class VendorWalletController {
  constructor(private readonly service: VendorWalletService) {}

  // The wallet belongs to the vendor. Any member of that vendor can read the
  // same balance and ledger; there is no per-member wallet.
  @ApiStandardResponse()
  @Get('balance')
  @VendorMember()
  @ApiOperation({ summary: "Get the vendor's wallet balance (any member)" })
  getBalance(@Param('vendorId') vendorId: string) {
    return this.service.getBalance(vendorId);
  }

  // Any vendor member can see transaction history.
  @ApiStandardResponse()
  @Get('transactions')
  @VendorMember()
  @ApiOperation({ summary: "List the vendor's wallet transactions (any member)" })
  listTransactions(
    @Param('vendorId') vendorId: string,
    @Query() dto: QueryVendorWalletDto,
  ) {
    return this.service.listTransactions(vendorId, dto);
  }

  // Aggregated totals (credits, debits, net, per-type) for the same filters.
  @ApiStandardResponse()
  @Get('summary')
  @VendorMember()
  @ApiOperation({ summary: "Get the vendor's wallet summary (any member)" })
  getSummary(
    @Param('vendorId') vendorId: string,
    @Query() dto: QueryVendorWalletDto,
  ) {
    return this.service.getSummary(vendorId, dto);
  }

  // Admin can view any vendor's wallet.
  @ApiStandardResponse()
  @Get('admin/balance')
  @RequirePermissions(Permission.VIEW_FINANCIALS, Permission.MANAGE_FINANCE, {
    mode: 'any',
  })
  @ApiOperation({ summary: "Get any vendor's wallet balance (Admin)" })
  adminGetBalance(@Param('vendorId') vendorId: string) {
    return this.service.getBalance(vendorId);
  }

  @ApiStandardResponse()
  @Get('admin/transactions')
  @RequirePermissions(Permission.VIEW_FINANCIALS, Permission.MANAGE_FINANCE, {
    mode: 'any',
  })
  @ApiOperation({ summary: "List any vendor's wallet transactions (Admin)" })
  adminListTransactions(
    @Param('vendorId') vendorId: string,
    @Query() dto: QueryVendorWalletDto,
  ) {
    return this.service.listTransactions(vendorId, dto);
  }

  @ApiStandardResponse()
  @Get('admin/summary')
  @RequirePermissions(Permission.VIEW_FINANCIALS, Permission.MANAGE_FINANCE, {
    mode: 'any',
  })
  @ApiOperation({ summary: "Get any vendor's wallet summary statistics (Admin)" })
  adminGetSummary(
    @Param('vendorId') vendorId: string,
    @Query() dto: QueryVendorWalletDto,
  ) {
    return this.service.getSummary(vendorId, dto);
  }
}
