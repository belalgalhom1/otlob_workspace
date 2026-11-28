import { Injectable, Logger, Optional } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationType, Role } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';

export type StaleOrderAlertReason =
  | 'PENDING_VENDOR'
  | 'NO_DRIVER_FOUND'
  | 'PENDING_PAYMENT';

export const DEFAULT_STALE_ORDER_ALERT_INTERVAL_MINS = 5;

export interface StaleOrderAlertInput {
  orderId: string;
  orderNumber: string;
  reason: StaleOrderAlertReason;
  referenceTime?: Date | null;
  intervalMins?: number | null;
}

/**
 * Replaces automatic order cancellation with recurring Super Admin alerts.
 * Orders remain active until manually resolved (accepted, assigned, delivered,
 * or explicitly cancelled by a human actor), while every active SUPER_ADMIN
 * receives a throttled push + in-app reminder every `staleOrderAlertIntervalMins`
 * minutes (default: 5 min).
 */
@Injectable()
export class StaleOrderAlertService {
  private readonly logger = new Logger(StaleOrderAlertService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
    @Optional() @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue?: Queue,
  ) {}

  resolveIntervalMins(rawValue?: number | null): number {
    const parsed = Number(rawValue);
    if (!Number.isFinite(parsed) || parsed < 1) {
      return DEFAULT_STALE_ORDER_ALERT_INTERVAL_MINS;
    }
    return Math.min(1440, Math.round(parsed));
  }

  async alertOrderIfDue(
    input: StaleOrderAlertInput,
  ): Promise<{ alerted: boolean; recipientCount: number }> {
    const intervalMins = this.resolveIntervalMins(input.intervalMins);
    const intervalSecs = Math.max(60, intervalMins * 60);
    const nowMs = Date.now();
    const throttleKey = `stale_order_alert:${input.orderId}:${input.reason}`;

    if (this.redis) {
      try {
        const acquired = await this.redis.setNX(
          throttleKey,
          String(nowMs),
          intervalSecs,
        );
        if (!acquired) {
          return { alerted: false, recipientCount: 0 };
        }
      } catch (err: unknown) {
        this.logger.warn(
          `Redis throttle check failed for ${throttleKey}: ${err instanceof Error ? err.message : String(err)}`,
        );
      }
    }

    if (!this.eventsQueue) {
      this.logger.warn(
        `Events queue unavailable; cannot send stale order alert for #${input.orderNumber}`,
      );
      return { alerted: false, recipientCount: 0 };
    }

    const superAdmins = await this.prisma.user.findMany({
      where: {
        role: Role.SUPER_ADMIN,
        isBanned: false,
        deletedAt: null,
      },
      select: { id: true },
    });

    const recipientIds = Array.from(
      new Set(superAdmins.map((u) => u.id).filter(Boolean)),
    );
    if (recipientIds.length === 0) {
      return { alerted: false, recipientCount: 0 };
    }

    const refTimeMs = input.referenceTime
      ? input.referenceTime.getTime()
      : nowMs - intervalMins * 60 * 1000;
    const elapsedMins = Math.max(
      intervalMins,
      Math.floor((nowMs - refTimeMs) / 60_000),
    );

    const { title, titleAr, body, bodyAr } = this.buildCopy(
      input.orderNumber,
      input.reason,
      elapsedMins,
    );

    // Time-bucketed key allows a fresh reminder every `intervalMins` while still
    // deduplicating concurrent worker runs within the same interval window.
    const bucket = Math.floor(nowMs / (intervalSecs * 1000));

    await Promise.all(
      recipientIds.map((adminId) => {
        const dedupeKey = `stale_order_alert:${input.orderId}:${input.reason}:${adminId}:${bucket}`;
        const jobId = `stale_order_alert_${input.orderId}_${input.reason}_${adminId}_${bucket}`;
        return this.eventsQueue!
          .add(
            EVENT_JOBS.NOTIFY,
            {
              dto: {
                userId: adminId,
                title,
                titleAr,
                body,
                bodyAr,
                type: NotificationType.ORDER_UPDATE,
                dedupeKey,
                data: {
                  kind: 'stale_order_alert',
                  alertReason: input.reason,
                  orderId: input.orderId,
                  orderNumber: input.orderNumber,
                  elapsedMins: String(elapsedMins),
                  intervalMins: String(intervalMins),
                },
              },
            },
            { jobId },
          )
          .catch((err: unknown) => {
            this.logger.error(
              `Failed to enqueue stale order alert for #${input.orderNumber} -> admin ${adminId}: ${err instanceof Error ? err.message : String(err)}`,
            );
          });
      }),
    );

    this.logger.warn(
      `🔔 Stale order alert [${input.reason}] sent for #${input.orderNumber} (${elapsedMins}m elapsed, every ${intervalMins}m) to ${recipientIds.length} Super Admin(s)`,
    );

    return { alerted: true, recipientCount: recipientIds.length };
  }

  private buildCopy(
    orderNumber: string,
    reason: StaleOrderAlertReason,
    elapsedMins: number,
  ): { title: string; titleAr: string; body: string; bodyAr: string } {
    switch (reason) {
      case 'PENDING_VENDOR':
        return {
          title: `Pending Order Alert #${orderNumber}`,
          titleAr: `تنبيه طلب معلق #${orderNumber}`,
          body: `Order #${orderNumber} has been waiting for vendor confirmation for ${elapsedMins} min. It will not be auto-cancelled — please review or intervene.`,
          bodyAr: `الطلب #${orderNumber} معلق بانتظار موافقة المتجر منذ ${elapsedMins} دقيقة ولن يُلغى تلقائياً — يرجى المراجعة أو التدخل.`,
        };
      case 'NO_DRIVER_FOUND':
        return {
          title: `Order Waiting for Driver #${orderNumber}`,
          titleAr: `طلب بانتظار سائق #${orderNumber}`,
          body: `Order #${orderNumber} has been waiting for a driver for ${elapsedMins} min. It will not be auto-cancelled — please assign a driver.`,
          bodyAr: `الطلب #${orderNumber} بانتظار قبول سائق منذ ${elapsedMins} دقيقة ولن يُلغى تلقائياً — يرجى تعيين سائق.`,
        };
      case 'PENDING_PAYMENT':
        return {
          title: `Pending Payment Alert #${orderNumber}`,
          titleAr: `تنبيه طلب بانتظار الدفع #${orderNumber}`,
          body: `Order #${orderNumber} has been awaiting mobile wallet payment for ${elapsedMins} min. It will not be auto-cancelled — please follow up.`,
          bodyAr: `الطلب #${orderNumber} بانتظار إتمام الدفع بالمحفظة منذ ${elapsedMins} دقيقة ولن يُلغى تلقائياً — يرجى المتابعة.`,
        };
    }
  }
}
