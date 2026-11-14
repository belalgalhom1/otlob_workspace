import { Body, Controller, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { ApiStandardResponse } from 'src/common/decorators/api-response.decorator';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';
import { Roles } from 'src/common/decorators/roles.decorator';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { DriverAssistService } from './driver-assist.service';
import { CustomerDecideAssistDto } from './dto/driver-assist.dto';

@ApiTags('Orders')
@ApiBearerAuth()
@Controller('orders')
export class OrderAssistDecisionController {
  constructor(private readonly driverAssistService: DriverAssistService) {}

  @ApiStandardResponse()
  @Post(':orderId/delivery-groups/:deliveryGroupId/assist/decision')
  @Roles(Role.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Customer] Approve or decline an assisted delivery (and its fee)',
  })
  decideAssist(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Param('deliveryGroupId') deliveryGroupId: string,
    @Body() body: CustomerDecideAssistDto,
  ) {
    return this.driverAssistService.customerDecideAssist(
      actor,
      orderId,
      deliveryGroupId,
      body?.approved === true,
    );
  }

  @ApiStandardResponse()
  @Post(':orderId/assist/decision')
  @Roles(Role.CUSTOMER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Customer] Approve or decline an assisted delivery (single-group order convenience)',
  })
  decideAssistOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() body: CustomerDecideAssistDto,
  ) {
    return this.driverAssistService.customerDecideAssistForOrder(
      actor,
      orderId,
      body?.approved === true,
    );
  }
}
