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
import { RejectVendorFulfillmentDto } from './dto/vendor-decision.dto';
import { PlaceMultiVendorOrderDto } from './dto/multi-vendor-order.dto';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';
import { Roles } from 'src/common/decorators/roles.decorator';
import { RequirePermissions } from 'src/common/decorators/permissions.decorator';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { Permission, Role } from '@prisma/client';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiStandardResponse } from '../../common/decorators/api-response.decorator';
import { ApiArrayResponse } from '../../common/decorators/api-response.decorator';

import { OrdersCheckoutService } from './orders-checkout.service';
import { OrdersStateService } from './orders-state.service';
import { OrdersPaymentService } from './orders-payment.service';
import { OrderVendorDecisionService } from './order-vendor-decision.service';
import { OrdersMultiVendorService } from './orders-multi-vendor.service';
import { DriverAssistService } from '../drivers/driver-assist.service';
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
    private readonly vendorDecisionService: OrderVendorDecisionService,
    private readonly multiVendorService: OrdersMultiVendorService,
    private readonly driverAssistService: DriverAssistService,
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
  async placeOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const order = await this.checkoutService.placeOrder(actor, dto, idempotencyKey);
    return this.ordersService.projectOrderForRole(order, actor);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Throttle({
    short: { limit: 3, ttl: 60000 },
    medium: { limit: 10, ttl: 300000 },
  })
  @Post('custom')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Place a custom delivery or ride order' })
  async placeCustomOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceCustomOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const order = await this.checkoutService.placeCustomOrder(actor, dto, idempotencyKey);
    return this.ordersService.projectOrderForRole(order, actor);
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
  async customerMarkPaid(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const order = await this.paymentService.customerMarkPaid(actor, orderId, file);
    return this.ordersService.projectOrderForRole(order, actor);
  }

  @ApiStandardResponse(OrderResponseDto)
  @Post('driver/:orderId/payment/confirm')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver confirms or denies receiving mobile wallet payment',
  })
  async driverConfirmPayment(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: ConfirmPaymentDto,
  ) {
    const order = await this.paymentService.driverConfirmPayment(
      actor,
      orderId,
      dto.received,
    );
    return this.ordersService.projectOrderForRole(order, actor);
  }

  @ApiStandardResponse()
  @Patch('driver/:orderId/status')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver updates order status (PICKED_UP / DELIVERED)',
  })
  async driverUpdateStatus(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    const order = await this.stateService.driverUpdateStatus(actor, orderId, dto);
    return this.ordersService.projectOrderForRole(order, actor);
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
  async driverConfirmPickup(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
    @Query('fulfillmentId') fulfillmentId?: string,
  ) {
    const order = await this.stateService.driverConfirmPickup(actor, orderId, file, fulfillmentId);
    return this.ordersService.projectOrderForRole(order, actor);
  }

  @ApiStandardResponse()
  @Post('driver/:orderId/fulfillment/:fulfillmentId/pickup')
  @Roles(Role.DRIVER)
  @ApiFileUpload({ type: 'IMAGE' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver confirms pickup for a specific vendor fulfillment stop with photo',
  })
  async driverConfirmFulfillmentPickup(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Param('fulfillmentId') fulfillmentId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const order = await this.stateService.driverConfirmFulfillmentPickup(actor, orderId, fulfillmentId, file);
    return this.ordersService.projectOrderForRole(order, actor);
  }

  @ApiStandardResponse()
  @Post('driver/:orderId/delivery')
  @Roles(Role.DRIVER)
  @ApiFileUpload({ type: 'IMAGE' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Driver confirms delivery with a photo of the order (PICKED_UP to DELIVERED)',
  })
  async driverConfirmDelivery(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @UploadedFile() file: Express.Multer.File,
    @Query('deliveryGroupId') deliveryGroupId?: string,
  ) {
    const order = await this.stateService.driverConfirmDelivery(actor, orderId, file, deliveryGroupId);
    return this.ordersService.projectOrderForRole(order, actor);
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
  async vendorUpdateStatus(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    const order = await this.stateService.vendorUpdateStatus(actor, orderId, dto);
    return this.ordersService.projectOrderForRole(order, actor);
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
  async cancelOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body('reason') reason?: string,
  ) {
    const order = await this.stateService.cancelOrder(
      actor,
      orderId,
      reason ?? 'Cancelled by user',
    );
    return this.ordersService.projectOrderForRole(order, actor);
  }

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
    @Body() body: { approved: boolean },
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
    summary: '[Customer] Approve or decline an assisted delivery (single-vendor order)',
  })
  decideAssistOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() body: { approved: boolean },
  ) {
    return this.driverAssistService.customerDecideAssistOrder(
      actor,
      orderId,
      body?.approved === true,
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
  async adminForceAssignDriver(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: AdminAssignDriverDto,
  ) {
    const order = await this.stateService.adminForceAssignDriver(actor, orderId, dto);
    return this.ordersService.projectOrderForRole(order, actor);
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
  async adminPlaceDirectOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceDirectOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const order = await this.checkoutService.adminPlaceDirectOrder(
      actor,
      dto,
      idempotencyKey,
    );
    return this.ordersService.projectOrderForRole(order, actor);
  }
  // ─── Vendor portions (multi-vendor orders) ────────────────────────────────
  // NOTE: static `vendor-decisions/*` paths must stay ABOVE the `:orderId`
  // param routes, otherwise Express captures the literal segment as an id.

  @ApiArrayResponse()
  @Get('vendor-decisions/pending')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({
    summary: '[Vendor] My vendor portions awaiting my accept/reject decision',
  })
  myPendingDecisions(@CurrentUser() actor: JwtAccessPayload) {
    return this.vendorDecisionService.listPendingForVendor(actor);
  }

  @ApiArrayResponse()
  @Get('vendor-decisions/vendor/:vendorId')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({ summary: '[Vendor] All my portions for one vendor' })
  listVendorDecisions(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('vendorId') vendorId: string,
  ) {
    return this.vendorDecisionService.listForVendor(actor, vendorId);
  }

  @ApiArrayResponse()
  @Get('vendor-decisions/order/:orderId')
  @RequirePermissions(Permission.MANAGE_ORDERS)
  @ApiOperation({ summary: '[Admin] Vendor portions and their states for an order' })
  listOrderDecisions(@Param('orderId') orderId: string) {
    return this.vendorDecisionService.listForOrder(orderId);
  }

  @ApiStandardResponse()
  @Patch('vendor-decisions/:fulfillmentId/accept')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Vendor] Accept ONLY my portion — other vendors are unaffected',
  })
  acceptFulfillment(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('fulfillmentId') fulfillmentId: string,
  ) {
    return this.vendorDecisionService.accept(actor, fulfillmentId);
  }

  @ApiStandardResponse()
  @Patch('vendor-decisions/:fulfillmentId/reject')
  @Roles(Role.VENDOR_MEMBER, Role.ADMIN, Role.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Vendor] Reject only my portion with an auditable reason; the customer is notified and the totals are adjusted',
  })
  rejectFulfillment(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('fulfillmentId') fulfillmentId: string,
    @Body() dto: RejectVendorFulfillmentDto,
  ) {
    return this.vendorDecisionService.reject(actor, fulfillmentId, dto);
  }
  // ─── Multi-vendor checkout ────────────────────────────────────────────────
  // NOTE: `multi-vendor/*` static paths must stay ABOVE the `:orderId` routes.

  @ApiStandardResponse()
  @Post('multi-vendor/fee-estimate')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Estimate a multi-vendor checkout, including the per-delivery fee breakdown and whether it splits',
  })
  estimateMultiVendor(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceMultiVendorOrderDto,
  ) {
    return this.multiVendorService.estimate(actor, dto);
  }

  @ApiStandardResponse()
  @Post('multi-vendor')
  @Roles(Role.CUSTOMER, Role.SUPER_ADMIN)
  @Throttle({
    short: { limit: 3, ttl: 60000 },
    medium: { limit: 10, ttl: 300000 },
  })
  @ApiOperation({
    summary:
      'Place one order containing multiple vendors, grouped into deliveries',
  })
  async placeMultiVendorOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Body() dto: PlaceMultiVendorOrderDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const order = await this.multiVendorService.placeOrder(actor, dto, idempotencyKey);
    return this.ordersService.projectOrderForRole(order, actor);
  }
}
