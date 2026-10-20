import {
  Controller,
  Get,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
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
}
