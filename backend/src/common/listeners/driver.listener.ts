import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationType, DriverStatus } from '@prisma/client';
import {
  DriverLocationUpdatedEvent,
  DriverStatusChangedEvent,
  DriverBreakDecidedEvent,
  DriverBreakDecision,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

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
  }

  @OnEvent(EVENTS.DRIVER_STATUS_CHANGED, { async: true })
  async handleStatusChanged(event: DriverStatusChangedEvent) {
    this.logger.debug(
      `Driver ${event.driverId}: ${event.oldStatus} → ${event.newStatus}`,
    );

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
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto }, { attempts: 1 });
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
        bodyAr:
          'انتهت صلاحية طلب الاستراحة دون موافقة. يمكنك الطلب مرة أخرى.',
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
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto }, { attempts: 1 });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue break notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
