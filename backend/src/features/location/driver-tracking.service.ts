import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriverStatus } from '@prisma/client';
import { DriverLocationUpdatedEvent } from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { applyPrecisionReduction } from '../../common/geo/geo.utils';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from './location.repository';

const USER_DRIVER_MAP_TTL_SECS = 12 * 60 * 60;
const ACTIVE_ORDER_CACHE_TTL_SECS = 12 * 60 * 60;

export interface ActiveOrderTrackingEntry {
  orderId: string;
  customerUserId: string;
}

/**
 * Domain service owning live driver location presence, socket disconnect
 * eviction policy, active-order location fan-out, and customer privacy masking.
 */
@Injectable()
export class DriverTrackingService {
  private readonly logger = new Logger(DriverTrackingService.name);

  constructor(
    private readonly locationRepository: LocationRepository,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async processLiveLocationUpdate(
    userId: string,
    lng: number,
    lat: number,
  ): Promise<void> {
    let driverId = await this.locationRepository.getCachedUserDriverId(userId);
    if (!driverId) {
      const driver = await this.locationRepository.findDriverByUserId(userId);
      if (!driver) return;
      driverId = driver.id;
      await this.locationRepository.cacheUserDriverId(
        userId,
        driverId,
        USER_DRIVER_MAP_TTL_SECS,
      );
    }

    await this.trackDriverLocation(driverId, lng, lat);

    const activeOrderRaw =
      await this.locationRepository.getCachedDriverActiveOrderRaw(driverId);
    if (!activeOrderRaw) {
      // No active order: still emit so admin live-tracking map can follow the driver
      this.eventEmitter.emit(
        EVENTS.DRIVER_LOCATION_UPDATED,
        new DriverLocationUpdatedEvent(driverId, userId, lng, lat, null, null),
      );
      return;
    }

    const activeOrder = JSON.parse(activeOrderRaw);
    const activeList: Array<{ orderId: string; customerUserId: string }> =
      Array.isArray(activeOrder?.orders) && activeOrder.orders.length > 0
        ? activeOrder.orders
        : activeOrder?.orderId
          ? [
              {
                orderId: activeOrder.orderId,
                customerUserId: activeOrder.customerUserId,
              },
            ]
          : [];

    for (const entry of activeList) {
      if (!entry?.orderId) continue;
      this.eventEmitter.emit(
        EVENTS.DRIVER_LOCATION_UPDATED,
        new DriverLocationUpdatedEvent(
          driverId,
          userId,
          lng,
          lat,
          entry.orderId,
          entry.customerUserId,
        ),
      );
    }
  }

  async handleUserDisconnect(userId: string): Promise<void> {
    const driver = await this.locationRepository.findDriverByUserId(userId);
    if (!driver) return;

    // Preserve ONLINE/ON_DELIVERY drivers across transient socket drops;
    // they still receive dispatches via FCM push & HTTP polling.
    if (
      driver.status === DriverStatus.ONLINE ||
      driver.status === DriverStatus.ON_DELIVERY
    ) {
      this.logger.debug(
        `Driver ${driver.id} socket disconnected, but driver is ${driver.status}. Preserving location in active pool.`,
      );
      return;
    }

    await this.locationRepository.removeDriverLocation(driver.id);
    this.logger.debug(
      `Removed driver ${driver.id} (${driver.status}) from active location pool due to disconnect`,
    );
  }

  async trackDriverLocation(
    driverId: string,
    lng: number,
    lat: number,
  ): Promise<void> {
    const settings = await this.platformSettings.getSettings();
    // Freshness TTL must comfortably exceed the driver app's slowest stationary
    // heartbeat so idle drivers aren't misclassified as stale.
    const ttlSecs = Number(settings.driverLocationFreshnessTtlSecs ?? 30);
    await this.locationRepository.upsertDriverGeoPoint(
      driverId,
      lng,
      lat,
      ttlSecs,
    );
  }

  async getDriverLocation(
    driverId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    return this.locationRepository.getDriverLocation(driverId);
  }

  async removeDriverLocation(driverId: string): Promise<void> {
    await this.locationRepository.removeDriverLocation(driverId);
  }

  async getLiveDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number; isFresh: boolean }>> {
    return this.locationRepository.getLiveDriverLocations(driverIds);
  }

  async getPersistedDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number }>> {
    return this.locationRepository.getPersistedDriverLocations(driverIds);
  }

  async getDriverLocationWithState(
    driverId: string,
    isCustomerFacing: boolean = false,
  ): Promise<{ lng: number; lat: number; isLive: boolean } | null> {
    const settings = await this.platformSettings.getSettings();
    const precisionMeters = isCustomerFacing
      ? Number(settings.driverLocationPrecisionMeters ?? 0)
      : 0;

    const live = await this.locationRepository.getDriverLocation(driverId);
    if (live) {
      const isFresh =
        await this.locationRepository.isDriverLocationFresh(driverId);
      const reduced = applyPrecisionReduction(
        live.lng,
        live.lat,
        precisionMeters,
      );
      return { ...reduced, isLive: isFresh };
    }

    const map = await this.locationRepository.getPersistedDriverLocations([
      driverId,
    ]);
    const persisted = map.get(driverId);
    if (persisted) {
      const reduced = applyPrecisionReduction(
        persisted.lng,
        persisted.lat,
        precisionMeters,
      );
      return { ...reduced, isLive: false };
    }

    return null;
  }

  async getDriverActiveOrder(
    driverId: string,
  ): Promise<{ orderId: string } | null> {
    const raw =
      await this.locationRepository.getCachedDriverActiveOrderRaw(driverId);
    if (!raw) return null;
    try {
      const parsed = JSON.parse(raw);
      return parsed?.orderId ? { orderId: parsed.orderId } : null;
    } catch {
      return null;
    }
  }

  async syncDriverActiveOrders(
    driverId: string,
    activeOrders: ActiveOrderTrackingEntry[],
  ): Promise<void> {
    if (activeOrders.length > 0) {
      await this.locationRepository.setCachedDriverActiveOrderRaw(
        driverId,
        JSON.stringify({
          orderId: activeOrders[0].orderId,
          customerUserId: activeOrders[0].customerUserId,
          orders: activeOrders,
        }),
        ACTIVE_ORDER_CACHE_TTL_SECS,
      );
    } else {
      await this.locationRepository.clearCachedDriverActiveOrder(driverId);
    }
  }

  async getOrderDriverLocation(
    orderId: string,
    customerUserId: string,
  ): Promise<{ lng: number; lat: number } | null> {
    const settings = await this.platformSettings.getSettings();
    const precisionMeters = Number(settings.driverLocationPrecisionMeters ?? 0);

    const row =
      await this.locationRepository.queryOrderDriverLocationSnapshot(orderId);
    if (!row || row.customerUserId !== customerUserId || !row.driverId) {
      return null;
    }

    const live = await this.locationRepository.getDriverLocation(row.driverId);
    if (
      live &&
      (await this.locationRepository.isDriverLocationFresh(row.driverId))
    ) {
      return applyPrecisionReduction(live.lng, live.lat, precisionMeters);
    }

    if (row.lastLng != null && row.lastLat != null) {
      return applyPrecisionReduction(row.lastLng, row.lastLat, precisionMeters);
    }

    return null;
  }
}
