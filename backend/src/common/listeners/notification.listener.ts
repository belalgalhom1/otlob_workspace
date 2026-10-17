import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  TicketStatusUpdatedEvent,
  ShiftReminderEvent,
  ShiftMissedEvent,
  ShiftSwapCancelledEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import { NotificationType, TicketStatus } from '@prisma/client';
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
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, { dto }, { attempts: 1 });
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
      title: 'Shift Missed / Tier Demotion',
      titleAr: 'تغيب عن الوردية / نزول المستوى',
      body: `You failed to start your shift on time. You have been demoted to ${event.newTier} tier.`,
      bodyAr: `لم تقم ببدء ورديتك في الوقت المحدد. تم تنزيل مستواك إلى ${event.newTier}.`,
      type: NotificationType.SYSTEM,
      data: { shiftId: event.shiftId, type: 'TIER_DEMOTION' },
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
}
