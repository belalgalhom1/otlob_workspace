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
  async handleDriverLocation(client: Socket, payload: { location?: unknown }) {
    const user = client.data.user as { sub: string; role: string } | undefined;
    if (user?.role !== 'DRIVER') return;

    const location = payload?.location;
    if (!Array.isArray(location) || location.length !== 2) return;

    const [lng, lat] = location as [unknown, unknown];
    if (
      typeof lng !== 'number' ||
      typeof lat !== 'number' ||
      !Number.isFinite(lng) ||
      !Number.isFinite(lat) ||
      lng < -180 ||
      lng > 180 ||
      lat < -90 ||
      lat > 90
    ) {
      return;
    }

    // Throttle to at most one update per second per socket to protect the
    // Redis geo pool and downstream broadcast fan-out.
    const now = Date.now();
    const lastAt = (client.data.lastLocationAt as number | undefined) ?? 0;
    if (now - lastAt < 1000) return;
    client.data.lastLocationAt = now;

    // Distributed guard against abusive/rogue clients that re-open sockets to
    // bypass the per-socket throttle. The per-socket gate caps a healthy driver
    // at ~1 update/s, so the window limit carries generous headroom (3+ sockets
    // incl. reconnect overlaps) and never trips legitimate traffic, while still
    // throttling reconnect-spamming clients.
    const count = await this.redis.incrementWindow(
      `ratelimit:driver-location:${user.sub}`,
      10,
    );
    if (count > 30) return;

    this.eventEmitter.emit('ws.driver.location.update', {
      userId: user.sub,
      location: [lng, lat],
    });
  }

  @SubscribeMessage('driver.location.request')
  handleDriverLocationRequest(client: Socket, payload: { orderId?: unknown }) {
    const user = client.data.user as { sub: string; role: string } | undefined;
    if (!user?.sub) return;

    const orderId = payload?.orderId;
    if (typeof orderId !== 'string' || orderId.length === 0) return;

    // Bound on-demand lookups: each socket may ask at most once per second.
    // Prevents reconnect storms / app reopenings from hammering the DB.
    const now = Date.now();
    const lastRequestAt =
      (client.data.lastLocationRequestAt as number | undefined) ?? 0;
    if (now - lastRequestAt < 1000) return;
    client.data.lastLocationRequestAt = now;

    this.eventEmitter.emit('ws.driver.location.request', {
      userId: user.sub,
      orderId,
    });
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
