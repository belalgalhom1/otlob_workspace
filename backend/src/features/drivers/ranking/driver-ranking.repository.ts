import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DeliveryIncidentResponsibility,
  DispatchStatus,
  DriverRankChangeReason,
  DriverRankingRunStatus,
  DriverRankingTriggerSource,
  DriverStatus,
  DriverTier,
  Prisma,
} from '@prisma/client';
import { DriverErrors } from '../../../common/constants/response.constants';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import {
  classifyShiftForRanking,
  DriverRankingOutcome,
  DriverWeeklyEvaluationResult,
  DriverWeeklyMetricInput,
  SHIFT_GRACE_MINUTES,
} from './driver-ranking.calculator';

export const STALE_RUNNING_RUN_MS = 15 * 60_000;
export const EVALUATION_COMMIT_BATCH_SIZE = 50;

@Injectable()
export class DriverRankingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async collectWeeklyMetricInputs(
    periodStart: Date,
    periodEnd: Date,
    asOf: Date,
    scopedDriverIds: string[] | null,
  ): Promise<DriverWeeklyMetricInput[]> {
    if (scopedDriverIds && scopedDriverIds.length === 0) {
      return [];
    }

    const drivers = await this.prisma.driver.findMany({
      where: {
        deletedAt: null,
        isApproved: true,
        ...(scopedDriverIds ? { id: { in: scopedDriverIds } } : {}),
      },
      select: { id: true, name: true, tier: true, status: true },
      orderBy: { name: 'asc' },
    });
    if (drivers.length === 0) return [];

    const driverIds = drivers.map((d) => d.id);
    const driverScopeFilter =
      scopedDriverIds !== null ? { in: driverIds } : undefined;

    const [dispatchGroups, completedGroups, incidents, shifts] =
      await Promise.all([
        this.prisma.orderDispatch.groupBy({
          by: ['driverId', 'status'],
          where: {
            ...(driverScopeFilter ? { driverId: driverScopeFilter } : {}),
            createdAt: { gte: periodStart, lte: periodEnd },
          },
          _count: { _all: true },
        }),
        this.prisma.orderDeliveryGroup.groupBy({
          by: ['primaryDriverId'],
          where: {
            primaryDriverId: driverScopeFilter ?? { not: null },
            status: DeliveryGroupStatus.DELIVERED,
            deliveredAt: { gte: periodStart, lte: periodEnd },
          },
          _count: { _all: true },
        }),
        this.prisma.driverDeliveryIncident.findMany({
          where: {
            ...(driverScopeFilter ? { driverId: driverScopeFilter } : {}),
            occurredAt: { gte: periodStart, lte: periodEnd },
          },
          select: {
            driverId: true,
            deliveryGroupId: true,
            responsibility: true,
          },
        }),
        this.prisma.driverShift.findMany({
          where: {
            ...(driverScopeFilter ? { driverId: driverScopeFilter } : {}),
            startTime: { gte: periodStart, lte: periodEnd },
          },
          select: {
            driverId: true,
            status: true,
            startTime: true,
            actualStart: true,
            isExcused: true,
          },
        }),
      ]);

    const inputByDriver = new Map<string, DriverWeeklyMetricInput>();
    for (const d of drivers) {
      inputByDriver.set(d.id, {
        driverId: d.id,
        driverName: d.name,
        currentTier: d.tier,
        isSuspended: d.status === DriverStatus.SUSPENDED,
        acceptedDispatches: 0,
        rejectedDispatches: 0,
        expiredDispatches: 0,
        cancelledDispatches: 0,
        completedOrders: 0,
        driverFaultFailures: 0,
        excludedIncidents: {
          customer: 0,
          vendor: 0,
          externalOrSystem: 0,
          underReview: 0,
        },
        onTimeShifts: 0,
        lateShifts: 0,
        missedShifts: 0,
        cancelledShifts: 0,
        excusedShifts: 0,
      });
    }

    for (const row of dispatchGroups) {
      const target = inputByDriver.get(row.driverId);
      if (!target) continue;
      const c = row._count._all;
      if (row.status === DispatchStatus.ACCEPTED) {
        target.acceptedDispatches += c;
      } else if (row.status === DispatchStatus.REJECTED) {
        target.rejectedDispatches += c;
      } else if (row.status === DispatchStatus.EXPIRED) {
        target.expiredDispatches += c;
      } else if (row.status === DispatchStatus.CANCELLED) {
        target.cancelledDispatches += c;
      }
    }

    for (const row of completedGroups) {
      if (!row.primaryDriverId) continue;
      const target = inputByDriver.get(row.primaryDriverId);
      if (!target) continue;
      target.completedOrders += row._count._all;
    }

    const driverFaultGroupKeys = new Set<string>();
    for (const inc of incidents) {
      const target = inputByDriver.get(inc.driverId);
      if (!target) continue;
      switch (inc.responsibility) {
        case DeliveryIncidentResponsibility.DRIVER_AT_FAULT: {
          const dedupeKey = `${inc.driverId}:${inc.deliveryGroupId}`;
          if (!driverFaultGroupKeys.has(dedupeKey)) {
            driverFaultGroupKeys.add(dedupeKey);
            target.driverFaultFailures += 1;
          }
          break;
        }
        case DeliveryIncidentResponsibility.CUSTOMER:
          target.excludedIncidents.customer += 1;
          break;
        case DeliveryIncidentResponsibility.VENDOR:
          target.excludedIncidents.vendor += 1;
          break;
        case DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM:
          target.excludedIncidents.externalOrSystem += 1;
          break;
        case DeliveryIncidentResponsibility.UNDER_REVIEW:
          target.excludedIncidents.underReview += 1;
          break;
      }
    }

    const effectiveEndMs = Math.min(periodEnd.getTime(), asOf.getTime());
    const graceMs = SHIFT_GRACE_MINUTES * 60_000;
    for (const shift of shifts) {
      const target = inputByDriver.get(shift.driverId);
      if (!target) continue;
      const bucket = classifyShiftForRanking(shift, effectiveEndMs, graceMs);
      switch (bucket) {
        case 'excused':
          target.excusedShifts += 1;
          break;
        case 'cancelled':
          target.cancelledShifts += 1;
          break;
        case 'missed':
          target.missedShifts += 1;
          break;
        case 'onTime':
          target.onTimeShifts += 1;
          break;
        case 'late':
          target.lateShifts += 1;
          break;
        case 'upcoming':
          break;
      }
    }

    return drivers.map((d) => inputByDriver.get(d.id)!);
  }

  findLatestRun() {
    return this.prisma.driverRankingEvaluationRun.findFirst({
      orderBy: { createdAt: 'desc' },
    });
  }

  findRunByPeriodKey(periodKey: string) {
    return this.prisma.driverRankingEvaluationRun.findUnique({
      where: { periodKey },
    });
  }

  findRunById(runId: string) {
    return this.prisma.driverRankingEvaluationRun.findUnique({
      where: { id: runId },
    });
  }

  findRunByIdOrThrow(runId: string) {
    return this.prisma.driverRankingEvaluationRun.findUniqueOrThrow({
      where: { id: runId },
    });
  }

  createRun(data: {
    periodKey: string;
    triggerSource: DriverRankingTriggerSource;
    triggeredByUserId: string | null;
    scheduledFor: Date;
    periodStart: Date;
    periodEnd: Date;
  }) {
    return this.prisma.driverRankingEvaluationRun.create({
      data: {
        ...data,
        status: DriverRankingRunStatus.RUNNING,
      },
    });
  }

  async claimRetryableRun(
    runId: string,
    actorUserId: string,
    staleCutoff: Date,
  ): Promise<number> {
    const res = await this.prisma.driverRankingEvaluationRun.updateMany({
      where: {
        id: runId,
        OR: [
          { status: DriverRankingRunStatus.FAILED },
          {
            status: DriverRankingRunStatus.RUNNING,
            updatedAt: { lt: staleCutoff },
          },
        ],
      },
      data: {
        status: DriverRankingRunStatus.RUNNING,
        errorMessage: null,
        triggeredByUserId: actorUserId,
      },
    });
    return res.count;
  }

  async failStaleRunningRun(
    runId: string,
    staleCutoff: Date,
    errorMessage: string,
  ): Promise<number> {
    const res = await this.prisma.driverRankingEvaluationRun.updateMany({
      where: {
        id: runId,
        status: DriverRankingRunStatus.RUNNING,
        updatedAt: { lt: staleCutoff },
      },
      data: {
        status: DriverRankingRunStatus.FAILED,
        errorMessage: errorMessage.slice(0, 1000),
      },
    });
    return res.count;
  }

  async touchRunHeartbeat(runId: string): Promise<void> {
    await this.prisma.driverRankingEvaluationRun.updateMany({
      where: { id: runId, status: DriverRankingRunStatus.RUNNING },
      data: { updatedAt: new Date() },
    });
  }

  completeRun(
    runId: string,
    counts: {
      totalDrivers: number;
      promotedCount: number;
      demotedCount: number;
      unchangedCount: number;
      inactiveCount: number;
    },
  ) {
    return this.prisma.driverRankingEvaluationRun.update({
      where: { id: runId },
      data: {
        status: DriverRankingRunStatus.COMPLETED,
        executedAt: new Date(),
        ...counts,
        errorMessage: null,
      },
    });
  }

  markRunFailed(runId: string, errorMessage: string) {
    return this.prisma.driverRankingEvaluationRun.update({
      where: { id: runId },
      data: {
        status: DriverRankingRunStatus.FAILED,
        errorMessage: errorMessage.slice(0, 1000),
      },
    });
  }

  async findCommittedDriverIds(runId: string): Promise<Set<string>> {
    const committedRows = await this.prisma.driverRankHistory.findMany({
      where: { runId },
      select: { driverId: true },
    });
    return new Set(committedRows.map((r) => r.driverId));
  }

  async commitDriverEvaluationBatchInTx(
    run: { id: string; periodStart: Date; periodEnd: Date },
    results: DriverWeeklyEvaluationResult[],
    evaluatedAt: Date,
  ): Promise<
    Array<{
      result: DriverWeeklyEvaluationResult;
      previousTier: DriverTier;
      userId: string;
    }>
  > {
    if (results.length === 0) return [];

    const dedupedResults: DriverWeeklyEvaluationResult[] = [];
    const seenDriverIds = new Set<string>();
    for (const r of results) {
      if (seenDriverIds.has(r.driverId)) continue;
      seenDriverIds.add(r.driverId);
      dedupedResults.push(r);
    }

    const batchDriverIds = dedupedResults.map((r) => r.driverId);
    const sortedLockIds = [...batchDriverIds].sort();

    return this.prisma.$transaction(async (tx) => {
      if (typeof tx.$executeRaw === 'function') {
        await tx.$executeRaw`SELECT id FROM drivers WHERE id IN (${Prisma.join(sortedLockIds)}) ORDER BY id FOR UPDATE`;
      }

      const [freshDrivers, existingEntries] = await Promise.all([
        tx.driver.findMany({
          where: { id: { in: batchDriverIds } },
          select: { id: true, tier: true, userId: true },
        }),
        tx.driverRankHistory.findMany({
          where: {
            runId: run.id,
            driverId: { in: batchDriverIds },
          },
          select: { driverId: true },
        }),
      ]);

      const freshDriverById = new Map(freshDrivers.map((d) => [d.id, d]));
      const existingDriverIds = new Set(existingEntries.map((e) => e.driverId));

      const pendingCommits: Array<{
        result: DriverWeeklyEvaluationResult;
        previousTier: DriverTier;
        userId: string;
      }> = [];
      const historyRowsToCreate: Prisma.DriverRankHistoryCreateManyInput[] = [];
      const driverIdsByNewTier = new Map<DriverTier, string[]>();

      for (const result of dedupedResults) {
        const freshDriver = freshDriverById.get(result.driverId);
        if (!freshDriver) continue;
        if (existingDriverIds.has(result.driverId)) continue;

        const previousTier = freshDriver.tier;
        // If a suspended driver had zero activity (outcome UNCHANGED), preserve
        // their locked freshDriver.tier so a concurrent manual override is never reverted.
        const effectiveNewTier =
          result.changeReason === DriverRankChangeReason.INACTIVE_DRIVER &&
          result.outcome === DriverRankingOutcome.UNCHANGED
            ? previousTier
            : result.newTier;
        const effectiveResult =
          effectiveNewTier === result.newTier
            ? result
            : { ...result, newTier: effectiveNewTier };

        pendingCommits.push({
          result: effectiveResult,
          previousTier,
          userId: freshDriver.userId,
        });

        historyRowsToCreate.push({
          driverId: result.driverId,
          runId: run.id,
          evaluatedAt,
          periodStart: run.periodStart,
          periodEnd: run.periodEnd,
          performancePercentage: result.performancePercentage,
          metricsSnapshot:
            result.metricsSnapshot as unknown as Prisma.InputJsonValue,
          previousTier,
          newTier: effectiveNewTier,
          changeReason: result.changeReason,
        });

        if (previousTier !== effectiveNewTier) {
          const group = driverIdsByNewTier.get(effectiveNewTier) ?? [];
          group.push(result.driverId);
          driverIdsByNewTier.set(effectiveNewTier, group);
        }
      }

      if (historyRowsToCreate.length === 0) {
        return [];
      }

      await tx.driverRankHistory.createMany({
        data: historyRowsToCreate,
        skipDuplicates: true,
      });

      for (const [tier, ids] of driverIdsByNewTier.entries()) {
        await tx.driver.updateMany({
          where: { id: { in: ids } },
          data: { tier },
        });
      }

      return pendingCommits;
    });
  }

  async applyManualTierOverrideInTx(
    tx: Prisma.TransactionClient,
    params: {
      driverId: string;
      newTier: DriverTier;
      adminUserId: string;
      reason: string;
      extraDriverUpdateData?: Prisma.DriverUpdateInput;
      fallbackDriver?: { id: string; userId: string; tier: DriverTier };
    },
  ) {
    if (typeof tx.$executeRaw === 'function') {
      await tx.$executeRaw`SELECT id FROM drivers WHERE id = ${params.driverId} FOR UPDATE`;
    }

    const freshDriver =
      typeof tx.driver?.findUnique === 'function'
        ? await tx.driver.findUnique({
            where: { id: params.driverId, deletedAt: null },
            select: { id: true, userId: true, tier: true },
          })
        : params.fallbackDriver;
    if (!freshDriver) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }

    const tierChanged = freshDriver.tier !== params.newTier;
    const hasExtraUpdate =
      params.extraDriverUpdateData != null &&
      Object.keys(params.extraDriverUpdateData).length > 0;

    if (!tierChanged && !hasExtraUpdate) {
      throw new BadRequestException(DriverErrors.RANK_TIER_UNCHANGED);
    }

    await tx.driver.update({
      where: { id: params.driverId },
      data: {
        ...(params.extraDriverUpdateData ?? {}),
        ...(tierChanged ? { tier: params.newTier } : {}),
      },
    });

    const historyEntry = tierChanged
      ? await tx.driverRankHistory.create({
          data: {
            driverId: params.driverId,
            runId: null,
            evaluatedAt: new Date(),
            previousTier: freshDriver.tier,
            newTier: params.newTier,
            changeReason: DriverRankChangeReason.ADMIN_OVERRIDE,
            adminUserId: params.adminUserId,
            overrideReason: params.reason,
          },
        })
      : null;

    return {
      historyEntry,
      previousTier: freshDriver.tier,
      newTier: params.newTier,
      userId: freshDriver.userId,
      tierChanged,
    };
  }

  overrideDriverTierTransaction(params: {
    driverId: string;
    newTier: DriverTier;
    adminUserId: string;
    reason: string;
  }) {
    return this.prisma.$transaction((tx) =>
      this.applyManualTierOverrideInTx(tx, params),
    );
  }

  findAllRunEntriesSummary(runId: string) {
    return this.prisma.driverRankHistory.findMany({
      where: { runId },
      select: { previousTier: true, newTier: true, changeReason: true },
    });
  }

  listRuns(skip: number, take: number) {
    return Promise.all([
      this.prisma.driverRankingEvaluationRun.findMany({
        skip,
        take,
        orderBy: [{ periodStart: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.driverRankingEvaluationRun.count(),
    ]);
  }

  findRunEntriesWithDriver(params: {
    runId: string;
    scopedDriverIds: string[] | null;
    search?: string;
    tier?: DriverTier;
    skip: number;
    take: number;
  }) {
    if (params.scopedDriverIds && params.scopedDriverIds.length === 0) {
      return Promise.resolve([[], 0] as [
        Array<
          Prisma.DriverRankHistoryGetPayload<{
            include: { driver: { select: { name: true } } };
          }>
        >,
        number,
      ]);
    }
    const cleanSearch = params.search?.trim();
    const where: Prisma.DriverRankHistoryWhereInput = {
      runId: params.runId,
      ...(params.scopedDriverIds
        ? { driverId: { in: params.scopedDriverIds } }
        : {}),
      ...(params.tier ? { newTier: params.tier } : {}),
      ...(cleanSearch
        ? {
            driver: {
              name: { contains: cleanSearch, mode: 'insensitive' },
            },
          }
        : {}),
    };

    return Promise.all([
      this.prisma.driverRankHistory.findMany({
        where,
        skip: params.skip,
        take: params.take,
        include: {
          driver: { select: { name: true } },
        },
        orderBy: [
          { performancePercentage: { sort: 'desc', nulls: 'last' } },
          { driver: { name: 'asc' } },
          { createdAt: 'asc' },
        ],
      }),
      this.prisma.driverRankHistory.count({ where }),
    ]);
  }

  findDriverRankHistory(driverId: string, skip: number, take: number) {
    return Promise.all([
      this.prisma.driverRankHistory.findMany({
        where: { driverId },
        skip,
        take,
        orderBy: { evaluatedAt: 'desc' },
        include: {
          driver: { select: { name: true } },
          run: { select: { periodKey: true } },
        },
      }),
      this.prisma.driverRankHistory.count({ where: { driverId } }),
    ]);
  }

  findRecentDriverRankHistory(driverId: string, take: number) {
    return this.prisma.driverRankHistory.findMany({
      where: { driverId },
      orderBy: { evaluatedAt: 'desc' },
      take,
      include: { run: { select: { periodKey: true } } },
    });
  }

  findDriverBasicByUserId(userId: string) {
    return this.prisma.driver.findUnique({
      where: { userId, deletedAt: null },
      select: { id: true, name: true, tier: true },
    });
  }

  listIncidents(
    where: Prisma.DriverDeliveryIncidentWhereInput,
    skip: number,
    take: number,
  ) {
    return Promise.all([
      this.prisma.driverDeliveryIncident.findMany({
        where,
        skip,
        take,
        orderBy: { occurredAt: 'desc' },
        include: {
          driver: { select: { name: true } },
          order: { select: { orderNumber: true } },
        },
      }),
      this.prisma.driverDeliveryIncident.count({ where }),
    ]);
  }

  findIncidentById(incidentId: string) {
    return this.prisma.driverDeliveryIncident.findUnique({
      where: { id: incidentId },
    });
  }

  updateIncidentReview(
    incidentId: string,
    data: Prisma.DriverDeliveryIncidentUpdateInput,
  ) {
    return this.prisma.driverDeliveryIncident.update({
      where: { id: incidentId },
      data,
      include: {
        driver: { select: { name: true } },
        order: { select: { orderNumber: true } },
      },
    });
  }
}
