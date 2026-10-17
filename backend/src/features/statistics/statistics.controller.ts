import { Controller, Get, Param, Query } from '@nestjs/common';
import { StatisticsService } from './statistics.service';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { RequirePermissions } from 'src/common/decorators/permissions.decorator';
import { VendorMember } from 'src/common/decorators/vendor-member.decorator';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Permission, Role, StatisticPeriod } from '@prisma/client';
import {
  IsEnum,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsISO8601,
  ValidateIf,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';

import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';

class StatsQueryDto {
  @IsEnum(StatisticPeriod)
  @IsOptional()
  period?: StatisticPeriod = StatisticPeriod.DAILY;

  @IsInt()
  @Min(1)
  @Max(365)
  @IsOptional()
  @Type(() => Number)
  limit?: number = 30;

  @IsISO8601()
  @IsOptional()
  from?: string;

  @IsISO8601()
  @IsOptional()
  @ValidateIf((o: StatsQueryDto) => o.from !== undefined)
  to?: string;
}

class AnalyticsQueryDto {
  @IsInt()
  @Min(1)
  @Max(200)
  @IsOptional()
  @Type(() => Number)
  limit?: number = 20;

  @IsISO8601()
  @IsOptional()
  from?: string;

  @IsISO8601()
  @IsOptional()
  @ValidateIf((o: AnalyticsQueryDto) => o.from !== undefined)
  to?: string;
}

@ApiTags('Statistics')
@ApiBearerAuth()
@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  // ─── Vendor stats (vendor member or admin) ────────────────────────────────

  @ApiStandardResponse()
  @Get('vendors/:vendorId')
  @VendorMember({ vendorIdParam: 'vendorId' })
  @ApiOperation({ summary: 'Get vendor statistics (member or admin)' })
  @ApiQuery({ name: 'period', enum: StatisticPeriod, required: false })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  getVendorStats(
    @Param('vendorId') vendorId: string,
    @Query() dto: StatsQueryDto,
  ) {
    return this.statisticsService.getVendorStats(
      vendorId,
      dto.period ?? StatisticPeriod.DAILY,
      dto.limit,
      dto.from,
      dto.to,
    );
  }

  @ApiStandardResponse()
  @Get('vendors/:vendorId/most-ordered-product')
  @VendorMember({ vendorIdParam: 'vendorId' })
  @ApiOperation({ summary: 'Get the most ordered product for a vendor' })
  getMostOrderedProduct(@Param('vendorId') vendorId: string) {
    return this.statisticsService.getMostOrderedProduct(vendorId);
  }

  // ─── Driver stats (self) ──────────────────────────────────────────────────

  @ApiStandardResponse()
  @Get('driver/me')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my driver statistics' })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  getMyDriverStats(
    @CurrentUser() actor: JwtAccessPayload,
    @Query() dto: StatsQueryDto,
  ) {
    return this.statisticsService.getMyDriverStats(
      actor.sub,
      dto.period ?? StatisticPeriod.DAILY,
      dto.limit,
      dto.from,
      dto.to,
    );
  }

  // ─── Admin: platform-wide stats ───────────────────────────────────────────

  @ApiStandardResponse()
  @Get('app')
  @RequirePermissions(Permission.VIEW_STATISTICS)
  @ApiOperation({ summary: '[Admin] Get platform-wide statistics' })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  getAppStats(@Query() dto: StatsQueryDto) {
    return this.statisticsService.getAppStats(
      dto.period ?? StatisticPeriod.DAILY,
      dto.limit,
      dto.from,
      dto.to,
    );
  }

  // ─── Admin: stats for a specific driver ───────────────────────────────────

  @ApiStandardResponse()
  @Get('drivers/:driverId')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Get statistics for a specific driver' })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  getDriverStats(
    @Param('driverId') driverId: string,
    @Query() dto: StatsQueryDto,
  ) {
    return this.statisticsService.getDriverStats(
      driverId,
      dto.period ?? StatisticPeriod.DAILY,
      dto.limit,
      dto.from,
      dto.to,
    );
  }

  // ─── Analytics Leaderboards ───────────────────────────────────────────────

  @ApiStandardResponse()
  @Get('analytics/drivers')
  @RequirePermissions(Permission.VIEW_STATISTICS)
  @ApiOperation({ summary: '[Admin] Get top drivers leaderboard' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'from', required: false, description: 'ISO date (inclusive)' })
  @ApiQuery({ name: 'to', required: false, description: 'ISO date (inclusive)' })
  getTopDrivers(@Query() dto: AnalyticsQueryDto) {
    return this.statisticsService.getTopDrivers(dto.limit ?? 20, dto.from, dto.to);
  }

  @ApiStandardResponse()
  @Get('analytics/customers')
  @RequirePermissions(Permission.VIEW_STATISTICS)
  @ApiOperation({ summary: '[Admin] Get top customers leaderboard' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'from', required: false, description: 'ISO date (inclusive)' })
  @ApiQuery({ name: 'to', required: false, description: 'ISO date (inclusive)' })
  getTopCustomers(@Query() dto: AnalyticsQueryDto) {
    return this.statisticsService.getTopCustomers(dto.limit ?? 20, dto.from, dto.to);
  }

  @ApiStandardResponse()
  @Get('analytics/vendors')
  @RequirePermissions(Permission.VIEW_STATISTICS)
  @ApiOperation({ summary: '[Admin] Get top vendors leaderboard' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'from', required: false, description: 'ISO date (inclusive)' })
  @ApiQuery({ name: 'to', required: false, description: 'ISO date (inclusive)' })
  getTopVendors(@Query() dto: AnalyticsQueryDto) {
    return this.statisticsService.getTopVendors(dto.limit ?? 20, dto.from, dto.to);
  }

  @ApiStandardResponse()
  @Get('analytics/products')
  @RequirePermissions(Permission.VIEW_STATISTICS)
  @ApiOperation({ summary: '[Admin] Get top products leaderboard' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'from', required: false, description: 'ISO date (inclusive)' })
  @ApiQuery({ name: 'to', required: false, description: 'ISO date (inclusive)' })
  getTopProducts(@Query() dto: AnalyticsQueryDto) {
    return this.statisticsService.getTopProducts(dto.limit ?? 20, dto.from, dto.to);
  }
}
