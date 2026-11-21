import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { EVENTS } from '../events/event-names';
import { WS_EVENTS } from '../events/ws-events';
import { DriverLocationUpdatedEvent } from '../events';
import { DriverTrackingService } from '../../features/location/driver-tracking.service';
import { SocketService } from '../../infrastructure/socket/socket.service';

@Injectable()
export class SocketListener {
  private readonly logger = new Logger(SocketListener.name);

  constructor(
    private readonly driverTracking: DriverTrackingService,
    private readonly socketService: SocketService,
  ) {}

  @OnEvent(EVENTS.WS_DRIVER_LOCATION_UPDATE, { async: true })
  async handleDriverLocationUpdate(payload: {
    userId: string;
    location: [number, number];
  }) {
    try {
      await this.driverTracking.processLiveLocationUpdate(
        payload.userId,
        payload.location[0],
        payload.location[1],
      );
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(
          `Failed to update driver location via WS: ${err.message}`,
        );
      }
    }
  }

  /**
   * Broadcast live driver coordinates from the WS process (as well as monolith
   * mode via ListenersModule) so customers and admin live-tracking rooms receive
   * updates without requiring heavy queue listeners in WsModule.
   */
  @OnEvent(EVENTS.DRIVER_LOCATION_UPDATED)
  handleLocationUpdated(event: DriverLocationUpdatedEvent) {
    const payload = {
      driverId: event.driverId,
      longitude: event.longitude,
      latitude: event.latitude,
      timestamp: new Date().toISOString(),
    };

    if (event.activeOrderId && event.customerUserId) {
      this.socketService
        .emitToUser(event.customerUserId, WS_EVENTS.DRIVER_LOCATION, {
          ...payload,
          orderId: event.activeOrderId,
        })
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit driver location: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }

    this.socketService
      .emitToRoom(`driver_${event.driverId}`, WS_EVENTS.DRIVER_LOCATION, {
        ...payload,
        orderId: event.activeOrderId,
      })
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to emit driver room location: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
  }

  @OnEvent(EVENTS.WS_DRIVER_DISCONNECTED, { async: true })
  async handleDriverDisconnected(payload: { userId: string }) {
    try {
      await this.driverTracking.handleUserDisconnect(payload.userId);
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(
          `Failed to handle driver disconnect via WS: ${err.message}`,
        );
      }
    }
  }

  @OnEvent(EVENTS.WS_DRIVER_LOCATION_REQUEST, { async: true })
  async handleDriverLocationRequest(payload: {
    userId: string;
    orderId: string;
  }) {
    try {
      const location = await this.driverTracking.getOrderDriverLocation(
        payload.orderId,
        payload.userId,
      );
      if (!location) return;

      await this.socketService
        .emitToUser(payload.userId, WS_EVENTS.DRIVER_LOCATION, {
          orderId: payload.orderId,
          longitude: location.lng,
          latitude: location.lat,
          timestamp: new Date().toISOString(),
        })
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit initial driver location for order ${payload.orderId}: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(
          `Failed to handle driver location request: ${err.message}`,
        );
      }
    }
  }
}
