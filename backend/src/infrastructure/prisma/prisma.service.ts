import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient, Prisma } from '@prisma/client';
import { ConfigService } from '@nestjs/config';

import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor(config: ConfigService) {
    const connectionString = config.getOrThrow<string>('DATABASE_URL');
    // Overallocated pools multiply across cluster instances (api + ws + worker),
    // so the per-process max must be tuned against the Postgres max_connections.
    const poolSize = config.get<number>('DB_POOL_SIZE') ?? 10;
    const pool = new Pool({
      connectionString,
      max: poolSize,
      idleTimeoutMillis: 30000, // how long a client is allowed to remain idle before being closed
      connectionTimeoutMillis: 5000, // return an error after 5 seconds if connection could not be established
    });
    const adapter = new PrismaPg(pool);
    super({ adapter });

    const modelsWithSoftDelete = Prisma.dmmf.datamodel.models
      .filter((model) => model.fields.some((f) => f.name === 'deletedAt'))
      .map((model) => model.name);

    const hasExplicitDeletedAt = (where: unknown): boolean =>
      typeof where === 'object' &&
      where !== null &&
      Object.prototype.hasOwnProperty.call(where, 'deletedAt');

    const withSoftDeleteFilter = (
      model: string,
      args: { where?: Record<string, unknown> },
    ) => {
      if (
        modelsWithSoftDelete.includes(model) &&
        !hasExplicitDeletedAt(args?.where)
      ) {
        args.where = { ...(args.where || {}), deletedAt: null };
      }
      return args;
    };

    const extended = this.$extends({
      query: {
        $allModels: {
          async findUnique({ model, args, query }) {
            return query(withSoftDeleteFilter(model, args as any) as any);
          },
          async findUniqueOrThrow({ model, args, query }) {
            return query(withSoftDeleteFilter(model, args as any) as any);
          },
          async findFirst({ model, args, query }) {
            return query(withSoftDeleteFilter(model, (args || {}) as any) as any);
          },
          async findFirstOrThrow({ model, args, query }) {
            return query(withSoftDeleteFilter(model, (args || {}) as any) as any);
          },
          async findMany({ model, args, query }) {
            return query(withSoftDeleteFilter(model, (args || {}) as any) as any);
          },
          async count({ model, args, query }) {
            const safeArgs = args || {};
            return query(withSoftDeleteFilter(model, safeArgs as any) as any);
          },
        },
      },
    });

    const extendedWithShutdown = extended as unknown as PrismaService;
    extendedWithShutdown.onModuleDestroy = async () => {
      await extended.$disconnect();
      await pool.end().catch(() => undefined);
    };

    return extendedWithShutdown as unknown as this;
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
