import { Injectable } from '@nestjs/common';
import { OrderStatus, OrderType, Role } from '@prisma/client';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { GeoPoint } from '../../common/geo/geo.utils';
import { extractGeoPointFromUnknown } from '../../common/geo/polyline.utils';
import { DriverTrackingService } from '../location/driver-tracking.service';
import { RoutingService } from '../location/routing.service';
import { OrdersService } from './orders.service';
import {
  ComputeRouteDto,
  OrderRouteResponseDto,
  RouteCoordinateDto,
} from './dto/order-route.dto';

interface ProjectedBranchOrVendorView {
  location?: unknown;
}

interface ProjectedFulfillmentView {
  status?: string | null;
  stopSequence?: number | null;
  vendorBranch?: ProjectedBranchOrVendorView | null;
  vendor?: ProjectedBranchOrVendorView | null;
}

interface ProjectedDeliveryGroupView {
  status?: string | null;
  primaryDriverId?: string | null;
}

interface ProjectedOrderView {
  id?: string | null;
  type?: string | null;
  status?: string | null;
  driverId?: string | null;
  driver?: { id?: string | null } | null;
  deliveryGroups?: ProjectedDeliveryGroupView[] | null;
  deliveryLocation?: unknown;
  pickupLocation?: unknown;
  vendorBranch?: ProjectedBranchOrVendorView | null;
  vendorFulfillments?: ProjectedFulfillmentView[] | null;
}

const TERMINAL_STATUSES = new Set<string>([
  OrderStatus.DELIVERED,
  OrderStatus.CANCELLED,
]);

const PICKED_UP_FULFILLMENT_STATUSES = new Set<string>([
  'PICKED_UP',
  'DELIVERED',
]);

const DEAD_FULFILLMENT_STATUSES = new Set<string>(['REJECTED', 'CANCELLED']);

/**
 * Resolves canonical driving route polylines for orders and map previews.
 * Reuses [OrdersService.getOne] for authorization & role-scoped projections,
 * [DriverTrackingService] for role-compliant live driver coordinates, and
 * [RoutingService] for cached road-following geometry.
 */
@Injectable()
export class OrderRouteService {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly driverTracking: DriverTrackingService,
    private readonly routingService: RoutingService,
  ) {}

  async getOrderRoute(
    actor: JwtAccessPayload,
    orderId: string,
    includeDriver = true,
  ): Promise<OrderRouteResponseDto> {
    const order = (await this.ordersService.getOne(
      actor,
      orderId,
    )) as ProjectedOrderView;
    const status = String(order.status ?? '');
    const destination = extractGeoPointFromUnknown(order.deliveryLocation);

    const driverPoint =
      includeDriver && !TERMINAL_STATUSES.has(status)
        ? await this.resolveLiveDriverPoint(order, actor.role)
        : null;

    const pickupStops = this.resolveOrderedPickupStops(
      order,
      status,
      driverPoint !== null,
    );

    const orderedWaypoints: GeoPoint[] = [];
    if (driverPoint) orderedWaypoints.push(driverPoint);
    orderedWaypoints.push(...pickupStops);
    if (destination) orderedWaypoints.push(destination);

    const computed = await this.routingService.computeRoute(orderedWaypoints);

    return {
      orderId: String(order.id ?? orderId),
      orderStatus: status || null,
      encodedPolyline: computed.encodedPolyline,
      coordinates: computed.coordinates,
      waypoints: computed.waypoints,
      distanceMeters: computed.distanceMeters,
      durationSeconds: computed.durationSeconds,
      isRoadRoute: computed.isRoadRoute,
      source: computed.source,
      driverLocation: driverPoint ? this.toCoordinateDto(driverPoint) : null,
      destination: destination ? this.toCoordinateDto(destination) : null,
    };
  }

  async computeCustomRoute(
    dto: ComputeRouteDto,
  ): Promise<OrderRouteResponseDto> {
    const waypoints: GeoPoint[] = dto.waypoints.map((w) => ({
      lat: Number(w.latitude),
      lng: Number(w.longitude),
    }));
    const computed = await this.routingService.computeRoute(waypoints);
    const destination =
      waypoints.length > 0 ? waypoints[waypoints.length - 1] : null;

    return {
      orderId: null,
      orderStatus: null,
      encodedPolyline: computed.encodedPolyline,
      coordinates: computed.coordinates,
      waypoints: computed.waypoints,
      distanceMeters: computed.distanceMeters,
      durationSeconds: computed.durationSeconds,
      isRoadRoute: computed.isRoadRoute,
      source: computed.source,
      driverLocation: null,
      destination: destination ? this.toCoordinateDto(destination) : null,
    };
  }

  private async resolveLiveDriverPoint(
    order: ProjectedOrderView,
    actorRole: Role,
  ): Promise<GeoPoint | null> {
    const groups = Array.isArray(order.deliveryGroups)
      ? order.deliveryGroups
      : [];
    const driverId: string | null =
      order.driverId ??
      order.driver?.id ??
      groups.find((g) => g.status !== 'CANCELLED' && g.primaryDriverId)
        ?.primaryDriverId ??
      groups.find((g) => g.primaryDriverId)?.primaryDriverId ??
      null;

    if (!driverId) return null;

    const liveLoc = await this.driverTracking.getDriverLocationWithState(
      driverId,
      actorRole === Role.CUSTOMER,
    );
    if (!liveLoc) return null;

    return extractGeoPointFromUnknown({
      lat: liveLoc.lat,
      lng: liveLoc.lng,
    });
  }

  private resolveOrderedPickupStops(
    order: ProjectedOrderView,
    status: string,
    hasLiveDriver: boolean,
  ): GeoPoint[] {
    const fulfillments = Array.isArray(order.vendorFulfillments)
      ? order.vendorFulfillments
      : [];

    const activeFulfillments = fulfillments
      .filter((f) => !DEAD_FULFILLMENT_STATUSES.has(String(f.status ?? '')))
      .map((f, idx) => ({ f, idx }))
      .sort((a, b) => {
        const seqA = Number.isFinite(Number(a.f.stopSequence))
          ? Number(a.f.stopSequence)
          : Number.MAX_SAFE_INTEGER;
        const seqB = Number.isFinite(Number(b.f.stopSequence))
          ? Number(b.f.stopSequence)
          : Number.MAX_SAFE_INTEGER;
        if (seqA !== seqB) return seqA - seqB;
        return a.idx - b.idx;
      })
      .map((entry) => entry.f);

    if (activeFulfillments.length > 0) {
      const unpicked = activeFulfillments.filter(
        (f) => !PICKED_UP_FULFILLMENT_STATUSES.has(String(f.status ?? '')),
      );
      // Include all active stores when order is past pickup without a live driver
      // (or on completed views) so store -> delivery road geometry still renders.
      const stopsSource =
        unpicked.length > 0
          ? unpicked
          : !hasLiveDriver
            ? activeFulfillments
            : [];

      const points: GeoPoint[] = [];
      for (const f of stopsSource) {
        const loc = extractGeoPointFromUnknown(
          f.vendorBranch?.location ??
            f.vendor?.location ??
            order.vendorBranch?.location ??
            order.pickupLocation,
        );
        if (loc) points.push(loc);
      }
      if (points.length > 0) return points;
    }

    const orderType = String(order.type ?? '');
    const isCustomOrRide =
      orderType === OrderType.CUSTOM_DELIVERY || orderType === OrderType.RIDE;
    const isAlreadyPickedUp =
      status === OrderStatus.PICKED_UP || status === OrderStatus.DELIVERED;

    if (!isAlreadyPickedUp || !hasLiveDriver) {
      const fallbackPickup = extractGeoPointFromUnknown(
        isCustomOrRide
          ? (order.pickupLocation ?? order.vendorBranch?.location)
          : (order.vendorBranch?.location ?? order.pickupLocation),
      );
      if (fallbackPickup) return [fallbackPickup];
    }

    return [];
  }

  private toCoordinateDto(point: GeoPoint): RouteCoordinateDto {
    return {
      latitude: point.lat,
      longitude: point.lng,
    };
  }
}
