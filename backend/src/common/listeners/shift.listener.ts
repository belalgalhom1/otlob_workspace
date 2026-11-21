import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationType } from '@prisma/client';
import {
  ShiftAssignedEvent,
  ShiftDisabledEvent,
  ShiftMissedEvent,
  ShiftReminderEvent,
  ShiftSpotAvailableEvent,
  ShiftSwapCancelledEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';

/**
 * Owns all driver shift lifecycle notifications (reminders, misses, swaps,
 * admin assignments/removals, and waitlist promotions).
 */
@Injectable()
export class ShiftListener {
  private readonly logger = new Logger(ShiftListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  private async enqueueNotification(dto: {
    userId: string;
    title: string;
    titleAr?: string | null;
    body?: string | null;
    bodyAr?: string | null;
    type: NotificationType;
    data?: Record<string, unknown>;
  }) {
    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue shift notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
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

  @OnEvent(EVENTS.SHIFT_ASSIGNED, { async: true })
  async handleShiftAssigned(event: ShiftAssignedEvent) {
    await this.enqueueNotification({
      userId: event.driverUserId,
      title: 'Shift Assigned',
      titleAr: 'تم إسناد وردية جديدة',
      body: 'A shift has been assigned to you. Open the app to view your schedule.',
      bodyAr: 'تم إسناد وردية جديدة إليك. افتح التطبيق لعرض جدولك.',
      type: NotificationType.SYSTEM,
      data: { shiftId: event.shiftId, type: 'SHIFT_ASSIGNED' },
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
}
