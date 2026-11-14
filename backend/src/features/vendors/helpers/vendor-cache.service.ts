import { Inject, Injectable } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';

const VENDOR_DETAILS_TTL_MS = 300000; // 5 mins

/**
 * Single owner of vendor detail cache key construction, reads/writes, and
 * invalidation across vendor services and background schedule workers.
 */
@Injectable()
export class VendorCacheService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {}

  async getOrSetVendorDetailsById(
    vendorId: string,
    loader: () => Promise<Record<string, unknown>>,
  ): Promise<Record<string, unknown>> {
    return this.getOrSet(`vendor_details_${vendorId}`, loader);
  }

  async getOrSetVendorDetailsBySlug(
    slug: string,
    loader: () => Promise<Record<string, unknown>>,
  ): Promise<Record<string, unknown>> {
    return this.getOrSet(`vendor_slug_details_${slug}`, loader);
  }

  private async getOrSet(
    cacheKey: string,
    loader: () => Promise<Record<string, unknown>>,
  ): Promise<Record<string, unknown>> {
    const cached = await this.cacheManager.get<Record<string, unknown>>(cacheKey);
    if (cached) return cached;

    const loaded = await loader();
    await this.cacheManager.set(cacheKey, loaded, VENDOR_DETAILS_TTL_MS);
    return loaded;
  }

  async invalidateVendorDetails(
    vendorId: string,
    knownSlug?: string | null,
  ): Promise<void> {
    await this.cacheManager.del(`vendor_details_${vendorId}`);

    let slug = knownSlug;
    if (!slug) {
      const vendor = await this.prisma.vendor.findUnique({
        where: { id: vendorId },
        select: { slug: true },
      });
      slug = vendor?.slug;
    }

    if (slug) {
      await this.cacheManager.del(`vendor_slug_details_${slug}`);
    }
  }

  async invalidateManyVendorDetails(vendorIds: string[]): Promise<void> {
    const uniqueIds = Array.from(new Set(vendorIds.filter(Boolean)));
    if (uniqueIds.length === 0) return;

    const vendors = await this.prisma.vendor.findMany({
      where: { id: { in: uniqueIds } },
      select: { id: true, slug: true },
    });
    const slugMap = new Map(vendors.map((v) => [v.id, v.slug]));

    await Promise.all(
      uniqueIds.flatMap((id) => {
        const keys = [`vendor_details_${id}`];
        const slug = slugMap.get(id);
        if (slug) keys.push(`vendor_slug_details_${slug}`);
        return keys.map((key) => this.cacheManager.del(key));
      }),
    );
  }
}
