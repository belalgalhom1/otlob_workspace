import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { SocketService } from '../../infrastructure/socket/socket.service';
import {
  DriverRankChangeReason,
  DriverStatus,
  DriverTier,
  NotificationType,
} from '@prisma/client';
import {
  DriverLocationUpdatedEvent,
  DriverStatusChangedEvent,
  DriverBreakDecidedEvent,
  DriverBreakDecision,
  DriverRankUpdatedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { compareTiers } from '../../features/drivers/ranking/driver-ranking.calculator';

const TIER_LABEL_EN: Record<DriverTier, string> = {
  [DriverTier.GOLD]: 'Gold',
  [DriverTier.SILVER]: 'Silver',
  [DriverTier.BRONZE]: 'Bronze',
};

const TIER_LABEL_AR: Record<DriverTier, string> = {
  [DriverTier.GOLD]: 'الذهبي',
  [DriverTier.SILVER]: 'الفضي',
  [DriverTier.BRONZE]: 'البرونزي',
};

@Injectable()
export class DriverListener {
  private readonly logger = new Logger(DriverListener.name);

  constructor(
    private readonly socketService: SocketService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  @OnEvent(EVENTS.DRIVER_LOCATION_UPDATED)
  handleLocationUpdated(event: DriverLocationUpdatedEvent) {
    const payload = {
      driverId: event.driverId,
      longitude: event.longitude,
      latitude: event.latitude,
      timestamp: new Date().toISOString(),
    };

    if (event.activeOrderId && event.customerUserId) {
      // High-frequency + socket-only, kept inline.
      this.socketService
        .emitToUser(event.customerUserId, 'driver.location', {
          ...payload,
          orderId: event.activeOrderId,
        })
        .catch((err: unknown) =>
          this.logger.error(
            `Failed to emit driver location: ${err instanceof Error ? err.message : String(err)}`,
          ),
        );
    }

    // Also broadcast to driver room so admin / dashboard locating this driver can listen in real-time
    this.socketService
      .emitToRoom(`driver_${event.driverId}`, 'driver.location', {
        ...payload,
        orderId: event.activeOrderId,
      })
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to emit driver room location: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
  }

  @OnEvent(EVENTS.DRIVER_STATUS_CHANGED, { async: true })
  async handleStatusChanged(event: DriverStatusChangedEvent) {
    this.logger.debug(
      `Driver ${event.driverId}: ${event.oldStatus} → ${event.newStatus}`,
    );

    if (event.newStatus === DriverStatus.SUSPENDED && event.driverUserId) {
      Promise.resolve(
        this.socketService.disconnectUser(event.driverUserId),
      ).catch((err: unknown) =>
        this.logger.error(
          `Failed to disconnect suspended driver socket: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );
    }

    if (!event.driverUserId) return;

    let dto:
      | {
          userId: string;
          title: string;
          titleAr: string;
          body: string;
          bodyAr: string;
          type: NotificationType;
          data: Record<string, any>;
        }
      | undefined;

    if (
      event.reason === 'UNPAID_COMMISSION' &&
      event.newStatus === DriverStatus.SUSPENDED
    ) {
      dto = {
        userId: event.driverUserId,
        title: 'Account Suspended',
        titleAr: 'تم تعليق الحساب',
        body: 'You have been suspended for unpaid commissions. Please settle your wallet to receive orders again.',
        bodyAr:
          'تم تعليق حسابك بسبب العمولات غير المدفوعة. يرجى تسوية محفظتك لاستقبال الطلبات مرة أخرى.',
        type: NotificationType.SYSTEM,
        data: { reason: 'UNPAID_COMMISSION' },
      };
    } else if (event.reason === 'SETTLEMENT_REQUIRED') {
      dto = {
        userId: event.driverUserId,
        title: 'Settlement Required',
        titleAr: 'مطلوب تسوية',
        body: 'You have reached the settlement milestone. Please transfer the money you owe to the platform wallet to keep receiving new orders.',
        bodyAr:
          'وصلت إلى حد التسوية. يرجى تحويل المبلغ المستحق إلى محفظة المنصة لاستمرار استقبال طلبات جديدة.',
        type: NotificationType.SYSTEM,
        data: { reason: 'SETTLEMENT_REQUIRED' },
      };
    } else if (event.reason === 'UNPAID_COMMISSION_SETTLED') {
      dto = {
        userId: event.driverUserId,
        title: 'Account Unsuspended',
        titleAr: 'تم فك تعليق الحساب',
        body: 'Your wallet top-up was approved. You can now go online and receive orders!',
        bodyAr:
          'تمت الموافقة على شحن محفظتك. يمكنك الآن تسجيل الدخول واستقبال الطلبات!',
        type: NotificationType.SYSTEM,
        data: { reason: 'UNPAID_COMMISSION_SETTLED' },
      };
    }

    if (!dto) return;

    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue driver status notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.DRIVER_BREAK_DECIDED, { async: true })
  async handleBreakDecided(event: DriverBreakDecidedEvent) {
    const copy: Record<
      DriverBreakDecision,
      { title: string; titleAr: string; body: string; bodyAr: string }
    > = {
      approved: {
        title: 'Break approved',
        titleAr: 'تمت الموافقة على الاستراحة',
        body: 'Your break was approved. You are now on break and will not receive orders.',
        bodyAr:
          'تمت الموافقة على استراحتك. أنت الآن في استراحة ولن تصلك طلبات.',
      },
      rejected: {
        title: 'Break request rejected',
        titleAr: 'تم رفض طلب الاستراحة',
        body: 'An admin rejected your break request. You are still online.',
        bodyAr: 'رفض المشرف طلب الاستراحة. ما زلت متاحًا.',
      },
      granted: {
        title: 'Break granted',
        titleAr: 'تم منح استراحة',
        body: 'An admin gave you a break. You are now on break.',
        bodyAr: 'منحك المشرف استراحة. أنت الآن في استراحة.',
      },
      ended_by_admin: {
        title: 'Break ended by admin',
        titleAr: 'أنهى المشرف الاستراحة',
        body: 'An admin ended your break early. Your break is over.',
        bodyAr: 'أنهى المشرف استراحتك مبكرًا. انتهت الاستراحة.',
      },
      auto_ended: {
        title: 'Break auto-ended',
        titleAr: 'انتهت الاستراحة تلقائيًا',
        body: 'Your break reached the maximum length and was ended.',
        bodyAr: 'بلغت استراحتك الحد الأقصى وتم إنهاؤها.',
      },
      request_expired: {
        title: 'Break request expired',
        titleAr: 'انتهت صلاحية طلب الاستراحة',
        body: 'Your break request expired without admin approval. You can request again.',
        bodyAr: 'انتهت صلاحية طلب الاستراحة دون موافقة. يمكنك الطلب مرة أخرى.',
      },
    };

    const text = copy[event.action];
    if (!text) return;

    const dto = {
      userId: event.driverUserId,
      title: text.title,
      titleAr: text.titleAr,
      body: text.body,
      bodyAr: text.bodyAr,
      type: NotificationType.SYSTEM,
      data: {
        kind: 'break',
        action: event.action,
        breakId: event.breakId,
        driverId: event.driverId,
      },
    };

    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue break notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.DRIVER_RANK_UPDATED, { async: true })
  async handleRankUpdated(event: DriverRankUpdatedEvent) {
    if (!event.driverUserId || event.previousTier === event.newTier) {
      return;
    }

    const newTier = event.newTier as DriverTier;
    const prevTier = event.previousTier as DriverTier;
    const newEn = TIER_LABEL_EN[newTier] ?? event.newTier;
    const newAr = TIER_LABEL_AR[newTier] ?? event.newTier;
    const isPromotion = compareTiers(newTier, prevTier) > 0;
    const scoreText =
      event.performancePercentage != null
        ? `${Number(event.performancePercentage.toFixed(2))}%`
        : null;
    const periodSuffix = event.periodKey ? ` (${event.periodKey})` : '';

    let title: string;
    let titleAr: string;
    let body: string;
    let bodyAr: string;

    if (event.changeReason === DriverRankChangeReason.INACTIVE_DRIVER) {
      title = `Weekly Rank Updated: ${newEn}`;
      titleAr = `تحديث المستوى الأسبوعي: ${newAr}`;
      body = `You had no qualifying activity last week${periodSuffix}, so your badge has been set to ${newEn}.`;
      bodyAr = `لم يكن لديك نشاط مؤهل الأسبوع الماضي${periodSuffix}، لذلك تم تعيين مستواك إلى ${newAr}.`;
    } else if (event.changeReason === DriverRankChangeReason.ADMIN_OVERRIDE) {
      title = `Driver Badge Updated: ${newEn}`;
      titleAr = `تم تحديث مستواك: ${newAr}`;
      const reasonSuffixEn = event.overrideReason
        ? ` Reason: ${event.overrideReason}`
        : '';
      const reasonSuffixAr = event.overrideReason
        ? ` السبب: ${event.overrideReason}`
        : '';
      body = `An administrator updated your badge to ${newEn}.${reasonSuffixEn}`;
      bodyAr = `قام المشرف بتحديث مستواك إلى ${newAr}.${reasonSuffixAr}`;
    } else if (isPromotion) {
      title = `Congratulations! Promoted to ${newEn}`;
      titleAr = `مبروك! تمت ترقيتك إلى المستوى ${newAr}`;
      body = scoreText
        ? `Your weekly performance score was ${scoreText}${periodSuffix}. Your badge is now ${newEn}.`
        : `Your badge has been promoted to ${newEn}.`;
      bodyAr = scoreText
        ? `نسبة أدائك الأسبوعية ${scoreText}${periodSuffix}. أصبح مستواك الآن ${newAr}.`
        : `تمت ترقية مستواك إلى ${newAr}.`;
    } else {
      title = `Weekly Rank Updated: ${newEn}`;
      titleAr = `تحديث المستوى الأسبوعي: ${newAr}`;
      body = scoreText
        ? `Your weekly performance score was ${scoreText}${periodSuffix}. Your badge is now ${newEn}.`
        : `Your badge has been updated to ${newEn}.`;
      bodyAr = scoreText
        ? `نسبة أدائك الأسبوعية ${scoreText}${periodSuffix}. أصبح مستواك الآن ${newAr}.`
        : `تم تحديث مستواك إلى ${newAr}.`;
    }

    await this.socketService
      .emitToUser(event.driverUserId, 'driver.rank.updated', {
        driverId: event.driverId,
        previousTier: event.previousTier,
        newTier: event.newTier,
        performancePercentage: event.performancePercentage,
        periodKey: event.periodKey,
        changeReason: event.changeReason,
      })
      .catch((err: unknown) =>
        this.logger.error(
          `Failed to emit driver.rank.updated socket event: ${err instanceof Error ? err.message : String(err)}`,
        ),
      );

    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, {
        dto: {
          userId: event.driverUserId,
          title,
          titleAr,
          body,
          bodyAr,
          type: NotificationType.SYSTEM,
          data: {
            kind: 'driver_rank_updated',
            driverId: event.driverId,
            previousTier: event.previousTier,
            newTier: event.newTier,
            performancePercentage: event.performancePercentage,
            periodKey: event.periodKey,
            changeReason: event.changeReason,
          },
        },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue driver rank notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
