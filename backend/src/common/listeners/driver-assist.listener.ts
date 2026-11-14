import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationType } from '@prisma/client';
import { Queue } from 'bullmq';
import { EVENTS } from '../events/event-names';
import {
  DriverAssistAssignedEvent,
  DriverAssistCustomerDecidedEvent,
  DriverAssistOfferedEvent,
  DriverAssistTimedOutEvent,
} from '../events';
import { EVENT_JOBS, QUEUES } from '../../infrastructure/queue/queues.constants';
import { SocketService } from '../../infrastructure/socket/socket.service';

/**
 * Handles post-commit Driver Assist side effects (offer broadcasts, customer
 * proposals, driver assignment sockets, customer decisions, and timeouts).
 * Initial request/decision admin alerts remain on NotificationListener.
 */
@Injectable()
export class DriverAssistListener {
  private readonly logger = new Logger(DriverAssistListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    private readonly socketService: SocketService,
  ) {}

  @OnEvent(EVENTS.DRIVER_ASSIST_OFFERED, { async: true })
  async handleAssistOffered(event: DriverAssistOfferedEvent): Promise<void> {
    for (const userId of event.targetUserIds) {
      await this.emitSocket(userId, 'assist.offer', {
        requestId: event.requestId,
        orderId: event.orderId,
        expiresAt: event.expiresAt,
      });
      await this.enqueueNotification({
        userId,
        title: 'Assist offer',
        titleAr: 'عرض مساعدة',
        body: 'A driver needs help with a delivery. Accept to assist.',
        bodyAr: 'سائق يحتاج مساعدة في توصيل. اقبل للمساعدة.',
        data: {
          requestId: event.requestId,
          orderId: event.orderId,
          action: 'assist_offer',
        },
      });
    }
  }

  @OnEvent(EVENTS.DRIVER_ASSIST_ASSIGNED, { async: true })
  async handleAssistAssigned(event: DriverAssistAssignedEvent): Promise<void> {
    const orderLabel = event.orderNumber || event.orderId;
    const groupFields = event.deliveryGroupId
      ? { deliveryGroupId: event.deliveryGroupId }
      : {};

    if (event.customerUserId) {
      const body = event.deliveryGroupId
        ? `An assisting driver was added to delivery ${orderLabel}. Extra fee: ${event.assistFee}. Approve or decline.`
        : `An assisting driver was added. Extra fee: ${event.assistFee}. Approve or decline.`;
      const bodyAr = event.deliveryGroupId
        ? `تمت إضافة سائق مساعد للتوصيل ${orderLabel}. رسوم إضافية: ${event.assistFee}. وافق أو ارفض.`
        : `تمت إضافة سائق مساعد. رسوم إضافية: ${event.assistFee}. وافق أو ارفض.`;

      await this.enqueueNotification({
        userId: event.customerUserId,
        title: 'Assisted delivery proposed',
        titleAr: 'تم اقتراح توصيل بمساعدة',
        body,
        bodyAr,
        data: {
          orderId: event.orderId,
          ...groupFields,
          assistFee: event.assistFee,
          action: 'assist_decision',
        },
      });

      await this.emitSocket(event.customerUserId, 'order.assist.proposed', {
        orderId: event.orderId,
        ...groupFields,
        assistFee: event.assistFee,
      });
    }

    if (event.assistDriverUserId) {
      await this.enqueueNotification({
        userId: event.assistDriverUserId,
        title: 'Assisting a delivery',
        titleAr: 'مساعد في توصيل',
        body: `You were assigned to assist delivery ${orderLabel}. You earn the full delivery fee.`,
        bodyAr: `تم تعيينك لمساعدة التوصيل ${orderLabel}. تحصل على كامل أجرة التوصيل.`,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
        },
      });

      await this.emitSocket(event.assistDriverUserId, 'order.assigned', {
        orderId: event.orderId,
        orderNumber: event.orderNumber,
        ...groupFields,
        role: 'ASSISTING',
      });
    }

    if (
      event.primaryDriverUserId &&
      event.primaryDriverUserId !== event.assistDriverUserId
    ) {
      await this.enqueueNotification({
        userId: event.primaryDriverUserId,
        title: 'Assisting driver assigned',
        titleAr: 'تم تعيين سائق مساعد',
        body: `A second driver was added to delivery ${orderLabel}. You remain the primary driver.`,
        bodyAr: `تمت إضافة سائق ثانٍ للتوصيل ${orderLabel}. لا تزال السائق الأساسي.`,
        data: {
          orderId: event.orderId,
          orderNumber: event.orderNumber,
        },
      });
    }
  }

  @OnEvent(EVENTS.DRIVER_ASSIST_CUSTOMER_DECIDED, { async: true })
  async handleCustomerDecided(
    event: DriverAssistCustomerDecidedEvent,
  ): Promise<void> {
    const groupFields = event.deliveryGroupId
      ? { deliveryGroupId: event.deliveryGroupId }
      : {};
    const recipients = new Set(
      [event.primaryDriverUserId, event.assistDriverUserId].filter(
        (id): id is string => Boolean(id),
      ),
    );

    const copy = event.approved
      ? {
          title: 'Assisted delivery approved',
          titleAr: 'تمت الموافقة على التوصيل بمساعدة',
          body: 'The customer approved the assisted delivery.',
          bodyAr: 'وافق العميل على التوصيل بمساعدة.',
          data: {
            orderId: event.orderId,
            ...groupFields,
            assistFee: event.assistFee,
          },
        }
      : {
          title: 'Assisted delivery declined',
          titleAr: 'رفض العميل التوصيل بمساعدة',
          body: 'The customer declined the assisted delivery.',
          bodyAr: 'رفض العميل التوصيل بمساعدة.',
          data: {
            orderId: event.orderId,
            ...groupFields,
          },
        };

    for (const userId of recipients) {
      await this.enqueueNotification({ userId, ...copy });
      await this.emitSocket(userId, 'order.assist.decided', {
        orderId: event.orderId,
        ...groupFields,
        approved: event.approved,
        assistFee: event.assistFee,
      });
    }
  }

  @OnEvent(EVENTS.DRIVER_ASSIST_TIMED_OUT, { async: true })
  async handleAssistTimedOut(event: DriverAssistTimedOutEvent): Promise<void> {
    const data = {
      orderId: event.orderId,
      ...(event.deliveryGroupId
        ? { deliveryGroupId: event.deliveryGroupId }
        : {}),
    };

    const messages: Array<{
      userId: string | null;
      body: string;
      bodyAr: string;
    }> = [
      {
        userId: event.customerUserId,
        body: 'No response was received; the assisting driver was removed.',
        bodyAr: 'لم يتم تلقي رد؛ تمت إزالة السائق المساعد.',
      },
      {
        userId: event.primaryDriverUserId,
        body: 'The assisting driver was removed (no customer response).',
        bodyAr: 'تمت إزالة السائق المساعد (لا رد من العميل).',
      },
      {
        userId:
          event.assistDriverUserId &&
          event.assistDriverUserId !== event.primaryDriverUserId
            ? event.assistDriverUserId
            : null,
        body: 'You were unassigned (no customer response).',
        bodyAr: 'تم إلغاء تعيينك (لا رد من العميل).',
      },
    ];

    for (const msg of messages) {
      if (!msg.userId) continue;
      await this.enqueueNotification({
        userId: msg.userId,
        title: 'Assisted delivery timed out',
        titleAr: 'انتهت مهلة التوصيل بمساعدة',
        body: msg.body,
        bodyAr: msg.bodyAr,
        data,
      });
      await this.emitSocket(msg.userId, 'order.assist.timed_out', data);
    }
  }

  private async enqueueNotification(dto: {
    userId: string;
    title: string;
    titleAr: string;
    body: string;
    bodyAr: string;
    data: Record<string, unknown>;
  }): Promise<void> {
    try {
      await this.eventsQueue.add(EVENT_JOBS.NOTIFY, {
        dto: {
          ...dto,
          type: NotificationType.ORDER_UPDATE,
        },
      });
    } catch (error) {
      this.logger.warn(
        `Failed to enqueue notification for user ${dto.userId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private async emitSocket(
    userId: string,
    event: string,
    payload: Record<string, unknown>,
  ): Promise<void> {
    try {
      await this.socketService.emitToUser(userId, event, payload);
    } catch (error) {
      this.logger.warn(
        `Failed to emit socket ${event} to user ${userId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
