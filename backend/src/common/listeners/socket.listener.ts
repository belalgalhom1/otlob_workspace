import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { LocationRepository } from '../../infrastructure/location/location.repository';
import { SocketService } from '../../infrastructure/socket/socket.service';

@Injectable()
export class SocketListener {
  private readonly logger = new Logger(SocketListener.name);

  constructor(
    private readonly locationRepository: LocationRepository,
    private readonly socketService: SocketService,
  ) {}

  @OnEvent('ws.driver.location.update', { async: true })
  async handleDriverLocationUpdate(payload: {
    userId: string;
    location: [number, number];
  }) {
    try {
      await this.locationRepository.processLiveLocationUpdate(
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

  @OnEvent('ws.driver.disconnected', { async: true })
  async handleDriverDisconnected(payload: { userId: string }) {
    try {
      await this.locationRepository.handleUserDisconnect(payload.userId);
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(
          `Failed to handle driver disconnect via WS: ${err.message}`,
        );
      }
    }
  }

  @OnEvent('ws.driver.location.request', { async: true })
  async handleDriverLocationRequest(payload: {
    userId: string;
    orderId: string;
  }) {
    try {
      const location = await this.locationRepository.getOrderDriverLocation(
        payload.orderId,
        payload.userId,
      );
      if (!location) return;

      await this.socketService
        .emitToUser(payload.userId, 'driver.location', {
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
