import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
// @ts-ignore - The user will install this package on their VPS
import { Emitter } from '@socket.io/redis-emitter';

@Injectable()
export class SocketService implements OnModuleInit {
  private readonly logger = new Logger(SocketService.name);
  private emitter!: Emitter;

  constructor(private readonly redisService: RedisService) {}

  onModuleInit() {
    const redisClient = this.redisService.getClient();

    // The emitter calls `publish()` synchronously and DISCARDS the returned
    // promise. On a sustained Redis outage ioredis rejects that promise after
    // maxRetriesPerRequest, which surfaces as an unhandled rejection that no
    // caller's `.catch()` can ever see (the service used to return an already
    // resolved promise). Wrapping publish turns it into a logged error.
    const safeClient = {
      publish: (channel: string, message: string) => {
        try {
          const result = redisClient.publish(channel, message);
          if (result && typeof result.catch === 'function') {
            result.catch((error: unknown) => {
              this.logger.error(
                `Failed to publish socket message on ${channel}: ${
                  error instanceof Error ? error.message : String(error)
                }`,
              );
            });
          }
        } catch (error: unknown) {
          this.logger.error(
            `Failed to publish socket message on ${channel}: ${
              error instanceof Error ? error.message : String(error)
            }`,
          );
        }
      },
    };

    this.emitter = new Emitter(safeClient);
  }

  /**
   * The emitter throws synchronously for reserved event names; a caller's
   * `.catch()` would never see that. Keep every emit non-throwing.
   */
  private safely(action: () => void): void {
    try {
      action();
    } catch (error: unknown) {
      this.logger.error(
        `Failed to emit socket message: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  emitToUser(userId: string, event: string, data: unknown): Promise<void> {
    this.logger.debug(`Emitting ${event} to user_${userId}`);
    this.safely(() =>
      this.emitter.of('/events').to(`user_${userId}`).emit(event, data),
    );
    return Promise.resolve();
  }

  emitToRoom(room: string, event: string, data: unknown): Promise<void> {
    this.safely(() => this.emitter.of('/events').to(room).emit(event, data));
    return Promise.resolve();
  }

  broadcast(event: string, data: unknown): Promise<void> {
    this.safely(() => this.emitter.of('/events').emit(event, data));
    return Promise.resolve();
  }

  emitToSocket(socketId: string, event: string, data: unknown): Promise<void> {
    this.safely(() =>
      this.emitter.of('/events').to(socketId).emit(event, data),
    );
    return Promise.resolve();
  }

  joinRoom(socketId: string, room: string): Promise<void> {
    this.safely(() =>
      this.emitter.of('/events').in(socketId).socketsJoin(room),
    );
    return Promise.resolve();
  }

  leaveRoom(socketId: string, room: string): Promise<void> {
    this.safely(() =>
      this.emitter.of('/events').in(socketId).socketsLeave(room),
    );
    return Promise.resolve();
  }

  disconnectRoom(room: string): Promise<void> {
    this.safely(() =>
      this.emitter.of('/events').in(room).disconnectSockets(true),
    );
    return Promise.resolve();
  }

  disconnectUser(userId: string): Promise<void> {
    return this.disconnectRoom(`user_${userId}`);
  }

  disconnectSession(sessionId: string): Promise<void> {
    return this.disconnectRoom(`session_${sessionId}`);
  }
}
