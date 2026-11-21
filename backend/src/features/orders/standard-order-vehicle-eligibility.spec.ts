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
import { OrdersCheckoutService } from './orders-checkout.service';
import { OrderSearchService } from './order-search.service';
import { DriverAssistMatchingService } from '../drivers/driver-assist-matching.service';
import { DriverAssistService } from '../drivers/driver-assist.service';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import { DeliveryFeeCalculator } from '../platform-settings/delivery-fee.calculator';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { OrderErrors } from '../../common/constants/response.constants';

const ALL_VEHICLES_ACTIVE: VehicleAvailabilitySettings = {
  allowBicycle: true,
  allowMotorcycle: true,
  allowCar: true,
  allowMinibus: true,
  allowTukTuk: true,
  allowMotorTricycle: true,
  allowQuarterTruck: true,
  allowHalfTruck: true,
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
        VehicleType.MINIBUS,
        VehicleType.TUK_TUK,
        VehicleType.MOTOR_TRICYCLE,
        VehicleType.QUARTER_TRUCK,
        VehicleType.HALF_TRUCK,
        null,
        undefined,
        '',
        'VAN',
        'TRUCK',
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

    it('enforces exact service-specific vehicle matrices for RIDE and CUSTOM_DELIVERY orders', () => {
      // RIDE supports ONLY MOTORCYCLE, CAR, MINIBUS, TUK_TUK
      for (const rideVehicle of [
        VehicleType.MOTORCYCLE,
        VehicleType.CAR,
        VehicleType.MINIBUS,
        VehicleType.TUK_TUK,
      ]) {
        expect(
          resolveAllowedVehicleTypes(
            rideVehicle,
            10,
            ALL_VEHICLES_ACTIVE,
            OrderType.RIDE,
          ),
        ).toEqual([rideVehicle]);
      }
      for (const nonRideVehicle of [
        VehicleType.BICYCLE,
        VehicleType.MOTOR_TRICYCLE,
        VehicleType.QUARTER_TRUCK,
        VehicleType.HALF_TRUCK,
      ]) {
        expect(
          resolveAllowedVehicleTypes(
            nonRideVehicle,
            10,
            ALL_VEHICLES_ACTIVE,
            OrderType.RIDE,
          ),
        ).toEqual([]);
      }
      expect(
        resolveAllowedVehicleTypes(null, 10, ALL_VEHICLES_ACTIVE, OrderType.RIDE),
      ).toEqual([
        VehicleType.MOTORCYCLE,
        VehicleType.CAR,
        VehicleType.MINIBUS,
        VehicleType.TUK_TUK,
      ]);

      // CUSTOM_DELIVERY supports ONLY MOTORCYCLE, MOTOR_TRICYCLE, QUARTER_TRUCK, HALF_TRUCK
      for (const customVehicle of [
        VehicleType.MOTORCYCLE,
        VehicleType.MOTOR_TRICYCLE,
        VehicleType.QUARTER_TRUCK,
        VehicleType.HALF_TRUCK,
      ]) {
        expect(
          resolveAllowedVehicleTypes(
            customVehicle,
            10,
            ALL_VEHICLES_ACTIVE,
            OrderType.CUSTOM_DELIVERY,
          ),
        ).toEqual([customVehicle]);
      }
      for (const nonCustomVehicle of [
        VehicleType.BICYCLE,
        VehicleType.CAR,
        VehicleType.MINIBUS,
        VehicleType.TUK_TUK,
      ]) {
        expect(
          resolveAllowedVehicleTypes(
            nonCustomVehicle,
            10,
            ALL_VEHICLES_ACTIVE,
            OrderType.CUSTOM_DELIVERY,
          ),
        ).toEqual([]);
      }
      expect(
        resolveAllowedVehicleTypes(
          null,
          3,
          ALL_VEHICLES_ACTIVE,
          OrderType.CUSTOM_DELIVERY,
        ),
      ).toEqual([
        VehicleType.MOTORCYCLE,
        VehicleType.MOTOR_TRICYCLE,
        VehicleType.QUARTER_TRUCK,
        VehicleType.HALF_TRUCK,
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
            id: 'drv-minibus',
            userId: 'u-minibus',
            vehicleType: VehicleType.MINIBUS,
            distanceKm: 0.6,
            activeShiftId: null,
          },
          {
            id: 'drv-tuktuk',
            userId: 'u-tuktuk',
            vehicleType: VehicleType.TUK_TUK,
            distanceKm: 0.65,
            activeShiftId: null,
          },
          {
            id: 'drv-quarter',
            userId: 'u-quarter',
            vehicleType: VehicleType.QUARTER_TRUCK,
            distanceKm: 0.7,
            activeShiftId: null,
          },
          {
            id: 'drv-half',
            userId: 'u-half',
            vehicleType: VehicleType.HALF_TRUCK,
            distanceKm: 0.75,
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
        true,
      );

      // Offers MUST ONLY be sent to Motorcycle and Bicycle drivers
      const offeredDriverIds = emitter.emit.mock.calls.map(
        (c) => c[1].driverId,
      );
      expect(offeredDriverIds).toEqual(['drv-moto', 'drv-bike']);
      expect(offeredDriverIds).not.toContain('drv-car');
      expect(offeredDriverIds).not.toContain('drv-minibus');
      expect(offeredDriverIds).not.toContain('drv-tuktuk');
      expect(offeredDriverIds).not.toContain('drv-quarter');
      expect(offeredDriverIds).not.toContain('drv-half');
      expect(offeredDriverIds).not.toContain('drv-tri');
    });

    it('returns no_drivers for STANDARD orders (including retries) when only CAR/MINIBUS/QUARTER_TRUCK drivers exist, and triggers NO_DRIVERS_AVAILABLE upon exhaustion', async () => {
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
            id: 'drv-quarter',
            userId: 'u-quarter',
            vehicleType: VehicleType.QUARTER_TRUCK,
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
        true,
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

    it('dispatches exact matching drivers for all RIDE and CUSTOM_DELIVERY vehicles and never sends cross-vehicle offers', async () => {
      for (const [orderType, requestedVehicle, wrongVehicle] of [
        [OrderType.RIDE, VehicleType.MOTORCYCLE, VehicleType.CAR],
        [OrderType.RIDE, VehicleType.CAR, VehicleType.MINIBUS],
        [OrderType.RIDE, VehicleType.MINIBUS, VehicleType.TUK_TUK],
        [OrderType.RIDE, VehicleType.TUK_TUK, VehicleType.MOTOR_TRICYCLE],
        [OrderType.CUSTOM_DELIVERY, VehicleType.MOTORCYCLE, VehicleType.CAR],
        [OrderType.CUSTOM_DELIVERY, VehicleType.MOTOR_TRICYCLE, VehicleType.TUK_TUK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.QUARTER_TRUCK, VehicleType.HALF_TRUCK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.HALF_TRUCK, VehicleType.QUARTER_TRUCK],
      ] as const) {
        const harness = buildDispatchHarness({
          orderType,
          requestedVehicleType: requestedVehicle,
          distanceKm: 8,
          nearbyDrivers: [
            {
              id: `drv-match-${requestedVehicle}`,
              userId: `u-match-${requestedVehicle}`,
              vehicleType: requestedVehicle,
              distanceKm: 1.0,
              activeShiftId: null,
            },
            {
              id: `drv-wrong-${wrongVehicle}`,
              userId: `u-wrong-${wrongVehicle}`,
              vehicleType: wrongVehicle,
              distanceKm: 0.5,
              activeShiftId: null,
            },
          ],
        });
        expect(
          await harness.dispatch.attemptDispatch({
            orderId: 'ord-1',
            orderNumber: `${orderType}-${requestedVehicle}`,
            attempt: 1,
          }),
        ).toBe('dispatched');
        expect(harness.geoSearch.findNearbyDrivers.mock.calls[0][4]).toEqual([
          requestedVehicle,
        ]);
        const offeredIds = harness.emitter.emit.mock.calls.map(
          (c) => c[1].driverId,
        );
        expect(offeredIds).toEqual([`drv-match-${requestedVehicle}`]);
      }
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

    it.each([
      [OrderType.RIDE, VehicleType.TUK_TUK, VehicleType.CAR],
      [OrderType.CUSTOM_DELIVERY, VehicleType.QUARTER_TRUCK, VehicleType.HALF_TRUCK],
    ])(
      'rejects acceptance on %s (requested=%s) when driver vehicle is %s at accept time',
      async (orderType, requestedVehicle, driverVehicle) => {
        const dispatchData = {
          orderId: 'ord-custom-acc',
          deliveryGroupId: 'grp-1',
          type: orderType,
          requestedVehicleType: requestedVehicle,
          expiresAt: new Date(Date.now() + 60_000).toISOString(),
          candidates: [
            {
              driverId: 'drv-mismatch',
              userId: 'u-mismatch',
              driverShiftId: null,
              deliveryGroupId: 'grp-1',
              distanceKm: 1.0,
              estimatedEarnings: 25,
              isStacked: false,
            },
          ],
        };
        const tx: any = {
          $queryRaw: jest.fn().mockResolvedValue([]),
          orderDeliveryGroup: {
            count: jest.fn().mockResolvedValue(0),
            findMany: jest.fn().mockResolvedValue([]),
            updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          },
          orderDispatch: { create: jest.fn().mockResolvedValue({}) },
          driver: {
            findUnique: jest.fn().mockResolvedValue({
              tier: 'SILVER',
              vehicleType: driverVehicle,
              isApproved: true,
              deletedAt: null,
              hasUnpaidCommission: false,
            }),
          },
        };
        const prisma: any = {
          order: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'ord-custom-acc',
              orderNumber: 'ORD-CUST-1',
              type: orderType,
              requestedVehicleType: requestedVehicle,
              status: OrderStatus.LOOKING_FOR_DRIVER,
              paymentMethod: 'CASH_ON_DELIVERY',
              paymentStatus: 'PENDING',
              upfrontAmount: 0,
              customerId: 'c1',
              distanceKm: 4,
              customer: { userId: 'u-c1' },
              vendorFulfillments: [],
              deliveryGroups: [
                {
                  id: 'grp-1',
                  status: DeliveryGroupStatus.LOOKING_FOR_DRIVER,
                  primaryDriverId: null,
                },
              ],
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
              requestedVehicleType: requestedVehicle,
            }),
            getDeliveryGroupPickupLocation: jest.fn().mockResolvedValue(null),
            getDistanceKm: jest.fn().mockResolvedValue(4),
          } as any,
          { add: jest.fn() } as any,
          { add: jest.fn() } as any,
          { record: jest.fn(), markProcessed: jest.fn() } as any,
          { onOrderStatusChanged: jest.fn() } as any,
          new DriverWorkloadHelper(),
        );

        await expect(
          lifecycle.handleAcceptance('disp-custom-1', 'drv-mismatch'),
        ).rejects.toThrow(OrderErrors.DRIVER_VEHICLE_NOT_ELIGIBLE);
        expect(tx.orderDeliveryGroup.updateMany).not.toHaveBeenCalled();
      },
    );
  });

  describe('OrdersStateService.adminForceAssignDriver vehicle validation', () => {
    function buildStateHarness(params: {
      orderType: OrderType;
      driverVehicleType: VehicleType | null;
      requestedVehicleType?: VehicleType | null;
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
          requestedVehicleType: params.requestedVehicleType ?? null,
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
      VehicleType.MINIBUS,
      VehicleType.TUK_TUK,
      VehicleType.MOTOR_TRICYCLE,
      VehicleType.QUARTER_TRUCK,
      VehicleType.HALF_TRUCK,
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

    it('allows matching vehicle types for RIDE & CUSTOM_DELIVERY and rejects mismatches on manual assignment', async () => {
      for (const [orderType, vehicleType] of [
        [OrderType.RIDE, VehicleType.MOTORCYCLE],
        [OrderType.RIDE, VehicleType.CAR],
        [OrderType.RIDE, VehicleType.MINIBUS],
        [OrderType.RIDE, VehicleType.TUK_TUK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.MOTORCYCLE],
        [OrderType.CUSTOM_DELIVERY, VehicleType.MOTOR_TRICYCLE],
        [OrderType.CUSTOM_DELIVERY, VehicleType.QUARTER_TRUCK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.HALF_TRUCK],
      ] as const) {
        const { svc, assignDriverMock } = buildStateHarness({
          orderType,
          requestedVehicleType: vehicleType,
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

      // Cross-service and wrong-vehicle manual force-assign MUST be rejected
      for (const [orderType, requestedVehicle, driverVehicle] of [
        [OrderType.RIDE, VehicleType.TUK_TUK, VehicleType.CAR],
        [OrderType.RIDE, VehicleType.MINIBUS, VehicleType.QUARTER_TRUCK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.QUARTER_TRUCK, VehicleType.HALF_TRUCK],
        [OrderType.CUSTOM_DELIVERY, VehicleType.MOTOR_TRICYCLE, VehicleType.CAR],
      ] as const) {
        const { svc, assignDriverMock } = buildStateHarness({
          orderType,
          requestedVehicleType: requestedVehicle,
          driverVehicleType: driverVehicle,
          distanceKm: 10,
        });
        await expect(
          svc.adminForceAssignDriver(
            { sub: 'admin-1', role: Role.SUPER_ADMIN } as any,
            'ord-1',
            { driverId: 'drv-1' },
          ),
        ).rejects.toThrow(OrderErrors.DRIVER_VEHICLE_NOT_ELIGIBLE);
        expect(assignDriverMock).not.toHaveBeenCalled();
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

  describe('OrdersCheckoutService Ride & Custom Delivery vehicle validation & pricing', () => {
    function buildCheckoutHarness(settingOverrides: Record<string, any> = {}) {
      const feeCalc = new DeliveryFeeCalculator();
      const settings: any = {
        ...ALL_VEHICLES_ACTIVE,
        baseDeliveryFee: 15,
        pricePerKm: 3,
        pricePerKmBicycle: 2,
        pricePerKmMotorcycle: 3,
        pricePerKmCar: 5,
        pricePerKmMinibus: 8,
        pricePerKmTukTuk: 4,
        pricePerKmMotorTricycle: 4,
        pricePerKmQuarterTruck: 8,
        pricePerKmHalfTruck: 12,
        minDeliveryFee: 15,
        maxDeliveryFee: 0,
        minDeliveryFeeBicycle: 15,
        maxDeliveryFeeBicycle: 0,
        minDeliveryFeeMotorcycle: 15,
        maxDeliveryFeeMotorcycle: 0,
        minDeliveryFeeCar: 15,
        maxDeliveryFeeCar: 0,
        minDeliveryFeeMinibus: 15,
        maxDeliveryFeeMinibus: 0,
        minDeliveryFeeTukTuk: 15,
        maxDeliveryFeeTukTuk: 0,
        minDeliveryFeeMotorTricycle: 15,
        maxDeliveryFeeMotorTricycle: 0,
        minDeliveryFeeQuarterTruck: 15,
        maxDeliveryFeeQuarterTruck: 0,
        minDeliveryFeeHalfTruck: 15,
        maxDeliveryFeeHalfTruck: 0,
        customOrderPlatformFee: 10,
        defaultTaxRate: 14,
        maxDeliveryRadiusKm: 1500,
        minOrderKm: 0,
        minDistanceFixedPrice: 0,
        goldTierBonusPerOrder: 0,
        driverBonusActive: false,
        driverBonusAmount: 0,
        driverBonusPaidByCustomer: false,
        coinValue: 1,
        amountSpentPerCoin: 10,
        minCoinsToUse: 1,
        highValueOrderThreshold: 0,
        highValueUpfrontRate: 0,
        ...settingOverrides,
      };
      const checkout = new OrdersCheckoutService(
        { getDistanceKm: jest.fn().mockResolvedValue(10) } as any,
        {} as any,
        {
          getSettings: jest.fn().mockResolvedValue(settings),
          calculateCustomerDeliveryBreakdown: jest.fn(
            (distanceKm, zoneOverride, perKm, isStd, s, vehicleType) =>
              feeCalc.calculateCustomerDeliveryBreakdown(s ?? settings, {
                distanceKm,
                zoneBaseDeliveryFeeOverride: zoneOverride,
                perKmOverride: perKm,
                isStandardOrder: isStd,
                vehicleType,
              }),
          ),
        } as any,
        { emit: jest.fn() } as any,
        {
          customer: {
            findUnique: jest
              .fn()
              .mockResolvedValue({ id: 'cust-1', coinBalance: 0 }),
          },
        } as any,
        {} as any,
        {} as any,
      );
      return { checkout };
    }

    const baseDto = {
      paymentMethod: 'CASH_ON_DELIVERY' as const,
      pickupAddress: 'Pickup St',
      pickupLocation: [31.2357, 30.0444] as [number, number],
      deliveryAddress: 'Dropoff St',
      deliveryLocation: [31.2, 30.0111] as [number, number],
      itemDetails: 'Box',
    };

    it.each([
      [OrderType.RIDE, VehicleType.MOTORCYCLE, 45], // 15 + 10*3
      [OrderType.RIDE, VehicleType.CAR, 65], // 15 + 10*5
      [OrderType.RIDE, VehicleType.MINIBUS, 95], // 15 + 10*8
      [OrderType.RIDE, VehicleType.TUK_TUK, 55], // 15 + 10*4
      [OrderType.CUSTOM_DELIVERY, VehicleType.MOTORCYCLE, 45], // 15 + 10*3
      [OrderType.CUSTOM_DELIVERY, VehicleType.MOTOR_TRICYCLE, 55], // 15 + 10*4
      [OrderType.CUSTOM_DELIVERY, VehicleType.QUARTER_TRUCK, 95], // 15 + 10*8
      [OrderType.CUSTOM_DELIVERY, VehicleType.HALF_TRUCK, 135], // 15 + 10*12
    ])(
      'accepts %s with %s and computes expected deliveryFee=%d',
      async (type, vehicleType, expectedDeliveryFee) => {
        const { checkout } = buildCheckoutHarness();
        const estimate = await checkout.estimateCustomOrder(
          { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
          { ...baseDto, type, vehicleType },
        );
        expect(estimate.deliveryFee).toBe(expectedDeliveryFee);
      },
    );

    it.each([
      [OrderType.RIDE, VehicleType.BICYCLE],
      [OrderType.RIDE, VehicleType.MOTOR_TRICYCLE],
      [OrderType.RIDE, VehicleType.QUARTER_TRUCK],
      [OrderType.RIDE, VehicleType.HALF_TRUCK],
      [OrderType.CUSTOM_DELIVERY, VehicleType.BICYCLE],
      [OrderType.CUSTOM_DELIVERY, VehicleType.CAR],
      [OrderType.CUSTOM_DELIVERY, VehicleType.MINIBUS],
      [OrderType.CUSTOM_DELIVERY, VehicleType.TUK_TUK],
    ])(
      'rejects disallowed %s + %s pairing with VEHICLE_TYPE_NOT_ALLOWED_FOR_SERVICE',
      async (type, vehicleType) => {
        const { checkout } = buildCheckoutHarness();
        await expect(
          checkout.estimateCustomOrder(
            { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
            { ...baseDto, type, vehicleType },
          ),
        ).rejects.toThrow(OrderErrors.VEHICLE_TYPE_NOT_ALLOWED_FOR_SERVICE);
      },
    );

    it('rejects disabled Ride/Custom vehicle types with VEHICLE_TYPE_DISABLED', async () => {
      const { checkout } = buildCheckoutHarness({ allowTukTuk: false });
      await expect(
        checkout.estimateCustomOrder(
          { sub: 'u-cust-1', role: Role.CUSTOMER } as any,
          { ...baseDto, type: OrderType.RIDE, vehicleType: VehicleType.TUK_TUK },
        ),
      ).rejects.toThrow(OrderErrors.VEHICLE_TYPE_DISABLED);
    });
  });
});
