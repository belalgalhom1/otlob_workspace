import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UploadedFile,
} from '@nestjs/common';
import { ApiFileUpload } from 'src/common/decorators/api-file-upload.decorator';
import { DriversService } from './drivers.service';
import { DriverAssistService } from './driver-assist.service';
import { AuthService } from '../auth/auth.service';
import {
  RegisterDriverDto,
  UpdateDriverProfileDto,
  UpdateDriverStatusDto,
  StartBreakDto,
  CreateDriverShiftDto,
  QueryDriversDto,
  QueryDriverWalletDto,
  AdminCreateDriverDto,
  AdminUpdateDriverDto,
} from './dto/driver.dto';
import {
  RequestAssistDriverDto,
  DecideAssistRequestDto,
  AssignAssistDriverDto,
} from './dto/driver-assist.dto';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';
import { RequirePermissions } from 'src/common/decorators/permissions.decorator';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Permission, Role } from '@prisma/client';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import {
  ApiStandardResponse,
  ApiArrayResponse,
} from 'src/common/decorators/api-response.decorator';
import { DriverBreak } from '../../_gen/prisma-classes/driver_break';

import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Drivers')
@ApiBearerAuth()
@Controller('drivers')
export class DriversController {
  constructor(
    private readonly driversService: DriversService,
    private readonly authService: AuthService,
    private readonly driverAssistService: DriverAssistService,
  ) {}

  // ═══════════════════════════════════════════════════════════════════════════
  // SELF-SERVICE  — any authenticated user can register; then DRIVER only
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse()
  @Post('register')
  @ApiOperation({
    summary: 'Register as a driver (creates driver profile, upgrades role)',
  })
  register(@CurrentUser('sub') userId: string, @Body() dto: RegisterDriverDto) {
    return this.driversService.register(userId, dto);
  }

  @ApiStandardResponse()
  @Get('me')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my driver profile' })
  getMyProfile(@CurrentUser('sub') userId: string) {
    return this.driversService.getMyProfile(userId);
  }

  @ApiStandardResponse()
  @Patch('me')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Update my driver profile' })
  updateProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateDriverProfileDto,
  ) {
    return this.driversService.updateProfile(userId, dto);
  }

  @ApiStandardResponse()
  @Post('me/avatar')
  @Roles(Role.DRIVER)
  @ApiFileUpload({ type: 'IMAGE', required: true })
  @ApiOperation({ summary: 'Upload driver avatar' })
  uploadAvatar(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.driversService.uploadAvatar(userId, file);
  }

  @ApiStandardResponse()
  @Patch('me/status')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update driver status (ONLINE / OFFLINE)',
  })
  updateStatus(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateDriverStatusDto,
  ) {
    return this.driversService.updateStatus(userId, dto);
  }

  // ─── Breaks ───────────────────────────────────────────────────────────────

  @ApiStandardResponse(DriverBreak)
  @Post('me/break/start')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request a break (pending admin approval)' })
  startBreak(
    @CurrentUser('sub') userId: string,
    @Body() dto?: StartBreakDto,
  ) {
    return this.driversService.startBreak(userId, dto);
  }

  @ApiStandardResponse(DriverBreak)
  @Post('me/break/end')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'End the active break (pre-break status restored)' })
  endBreak(@CurrentUser('sub') userId: string) {
    return this.driversService.endBreak(userId);
  }

  @ApiStandardResponse(DriverBreak)
  @Post('me/break/cancel')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel my pending break request' })
  cancelBreak(@CurrentUser('sub') userId: string) {
    return this.driversService.cancelBreakRequest(userId);
  }

  @ApiArrayResponse(DriverBreak)
  @Get('me/breaks')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'List my recent breaks' })
  getMyBreaks(@CurrentUser('sub') userId: string) {
    return this.driversService.getMyBreaks(userId);
  }

  @ApiStandardResponse(DriverBreak)
  @Get('me/break/active')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my active break, if any' })
  getActiveBreak(@CurrentUser('sub') userId: string) {
    return this.driversService.getActiveBreak(userId);
  }

  // ─── Shifts ───────────────────────────────────────────────────────────────

  @ApiStandardResponse()
  @Post('me/shifts')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Create a shift' })
  createShift(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDriverShiftDto,
  ) {
    return this.driversService.createShift(userId, dto);
  }

  @ApiStandardResponse()
  @Get('me/shifts')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get my shifts' })
  getMyShifts(@CurrentUser('sub') userId: string) {
    return this.driversService.getMyShifts(userId);
  }

  @ApiStandardResponse()
  @Post('me/shifts/:shiftId/start')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiFileUpload({ type: 'IMAGE', required: true })
  @ApiOperation({
    summary:
      'Start a shift (selfie required, must be inside the shift zone, flips ONLINE)',
  })
  startShift(
    @CurrentUser('sub') userId: string,
    @Param('shiftId') shiftId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() body?: { latitude?: number; longitude?: number },
  ) {
    const latitude =
      body?.latitude != null ? Number(body.latitude) : undefined;
    const longitude =
      body?.longitude != null ? Number(body.longitude) : undefined;
    return this.driversService.startShift(
      userId,
      shiftId,
      file,
      latitude,
      longitude,
    );
  }

  @ApiStandardResponse()
  @Post('me/shifts/:shiftId/end')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'End a shift' })
  endShift(
    @CurrentUser('sub') userId: string,
    @Param('shiftId') shiftId: string,
  ) {
    return this.driversService.endShift(userId, shiftId);
  }

  @ApiStandardResponse()
  @Delete('me/shifts/:shiftId')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete my shift (any status)' })
  deleteMyShift(
    @CurrentUser('sub') userId: string,
    @Param('shiftId') shiftId: string,
  ) {
    return this.driversService.deleteMyShift(userId, shiftId);
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  @ApiStandardResponse()
  @Get('me/wallet')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get wallet balance' })
  getWalletBalance(@CurrentUser('sub') userId: string) {
    return this.driversService.getWalletBalance(userId);
  }

  @ApiStandardResponse()
  @Get('me/wallet/transactions')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: 'Get wallet transaction history' })
  getWalletTransactions(
    @CurrentUser('sub') userId: string,
    @Query() dto: QueryDriverWalletDto,
  ) {
    return this.driversService.getWalletTransactions(userId, dto);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN
  // ═══════════════════════════════════════════════════════════════════════════

  @ApiStandardResponse()
  @Post('admin')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Create a new driver directly' })
  async adminCreate(
    @CurrentUser() actor: any,
    @Body() dto: AdminCreateDriverDto,
  ) {
    // Create user with DRIVER role
    const { user } = await this.authService.register(
      {
        email: dto.email,
        phone: dto.phone,
        password: dto.password,
        name: dto.name,
        role: Role.DRIVER,
      },
      true, // isAdminCreated
    );

    // Create driver profile
    return this.driversService.adminCreateDriver(user.id, actor.sub, dto);
  }

  @ApiStandardResponse()
  @Patch(':driverId/admin')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({
    summary: '[Admin] Update driver profile and sensitive fields',
  })
  async adminUpdate(
    @CurrentUser() actor: any,
    @Param('driverId') driverId: string,
    @Body() dto: AdminUpdateDriverDto,
  ) {
    return this.driversService.adminUpdateDriver(driverId, actor.sub, dto);
  }

  @ApiStandardResponse()
  @Get()
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] List all drivers' })
  adminFindAll(
    @Query() dto: QueryDriversDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.driversService.adminFindAll(dto, actor);
  }

  // NOTE: static `breaks/*` routes must stay BEFORE `:driverId` param routes.
  // Otherwise Express would capture `breaks` as a driverId and the pending
  // queue / history endpoints would 404 (vendor break page stays empty).
  @ApiArrayResponse(DriverBreak)
  @Get('breaks/pending')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] List pending break requests' })
  adminGetPendingBreaks() {
    return this.driversService.getPendingBreaks();
  }

  @ApiStandardResponse(DriverBreak)
  @Post('breaks/:breakId/approve')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Approve a break request (driver ON_BREAK)' })
  adminApproveBreak(
    @CurrentUser('sub') reviewerId: string,
    @Param('breakId') breakId: string,
  ) {
    return this.driversService.approveBreak(breakId, reviewerId);
  }

  @ApiStandardResponse(DriverBreak)
  @Post('breaks/:breakId/reject')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Reject a break request' })
  adminRejectBreak(
    @CurrentUser('sub') reviewerId: string,
    @Param('breakId') breakId: string,
  ) {
    return this.driversService.rejectBreak(breakId, reviewerId);
  }

  @ApiStandardResponse(DriverBreak)
  @Post('breaks/:breakId/end')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Force-end an active break early' })
  adminEndBreak(
    @CurrentUser('sub') reviewerId: string,
    @Param('breakId') breakId: string,
  ) {
    return this.driversService.adminEndBreak(breakId, reviewerId);
  }

  @ApiStandardResponse()
  @Get(':driverId')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Get a driver by ID' })
  adminFindOne(@Param('driverId') driverId: string) {
    return this.driversService.adminFindOne(driverId);
  }

  @ApiStandardResponse()
  @Get(':driverId/location')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Get a driver current location' })
  adminGetDriverLocation(@Param('driverId') driverId: string) {
    return this.driversService.adminGetDriverLocation(driverId);
  }

  @ApiStandardResponse()
  @Post(':driverId/suspend')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Suspend a driver' })
  adminSuspend(@Param('driverId') driverId: string) {
    return this.driversService.adminSuspend(driverId);
  }

  @ApiStandardResponse()
  @Post(':driverId/unsuspend')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Unsuspend a driver' })
  adminUnsuspend(@Param('driverId') driverId: string) {
    return this.driversService.adminUnsuspend(driverId);
  }

  @ApiStandardResponse()
  @Post(':driverId/shifts')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Create a shift for a driver' })
  adminCreateShift(
    @Param('driverId') driverId: string,
    @Body() dto: CreateDriverShiftDto,
  ) {
    return this.driversService.adminCreateShift(driverId, dto);
  }

  @ApiStandardResponse()
  @Get(':driverId/shifts')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Get shifts for a driver' })
  adminGetShifts(@Param('driverId') driverId: string) {
    return this.driversService.adminGetShifts(driverId);
  }

  @ApiStandardResponse(DriverBreak)
  @Post(':driverId/breaks/grant')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Admin] Grant a break manually (no request needed, quota bypassed)',
  })
  adminGrantBreak(
    @CurrentUser('sub') reviewerId: string,
    @Param('driverId') driverId: string,
    @Body() dto?: StartBreakDto,
  ) {
    return this.driversService.adminGrantBreak(driverId, reviewerId, dto);
  }

  @ApiArrayResponse(DriverBreak)
  @Get(':driverId/breaks')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] List recent breaks for a driver' })
  adminGetBreaks(@Param('driverId') driverId: string) {
    return this.driversService.adminGetBreaks(driverId);
  }
  // ─── Extra driver assistance ───────────────────────────────────────────────
  // NOTE: these are static `assist/*` paths and must stay before the
  // `:driverId/...` param routes below, otherwise Express would capture
  // `assist` as a driverId (same trap as `breaks/*`).

  @ApiStandardResponse()
  @Post('assist/:orderId/groups/:deliveryGroupId/request')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Driver] Request an additional driver for a delivery I am assigned to',
  })
  requestAssist(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Param('deliveryGroupId') deliveryGroupId: string,
    @Body() dto: RequestAssistDriverDto,
  ) {
    return this.driverAssistService.requestAssist(actor, orderId, deliveryGroupId, dto);
  }

  @ApiStandardResponse()
  @Post('assist/order/:orderId/request')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Driver] Request an additional driver for a single-vendor order I am assigned to',
  })
  requestAssistOrder(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('orderId') orderId: string,
    @Body() dto: RequestAssistDriverDto,
  ) {
    return this.driverAssistService.requestAssistOrder(actor, orderId, dto);
  }

  @ApiArrayResponse()
  @Get('assist/mine')
  @Roles(Role.DRIVER)
  @ApiOperation({ summary: '[Driver] My assistance requests and their status' })
  myAssistRequests(@CurrentUser() actor: JwtAccessPayload) {
    return this.driverAssistService.myRequests(actor);
  }

  @ApiStandardResponse()
  @Patch('assist/:requestId/cancel')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Driver] Withdraw my own pending assistance request' })
  cancelAssistRequest(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
  ) {
    return this.driverAssistService.cancelByDriver(requestId, actor);
  }

  @ApiArrayResponse()
  @Get('assist/pending')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Pending extra-driver assistance requests' })
  listPendingAssistRequests() {
    return this.driverAssistService.listPending();
  }

  @ApiArrayResponse()
  @Get('assist/order/:orderId')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] Assistance requests for one order' })
  listAssistRequestsForOrder(@Param('orderId') orderId: string) {
    return this.driverAssistService.listForOrder(orderId);
  }

  @ApiStandardResponse()
  @Patch('assist/:requestId/decide')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Approve or reject an assistance request' })
  decideAssistRequest(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
    @Body() dto: DecideAssistRequestDto,
  ) {
    return this.driverAssistService.decide(requestId, actor, dto);
  }

  // The authorization rule for this action is an explicit disjunction:
  // MANAGE_ORDERS **or** MANAGE_DRIVERS (mode: 'any'). It must NOT be AND.
  @ApiStandardResponse()
  @Patch('assist/:requestId/assign-driver')
  @RequirePermissions(Permission.MANAGE_ORDERS, Permission.MANAGE_DRIVERS, {
    mode: 'any',
  })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Assign an assisting driver, keeping the primary driver (MANAGE_ORDERS or MANAGE_DRIVERS)',
  })
  assignAssistDriver(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
    @Body() dto: AssignAssistDriverDto,
  ) {
    return this.driverAssistService.assignDriver(requestId, actor, dto);
  }

  @ApiStandardResponse()
  @Patch('assist/:requestId/auto-assign')
  @RequirePermissions(Permission.MANAGE_ORDERS, Permission.MANAGE_DRIVERS)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Auto-assign the nearest eligible driver as the assistant',
  })
  autoAssignAssistDriver(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
  ) {
    return this.driverAssistService.autoAssignAssistDriver(requestId, actor);
  }

  @ApiStandardResponse()
  @Patch('assist/:requestId/offer-nearest')
  @RequirePermissions(Permission.MANAGE_ORDERS, Permission.MANAGE_DRIVERS, {
    mode: 'any',
  })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[Admin] Auto-offer the assist to the top-N nearest eligible drivers',
  })
  offerAssistToNearest(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
    @Query('limit') limit?: string,
  ) {
    const n = Math.min(Math.max(Number(limit) || 5, 1), 10);
    return this.driverAssistService.offerAssistToNearest(requestId, actor, n);
  }

  @ApiStandardResponse()
  @Post('assist/:requestId/offer/respond')
  @Roles(Role.DRIVER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: '[Driver] Accept or decline an assist offer',
  })
  respondToAssistOffer(
    @CurrentUser() actor: JwtAccessPayload,
    @Param('requestId') requestId: string,
    @Body() body: { accept: boolean },
  ) {
    return this.driverAssistService.respondToAssistOffer(
      actor,
      requestId,
      body?.accept === true,
    );
  }

  @ApiArrayResponse()
  @Get('assist/offers/pending')
  @Roles(Role.DRIVER)
  @ApiOperation({
    summary: '[Driver] Pending assist offers (HTTP fallback when socket is down)',
  })
  pendingAssistOffers(@CurrentUser() actor: JwtAccessPayload) {
    return this.driverAssistService.getPendingAssistOffers(actor);
  }
}
