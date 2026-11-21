import { Injectable, Logger } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import {
  DispatchStatus,
  OrderType,
  Prisma,
} from '@prisma/client';
import { OrderSearchSnapshotRecord } from './dispatch-search.types';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

export interface DispatchCandidateOffer {
  driverId: string;
  userId: string;
  driverShiftId: string | null;
  deliveryGroupId: string;
  distanceKm: number;
  estimatedEarnings: number;
  pickupLocationName?: string;
  dropoffLocationName?: string;
  pickupLocationLogo?: string | null;
  dropoffCustomerAvatar?: string | null;
  isStacked: boolean;
}

export interface DispatchBroadcastPayload {
  dispatchId: string;
  orderId: string;
  deliveryGroupId: string;
  type: OrderType;
  requestedVehicleType?: string | null;
  candidates: DispatchCandidateOffer[];
  expiresAt: string;
  pickupLocationName?: string;
  dropoffLocationName?: string;
  pickupLocationLogo?: string | null;
  dropoffCustomerAvatar?: string | null;
}

export interface DispatchRetryState {
  attempt: number;
  excludeDriverIds: string[];
}

type QueryClient = Prisma.TransactionClient | PrismaService;

/**
 * Canonical repository owning Redis live-dispatch keys (claims, broadcast
 * payloads, retry counters, rejection sets, handoff dedupe) and `OrderDispatch`
 * terminal persistence.
 */
@Injectable()
export class DispatchRepository {
  private readonly logger = new Logger(DispatchRepository.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  // ─── Key builders (single source of truth) ────────────────────────────────

  private broadcastKey(dispatchId: string): string {
    return `otlobegy:dispatch:${dispatchId}`;
  }

  private rejectedSetKey(dispatchId: string): string {
    return `otlobegy:dispatch:${dispatchId}:rejected`;
  }

  private activeClaimKey(scope: string): string {
    return `otlobegy:order-dispatch-active:${scope}`;
  }

  private dispatchStateKey(scope: string): string {
    return `otlobegy:dispatch-state:${scope}`;
  }

  private driverPendingKey(driverId: string): string {
    return `otlobegy:driver-pending-dispatches:${driverId}`;
  }

  private handoffDedupeKey(orderId: string, scope: string): string {
    return `otlobegy:dispatch-handoff:${orderId}:${scope}`;
  }

  private searchStatusKey(orderId: string): string {
    return `otlobegy:order-search-status:${orderId}`;
  }

  // ─── Broadcast payloads & single-flight claims ───────────────────────────

  async saveBroadcast(
    dispatchId: string,
    payload: DispatchBroadcastPayload,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.set(
      this.broadcastKey(dispatchId),
      JSON.stringify(payload),
      ttlSecs,
    );
  }

  async getBroadcast(
    dispatchId: string,
  ): Promise<DispatchBroadcastPayload | null> {
    const raw = await this.redis.get(this.broadcastKey(dispatchId));
    if (!raw) return null;
    try {
      return JSON.parse(raw) as DispatchBroadcastPayload;
    } catch {
      return null;
    }
  }

  async deleteBroadcast(dispatchId: string): Promise<void> {
    await this.redis.del(this.broadcastKey(dispatchId));
  }

  async acquireActiveClaim(
    scope: string,
    dispatchId: string,
    ttlSecs: number,
  ): Promise<boolean> {
    return this.redis.setNX(this.activeClaimKey(scope), dispatchId, ttlSecs);
  }

  async getActiveClaim(scope: string): Promise<string | null> {
    return this.redis.get(this.activeClaimKey(scope));
  }

  async releaseActiveClaim(
    scope: string,
    dispatchId: string,
  ): Promise<boolean> {
    return this.redis.delIfValue(this.activeClaimKey(scope), dispatchId);
  }

  /**
   * Release a stale active-dispatch claim whose payload is missing, invalid, or
   * past `expiresAt` (for crash recovery in stuck-order monitor).
   */
  async clearStaleDispatchClaim(scopeId: string): Promise<void> {
    try {
      const key = this.activeClaimKey(scopeId);
      const activeDispatchId = await this.redis.get(key);
      if (!activeDispatchId) return;

      const raw = await this.redis.get(this.broadcastKey(activeDispatchId));
      let stale = false;
      if (!raw) {
        stale = true;
      } else {
        try {
          const payload = JSON.parse(raw) as { expiresAt?: string };
          stale =
            !payload.expiresAt ||
            Date.now() > new Date(payload.expiresAt).getTime();
        } catch {
          stale = true;
        }
      }

      if (stale) {
        const removed = await this.redis.delIfValue(key, activeDispatchId);
        if (removed) {
          this.logger.warn(`Cleared stale dispatch claim for scope ${scopeId}`);
        } else {
          this.logger.debug(
            `Stale claim for ${scopeId} was superseded before clearing`,
          );
        }
      }
    } catch (err) {
      this.logger.warn(
        `Failed to clear stale dispatch claim for ${scopeId}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }

  // ─── Attempt/retry state ─────────────────────────────────────────────────

  async saveDispatchState(
    scope: string,
    state: DispatchRetryState,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.set(
      this.dispatchStateKey(scope),
      JSON.stringify(state),
      ttlSecs,
    );
  }

  async readDispatchState(scopeId: string): Promise<DispatchRetryState> {
    try {
      const raw = await this.redis.get(this.dispatchStateKey(scopeId));
      if (!raw) return { attempt: 1, excludeDriverIds: [] };
      const state = JSON.parse(raw) as {
        attempt?: number;
        excludeDriverIds?: string[];
      };
      return {
        attempt: Number(state.attempt) || 1,
        excludeDriverIds: Array.isArray(state.excludeDriverIds)
          ? state.excludeDriverIds
          : [],
      };
    } catch {
      return { attempt: 1, excludeDriverIds: [] };
    }
  }

  async deleteDispatchState(scope: string): Promise<void> {
    await this.redis.del(this.dispatchStateKey(scope));
  }

  // ─── Handoff idempotency ─────────────────────────────────────────────────

  async isHandoffDeduped(orderId: string, scope: string): Promise<boolean> {
    return Boolean(await this.redis.get(this.handoffDedupeKey(orderId, scope)));
  }

  async markHandoffDeduped(
    orderId: string,
    scope: string,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.set(this.handoffDedupeKey(orderId, scope), '1', ttlSecs);
  }

  async clearHandoffDedupe(orderId: string, scope: string): Promise<void> {
    await this.redis.del(this.handoffDedupeKey(orderId, scope));
  }

  // ─── Customer live search status snapshots ───────────────────────────────

  async saveSearchSnapshot(
    orderId: string,
    snapshot: OrderSearchSnapshotRecord,
    ttlSecs = 1800,
  ): Promise<void> {
    await this.redis.set(
      this.searchStatusKey(orderId),
      JSON.stringify(snapshot),
      ttlSecs,
    );
  }

  async getSearchSnapshot(
    orderId: string,
  ): Promise<OrderSearchSnapshotRecord | null> {
    const raw = await this.redis.get(this.searchStatusKey(orderId));
    if (!raw) return null;
    try {
      return JSON.parse(raw) as OrderSearchSnapshotRecord;
    } catch {
      return null;
    }
  }

  async clearForRetry(orderId: string, scopes: string[]): Promise<void> {
    await Promise.all([
      this.redis.del(this.searchStatusKey(orderId)),
      ...scopes.flatMap((scope) => [
        this.redis.del(this.activeClaimKey(scope)),
        this.redis.del(this.dispatchStateKey(scope)),
        this.redis.del(this.handoffDedupeKey(orderId, scope)),
      ]),
    ]);
  }

  // ─── Driver pending dispatch sets ────────────────────────────────────────

  async addDriverPending(
    driverId: string,
    dispatchId: string,
    ttlSecs: number,
  ): Promise<void> {
    const key = this.driverPendingKey(driverId);
    await this.redis.sadd(key, dispatchId);
    await this.redis.expire(key, ttlSecs);
  }

  async removeDriverPending(
    driverId: string,
    dispatchId: string,
  ): Promise<void> {
    await this.redis.srem(this.driverPendingKey(driverId), dispatchId);
  }

  async removeDispatchForCandidates(
    candidates: Array<{ driverId: string }>,
    dispatchId: string,
  ): Promise<void> {
    if (candidates.length === 0) return;
    await Promise.all(
      candidates.map((c) => this.removeDriverPending(c.driverId, dispatchId)),
    );
  }

  async getDriverPendingIds(driverId: string): Promise<string[]> {
    return this.redis.smembers(this.driverPendingKey(driverId));
  }

  // ─── Rejection tracking sets ─────────────────────────────────────────────

  async markCandidateRejected(
    dispatchId: string,
    driverId: string,
  ): Promise<number> {
    return this.redis.sadd(this.rejectedSetKey(dispatchId), driverId);
  }

  async refreshRejectedSetTtl(
    dispatchId: string,
    ttlSecs: number,
  ): Promise<void> {
    await this.redis.expire(this.rejectedSetKey(dispatchId), ttlSecs);
  }

  async getRejectedDriverIds(dispatchId: string): Promise<string[]> {
    return this.redis.smembers(this.rejectedSetKey(dispatchId));
  }

  async isCandidateRejected(
    dispatchId: string,
    driverId: string,
  ): Promise<boolean> {
    return Boolean(
      await this.redis.sismember(this.rejectedSetKey(dispatchId), driverId),
    );
  }

  async getRejectedCount(dispatchId: string): Promise<number> {
    return this.redis.scard(this.rejectedSetKey(dispatchId));
  }

  async deleteRejectedSet(dispatchId: string): Promise<void> {
    await this.redis.del(this.rejectedSetKey(dispatchId));
  }

  // ─── Terminal OrderDispatch persistence ──────────────────────────────────

  async createTerminalRecords(
    client: QueryClient,
    params: {
      orderId: string;
      type: OrderType;
      expiresAt: Date;
      candidates: Array<{
        driverId: string;
        driverShiftId: string | null;
        deliveryGroupId: string;
        distanceKm: number;
        estimatedEarnings: number;
      }>;
      status: DispatchStatus;
    },
  ): Promise<void> {
    if (params.candidates.length === 0) return;
    await client.orderDispatch.createMany({
      data: params.candidates.map((candidate) => ({
        id: uuidv4(),
        orderId: params.orderId,
        driverId: candidate.driverId,
        driverShiftId: candidate.driverShiftId,
        deliveryGroupId: candidate.deliveryGroupId,
        type: params.type,
        distanceKm: candidate.distanceKm,
        estimatedEarnings: candidate.estimatedEarnings,
        status: params.status,
        expiresAt: params.expiresAt,
      })),
    });
  }
}
