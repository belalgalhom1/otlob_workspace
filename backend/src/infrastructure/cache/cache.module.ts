import {
  Module,
  Global,
  Logger,
  OnApplicationShutdown,
} from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { ConfigService } from '@nestjs/config';
import { createCluster, createKeyv } from '@keyv/redis';
import { parseRedisConfig } from '../redis/redis.parser';

const cacheLogger = new Logger('AppCacheModule');
let cacheKeyvStore: ReturnType<typeof createKeyv> | null = null;

@Global()
@Module({
  imports: [
    CacheModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const { urls, isCluster } = parseRedisConfig(config);

        const connectTarget = isCluster
          ? (createCluster({
              rootNodes: urls.map((url) => ({ url })),
            }) as unknown as Parameters<typeof createKeyv>[0])
          : urls[0];

        const keyv = createKeyv(connectTarget, {
          throwOnConnectError: false,
          throwOnErrors: false,
        });
        keyv.on('error', (err: unknown) => {
          const message = err instanceof Error ? err.message : String(err);
          cacheLogger.error(`Cache Redis error: ${message}`);
        });
        cacheKeyvStore = keyv;

        return {
          stores: [keyv],
          ttl: 600000,
        };
      },
    }),
  ],
  exports: [CacheModule],
})
export class AppCacheModule implements OnApplicationShutdown {
  async onApplicationShutdown() {
    if (cacheKeyvStore) {
      await cacheKeyvStore.disconnect().catch(() => undefined);
      cacheKeyvStore = null;
    }
  }
}
