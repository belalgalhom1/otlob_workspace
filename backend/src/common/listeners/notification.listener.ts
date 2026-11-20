import { Injectable, Logger, Optional } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  TicketStatusUpdatedEvent,
  ShiftReminderEvent,
  ShiftMissedEvent,
  ShiftSwapCancelledEvent,
  ShiftDisabledEvent,
  ShiftSpotAvailableEvent,
  OrderVendorRejectedEvent,
  OrderFulfillmentDecidedEvent,
  DriverAssistDecidedEvent,
  DriverAssistRequestedEvent,
  DriverRankEvaluationFailedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  NotificationType,
  OrderVendorFulfillmentStatus,
  Role,
  TicketStatus,
} from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

const TICKET_STATUS_LABELS: Record<TicketStatus, { en: string; ar: string }> = {
  [TicketStatus.OPEN]: { en: 'Open', ar: 'مفتوحة' },
  [TicketStatus.IN_PROGRESS]: { en: 'In Progress', ar: 'قيد المعالجة' },
  [TicketStatus.WAITING_ON_USER]: { en: 'Waiting on You', ar: 'في انتظارك' },
  [TicketStatus.RESOLVED]: { en: 'Resolved', ar: 'تم الحل' },
  [TicketStatus.ESCALATED]: { en: 'Escalated', ar: 'تم التصعيد للمدير' },
  [TicketStatus.CLOSED]: { en: 'Closed', ar: 'مغلقة' },
};

@Injectable()
export class NotificationListener {
  private readonly logger = new Logger(NotificationListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    @Optional() private readonly prisma?: PrismaService,
  ) {}

  // The DB write + socket + push for each notification happens on the worker
  // (EventsProcessor); listeners only build the DTO and enqueue it.

  private async enqueueNotification(dto: {
    userId: string;
    title: string;
    titleAr?: string | null;
    body?: string | null;
    bodyAr?: string | null;
    type: NotificationType;
    data?: Record<string, any>;
  }) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.TICKET_STATUS_UPDATED, { async: true })
  async handleTicketStatusUpdated(event: TicketStatusUpdatedEvent) {
    if (event.creatorId === event.actorId) return;

    const label = TICKET_STATUS_LABELS[event.status];

    await this.enqueueNotification({
      userId: event.creatorId,
      title: `Ticket #${event.ticketNumber} Updated`,
      titleAr: `تم تحديث التذكرة #${event.ticketNumber}`,
      body: `Your ticket status has been changed to: ${label.en}`,
      bodyAr: `تم تغيير حالة تذكرتك إلى: ${label.ar}`,
      type: NotificationType.TICKET_UPDATE,
      data: {
        ticketId: event.ticketId,
        ticketNumber: event.ticketNumber,
        status: event.status,
      },
    });
  }

  @OnEvent(EVENTS.SHIFT_REMINDER, { async: true })
  async handleShiftReminder(event: ShiftReminderEvent) {
    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Upcoming Shift Reminder',
      titleAr: 'تذكير بالوردية القادمة',
      body: `Your shift at zone ${event.zoneId ?? 'Global'} starts in 30 minutes! Be inside the zone and start it to go online.`,
      bodyAr: `ورديتك في المنطقة ${event.zoneId ?? 'العامة'} تبدأ خلال 30 دقيقة! كن داخل المنطقة وابدأها لتظهر متصلاً.`,
      type: NotificationType.SYSTEM,
      data: { shiftId: event.shiftId },
    });
  }

  @OnEvent(EVENTS.SHIFT_MISSED, { async: true })
  async handleShiftMissed(event: ShiftMissedEvent) {
    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Shift Missed',
      titleAr: 'تغيب عن الوردية',
      body: 'You missed starting your scheduled shift on time. This will be reflected in your weekly ranking evaluation.',
      bodyAr:
        'فاتك بدء ورديتك المجدولة في الوقت المحدد. سيؤثر ذلك على تقييم مستواك الأسبوعي.',
      type: NotificationType.SYSTEM,
      data: { shiftId: event.shiftId, type: 'SHIFT_MISSED' },
    });
  }

  @OnEvent(EVENTS.DRIVER_RANK_EVALUATION_FAILED, { async: true })
  async handleRankEvaluationFailed(event: DriverRankEvaluationFailedEvent) {
    if (!this.prisma) return;
    try {
      const admins = await this.prisma.user.findMany({
        where: {
          role: { in: [Role.ADMIN, Role.SUPER_ADMIN] },
          isBanned: false,
          deletedAt: null,
        },
        select: { id: true },
      });

      await Promise.all(
        admins.map((admin) =>
          this.enqueueNotification({
            userId: admin.id,
            title: 'Weekly Driver Ranking Failed',
            titleAr: 'فشل تقييم مستويات السائقين الأسبوعي',
            body: `Evaluation run for week ${event.periodKey} failed: ${event.errorMessage}. Open Driver Ranking to retry.`,
            bodyAr: `فشل تشغيل تقييم الأسبوع ${event.periodKey}: ${event.errorMessage}. افتح تصنيف السائقين لإعادة المحاولة.`,
            type: NotificationType.SYSTEM,
            data: {
              kind: 'driver_rank_evaluation_failed',
              runId: event.runId,
              periodKey: event.periodKey,
            },
          }),
        ),
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to notify admins about driver ranking failure: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.SHIFT_SWAP_CANCELLED, { async: true })
  async handleShiftSwapCancelled(event: ShiftSwapCancelledEvent) {
    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Shift Swap Cancelled',
      titleAr: 'تم إلغاء تبديل الوردية',
      body: 'Your pending swap was not accepted. You are required to attend this shift in 30 mins.',
      bodyAr: 'لم يتم قبول طلب التبديل. يرجى الحضور للوردية خلال 30 دقيقة.',
      type: NotificationType.SYSTEM,
      data: { shiftId: event.shiftId },
    });
  }

  // An admin removed/reassigned the driver from a shift (or deleted the whole
  // pool). Self-cancels are skipped — the driver already knows, they did it.
  @OnEvent(EVENTS.SHIFT_DISABLED, { async: true })
  async handleShiftDisabled(event: ShiftDisabledEvent) {
    if (event.reason !== 'admin') return;

    const count = event.count ?? 1;
    const isBulk = count > 1;

    await this.enqueueNotification({
      userId: event.driverUserId,
      title: isBulk ? 'Shifts Removed' : 'Shift Removed',
      titleAr: isBulk ? 'تم إزالة الورديات' : 'تم إزالة الوردية',
      body: isBulk
        ? `${count} shifts assigned to you were removed by admin. Open the app to see your updated schedule.`
        : 'A shift assigned to you was removed by admin. Open the app to see your updated schedule.',
      bodyAr: isBulk
        ? `تم إزالة ${count} من الورديات المسندة إليك من قبل الإدارة. افتح التطبيق لعرض جدولك المحدّث.`
        : 'تم إزالة وردية مسندة إليك من قبل الإدارة. افتح التطبيق لعرض جدولك المحدّث.',
      type: NotificationType.SYSTEM,
      data: {
        shiftId: event.shiftId,
        type: 'SHIFT_REMOVED',
        ...(isBulk ? { count } : {}),
      },
    });
  }

  // A seat freed up in a full pool and the waitlist promoted this driver into
  // it automatically.
  @OnEvent(EVENTS.SHIFT_SPOT_AVAILABLE, { async: true })
  async handleShiftSpotAvailable(event: ShiftSpotAvailableEvent) {
    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Shift Assigned From Waitlist',
      titleAr: 'تم إسناد وردية من قائمة الانتظار',
      body: 'A seat opened up in a shift you were waiting for and it is now yours. Open the app to view your schedule.',
      bodyAr:
        'تم توفّر مقعد في وردية كنت تنتظرها وأصبحت لك الآن. افتح التطبيق لعرض جدولك.',
      type: NotificationType.SYSTEM,
      data: { shiftPoolId: event.shiftPoolId, type: 'WAITLIST_PROMOTED' },
    });
  }

  // ─── Multi-vendor orders ───────────────────────────────────────────────────

  /**
   * A vendor rejected its portion. Tell the customer promptly, naming the
   * vendor, the affected items and the reason, and stating the money change so
   * the customer is not surprised by the adjusted total.
   */
  @OnEvent(EVENTS.ORDER_VENDOR_REJECTED, { async: true })
  async handleOrderVendorRejected(event: OrderVendorRejectedEvent) {
    const items =
      event.affectedItemNames.length > 0
        ? event.affectedItemNames.join(', ')
        : 'some items';
    const money =
      event.refundAmount > 0
        ? ` ${event.refundAmount} EGP was removed from your total.`
        : '';

    if (!event.allPortionsRejected) {
      await this.enqueueNotification({
        userId: event.customerUserId,
        title: `Part of your order was unavailable`,
        titleAr: 'جزء من طلبك غير متوفر',
        body: `${event.vendorName} could not fulfil: ${items}. ${event.rejectionReason}.${money}`,
        bodyAr: `${event.vendorNameAr ?? event.vendorName} لم يستطع تلبية الطلب: ${items}. ${event.rejectionReasonAr ?? event.rejectionReason}.${money}`,
        type: NotificationType.ORDER_UPDATE,
        data: {
          orderId: event.orderId,
          type: 'VENDOR_PORTION_REJECTED',
          fulfillmentId: event.fulfillmentId,
          refundAmount: event.refundAmount,
        },
      });
    }
  }

  /** Vendor accepted its own portion — tell the customer this part is moving. */
  @OnEvent(EVENTS.ORDER_FULFILLMENT_DECIDED, { async: true })
  async handleFulfillmentDecided(event: OrderFulfillmentDecidedEvent) {
    if (event.status !== OrderVendorFulfillmentStatus.ACCEPTED) return;

    await this.enqueueNotification({
      userId: event.customerUserId,
      title: 'A vendor accepted part of your order',
      titleAr: 'قبل أحد الموردين جزءًا من طلبك',
      body: `Part of your order ${event.orderNumber} was accepted and is now being prepared.`,
      bodyAr: `تم قبول جزء من طلبك ${event.orderNumber} ويجري تجهيزه الآن.`,
      type: NotificationType.ORDER_UPDATE,
      data: {
        orderId: event.orderId,
        type: 'FULFILLMENT_ACCEPTED',
        fulfillmentId: event.fulfillmentId,
      },
    });
  }

  // ─── Extra-driver assistance ──────────────────────────────────────────────

  @OnEvent(EVENTS.DRIVER_ASSIST_REQUESTED, { async: true })
  async handleDriverAssistRequested(event: DriverAssistRequestedEvent) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.DRIVER_ASSIST_REQUESTED, event, {
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue driver.assist.requested event: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  /** Support approved/rejected/withdrew an assistance request — tell the driver. */
  @OnEvent(EVENTS.DRIVER_ASSIST_DECIDED, { async: true })
  async handleAssistDecided(event: DriverAssistDecidedEvent) {
    const copy: Record<string, { en: string; ar: string }> = {
      approved: {
        en: 'Your request for an extra driver was approved.',
        ar: 'تمت الموافقة على طلبك لسائق إضافي.',
      },
      rejected: {
        en: 'Your request for an extra driver was rejected.',
        ar: 'تم رفض طلبك لسائق إضافي.',
      },
      cancelled: {
        en: 'Your extra-driver request was withdrawn.',
        ar: 'تم إلغاء طلب السائق الإضافي.',
      },
      fulfilled: {
        en: 'An extra driver has been assigned to your delivery.',
        ar: 'تم تعيين سائق إضافي لتوصيلك.',
      },
    };
    const text = copy[event.decision];
    if (!text) return;

    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Extra driver request update',
      titleAr: 'تحديث طلب السائق الإضافي',
      body: text.en,
      bodyAr: text.ar,
      type: NotificationType.ORDER_UPDATE,
      data: { orderId: event.orderId, requestId: event.requestId },
    });
  }
}
