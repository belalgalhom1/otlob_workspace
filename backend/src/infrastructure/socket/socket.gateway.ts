import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Inject, Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { JWT_ACCESS_SERVICE } from 'src/common/constants/jwt.constants';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SocketAuthService } from './socket-auth.service';
import { RedisService } from '../redis/redis.service';

@WebSocketGateway({
  namespace: 'events',
  cors: { origin: '*' },
  pingInterval: 10000,
  pingTimeout: 5000,
})
export class SocketGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(SocketGateway.name);

  constructor(
    @Inject(JWT_ACCESS_SERVICE)
    private readonly jwtService: JwtService,
    private readonly eventEmitter: EventEmitter2,
    private readonly socketAuthService: SocketAuthService,
    private readonly redis: RedisService,
  ) {}

  afterInit(server: Server) {
    server.use(async (socket: Socket, next) => {
      try {
        const authHeader = socket.handshake.headers?.authorization;
        const headerToken = authHeader?.startsWith('Bearer ')
          ? authHeader.slice(7)
          : authHeader;
        const token =
          (socket.handshake.auth?.token as string | undefined) ||
          (socket.handshake.query?.token as string | undefined) ||
          headerToken;

        if (!token) return next(new Error('Unauthorized'));

        const payload = this.jwtService.verify(token);

        if (!payload?.sub) return next(new Error('Unauthorized'));

        // Fast sub-millisecond check in Redis for banned users or revoked sessions
        const [isBanned, isRevokedSession, isRevokedUser] = await Promise.all([
          this.redis.get(`banned:user:${payload.sub}`),
          payload.sid ? this.redis.get(`revoked:session:${payload.sid}`) : null,
          this.redis.get(`revoked:user:${payload.sub}`),
        ]);

        if (isBanned || isRevokedSession || isRevokedUser) {
          return next(new Error('Unauthorized'));
        }

        // Enforce strict authorization rules based on user role and activity
        const isAuthorized = await this.socketAuthService.authorize(payload.sub, payload.role);
        if (!isAuthorized) {
          return next(new Error('Forbidden'));
        }

        socket.data.user = payload;
        const room = `user_${payload.sub}`;
        void socket.join(room);
        if (payload.sid) {
          void socket.join(`session_${payload.sid}`);
        }
        this.logger.debug(
          `User ${payload.sub} (session: ${payload.sid ?? 'none'}) authenticated and joined rooms`,
        );
        next();
      } catch (err) {
        if (err instanceof Error) {
          this.logger.warn(`WS auth failed: ${err.message}`);
        } else {
          this.logger.warn(`WS auth failed: ${String(err)}`);
        }
        next(new Error('Unauthorized'));
      }
    });
  }


  @SubscribeMessage('driver.location.update')
  handleDriverLocation(client: Socket, payload: { location: [number, number] }) {
    const user = client.data.user as { sub: string; role: string } | undefined;
    if (user?.role === 'DRIVER') {
      this.eventEmitter.emit('ws.driver.location.update', {
        userId: user.sub,
        location: payload.location,
      });
    }
  }

  handleConnection(client: Socket) {
    this.logger.log(
      `✅ Client Connected: ${(client.data.user as { sub: string } | undefined)?.sub} (${client.id})`,
    );
  }

  handleDisconnect(client: Socket) {
    const user = client.data.user as { sub: string; role: string } | undefined;
    this.logger.log(
      `❌ Client Disconnected: ${user?.sub ?? 'unknown'} (${client.id})`,
    );

    if (user?.role === 'DRIVER') {
      this.eventEmitter.emit('ws.driver.disconnected', {
        userId: user.sub,
      });
    }
  }
}
