import { BadRequestException, ForbiddenException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DispatchStatus,
  OrderStatus,
  OrderType,
  Role,
  VehicleType,
} from '@prisma/client';
import { OrderSearchService } from './order-search.service';
import {
  DriverSearchPhase,
  SearchTerminalReason,
} from '../dispatch/dispatch-search.types';
import { DispatchSearchTracker } from '../dispatch/dispatch-search-tracker.service';
import { OrderCancellationService } from './transitions/order-cancellation.service';
import {
  CustomerErrors,
  OrderErrors,
} from '../../common/constants/response.constants';
import { EVENTS } from '../../common/events/event-names';

const CUSTOMER_ACTOR = {
  sub: 'user-cust-1',
  role: Role.CUSTOMER,
} as any;

const BASE_SETTINGS = {
  driverSearchRadiusKm: 3,
  driverSearchRadiusStepKm: 3,
  driverSearchRadiusMaxKm: 15,
  driverSearchMaxAttempts: 5,
  driverAcceptTimeoutSecs: 30,
  driverShiftsEnabled: true,
  allowBicycle: true,
  allowMotorcycle: true,
  allowCar: true,
  allowMinibus: true,
  allowTukTuk: true,
  allowMotorTricycle: false,
  allowQuarterTruck: false,
  allowHalfTruck: false,
  maxKmForBicycle: 5,
  maxActiveOrdersPerCustomer: 3,
};

describe('OrderSearchService & Custom Delivery Matching Architecture', () => {
  it('getNearbyDriversPreview uses all active RIDE vehicle types when unspecified and strips driver PII', async () => {
    const geoSearch = {
      findNearbyDrivers: jest.fn().mockResolvedValue([
        {
          id: 'drv-1',
          userId: 'u-drv-1',
          vehicleType: 'CAR',
          distanceKm: 1.234,
          activeShiftId: null,
        },
        {
          id: 'drv-stale',
          userId: 'u-drv-2',
          vehicleType: 'CAR',
          distanceKm: 2.0,
          activeShiftId: null,
        },
      ]),
    };
    const locationRepo = {
      getLiveDriverLocations: jest.fn().mockResolvedValue(
        new Map([
          ['drv-1', { lng: 31.235, lat: 30.044, isFresh: true }],
          ['drv-stale', { lng: 31.24, lat: 30.05, isFresh: false }],
        ]),
      ),
    };
    const service = new OrderSearchService(
      {} as any,
      { getSettings: jest.fn().mockResolvedValue(BASE_SETTINGS) } as any,
      geoSearch as any,
      {} as any,
      locationRepo as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );

    const res = await service.getNearbyDriversPreview({
      lat: 30.044,
      lng: 31.235,
      type: OrderType.RIDE,
    });

    expect(geoSearch.findNearbyDrivers).toHaveBeenCalledWith(
      31.235,
      30.044,
      3,
      [],
      ['MOTORCYCLE', 'CAR', 'MINIBUS', 'TUK_TUK'],
      false,
      null,
    );
    expect(res.count).toBe(1);
    expect(res.drivers[0]).toEqual({
      latitude: 30.044,
      longitude: 31.235,
      vehicleType: VehicleType.CAR,
      distanceKm: 1.23,
    });
    expect((res.drivers[0] as any).id).toBeUndefined();
    expect((res.drivers[0] as any).userId).toBeUndefined();
  });

  it('getOrderSearchStatus blocks unauthorized users', async () => {
    const prisma = {
      order: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'ord-1',
          orderNumber: 'OTL-1',
          type: OrderType.CUSTOM_DELIVERY,
          status: OrderStatus.LOOKING_FOR_DRIVER,
          revision: 1,
          customer: { id: 'c-other', userId: 'user-other' },
          deliveryGroups: [],
        }),
      },
    };
    const service = new OrderSearchService(
      prisma as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
      {} as any,
      {} as any,
      {} as any,
    );

    await expect(
      service.getOrderSearchStatus(CUSTOMER_ACTOR, 'ord-1'),
    ).rejects.toThrow(ForbiddenException);
  });

  it('getOrderSearchStatus reconstructs state from DB/dispatch when Redis snapshot expired and computes real driver distance without fake ETA', async () => {
    const prisma = {
      order: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'ord-2',
          orderNumber: 'OTL-2',
          type: OrderType.CUSTOM_DELIVERY,
          status: OrderStatus.DRIVER_ASSIGNED,
          revision: 3,
          distanceKm: 4.5,
          requestedVehicleType: VehicleType.MOTORCYCLE,
          cancelReason: null,
          cancelledByRole: null,
          cancelledByUserId: null,
          createdAt: new Date('2026-11-21T01:00:00Z'),
          updatedAt: new Date('2026-11-21T01:02:00Z'),
          customer: { id: 'cust-1', userId: 'user-cust-1' },
          deliveryGroups: [
            {
              id: 'grp-2',
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              primaryDriverId: 'drv-9',
              sequence: 1,
            },
          ],
        }),
      },
    };
    const driverTracking = {
      getDriverLocationWithState: jest
        .fn()
        .mockResolvedValue({ lng: 31.22, lat: 30.03, isLive: true }),
    };
    const locationRepo = {
      getOrderLocationContext: jest
        .fn()
        .mockResolvedValue({ lng: 31.23, lat: 30.04, deliveryLng: 31.26, deliveryLat: 30.06 }),
      getDistanceKm: jest.fn().mockResolvedValue(1.472),
    };
    const service = new OrderSearchService(
      prisma as any,
      { getSettings: jest.fn().mockResolvedValue(BASE_SETTINGS) } as any,
      {} as any,
      driverTracking as any,
      locationRepo as any,
      { getSearchSnapshot: jest.fn().mockResolvedValue(null) } as any,
      {} as any,
      {} as any,
      { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
      {} as any,
      {} as any,
      {} as any,
    );

    const status = await service.getOrderSearchStatus(CUSTOMER_ACTOR, 'ord-2');
    expect(status.phase).toBe(DriverSearchPhase.DRIVER_FOUND);
    expect(status.driverLocation).toEqual({
      latitude: 30.03,
      longitude: 31.22,
    });
    expect(status.driverDistanceKm).toBe(1.47);
    expect(status.driverEtaMinutes).toBeNull();
    expect(status.canRetry).toBe(false);
  });

  it('retryCustomOrderSearch returns alreadyAssigned when driver accepted concurrently', async () => {
    const tx = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'ord-race',
          orderNumber: 'OTL-RACE',
          type: OrderType.CUSTOM_DELIVERY,
          status: OrderStatus.DRIVER_ASSIGNED,
          revision: 4,
          coinsUsed: 0,
          customerId: 'cust-1',
          customer: { userId: 'user-cust-1' },
          deliveryGroups: [
            {
              id: 'grp-race',
              status: DeliveryGroupStatus.DRIVER_ASSIGNED,
              primaryDriverId: 'drv-1',
            },
          ],
        }),
      },
    };
    const fullOrder = {
      id: 'ord-race',
      orderNumber: 'OTL-RACE',
      type: OrderType.CUSTOM_DELIVERY,
      status: OrderStatus.DRIVER_ASSIGNED,
      revision: 4,
      distanceKm: 2,
      createdAt: new Date('2026-11-21T01:00:00Z'),
      updatedAt: new Date('2026-11-21T01:01:00Z'),
      customer: { id: 'cust-1', userId: 'user-cust-1' },
      deliveryGroups: [
        {
          id: 'grp-race',
          status: DeliveryGroupStatus.DRIVER_ASSIGNED,
          primaryDriverId: 'drv-1',
          sequence: 1,
        },
      ],
    };
    const service = new OrderSearchService(
      {
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
        order: { findUnique: jest.fn().mockResolvedValue(fullOrder) },
      } as any,
      { getSettings: jest.fn().mockResolvedValue(BASE_SETTINGS) } as any,
      {} as any,
      { getDriverLocationWithState: jest.fn().mockResolvedValue(null) } as any,
      { getOrderLocationContext: jest.fn().mockResolvedValue(null) } as any,
      { getSearchSnapshot: jest.fn().mockResolvedValue(null) } as any,
      { findById: jest.fn().mockResolvedValue(fullOrder) } as any,
      { projectOrderForRole: jest.fn().mockResolvedValue(fullOrder) } as any,
      { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
      {} as any,
      {} as any,
      {} as any,
    );

    const res = await service.retryCustomOrderSearch(CUSTOMER_ACTOR, 'ord-race');
    expect(res.retried).toBe(false);
    expect(res.alreadyAssigned).toBe(true);
    expect(res.alreadySearching).toBe(false);
  });

  it('retryCustomOrderSearch atomically re-deducts refunded coins, deletes REFUNDED ledger row, clears dispatch state, and re-enqueues dispatch', async () => {
    const deletedLedgerIds: string[] = [];
    const decrementAmounts: number[] = [];
    const tx: any = {
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([]) // SELECT orders FOR UPDATE
        .mockResolvedValueOnce([{ id: 'cust-1', coinBalance: 80 }]), // SELECT customers FOR UPDATE
      order: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'ord-retry',
          orderNumber: 'OTL-RETRY',
          type: OrderType.CUSTOM_DELIVERY,
          status: OrderStatus.CANCELLED,
          revision: 2,
          coinsUsed: 50,
          customerId: 'cust-1',
          customer: { userId: 'user-cust-1' },
          deliveryGroups: [
            {
              id: 'grp-retry',
              status: DeliveryGroupStatus.CANCELLED,
              primaryDriverId: null,
            },
          ],
        }),
        count: jest.fn().mockResolvedValue(0),
        update: jest.fn().mockResolvedValue({ revision: 3 }),
      },
      customerCoinTransaction: {
        findUnique: jest.fn().mockResolvedValue({ id: 'coin-ref-1', amount: 50 }),
        delete: jest.fn().mockImplementation(({ where }) => {
          deletedLedgerIds.push(where.id);
          return Promise.resolve({});
        }),
      },
      customer: {
        update: jest.fn().mockImplementation(({ data }) => {
          decrementAmounts.push(data.coinBalance.decrement);
          return Promise.resolve({});
        }),
      },
      orderDeliveryGroup: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      orderStatusEvent: { create: jest.fn().mockResolvedValue({}) },
    };

    const dispatchRepo = {
      clearForRetry: jest.fn().mockResolvedValue(undefined),
      getSearchSnapshot: jest.fn().mockResolvedValue(null),
      readDispatchState: jest
        .fn()
        .mockResolvedValue({ attempt: 1, excludeDriverIds: [] }),
      getActiveClaim: jest.fn().mockResolvedValue(null),
    };
    const searchTracker = { publishPhase: jest.fn().mockResolvedValue(null) };
    const emitter = { emit: jest.fn() };
    const outbox = { record: jest.fn().mockResolvedValue({}) };
    const fullOrder = {
      id: 'ord-retry',
      orderNumber: 'OTL-RETRY',
      type: OrderType.CUSTOM_DELIVERY,
      status: OrderStatus.LOOKING_FOR_DRIVER,
      revision: 3,
      distanceKm: 3,
      createdAt: new Date(),
      updatedAt: new Date(),
      customer: { id: 'cust-1', userId: 'user-cust-1' },
      deliveryGroups: [
        {
          id: 'grp-retry',
          status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
          primaryDriverId: null,
          sequence: 1,
        },
      ],
    };
    const prisma: any = {
      $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
      order: { findUnique: jest.fn().mockResolvedValue(fullOrder) },
      orderDispatch: { findMany: jest.fn().mockResolvedValue([]) },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-cust-1',
          name: 'Ali',
          role: Role.CUSTOMER,
          avatar: null,
        }),
      },
    };

    const service = new OrderSearchService(
      prisma,
      { getSettings: jest.fn().mockResolvedValue(BASE_SETTINGS) } as any,
      { findNearbyDrivers: jest.fn().mockResolvedValue([]) } as any,
      {} as any,
      { getOrderLocationContext: jest.fn().mockResolvedValue(null) } as any,
      dispatchRepo as any,
      { findById: jest.fn().mockResolvedValue(fullOrder) } as any,
      { projectOrderForRole: jest.fn().mockResolvedValue(fullOrder) } as any,
      { canManageOrders: jest.fn().mockResolvedValue(false) } as any,
      {
        validateActiveOrderLimit: jest
          .fn()
          .mockResolvedValue({ maxActive: 3, requirePriorDelivery: false }),
      } as any,
      outbox as any,
      emitter as any,
      searchTracker as any,
    );

    const res = await service.retryCustomOrderSearch(
      CUSTOMER_ACTOR,
      'ord-retry',
    );
    expect(res.retried).toBe(true);
    expect(decrementAmounts).toEqual([50]);
    expect(deletedLedgerIds).toEqual(['coin-ref-1']);
    expect(dispatchRepo.clearForRetry).toHaveBeenCalledWith('ord-retry', [
      'ord-retry',
      'grp-retry',
    ]);
    expect(emitter.emit).toHaveBeenCalledWith(
      EVENTS.ORDER_STATUS_CHANGED,
      expect.objectContaining({
        orderId: 'ord-retry',
        newStatus: OrderStatus.LOOKING_FOR_DRIVER,
        revision: 3,
      }),
    );
  });

  it('retryCustomOrderSearch rejects cleanly when customer already spent refunded coins', async () => {
    const tx: any = {
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ id: 'cust-1', coinBalance: 10 }]),
      order: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'ord-coins',
          orderNumber: 'OTL-COINS',
          type: OrderType.CUSTOM_DELIVERY,
          status: OrderStatus.CANCELLED,
          revision: 2,
          coinsUsed: 50,
          customerId: 'cust-1',
          customer: { userId: 'user-cust-1' },
          deliveryGroups: [{ id: 'g1', status: 'CANCELLED', primaryDriverId: null }],
        }),
        count: jest.fn().mockResolvedValue(0),
      },
      customerCoinTransaction: {
        findUnique: jest.fn().mockResolvedValue({ id: 'ref-1', amount: 50 }),
      },
    };
    const service = new OrderSearchService(
      { $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))) } as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {
        validateActiveOrderLimit: jest
          .fn()
          .mockResolvedValue({ maxActive: 3, requirePriorDelivery: false }),
      } as any,
      {} as any,
      {} as any,
    );

    await expect(
      service.retryCustomOrderSearch(CUSTOMER_ACTOR, 'ord-coins'),
    ).rejects.toThrow(CustomerErrors.INSUFFICIENT_COIN_BALANCE);
  });

  it('DispatchSearchTracker merges unique contacted & rejected driver IDs without leaking them over WebSocket', async () => {
    let savedSnapshot: any = null;
    const dispatchRepo = {
      getSearchSnapshot: jest.fn().mockResolvedValue({
        orderId: 'ord-ws',
        orderNumber: 'OTL-WS',
        orderType: OrderType.CUSTOM_DELIVERY,
        customerUserId: 'user-cust-1',
        orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
        revision: 1,
        phase: DriverSearchPhase.FINDING_DRIVERS,
        attempt: 1,
        maxAttempts: 5,
        radiusKm: 3,
        maxRadiusKm: 15,
        contactedCount: 2,
        totalContactedDriverIds: ['d1', 'd2'],
        rejectedDriverIds: ['d1'],
        waveExpiresAt: null,
        searchTimeoutSecs: 30,
        searchStartedAt: '2026-11-21T01:00:00Z',
        updatedAt: '2026-11-21T01:00:05Z',
        terminalReason: SearchTerminalReason.NONE,
        sequence: 100,
      }),
      saveSearchSnapshot: jest.fn().mockImplementation((_id, snap) => {
        savedSnapshot = snap;
        return Promise.resolve();
      }),
    };
    const socketService = {
      emitToUser: jest.fn().mockResolvedValue(undefined),
    };
    const tracker = new DispatchSearchTracker(
      dispatchRepo as any,
      {} as any,
      { getSettings: jest.fn().mockResolvedValue(BASE_SETTINGS) } as any,
      socketService as any,
    );

    const payload = await tracker.publishPhase({
      orderId: 'ord-ws',
      orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
      phase: DriverSearchPhase.CONTACTING_DRIVERS,
      attempt: 2,
      contactedDriverIds: ['d2', 'd3'],
      newlyRejectedDriverIds: ['d2'],
    });

    expect(savedSnapshot.totalContactedDriverIds).toEqual(['d1', 'd2', 'd3']);
    expect(payload?.totalContactedCount).toBe(3);
    expect(payload?.rejectedCount).toBe(2);
    expect((payload as any).totalContactedDriverIds).toBeUndefined();
    expect(socketService.emitToUser).toHaveBeenCalledWith(
      'user-cust-1',
      EVENTS.ORDER_SEARCH_PROGRESS,
      expect.objectContaining({
        orderId: 'ord-ws',
        phase: DriverSearchPhase.CONTACTING_DRIVERS,
        attempt: 2,
      }),
    );
  });

  it('OrderCancellationService handles idempotent customer retry cleanly', async () => {
    const cancelledOrder = {
      id: 'ord-c1',
      orderNumber: 'OTL-C1',
      status: OrderStatus.CANCELLED,
      cancelledByUserId: 'user-cust-1',
      customer: { userId: 'user-cust-1', user: { id: 'user-cust-1' } },
    };
    const ordersRepo = {
      findById: jest.fn().mockResolvedValue(cancelledOrder),
      cancelOrder: jest.fn(),
    };
    const service = new OrderCancellationService(
      ordersRepo as any,
      {} as any,
      {} as any,
      { emit: jest.fn() } as any,
    );

    const res = await service.cancelOrder(CUSTOMER_ACTOR, 'ord-c1', 'changed mind');
    expect(res).toBe(cancelledOrder);
    expect(ordersRepo.cancelOrder).not.toHaveBeenCalled();
  });

  it('OrderCancellationService rejects non-customer retry of DELIVERED order with BadRequestException after ownership check', async () => {
    const ordersRepo = {
      findById: jest.fn().mockResolvedValue({
        id: 'ord-del',
        status: OrderStatus.DELIVERED,
        cancelledByUserId: null,
        customer: { userId: 'user-cust-1' },
      }),
    };
    const service = new OrderCancellationService(
      ordersRepo as any,
      {} as any,
      {} as any,
      { emit: jest.fn() } as any,
    );

    await expect(
      service.cancelOrder(CUSTOMER_ACTOR, 'ord-del', ''),
    ).rejects.toThrow(new BadRequestException(OrderErrors.CANNOT_CANCEL_ORDER));
  });
});
