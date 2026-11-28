import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';
import { ApiFileUpload } from '../../common/decorators/api-file-upload.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { Role, Permission } from '@prisma/client';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { DriverManagersService } from './driver-managers.service';
import {
  AssignDriversToManagerDto,
  ProcessDriverManagerPayoutDto,
  UnassignDriversFromManagerDto,
} from './dto/driver-manager.dto';

@ApiTags('Driver Managers')
@ApiBearerAuth()
@Controller('driver-managers')
export class DriverManagersController {
  constructor(private readonly service: DriverManagersService) {}

  @ApiStandardResponse()
  @Get()
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS, Permission.MANAGE_FINANCE, {
    mode: 'any',
  })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] List all driver managers with assigned driver counts',
  })
  listManagers() {
    return this.service.listManagers();
  }

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
  @Post('payout/receipt')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_FINANCE)
  @ApiFileUpload({ type: 'IMAGE', required: true })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Upload a transfer receipt screenshot for a driver manager wallet payout',
  })
  uploadPayoutReceipt(@UploadedFile() file: Express.Multer.File) {
    return this.service.uploadPayoutReceipt(file);
  }

  @ApiStandardResponse()
  @Post('assign')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Assign drivers to a driver manager (all or specific). Each driver can be assigned to only one manager.',
  })
  assignDrivers(@Body() body: AssignDriversToManagerDto) {
    return this.service.assignDrivers(body);
  }

  @ApiStandardResponse()
  @Get(':userId')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS, Permission.MANAGE_FINANCE, {
    mode: 'any',
  })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Get driver manager details and assigned drivers',
  })
  getManagerDetails(@Param('userId') userId: string) {
    return this.service.getManagerDetails(userId);
  }

  @ApiStandardResponse()
  @Get(':userId/transactions')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_FINANCE, Permission.MANAGE_DRIVERS, {
    mode: 'any',
  })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] List wallet transactions for a specific driver manager',
  })
  getManagerTransactions(
    @Param('userId') userId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.service.getTransactionsByUserId(userId, page ?? 1, limit ?? 20);
  }

  @ApiStandardResponse()
  @Post(':userId/payout')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_FINANCE)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Settle/zero out or partially pay out a driver manager wallet with optional transfer receipt',
  })
  processManagerPayout(
    @Param('userId') userId: string,
    @Body() body: ProcessDriverManagerPayoutDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.service.processPayout(userId, body, actor.sub);
  }

  @ApiStandardResponse()
  @Post(':userId/unassign')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Unassign specific drivers from a driver manager',
  })
  unassignDrivers(
    @Param('userId') userId: string,
    @Body() body: UnassignDriversFromManagerDto,
  ) {
    return this.service.unassignDrivers(userId, body.driverIds);
  }

  @ApiStandardResponse()
  @Get(':userId/drivers')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Get drivers assigned to a driver manager',
  })
  getManagerDrivers(@Param('userId') userId: string) {
    return this.service.getManagerDrivers(userId);
  }
}
