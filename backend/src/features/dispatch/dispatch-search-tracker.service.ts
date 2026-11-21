import { Injectable, Logger, Optional } from '@nestjs/common';
import { OrderStatus, OrderType } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { EVENTS } from '../../common/events/event-names';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { DispatchRepository } from './dispatch.repository';
import {
  DriverSearchPhase,
  OrderSearchProgressWsPayload,
  OrderSearchSnapshotRecord,
  SearchTerminalReason,
} from './dispatch-search.types';

export interface PublishSearchPhaseInput {
  orderId: string;
  orderNumber?: string;
  orderType?: OrderType;
  orderStatus: OrderStatus;
  revision?: number;
  customerUserId?: string | null;
  phase: DriverSearchPhase;
  attempt?: number;
  maxAttempts?: number;
  radiusKm?: number;
  maxRadiusKm?: number;
  contactedCount?: number;
  contactedDriverIds?: string[];
  newlyRejectedDriverIds?: string[];
  waveExpiresAt?: string | null;
  searchTimeoutSecs?: number;
  terminalReason?: SearchTerminalReason;
  resetHistory?: boolean;
}

/**
 * Coordinates durable Redis search-status snapshots and direct real-time
 * WebSocket progress emissions (`'order.search_progress'`) for customers.
 */
@Injectable()
export class DispatchSearchTracker {
  private readonly logger = new Logger(DispatchSearchTracker.name);

  constructor(
    private readonly dispatchRepository: DispatchRepository,
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    @Optional() private readonly socketService?: SocketService,
  ) {}

  async publishPhase(
    input: PublishSearchPhaseInput,
  ): Promise<OrderSearchProgressWsPayload | null> {
    try {
      const existing = input.resetHistory
        ? null
        : await this.dispatchRepository.getSearchSnapshot(input.orderId);

      const settings = await this.platformSettings.getSettings();
      const maxAttempts =
        input.maxAttempts ??
        existing?.maxAttempts ??
        Number(settings.driverSearchMaxAttempts ?? 5);
      const maxRadiusKm =
        input.maxRadiusKm ??
        existing?.maxRadiusKm ??
        Number(settings.driverSearchRadiusMaxKm ?? 15);
      const searchTimeoutSecs =
        input.searchTimeoutSecs ??
        existing?.searchTimeoutSecs ??
        Number(settings.driverAcceptTimeoutSecs ?? 30);
      const attempt = input.attempt ?? existing?.attempt ?? 1;
      const radiusKm =
        input.radiusKm ??
        existing?.radiusKm ??
        Math.min(
          Number(settings.driverSearchRadiusKm ?? 3) +
            Number(settings.driverSearchRadiusStepKm ?? 3) *
              Math.max(0, attempt - 1),
          maxRadiusKm,
        );

      let orderNumber = input.orderNumber ?? existing?.orderNumber;
      let orderType = input.orderType ?? existing?.orderType;
      let customerUserId = input.customerUserId ?? existing?.customerUserId;
      let revision = input.revision ?? existing?.revision ?? 0;

      if (!orderNumber || !orderType || !customerUserId) {
        const orderRow = await this.prisma.order.findUnique({
          where: { id: input.orderId },
          select: {
            orderNumber: true,
            type: true,
            revision: true,
            customer: { select: { userId: true } },
          },
        });
        if (!orderRow) return null;
        orderNumber = orderNumber ?? orderRow.orderNumber;
        orderType = orderType ?? orderRow.type;
        customerUserId = customerUserId ?? orderRow.customer?.userId;
        revision = Math.max(revision, Number(orderRow.revision ?? 0));
      }

      if (!customerUserId || !orderNumber || !orderType) {
        return null;
      }

      const contactedSet = new Set(
        input.resetHistory ? [] : (existing?.totalContactedDriverIds ?? []),
      );
      for (const id of input.contactedDriverIds ?? []) {
        if (id) contactedSet.add(id);
      }

      const rejectedSet = new Set(
        input.resetHistory ? [] : (existing?.rejectedDriverIds ?? []),
      );
      for (const id of input.newlyRejectedDriverIds ?? []) {
        if (id) rejectedSet.add(id);
      }

      const nowIso = new Date().toISOString();
      const sequence = Math.max(Date.now(), (existing?.sequence ?? 0) + 1);
      const snapshot: OrderSearchSnapshotRecord = {
        orderId: input.orderId,
        orderNumber,
        orderType,
        customerUserId,
        orderStatus: input.orderStatus,
        revision,
        phase: input.phase,
        attempt,
        maxAttempts,
        radiusKm,
        maxRadiusKm,
        contactedCount:
          input.contactedCount ??
          (input.contactedDriverIds ? input.contactedDriverIds.length : (existing?.contactedCount ?? 0)),
        totalContactedDriverIds: Array.from(contactedSet),
        rejectedDriverIds: Array.from(rejectedSet),
        waveExpiresAt:
          input.waveExpiresAt !== undefined
            ? input.waveExpiresAt
            : (existing?.waveExpiresAt ?? null),
        searchTimeoutSecs,
        searchStartedAt: input.resetHistory
          ? nowIso
          : (existing?.searchStartedAt ?? nowIso),
        updatedAt: nowIso,
        terminalReason:
          input.terminalReason ??
          existing?.terminalReason ??
          SearchTerminalReason.NONE,
        sequence,
      };

      await this.dispatchRepository.saveSearchSnapshot(
        input.orderId,
        snapshot,
        1800,
      );

      const wsPayload: OrderSearchProgressWsPayload = {
        orderId: snapshot.orderId,
        orderNumber: snapshot.orderNumber,
        orderStatus: snapshot.orderStatus,
        revision: snapshot.revision,
        phase: snapshot.phase,
        attempt: snapshot.attempt,
        maxAttempts: snapshot.maxAttempts,
        radiusKm: snapshot.radiusKm,
        maxRadiusKm: snapshot.maxRadiusKm,
        contactedCount: snapshot.contactedCount,
        totalContactedCount: snapshot.totalContactedDriverIds.length,
        rejectedCount: snapshot.rejectedDriverIds.length,
        waveExpiresAt: snapshot.waveExpiresAt,
        searchTimeoutSecs: snapshot.searchTimeoutSecs,
        terminalReason: snapshot.terminalReason,
        updatedAt: snapshot.updatedAt,
        sequence: snapshot.sequence,
      };

      await this.socketService
        ?.emitToUser(customerUserId, EVENTS.ORDER_SEARCH_PROGRESS, wsPayload)
        .catch((err: unknown) => {
          this.logger.warn(
            `Failed to emit search progress for order ${input.orderId}: ${
              err instanceof Error ? err.message : String(err)
            }`,
          );
        });

      return wsPayload;
    } catch (err: unknown) {
      this.logger.warn(
        `Search tracker update skipped for order ${input.orderId}: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      return null;
    }
  }
}
