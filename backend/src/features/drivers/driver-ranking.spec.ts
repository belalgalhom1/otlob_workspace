import { BadRequestException, ConflictException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DeliveryIncidentResponsibility,
  DeliveryIncidentType,
  DispatchStatus,
  DriverRankChangeReason,
  DriverRankingRunStatus,
  DriverRankingTriggerSource,
  DriverShiftStatus,
  DriverStatus,
  DriverTier,
  OrderStatus,
  Role,
  StatisticPeriod,
} from '@prisma/client';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { DispatchLifecycleService } from '../dispatch/dispatch-lifecycle.service';
import { StatisticsAnalyticsRepository } from '../statistics/statistics-analytics.repository';
import {
  DriverRankEvaluationFailedEvent,
  DriverRankUpdatedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { DriverListener } from '../../common/listeners/driver.listener';
import { NotificationListener } from '../../common/listeners/notification.listener';
import {
  getCairoWeekBounds,
  getNextScheduledEvaluationUtc,
  getPreviousCompletedCairoWeek,
  isoWeekKeyFromMonday,
  tzParts,
} from '../../common/utils/timezone';
import { DriverShiftsService } from '../driver-shifts/driver-shifts.service';
import { OrderRejectionRecomputor } from '../orders/helpers/order-rejection-recomputor';
import { OrderCancellationService } from '../orders/transitions/order-cancellation.service';
import { DriverAssistService } from './driver-assist.service';
import { ReviewsProcessor } from '../reviews/reviews.processor';
import { REVIEW_JOBS } from '../../infrastructure/queue/queues.constants';
import { DriverAdminService } from './driver-admin.service';
import { OrdersStateService } from '../orders/orders-state.service';
import {
  DriverDeliveryIncidentsService,
} from './ranking/driver-delivery-incidents.service';
import {
  DriverRankingOutcome,
  DriverWeeklyMetricInput,
  evaluateDriverWeeklyMetrics,
  resolveTierForPercentage,
} from './ranking/driver-ranking.calculator';
import {
  DriverRankingRepository,
  EVALUATION_COMMIT_BATCH_SIZE,
  STALE_RUNNING_RUN_MS,
} from './ranking/driver-ranking.repository';
import { DriverRankingService } from './ranking/driver-ranking.service';

function makeInput(
  overrides: Partial<DriverWeeklyMetricInput> = {},
): DriverWeeklyMetricInput {
  return {
    driverId: 'drv-1',
    driverName: 'Driver 1',
    currentTier: DriverTier.SILVER,
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
    ...overrides,
  };
}

describe('Weekly Driver Ranking System', () => {
  describe('Pure calculator & simulation scenarios', () => {
    it('reproduces all 5 simulation drivers accurately (A: GOLD 98.33%, B: SILVER 90%, C: SILVER 85%, D: SILVER 85%, E: inactive SILVER)', () => {
      const driverA = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'A',
          driverName: 'Driver A',
          currentTier: DriverTier.SILVER,
          acceptedDispatches: 98,
          rejectedDispatches: 2,
          completedOrders: 97,
          driverFaultFailures: 3,
          onTimeShifts: 10,
        }),
      );
      expect(driverA.performancePercentage).toBeCloseTo(98.333333, 5);
      expect(driverA.newTier).toBe(DriverTier.GOLD);
      expect(driverA.outcome).toBe(DriverRankingOutcome.PROMOTED);

      const driverB = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'B',
          driverName: 'Driver B',
          acceptedDispatches: 90,
          rejectedDispatches: 10,
          completedOrders: 90,
          driverFaultFailures: 10,
          onTimeShifts: 9,
          lateShifts: 1,
        }),
      );
      expect(driverB.performancePercentage).toBe(90);
      expect(driverB.newTier).toBe(DriverTier.SILVER);
      expect(driverB.outcome).toBe(DriverRankingOutcome.UNCHANGED);

      const driverC = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'C',
          driverName: 'Driver C',
          acceptedDispatches: 85,
          rejectedDispatches: 15,
          completedOrders: 80,
          driverFaultFailures: 20,
          onTimeShifts: 9,
          missedShifts: 1,
        }),
      );
      expect(driverC.performancePercentage).toBe(85);
      expect(driverC.newTier).toBe(DriverTier.SILVER);

      const driverD = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'D',
          driverName: 'Driver D',
          acceptedDispatches: 95,
          rejectedDispatches: 5,
          completedOrders: 70,
          driverFaultFailures: 30,
          onTimeShifts: 9,
          lateShifts: 1,
        }),
      );
      expect(driverD.performancePercentage).toBe(85);
      expect(driverD.newTier).toBe(DriverTier.SILVER);

      const driverE = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'E',
          driverName: 'Driver E',
          currentTier: DriverTier.GOLD,
        }),
      );
      expect(driverE.performancePercentage).toBeNull();
      expect(driverE.newTier).toBe(DriverTier.SILVER);
      expect(driverE.changeReason).toBe(DriverRankChangeReason.INACTIVE_DRIVER);
      expect(driverE.outcome).toBe(DriverRankingOutcome.INACTIVE_SILVER);
    });

    it('enforces anti-manipulation rule: 20/20 accepted, 14 completed + 6 driver-fault cancellations = 90% SILVER', () => {
      const res = evaluateDriverWeeklyMetrics(
        makeInput({
          currentTier: DriverTier.GOLD,
          acceptedDispatches: 20,
          completedOrders: 14,
          driverFaultFailures: 6,
          onTimeShifts: 6,
        }),
      );
      expect(res.acceptanceRate).toBe(100);
      expect(res.completionRate).toBe(70);
      expect(res.shiftPunctualityRate).toBe(100);
      expect(res.performancePercentage).toBe(90);
      expect(res.newTier).toBe(DriverTier.SILVER);
      expect(res.outcome).toBe(DriverRankingOutcome.DEMOTED);
    });

    it('does NOT round scores before comparing against exact 95% GOLD and 85% SILVER cutoffs', () => {
      // 94.996% must NOT round up to 95.0% GOLD
      expect(resolveTierForPercentage(94.996)).toBe(DriverTier.SILVER);
      expect(resolveTierForPercentage(95)).toBe(DriverTier.GOLD);
      // 84.999% must NOT round up to 85.0% SILVER
      expect(resolveTierForPercentage(84.999)).toBe(DriverTier.BRONZE);
      expect(resolveTierForPercentage(85)).toBe(DriverTier.SILVER);
    });

    it('excludes CANCELLED dispatches, external/under-review incidents, and excused/cancelled shifts while applying partial-metric & anti-gaming rules', () => {
      // Shifts disabled or 0 scheduled shifts -> average Acceptance + Completion only
      const shiftsOff = evaluateDriverWeeklyMetrics(
        makeInput({
          acceptedDispatches: 19,
          rejectedDispatches: 1,
          cancelledDispatches: 5, // excluded
          completedOrders: 19,
          excludedIncidents: {
            customer: 2,
            vendor: 1,
            externalOrSystem: 1,
            underReview: 1,
          },
          cancelledShifts: 2,
          excusedShifts: 1,
        }),
      );
      expect(shiftsOff.acceptanceRate).toBe(95);
      expect(shiftsOff.completionRate).toBe(100);
      expect(shiftsOff.shiftPunctualityRate).toBeNull();
      expect(shiftsOff.performancePercentage).toBe(97.5);
      expect(shiftsOff.newTier).toBe(DriverTier.GOLD);
      expect(shiftsOff.explanations.length).toBeGreaterThanOrEqual(5);

      // Shift-only 100% with 0 dispatches & 0 orders -> capped at SILVER
      const shiftOnly = evaluateDriverWeeklyMetrics(
        makeInput({
          currentTier: DriverTier.BRONZE,
          onTimeShifts: 5,
        }),
      );
      expect(shiftOnly.performancePercentage).toBe(100);
      expect(shiftOnly.newTier).toBe(DriverTier.SILVER);
      expect(shiftOnly.outcome).toBe(DriverRankingOutcome.CAPPED_SILVER);
      expect(shiftOnly.metricsSnapshot.cappedDueToNoOrders).toBe(true);

      // Missed shift with 0 dispatches/orders -> active poor performance -> 0% BRONZE (NOT inactive SILVER)
      const missedShiftOnly = evaluateDriverWeeklyMetrics(
        makeInput({
          currentTier: DriverTier.GOLD,
          missedShifts: 1,
        }),
      );
      expect(missedShiftOnly.performancePercentage).toBe(0);
      expect(missedShiftOnly.newTier).toBe(DriverTier.BRONZE);
      expect(missedShiftOnly.changeReason).toBe(
        DriverRankChangeReason.WEEKLY_EVALUATION,
      );
    });
  });

  describe('Cairo Monday-start week boundaries & DST handling', () => {
    it('computes previous completed Monday-Sunday ISO week strictly in Africa/Cairo', () => {
      // Monday Nov 9, 2026 00:05 Cairo (UTC+2) => Sunday Nov 8 22:05 UTC
      const mondayCairo = new Date('2026-11-08T22:05:00.000Z');
      const prev = getPreviousCompletedCairoWeek(mondayCairo, 'Africa/Cairo');
      expect(prev.monday.year).toBe(2026);
      expect(prev.monday.month).toBe(11);
      expect(prev.monday.day).toBe(2);
      expect(prev.sunday.year).toBe(2026);
      expect(prev.sunday.month).toBe(11);
      expect(prev.sunday.day).toBe(8);
      expect(prev.periodKey).toBe('2026-W45');
      expect(prev.periodStart.toISOString()).toBe('2026-11-01T22:00:00.000Z');
      expect(prev.periodEnd.toISOString()).toBe('2026-11-08T21:59:59.999Z');
    });

    it('handles year-boundary ISO weeks (Dec 29 -> Jan 4) and Egypt DST transitions cleanly', () => {
      expect(
        isoWeekKeyFromMonday({ year: 2025, month: 12, day: 29 }),
      ).toBe('2026-W01');

      // Egypt spring-forward DST happens last Friday of April (April 24, 2026: UTC+2 -> UTC+3)
      // Week Mon Apr 20 -> Sun Apr 26 spans DST jump; week length is 167 hours cleanly.
      const insideDstWeek = new Date('2026-04-22T12:00:00.000Z');
      const bounds = getCairoWeekBounds(insideDstWeek, 'Africa/Cairo');
      expect(bounds.periodKey).toBe('2026-W17');
      expect(bounds.periodStart.toISOString()).toBe('2026-04-19T22:00:00.000Z');
      expect(bounds.periodEnd.toISOString()).toBe('2026-04-26T20:59:59.999Z');

      // Once W45 is completed, next scheduled evaluation jumps to Monday Nov 16 00:05 Cairo
      const next = getNextScheduledEvaluationUtc(
        new Date('2026-11-09T10:00:00.000Z'),
        '00:05',
        true,
        'Africa/Cairo',
      );
      const nextParts = tzParts(next, 'Africa/Cairo');
      expect(nextParts).toMatchObject({
        year: 2026,
        month: 11,
        day: 16,
        weekday: 1,
      });
    });

    it('never returns a past timestamp on Tue-Sun and honors Monday timing + autoEvalEnabled', () => {
      // Friday Nov 13, 2026 12:00 Cairo, even when previous week run doesn't exist -> next Monday Nov 16 00:05
      const fridayNow = new Date('2026-11-13T10:00:00.000Z');
      const fromFriday = getNextScheduledEvaluationUtc(
        fridayNow,
        '00:05',
        false,
        'Africa/Cairo',
        true,
      );
      expect(fromFriday.getTime()).toBeGreaterThan(fridayNow.getTime());
      expect(tzParts(fromFriday, 'Africa/Cairo')).toMatchObject({
        year: 2026,
        month: 11,
        day: 16,
        weekday: 1,
      });

      // Monday Nov 9, 2026 00:02 Cairo (before 00:05) -> today Nov 9 00:05
      const mondayBefore = new Date('2026-11-08T22:02:00.000Z');
      const fromMondayBefore = getNextScheduledEvaluationUtc(
        mondayBefore,
        '00:05',
        false,
        'Africa/Cairo',
        false,
      );
      expect(tzParts(fromMondayBefore, 'Africa/Cairo')).toMatchObject({
        year: 2026,
        month: 11,
        day: 9,
        weekday: 1,
      });

      // Monday Nov 9, 2026 10:00 Cairo (after 00:05) with autoEvalEnabled=false -> next Monday Nov 16
      const mondayAfterDisabled = new Date('2026-11-09T08:00:00.000Z');
      const fromMondayDisabled = getNextScheduledEvaluationUtc(
        mondayAfterDisabled,
        '00:05',
        false,
        'Africa/Cairo',
        false,
      );
      expect(tzParts(fromMondayDisabled, 'Africa/Cairo')).toMatchObject({
        year: 2026,
        month: 11,
        day: 16,
        weekday: 1,
      });
    });
  });

  describe('DriverRankingService integration, idempotency, retries & dry run', () => {
    function makeRankingServiceHarness() {
      const drivers = [
        {
          id: 'drv-1',
          userId: 'u-1',
          name: 'Driver One',
          tier: DriverTier.SILVER,
          isApproved: true,
          deletedAt: null,
        },
        {
          id: 'drv-2',
          userId: 'u-2',
          name: 'Driver Two',
          tier: DriverTier.GOLD,
          isApproved: true,
          deletedAt: null,
        },
      ];
      const runs: any[] = [];
      const historyRows: any[] = [];
      const incidents: any[] = [
        {
          id: 'inc-1',
          orderId: 'ord-1',
          deliveryGroupId: 'grp-cust',
          driverId: 'drv-1',
          incidentType: DeliveryIncidentType.ORDER_CANCELLED,
          responsibility: DeliveryIncidentResponsibility.CUSTOMER,
          reason: 'Customer cancelled',
          reportedByUserId: 'u-c1',
          reviewedByUserId: null,
          reviewedAt: null,
          reviewNote: null,
          occurredAt: new Date('2026-11-10T10:00:00.000Z'),
          createdAt: new Date('2026-11-10T10:00:00.000Z'),
          driver: { name: 'Driver One' },
          order: { orderNumber: 'OTL-1' },
        },
        {
          id: 'inc-2',
          orderId: 'ord-2',
          deliveryGroupId: 'grp-rev',
          driverId: 'drv-1',
          incidentType: DeliveryIncidentType.DRIVER_REASSIGNED,
          responsibility: DeliveryIncidentResponsibility.UNDER_REVIEW,
          reason: 'Pending dispute',
          reportedByUserId: 'admin-1',
          reviewedByUserId: null,
          reviewedAt: null,
          reviewNote: null,
          occurredAt: new Date('2026-11-10T11:00:00.000Z'),
          createdAt: new Date('2026-11-10T11:00:00.000Z'),
          driver: { name: 'Driver One' },
          order: { orderNumber: 'OTL-2' },
        },
      ];
      const walletTxs: any[] = [
        { id: 'wt-1', amount: 40, type: 'DELIVERY_FEE' },
      ];
      const emit = jest.fn();

      const matchesRunUpdateWhere = (r: any, where: any): boolean => {
        if (where.id && r.id !== where.id) return false;
        if (where.status && r.status !== where.status) return false;
        if (where.updatedAt?.lt && !(r.updatedAt < where.updatedAt.lt)) {
          return false;
        }
        if (Array.isArray(where.OR)) {
          return where.OR.some((branch: any) =>
            matchesRunUpdateWhere(r, branch),
          );
        }
        return true;
      };

      const filterHistoryRows = (where: any = {}) => {
        const driverIn = where?.driverId?.in as string[] | undefined;
        const driverEq =
          typeof where?.driverId === 'string' ? where.driverId : undefined;
        const nameSearch = where?.driver?.name?.contains as string | undefined;

        return historyRows.filter((h) => {
          if (where.runId && h.runId !== where.runId) return false;
          if (driverEq && h.driverId !== driverEq) return false;
          if (driverIn && !driverIn.includes(h.driverId)) return false;
          if (where.newTier && h.newTier !== where.newTier) return false;
          if (nameSearch) {
            const dName =
              drivers.find((d) => d.id === h.driverId)?.name ?? '';
            if (!dName.toLowerCase().includes(nameSearch.toLowerCase())) {
              return false;
            }
          }
          return true;
        });
      };

      const prisma: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        driver: {
          findMany: jest.fn(({ where }) => {
            const ids = where?.id?.in as string[] | undefined;
            const list = ids
              ? drivers.filter((d) => ids.includes(d.id))
              : drivers;
            return Promise.resolve(list.map((d) => ({ ...d })));
          }),
          findUnique: jest.fn(({ where }) => {
            const found = drivers.find((d) => d.id === where.id);
            return Promise.resolve(found ? { ...found } : null);
          }),
          update: jest.fn(({ where, data }) => {
            const found = drivers.find((d) => d.id === where.id);
            if (found && data.tier) found.tier = data.tier;
            return Promise.resolve(found);
          }),
          updateMany: jest.fn(({ where, data }) => {
            const ids = (where?.id?.in as string[]) ?? [];
            const matching = drivers.filter((d) => ids.includes(d.id));
            for (const m of matching) {
              if (data.tier) m.tier = data.tier;
            }
            return Promise.resolve({ count: matching.length });
          }),
        },
        orderDispatch: {
          groupBy: jest.fn().mockResolvedValue([
            {
              driverId: 'drv-1',
              status: DispatchStatus.ACCEPTED,
              _count: { _all: 10 },
            },
            {
              driverId: 'drv-1',
              status: DispatchStatus.CANCELLED,
              _count: { _all: 3 },
            },
          ]),
        },
        orderDeliveryGroup: {
          groupBy: jest.fn().mockResolvedValue([
            { primaryDriverId: 'drv-1', _count: { _all: 10 } },
          ]),
        },
        driverDeliveryIncident: {
          findMany: jest.fn(() => Promise.resolve(incidents.map((i) => ({ ...i })))),
          count: jest.fn(() => Promise.resolve(incidents.length)),
          findUnique: jest.fn(({ where }) => {
            const found = incidents.find((i) => i.id === where.id);
            return Promise.resolve(found ? { ...found } : null);
          }),
          update: jest.fn(({ where, data }) => {
            const found = incidents.find((i) => i.id === where.id);
            if (found) Object.assign(found, data);
            return Promise.resolve(found ? { ...found } : null);
          }),
        },
        driverShift: {
          findMany: jest.fn().mockResolvedValue([
            // drv-1: 1 on-time COMPLETED shift (within 5m grace) + 1 excused MISSED shift
            {
              driverId: 'drv-1',
              status: DriverShiftStatus.COMPLETED,
              startTime: new Date('2026-11-10T08:00:00.000Z'),
              actualStart: new Date('2026-11-10T08:05:00.000Z'),
              isExcused: false,
            },
            {
              driverId: 'drv-1',
              status: DriverShiftStatus.MISSED,
              startTime: new Date('2026-11-11T08:00:00.000Z'),
              actualStart: null,
              isExcused: true,
            },
            // drv-2 has zero activity -> inactive SILVER
          ]),
        },
        driverRankingEvaluationRun: {
          findFirst: jest.fn(() =>
            Promise.resolve(runs[runs.length - 1] ?? null),
          ),
          findUnique: jest.fn(({ where }) => {
            const found = runs.find((r) =>
              where.periodKey
                ? r.periodKey === where.periodKey
                : r.id === where.id,
            );
            return Promise.resolve(found ? { ...found } : null);
          }),
          findUniqueOrThrow: jest.fn(({ where }) => {
            const found = runs.find((r) => r.id === where.id);
            if (!found) throw new Error('Not found');
            return Promise.resolve({ ...found });
          }),
          create: jest.fn(({ data }) => {
            if (runs.some((r) => r.periodKey === data.periodKey)) {
              return Promise.reject({ code: 'P2002' });
            }
            const created = {
              id: `run-${runs.length + 1}`,
              ...data,
              totalDrivers: 0,
              promotedCount: 0,
              demotedCount: 0,
              unchangedCount: 0,
              inactiveCount: 0,
              errorMessage: null,
              createdAt: new Date(),
              updatedAt: new Date(),
            };
            runs.push(created);
            return Promise.resolve({ ...created });
          }),
          update: jest.fn(({ where, data }) => {
            const r = runs.find((x) => x.id === where.id);
            if (r) Object.assign(r, data, { updatedAt: new Date() });
            return Promise.resolve(r ? { ...r } : null);
          }),
          updateMany: jest.fn(({ where, data }) => {
            const matching = runs.filter((r) => matchesRunUpdateWhere(r, where));
            for (const m of matching) {
              Object.assign(m, data, {
                updatedAt: data.updatedAt ?? new Date(),
              });
            }
            return Promise.resolve({ count: matching.length });
          }),
        },
        driverRankHistory: {
          findMany: jest.fn(({ where, skip, take } = {}) => {
            const enriched = filterHistoryRows(where).map((h) => ({
              ...h,
              driver: {
                name: drivers.find((d) => d.id === h.driverId)?.name ?? '',
              },
            }));
            enriched.sort((a, b) => {
              if (
                a.performancePercentage === null &&
                b.performancePercentage !== null
              ) {
                return 1;
              }
              if (
                a.performancePercentage !== null &&
                b.performancePercentage === null
              ) {
                return -1;
              }
              if (
                a.performancePercentage !== null &&
                b.performancePercentage !== null &&
                b.performancePercentage !== a.performancePercentage
              ) {
                return b.performancePercentage - a.performancePercentage;
              }
              return a.driver.name.localeCompare(b.driver.name);
            });
            const start = skip ?? 0;
            const sliced =
              typeof take === 'number'
                ? enriched.slice(start, start + take)
                : enriched.slice(start);
            return Promise.resolve(sliced);
          }),
          count: jest.fn(({ where } = {}) =>
            Promise.resolve(filterHistoryRows(where).length),
          ),
          findUnique: jest.fn(({ where }) => {
            const key = where?.runId_driverId;
            const found = key
              ? historyRows.find(
                  (h) => h.runId === key.runId && h.driverId === key.driverId,
                )
              : null;
            return Promise.resolve(found ? { ...found } : null);
          }),
          create: jest.fn(({ data }) => {
            if (
              data.runId &&
              historyRows.some(
                (h) => h.runId === data.runId && h.driverId === data.driverId,
              )
            ) {
              return Promise.reject({ code: 'P2002' });
            }
            const row = {
              id: `hist-${historyRows.length + 1}`,
              ...data,
              createdAt: new Date(),
            };
            historyRows.push(row);
            return Promise.resolve({ ...row });
          }),
          createMany: jest.fn(({ data, skipDuplicates }) => {
            let count = 0;
            for (const entry of data) {
              if (
                entry.runId &&
                historyRows.some(
                  (h) => h.runId === entry.runId && h.driverId === entry.driverId,
                )
              ) {
                if (skipDuplicates) continue;
                return Promise.reject({ code: 'P2002' });
              }
              historyRows.push({
                id: `hist-${historyRows.length + 1}`,
                ...entry,
                createdAt: new Date(),
              });
              count++;
            }
            return Promise.resolve({ count });
          }),
        },
        $transaction: jest.fn(async (fn) => {
          const histSnapshotLen = historyRows.length;
          const tierSnapshots = drivers.map((d) => d.tier);
          try {
            return await fn(prisma);
          } catch (err) {
            historyRows.length = histSnapshotLen;
            drivers.forEach((d, idx) => {
              d.tier = tierSnapshots[idx];
            });
            throw err;
          }
        }),
      };

      const platformSettings: any = {
        getSettings: jest.fn().mockResolvedValue({
          driverRankingAutoEvalEnabled: true,
          driverRankingEvalTime: '00:05',
        }),
      };

      const driverManagersService: any = {
        getManagedDriverIds: jest.fn().mockResolvedValue(['drv-1']),
        assertManagesDriver: jest.fn().mockResolvedValue(undefined),
      };

      const rankingRepository = new DriverRankingRepository(prisma);
      const service = new DriverRankingService(
        rankingRepository,
        platformSettings,
        driverManagersService,
        { emit } as any,
      );
      const incidentsService = new DriverDeliveryIncidentsService(
        rankingRepository,
        driverManagersService,
        { emit } as any,
      );

      return {
        service,
        rankingRepository,
        incidentsService,
        prisma,
        drivers,
        runs,
        historyRows,
        incidents,
        walletTxs,
        emit,
      };
    }

    it('Dry Run calculates exact results without mutating driver.tier or creating history records', async () => {
      const h = makeRankingServiceHarness();

      const preview = await h.service.previewEvaluation();

      expect(preview.totalDrivers).toBe(2);
      expect(preview.promotedCount).toBe(1); // drv-1 -> GOLD
      expect(preview.demotedCount).toBe(1); // drv-2 inactive -> GOLD -> SILVER
      expect(preview.inactiveCount).toBe(1);
      expect(h.drivers[0].tier).toBe(DriverTier.SILVER);
      expect(h.drivers[1].tier).toBe(DriverTier.GOLD);
      expect(h.historyRows).toHaveLength(0);
      expect(h.runs).toHaveLength(0);
    });

    it('executes evaluation, prevents duplicate periodKey runs, notifies only on badge change, and keeps settlements untouched', async () => {
      const h = makeRankingServiceHarness();

      const run = await h.service.runEvaluation({
        triggerSource: DriverRankingTriggerSource.SCHEDULED,
      });

      expect(run.status).toBe(DriverRankingRunStatus.COMPLETED);
      expect(run.totalDrivers).toBe(2);
      expect(run.promotedCount).toBe(1);
      expect(run.demotedCount).toBe(1);
      expect(run.inactiveCount).toBe(1);
      expect(h.drivers[0].tier).toBe(DriverTier.GOLD);
      expect(h.drivers[1].tier).toBe(DriverTier.SILVER);
      expect(h.historyRows).toHaveLength(2);
      expect(h.walletTxs).toEqual([
        { id: 'wt-1', amount: 40, type: 'DELIVERY_FEE' },
      ]);
      expect(h.emit).toHaveBeenCalledTimes(2);
      expect(h.emit).toHaveBeenCalledWith(
        EVENTS.DRIVER_RANK_UPDATED,
        expect.objectContaining({
          driverId: 'drv-1',
          previousTier: DriverTier.SILVER,
          newTier: DriverTier.GOLD,
        }),
      );

      // Second execution for the same periodKey must be blocked cleanly
      await expect(
        h.service.runEvaluation({
          triggerSource: DriverRankingTriggerSource.MANUAL,
          triggeredByUserId: 'admin-1',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('marks failed runs cleanly across chunk boundaries, alerts admins, and retryFailedRun resumes without duplicating committed chunks', async () => {
      const h = makeRankingServiceHarness();

      // Expand to 51 drivers (EVALUATION_COMMIT_BATCH_SIZE = 50 -> Chunk 1 = 50, Chunk 2 = 1):
      // Replace default drivers with drv-001 (active SILVER->GOLD), drv-002..050 (inactive SILVER->SILVER),
      // and drv-051 (inactive GOLD->SILVER in Chunk 2).
      h.drivers.splice(
        0,
        h.drivers.length,
        {
          id: 'drv-1',
          userId: 'u-1',
          name: 'Driver 001',
          tier: DriverTier.SILVER,
          isApproved: true,
          deletedAt: null,
        },
        ...Array.from(
          { length: EVALUATION_COMMIT_BATCH_SIZE - 1 },
          (_, idx) => {
            const num = String(idx + 2).padStart(3, '0');
            return {
              id: `drv-${num}`,
              userId: `u-${num}`,
              name: `Driver ${num}`,
              tier: DriverTier.SILVER,
              isApproved: true,
              deletedAt: null,
            };
          },
        ),
        {
          id: 'drv-051',
          userId: 'u-051',
          name: 'Driver 051',
          tier: DriverTier.GOLD,
          isApproved: true,
          deletedAt: null,
        },
      );

      let chunk2Attempts = 0;
      const origUpdateMany = h.prisma.driver.updateMany;
      h.prisma.driver.updateMany = jest.fn((args: any) => {
        const ids = (args?.where?.id?.in as string[]) ?? [];
        if (ids.includes('drv-051') && chunk2Attempts === 0) {
          chunk2Attempts++;
          return Promise.reject(new Error('Simulated DB transient error'));
        }
        return origUpdateMany(args);
      });

      await expect(
        h.service.runEvaluation({
          triggerSource: DriverRankingTriggerSource.SCHEDULED,
        }),
      ).rejects.toThrow('Simulated DB transient error');

      // Chunk 1 (50 drivers) succeeded, notified, & heartbeat updated; Chunk 2 rolled back; run FAILED
      expect(h.runs[0].status).toBe(DriverRankingRunStatus.FAILED);
      expect(h.historyRows).toHaveLength(EVALUATION_COMMIT_BATCH_SIZE);
      expect(
        h.historyRows.some((row) => row.driverId === 'drv-051'),
      ).toBe(false);
      expect(h.drivers[h.drivers.length - 1].tier).toBe(DriverTier.GOLD);
      expect(
        h.prisma.driverRankingEvaluationRun.updateMany,
      ).toHaveBeenCalledWith({
        where: {
          id: h.runs[0].id,
          status: DriverRankingRunStatus.RUNNING,
        },
        data: { updatedAt: expect.any(Date) },
      });
      expect(h.emit).toHaveBeenCalledWith(
        EVENTS.DRIVER_RANK_UPDATED,
        expect.objectContaining({
          driverId: 'drv-1',
          newTier: DriverTier.GOLD,
        }),
      );
      expect(h.emit).toHaveBeenCalledWith(
        EVENTS.DRIVER_RANK_EVALUATION_FAILED,
        expect.objectContaining({
          runId: h.runs[0].id,
          periodKey: h.runs[0].periodKey,
        }),
      );

      // Cron ticker must NOT auto-duplicate or crash over a FAILED run
      await h.service.checkAndRunScheduledEvaluation();
      expect(h.runs).toHaveLength(1);

      // Retry resumes from Chunk 2 (drv-051) without duplicating Chunk 1 history rows or notifications
      h.emit.mockClear();
      const retried = await h.service.retryFailedRun(h.runs[0].id, {
        sub: 'admin-1',
        role: Role.SUPER_ADMIN,
      } as any);
      expect(retried.status).toBe(DriverRankingRunStatus.COMPLETED);
      expect(retried.totalDrivers).toBe(EVALUATION_COMMIT_BATCH_SIZE + 1);
      expect(h.historyRows).toHaveLength(EVALUATION_COMMIT_BATCH_SIZE + 1);
      expect(h.drivers[h.drivers.length - 1].tier).toBe(DriverTier.SILVER);
      expect(h.emit).toHaveBeenCalledTimes(1);
      expect(h.emit).toHaveBeenCalledWith(
        EVENTS.DRIVER_RANK_UPDATED,
        expect.objectContaining({
          driverId: 'drv-051',
          newTier: DriverTier.SILVER,
        }),
      );
    });

    it('getMyRankSummary does not penalize future SCHEDULED shifts later in an in-progress week', async () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-11-10T10:00:00.000Z')); // Tuesday 12:00 Cairo
      try {
        const h = makeRankingServiceHarness();
        h.prisma.driver.findUnique = jest
          .fn()
          .mockResolvedValue({ ...h.drivers[0] });
        h.prisma.driverRankHistory.findMany = jest.fn().mockResolvedValue([]);
        h.prisma.driverShift.findMany = jest.fn().mockResolvedValue([
          // Earlier Tuesday shift missed (>5m past 08:00 UTC / 10:00 Cairo)
          {
            driverId: 'drv-1',
            status: DriverShiftStatus.SCHEDULED,
            startTime: new Date('2026-11-10T08:00:00.000Z'),
            actualStart: null,
            isExcused: false,
          },
          // Future Wednesday & Thursday scheduled shifts must NOT count as missed
          {
            driverId: 'drv-1',
            status: DriverShiftStatus.SCHEDULED,
            startTime: new Date('2026-11-11T08:00:00.000Z'),
            actualStart: null,
            isExcused: false,
          },
          {
            driverId: 'drv-1',
            status: DriverShiftStatus.SCHEDULED,
            startTime: new Date('2026-11-12T08:00:00.000Z'),
            actualStart: null,
            isExcused: false,
          },
        ]);

        const summary = await h.service.getMyRankSummary('u-1');
        expect(summary.currentWeekProgress?.metricsSnapshot.missedShifts).toBe(1);
        expect(summary.currentWeekProgress?.metricsSnapshot.eligibleShifts).toBe(1);
      } finally {
        jest.useRealTimers();
      }
    });

    it('checkAndRunScheduledEvaluation triggers only on Monday after evalTime and recovers stale RUNNING runs', async () => {
      jest.useFakeTimers();
      try {
        const h = makeRankingServiceHarness();

        // Wednesday -> never auto-runs previous week mid-week
        jest.setSystemTime(new Date('2026-11-11T10:00:00.000Z'));
        await h.service.checkAndRunScheduledEvaluation();
        expect(h.runs).toHaveLength(0);

        // Monday before evalTime (00:05 Cairo = Sun 22:05 UTC; at 22:02 UTC it's 00:02 Cairo) -> skipped
        jest.setSystemTime(new Date('2026-11-15T22:02:00.000Z'));
        await h.service.checkAndRunScheduledEvaluation();
        expect(h.runs).toHaveLength(0);

        // Monday at/after evalTime (22:06 UTC = Mon 00:06 Cairo) -> executes previous completed week
        jest.setSystemTime(new Date('2026-11-15T22:06:00.000Z'));
        await h.service.checkAndRunScheduledEvaluation();
        expect(h.runs).toHaveLength(1);
        expect(h.runs[0].status).toBe(DriverRankingRunStatus.COMPLETED);

        // Stale RUNNING run recovery on a fresh harness
        const h2 = makeRankingServiceHarness();
        const staleAt = new Date(Date.now() - STALE_RUNNING_RUN_MS - 60_000);
        const prevWeek = getPreviousCompletedCairoWeek(new Date(), 'Africa/Cairo');
        h2.runs.push({
          id: 'run-stale',
          periodKey: prevWeek.periodKey,
          status: DriverRankingRunStatus.RUNNING,
          triggerSource: DriverRankingTriggerSource.SCHEDULED,
          triggeredByUserId: null,
          scheduledFor: staleAt,
          executedAt: null,
          periodStart: prevWeek.periodStart,
          periodEnd: prevWeek.periodEnd,
          totalDrivers: 0,
          promotedCount: 0,
          demotedCount: 0,
          unchangedCount: 0,
          inactiveCount: 0,
          errorMessage: null,
          createdAt: staleAt,
          updatedAt: staleAt,
        });

        await h2.service.checkAndRunScheduledEvaluation();
        expect(h2.runs[0].status).toBe(DriverRankingRunStatus.FAILED);
        expect(h2.emit).toHaveBeenCalledWith(
          EVENTS.DRIVER_RANK_EVALUATION_FAILED,
          expect.objectContaining({ runId: 'run-stale' }),
        );

        const retried = await h2.service.retryFailedRun('run-stale', {
          sub: 'admin-1',
          role: Role.SUPER_ADMIN,
        } as any);
        expect(retried.status).toBe(DriverRankingRunStatus.COMPLETED);
      } finally {
        jest.useRealTimers();
      }
    });

    it('supports manual ADMIN_OVERRIDE with mandatory reason, rejects no-op override, and creates immutable audit record', async () => {
      const h = makeRankingServiceHarness();

      await expect(
        h.service.overrideDriverTier(
          'drv-1',
          { newTier: DriverTier.GOLD, reason: '   ' },
          { sub: 'admin-1', role: Role.ADMIN } as any,
        ),
      ).rejects.toThrow(BadRequestException);

      // Same tier (SILVER -> SILVER) must be rejected cleanly
      await expect(
        h.service.overrideDriverTier(
          'drv-1',
          { newTier: DriverTier.SILVER, reason: 'No actual change' },
          { sub: 'admin-1', role: Role.ADMIN } as any,
        ),
      ).rejects.toThrow(BadRequestException);

      const entry = await h.service.overrideDriverTier(
        'drv-1',
        { newTier: DriverTier.GOLD, reason: 'Exceptional emergency assist' },
        { sub: 'admin-1', role: Role.ADMIN } as any,
      );

      expect(entry!.changeReason).toBe(DriverRankChangeReason.ADMIN_OVERRIDE);
      expect(entry!.overrideReason).toBe('Exceptional emergency assist');
      expect(entry!.adminUserId).toBe('admin-1');
      expect(entry!.runId).toBeNull();
      expect(h.drivers[0].tier).toBe(DriverTier.GOLD);
    });

    it('collectWeeklyMetricInputs omits driverId IN filter for unscoped full-fleet runs and includes it when scoped', async () => {
      const h = makeRankingServiceHarness();
      const start = new Date('2026-11-02T00:00:00.000Z');
      const end = new Date('2026-11-08T23:59:59.999Z');
      const asOf = new Date('2026-11-09T00:05:00.000Z');

      await h.rankingRepository.collectWeeklyMetricInputs(
        start,
        end,
        asOf,
        null,
      );

      expect(
        h.prisma.orderDispatch.groupBy.mock.calls[0][0].where.driverId,
      ).toBeUndefined();
      expect(
        h.prisma.orderDeliveryGroup.groupBy.mock.calls[0][0].where
          .primaryDriverId,
      ).toEqual({ not: null });
      expect(
        h.prisma.driverDeliveryIncident.findMany.mock.calls[0][0].where
          .driverId,
      ).toBeUndefined();
      expect(
        h.prisma.driverShift.findMany.mock.calls[0][0].where.driverId,
      ).toBeUndefined();

      jest.clearAllMocks();
      await h.rankingRepository.collectWeeklyMetricInputs(start, end, asOf, [
        'drv-1',
      ]);

      expect(
        h.prisma.orderDispatch.groupBy.mock.calls[0][0].where.driverId,
      ).toEqual({ in: ['drv-1'] });
      expect(
        h.prisma.orderDeliveryGroup.groupBy.mock.calls[0][0].where
          .primaryDriverId,
      ).toEqual({ in: ['drv-1'] });
      expect(
        h.prisma.driverDeliveryIncident.findMany.mock.calls[0][0].where
          .driverId,
      ).toEqual({ in: ['drv-1'] });
      expect(
        h.prisma.driverShift.findMany.mock.calls[0][0].where.driverId,
      ).toEqual({ in: ['drv-1'] });
    });

    it('previewEvaluation and getRunDetails paginate and filter entries while preserving full-fleet summary totals', async () => {
      const h = makeRankingServiceHarness();
      h.drivers.push({
        id: 'drv-3',
        userId: 'u-3',
        name: 'Zed Beta',
        tier: DriverTier.GOLD,
        isApproved: true,
        deletedAt: null,
      });

      const admin = { sub: 'admin-1', role: Role.ADMIN } as any;

      const filteredPreview = await h.service.previewEvaluation(admin, {
        page: 2,
        limit: 1,
        tier: DriverTier.SILVER,
      });
      expect(filteredPreview.totalDrivers).toBe(3);
      expect(filteredPreview.promotedCount).toBe(1);
      expect(filteredPreview.demotedCount).toBe(2);
      expect(filteredPreview.inactiveCount).toBe(2);
      expect(filteredPreview.drivers).toHaveLength(1);
      expect(filteredPreview.drivers[0].driverId).toBe('drv-3');
      expect(filteredPreview.meta).toEqual({
        total: 2,
        page: 2,
        limit: 1,
        totalPages: 2,
      });

      const searchPreview = await h.service.previewEvaluation(admin, {
        search: 'zed',
      });
      expect(searchPreview.totalDrivers).toBe(3);
      expect(searchPreview.drivers.map((d) => d.driverId)).toEqual(['drv-3']);
      expect(searchPreview.meta).toEqual({
        total: 1,
        page: 1,
        limit: 50,
        totalPages: 1,
      });

      const run = await h.service.runEvaluation({
        triggerSource: DriverRankingTriggerSource.MANUAL,
        triggeredByUserId: 'admin-1',
      });

      const pagedDetails = await h.service.getRunDetails(run.id, admin, {
        page: 2,
        limit: 1,
        tier: DriverTier.SILVER,
      });
      expect(pagedDetails.entries).toHaveLength(1);
      expect(pagedDetails.entries[0].driverId).toBe('drv-3');
      expect(pagedDetails.meta).toEqual({
        total: 2,
        page: 2,
        limit: 1,
        totalPages: 2,
      });

      const searchDetails = await h.service.getRunDetails(run.id, admin, {
        search: 'one',
      });
      expect(searchDetails.entries.map((e) => e.driverId)).toEqual(['drv-1']);
      expect(searchDetails.meta).toEqual({
        total: 1,
        page: 1,
        limit: 50,
        totalPages: 1,
      });
    });

    it('acquires FOR UPDATE row locks before mutating tiers in override and batch evaluation commits', async () => {
      const h = makeRankingServiceHarness();

      await h.service.overrideDriverTier(
        'drv-1',
        { newTier: DriverTier.GOLD, reason: 'Lock check override' },
        { sub: 'admin-1', role: Role.ADMIN } as any,
      );

      expect(h.prisma.$executeRaw).toHaveBeenCalledTimes(1);
      const overrideLockStrings = h.prisma.$executeRaw.mock.calls[0][0] as string[];
      expect(overrideLockStrings.join('?')).toContain('FOR UPDATE');
      expect(h.prisma.$executeRaw.mock.calls[0].slice(1)).toEqual(['drv-1']);
      expect(
        h.prisma.$executeRaw.mock.invocationCallOrder[0],
      ).toBeLessThan(h.prisma.driver.update.mock.invocationCallOrder[0]);

      h.prisma.$executeRaw.mockClear();
      h.drivers.reverse(); // Force unsorted input order [drv-2, drv-1]

      await h.service.runEvaluation({
        triggerSource: DriverRankingTriggerSource.SCHEDULED,
      });

      expect(h.prisma.$executeRaw).toHaveBeenCalledTimes(1);
      const batchTemplateStrings = h.prisma.$executeRaw.mock.calls[0][0] as string[];
      const batchJoinedIdsSql = h.prisma.$executeRaw.mock.calls[0][1];
      expect(batchTemplateStrings.join('?')).toContain('ORDER BY id FOR UPDATE');
      expect(batchJoinedIdsSql.values).toEqual(['drv-1', 'drv-2']);
    });

    it('DriverDeliveryIncidentsService reviews incidents with audit trail and strips nested Prisma relations', async () => {
      const h = makeRankingServiceHarness();
      const updated = await h.incidentsService.reviewIncident(
        'inc-2',
        {
          responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
          reviewNote: 'Confirmed driver abandoned pickup without valid reason',
        },
        { sub: 'admin-1', role: Role.ADMIN } as any,
      );

      expect(updated.responsibility).toBe(
        DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
      );
      expect(updated.driverName).toBe('Driver One');
      expect(updated.orderNumber).toBe('OTL-2');
      expect((updated as any).driver).toBeUndefined();
      expect((updated as any).order).toBeUndefined();
      expect(h.emit).toHaveBeenCalledWith(
        EVENTS.AUDIT_LOG_CREATED,
        expect.objectContaining({
          action: 'REVIEW_DELIVERY_INCIDENT',
          entityId: 'inc-2',
        }),
      );
    });
  });

  describe('Legacy tier mutation removal & cancellation accountability', () => {
    it('ReviewsProcessor updates rating and ratingCount ONLY without mutating tier', async () => {
      const updateMock = jest.fn().mockResolvedValue({});
      const prisma: any = {
        orderReview: {
          aggregate: jest.fn().mockResolvedValue({
            _avg: { rating: 4.9 },
            _count: { _all: 25 },
          }),
        },
        driver: { update: updateMock },
      };

      const processor = new ReviewsProcessor(prisma);
      await processor.process({
        id: 'job-1',
        name: REVIEW_JOBS.UPDATE_RATINGS,
        data: { vendorId: null, driverId: 'drv-1' },
      } as any);

      expect(updateMock).toHaveBeenCalledWith({
        where: { id: 'drv-1' },
        data: { rating: 490, ratingCount: 25 },
      });
    });

    it('DriverShiftsService.handle5MinLateCheck marks MISSED without mutating tier', async () => {
      const driverUpdateMock = jest.fn();
      const shiftUpdateManyMock = jest.fn().mockResolvedValue({ count: 1 });
      const emitMock = jest.fn();
      const prisma: any = {
        driverShift: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'sh-1',
              driverId: 'drv-1',
              driver: { tier: DriverTier.GOLD, user: { id: 'u-1' } },
            },
          ]),
          updateMany: shiftUpdateManyMock,
        },
        driver: { update: driverUpdateMock },
      };
      const settings: any = {
        getSettings: jest
          .fn()
          .mockResolvedValue({ driverShiftsEnabled: true }),
      };

      const svc = new DriverShiftsService(prisma, settings, {
        emit: emitMock,
      } as any);
      await svc.handle5MinLateCheck();

      expect(shiftUpdateManyMock).toHaveBeenCalled();
      expect(driverUpdateMock).not.toHaveBeenCalled();
      expect(emitMock).toHaveBeenCalledWith(
        EVENTS.SHIFT_MISSED,
        expect.objectContaining({ driverUserId: 'u-1', shiftId: 'sh-1' }),
      );
    });

    it('DriverShiftsService.removeDriverFromShift protects historical COMPLETED/MISSED shifts', async () => {
      const prisma: any = {
        driverShift: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'sh-1',
            driverId: 'drv-1',
            status: DriverShiftStatus.MISSED,
            driver: { status: 'OFFLINE', user: { id: 'u-1' } },
            swapRequests: [],
          }),
        },
      };
      const svc = new DriverShiftsService(prisma, {} as any, {
        emit: jest.fn(),
      } as any);

      await expect(
        svc.removeDriverFromShift('sh-1', {
          sub: 'admin-1',
          role: Role.SUPER_ADMIN,
        } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('DriverShiftsService.excuseShift emits audit log on excuse change', async () => {
      const emitMock = jest.fn();
      const prisma: any = {
        driverShift: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'sh-1',
            driverId: 'drv-1',
            status: DriverShiftStatus.MISSED,
            isExcused: false,
            excuseReason: null,
          }),
          update: jest.fn().mockResolvedValue({
            id: 'sh-1',
            driverId: 'drv-1',
            status: DriverShiftStatus.MISSED,
            isExcused: true,
            excuseReason: 'Hospital emergency',
          }),
        },
      };
      const svc = new DriverShiftsService(prisma, {} as any, {
        emit: emitMock,
      } as any);

      const res = await svc.excuseShift(
        'sh-1',
        { sub: 'admin-1', role: Role.ADMIN } as any,
        { isExcused: true, excuseReason: 'Hospital emergency' },
      );

      expect(res.isExcused).toBe(true);
      expect(emitMock).toHaveBeenCalledWith(
        EVENTS.AUDIT_LOG_CREATED,
        expect.objectContaining({
          action: 'EXCUSE_DRIVER_SHIFT',
          entityId: 'sh-1',
        }),
      );
    });

    it('OrderCancellationService requires responsibleDriverId for multi-driver DRIVER_AT_FAULT cancellation and validates assignment', async () => {
      const cancelOrderMock = jest.fn();
      const prisma: any = {
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              isPaymentCollector: true,
              primaryDriverId: 'drv-1',
              assistDriverId: null,
              primaryDriver: { userId: 'u-d1' },
            },
            {
              id: 'grp-2',
              sequence: 2,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              isPaymentCollector: false,
              primaryDriverId: 'drv-2',
              assistDriverId: null,
              primaryDriver: { userId: 'u-d2' },
            },
          ]),
        },
        user: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'admin-1',
            name: 'Ops Admin',
            avatar: null,
            role: Role.ADMIN,
            driver: null,
            vendorMemberships: [],
          }),
        },
      };
      const repo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-mv',
          orderNumber: 'ORD-MV',
          status: OrderStatus.DRIVER_ASSIGNED,
          coinsUsed: 0,
          customerId: 'c1',
          customer: { userId: 'u-c1', user: { id: 'u-c1' } },
          vendorFulfillments: [{ vendorId: 'v-1' }],
        }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
        cancelOrder: cancelOrderMock,
      };
      const svc = new OrderCancellationService(
        repo,
        prisma,
        { canManageOrders: jest.fn().mockResolvedValue(true) } as any,
        { emit: jest.fn() } as any,
      );

      await expect(
        svc.cancelOrder(
          { sub: 'admin-1', role: Role.ADMIN } as any,
          'ord-mv',
          'Ambiguous fault without specifying which driver',
          { responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT },
        ),
      ).rejects.toThrow(BadRequestException);

      await expect(
        svc.cancelOrder(
          { sub: 'admin-1', role: Role.ADMIN } as any,
          'ord-mv',
          'Wrong driver id',
          {
            responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
            responsibleDriverId: 'drv-unassigned',
          },
        ),
      ).rejects.toThrow(BadRequestException);
      expect(cancelOrderMock).not.toHaveBeenCalled();
    });

    it('OrderCancellationService classifies admin cancellation responsibility per assigned delivery group', async () => {
      const cancelOrderMock = jest.fn().mockResolvedValue({
        id: 'ord-1',
        revision: 3,
        customer: { user: { id: 'u-c1' } },
        deliveryGroups: [],
      });
      const prisma: any = {
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              isPaymentCollector: true,
              primaryDriverId: 'drv-1',
              assistDriverId: null,
              primaryDriver: { userId: 'u-d1' },
            },
          ]),
        },
        user: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'admin-1',
            name: 'Ops Admin',
            avatar: null,
            role: Role.ADMIN,
            driver: null,
            vendorMemberships: [],
          }),
        },
      };
      const repo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-1',
          orderNumber: 'ORD-1',
          status: OrderStatus.DRIVER_ASSIGNED,
          coinsUsed: 0,
          customerId: 'c1',
          customer: { userId: 'u-c1', user: { id: 'u-c1' } },
          vendorFulfillments: [{ vendorId: 'v-1' }],
        }),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
        cancelOrder: cancelOrderMock,
      };
      const svc = new OrderCancellationService(
        repo,
        prisma,
        { canManageOrders: jest.fn().mockResolvedValue(true) } as any,
        { emit: jest.fn() } as any,
      );

      await svc.cancelOrder(
        { sub: 'admin-1', role: Role.ADMIN } as any,
        'ord-1',
        'Driver asked support to drop without valid excuse',
        { responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT },
      );

      expect(cancelOrderMock).toHaveBeenCalledWith(
        'ord-1',
        'admin-1',
        'Driver asked support to drop without valid excuse',
        OrderStatus.DRIVER_ASSIGNED,
        0,
        'c1',
        'ORD-1',
        ['drv-1'],
        expect.objectContaining({
          driverIncidents: [
            expect.objectContaining({
              deliveryGroupId: 'grp-1',
              driverId: 'drv-1',
              responsibility: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
            }),
          ],
        }),
      );
    });

    it('DriverAdminService requires mandatory reason when manually changing driver tier', async () => {
      const driverData = {
        id: 'drv-1',
        userId: 'u-1',
        tier: DriverTier.SILVER,
        status: 'OFFLINE',
      };
      const txCreateHistory = jest.fn().mockResolvedValue({ id: 'h-1' });
      const prisma: any = {
        user: {
          findUnique: jest.fn().mockResolvedValue({ role: Role.ADMIN }),
        },
        driver: { update: jest.fn().mockResolvedValue(driverData) },
        driverRankHistory: { create: txCreateHistory },
        $transaction: jest.fn((fn) => fn(prisma)),
      };
      const repo: any = {
        findById: jest.fn().mockResolvedValue(driverData),
        update: jest.fn(),
      };
      const emit = jest.fn();

      const adminService = new DriverAdminService(
        repo,
        prisma,
        {} as any,
        {} as any,
        {} as any,
        { emit } as any,
      );

      await expect(
        adminService.adminUpdateDriver('drv-1', 'admin-1', {
          tier: DriverTier.GOLD,
        }),
      ).rejects.toThrow(BadRequestException);

      await adminService.adminUpdateDriver('drv-1', 'admin-1', {
        tier: DriverTier.GOLD,
        tierOverrideReason: 'Verified special case',
      });

      expect(txCreateHistory).toHaveBeenCalledWith({
        data: expect.objectContaining({
          driverId: 'drv-1',
          previousTier: DriverTier.SILVER,
          newTier: DriverTier.GOLD,
          changeReason: DriverRankChangeReason.ADMIN_OVERRIDE,
          overrideReason: 'Verified special case',
        }),
      });
      expect(emit).toHaveBeenCalledWith(
        EVENTS.DRIVER_RANK_UPDATED,
        expect.objectContaining({ driverId: 'drv-1', newTier: DriverTier.GOLD }),
      );
    });

    it('DriverListener & NotificationListener deliver rank change and failure notifications', async () => {
      const addQueue = jest.fn().mockResolvedValue({});
      const emitToUser = jest.fn().mockResolvedValue(undefined);
      const driverListener = new DriverListener(
        { emitToUser } as any,
        { add: addQueue } as any,
      );

      await driverListener.handleRankUpdated(
        new DriverRankUpdatedEvent(
          'drv-1',
          'u-d1',
          DriverTier.SILVER,
          DriverTier.GOLD,
          98.33,
          '2026-W45',
          DriverRankChangeReason.WEEKLY_EVALUATION,
        ),
      );
      expect(emitToUser).toHaveBeenCalledWith(
        'u-d1',
        'driver.rank.updated',
        expect.objectContaining({ newTier: DriverTier.GOLD }),
      );
      expect(addQueue).toHaveBeenCalledTimes(1);

      // Unchanged tier should not spam notification
      await driverListener.handleRankUpdated(
        new DriverRankUpdatedEvent(
          'drv-1',
          'u-d1',
          DriverTier.GOLD,
          DriverTier.GOLD,
          98.33,
          '2026-W46',
          DriverRankChangeReason.WEEKLY_EVALUATION,
        ),
      );
      expect(addQueue).toHaveBeenCalledTimes(1);

      // Admin alert on failed evaluation
      const notifListener = new NotificationListener(
        { add: addQueue } as any,
        {
          user: {
            findMany: jest
              .fn()
              .mockResolvedValue([{ id: 'admin-1' }, { id: 'admin-2' }]),
          },
        } as any,
      );
      await notifListener.handleRankEvaluationFailed(
        new DriverRankEvaluationFailedEvent('run-1', '2026-W45', 'DB timeout'),
      );
      expect(addQueue).toHaveBeenCalledTimes(3);
    });

    it('OrdersStateService.adminForceAssignDriver forwards previousDriverResponsibility & reason to assignDriver', async () => {
      const assignDriverMock = jest.fn().mockResolvedValue({
        revision: 4,
        status: OrderStatus.DRIVER_ASSIGNED,
      });
      const ordersRepo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-r1',
          orderNumber: 'OTL-R1',
          status: OrderStatus.DRIVER_ASSIGNED,
          paymentMethod: 'CASH_ON_DELIVERY',
          paymentStatus: 'PENDING',
          customerId: 'c-1',
          customer: { user: { id: 'u-c1' } },
          vendorFulfillments: [{ vendorId: 'v-1' }],
        }),
        assignDriver: assignDriverMock,
        freeDriver: jest.fn().mockResolvedValue(undefined),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
      };
      const prisma: any = {
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-new',
            status: 'ONLINE',
            userId: 'u-drv-new',
          }),
        },
        platformSetting: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ maxActiveOrdersPerDriver: 2 }),
        },
        driverShift: { findFirst: jest.fn().mockResolvedValue({ id: 'sh-1' }) },
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: OrderStatus.DRIVER_ASSIGNED }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              primaryDriverId: 'drv-old',
              assistDriverId: null,
            },
          ]),
          update: jest.fn().mockResolvedValue({}),
        },
      };
      const svc = new OrdersStateService(
        ordersRepo,
        {} as any,
        {} as any,
        { emit: jest.fn() } as any,
        prisma,
        {} as any,
        undefined,
        undefined,
        undefined,
        undefined,
        { countActiveUnits: jest.fn().mockResolvedValue(0) } as any,
      );

      await svc.adminForceAssignDriver(
        { sub: 'admin-1', role: Role.ADMIN } as any,
        'ord-r1',
        {
          driverId: 'drv-new',
          previousDriverResponsibility:
            DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
          reassignmentReason: 'Refused pickup after accepting',
        },
      );

      expect(assignDriverMock).toHaveBeenCalledWith(
        'ord-r1',
        'drv-new',
        'sh-1',
        'admin-1',
        OrderStatus.DRIVER_ASSIGNED,
        2,
        'grp-1',
        {
          previousDriverResponsibility:
            DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
          reassignmentReason: 'Refused pickup after accepting',
        },
      );
    });
  });

  describe('StatisticsAnalyticsRepository & Weekly Ranking KPI Parity', () => {
    it('getDriverStats exposes eligibleDispatches, acceptanceRate, driverFaultCancellations, and completionRate matching ranking formulas', async () => {
      const occurredAt = new Date('2026-11-10T12:00:00.000Z');
      const prisma: any = {
        driverStatistic: {
          findMany: jest.fn().mockResolvedValue([
            {
              driverId: 'drv-1',
              period: StatisticPeriod.DAILY,
              startDate: new Date('2026-11-09T22:00:00.000Z'),
              totalOrders: 11,
              totalEarnings: 420,
              completedOrders: 7,
              cancelledOrders: 4, // 3 non-driver-fault + 1 driver fault
              onlineHours: 8,
              totalDispatchesReceived: 15, // includes 5 cancelled broadcast offers
              dispatchesAccepted: 8,
              dispatchesRejected: 2,
              dispatchesExpired: 0,
            },
          ]),
        },
        driverDeliveryIncident: {
          findMany: jest.fn().mockResolvedValue([
            { deliveryGroupId: 'grp-1', occurredAt },
            // Duplicate incident on same deliveryGroupId must deduplicate
            { deliveryGroupId: 'grp-1', occurredAt },
          ]),
        },
      };

      const repo = new StatisticsAnalyticsRepository(prisma);
      const [bucket] = await repo.getDriverStats(
        'drv-1',
        StatisticPeriod.WEEKLY,
        1,
        '2026-11-09',
        '2026-11-15',
      );

      expect(bucket.eligibleDispatches).toBe(10);
      expect(bucket.acceptanceRate).toBe(80);
      expect(bucket.driverFaultCancellations).toBe(1);
      expect(bucket.completionRate).toBe(87.5);
      expect(bucket.totalDispatchesReceived).toBe(15);
      expect(bucket.cancelledOrders).toBe(4);
    });

    it('getManagedDriversStats computes canonical acceptanceRate & completionRate for totals and each driver row', async () => {
      const prisma: any = {
        driverStatistic: {
          findMany: jest.fn().mockResolvedValue([
            {
              driverId: 'drv-1',
              period: StatisticPeriod.DAILY,
              startDate: new Date('2026-11-09T22:00:00.000Z'),
              totalOrders: 11,
              totalEarnings: 420,
              completedOrders: 7,
              cancelledOrders: 4,
              onlineHours: 8,
              totalDispatchesReceived: 15,
              dispatchesAccepted: 8,
              dispatchesRejected: 2,
              dispatchesExpired: 0,
            },
          ]),
        },
        driver: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'drv-1',
              name: 'Driver One',
              avatar: null,
              tier: DriverTier.SILVER,
              status: 'ONLINE',
              user: { name: 'Driver One', phone: '+2010', avatar: null },
            },
          ]),
        },
        driverDeliveryIncident: {
          findMany: jest.fn().mockResolvedValue([
            { driverId: 'drv-1', deliveryGroupId: 'grp-1' },
          ]),
        },
      };

      const repo = new StatisticsAnalyticsRepository(prisma);
      const res = await repo.getManagedDriversStats(
        ['drv-1'],
        StatisticPeriod.WEEKLY,
        1,
        '2026-11-09',
        '2026-11-15',
      );

      expect(res.totals.eligibleDispatches).toBe(10);
      expect(res.totals.acceptanceRate).toBe(80);
      expect(res.totals.driverFaultCancellations).toBe(1);
      expect(res.totals.completionRate).toBe(87.5);
      expect(res.drivers[0].acceptanceRate).toBe(80);
      expect(res.drivers[0].completionRate).toBe(87.5);
    });
  });

  describe('Cross-system fairness & tier parity (Dispatch expiry, Suspended drivers, Earnings)', () => {
    it('DispatchLifecycleService.handleExpiry marks mid-broadcast busy/on-break candidates CANCELLED instead of EXPIRED', async () => {
      const expiresAt = new Date(Date.now() + 60_000).toISOString();
      const createTerminalRecords = jest.fn().mockResolvedValue(undefined);
      const dispatchRepository: any = {
        getBroadcast: jest.fn().mockResolvedValue({
          dispatchId: 'disp-exp-1',
          orderId: 'ord-1',
          deliveryGroupId: 'grp-1',
          type: 'STANDARD',
          expiresAt,
          candidates: [
            {
              driverId: 'drv-avail',
              userId: 'u-avail',
              driverShiftId: 'sh-avail',
              deliveryGroupId: 'grp-1',
              distanceKm: 1.2,
              estimatedEarnings: 30,
            },
            {
              driverId: 'drv-busy',
              userId: 'u-busy',
              driverShiftId: 'sh-busy',
              deliveryGroupId: 'grp-1',
              distanceKm: 1.5,
              estimatedEarnings: 30,
            },
            {
              driverId: 'drv-break',
              userId: 'u-break',
              driverShiftId: 'sh-break',
              deliveryGroupId: 'grp-1',
              distanceKm: 1.8,
              estimatedEarnings: 30,
            },
          ],
        }),
        releaseActiveClaim: jest.fn().mockResolvedValue(true),
        deleteBroadcast: jest.fn().mockResolvedValue(undefined),
        deleteDispatchState: jest.fn().mockResolvedValue(undefined),
        getRejectedDriverIds: jest.fn().mockResolvedValue([]),
        deleteRejectedSet: jest.fn().mockResolvedValue(undefined),
        removeDispatchForCandidates: jest.fn().mockResolvedValue(undefined),
        createTerminalRecords,
        saveDispatchState: jest.fn().mockResolvedValue(undefined),
      };
      const shiftUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
      const prisma: any = {
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: OrderStatus.LOOKING_FOR_DRIVER }),
        },
        orderDeliveryGroup: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: DeliveryGroupStatus.LOOKING_FOR_DRIVER }),
          findMany: jest.fn().mockResolvedValue([
            // drv-busy accepted another order after broadcast
            { primaryDriverId: 'drv-busy', assistDriverId: null },
          ]),
        },
        driver: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'drv-avail',
              status: DriverStatus.ONLINE,
              isApproved: true,
              deletedAt: null,
              hasUnpaidCommission: false,
            },
            {
              id: 'drv-busy',
              status: DriverStatus.ON_DELIVERY,
              isApproved: true,
              deletedAt: null,
              hasUnpaidCommission: false,
            },
            {
              id: 'drv-break',
              status: DriverStatus.ON_BREAK,
              isApproved: true,
              deletedAt: null,
              hasUnpaidCommission: false,
            },
          ]),
        },
        driverShift: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'sh-avail', driverId: 'drv-avail' },
            { id: 'sh-busy', driverId: 'drv-busy' },
            { id: 'sh-break', driverId: 'drv-break' },
          ]),
          updateMany: shiftUpdateMany,
        },
      };
      const emit = jest.fn();
      const lifecycle = new DispatchLifecycleService(
        dispatchRepository,
        {
          getSettings: jest.fn().mockResolvedValue({
            maxActiveOrdersPerDriver: 1,
            driverShiftsEnabled: true,
            driverAcceptTimeoutSecs: 30,
          }),
        } as any,
        { emit } as any,
        prisma,
        {} as any,
        { add: jest.fn().mockResolvedValue(undefined) } as any,
        { add: jest.fn() } as any,
        {} as any,
        {} as any,
        new DriverWorkloadHelper(),
      );

      await lifecycle.handleExpiry({
        dispatchId: 'disp-exp-1',
        orderId: 'ord-1',
        orderNumber: 'ORD-1',
        attempt: 1,
        excludeDriverIds: [],
        deliveryGroupId: 'grp-1',
      });

      expect(createTerminalRecords).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          status: DispatchStatus.CANCELLED,
          candidates: [
            expect.objectContaining({ driverId: 'drv-busy' }),
            expect.objectContaining({ driverId: 'drv-break' }),
          ],
        }),
      );
      expect(createTerminalRecords).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          status: DispatchStatus.EXPIRED,
          candidates: [expect.objectContaining({ driverId: 'drv-avail' })],
        }),
      );
      expect(shiftUpdateMany).toHaveBeenCalledWith({
        where: { id: { in: ['sh-avail'] } },
        data: { expiredDispatches: { increment: 1 } },
      });
      const respondedCalls = emit.mock.calls.filter(
        (c) => c[0] === EVENTS.ORDER_DISPATCH_RESPONDED,
      );
      expect(respondedCalls).toHaveLength(1);
      expect(respondedCalls[0][1]).toMatchObject({
        driverId: 'drv-avail',
        status: DispatchStatus.EXPIRED,
      });
    });

    it('keeps suspended BRONZE driver unchanged on 0 weekly activity while scoring prior weekly work normally', () => {
      const suspendedInactiveBronze = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'drv-susp-bronze',
          currentTier: DriverTier.BRONZE,
          isSuspended: true,
        }),
      );
      expect(suspendedInactiveBronze.newTier).toBe(DriverTier.BRONZE);
      expect(suspendedInactiveBronze.outcome).toBe(
        DriverRankingOutcome.UNCHANGED,
      );
      expect(suspendedInactiveBronze.changeReason).toBe(
        DriverRankChangeReason.INACTIVE_DRIVER,
      );

      const suspendedWithPriorWork = evaluateDriverWeeklyMetrics(
        makeInput({
          driverId: 'drv-susp-worked',
          currentTier: DriverTier.GOLD,
          isSuspended: true,
          acceptedDispatches: 7,
          rejectedDispatches: 3,
          completedOrders: 7,
          driverFaultFailures: 3,
          onTimeShifts: 7,
          missedShifts: 3,
        }),
      );
      expect(suspendedWithPriorWork.performancePercentage).toBe(70);
      expect(suspendedWithPriorWork.newTier).toBe(DriverTier.BRONZE);
      expect(suspendedWithPriorWork.outcome).toBe(DriverRankingOutcome.DEMOTED);
    });

    it('OrderEarningsCalculator applies tier per-km bonus adjustment identically to OrderSettlementService', () => {
      const calculator = new OrderEarningsCalculator();
      const settings = {
        driverShiftsEnabled: true,
        goldTierBonusPerKm: 2,
        silverTierBonusPerKm: 1,
        bronzeTierBonusPerKm: 0,
        deliveryCommissionRate: 20,
        driverManagerCommissionRate: 10,
      };

      expect(
        calculator.calculateDriverEarningsForFee(50, settings, {
          driverTier: 'GOLD',
          distanceKm: 5,
          isStandardOrder: true,
        }),
      ).toBe(35);

      expect(
        calculator.calculateDriverEarningsForFee(50, settings, {
          driverTier: 'SILVER',
          distanceKm: 5,
          isStandardOrder: true,
        }),
      ).toBe(32);

      expect(
        calculator.calculateDriverEarningsForFee(50, settings, {
          driverTier: 'BRONZE',
          distanceKm: 5,
          isStandardOrder: true,
        }),
      ).toBe(27);
    });

    it('DispatchLifecycleService.handleExpiry skips EXPIRED penalty and retries when group already has primaryDriverId (acceptance-vs-expiry race)', async () => {
      const expiresAt = new Date(Date.now() - 5_000).toISOString();
      const createTerminalRecords = jest.fn().mockResolvedValue(undefined);
      const deleteBroadcast = jest.fn().mockResolvedValue(undefined);
      const deleteDispatchState = jest.fn().mockResolvedValue(undefined);
      const deleteRejectedSet = jest.fn().mockResolvedValue(undefined);
      const removeDispatchForCandidates = jest
        .fn()
        .mockResolvedValue(undefined);
      const dispatchRepository: any = {
        getBroadcast: jest.fn().mockResolvedValue({
          dispatchId: 'disp-race-1',
          orderId: 'ord-race-1',
          deliveryGroupId: 'grp-race-1',
          type: 'STANDARD',
          expiresAt,
          candidates: [
            {
              driverId: 'drv-avail',
              userId: 'u-avail',
              driverShiftId: 'sh-avail',
              deliveryGroupId: 'grp-race-1',
              distanceKm: 1.0,
              estimatedEarnings: 25,
            },
          ],
        }),
        releaseActiveClaim: jest.fn().mockResolvedValue(true),
        deleteBroadcast,
        deleteDispatchState,
        getRejectedDriverIds: jest.fn().mockResolvedValue([]),
        deleteRejectedSet,
        removeDispatchForCandidates,
        createTerminalRecords,
        saveDispatchState: jest.fn().mockResolvedValue(undefined),
      };
      const shiftUpdateMany = jest.fn().mockResolvedValue({ count: 0 });
      const retryQueueAdd = jest.fn().mockResolvedValue(undefined);
      const emit = jest.fn();
      const prisma: any = {
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: OrderStatus.LOOKING_FOR_DRIVER }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
            primaryDriverId: 'drv-winner',
          }),
        },
        driverShift: { updateMany: shiftUpdateMany },
      };

      const lifecycle = new DispatchLifecycleService(
        dispatchRepository,
        {
          getSettings: jest.fn().mockResolvedValue({
            maxActiveOrdersPerDriver: 1,
            driverShiftsEnabled: true,
            driverAcceptTimeoutSecs: 30,
          }),
        } as any,
        { emit } as any,
        prisma,
        {} as any,
        { add: retryQueueAdd } as any,
        { add: jest.fn() } as any,
        {} as any,
        {} as any,
        new DriverWorkloadHelper(),
      );

      await lifecycle.handleExpiry({
        dispatchId: 'disp-race-1',
        orderId: 'ord-race-1',
        orderNumber: 'ORD-RACE-1',
        attempt: 1,
        excludeDriverIds: [],
        deliveryGroupId: 'grp-race-1',
      });

      expect(deleteBroadcast).toHaveBeenCalledWith('disp-race-1');
      expect(dispatchRepository.releaseActiveClaim).toHaveBeenCalledWith(
        'grp-race-1',
        'disp-race-1',
      );
      expect(deleteDispatchState).toHaveBeenCalledWith('grp-race-1');
      expect(createTerminalRecords).not.toHaveBeenCalled();
      expect(shiftUpdateMany).not.toHaveBeenCalled();
      expect(retryQueueAdd).not.toHaveBeenCalled();
      expect(emit).not.toHaveBeenCalled();
    });

    it('records DRIVER_UNASSIGNED on assist decline and DELIVERY_FAILURE on vendor-rejected assigned delivery group', async () => {
      const createIncident = jest.fn().mockResolvedValue({ id: 'inc-new' });
      const assistPrisma: any = {
        customer: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'cust-1', userId: 'u-cust-1' }),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-1',
            customerId: 'cust-1',
            orderNumber: 'ORD-1',
            status: OrderStatus.DRIVER_ASSIGNED,
          }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            orderId: 'ord-1',
            status: DeliveryGroupStatus.DRIVER_ASSIGNED,
            primaryDriverId: 'drv-primary',
            assistDriverId: 'drv-assist',
            assistFee: 25,
            assistCustomerApproved: null,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        driverAssistRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        driverDeliveryIncident: {
          create: createIncident,
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({ userId: 'u-drv' }),
        },
      };

      const assistService = new DriverAssistService(
        assistPrisma,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn() } as any,
        { clearOffer: jest.fn() } as any,
        {
          cancelOrder: jest.fn(),
          recomputeGroupedOrderStatusAfterCancel: jest.fn(),
          cancelDeliveryGroupAfterAssistFailure: jest
            .fn()
            .mockResolvedValue(undefined),
        },
      );

      await assistService.customerDecideAssist(
        { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
        'ord-1',
        'grp-1',
        false,
      );

      expect(createIncident).toHaveBeenCalledWith({
        data: expect.objectContaining({
          orderId: 'ord-1',
          deliveryGroupId: 'grp-1',
          driverId: 'drv-assist',
          incidentType: DeliveryIncidentType.DRIVER_UNASSIGNED,
          responsibility: DeliveryIncidentResponsibility.CUSTOMER,
        }),
      });

      const txIncidentCreate = jest.fn().mockResolvedValue({ id: 'inc-vf' });
      const recomputorTx: any = {
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            deliveryFee: 30,
            sequence: 2,
            primaryDriverId: 'drv-primary',
            assistDriverId: null,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        orderDeliveryGroupItem: {
          count: jest.fn().mockResolvedValue(0),
        },
        orderDispatch: {
          updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        orderStatusEvent: {
          upsert: jest.fn().mockResolvedValue({}),
        },
        driverDeliveryIncident: {
          create: txIncidentCreate,
        },
      };
      const recomputor = new OrderRejectionRecomputor({} as any, {} as any);
      await recomputor.syncDeliveryGroupAfterVendorRemoved(
        recomputorTx,
        'grp-2',
        'ord-1',
        OrderStatus.DRIVER_ASSIGNED,
      );

      expect(txIncidentCreate).toHaveBeenCalledWith({
        data: expect.objectContaining({
          orderId: 'ord-1',
          deliveryGroupId: 'grp-2',
          driverId: 'drv-primary',
          incidentType: DeliveryIncidentType.DELIVERY_FAILURE,
          responsibility: DeliveryIncidentResponsibility.VENDOR,
        }),
      });
    });
  });
});
