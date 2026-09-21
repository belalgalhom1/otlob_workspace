import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { EVENTS } from '../events/event-names';

const WS = {
  PLATFORM_SETTINGS_UPDATED: 'platform.settings.updated',
} as const;

@Injectable()
export class SettingsListener {
  private readonly logger = new Logger(SettingsListener.name);

  constructor(private readonly socketService: SocketService) {}

  @OnEvent(EVENTS.SETTINGS_UPDATED)
  async handleSettingsUpdated() {
    try {
      await this.socketService.broadcast(WS.PLATFORM_SETTINGS_UPDATED, {
        updatedAt: new Date().toISOString(),
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to broadcast platform settings update: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }
}