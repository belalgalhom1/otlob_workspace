import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { Role, Permission } from '@prisma/client';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { DriverManagersService } from './driver-managers.service';

@ApiTags('Driver Managers')
@ApiBearerAuth()
@Controller('driver-managers')
export class DriverManagersController {
  constructor(private readonly service: DriverManagersService) {}

  @ApiStandardResponse()
  @Get('me/wallet')
  @Roles(Role.DRIVER_MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get my driver-manager wallet' })
  getMyWallet(@CurrentUser() user: JwtAccessPayload) {
    return this.service.getMyWallet(user.sub);
  }

  @ApiStandardResponse()
  @Get('me/transactions')
  @Roles(Role.DRIVER_MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'List my driver-manager wallet transactions' })
  getTransactions(
    @CurrentUser() user: JwtAccessPayload,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.service.getTransactions(user.sub, page ?? 1, limit ?? 20);
  }

  @ApiStandardResponse()
  @Post('assign')
  @Roles(Role.SUPER_ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Super Admin] Assign drivers to a driver manager (all or specific). Each driver can be assigned to only one manager.',
  })
  assignDrivers(
    @Body()
    body: {
      driverManagerUserId: string;
      driverIds?: string[];
      manageAllDrivers?: boolean;
    },
  ) {
    return this.service.assignDrivers(body);
  }

  @ApiStandardResponse()
  @Get(':userId/drivers')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Get drivers assigned to a driver manager',
  })
  getManagerDrivers(@Query('driverManagerUserId') driverManagerUserId: string) {
    return this.service.getManagerDrivers(driverManagerUserId);
  }
}
