import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { MessageType, NotificationType } from '@prisma/client';
import { SocketService } from '../../infrastructure/socket/socket.service';
import {
  ChatMessageSentEvent,
  ChatMessageReadEvent,
  ChatConversationCreatedEvent,
  ChatConversationClosedEvent,
} from '../events';
import { EVENTS } from '../events/event-names';
import { WS_EVENTS } from '../events/ws-events';
import {
  QUEUES,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

@Injectable()
export class ChatListener {
  private readonly logger = new Logger(ChatListener.name);

  constructor(
    private readonly socketService: SocketService,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
  ) {}

  @OnEvent(EVENTS.CHAT_MESSAGE_SENT, { async: true })
  async handleMessageSent(event: ChatMessageSentEvent) {
    const isSystem = event.type === MessageType.SYSTEM;

    const socketPayload = {
      messageId: event.messageId,
      id: event.messageId,
      conversationId: event.conversationId,
      orderId: event.orderId ?? null,
      senderId: event.senderId,
      senderName: event.senderName,
      senderAvatar: event.senderAvatar ?? null,
      senderRole: event.senderRole,
      senderTitle: event.senderTitle ?? null,
      senderTitleAr: event.senderTitleAr ?? null,
      sender: {
        id: event.senderId,
        name: event.senderName,
        avatar: event.senderAvatar ?? null,
        role: event.senderRole,
        title: event.senderTitle ?? null,
        titleAr: event.senderTitleAr ?? null,
      },
      type: event.type,
      text: event.text,
      mediaUrl: event.mediaUrl,
      metadata: event.metadata,
      replyTo: event.replyTo ?? null,
      isSystem,
      createdAt: event.createdAt,
    };

    // Realtime socket fan-out stays inline; only the DB batch (createMany)
    // for push/notification records is offloaded to the worker.
    this.logger.log(
      `Notifying chat participants: ${event.participantIds.join(', ')}`,
    );
    await Promise.all(
      event.participantIds.map((userId) =>
        this.socketService
          .emitToUser(userId, WS_EVENTS.CHAT_MESSAGE, socketPayload)
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to emit ${WS_EVENTS.CHAT_MESSAGE} for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
      ),
    );

    if (isSystem) return;

    const recipients = event.participantIds.filter(
      (id) => id !== event.senderId,
    );

    const notificationPayloads = recipients.map((userId) => ({
      userId,
      title: 'New message',
      titleAr: 'رسالة جديدة',
      body: this.buildPreview(event),
      bodyAr: this.buildPreviewAr(event),
      type: NotificationType.CHAT_MESSAGE,
      data: {
        conversationId: event.conversationId,
        orderId: event.orderId ?? null,
        messageId: event.messageId,
        senderId: event.senderId,
        chatType: event.conversationType ?? null,
      },
    }));

    if (!notificationPayloads.length) return;

    try {
      await this.eventsQueue.add(
        EVENT_JOBS.CHAT_NOTIFICATIONS,
        { dtos: notificationPayloads },
        { attempts: 1 },
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue chat notifications: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  @OnEvent(EVENTS.CHAT_MESSAGE_READ, { async: true })
  async handleMessageRead(event: ChatMessageReadEvent) {
    const payload = {
      conversationId: event.conversationId,
      userId: event.userId,
      lastReadAt: event.lastReadAt,
      lastReadMessageId: event.lastReadMessageId,
    };

    const recipientIds = event.participantIds.filter(
      (id) => id !== event.userId,
    );

    await Promise.all(
      recipientIds.map((userId) =>
        this.socketService
          .emitToUser(userId, WS_EVENTS.CHAT_READ, payload)
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to emit ${WS_EVENTS.CHAT_READ} for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
      ),
    );
  }

  @OnEvent(EVENTS.CHAT_CONVERSATION_CREATED, { async: true })
  async handleConversationCreated(event: ChatConversationCreatedEvent) {
    const payload = {
      conversationId: event.conversationId,
      type: event.type,
      orderId: event.orderId,
    };

    await Promise.all(
      event.participantIds.map((userId) =>
        this.socketService
          .emitToUser(userId, WS_EVENTS.CONVERSATION_CREATED, payload)
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to emit ${WS_EVENTS.CONVERSATION_CREATED} for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
      ),
    );
  }

  @OnEvent(EVENTS.CHAT_CONVERSATION_CLOSED, { async: true })
  async handleConversationClosed(event: ChatConversationClosedEvent) {
    const payload = {
      conversationId: event.conversationId,
      closedBy: event.closedBy,
    };

    await Promise.all(
      event.participantIds.map((userId) =>
        this.socketService
          .emitToUser(userId, WS_EVENTS.CONVERSATION_CLOSED, payload)
          .catch((err: unknown) =>
            this.logger.error(
              `Failed to emit ${WS_EVENTS.CONVERSATION_CLOSED} for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
            ),
          ),
      ),
    );
  }

  private buildPreview(event: ChatMessageSentEvent): string {
    if (event.text) {
      return event.text.length > 80
        ? event.text.slice(0, 80) + '…'
        : event.text;
    }

    switch (event.type as MessageType) {
      case MessageType.IMAGE:
        return 'Sent a photo';
      case MessageType.VIDEO:
        return 'Sent a video';
      case MessageType.AUDIO:
        return 'Sent a voice message';
      case MessageType.LOCATION:
        return 'Shared a location';
      case MessageType.PRODUCT: {
        const productName = (
          event.metadata as { product?: { name?: string } } | null
        )?.product?.name;
        return productName ? `Sent offer: ${productName}` : 'Sent an offer';
      }
      default:
        return 'New message';
    }
  }

  private buildPreviewAr(event: ChatMessageSentEvent): string {
    if (event.text) {
      return event.text.length > 80
        ? event.text.slice(0, 80) + '…'
        : event.text;
    }

    switch (event.type as MessageType) {
      case MessageType.IMAGE:
        return 'أرسل صورة';
      case MessageType.VIDEO:
        return 'أرسل فيديو';
      case MessageType.AUDIO:
        return 'أرسل رسالة صوتية';
      case MessageType.LOCATION:
        return 'شارك موقعاً';
      case MessageType.PRODUCT: {
        const productName = (
          event.metadata as { product?: { name?: string } } | null
        )?.product?.name;
        return productName ? `أرسل عرضاً: ${productName}` : 'أرسل عرض منتج';
      }
      default:
        return 'رسالة جديدة';
    }
  }
}
