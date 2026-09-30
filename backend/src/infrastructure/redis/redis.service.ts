import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import Redis, { Cluster } from 'ioredis';
import { ConfigService } from '@nestjs/config';
import { parseRedisConfig } from './redis.parser';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client!: Redis | Cluster;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const { urls, isCluster } = parseRedisConfig(this.config);

    const retryStrategy = (times: number) => Math.min(times * 50, 2000);

    if (isCluster) {
      this.logger.log('Initializing Redis in Cluster Mode');
      this.client = new Redis.Cluster(urls, {
        clusterRetryStrategy: retryStrategy,
        redisOptions: {},
        lazyConnect: true,
      });
    } else {
      this.client = new Redis(urls[0], {
        lazyConnect: true,
        retryStrategy,
      });
    }

    this.client.on('connect', () =>
      this.logger.log('✅ Redis connection established'),
    );

    this.client.on('ready', () =>
      this.logger.log('🚀 Redis is ready to accept commands'),
    );

    this.client.on('reconnecting', () =>
      this.logger.warn('🔄 Redis reconnecting...'),
    );

    this.client.on('close', () =>
      this.logger.warn('🔌 Redis connection closed'),
    );

    this.client.on('error', (err: Error) =>
      this.logger.error(`❌ Redis error: ${err.message}`, err.stack),
    );
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client) {
      this.logger.warn('Redis connection closing...');
      await this.client.quit();
      this.logger.log('Redis connection closed');
    }
  }

  getClient(): Redis | Cluster {
    return this.client;
  }

  async set(key: string, value: string, ttl: number): Promise<void> {
    try {
      await this.client.set(key, value, 'EX', ttl);
    } catch (error) {
      this.logger.error(`Failed to SET key "${key}"`, (error as Error).stack);
      throw error;
    }
  }

  async setNX(key: string, value: string, ttl: number): Promise<boolean> {
    try {
      const res = await this.client.set(key, value, 'EX', ttl, 'NX');
      return res === 'OK';
    } catch (error) {
      this.logger.error(`Failed to SETNX key "${key}"`, (error as Error).stack);
      throw error;
    }
  }

  async get(key: string): Promise<string | null> {
    try {
      return await this.client.get(key);
    } catch (error) {
      this.logger.error(`Failed to GET key "${key}"`, (error as Error).stack);
      return null;
    }
  }

  async del(...keys: string[]): Promise<void> {
    try {
      await this.client.del(...keys);
    } catch (error) {
      this.logger.error(
        `Failed to DEL keys "${keys.join(', ')}"`,
        (error as Error).stack,
      );
    }
  }

  /**
   * Atomically return the value of `key` and remove it (Redis GETDEL).
   * Safe for cross-process coordination (e.g. claiming a session exactly once
   * across cluster workers) even when Redis < 6.2 lacks native GETDEL.
   * Returns null when the key does not exist.
   */
  async getdel(key: string): Promise<string | null> {
    const script = `
      local v = redis.call('GET', KEYS[1])
      if v then
        redis.call('DEL', KEYS[1])
      end
      return v
    `;
    try {
      return (await this.client.eval(script, 1, key)) as string | null;
    } catch (error) {
      this.logger.error(
        `Failed to GETDEL key "${key}"`,
        (error as Error).stack,
      );
      return null;
    }
  }

  async incr(key: string): Promise<number> {
    try {
      return await this.client.incr(key);
    } catch (error) {
      this.logger.error(`Failed to INCR key "${key}"`, (error as Error).stack);
      return 0;
    }
  }

  async expire(key: string, ttl: number): Promise<void> {
    try {
      await this.client.expire(key, ttl);
    } catch (error) {
      this.logger.error(
        `Failed to EXPIRE key "${key}"`,
        (error as Error).stack,
      );
    }
  }

  /**
   * Atomic fixed-window counter: INCR + EXPIRE-on-first-hit in one Lua call.
   * Returns the number of hits in the current window (1 for the first).
   */
  async incrementWindow(key: string, ttlSeconds: number): Promise<number> {
    const script = `
      local c = redis.call('INCR', KEYS[1])
      if c == 1 then
        redis.call('EXPIRE', KEYS[1], ARGV[1])
      end
      return c
    `;
    try {
      return (await this.client.eval(script, 1, key, ttlSeconds)) as number;
    } catch (error) {
      this.logger.error(
        `Failed to INCR window for key "${key}"`,
        (error as Error).stack,
      );
      return 0;
    }
  }

  async exists(...keys: string[]): Promise<boolean> {
    try {
      const count = await this.client.exists(...keys);
      return count > 0;
    } catch (error) {
      this.logger.error(
        `Failed to check EXISTS for keys "${keys.join(', ')}"`,
        (error as Error).stack,
      );
      return false;
    }
  }

  async ttl(key: string): Promise<number> {
    try {
      return await this.client.ttl(key);
    } catch (error) {
      this.logger.error(
        `Failed to get TTL for key "${key}"`,
        (error as Error).stack,
      );
      return -2;
    }
  }

  async geoadd(
    key: string,
    lng: number,
    lat: number,
    member: string,
  ): Promise<void> {
    try {
      await this.client.geoadd(key, lng, lat, member);
    } catch (error) {
      this.logger.error(
        `Failed to GEOADD for key "${key}"`,
        (error as Error).stack,
      );
      throw error;
    }
  }

  async georadius(
    key: string,
    lng: number,
    lat: number,
    radiusKm: number,
    count?: number,
  ): Promise<Array<{ member: string; distanceKm: number }>> {
    try {
      const results = await this.client.georadius(
        key,
        lng,
        lat,
        radiusKm,
        'km',
        'WITHDIST',
        ...(count ? (['COUNT', count, 'ASC'] as const) : (['ASC'] as const)),
      );
      return (results as any[]).map((r) => ({
        member: r[0],
        distanceKm: parseFloat(r[1]),
      }));
    } catch (error) {
      this.logger.error(
        `Failed to GEORADIUS for key "${key}"`,
        (error as Error).stack,
      );
      return [];
    }
  }

  async zrem(key: string, member: string): Promise<void> {
    try {
      await this.client.zrem(key, member);
    } catch (error) {
      this.logger.error(
        `Failed to ZREM member from key "${key}"`,
        (error as Error).stack,
      );
    }
  }

  /**
   * Remove multiple members from a sorted set in a single call (ZREM varargs).
   */
  async zremMembers(key: string, members: string[]): Promise<number> {
    if (members.length === 0) return 0;
    try {
      return await this.client.zrem(key, ...members);
    } catch (error) {
      this.logger.error(
        `Failed to ZREM members from key "${key}"`,
        (error as Error).stack,
      );
      return 0;
    }
  }

  /**
   * All member names of a sorted set within [start, stop] (ZRANGE).
   */
  async zrange(key: string, start = 0, stop = -1): Promise<string[]> {
    try {
      return await this.client.zrange(key, start, stop);
    } catch (error) {
      this.logger.error(
        `Failed to ZRANGE key "${key}"`,
        (error as Error).stack,
      );
      return [];
    }
  }

  async geopos(
    key: string,
    member: string,
  ): Promise<{ lng: number; lat: number } | null> {
    try {
      const pos = await this.client.geopos(key, member);
      if (pos && pos[0]) {
        return {
          lng: parseFloat(pos[0][0]),
          lat: parseFloat(pos[0][1]),
        };
      }
      return null;
    } catch (error) {
      this.logger.error(
        `Failed to GEOPOS for key "${key}"`,
        (error as Error).stack,
      );
      return null;
    }
  }

  async sadd(key: string, ...members: string[]): Promise<number> {
    try {
      return await this.client.sadd(key, ...members);
    } catch (error) {
      this.logger.error(
        `Failed to SADD to key "${key}"`,
        (error as Error).stack,
      );
      return 0;
    }
  }

  async scard(key: string): Promise<number> {
    try {
      return await this.client.scard(key);
    } catch (error) {
      this.logger.error(`Failed to SCARD key "${key}"`, (error as Error).stack);
      return 0;
    }
  }

  async smembers(key: string): Promise<string[]> {
    try {
      return await this.client.smembers(key);
    } catch (error) {
      this.logger.error(
        `Failed to SMEMBERS key "${key}"`,
        (error as Error).stack,
      );
      return [];
    }
  }

  async srem(key: string, ...members: string[]): Promise<number> {
    try {
      return await this.client.srem(key, ...members);
    } catch (error) {
      this.logger.error(
        `Failed to SREM from key "${key}"`,
        (error as Error).stack,
      );
      return 0;
    }
  }

  async sismember(key: string, member: string): Promise<boolean> {
    try {
      const res = await this.client.sismember(key, member);
      return res === 1;
    } catch (error) {
      this.logger.error(
        `Failed to SISMEMBER key "${key}"`,
        (error as Error).stack,
      );
      return false;
    }
  }
}
