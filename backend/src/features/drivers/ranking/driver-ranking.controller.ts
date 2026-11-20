import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { DriverRankingTriggerSource, Permission, Role } from '@prisma/client';
import { ApiStandardResponse } from '../../../common/decorators/api-response.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../../common/decorators/permissions.decorator';
import { Roles } from '../../../common/decorators/roles.decorator';
import type { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import { DriverDeliveryIncidentsService } from './driver-delivery-incidents.service';
import { DriverRankingService } from './driver-ranking.service';
import {
  DriverDeliveryIncidentDto,
  DriverMyRankSummaryResponseDto,
  DriverRankHistoryEntryDto,
  DriverRankingEvaluationRunDto,
  DriverRankingPreviewResponseDto,
  DriverRankingRunDetailsResponseDto,
  DriverRankingScheduleStatusDto,
  OverrideDriverRankDto,
  PaginatedDeliveryIncidentsResponseDto,
  PaginatedDriverRankHistoryResponseDto,
  PaginatedRankingRunsResponseDto,
  QueryDeliveryIncidentsDto,
  QueryDriverRankHistoryDto,
  QueryRankingPreviewDto,
  QueryRankingRunsDto,
  QueryRunDetailsDto,
  UpdateDeliveryIncidentDto,
} from './dto/driver-ranking.dto';

@ApiTags('Driver Ranking')
@ApiBearerAuth()
@Controller('driver-ranking')
export class DriverRankingController {
  constructor(
    private readonly driverRankingService: DriverRankingService,
    private readonly incidentsService: DriverDeliveryIncidentsService,
  ) {}

  @ApiStandardResponse(DriverRankingScheduleStatusDto)
  @Get('schedule')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({
    summary:
      '[Admin] Get weekly driver ranking evaluation schedule & next run timestamp',
  })
  getScheduleStatus() {
    return this.driverRankingService.getScheduleStatus();
  }

  @ApiStandardResponse(DriverRankingPreviewResponseDto)
  @Get('preview')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({
    summary:
      '[Admin] Dry-run preview of previous completed week ranking results without modifying badges',
  })
  previewEvaluation(
    @CurrentUser() actor: JwtAccessPayload,
    @Query() query: QueryRankingPreviewDto,
  ) {
    return this.driverRankingService.previewEvaluation(actor, query);
  }

  @ApiStandardResponse(DriverRankingEvaluationRunDto)
  @Post('run')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      '[Admin] Execute weekly driver ranking evaluation immediately for the previous completed week',
  })
  runEvaluationNow(@CurrentUser() actor: JwtAccessPayload) {
    return this.driverRankingService.runEvaluation({
      triggerSource: DriverRankingTriggerSource.MANUAL,
      triggeredByUserId: actor.sub,
    });
  }

  @ApiStandardResponse(PaginatedRankingRunsResponseDto)
  @Get('runs')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: '[Admin] List weekly driver ranking evaluation runs' })
  listRuns(@Query() dto: QueryRankingRunsDto) {
    return this.driverRankingService.listRuns(dto);
  }

  @ApiStandardResponse(DriverRankingRunDetailsResponseDto)
  @Get('runs/:runId')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({
    summary: '[Admin] Get a weekly driver ranking run and its driver entries',
  })
  getRunDetails(
    @Param('runId') runId: string,
    @CurrentUser() actor: JwtAccessPayload,
    @Query() query: QueryRunDetailsDto,
  ) {
    return this.driverRankingService.getRunDetails(runId, actor, query);
  }

  @ApiStandardResponse(DriverRankingEvaluationRunDto)
  @Post('runs/:runId/retry')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      '[Admin] Safely resume/retry a failed weekly evaluation run without duplicating already-committed entries',
  })
  retryFailedRun(
    @Param('runId') runId: string,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.driverRankingService.retryFailedRun(runId, actor);
  }

  @ApiStandardResponse(PaginatedDriverRankHistoryResponseDto)
  @Get('drivers/:driverId/history')
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @ApiOperation({ summary: "[Admin] Get a driver's ranking & override history" })
  getDriverHistory(
    @Param('driverId') driverId: string,
    @Query() dto: QueryDriverRankHistoryDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.driverRankingService.getDriverRankHistory(driverId, dto, actor);
  }

  @ApiStandardResponse(DriverRankHistoryEntryDto)
  @Post('drivers/:driverId/override')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions(Permission.MANAGE_DRIVERS)
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      '[Admin] Manually override a driver badge with mandatory audit reason',
  })
  overrideDriverTier(
    @Param('driverId') driverId: string,
    @Body() dto: OverrideDriverRankDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.driverRankingService.overrideDriverTier(driverId, dto, actor);
  }

  @ApiStandardResponse(PaginatedDeliveryIncidentsResponseDto)
  @Get('incidents')
  @RequirePermissions(Permission.MANAGE_DRIVERS, Permission.MANAGE_ORDERS, {
    mode: 'any',
  })
  @ApiOperation({
    summary:
      '[Admin] List delivery cancellation & reassignment responsibility incidents',
  })
  listIncidents(
    @Query() dto: QueryDeliveryIncidentsDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.incidentsService.listIncidents(dto, actor);
  }

  @ApiStandardResponse(DriverDeliveryIncidentDto)
  @Patch('incidents/:incidentId')
  @RequirePermissions(Permission.MANAGE_DRIVERS, Permission.MANAGE_ORDERS, {
    mode: 'any',
  })
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @ApiOperation({
    summary:
      '[Admin] Update/resolve a delivery incident responsibility classification',
  })
  reviewIncident(
    @Param('incidentId') incidentId: string,
    @Body() dto: UpdateDeliveryIncidentDto,
    @CurrentUser() actor: JwtAccessPayload,
  ) {
    return this.incidentsService.reviewIncident(incidentId, dto, actor);
  }

  @ApiStandardResponse(DriverMyRankSummaryResponseDto)
  @Get('me')
  @Roles(Role.DRIVER)
  @ApiOperation({
    summary:
      'Get current driver badge, current week progress, next evaluation time, and history',
  })
  getMyRankSummary(@CurrentUser('sub') userId: string) {
    return this.driverRankingService.getMyRankSummary(userId);
  }
}
