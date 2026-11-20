import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DriverRankChangeReason,
  DriverRankingRunStatus,
  DriverRankingTriggerSource,
  Role,
} from '@prisma/client';
import { DriverErrors } from '../../../common/constants/response.constants';
import {
  AuditLogCreatedEvent,
  DriverRankEvaluationFailedEvent,
  DriverRankUpdatedEvent,
} from '../../../common/events';
import { EVENTS } from '../../../common/events/event-names';
import type { JwtAccessPayload } from '../../../common/interfaces/jwt-payload.interface';
import {
  appTimeZone,
  formatEvalTimeHhMm,
  getCairoWeekBounds,
  getNextScheduledEvaluationUtc,
  getPreviousCompletedCairoWeek,
  getScheduledEvaluationUtcForCompletedWeek,
  tzParts,
} from '../../../common/utils/timezone';
import { PlatformSettingsService } from '../../platform-settings/platform-settings.service';
import { DriverManagersService } from '../driver-managers.service';
import {
  DriverWeeklyEvaluationResult,
  evaluateDriverWeeklyMetrics,
  summarizeRankTransitions,
} from './driver-ranking.calculator';
import {
  DriverRankingRepository,
  EVALUATION_COMMIT_BATCH_SIZE,
  STALE_RUNNING_RUN_MS,
} from './driver-ranking.repository';
import {
  OverrideDriverRankDto,
  QueryDriverRankHistoryDto,
  QueryRankingPreviewDto,
  QueryRankingRunsDto,
  QueryRunDetailsDto,
} from './dto/driver-ranking.dto';

@Injectable()
export class DriverRankingService {
  private readonly logger = new Logger(DriverRankingService.name);

  constructor(
    private readonly rankingRepository: DriverRankingRepository,
    private readonly platformSettings: PlatformSettingsService,
    private readonly driverManagersService: DriverManagersService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // ─── Schedule & Dry Run ───────────────────────────────────────────────────

  async getScheduleStatus() {
    const now = new Date();
    const tz = appTimeZone();
    const settings = await this.platformSettings.getSettings();
    const evalTime = formatEvalTimeHhMm(settings.driverRankingEvalTime);

    const currentWeek = getCairoWeekBounds(now, tz);
    const lastCompletedWeek = getPreviousCompletedCairoWeek(now, tz);

    const [latestRun, lastCompletedWeekRun] = await Promise.all([
      this.rankingRepository.findLatestRun(),
      this.rankingRepository.findRunByPeriodKey(lastCompletedWeek.periodKey),
    ]);

    const autoEvalEnabled = settings.driverRankingAutoEvalEnabled ?? true;
    const nextEvaluationAt = getNextScheduledEvaluationUtc(
      now,
      evalTime,
      Boolean(lastCompletedWeekRun),
      tz,
      autoEvalEnabled,
    );

    return {
      enabled: autoEvalEnabled,
      evalTime,
      frequency: 'WEEKLY',
      evaluationDay: 'MONDAY',
      timezone: tz,
      nextEvaluationAt,
      currentWeek: {
        periodKey: currentWeek.periodKey,
        periodStart: currentWeek.periodStart,
        periodEnd: currentWeek.periodEnd,
      },
      lastCompletedWeek: {
        periodKey: lastCompletedWeek.periodKey,
        periodStart: lastCompletedWeek.periodStart,
        periodEnd: lastCompletedWeek.periodEnd,
      },
      latestRun,
      lastCompletedWeekRun,
    };
  }

  async previewEvaluation(
    actor?: JwtAccessPayload,
    dto?: QueryRankingPreviewDto,
  ) {
    const now = new Date();
    const tz = appTimeZone();
    const week = getPreviousCompletedCairoWeek(now, tz);
    const scopedDriverIds = await this.resolveScopedDriverIds(actor);

    const [existingRun, results] = await Promise.all([
      this.rankingRepository.findRunByPeriodKey(week.periodKey),
      this.collectAndEvaluatePeriod(
        week.periodStart,
        week.periodEnd,
        scopedDriverIds,
        now,
      ),
    ]);

    const sortedResults = [...results].sort((a, b) => {
      if (a.performancePercentage === null && b.performancePercentage !== null) {
        return 1;
      }
      if (a.performancePercentage !== null && b.performancePercentage === null) {
        return -1;
      }
      if (
        a.performancePercentage !== null &&
        b.performancePercentage !== null &&
        b.performancePercentage !== a.performancePercentage
      ) {
        return b.performancePercentage - a.performancePercentage;
      }
      return a.driverName.localeCompare(b.driverName);
    });

    const counts = summarizeRankTransitions(sortedResults);
    const page = dto?.page ?? 1;
    const limit = dto?.limit ?? 50;
    const cleanSearch = dto?.search?.trim().toLowerCase();
    const filteredResults = sortedResults.filter((item) => {
      if (dto?.tier && item.newTier !== dto.tier) return false;
      if (cleanSearch && !item.driverName.toLowerCase().includes(cleanSearch)) {
        return false;
      }
      return true;
    });

    const total = filteredResults.length;
    const skip = (page - 1) * limit;
    const pagedResults = filteredResults.slice(skip, skip + limit);

    return {
      week: {
        periodKey: week.periodKey,
        periodStart: week.periodStart,
        periodEnd: week.periodEnd,
      },
      alreadyExecuted: existingRun?.status === DriverRankingRunStatus.COMPLETED,
      ...counts,
      drivers: pagedResults,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // ─── Scheduled Checker & Manual Evaluation ────────────────────────────────

  async checkAndRunScheduledEvaluation(): Promise<void> {
    try {
      const settings = await this.platformSettings.getSettings();
      if (!settings.driverRankingAutoEvalEnabled) return;

      const now = new Date();
      const tz = appTimeZone();
      const week = getPreviousCompletedCairoWeek(now, tz);

      const existing = await this.rankingRepository.findRunByPeriodKey(
        week.periodKey,
      );
      if (existing) {
        // Recover stuck RUNNING runs caused by worker crash/restart after TTL.
        if (
          existing.status === DriverRankingRunStatus.RUNNING &&
          existing.updatedAt &&
          now.getTime() - existing.updatedAt.getTime() >= STALE_RUNNING_RUN_MS
        ) {
          const timeoutMsg =
            'Evaluation run timed out or worker restarted before completion.';
          const reclaimed = await this.rankingRepository.failStaleRunningRun(
            existing.id,
            new Date(now.getTime() - STALE_RUNNING_RUN_MS),
            timeoutMsg,
          );
          if (reclaimed > 0) {
            this.eventEmitter.emit(
              EVENTS.DRIVER_RANK_EVALUATION_FAILED,
              new DriverRankEvaluationFailedEvent(
                existing.id,
                existing.periodKey,
                timeoutMsg,
              ),
            );
            this.logger.error(
              `Marked stale RUNNING driver ranking run ${existing.periodKey} as FAILED`,
            );
          }
        }
        return;
      }

      // Automatic evaluations execute strictly on Mondays in `tz` so mid-week
      // initial deploys or mid-week schedule edits affect future Mondays only.
      if (tzParts(now, tz).weekday !== 1) {
        return;
      }

      const scheduledFor = getScheduledEvaluationUtcForCompletedWeek(
        now,
        settings.driverRankingEvalTime,
        tz,
      );
      if (now.getTime() < scheduledFor.getTime()) {
        return;
      }

      await this.runEvaluation({
        triggerSource: DriverRankingTriggerSource.SCHEDULED,
        triggeredByUserId: null,
        scheduledFor,
      });
    } catch (error: unknown) {
      if (error instanceof ConflictException) {
        return;
      }
      this.logger.error(
        `Scheduled driver ranking evaluation check failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  async runEvaluation(params: {
    triggerSource: DriverRankingTriggerSource;
    triggeredByUserId?: string | null;
    scheduledFor?: Date;
  }) {
    const now = new Date();
    const tz = appTimeZone();
    const settings = await this.platformSettings.getSettings();
    const week = getPreviousCompletedCairoWeek(now, tz);
    const scheduledFor =
      params.scheduledFor ??
      getScheduledEvaluationUtcForCompletedWeek(
        now,
        settings.driverRankingEvalTime,
        tz,
      );

    let run;
    try {
      run = await this.rankingRepository.createRun({
        periodKey: week.periodKey,
        triggerSource: params.triggerSource,
        triggeredByUserId: params.triggeredByUserId ?? null,
        scheduledFor,
        periodStart: week.periodStart,
        periodEnd: week.periodEnd,
      });
    } catch (error: unknown) {
      if (this.isUniqueViolation(error)) {
        throw new ConflictException(DriverErrors.RANK_EVALUATION_ALREADY_EXISTS);
      }
      throw error;
    }

    return this.executeRun(run);
  }

  async retryFailedRun(runId: string, actor: JwtAccessPayload) {
    const existing = await this.rankingRepository.findRunById(runId);
    if (!existing) {
      throw new NotFoundException(DriverErrors.RANK_EVALUATION_NOT_FOUND);
    }

    const staleCutoff = new Date(Date.now() - STALE_RUNNING_RUN_MS);
    const isStaleRunning =
      existing.status === DriverRankingRunStatus.RUNNING &&
      existing.updatedAt != null &&
      existing.updatedAt.getTime() < staleCutoff.getTime();

    if (
      existing.status !== DriverRankingRunStatus.FAILED &&
      !isStaleRunning
    ) {
      throw new ConflictException(DriverErrors.RANK_EVALUATION_NOT_FAILED);
    }

    const claimed = await this.rankingRepository.claimRetryableRun(
      runId,
      actor.sub,
      staleCutoff,
    );
    if (claimed === 0) {
      throw new ConflictException(DriverErrors.RANK_EVALUATION_NOT_FAILED);
    }

    const run = await this.rankingRepository.findRunByIdOrThrow(runId);
    return this.executeRun(run);
  }

  private async executeRun(run: {
    id: string;
    periodKey: string;
    periodStart: Date;
    periodEnd: Date;
  }) {
    try {
      const now = new Date();
      const [alreadyCommittedDriverIds, results] = await Promise.all([
        this.rankingRepository.findCommittedDriverIds(run.id),
        this.collectAndEvaluatePeriod(run.periodStart, run.periodEnd, null, now),
      ]);

      const pendingResults = results.filter(
        (r) => !alreadyCommittedDriverIds.has(r.driverId),
      );
      const evaluatedAt = new Date();

      for (
        let offset = 0;
        offset < pendingResults.length;
        offset += EVALUATION_COMMIT_BATCH_SIZE
      ) {
        const chunk = pendingResults.slice(
          offset,
          offset + EVALUATION_COMMIT_BATCH_SIZE,
        );
        const committed =
          await this.rankingRepository.commitDriverEvaluationBatchInTx(
            run,
            chunk,
            evaluatedAt,
          );

        for (const item of committed) {
          if (item.previousTier !== item.result.newTier && item.userId) {
            try {
              this.eventEmitter.emit(
                EVENTS.DRIVER_RANK_UPDATED,
                new DriverRankUpdatedEvent(
                  item.result.driverId,
                  item.userId,
                  item.previousTier,
                  item.result.newTier,
                  item.result.performancePercentage,
                  run.periodKey,
                  item.result.changeReason,
                ),
              );
            } catch (emitErr: unknown) {
              this.logger.warn(
                `Failed to emit DRIVER_RANK_UPDATED for driver ${item.result.driverId}: ${emitErr instanceof Error ? emitErr.message : String(emitErr)}`,
              );
            }
          }
        }

        if (offset + chunk.length < pendingResults.length) {
          await this.rankingRepository
            .touchRunHeartbeat(run.id)
            .catch(() => undefined);
        }
      }

      const allEntries =
        await this.rankingRepository.findAllRunEntriesSummary(run.id);
      const counts = summarizeRankTransitions(allEntries);
      const completedRun = await this.rankingRepository.completeRun(
        run.id,
        counts,
      );

      this.logger.log(
        `Completed weekly driver ranking run ${run.periodKey}: total=${counts.totalDrivers}, promoted=${counts.promotedCount}, demoted=${counts.demotedCount}, inactive=${counts.inactiveCount}`,
      );
      return completedRun;
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : String(error);
      await this.rankingRepository
        .markRunFailed(run.id, msg)
        .catch(() => undefined);

      this.eventEmitter.emit(
        EVENTS.DRIVER_RANK_EVALUATION_FAILED,
        new DriverRankEvaluationFailedEvent(run.id, run.periodKey, msg),
      );
      this.logger.error(
        `Weekly driver ranking run ${run.periodKey} FAILED: ${msg}`,
      );
      throw error;
    }
  }

  // ─── Admin Manual Override ────────────────────────────────────────────────

  async overrideDriverTier(
    driverId: string,
    dto: OverrideDriverRankDto,
    actor: JwtAccessPayload,
  ) {
    const cleanReason = dto.reason?.trim() ?? '';
    if (!cleanReason) {
      throw new BadRequestException(DriverErrors.RANK_OVERRIDE_REASON_REQUIRED);
    }

    const result = await this.rankingRepository.overrideDriverTierTransaction({
      driverId,
      newTier: dto.newTier,
      adminUserId: actor.sub,
      reason: cleanReason,
    });

    this.eventEmitter.emit(
      EVENTS.AUDIT_LOG_CREATED,
      new AuditLogCreatedEvent(
        actor.sub,
        null,
        null,
        'UPDATE',
        'OVERRIDE_DRIVER_TIER',
        'Driver',
        driverId,
        { tier: dto.newTier, reason: cleanReason },
        { tier: result.previousTier },
      ),
    );

    if (result.tierChanged) {
      this.eventEmitter.emit(
        EVENTS.DRIVER_RANK_UPDATED,
        new DriverRankUpdatedEvent(
          driverId,
          result.userId,
          result.previousTier,
          dto.newTier,
          null,
          null,
          DriverRankChangeReason.ADMIN_OVERRIDE,
          cleanReason,
        ),
      );
    }

    return result.historyEntry;
  }

  // ─── Queries (Runs, History, Driver Self View) ────────────────────────────

  async listRuns(dto: QueryRankingRunsDto) {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const skip = (page - 1) * limit;

    const [data, total] = await this.rankingRepository.listRuns(skip, limit);

    return {
      data,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async getRunDetails(
    runId: string,
    actor?: JwtAccessPayload,
    dto?: QueryRunDetailsDto,
  ) {
    const run = await this.rankingRepository.findRunById(runId);
    if (!run) {
      throw new NotFoundException(DriverErrors.RANK_EVALUATION_NOT_FOUND);
    }

    const page = dto?.page ?? 1;
    const limit = dto?.limit ?? 50;
    const skip = (page - 1) * limit;
    const scopedDriverIds = await this.resolveScopedDriverIds(actor);

    const [entries, total] =
      await this.rankingRepository.findRunEntriesWithDriver({
        runId,
        scopedDriverIds,
        search: dto?.search,
        tier: dto?.tier,
        skip,
        take: limit,
      });

    return {
      run,
      entries: entries.map(({ driver, ...rest }) => ({
        ...rest,
        driverName: driver.name,
        periodKey: run.periodKey,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getDriverRankHistory(
    driverId: string,
    dto: QueryDriverRankHistoryDto,
    actor?: JwtAccessPayload,
  ) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      await this.driverManagersService.assertManagesDriver(actor.sub, driverId);
    }

    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const skip = (page - 1) * limit;

    const [rows, total] = await this.rankingRepository.findDriverRankHistory(
      driverId,
      skip,
      limit,
    );

    return {
      data: rows.map(({ driver, run, ...rest }) => ({
        ...rest,
        driverName: driver.name,
        periodKey: run?.periodKey ?? null,
      })),
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async getMyRankSummary(userId: string) {
    const driver = await this.rankingRepository.findDriverBasicByUserId(userId);
    if (!driver) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }

    const now = new Date();
    const tz = appTimeZone();
    const settings = await this.platformSettings.getSettings();
    const currentWeek = getCairoWeekBounds(now, tz);
    const lastCompletedWeek = getPreviousCompletedCairoWeek(now, tz);

    const [lastCompletedWeekRun, historyRows, progressResults] =
      await Promise.all([
        this.rankingRepository.findRunByPeriodKey(lastCompletedWeek.periodKey),
        this.rankingRepository.findRecentDriverRankHistory(driver.id, 12),
        this.collectAndEvaluatePeriod(
          currentWeek.periodStart,
          currentWeek.periodEnd,
          [driver.id],
          now,
        ),
      ]);

    const nextEvaluationAt = getNextScheduledEvaluationUtc(
      now,
      settings.driverRankingEvalTime,
      Boolean(lastCompletedWeekRun),
      tz,
      settings.driverRankingAutoEvalEnabled ?? true,
    );

    const recentHistory = historyRows.map(({ run, ...rest }) => ({
      ...rest,
      driverName: driver.name,
      periodKey: run?.periodKey ?? null,
    }));

    return {
      driverId: driver.id,
      currentTier: driver.tier,
      timezone: tz,
      nextEvaluationAt,
      currentWeek: {
        periodKey: currentWeek.periodKey,
        periodStart: currentWeek.periodStart,
        periodEnd: currentWeek.periodEnd,
      },
      currentWeekProgress: progressResults[0] ?? null,
      latestEvaluation: recentHistory[0] ?? null,
      recentHistory,
    };
  }

  // ─── Core Evaluation Wrapper ──────────────────────────────────────────────

  async collectAndEvaluatePeriod(
    periodStart: Date,
    periodEnd: Date,
    scopedDriverIds: string[] | null,
    asOf: Date = new Date(),
  ): Promise<DriverWeeklyEvaluationResult[]> {
    const inputs = await this.rankingRepository.collectWeeklyMetricInputs(
      periodStart,
      periodEnd,
      asOf,
      scopedDriverIds,
    );
    return inputs.map((input) => evaluateDriverWeeklyMetrics(input));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private async resolveScopedDriverIds(
    actor?: JwtAccessPayload,
  ): Promise<string[] | null> {
    if (actor?.role === Role.DRIVER_MANAGER) {
      return this.driverManagersService.getManagedDriverIds(actor.sub);
    }
    return null;
  }

  private isUniqueViolation(err: unknown): boolean {
    return (
      typeof err === 'object' &&
      err !== null &&
      'code' in err &&
      (err as { code?: string }).code === 'P2002'
    );
  }
}
