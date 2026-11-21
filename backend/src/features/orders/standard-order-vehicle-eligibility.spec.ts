import { BadRequestException } from '@nestjs/common';
import {
  DeliveryGroupStatus,
  DriverAssistRequestStatus,
  DriverStatus,
  OrderStatus,
  OrderType,
  Role,
  VehicleType,
} from '@prisma/client';
import {
  DriverGeoSearchService,
  isDriverVehicleEligibleForOrder,
  resolveAllowedVehicleTypes,
  VehicleAvailabilitySettings,
} from '../location/driver-geo-search.service';
import { LocationRepository } from '../location/location.repository';
import { DispatchService } from '../dispatch/dispatch.service';
import { DispatchLifecycleService } from '../dispatch/dispatch-lifecycle.service';
import { DispatchRepository } from '../dispatch/dispatch.repository';
import { DispatchProcessor } from '../dispatch/dispatch.processor';
import {
  DriverSearchPhase,
  SearchTerminalReason,
} from '../dispatch/dispatch-search.types';
import { OrdersStateService } from './orders-state.service';
import { OrderSearchService } from './order-search.service';
import { DriverAssistMatchingService } from '../drivers/driver-assist-matching.service';
import { DriverAssistService } from '../drivers/driver-assist.service';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { OrderErrors } from '../../common/constants/response.constants';

const ALL_VEHICLES_ACTIVE: VehicleAvailabilitySettings = {
  allowBicycle: true,
  allowMotorcycle: true,
  allowCar: true,
  allowVan: true,
  allowTruck: true,
  allowMotorTricycle: true,
  maxKmForBicycle: 5,
};

describe('STANDARD Order Vehicle Eligibility (Motorcycle & Bicycle Only)', () => {
  describe('resolveAllowedVehicleTypes & isDriverVehicleEligibleForOrder', () => {
    it('allows only MOTORCYCLE and BICYCLE for STANDARD orders even when all vehicles are active', () => {
      const allowed = resolveAllowedVehicleTypes(
        null,
        3.5,
        ALL_VEHICLES_ACTIVE,
        OrderType.STANDARD,
      );
      expect(allowed).toEqual([VehicleType.MOTORCYCLE, VehicleType.BICYCLE]);

      expect(
        isDriverVehicleEligibleForOrder({
          orderType: OrderType.STANDARD,
          driverVehicleType: VehicleType.MOTORCYCLE,
          orderDistanceKm: 3.5,
          settings: ALL_VEHICLES_ACTIVE,
        }),
      ).toBe(true);
      expect(
        isDriverVehicleEligibleForOrder({
          orderType: OrderType.STANDARD,
          driverVehicleType: VehicleType.BICYCLE,
          orderDistanceKm: 3.5,
          settings: ALL_VEHICLES_ACTIVE,
        }),
      ).toBe(true);

      for (const excluded of [
        VehicleType.CAR,
        VehicleType.VAN,
        VehicleType.TRUCK,
        VehicleType.MOTOR_TRICYCLE,
        null,
        undefined,
        '',
        'SCOOTER',
      ]) {
        expect(
          isDriverVehicleEligibleForOrder({
            orderType: OrderType.STANDARD,
            driverVehicleType: excluded,
            orderDistanceKm: 3.5,
            settings: ALL_VEHICLES_ACTIVE,
          }),
        ).toBe(false);
      }
    });

    it('enforces active settings and bicycle max distance on STANDARD orders', () => {
      // Distance > maxKmForBicycle excludes BICYCLE
      expect(
        resolveAllowedVehicleTypes(
          null,
          8,
          ALL_VEHICLES_ACTIVE,
          OrderType.STANDARD,
        ),
      ).toEqual([VehicleType.MOTORCYCLE]);

      // Motorcycle disabled -> only BICYCLE allowed within maxKmForBicycle
      expect(
        resolveAllowedVehicleTypes(
          null,
          3,
          { ...ALL_VEHICLES_ACTIVE, allowMotorcycle: false },
          OrderType.STANDARD,
        ),
      ).toEqual([VehicleType.BICYCLE]);

      // Bicycle disabled -> only MOTORCYCLE allowed
      expect(
        resolveAllowedVehicleTypes(
          null,
          3,
          { ...ALL_VEHICLES_ACTIVE, allowBicycle: false },
          OrderType.STANDARD,
        ),
      ).toEqual([VehicleType.MOTORCYCLE]);

      // Both Motorcycle & Bicycle disabled -> empty list (never falls back to CAR/VAN)
      expect(
        resolveAllowedVehicleTypes(
          null,
          3,
          {
            ...ALL_VEHICLES_ACTIVE,
            allowMotorcycle: false,
            allowBicycle: false,
          },
          OrderType.STANDARD,
        ),
      ).toEqual([]);
    });

    it('preserves existing eligibility rules for CUSTOM_DELIVERY and RIDE orders', () => {
      expect(
        resolveAllowedVehicleTypes(
          VehicleType.CAR,
          10,
          ALL_VEHICLES_ACTIVE,
          OrderType.RIDE,
        ),
      ).toEqual([VehicleType.CAR]);

      expect(
        resolveAllowedVehicleTypes(
          VehicleType.VAN,
          10,
          ALL_VEHICLES_ACTIVE,
          OrderType.CUSTOM_DELIVERY,
        ),
      ).toEqual([VehicleType.VAN]);

      expect(
        resolveAllowedVehicleTypes(
          VehicleType.TRUCK,
          10,
          ALL_VEHICLES_ACTIVE,
          OrderType.CUSTOM_DELIVERY,
        ),
      ).toEqual([VehicleType.TRUCK]);

      expect(
        resolveAllowedVehicleTypes(
          null,
          3,
          ALL_VEHICLES_ACTIVE,
          OrderType.CUSTOM_DELIVERY,
        ),
      ).toEqual([
        VehicleType.MOTORCYCLE,
        VehicleType.BICYCLE,
        VehicleType.CAR,
        VehicleType.VAN,
        VehicleType.TRUCK,
        VehicleType.MOTOR_TRICYCLE,
      ]);
    });
  });

  describe('LocationRepository & DriverGeoSearchService fail-closed filtering', () => {
    it('fails closed without querying DB/Redis when allowedVehicleTypes is empty', async () => {
      const queryRaw = jest.fn();
      const redis = { georadius: jest.fn() };
      const repo = new LocationRepository(
        { $queryRaw: queryRaw } as any,
        redis as any,
      );
      const search = new DriverGeoSearchService(repo, {
        getSettings: jest.fn(),
      } as any);

      expect(
        await search.findNearbyDrivers(31.23, 30.04, 5, [], [], false),
      ).toEqual([]);
      expect(redis.georadius).not.toHaveBeenCalled();

      expect(
        await repo.queryNearbyEligibleDrivers({
          candidateIds: ['drv-1'],
          longitude: 31.23,
          latitude: 30.04,
          allowedVehicleTypes: [],
          requireActiveShift: false,
          maxActiveOrders: 1,
          maxVendorMeters: 2000,
          maxCustomerMeters: 2500,
          activeOrderStatuses: ['DRIVER_ASSIGNED'],
        }),
      ).toEqual([]);
      expect(queryRaw).not.toHaveBeenCalled();
    });
  });

  describe('DispatchService.attemptDispatch & DispatchProcessor retries / no-driver handling', () => {
    function buildDispatchHarness(options: {
      orderType: OrderType;
      requestedVehicleType?: VehicleType | null;
      distanceKm?: number;
      nearbyDrivers: Array<{
        id: string;
        userId: string;
        vehicleType: string | null;
        distanceKm: number;
        activeShiftId: string | null;
        tier?: string;
      }>;
      settings?: Partial<VehicleAvailabilitySettings>;
    }) {
      const geoSearch = {
        findNearbyDrivers: jest.fn().mockResolvedValue(options.nearbyDrivers),
      };
      const emitter = { emit: jest.fn() };
      const dispatchQueue = { add: jest.fn().mockResolvedValue({}) };
      const redis = {
        set: jest.fn().mockResolvedValue(undefined),
        setNX: jest.fn().mockResolvedValue(true),
        sadd: jest.fn().mockResolvedValue(1),
        expire: jest.fn().mockResolvedValue(1),
        del: jest.fn().mockResolvedValue(1),
        delIfValue: jest.fn().mockResolvedValue(true),
      };
      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-1',
            status: OrderStatus.LOOKING_FOR_DRIVER,
            type: options.orderType,
            pickupAddress: 'Downtown',
            deliveryFee: 25,
            customer: { userId: 'u-cust', user: { name: 'Ali', avatar: null } },
          }),
        },
        orderDeliveryGroup: {
          count: jest.fn().mockResolvedValue(1),
          findFirst: jest.fn().mockResolvedValue({
            id: 'grp-1',
            orderId: 'ord-1',
            sequence: 1,
            status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
            deliveryFee: 25,
            goldSurchargeAmount: 0,
            distanceKm: options.distanceKm ?? 3,
            primaryDriverId: null,
            items: [],
          }),
        },
      };
      const locationRepo: any = {
        getOrderLocationContext: jest.fn().mockResolvedValue({
          requestedVehicleType: options.requestedVehicleType ?? null,
          lng: 31.23,
          lat: 30.04,
          deliveryLng: 31.25,
          deliveryLat: 30.05,
        }),
        getDeliveryGroupPickupLocation: jest
          .fn()
          .mockResolvedValue({ lng: 31.23, lat: 30.04 }),
        getDistanceKm: jest.fn().mockResolvedValue(options.distanceKm ?? 3),
      };
      const fullSettings = {
        ...ALL_VEHICLES_ACTIVE,
        driverSearchRadiusKm: 3,
        driverSearchRadiusStepKm: 3,
        driverSearchRadiusMaxKm: 15,
        driverAcceptTimeoutSecs: 30,
        maxDispatchBatchSize: 20,
        driverSearchMaxAttempts: 3,
        driverShiftsEnabled: false,
        driverCommissionRate: 0,
        ...options.settings,
      };
      const settingsSvc: any = {
        getSettings: jest.fn().mockResolvedValue(fullSettings),
        getVehiclePerKm: jest.fn().mockResolvedValue(null),
        calculateDeliveryFee: jest.fn().mockResolvedValue(25),
      };
      const dispatchRepo = new DispatchRepository(prisma, redis as any);
      const dispatch = new DispatchService(
        dispatchRepo,
        {} as any,
        settingsSvc,
        emitter as any,
        prisma,
        locationRepo,
        geoSearch as any,
        new OrderEarningsCalculator(settingsSvc),
        dispatchQueue as any,
      );
      return { dispatch, geoSearch, emitter, dispatchQueue };
    }

    it('dispatches STANDARD orders to eligible MOTORCYCLE and BICYCLE drivers and excludes CAR/VAN/TRUCK/MOTOR_TRICYCLE', async () => {
      const { dispatch, geoSearch, emitter } = buildDispatchHarness({
        orderType: OrderType.STANDARD,
        distanceKm: 3,
        nearbyDrivers: [
          {
            id: 'drv-moto',
            userId: 'u-moto',
            vehicleType: VehicleType.MOTORCYCLE,
            distanceKm: 1.0,
            activeShiftId: null,
          },
          {
            id: 'drv-bike',
            userId: 'u-bike',
            vehicleType: VehicleType.BICYCLE,
            distanceKm: 1.2,
            activeShiftId: null,
          },
          {
            id: 'drv-car',
            userId: 'u-car',
            vehicleType: VehicleType.CAR,
            distanceKm: 0.5,
            activeShiftId: null,
          },
          {
            id: 'drv-van',
            userId: 'u-van',
            vehicleType: VehicleType.VAN,
            distanceKm: 0.6,
            activeShiftId: null,
          },
          {
            id: 'drv-truck',
            userId: 'u-truck',
            vehicleType: VehicleType.TRUCK,
            distanceKm: 0.7,
            activeShiftId: null,
          },
          {
            id: 'drv-tri',
            userId: 'u-tri',
            vehicleType: VehicleType.MOTOR_TRICYCLE,
            distanceKm: 0.8,
            activeShiftId: null,
          },
        ],
      });

      const outcome = await dispatch.attemptDispatch({
        orderId: 'ord-1',
        orderNumber: 'STD-1',
        attempt: 1,
      });

      expect(outcome).toBe('dispatched');
      expect(geoSearch.findNearbyDrivers).toHaveBeenCalledWith(
        31.23,
        30.04,
        3,
        [],
        [VehicleType.MOTORCYCLE, VehicleType.BICYCLE],
        false,
        { lng: 31.25, lat: 30.05 },
      );

      // Offers MUST ONLY be sent to Motorcycle and Bicycle drivers
      const offeredDriverIds = emitter.emit.mock.calls.map(
        (c) => c[1].driverId,
      );
      expect(offeredDriverIds).toEqual(['drv-moto', 'drv-bike']);
      expect(offeredDriverIds).not.toContain('drv-car');
      expect(offeredDriverIds).not.toContain('drv-van');
      expect(offeredDriverIds).not.toContain('drv-truck');
      expect(offeredDriverIds).not.toContain('drv-tri');
    });

    it('returns no_drivers for STANDARD orders (including retries) when only CAR/VAN/TRUCK drivers exist, and triggers NO_DRIVERS_AVAILABLE upon exhaustion', async () => {
      const { dispatch, geoSearch, emitter } = buildDispatchHarness({
        orderType: OrderType.STANDARD,
        distanceKm: 3,
        nearbyDrivers: [
          {
            id: 'drv-car',
            userId: 'u-car',
            vehicleType: VehicleType.CAR,
            distanceKm: 0.5,
            activeShiftId: null,
          },
          {
            id: 'drv-van',
            userId: 'u-van',
            vehicleType: VehicleType.VAN,
            distanceKm: 0.7,
            activeShiftId: null,
          },
        ],
      });

      // Attempt 1 & Retry Attempt 2 both enforce Motorcycle/Bicycle only and emit zero offers
      for (const attempt of [1, 2]) {
        const outcome = await dispatch.attemptDispatch({
          orderId: 'ord-1',
          orderNumber: 'STD-NO-ELIGIBLE',
          attempt,
        });
        expect(outcome).toBe('no_drivers');
      }
      expect(emitter.emit).not.toHaveBeenCalled();
      expect(geoSearch.findNearbyDrivers).toHaveBeenNthCalledWith(
        2,
        31.23,
        30.04,
        6, // expanded radius on retry attempt 2
        [],
        [VehicleType.MOTORCYCLE, VehicleType.BICYCLE],
        false,
        { lng: 31.25, lat: 30.05 },
      );

      // Exhaustion in DispatchProcessor publishes NO_DRIVERS_AVAILABLE and cancels group
      const publishPhase = jest.fn().mockResolvedValue(undefined);
      const handleUndispatchableDeliveryGroup = jest
        .fn()
        .mockResolvedValue({ groupCancelled: true, orderCancelled: true });
      const processor = new DispatchProcessor(
        dispatch,
        {
          getSearchSnapshot: jest
            .fn()
            .mockResolvedValue({ totalContactedDriverIds: [] }),
        } as any,
        {
          transitionAcceptedOrderToSearching: jest.fn(),
          handleUndispatchableDeliveryGroup,
        } as any,
        { enqueueCancelOrder: jest.fn() } as any,
        {
          getSettings: jest
            .fn()
            .mockResolvedValue({ driverSearchMaxAttempts: 3 }),
        } as any,
        {
          order: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'ord-1',
              status: OrderStatus.LOOKING_FOR_DRIVER,
            }),
          },
        } as any,
        geoSearch as any,
        { add: jest.fn() } as any,
        { publishPhase } as any,
      );

      const res = await processor.process({
        id: 'job-exhaust',
        name: 'order.dispatch',
        data: {
          orderId: 'ord-1',
          orderNumber: 'STD-NO-ELIGIBLE',
          attempt: 4,
          deliveryGroupId: 'grp-1',
        },
      } as any);

      expect(res.noDriversFound).toBe(true);
      expect(publishPhase).toHaveBeenCalledWith(
        expect.objectContaining({
          phase: DriverSearchPhase.NO_DRIVERS_AVAILABLE,
          terminalReason: SearchTerminalReason.NO_DRIVERS_AVAILABLE,
        }),
      );
      expect(handleUndispatchableDeliveryGroup).toHaveBeenCalled();
    });

    it('preserves CAR dispatch for RIDE and VAN dispatch for CUSTOM_DELIVERY', async () => {
      const rideHarness = buildDispatchHarness({
        orderType: OrderType.RIDE,
        requestedVehicleType: VehicleType.CAR,
        distanceKm: 8,
        nearbyDrivers: [
          {
            id: 'drv-car',
            userId: 'u-car',
            vehicleType: VehicleType.CAR,
            distanceKm: 1.0,
            activeShiftId: null,
          },
        ],
      });
      expect(
        await rideHarness.dispatch.attemptDispatch({
          orderId: 'ord-1',
          orderNumber: 'RIDE-1',
          attempt: 1,
        }),
      ).toBe('dispatched');
      expect(rideHarness.geoSearch.findNearbyDrivers.mock.calls[0][4]).toEqual([
        VehicleType.CAR,
      ]);

      const customHarness = buildDispatchHarness({
        orderType: OrderType.CUSTOM_DELIVERY,
        requestedVehicleType: VehicleType.VAN,
        distanceKm: 10,
        nearbyDrivers: [
          {
            id: 'drv-van',
            userId: 'u-van',
            vehicleType: VehicleType.VAN,
            distanceKm: 1.5,
            activeShiftId: null,
          },
        ],
      });
      expect(
        await customHarness.dispatch.attemptDispatch({
          orderId: 'ord-1',
          orderNumber: 'CD-1',
          attempt: 1,
        }),
      ).toBe('dispatched');
      expect(
        customHarness.geoSearch.findNearbyDrivers.mock.calls[0][4],
      ).toEqual([VehicleType.VAN]);
    });
  });

  describe('DispatchLifecycleService.handleAcceptance runtime vehicle guard', () => {
    it('rejects acceptance on a STANDARD order if the driver vehicle is CAR/VAN at accept time', async () => {
      const dispatchData = {
        orderId: 'ord-std-acc',
        deliveryGroupId: 'grp-1',
        type: OrderType.STANDARD,
        expiresAt: new Date(Date.now() + 60_000).toISOString(),
        candidates: [
          {
            driverId: 'drv-car',
            userId: 'u-car',
            driverShiftId: null,
            deliveryGroupId: 'grp-1',
            distanceKm: 1,
            estimatedEarnings: 20,
            isStacked: false,
          },
        ],
      };

      const tx: any = {
        $queryRaw: jest.fn().mockResolvedValue([{ id: 'drv-car' }]),
        orderDeliveryGroup: {
          count: jest.fn().mockResolvedValue(0),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        order: {
          count: jest.fn().mockResolvedValue(0),
          update: jest.fn().mockResolvedValue({ revision: 2 }),
        },
        orderDispatch: { create: jest.fn().mockResolvedValue({}) },
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            tier: 'SILVER',
            vehicleType: VehicleType.CAR,
            isApproved: true,
            deletedAt: null,
            hasUnpaidCommission: false,
          }),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      const prisma: any = {
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-std-acc',
            orderNumber: 'STD-ACC',
            type: OrderType.STANDARD,
            requestedVehicleType: null,
            status: OrderStatus.LOOKING_FOR_DRIVER,
            paymentMethod: 'CASH_ON_DELIVERY',
            paymentStatus: 'PENDING',
            upfrontAmount: 0,
            customerId: 'c1',
            distanceKm: 2,
            customer: { userId: 'u-c1' },
            deliveryGroups: [
              {
                id: 'grp-1',
                status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                primaryDriverId: null,
              },
            ],
            vendorFulfillments: [],
          }),
        },
        orderVendorFulfillment: { findMany: jest.fn().mockResolvedValue([]) },
        $transaction: jest.fn((cb: any) => Promise.resolve(cb(tx))),
      };
      const redis: any = {
        get: jest.fn().mockResolvedValue(JSON.stringify(dispatchData)),
        smembers: jest.fn().mockResolvedValue([]),
        delIfValue: jest.fn().mockResolvedValue(true),
      };
      const lifecycle = new DispatchLifecycleService(
        new DispatchRepository(prisma, redis),
        {
          getSettings: jest.fn().mockResolvedValue({
            ...ALL_VEHICLES_ACTIVE,
            maxActiveOrdersPerDriver: 1,
          }),
        } as any,
        { emit: jest.fn() } as any,
        prisma,
        {
          getOrderLocationContext: jest.fn().mockResolvedValue({
            lng: 31.23,
            lat: 30.04,
            deliveryLng: 31.25,
            deliveryLat: 30.05,
          }),
          getDeliveryGroupPickupLocation: jest
            .fn()
            .mockResolvedValue({ lng: 31.23, lat: 30.04 }),
          getDistanceKm: jest.fn().mockResolvedValue(2),
        } as any,
        { add: jest.fn() } as any,
        { add: jest.fn() } as any,
        { record: jest.fn(), markProcessed: jest.fn() } as any,
        { onOrderStatusChanged: jest.fn() } as any,
        new DriverWorkloadHelper(),
      );

      await expect(
        lifecycle.handleAcceptance('disp-1', 'drv-car'),
      ).rejects.toThrow(OrderErrors.STANDARD_ORDER_VEHICLE_NOT_ELIGIBLE);
      expect(tx.orderDeliveryGroup.updateMany).not.toHaveBeenCalled();
    });
  });

  describe('OrdersStateService.adminForceAssignDriver vehicle validation', () => {
    function buildStateHarness(params: {
      orderType: OrderType;
      driverVehicleType: VehicleType | null;
      distanceKm?: number;
    }) {
      const assignDriverMock = jest.fn().mockResolvedValue({
        revision: 2,
        status: OrderStatus.DRIVER_ASSIGNED,
      });
      const prisma: any = {
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-1',
            status: DriverStatus.ONLINE,
            userId: 'u-drv-1',
            vehicleType: params.driverVehicleType,
            isApproved: true,
            deletedAt: null,
          }),
        },
        platformSetting: {
          findUnique: jest.fn().mockResolvedValue({
            maxActiveOrdersPerDriver: 2,
            ...ALL_VEHICLES_ACTIVE,
          }),
        },
        driverShift: { findFirst: jest.fn().mockResolvedValue(null) },
        order: {
          findUnique: jest
            .fn()
            .mockResolvedValue({ status: OrderStatus.LOOKING_FOR_DRIVER }),
        },
        orderDeliveryGroup: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'grp-1',
              sequence: 1,
              status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
              primaryDriverId: null,
              assistDriverId: null,
            },
          ]),
          update: jest.fn().mockResolvedValue({}),
        },
      };
      const ordersRepo: any = {
        findById: jest.fn().mockResolvedValue({
          id: 'ord-1',
          orderNumber: 'ORD-1',
          type: params.orderType,
          distanceKm: params.distanceKm ?? 3,
          status: OrderStatus.LOOKING_FOR_DRIVER,
          paymentMethod: 'CASH_ON_DELIVERY',
          paymentStatus: 'PENDING',
          customerId: 'c1',
          customer: { user: { id: 'u-c1' } },
          vendorFulfillments: [],
        }),
        assignDriver: assignDriverMock,
        freeDriver: jest.fn(),
        getOrderVendorUserIds: jest.fn().mockResolvedValue([]),
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
      return { svc, assignDriverMock };
    }

    it.each([VehicleType.MOTORCYCLE, VehicleType.BICYCLE])(
      'allows manual assignment of %s driver on STANDARD order',
      async (vehicleType) => {
        const { svc, assignDriverMock } = buildStateHarness({
          orderType: OrderType.STANDARD,
          driverVehicleType: vehicleType,
          distanceKm: 3,
        });
        await svc.adminForceAssignDriver(
          { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
          'ord-1',
          { driverId: 'drv-1' },
        );
        expect(assignDriverMock).toHaveBeenCalledTimes(1);
      },
    );

    it.each([
      VehicleType.CAR,
      VehicleType.VAN,
      VehicleType.TRUCK,
      VehicleType.MOTOR_TRICYCLE,
      null,
    ])(
      'rejects manual assignment of %s driver on STANDARD order',
      async (vehicleType) => {
        const { svc, assignDriverMock } = buildStateHarness({
          orderType: OrderType.STANDARD,
          driverVehicleType: vehicleType,
          distanceKm: 3,
        });
        await expect(
          svc.adminForceAssignDriver(
            { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
            'ord-1',
            { driverId: 'drv-1' },
          ),
        ).rejects.toThrow(BadRequestException);
        expect(assignDriverMock).not.toHaveBeenCalled();
      },
    );

    it('rejects manual BICYCLE assignment when STANDARD order exceeds maxKmForBicycle', async () => {
      const { svc, assignDriverMock } = buildStateHarness({
        orderType: OrderType.STANDARD,
        driverVehicleType: VehicleType.BICYCLE,
        distanceKm: 9,
      });
      await expect(
        svc.adminForceAssignDriver(
          { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
          'ord-1',
          { driverId: 'drv-1' },
        ),
      ).rejects.toThrow(OrderErrors.BICYCLE_DISTANCE_EXCEEDED);
      expect(assignDriverMock).not.toHaveBeenCalled();
    });

    it('continues allowing CAR for RIDE and VAN for CUSTOM_DELIVERY', async () => {
      for (const [orderType, vehicleType] of [
        [OrderType.RIDE, VehicleType.CAR],
        [OrderType.CUSTOM_DELIVERY, VehicleType.VAN],
      ] as const) {
        const { svc, assignDriverMock } = buildStateHarness({
          orderType,
          driverVehicleType: vehicleType,
          distanceKm: 10,
        });
        await svc.adminForceAssignDriver(
          { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
          'ord-1',
          { driverId: 'drv-1' },
        );
        expect(assignDriverMock).toHaveBeenCalledTimes(1);
      }
    });
  });

  describe('DriverAssistMatchingService, DriverAssistService, and OrderSearchService', () => {
    it('excludes CAR/VAN from STANDARD assist matching and manual assist assignment', async () => {
      const driverFindMany = jest.fn().mockResolvedValue([
        { id: 'drv-car', vehicleType: VehicleType.CAR },
        { id: 'drv-bike', vehicleType: VehicleType.BICYCLE },
      ]);
      const matching = new DriverAssistMatchingService(
        {
          $queryRaw: jest.fn().mockResolvedValue([
            { id: 'drv-p', lng: 31.23, lat: 30.04 },
            { id: 'drv-car', lng: 31.2301, lat: 30.0401 },
            { id: 'drv-bike', lng: 31.232, lat: 30.042 },
          ]),
          orderDeliveryGroup: {
            findUnique: jest
              .fn()
              .mockResolvedValue({ primaryDriverId: 'drv-p' }),
            findMany: jest.fn().mockResolvedValue([]),
          },
          driver: { findMany: driverFindMany },
          order: {
            findUnique: jest.fn().mockResolvedValue({
              type: OrderType.STANDARD,
              requestedVehicleType: null,
              distanceKm: 2,
            }),
          },
        } as any,
        { emit: jest.fn() } as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            ...ALL_VEHICLES_ACTIVE,
            driverShiftsEnabled: false,
          }),
        } as any,
        {
          getDeliveryGroupPickupLocation: jest
            .fn()
            .mockResolvedValue({ lng: 31.23, lat: 30.04 }),
          getOrderLocationContext: jest
            .fn()
            .mockResolvedValue({ lng: 31.23, lat: 30.04 }),
        } as any,
        { mgetStrings: jest.fn().mockResolvedValue([]) } as any,
      );

      const best = await matching.findBestCandidate({
        deliveryGroupId: 'grp-1',
        orderId: 'ord-std-1',
      });
      expect(best).toBe('drv-bike');
      expect(driverFindMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            vehicleType: { in: [VehicleType.MOTORCYCLE, VehicleType.BICYCLE] },
          }),
        }),
      );

      // Manual assist assignment rejects CAR driver on STANDARD order
      const assistService = new DriverAssistService(
        {
          driverAssistRequest: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'req-1',
              status: DriverAssistRequestStatus.APPROVED,
              orderId: 'ord-std-1',
              deliveryGroupId: 'grp-1',
              order: {
                id: 'ord-std-1',
                orderNumber: 'STD-1',
                status: OrderStatus.DRIVER_ASSIGNED,
                type: OrderType.STANDARD,
                requestedVehicleType: null,
                distanceKm: 2,
              },
            }),
          },
          driver: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'drv-car',
              userId: 'u-car',
              status: DriverStatus.ONLINE,
              isApproved: true,
              vehicleType: VehicleType.CAR,
              hasUnpaidCommission: false,
              deletedAt: null,
              tier: 'SILVER',
            }),
          },
        } as any,
        { emit: jest.fn() } as any,
        { getSettings: jest.fn().mockResolvedValue(ALL_VEHICLES_ACTIVE) } as any,
        matching,
        {} as any,
      );

      await expect(
        assistService.assignDriver(
          'req-1',
          { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
          { driverId: 'drv-car' },
        ),
      ).rejects.toThrow(OrderErrors.STANDARD_ORDER_VEHICLE_NOT_ELIGIBLE);
    });

    it('OrderSearchService.getNearbyDriversPreview restricts STANDARD preview to MOTORCYCLE & BICYCLE', async () => {
      const geoSearch = { findNearbyDrivers: jest.fn().mockResolvedValue([]) };
      const searchService = new OrderSearchService(
        {} as any,
        {
          getSettings: jest.fn().mockResolvedValue({
            ...ALL_VEHICLES_ACTIVE,
            driverSearchRadiusKm: 4,
          }),
        } as any,
        geoSearch as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      await searchService.getNearbyDriversPreview({
        lat: 30.044,
        lng: 31.235,
        type: OrderType.STANDARD,
      });

      expect(geoSearch.findNearbyDrivers).toHaveBeenCalledWith(
        31.235,
        30.044,
        4,
        [],
        [VehicleType.MOTORCYCLE, VehicleType.BICYCLE],
        false,
        null,
      );
    });
  });
});
