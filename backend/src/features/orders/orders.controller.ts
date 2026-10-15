import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
  UploadedFile,
} from '@nestjs/common';
import { ApiFileUpload } from '../../common/decorators/api-file-upload.decorator';
import { OrdersService } from './orders.service';
import { DispatchService } from '../dispatch/dispatch.service';
import {
  PlaceOrderDto,
  UpdateOrderStatusDto,
  QueryOrdersDto,
  RespondToDispatchDto,
  AdminAssignDriverDto,
  PlaceCustomOrderDto,
  PlaceDirectOrderDto,
  ConfirmPaymentDto,
  OrderFeeEstimateDto,
} from './dto/order.dto';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';
import { Roles } from 'src/common/decorators/roles.decorator';
import { RequirePermissions } from 'src/common/decorators/permissions.decorator';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { Permission, Role } from '@prisma/client';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';

import { OrdersCheckoutService } from './orders-checkout.service';
import { OrdersStateService } from './orders-state.service';
import { OrdersPaymentService } from './orders-payment.service';
import { OrderResponseDto } from 'src/common/dto/response-models.dto';

@ApiTags('Orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly dispatchService: DispatchService,
    private readonly checkoutService: OrdersCheckoutService,
    private readonly stateService: OrdersStateService,
    private readonly paymentService: OrdersPaymentService,
  ) {}

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse(OrderResponseDto)
  @Throttle({
    short: { limit: 3, ttl: 60000 },
    medium: { limit: 10, ttl: 300000 },
  })
  @Post()
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Place a new order from active cart' })
  placeOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.checkoutService.placeOrder(actor, dto, idempotencyKey);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Throttle({
    short: { limit: 3, ttl: 60000 },
    medium: { limit: 10, ttl: 300000 },
  })
  @Post('custom')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Place a custom delivery or ride order' })
  placeCustomOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceCustomOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.checkoutService.placeCustomOrder(actor, dto, idempotencyKey);
  }

  @ApiStandardResponse(OrderFeeEstimateDto)
  @Post('custom-fee-estimate')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      'Estimate custom delivery/ride fare before placing (fee is fixed to pickup→dropoff distance)',
  })
  estimateCustomOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceCustomOrderDto,
  ) {
    return this.checkoutService.estimateCustomOrder(actor, dto);
  }

  @ApiStandardResponse(OrderFeeEstimateDto)
  @Post('fee-estimate')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      'Estimate delivery fee and order total before placing (fee is fixed to vendor→customer distance)',
  })
  estimateOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceOrderDto,
  ) {
    return this.checkoutService.estimateOrder(actor, dto);
  }

  @ApiStandardResponse()
  @Get('my')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get my order history (customer)' })
  getMyOrdersAsCustomer(
    @CurrentUser() actor: JwtAccessPayload,
    @Query() dto: QueryOrdersDto,
  ) {
    return this.ordersService.getMyOrdersAsCustomer(actor, dto);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRIVER
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse()
  @Get('driver/my')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my orders as driver' })
  getMyOrdersAsDriver(
    @CurrentUser() actor: JwtAccessPayload,
    @Query() dto: QueryOrdersDto,
  ) {
    return this.ordersService.getMyOrdersAsDriver(actor, dto);
  }

  @ApiStandardResponse()
  @Get('driver/dispatches')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my pending dispatch requests' })
  getMyDispatches(@CurrentUser() actor: JwtAccessPayload) {
    return this.dispatchService.getPendingForDriver(actor.sub);
  }

  @ApiStandardResponse()
  @Post('driver/dispatches/:dispatchId/respond')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept or reject a dispatch request' })
  respondToDispatch(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('dispatchId') dispatchId: string,
    @Body() dto: RespondToDispatchDto,
  ) {
    return this.stateService.respondToDispatch(actor, dispatchId, dto);
  }

  // ─── Mobile Wallet Payment Endpoints ───────────────────────────────────────

  @ApiStandardResponse(OrderResponseDto)
  @Post('customer/:orderId/payment/mark-paid')
  @Roles(Role.CUSTOMER)
  @ApiFileUpload({ type: 'IMAGE' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Customer marks mobile wallet payment as paid with receipt',
  })
  customerMarkPaid(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.paymentService.customerMarkPaid(actor, orderId, file);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Post('driver/:orderId/payment/confirm')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver confirms or denies receiving mobile wallet payment',
  })
  driverConfirmPayment(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: ConfirmPaymentDto,
  ) {
    return this.paymentService.driverConfirmPayment(
      actor,
      orderId,
      dto.received,
    );
  }

  @ApiStandardResponse()
  @Patch('driver/:orderId/status')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver updates order status (PICKED_UP / DELIVERED)',
  })
  driverUpdateStatus(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.stateService.driverUpdateStatus(actor, orderId, dto);
  }

  @ApiStandardResponse()
  @Post('driver/:orderId/pickup')
  @Roles(Role.DRIVER)
  @ApiFileUpload({ type: 'IMAGE' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Driver confirms pickup with a photo of the order (STAGE to READY_FOR_PICKUP / CUSTOM_DELIVERY)',
  })
  driverConfirmPickup(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.stateService.driverConfirmPickup(actor, orderId, file);
  }

  @ApiStandardResponse()
  @Post('driver/:orderId/delivery')
  @Roles(Role.DRIVER)
  @ApiFileUpload({ type: 'IMAGE' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver confirms delivery with a photo of the order (PICKED_UP to DELIVERED)',
  })
  driverConfirmDelivery(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.stateService.driverConfirmDelivery(actor, orderId, file);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse()
  @Get('vendor/:vendorId')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get orders for a vendor (vendor member or admin)' })
  getVendorOrders(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('vendorId') vendorId: string,
    @Query() dto: QueryOrdersDto,
  ) {
    return this.ordersService.getVendorOrders(actor, vendorId, dto);
  }

  @ApiStandardResponse()
  @Patch('vendor/:orderId/status')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Vendor updates order status' })
  vendorUpdateStatus(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.stateService.vendorUpdateStatus(actor, orderId, dto);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse(OrderResponseDto)
  @Get(':orderId')
  @ApiOperation({
    summary: 'Get a single order (customer/driver/vendor/admin)',
  })
  getOne(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
  ) {
    return this.ordersService.getOne(actor, orderId);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Post(':orderId/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an order (customer or vendor)' })
  cancelOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body('reason') reason?: string,
  ) {
    return this.stateService.cancelOrder(
      actor,
      orderId,
      reason ?? 'Cancelled by user',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse()
  @Get()
  @RequirePermissions(Permission.MANAGE_ORDERS)
  @ApiOperation({ summary: '[Admin] List all orders with filters' })
  adminFindAll(@Query() dto: QueryOrdersDto) {
    return this.ordersService.adminFindAll(dto);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Post(':orderId/assign-driver')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_ORDERS)
  @ApiOperation({ summary: '[Admin] Force-assign a driver to an order' })
  adminForceAssignDriver(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: AdminAssignDriverDto,
  ) {
    return this.stateService.adminForceAssignDriver(actor, orderId, dto);
  }

  // ─── Order Item Modifications & Direct Orders ────────────────────────────────

  @ApiStandardResponse(OrderResponseDto)
  @Throttle({
    short: { limit: 3, ttl: 60000 },
    medium: { limit: 10, ttl: 300000 },
  })
  @Post('admin/direct')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.VENDOR_MEMBER)
  @ApiOperation({
    summary: '[Admin/Vendor] Create a pending order directly for a customer',
  })
  adminPlaceDirectOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceDirectOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.checkoutService.adminPlaceDirectOrder(
      actor,
      dto,
      idempotencyKey,
    );
  }
}
