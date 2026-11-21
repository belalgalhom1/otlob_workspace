import { ForbiddenException } from '@nestjs/common';
import { OrderStatus, OrderType, Role } from '@prisma/client';
import { GeoPoint } from '../../common/geo/geo.utils';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { DriverTrackingService } from '../location/driver-tracking.service';
import {
  ComputedRouteResult,
  RoutingService,
} from '../location/routing.service';
import { OrdersService } from './orders.service';
import { OrderRouteService } from './order-route.service';

describe('OrderRouteService', () => {
  const storeA = { type: 'Point', coordinates: [31.2357, 30.0444] };
  const storeB = { type: 'Point', coordinates: [31.245, 30.05] };
  const dest = { type: 'Point', coordinates: [31.26, 30.065] };

  function makeActor(sub: string, role: Role): JwtAccessPayload {
    return { sub, role } as JwtAccessPayload;
  }

  function makeRoutingMock() {
    const computeRoute = jest.fn<
      Promise<ComputedRouteResult>,
      [readonly GeoPoint[]]
    >((waypoints) =>
      Promise.resolve({
        encodedPolyline: 'encoded-poly',
        coordinates: waypoints.map((p) => ({
          latitude: p.lat,
          longitude: p.lng,
        })),
        waypoints: waypoints.map((p) => ({
          latitude: p.lat,
          longitude: p.lng,
        })),
        distanceMeters: 2500,
        durationSeconds: 360,
        isRoadRoute: true,
        source: 'osrm',
      }),
    );
    return { computeRoute };
  }

  it('routes pending regular store order from store branch to delivery address before driver assignment', async () => {
    const ordersService = {
      getOne: jest.fn().mockResolvedValue({
        id: 'ord-1',
        type: OrderType.STANDARD,
        status: OrderStatus.PENDING,
        driverId: null,
        deliveryLocation: dest,
        vendorFulfillments: [
          {
            id: 'f-1',
            status: 'PENDING',
            vendorBranch: { location: storeA },
          },
        ],
      }),
    };
    const driverTracking = { getDriverLocationWithState: jest.fn() };
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      ordersService as unknown as OrdersService,
      driverTracking as unknown as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    const res = await service.getOrderRoute(
      makeActor('u-cust', Role.CUSTOMER),
      'ord-1',
    );

    expect(driverTracking.getDriverLocationWithState).not.toHaveBeenCalled();
    expect(routingService.computeRoute).toHaveBeenCalledWith([
      { lat: 30.0444, lng: 31.2357 },
      { lat: 30.065, lng: 31.26 },
    ]);
    expect(res.orderId).toBe('ord-1');
    expect(res.isRoadRoute).toBe(true);
    expect(res.driverLocation).toBeNull();
  });

  it('includes precision-masked live driver before unpicked store stops for customer viewer', async () => {
    const ordersService = {
      getOne: jest.fn().mockResolvedValue({
        id: 'ord-2',
        type: OrderType.STANDARD,
        status: OrderStatus.DRIVER_ASSIGNED,
        driverId: 'drv-1',
        deliveryLocation: dest,
        vendorFulfillments: [
          {
            id: 'f-2',
            stopSequence: 2,
            status: 'PREPARING',
            vendorBranch: { location: storeB },
          },
          {
            id: 'f-1',
            stopSequence: 1,
            status: 'READY_FOR_PICKUP',
            vendorBranch: { location: storeA },
          },
        ],
      }),
    };
    const driverTracking = {
      getDriverLocationWithState: jest.fn().mockResolvedValue({
        lat: 30.03,
        lng: 31.22,
      }),
    };
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      ordersService as unknown as OrdersService,
      driverTracking as unknown as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    const res = await service.getOrderRoute(
      makeActor('u-cust', Role.CUSTOMER),
      'ord-2',
    );

    expect(driverTracking.getDriverLocationWithState).toHaveBeenCalledWith(
      'drv-1',
      true,
    );
    expect(routingService.computeRoute).toHaveBeenCalledWith([
      { lat: 30.03, lng: 31.22 },
      { lat: 30.0444, lng: 31.2357 },
      { lat: 30.05, lng: 31.245 },
      { lat: 30.065, lng: 31.26 },
    ]);
    expect(res.driverLocation).toEqual({
      latitude: 30.03,
      longitude: 31.22,
    });
  });

  it('routes directly from live driver to customer after all fulfillments are picked up', async () => {
    const ordersService = {
      getOne: jest.fn().mockResolvedValue({
        id: 'ord-3',
        type: OrderType.STANDARD,
        status: OrderStatus.PICKED_UP,
        driverId: 'drv-1',
        deliveryLocation: dest,
        vendorFulfillments: [
          {
            id: 'f-1',
            status: 'PICKED_UP',
            vendorBranch: { location: storeA },
          },
        ],
      }),
    };
    const driverTracking = {
      getDriverLocationWithState: jest.fn().mockResolvedValue({
        lat: 30.055,
        lng: 31.252,
      }),
    };
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      ordersService as unknown as OrdersService,
      driverTracking as unknown as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    await service.getOrderRoute(makeActor('u-drv', Role.DRIVER), 'ord-3');

    expect(driverTracking.getDriverLocationWithState).toHaveBeenCalledWith(
      'drv-1',
      false,
    );
    expect(routingService.computeRoute).toHaveBeenCalledWith([
      { lat: 30.055, lng: 31.252 },
      { lat: 30.065, lng: 31.26 },
    ]);
  });

  it('supports RIDE / CUSTOM_DELIVERY pickupLocation before and after pickup', async () => {
    const pickup = { type: 'Point', coordinates: [31.23, 30.04] };
    const ordersService = {
      getOne: jest.fn().mockResolvedValue({
        id: 'ord-ride',
        type: OrderType.RIDE,
        status: OrderStatus.DRIVER_ASSIGNED,
        driverId: 'drv-ride',
        pickupLocation: pickup,
        deliveryLocation: dest,
        vendorFulfillments: [],
      }),
    };
    const driverTracking = {
      getDriverLocationWithState: jest.fn().mockResolvedValue({
        lat: 30.02,
        lng: 31.21,
      }),
    };
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      ordersService as unknown as OrdersService,
      driverTracking as unknown as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    await service.getOrderRoute(makeActor('u-cust', Role.CUSTOMER), 'ord-ride');

    expect(routingService.computeRoute).toHaveBeenCalledWith([
      { lat: 30.02, lng: 31.21 },
      { lat: 30.04, lng: 31.23 },
      { lat: 30.065, lng: 31.26 },
    ]);
  });

  it('propagates OrdersService authorization error without computing route', async () => {
    const ordersService = {
      getOne: jest.fn().mockRejectedValue(new ForbiddenException('denied')),
    };
    const driverTracking = { getDriverLocationWithState: jest.fn() };
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      ordersService as unknown as OrdersService,
      driverTracking as unknown as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    await expect(
      service.getOrderRoute(makeActor('other', Role.CUSTOMER), 'ord-x'),
    ).rejects.toThrow(ForbiddenException);
    expect(routingService.computeRoute).not.toHaveBeenCalled();
  });

  it('computes custom waypoint routes via POST DTO', async () => {
    const routingService = makeRoutingMock();
    const service = new OrderRouteService(
      {} as OrdersService,
      {} as DriverTrackingService,
      routingService as unknown as RoutingService,
    );

    const res = await service.computeCustomRoute({
      waypoints: [
        { latitude: 30.0444, longitude: 31.2357 },
        { latitude: 30.065, longitude: 31.26 },
      ],
    });

    expect(res.orderId).toBeNull();
    expect(res.isRoadRoute).toBe(true);
    expect(res.destination).toEqual({ latitude: 30.065, longitude: 31.26 });
  });
});
