import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DriverShiftStatus,
  DriverStatus,
  Role,
  SwapRequestStatus,
} from '@prisma/client';
import type { Queue } from 'bullmq';
import { DriverErrors } from 'src/common/constants/response.constants';
import {
  DriverStatusChangedEvent,
  ShiftDisabledEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import type { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import { NotificationListener } from 'src/common/listeners/notification.listener';
import type { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import type { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { EVENT_JOBS } from 'src/infrastructure/queue/queues.constants';
import { DriverShiftsService } from './driver-shifts.service';

interface MockNotifyJobPayload {
  dto: {
    userId: string;
    title: string;
    titleAr: string;
    body: string;
    bodyAr: string;
    data: Record<string, unknown>;
  };
}

describe('DriverShiftsService.adminRemoveDriverBulk', () => {
  const adminActor: JwtAccessPayload = {
    sub: 'admin-user-1',
    sid: 'sid-admin',
    role: Role.ADMIN,
    verified: true,
  };

  const managerActor: JwtAccessPayload = {
    sub: 'mgr-user-1',
    sid: 'sid-mgr',
    role: Role.DRIVER_MANAGER,
    verified: true,
  };

  function createService(overrides?: {
    driver?: { id: string; userId: string } | null;
    txDriver?: { id: string; userId: string; status: DriverStatus } | null;
    pools?: { id: string }[];
    shifts?: {
      id: string;
      shiftPoolId: string | null;
      status: DriverShiftStatus;
    }[];
    manager?: { id: string; manageAllDrivers: boolean } | null;
    assignment?: { id: string } | null;
  }) {
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      shiftPool: {
        findMany: jest
          .fn()
          .mockResolvedValue(overrides?.pools ?? [{ id: 'p1' }, { id: 'p2' }]),
      },
      driver: {
        findUnique: jest.fn().mockResolvedValue(
          overrides && 'txDriver' in overrides
            ? overrides.txDriver
            : {
                id: 'drv-1',
                userId: 'u-drv-1',
                status: DriverStatus.OFFLINE,
              },
        ),
        update: jest.fn().mockResolvedValue({}),
      },
      driverShift: {
        findMany: jest.fn().mockResolvedValue(overrides?.shifts ?? []),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      shiftSwapRequest: {
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
    };

    const prisma = {
      driver: {
        findUnique: jest
          .fn()
          .mockResolvedValue(
            overrides && 'driver' in overrides
              ? overrides.driver
              : { id: 'drv-1', userId: 'u-drv-1' },
          ),
      },
      driverManager: {
        findUnique: jest.fn().mockResolvedValue(overrides?.manager ?? null),
      },
      driverManagerAssignment: {
        findUnique: jest.fn().mockResolvedValue(overrides?.assignment ?? null),
      },
      $transaction: jest.fn((fn: (client: typeof tx) => Promise<unknown>) =>
        fn(tx),
      ),
    };

    const eventEmitter = {
      emit: jest.fn<boolean, [string, unknown]>(),
    };

    const service = new DriverShiftsService(
      prisma as unknown as PrismaService,
      { getSettings: jest.fn() } as unknown as PlatformSettingsService,
      eventEmitter as unknown as EventEmitter2,
    );
    const promoteSpy = jest
      .spyOn(service, 'promoteFromWaitlist')
      .mockResolvedValue(undefined);

    return { service, prisma, tx, eventEmitter, promoteSpy };
  }

  it('removes scheduled and cancelled shifts, cancels pending swaps, emits one bulk ShiftDisabledEvent, and promotes waitlists', async () => {
    const { service, tx, eventEmitter, promoteSpy } = createService({
      pools: [{ id: 'p1' }, { id: 'p2' }, { id: 'p3' }],
      shifts: [
        { id: 's1', shiftPoolId: 'p1', status: DriverShiftStatus.SCHEDULED },
        { id: 's2', shiftPoolId: 'p2', status: DriverShiftStatus.CANCELLED },
        { id: 's3', shiftPoolId: 'p3', status: DriverShiftStatus.COMPLETED },
      ],
    });

    const res = await service.adminRemoveDriverBulk(
      { driverId: 'drv-1', shiftPoolIds: ['p1', 'p2', 'p3'] },
      adminActor,
    );

    expect(res).toEqual({ success: true, removed: 2, skippedHistorical: 1 });
    expect(tx.shiftSwapRequest.updateMany).toHaveBeenCalledWith({
      where: {
        driverShiftId: { in: ['s1', 's2'] },
        status: SwapRequestStatus.PENDING,
      },
      data: { status: SwapRequestStatus.CANCELLED },
    });
    expect(tx.driverShift.deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['s1', 's2'] } },
    });
    expect(tx.driver.update).not.toHaveBeenCalled();
    expect(eventEmitter.emit).toHaveBeenCalledTimes(1);
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      EVENTS.SHIFT_DISABLED,
      expect.objectContaining<Partial<ShiftDisabledEvent>>({
        driverUserId: 'u-drv-1',
        shiftId: 's1',
        reason: 'admin',
        count: 2,
      }),
    );
    expect(promoteSpy).toHaveBeenCalledTimes(2);
    expect(promoteSpy).toHaveBeenCalledWith('p1');
    expect(promoteSpy).toHaveBeenCalledWith('p2');
  });

  it('sets driver OFFLINE and emits DRIVER_STATUS_CHANGED when removing an ACTIVE shift and driver is ONLINE', async () => {
    const { service, tx, eventEmitter, promoteSpy } = createService({
      pools: [{ id: 'p1' }, { id: 'p2' }],
      txDriver: { id: 'drv-1', userId: 'u-drv-1', status: DriverStatus.ONLINE },
      shifts: [
        { id: 's1', shiftPoolId: 'p1', status: DriverShiftStatus.ACTIVE },
        { id: 's2', shiftPoolId: 'p2', status: DriverShiftStatus.SCHEDULED },
      ],
    });

    const res = await service.adminRemoveDriverBulk(
      { driverId: 'drv-1', shiftPoolIds: ['p1', 'p2'] },
      adminActor,
    );

    expect(res).toEqual({ success: true, removed: 2, skippedHistorical: 0 });
    expect(tx.driver.update).toHaveBeenCalledWith({
      where: { id: 'drv-1' },
      data: { status: DriverStatus.OFFLINE },
    });
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      EVENTS.DRIVER_STATUS_CHANGED,
      expect.objectContaining<Partial<DriverStatusChangedEvent>>({
        driverId: 'drv-1',
        driverUserId: 'u-drv-1',
        oldStatus: DriverStatus.ONLINE,
        newStatus: DriverStatus.OFFLINE,
      }),
    );
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      EVENTS.SHIFT_DISABLED,
      expect.any(ShiftDisabledEvent),
    );
    expect(promoteSpy).toHaveBeenCalledTimes(2);
  });

  it('rejects atomically without deleting any shift when driver is ON_DELIVERY on an ACTIVE shift', async () => {
    const { service, tx, eventEmitter, promoteSpy } = createService({
      pools: [{ id: 'p1' }, { id: 'p2' }],
      txDriver: {
        id: 'drv-1',
        userId: 'u-drv-1',
        status: DriverStatus.ON_DELIVERY,
      },
      shifts: [
        { id: 's1', shiftPoolId: 'p1', status: DriverShiftStatus.ACTIVE },
        { id: 's2', shiftPoolId: 'p2', status: DriverShiftStatus.SCHEDULED },
      ],
    });

    await expect(
      service.adminRemoveDriverBulk(
        { driverId: 'drv-1', shiftPoolIds: ['p1', 'p2'] },
        adminActor,
      ),
    ).rejects.toThrow(
      new BadRequestException(DriverErrors.CANNOT_END_WHILE_ON_DELIVERY),
    );

    expect(tx.driver.update).not.toHaveBeenCalled();
    expect(tx.shiftSwapRequest.updateMany).not.toHaveBeenCalled();
    expect(tx.driverShift.deleteMany).not.toHaveBeenCalled();
    expect(eventEmitter.emit).not.toHaveBeenCalled();
    expect(promoteSpy).not.toHaveBeenCalled();
  });

  it('preserves historical-only shifts without emitting notifications or waitlist promotion', async () => {
    const { service, tx, eventEmitter, promoteSpy } = createService({
      pools: [{ id: 'p1' }, { id: 'p2' }],
      shifts: [
        { id: 's1', shiftPoolId: 'p1', status: DriverShiftStatus.COMPLETED },
        { id: 's2', shiftPoolId: 'p2', status: DriverShiftStatus.MISSED },
      ],
    });

    const res = await service.adminRemoveDriverBulk(
      { driverId: 'drv-1', shiftPoolIds: ['p1', 'p2'] },
      adminActor,
    );

    expect(res).toEqual({ success: true, removed: 0, skippedHistorical: 2 });
    expect(tx.driverShift.deleteMany).not.toHaveBeenCalled();
    expect(eventEmitter.emit).not.toHaveBeenCalled();
    expect(promoteSpy).not.toHaveBeenCalled();
  });

  it('rejects duplicate shiftPoolIds', async () => {
    const { service, prisma } = createService();

    await expect(
      service.adminRemoveDriverBulk(
        { driverId: 'drv-1', shiftPoolIds: ['p1', 'p1'] },
        adminActor,
      ),
    ).rejects.toThrow(
      new BadRequestException(DriverErrors.SHIFT_POOL_IDS_MUST_BE_UNIQUE),
    );

    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('throws NotFoundException when driver does not exist', async () => {
    const { service } = createService({ driver: null });

    await expect(
      service.adminRemoveDriverBulk(
        { driverId: 'missing-drv', shiftPoolIds: ['p1'] },
        adminActor,
      ),
    ).rejects.toThrow(new NotFoundException(DriverErrors.PROFILE_NOT_FOUND));
  });

  it('throws NotFoundException when one or more shift pools are missing', async () => {
    const { service } = createService({ pools: [{ id: 'p1' }] });

    await expect(
      service.adminRemoveDriverBulk(
        { driverId: 'drv-1', shiftPoolIds: ['p1', 'p2'] },
        adminActor,
      ),
    ).rejects.toThrow(new NotFoundException(DriverErrors.SHIFT_POOL_MISSING));
  });

  it('enforces DRIVER_MANAGER scope for unassigned drivers', async () => {
    const { service } = createService({
      manager: { id: 'mgr-1', manageAllDrivers: false },
      assignment: null,
    });

    await expect(
      service.adminRemoveDriverBulk(
        { driverId: 'drv-1', shiftPoolIds: ['p1'] },
        managerActor,
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('allows DRIVER_MANAGER when assigned to the driver', async () => {
    const { service } = createService({
      manager: { id: 'mgr-1', manageAllDrivers: false },
      assignment: { id: 'assign-1' },
      pools: [{ id: 'p1' }],
      shifts: [
        { id: 's1', shiftPoolId: 'p1', status: DriverShiftStatus.SCHEDULED },
      ],
    });

    const res = await service.adminRemoveDriverBulk(
      { driverId: 'drv-1', shiftPoolIds: ['p1'] },
      managerActor,
    );

    expect(res).toEqual({ success: true, removed: 1, skippedHistorical: 0 });
  });
});

describe('NotificationListener.handleShiftDisabled', () => {
  it('enqueues bulk notification copy when count > 1', async () => {
    const addMock = jest
      .fn<Promise<unknown>, [string, MockNotifyJobPayload]>()
      .mockResolvedValue({});
    const listener = new NotificationListener({
      add: addMock,
    } as unknown as Queue);

    await listener.handleShiftDisabled(
      new ShiftDisabledEvent('u-drv-1', 's1', 'admin', 5),
    );

    expect(addMock).toHaveBeenCalledTimes(1);
    const [jobName, payload] = addMock.mock.calls[0];
    expect(jobName).toBe(EVENT_JOBS.NOTIFY);
    expect(payload.dto.userId).toBe('u-drv-1');
    expect(payload.dto.title).toBe('Shifts Removed');
    expect(payload.dto.body).toContain(
      '5 shifts assigned to you were removed by admin.',
    );
    expect(payload.dto.bodyAr).toContain('من قبل الإدارة');
    expect(payload.dto.data).toEqual({
      shiftId: 's1',
      type: 'SHIFT_REMOVED',
      count: 5,
    });
  });

  it('keeps singular notification copy when count is 1 and ignores self reason', async () => {
    const addMock = jest
      .fn<Promise<unknown>, [string, MockNotifyJobPayload]>()
      .mockResolvedValue({});
    const listener = new NotificationListener({
      add: addMock,
    } as unknown as Queue);

    await listener.handleShiftDisabled(
      new ShiftDisabledEvent('u-drv-1', 's1', 'self', 3),
    );
    expect(addMock).not.toHaveBeenCalled();

    await listener.handleShiftDisabled(
      new ShiftDisabledEvent('u-drv-1', 's1', 'admin', 1),
    );
    expect(addMock).toHaveBeenCalledTimes(1);
    const [jobName, payload] = addMock.mock.calls[0];
    expect(jobName).toBe(EVENT_JOBS.NOTIFY);
    expect(payload.dto.title).toBe('Shift Removed');
    expect(payload.dto.body).toBe(
      'A shift assigned to you was removed by admin. Open the app to see your updated schedule.',
    );
    expect(payload.dto.bodyAr).toContain('من قبل الإدارة');
    expect(payload.dto.data).toEqual({
      shiftId: 's1',
      type: 'SHIFT_REMOVED',
    });
  });
});
