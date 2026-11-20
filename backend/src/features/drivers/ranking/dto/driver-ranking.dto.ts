import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import {
  DeliveryIncidentResponsibility,
  DeliveryIncidentType,
  DriverRankChangeReason,
  DriverRankingRunStatus,
  DriverRankingTriggerSource,
  DriverTier,
} from '@prisma/client';
import { DriverRankingOutcome } from '../driver-ranking.calculator';

export { DriverRankingOutcome };

export class OverrideDriverRankDto {
  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  @IsEnum(DriverTier)
  @IsNotEmpty()
  newTier!: DriverTier;

  @ApiProperty({
    example: 'Escalated support review confirmed vehicle issue exception',
    maxLength: 500,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  reason!: string;
}

export class QueryRankingRunsDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export class QueryDriverRankHistoryDto extends QueryRankingRunsDto {}

export class QueryDeliveryIncidentsDto extends QueryRankingRunsDto {
  @ApiPropertyOptional({
    enum: DeliveryIncidentResponsibility,
    enumName: 'DeliveryIncidentResponsibility',
  })
  @IsOptional()
  @IsEnum(DeliveryIncidentResponsibility)
  responsibility?: DeliveryIncidentResponsibility;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  driverId?: string;
}

export class UpdateDeliveryIncidentDto {
  @ApiProperty({
    enum: DeliveryIncidentResponsibility,
    enumName: 'DeliveryIncidentResponsibility',
  })
  @IsEnum(DeliveryIncidentResponsibility)
  @IsNotEmpty()
  responsibility!: DeliveryIncidentResponsibility;

  @ApiPropertyOptional({
    example: 'Driver provided verified police/accident report',
    maxLength: 500,
  })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  reviewNote?: string;
}

export class ExcludedIncidentsSummaryDto {
  @ApiProperty()
  customer!: number;

  @ApiProperty()
  vendor!: number;

  @ApiProperty()
  externalOrSystem!: number;

  @ApiProperty()
  underReview!: number;
}

export class DriverMetricsSnapshotDto {
  @ApiProperty()
  acceptedDispatches!: number;

  @ApiProperty()
  rejectedDispatches!: number;

  @ApiProperty()
  expiredDispatches!: number;

  @ApiProperty()
  eligibleDispatches!: number;

  @ApiProperty()
  cancelledDispatches!: number;

  @ApiProperty()
  completedOrders!: number;

  @ApiProperty()
  driverFaultFailures!: number;

  @ApiProperty()
  driverResponsibleOrders!: number;

  @ApiProperty({ type: ExcludedIncidentsSummaryDto })
  excludedIncidents!: ExcludedIncidentsSummaryDto;

  @ApiProperty()
  onTimeShifts!: number;

  @ApiProperty()
  lateShifts!: number;

  @ApiProperty()
  missedShifts!: number;

  @ApiProperty()
  eligibleShifts!: number;

  @ApiProperty()
  cancelledShifts!: number;

  @ApiProperty()
  excusedShifts!: number;

  @ApiPropertyOptional({ nullable: true, type: Number })
  acceptanceRate!: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  completionRate!: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  shiftPunctualityRate!: number | null;

  @ApiProperty()
  applicableMetricsCount!: number;

  @ApiProperty()
  cappedDueToNoOrders!: boolean;

  @ApiProperty({ type: [String] })
  explanations!: string[];
}

export class RankingWeekWindowDto {
  @ApiProperty({ example: '2026-W47' })
  periodKey!: string;

  @ApiProperty({ type: Date })
  periodStart!: Date;

  @ApiProperty({ type: Date })
  periodEnd!: Date;
}

export class DriverRankingEvaluationRunDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ example: '2026-W46' })
  periodKey!: string;

  @ApiProperty({
    enum: DriverRankingRunStatus,
    enumName: 'DriverRankingRunStatus',
  })
  status!: DriverRankingRunStatus;

  @ApiProperty({
    enum: DriverRankingTriggerSource,
    enumName: 'DriverRankingTriggerSource',
  })
  triggerSource!: DriverRankingTriggerSource;

  @ApiPropertyOptional({ nullable: true })
  triggeredByUserId?: string | null;

  @ApiProperty({ type: Date })
  scheduledFor!: Date;

  @ApiPropertyOptional({ type: Date, nullable: true })
  executedAt?: Date | null;

  @ApiProperty({ type: Date })
  periodStart!: Date;

  @ApiProperty({ type: Date })
  periodEnd!: Date;

  @ApiProperty()
  totalDrivers!: number;

  @ApiProperty()
  promotedCount!: number;

  @ApiProperty()
  demotedCount!: number;

  @ApiProperty()
  unchangedCount!: number;

  @ApiProperty()
  inactiveCount!: number;

  @ApiPropertyOptional({ nullable: true })
  errorMessage?: string | null;

  @ApiProperty({ type: Date })
  createdAt!: Date;

  @ApiProperty({ type: Date })
  updatedAt!: Date;
}

export class DriverRankingScheduleStatusDto {
  @ApiProperty()
  enabled!: boolean;

  @ApiProperty({ example: '00:05' })
  evalTime!: string;

  @ApiProperty({ example: 'WEEKLY' })
  frequency!: string;

  @ApiProperty({ example: 'MONDAY' })
  evaluationDay!: string;

  @ApiProperty({ example: 'Africa/Cairo' })
  timezone!: string;

  @ApiProperty({ type: Date })
  nextEvaluationAt!: Date;

  @ApiProperty({ type: RankingWeekWindowDto })
  currentWeek!: RankingWeekWindowDto;

  @ApiProperty({ type: RankingWeekWindowDto })
  lastCompletedWeek!: RankingWeekWindowDto;

  @ApiPropertyOptional({
    type: DriverRankingEvaluationRunDto,
    nullable: true,
  })
  latestRun?: DriverRankingEvaluationRunDto | null;

  @ApiPropertyOptional({
    type: DriverRankingEvaluationRunDto,
    nullable: true,
  })
  lastCompletedWeekRun?: DriverRankingEvaluationRunDto | null;
}

export class DriverRankingPreviewItemDto {
  @ApiProperty()
  driverId!: string;

  @ApiProperty()
  driverName!: string;

  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  previousTier!: DriverTier;

  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  newTier!: DriverTier;

  @ApiProperty({
    enum: DriverRankChangeReason,
    enumName: 'DriverRankChangeReason',
  })
  changeReason!: DriverRankChangeReason;

  @ApiProperty({
    enum: DriverRankingOutcome,
    enumName: 'DriverRankingOutcome',
  })
  outcome!: DriverRankingOutcome;

  @ApiPropertyOptional({ nullable: true, type: Number })
  performancePercentage?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  acceptanceRate?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  completionRate?: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  shiftPunctualityRate?: number | null;

  @ApiProperty({ type: DriverMetricsSnapshotDto })
  metricsSnapshot!: DriverMetricsSnapshotDto;

  @ApiProperty({ type: [String] })
  explanations!: string[];
}

export class QueryRankingPreviewDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 200 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  limit?: number = 50;

  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @ApiPropertyOptional({ enum: DriverTier, enumName: 'DriverTier' })
  @IsOptional()
  @IsEnum(DriverTier)
  tier?: DriverTier;
}

export class QueryRunDetailsDto extends QueryRankingPreviewDto {}

export class DriverRankingPaginationMetaDto {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  totalPages!: number;
}

export class DriverRankingPreviewResponseDto {
  @ApiProperty({ type: RankingWeekWindowDto })
  week!: RankingWeekWindowDto;

  @ApiProperty()
  alreadyExecuted!: boolean;

  @ApiProperty({ type: Number })
  totalDrivers!: number;

  @ApiProperty({ type: Number })
  promotedCount!: number;

  @ApiProperty({ type: Number })
  demotedCount!: number;

  @ApiProperty({ type: Number })
  unchangedCount!: number;

  @ApiProperty({ type: Number })
  inactiveCount!: number;

  @ApiProperty({ type: [DriverRankingPreviewItemDto] })
  drivers!: DriverRankingPreviewItemDto[];

  @ApiProperty({ type: DriverRankingPaginationMetaDto })
  meta!: DriverRankingPaginationMetaDto;
}

export class DriverRankHistoryEntryDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  driverId!: string;

  @ApiPropertyOptional({ nullable: true })
  driverName?: string | null;

  @ApiPropertyOptional({ nullable: true })
  runId?: string | null;

  @ApiPropertyOptional({ nullable: true })
  periodKey?: string | null;

  @ApiProperty({ type: Date })
  evaluatedAt!: Date;

  @ApiPropertyOptional({ type: Date, nullable: true })
  periodStart?: Date | null;

  @ApiPropertyOptional({ type: Date, nullable: true })
  periodEnd?: Date | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  performancePercentage?: number | null;

  @ApiPropertyOptional({ type: DriverMetricsSnapshotDto, nullable: true })
  metricsSnapshot?: DriverMetricsSnapshotDto | null;

  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  previousTier!: DriverTier;

  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  newTier!: DriverTier;

  @ApiProperty({
    enum: DriverRankChangeReason,
    enumName: 'DriverRankChangeReason',
  })
  changeReason!: DriverRankChangeReason;

  @ApiPropertyOptional({ nullable: true })
  adminUserId?: string | null;

  @ApiPropertyOptional({ nullable: true })
  overrideReason?: string | null;

  @ApiProperty({ type: Date })
  createdAt!: Date;
}

export class PaginatedRankingRunsResponseDto {
  @ApiProperty({ type: [DriverRankingEvaluationRunDto] })
  data!: DriverRankingEvaluationRunDto[];

  @ApiProperty({ type: DriverRankingPaginationMetaDto })
  meta!: DriverRankingPaginationMetaDto;
}

export class PaginatedDriverRankHistoryResponseDto {
  @ApiProperty({ type: [DriverRankHistoryEntryDto] })
  data!: DriverRankHistoryEntryDto[];

  @ApiProperty({ type: DriverRankingPaginationMetaDto })
  meta!: DriverRankingPaginationMetaDto;
}

export class DriverRankingRunDetailsResponseDto {
  @ApiProperty({ type: DriverRankingEvaluationRunDto })
  run!: DriverRankingEvaluationRunDto;

  @ApiProperty({ type: [DriverRankHistoryEntryDto] })
  entries!: DriverRankHistoryEntryDto[];

  @ApiProperty({ type: DriverRankingPaginationMetaDto })
  meta!: DriverRankingPaginationMetaDto;
}

export class DriverDeliveryIncidentDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  orderId!: string;

  @ApiPropertyOptional({ nullable: true })
  orderNumber?: string | null;

  @ApiProperty()
  deliveryGroupId!: string;

  @ApiProperty()
  driverId!: string;

  @ApiPropertyOptional({ nullable: true })
  driverName?: string | null;

  @ApiProperty({ enum: DeliveryIncidentType, enumName: 'DeliveryIncidentType' })
  incidentType!: DeliveryIncidentType;

  @ApiProperty({
    enum: DeliveryIncidentResponsibility,
    enumName: 'DeliveryIncidentResponsibility',
  })
  responsibility!: DeliveryIncidentResponsibility;

  @ApiPropertyOptional({ nullable: true })
  reason?: string | null;

  @ApiPropertyOptional({ nullable: true })
  reportedByUserId?: string | null;

  @ApiPropertyOptional({ nullable: true })
  reviewedByUserId?: string | null;

  @ApiPropertyOptional({ type: Date, nullable: true })
  reviewedAt?: Date | null;

  @ApiPropertyOptional({ nullable: true })
  reviewNote?: string | null;

  @ApiProperty({ type: Date })
  occurredAt!: Date;

  @ApiProperty({ type: Date })
  createdAt!: Date;
}

export class PaginatedDeliveryIncidentsResponseDto {
  @ApiProperty({ type: [DriverDeliveryIncidentDto] })
  data!: DriverDeliveryIncidentDto[];

  @ApiProperty({ type: DriverRankingPaginationMetaDto })
  meta!: DriverRankingPaginationMetaDto;
}

export class DriverMyRankSummaryResponseDto {
  @ApiProperty()
  driverId!: string;

  @ApiProperty({ enum: DriverTier, enumName: 'DriverTier' })
  currentTier!: DriverTier;

  @ApiProperty()
  timezone!: string;

  @ApiProperty({ type: Date })
  nextEvaluationAt!: Date;

  @ApiProperty({ type: RankingWeekWindowDto })
  currentWeek!: RankingWeekWindowDto;

  @ApiPropertyOptional({ type: DriverRankingPreviewItemDto, nullable: true })
  currentWeekProgress?: DriverRankingPreviewItemDto | null;

  @ApiPropertyOptional({ type: DriverRankHistoryEntryDto, nullable: true })
  latestEvaluation?: DriverRankHistoryEntryDto | null;

  @ApiProperty({ type: [DriverRankHistoryEntryDto] })
  recentHistory!: DriverRankHistoryEntryDto[];
}
