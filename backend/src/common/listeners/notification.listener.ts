import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationType, TicketStatus } from '@prisma/client';
import { TicketStatusUpdatedEvent } from '../events';
import { EVENTS } from '../events/event-names';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';

const TICKET_STATUS_LABELS: Record<TicketStatus, { en: string; ar: string }> = {
  [TicketStatus.OPEN]: { en: 'Open', ar: 'مفتوحة' },
  [TicketStatus.IN_PROGRESS]: { en: 'In Progress', ar: 'قيد المعالجة' },
  [TicketStatus.WAITING_ON_USER]: { en: 'Waiting on You', ar: 'في انتظارك' },
  [TicketStatus.RESOLVED]: { en: 'Resolved', ar: 'تم الحل' },
  [TicketStatus.ESCALATED]: { en: 'Escalated', ar: 'تم التصعيد للمدير' },
  [TicketStatus.CLOSED]: { en: 'Closed', ar: 'مغلقة' },
};

/**
 * Owns support-ticket status notifications (enqueued to `QUEUES.EVENTS`).
 * Domain-specific listeners for shifts, orders, drivers, and driver-assist live
 * in `ShiftListener`, `OrderListener`, `DriverListener`, and
 * `DriverAssistListener`.
 */
@Injectable()
export class NotificationListener {
  private readonly logger = new Logger(NotificationListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  @OnEvent(EVENTS.TICKET_STATUS_UPDATED, { async: true })
  async handleTicketStatusUpdated(event: TicketStatusUpdatedEvent) {
    if (event.creatorId === event.actorId) return;

    const label = TICKET_STATUS_LABELS[event.status];

    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, {
        dto: {
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
        },
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue ticket notification: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
