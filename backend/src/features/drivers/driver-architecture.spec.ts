import * as fs from 'fs';
import * as path from 'path';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DriverAssistRequestStatus,
  DriverBreakReason,
  DriverShiftStatus,
  DriverStatus,
  NotificationType,
  Role,
} from '@prisma/client';
import { DriverErrors } from '../../common/constants/response.constants';
import {
  DriverAssistAssignedEvent,
  DriverAssistCustomerDecidedEvent,
  DriverAssistOfferedEvent,
  DriverAssistTimedOutEvent,
  DriverBreakDecidedEvent,
  DriverStatusChangedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { DriverAssistListener } from '../../common/listeners/driver-assist.listener';
import { DriverListener } from '../../common/listeners/driver.listener';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import { DriverAssistMatchingService } from './driver-assist-matching.service';
import { DriverAssistService } from './driver-assist.service';
import { DriverBreaksService } from './driver-breaks.service';
import { DriverShiftExecutionService } from './driver-shift-execution.service';

describe('Drivers & Assist Clean Architecture', () => {
  const customerActor: JwtAccessPayload = {
    sub: 'cust-user-1',
    sid: 'sid-cust-1',
    role: Role.CUSTOMER,
    verified: true,
  };

  const driverActor: JwtAccessPayload = {
    sub: 'drv-user-2',
    sid: 'sid-drv-2',
    role: Role.DRIVER,
    verified: true,
  };

  describe('Acyclic Orders <-> Drivers module wiring & OrderAssistCancellationPort', () => {
    it('uses zero forwardRef, isolates Statistics/Orders/Socket boundaries, and decouples assist side effects via events', () => {
      const ordersModuleSrc = fs.readFileSync(
        path.resolve(__dirname, '../orders/orders.module.ts'),
        'utf8',
      );
      const driversModuleSrc = fs.readFileSync(
        path.resolve(__dirname, './drivers.module.ts'),
        'utf8',
      );
      const statisticsModuleSrc = fs.readFileSync(
        path.resolve(__dirname, '../statistics/statistics.module.ts'),
        'utf8',
      );
      const driverShiftsModuleSrc = fs.readFileSync(
        path.resolve(__dirname, '../driver-shifts/driver-shifts.module.ts'),
        'utf8',
      );
      const orderSettlementSrc = fs.readFileSync(
        path.resolve(__dirname, '../orders/order-settlement.service.ts'),
        'utf8',
      );
      const driverAssistSrc = fs.readFileSync(
        path.resolve(__dirname, './driver-assist.service.ts'),
        'utf8',
      );
      const driverAssistMatchingSrc = fs.readFileSync(
        path.resolve(__dirname, './driver-assist-matching.service.ts'),
        'utf8',
      );

      expect(ordersModuleSrc).not.toContain('forwardRef');
      expect(ordersModuleSrc).not.toContain('StatisticsModule');
      expect(ordersModuleSrc).not.toContain('SocketModule');
      expect(ordersModuleSrc).toContain('OrderSettlementService');
      expect(ordersModuleSrc).toContain('ORDER_ASSIST_CANCELLATION_PORT');

      expect(statisticsModuleSrc).not.toContain('SocketModule');
      expect(statisticsModuleSrc).not.toContain('PlatformSettingsModule');
      expect(statisticsModuleSrc).not.toContain('OrderSettlementService');

      expect(driversModuleSrc).not.toContain('forwardRef');
      expect(driversModuleSrc).not.toContain('SocketModule');
      expect(driversModuleSrc).toContain('OrdersModule');
      expect(driversModuleSrc).toContain('OrderAssistDecisionController');

      expect(driverShiftsModuleSrc).not.toContain('NotificationsModule');
      expect(driverShiftsModuleSrc).not.toContain('SocketModule');

      expect(orderSettlementSrc).not.toContain('SocketService');
      expect(orderSettlementSrc).not.toContain('StatisticsRepository');

      expect(driverAssistSrc).not.toContain('NotificationsService');
      expect(driverAssistSrc).not.toContain('SocketService');
      expect(driverAssistMatchingSrc).not.toContain('NotificationsService');
      expect(driverAssistMatchingSrc).not.toContain('SocketService');
    });

    it('cancels the delivery group via OrderAssistCancellationPort when customer declines assist', async () => {
      const ordersState = {
        cancelOrder: jest.fn().mockResolvedValue({ cancelled: true }),
        recomputeGroupedOrderStatusAfterCancel: jest
          .fn()
          .mockResolvedValue(undefined),
        cancelDeliveryGroupAfterAssistFailure: jest
          .fn()
          .mockResolvedValue(undefined),
      };

      const prisma: any = {
        customer: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'cust-1', userId: 'cust-user-1' }),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'order-1',
            customerId: 'cust-1',
            orderNumber: 'ORD-1',
            status: 'DRIVER_ASSIGNED',
          }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            orderId: 'order-1',
            assistDriverId: 'drv-assist',
            assistFee: 30,
            assistCustomerApproved: null,
            primaryDriverId: 'drv-primary',
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          count: jest.fn().mockResolvedValue(0),
        },
        driverAssistRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({ userId: 'u-1' }),
        },
      };

      const eventEmit = jest.fn();
      const service = new DriverAssistService(
        prisma,
        { emit: eventEmit } as any,
        { getSettings: jest.fn() } as any,
        { clearOffer: jest.fn() } as any,
        ordersState,
      );

      const res = await service.customerDecideAssist(
        customerActor,
        'order-1',
        'grp-1',
        false,
      );

      expect(res).toEqual({ approved: false, assistFee: 30 });
      expect(
        ordersState.cancelDeliveryGroupAfterAssistFailure,
      ).toHaveBeenCalledWith(
        'order-1',
        'grp-1',
        'Customer declined assisted delivery',
        ['drv-primary', 'drv-assist'],
      );
      expect(eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED,
        expect.any(DriverAssistCustomerDecidedEvent),
      );
    });

    it('routes customerDecideAssistForOrder to the pending delivery group', async () => {
      const ordersState = {
        cancelOrder: jest.fn().mockResolvedValue(undefined),
        recomputeGroupedOrderStatusAfterCancel: jest
          .fn()
          .mockResolvedValue(undefined),
        cancelDeliveryGroupAfterAssistFailure: jest
          .fn()
          .mockResolvedValue(undefined),
      };

      const prisma: any = {
        customer: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'cust-1', userId: 'cust-user-1' }),
        },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'order-sv',
            customerId: 'cust-1',
            orderNumber: 'ORD-SV',
            status: 'DRIVER_ASSIGNED',
          }),
        },
        orderDeliveryGroup: {
          findFirst: jest.fn().mockResolvedValue({ id: 'grp-sv' }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-sv',
            orderId: 'order-sv',
            primaryDriverId: 'drv-1',
            assistDriverId: 'drv-assist',
            assistFee: 20,
            assistCustomerApproved: null,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        driverAssistRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({ userId: 'u-1' }),
        },
      };

      const service = new DriverAssistService(
        prisma,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn() } as any,
        { clearOffer: jest.fn() } as any,
        ordersState,
      );

      const res = await service.customerDecideAssistForOrder(
        customerActor,
        'order-sv',
        false,
      );

      expect(res).toEqual({ approved: false, assistFee: 20 });
      expect(
        ordersState.cancelDeliveryGroupAfterAssistFailure,
      ).toHaveBeenCalledWith(
        'order-sv',
        'grp-sv',
        'Customer declined assisted delivery',
        ['drv-1', 'drv-assist'],
      );
    });
  });

  describe('DriverBreaksService', () => {
    function makeBreaksHarness(overrides?: {
      breaksEnabled?: boolean;
      breakCount?: number;
      usedMinutes?: number;
      openBreaks?: any[];
      staleBreaks?: any[];
    }) {
      const driver = {
        id: 'drv-1',
        userId: 'drv-user-1',
        status: DriverStatus.ONLINE,
        isApproved: true,
      };
      const driversRepository: any = {
        findByUserId: jest.fn().mockResolvedValue(driver),
        findById: jest.fn().mockResolvedValue({ ...driver, status: DriverStatus.ON_BREAK }),
        findActiveBreak: jest.fn().mockResolvedValue(null),
        findActiveOrderForDriver: jest.fn().mockResolvedValue(null),
        findPendingDispatchForDriver: jest.fn().mockResolvedValue(null),
        findPendingBreak: jest.fn().mockResolvedValue(null),
        findActiveShiftForDriver: jest.fn().mockResolvedValue({ id: 'shift-1' }),
        countShiftBreaks: jest.fn().mockResolvedValue(overrides?.breakCount ?? 0),
        sumShiftBreakMinutes: jest
          .fn()
          .mockResolvedValue(overrides?.usedMinutes ?? 0),
        createBreak: jest.fn().mockResolvedValue({
          id: 'brk-new',
          driverId: 'drv-1',
          reason: DriverBreakReason.REST,
        }),
        findOpenBreaks: jest.fn().mockResolvedValue(overrides?.openBreaks ?? []),
        findBreakById: jest.fn().mockImplementation((id: string) =>
          Promise.resolve(
            (overrides?.openBreaks ?? []).find((b) => b.id === id) ?? null,
          ),
        ),
        endBreak: jest.fn().mockImplementation((id: string) =>
          Promise.resolve({ id, status: 'ENDED' }),
        ),
        updateStatus: jest.fn().mockResolvedValue(undefined),
        incrementShiftBreakMinutes: jest.fn().mockResolvedValue(undefined),
        findStalePendingBreaks: jest
          .fn()
          .mockResolvedValue(overrides?.staleBreaks ?? []),
        rejectBreak: jest.fn().mockImplementation((id: string) =>
          Promise.resolve({ id, driverId: 'drv-1', status: 'REJECTED' }),
        ),
      };
      // During assertCanBreak inside startBreak, driver status must be ONLINE (not ON_BREAK).
      driversRepository.findById.mockImplementation((id: string) => {
        if ((overrides?.openBreaks ?? []).length > 0 && id === 'drv-1') {
          return Promise.resolve({ ...driver, status: DriverStatus.ON_BREAK });
        }
        return Promise.resolve(driver);
      });

      const platformSettings: any = {
        getSettings: jest.fn().mockResolvedValue({
          breaksEnabled: overrides?.breaksEnabled ?? true,
          maxBreaksPerShift: 2,
          maxBreakMinutesPerShift: 30,
          maxSingleBreakMinutes: 15,
          pendingBreakExpiryMins: 10,
        }),
      };

      const eventEmit = jest.fn();

      const service = new DriverBreaksService(
        driversRepository,
        platformSettings,
        { assertManagesDriver: jest.fn() } as any,
        {
          getDriverLocation: jest.fn().mockResolvedValue(null),
          removeDriverLocation: jest.fn().mockResolvedValue(undefined),
        } as any,
        { emit: eventEmit } as unknown as EventEmitter2,
      );

      return { service, driversRepository, eventEmit };
    }

    it('rejects startBreak when breaksEnabled kill-switch is false or shift quotas are reached', async () => {
      const disabled = makeBreaksHarness({ breaksEnabled: false });
      await expect(disabled.service.startBreak('drv-user-1')).rejects.toThrow(
        new BadRequestException(DriverErrors.BREAKS_DISABLED),
      );

      const countMaxed = makeBreaksHarness({ breakCount: 2 });
      await expect(countMaxed.service.startBreak('drv-user-1')).rejects.toThrow(
        new BadRequestException(DriverErrors.BREAK_LIMIT_REACHED),
      );

      const minsMaxed = makeBreaksHarness({ usedMinutes: 30 });
      await expect(minsMaxed.service.startBreak('drv-user-1')).rejects.toThrow(
        new BadRequestException(DriverErrors.BREAK_MINUTES_EXHAUSTED),
      );
    });

    it('autoEndExpiredBreaks ends over-limit open breaks and rejects stale pending requests', async () => {
      const expiredBreak = {
        id: 'brk-expired',
        driverId: 'drv-1',
        shiftId: 'shift-1',
        status: 'APPROVED',
        endedAt: null,
        startedAt: new Date(Date.now() - 20 * 60000),
        requestedMinutes: 10,
        prevStatus: DriverStatus.ONLINE,
      };
      const freshBreak = {
        id: 'brk-fresh',
        driverId: 'drv-1',
        shiftId: 'shift-1',
        status: 'APPROVED',
        endedAt: null,
        startedAt: new Date(Date.now() - 2 * 60000),
        requestedMinutes: 15,
        prevStatus: DriverStatus.ONLINE,
      };
      const stalePending = { id: 'brk-stale', driverId: 'drv-1' };

      const h = makeBreaksHarness({
        openBreaks: [expiredBreak, freshBreak],
        staleBreaks: [stalePending],
      });

      const result = await h.service.autoEndExpiredBreaks();

      expect(result).toEqual({ ended: 1, rejected: 1 });
      expect(h.driversRepository.endBreak).toHaveBeenCalledTimes(1);
      expect(h.driversRepository.endBreak).toHaveBeenCalledWith(
        'brk-expired',
        expect.any(Date),
        expect.any(Number),
        true,
      );
      expect(h.driversRepository.updateStatus).toHaveBeenCalledWith(
        'drv-1',
        DriverStatus.ONLINE,
      );
      expect(h.driversRepository.rejectBreak).toHaveBeenCalledWith(
        'brk-stale',
        'system',
      );

      expect(h.eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_STATUS_CHANGED,
        expect.any(DriverStatusChangedEvent),
      );
      expect(h.eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_BREAK_DECIDED,
        expect.objectContaining<Partial<DriverBreakDecidedEvent>>({
          breakId: 'brk-expired',
          action: 'auto_ended',
        }),
      );
      expect(h.eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_BREAK_DECIDED,
        expect.objectContaining<Partial<DriverBreakDecidedEvent>>({
          breakId: 'brk-stale',
          action: 'request_expired',
        }),
      );
    });
  });

  describe('DriverShiftExecutionService', () => {
    function makeShiftHarness(overrides?: {
      status?: DriverStatus;
      tier?: string;
      rejectedDispatches?: number;
      expiredDispatches?: number;
    }) {
      const driver = {
        id: 'drv-1',
        userId: 'drv-user-1',
        status: overrides?.status ?? DriverStatus.ONLINE,
        tier: overrides?.tier ?? 'BRONZE',
      };
      const driversRepository: any = {
        findByUserId: jest.fn().mockResolvedValue(driver),
        findById: jest.fn().mockResolvedValue(driver),
        findShiftById: jest.fn().mockResolvedValue({
          id: 'shift-1',
          driverId: 'drv-1',
          status: DriverShiftStatus.ACTIVE,
        }),
        findActiveBreak: jest.fn().mockResolvedValue({ id: 'open-brk' }),
        findPendingBreak: jest.fn().mockResolvedValue({ id: 'pend-brk' }),
        cancelBreak: jest.fn().mockResolvedValue(undefined),
        countDeliveredOrdersInShift: jest.fn().mockResolvedValue(4),
        sumShiftEarnings: jest.fn().mockResolvedValue(220),
        endShiftSafely: jest.fn().mockResolvedValue({
          id: 'shift-1',
          status: DriverShiftStatus.COMPLETED,
          rejectedDispatches: overrides?.rejectedDispatches ?? 0,
          expiredDispatches: overrides?.expiredDispatches ?? 0,
        }),
        updateStatus: jest.fn().mockResolvedValue(undefined),
        updateLastLocation: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
      };

      const driverTracking: any = {
        getDriverLocation: jest.fn().mockResolvedValue({ lng: 31.2, lat: 30.0 }),
        removeDriverLocation: jest.fn().mockResolvedValue(undefined),
      };

      const driverBreaksService: any = {
        finishBreak: jest.fn().mockResolvedValue(undefined),
      };

      const eventEmit = jest.fn();

      const service = new DriverShiftExecutionService(
        driversRepository,
        {} as any,
        {} as any,
        driverTracking,
        driverBreaksService,
        { emit: eventEmit } as unknown as EventEmitter2,
      );

      return {
        service,
        driversRepository,
        driverTracking,
        driverBreaksService,
        eventEmit,
      };
    }

    it('blocks manual endShift while driver is ON_DELIVERY', async () => {
      const h = makeShiftHarness({ status: DriverStatus.ON_DELIVERY });

      await expect(h.service.endShift('drv-user-1', 'shift-1')).rejects.toThrow(
        new BadRequestException(DriverErrors.CANNOT_END_WHILE_ON_DELIVERY),
      );
      expect(h.driversRepository.endShiftSafely).not.toHaveBeenCalled();
    });

    it('defers endShiftBySystem while driver is ON_DELIVERY', async () => {
      const h = makeShiftHarness({ status: DriverStatus.ON_DELIVERY });

      const res = await h.service.endShiftBySystem('drv-1', 'shift-1');

      expect(res).toBeUndefined();
      expect(h.driversRepository.endShiftSafely).not.toHaveBeenCalled();
      expect(h.driverBreaksService.finishBreak).not.toHaveBeenCalled();
    });

    it('finalizes idle shift in endShiftBySystem, closes breaks, sets OFFLINE, and promotes tier on 0 rejected/expired', async () => {
      const h = makeShiftHarness({
        status: DriverStatus.ONLINE,
        tier: 'BRONZE',
        rejectedDispatches: 0,
        expiredDispatches: 0,
      });

      const updated = await h.service.endShiftBySystem('drv-1', 'shift-1');

      expect(updated?.status).toBe(DriverShiftStatus.COMPLETED);
      expect(h.driverBreaksService.finishBreak).toHaveBeenCalledWith(
        'open-brk',
        false,
      );
      expect(h.driversRepository.cancelBreak).toHaveBeenCalledWith('pend-brk');
      expect(h.driversRepository.updateStatus).toHaveBeenCalledWith(
        'drv-1',
        DriverStatus.OFFLINE,
      );
      expect(h.driversRepository.updateLastLocation).toHaveBeenCalledWith(
        'drv-1',
        31.2,
        30.0,
      );
      expect(h.driverTracking.removeDriverLocation).toHaveBeenCalledWith('drv-1');
      expect(h.driversRepository.update).toHaveBeenCalledWith('drv-1', {
        tier: 'SILVER',
      });
      expect(h.eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_STATUS_CHANGED,
        expect.objectContaining({
          driverId: 'drv-1',
          oldStatus: DriverStatus.ONLINE,
          newStatus: DriverStatus.OFFLINE,
          reason: 'Shift ended by system.',
        }),
      );
    });
  });

  describe('DriverAssistMatchingService & DriverAssistService offer flow', () => {
    it('removes declining driver from Redis offer without assigning', async () => {
      const future = new Date(Date.now() + 60_000).toISOString();
      const prisma: any = {
        driver: {
          findUnique: jest.fn().mockResolvedValue({ id: 'drv-2' }),
        },
        driverAssistRequest: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-1',
            status: DriverAssistRequestStatus.APPROVED,
          }),
        },
      };
      const redis: any = {
        get: jest.fn().mockResolvedValue(
          JSON.stringify({
            driverIds: ['drv-2', 'drv-3'],
            orderId: 'order-1',
            expiresAt: future,
          }),
        ),
        set: jest.fn().mockResolvedValue(undefined),
        del: jest.fn().mockResolvedValue(undefined),
      };

      const matching = new DriverAssistMatchingService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
        redis,
      );
      const assist = new DriverAssistService(
        prisma,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn() } as any,
        matching,
        {
          cancelOrder: jest.fn(),
          recomputeGroupedOrderStatusAfterCancel: jest.fn(),
          cancelDeliveryGroupAfterAssistFailure: jest.fn(),
        },
      );
      const assignSpy = jest.spyOn(assist, 'assignDriver');

      const res = await assist.respondToAssistOffer(driverActor, 'req-1', false);

      expect(res).toEqual({ declined: true });
      expect(redis.set).toHaveBeenCalledWith(
        'assist:offer:req-1',
        JSON.stringify({
          driverIds: ['drv-3'],
          orderId: 'order-1',
          expiresAt: future,
        }),
        15,
      );
      expect(assignSpy).not.toHaveBeenCalled();
    });

    it('delegates accepted offer to CAS assignDriver and throws ConflictException when CAS loses race', async () => {
      const future = new Date(Date.now() + 60_000).toISOString();
      const tx: any = {
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            primaryDriverId: 'drv-primary',
            assistDriverId: null,
            status: DeliveryGroupStatus.READY_FOR_PICKUP,
            deliveryFee: 30,
            distanceKm: 2,
            orderId: 'order-1',
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        },
        order: {
          findFirst: jest.fn().mockResolvedValue(null),
        },
        driverShift: {
          findFirst: jest.fn().mockResolvedValue({ id: 'shift-2' }),
        },
      };
      // Also verify first findFirst is orderDeliveryGroup busy check
      tx.orderDeliveryGroup.findFirst = jest.fn().mockResolvedValue(null);

      const fullRequest = {
        id: 'req-1',
        status: DriverAssistRequestStatus.APPROVED,
        orderId: 'order-1',
        deliveryGroupId: 'grp-1',
      };
      const prisma: any = {
        $transaction: jest
          .fn()
          .mockImplementation((fn: any) => Promise.resolve(fn(tx))),
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-2',
            userId: 'drv-user-2',
            status: DriverStatus.ONLINE,
            isApproved: true,
            vehicleType: 'MOTORCYCLE',
            hasUnpaidCommission: false,
            deletedAt: null,
            tier: 'GOLD',
          }),
        },
        driverAssistRequest: {
          findUnique: jest.fn().mockResolvedValue(fullRequest),
        },
      };
      const redis: any = {
        get: jest.fn().mockResolvedValue(
          JSON.stringify({
            driverIds: ['drv-2'],
            orderId: 'order-1',
            expiresAt: future,
          }),
        ),
        set: jest.fn(),
        del: jest.fn(),
      };

      const matching = new DriverAssistMatchingService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
        redis,
      );
      const assist = new DriverAssistService(
        prisma,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn() } as any,
        matching,
        {
          cancelOrder: jest.fn(),
          recomputeGroupedOrderStatusAfterCancel: jest.fn(),
          cancelDeliveryGroupAfterAssistFailure: jest.fn(),
        },
      );

      await expect(
        assist.respondToAssistOffer(driverActor, 'req-1', true),
      ).rejects.toThrow(
        new ConflictException(DriverErrors.ASSIST_DRIVER_ALREADY_ASSIGNED),
      );
      expect(tx.orderDeliveryGroup.updateMany).toHaveBeenCalledWith({
        where: { id: 'grp-1', assistDriverId: null },
        data: expect.objectContaining({
          assistDriverId: 'drv-2',
          assistDriverShiftId: 'shift-2',
          assignedByUserId: 'drv-user-2',
        }),
      });
    });

    it('emits DRIVER_ASSIST_OFFERED with resolved userIds instead of inline sockets/notifications', async () => {
      const eventEmit = jest.fn();
      const prisma: any = {
        driverAssistRequest: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-offer',
            status: DriverAssistRequestStatus.APPROVED,
            orderId: 'order-1',
            deliveryGroupId: 'grp-1',
          }),
        },
        driver: {
          findMany: jest
            .fn()
            .mockResolvedValue([{ userId: 'u-cand-1' }, { userId: 'u-cand-2' }]),
        },
      };
      const redis: any = {
        set: jest.fn().mockResolvedValue(undefined),
      };
      const matching = new DriverAssistMatchingService(
        prisma,
        { emit: eventEmit } as any,
        {} as any,
        {} as any,
        redis,
      );
      jest
        .spyOn(matching as any, 'findNearestEligibleAssistDrivers')
        .mockResolvedValue(['drv-1', 'drv-2']);

      const result = await matching.offerAssistToNearest(
        'req-offer',
        driverActor,
        5,
      );

      expect(result.offered).toEqual(['drv-1', 'drv-2']);
      expect(eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_ASSIST_OFFERED,
        expect.objectContaining<Partial<DriverAssistOfferedEvent>>({
          requestId: 'req-offer',
          orderId: 'order-1',
          targetUserIds: ['u-cand-1', 'u-cand-2'],
        }),
      );
    });

    it('emits DRIVER_ASSIST_TIMED_OUT when autoDeclineExpiredAssistDecisions expires group assist', async () => {
      const eventEmit = jest.fn();
      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            customerId: 'cust-1',
            orderNumber: 'ORD-SV',
          }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-sv-exp',
              orderId: 'order-sv-exp',
              primaryDriverId: 'drv-p',
              assistDriverId: 'drv-a',
              assistFee: 25,
            },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        customer: {
          findUnique: jest.fn().mockResolvedValue({ userId: 'cust-user-1' }),
        },
        driver: {
          findUnique: jest
            .fn()
            .mockImplementation(({ where }: any) =>
              Promise.resolve({
                userId: where.id === 'drv-p' ? 'u-p' : 'u-a',
              }),
            ),
        },
        driverAssistRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      const ordersState = {
        cancelOrder: jest.fn().mockResolvedValue(undefined),
        recomputeGroupedOrderStatusAfterCancel: jest.fn(),
        cancelDeliveryGroupAfterAssistFailure: jest
          .fn()
          .mockResolvedValue(undefined),
      };
      const assist = new DriverAssistService(
        prisma,
        { emit: eventEmit } as any,
        {
          getSettings: jest
            .fn()
            .mockResolvedValue({ assistDecisionTimeoutSecs: 120 }),
        } as any,
        { clearOffer: jest.fn() } as any,
        ordersState,
      );

      await assist.autoDeclineExpiredAssistDecisions();

      expect(prisma.orderDeliveryGroup.updateMany).toHaveBeenCalledWith({
        where: { id: 'grp-sv-exp', assistCustomerApproved: null },
        data: expect.objectContaining({
          assistDriverId: null,
          assistCustomerApproved: false,
        }),
      });
      expect(
        ordersState.cancelDeliveryGroupAfterAssistFailure,
      ).toHaveBeenCalledWith(
        'order-sv-exp',
        'grp-sv-exp',
        'Assist decision timed out',
        ['drv-p', 'drv-a'],
      );
      expect(eventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_ASSIST_TIMED_OUT,
        new DriverAssistTimedOutEvent(
          'order-sv-exp',
          'grp-sv-exp',
          'cust-user-1',
          'u-p',
          'u-a',
        ),
      );

      // If the customer already decided concurrently, CAS updateMany returns count: 0 -> skip cleanly
      ordersState.cancelDeliveryGroupAfterAssistFailure.mockClear();
      eventEmit.mockClear();
      prisma.orderDeliveryGroup.updateMany.mockResolvedValueOnce({ count: 0 });
      await assist.autoDeclineExpiredAssistDecisions();
      expect(
        ordersState.cancelDeliveryGroupAfterAssistFailure,
      ).not.toHaveBeenCalled();
      expect(eventEmit).not.toHaveBeenCalled();
    });
  });

  describe('Event-driven DriverListener & DriverAssistListener', () => {
    it('disconnects driver socket when DriverListener handles SUSPENDED status change', async () => {
      const socketService: any = {
        disconnectUser: jest.fn().mockResolvedValue(undefined),
        emitToUser: jest.fn(),
      };
      const eventsQueue: any = {
        add: jest.fn().mockResolvedValue(undefined),
      };
      const listener = new DriverListener(socketService, eventsQueue);

      await listener.handleStatusChanged(
        new DriverStatusChangedEvent(
          'drv-1',
          'drv-user-suspended',
          DriverStatus.ONLINE,
          DriverStatus.SUSPENDED,
          'UNPAID_COMMISSION',
        ),
      );
      expect(socketService.disconnectUser).toHaveBeenCalledTimes(1);
      expect(socketService.disconnectUser).toHaveBeenCalledWith(
        'drv-user-suspended',
      );

      await listener.handleStatusChanged(
        new DriverStatusChangedEvent(
          'drv-1',
          'drv-user-online',
          DriverStatus.ONLINE,
          DriverStatus.ONLINE,
          'SETTLEMENT_REQUIRED',
        ),
      );
      expect(socketService.disconnectUser).toHaveBeenCalledTimes(1);
    });

    it('dispatches assist sockets and EVENT_JOBS.NOTIFY jobs in DriverAssistListener', async () => {
      const socketService: any = {
        emitToUser: jest.fn().mockResolvedValue(undefined),
      };
      const eventsQueue: any = {
        add: jest.fn().mockResolvedValue(undefined),
      };
      const listener = new DriverAssistListener(eventsQueue, socketService);

      await listener.handleAssistOffered(
        new DriverAssistOfferedEvent(
          'req-1',
          'order-1',
          ['u-cand-1', 'u-cand-2'],
          '2026-11-14T10:00:00.000Z',
        ),
      );
      expect(socketService.emitToUser).toHaveBeenCalledWith(
        'u-cand-1',
        'assist.offer',
        {
          requestId: 'req-1',
          orderId: 'order-1',
          expiresAt: '2026-11-14T10:00:00.000Z',
        },
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'u-cand-1',
            type: NotificationType.ORDER_UPDATE,
            data: {
              requestId: 'req-1',
              orderId: 'order-1',
              action: 'assist_offer',
            },
          }),
        }),
      );

      socketService.emitToUser.mockClear();
      eventsQueue.add.mockClear();

      await listener.handleAssistAssigned(
        new DriverAssistAssignedEvent(
          'req-1',
          'order-1',
          'ORD-100',
          'grp-1',
          35,
          'cust-user-1',
          'primary-user-1',
          'assist-user-1',
        ),
      );
      expect(socketService.emitToUser).toHaveBeenCalledWith(
        'cust-user-1',
        'order.assist.proposed',
        { orderId: 'order-1', deliveryGroupId: 'grp-1', assistFee: 35 },
      );
      expect(socketService.emitToUser).toHaveBeenCalledWith(
        'assist-user-1',
        'order.assigned',
        expect.objectContaining({
          role: 'ASSISTING',
          orderId: 'order-1',
          deliveryGroupId: 'grp-1',
        }),
      );
      expect(eventsQueue.add).toHaveBeenCalledTimes(3);

      eventsQueue.add.mockClear();
      await listener.handleCustomerDecided(
        new DriverAssistCustomerDecidedEvent(
          'order-1',
          null,
          true,
          35,
          'primary-user-1',
          'assist-user-1',
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledTimes(2);

      eventsQueue.add.mockClear();
      await listener.handleAssistTimedOut(
        new DriverAssistTimedOutEvent(
          'order-1',
          'grp-1',
          'cust-user-1',
          'primary-user-1',
          'assist-user-1',
        ),
      );
      expect(eventsQueue.add).toHaveBeenCalledTimes(3);
    });
  });
});
