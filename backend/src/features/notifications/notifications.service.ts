import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PushService } from '../../infrastructure/push/push.service';
import { SocketService } from '../../infrastructure/socket/socket.service';
import {
  QueryNotificationsDto,
  MarkNotificationsReadDto,
  CreateNotificationDto,
} from './dto/notification.dto';
import {
  DispatchAnnouncementDto,
  AnnouncementAudience,
} from './dto/dispatch-announcement.dto';
import { Language, NotificationType, Prisma } from '@prisma/client';
import {
  CommonErrors,
  NotificationErrors,
} from 'src/common/constants/response.constants';
import { randomUUID } from 'crypto';
import { WS_EVENTS } from '../../common/events/ws-events';

export const SOCKET_EVENTS = {
  NOTIFICATION: WS_EVENTS.NOTIFICATION,
  CHAT_MESSAGE: WS_EVENTS.CHAT_MESSAGE,
  CHAT_READ: WS_EVENTS.CHAT_READ,
  CONVERSATION_CREATED: WS_EVENTS.CONVERSATION_CREATED,
  CONVERSATION_CLOSED: WS_EVENTS.CONVERSATION_CLOSED,
} as const;

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushService: PushService,
    private readonly socketService: SocketService,
  ) {}

  async create(dto: CreateNotificationDto) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: dto.userId,
        title: dto.title,
        titleAr: dto.titleAr ?? null,
        body: dto.body ?? null,
        bodyAr: dto.bodyAr ?? null,
        type: dto.type,
        data: dto.data,
        isRead: false,
      },
    });

    try {
      await this.socketService.emitToUser(
        dto.userId,
        SOCKET_EVENTS.NOTIFICATION,
        {
          id: notification.id,
          title: notification.title,
          titleAr: notification.titleAr,
          body: notification.body,
          bodyAr: notification.bodyAr,
          type: notification.type,
          data: notification.data,
          createdAt: notification.createdAt,
        },
      );
    } catch (err) {
      this.logger.error(
        `Socket emit failed for user ${dto.userId}: ${(err as Error).message}`,
      );
    }

    try {
      await this.dispatchPush(
        dto.userId,
        dto.type,
        dto.title,
        dto.titleAr ?? null,
        dto.body ?? null,
        dto.bodyAr ?? null,
        dto.data as Record<string, string> | undefined,
      );
    } catch (err) {
      this.logger.error(
        `Push dispatch failed for user ${dto.userId}: ${(err as Error).message}`,
      );
    }

    return notification;
  }

  async createMany(dtos: CreateNotificationDto[]) {
    if (!dtos.length) return [];

    const now = new Date();
    const payloads = dtos.map((dto) => ({
      id: randomUUID(),
      userId: dto.userId,
      title: dto.title,
      titleAr: dto.titleAr ?? null,
      body: dto.body ?? null,
      bodyAr: dto.bodyAr ?? null,
      type: dto.type,
      data: dto.data ?? null,
      isRead: false,
      createdAt: now,
    }));

    await this.prisma.notification.createMany({
      data: payloads as Prisma.NotificationCreateManyInput[],
    });

    const userIds = [...new Set(dtos.map((d) => d.userId))];

    const users = await this.prisma.user.findMany({
      where: { id: { in: userIds }, isBanned: false, deletedAt: null },
      select: {
        id: true,
        language: true,
        devices: { select: { token: true } },
        notificationSettings: {
          select: {
            pushEnabled: true,
            orderUpdates: true,
            chatMessages: true,
            promotions: true,
            system: true,
            ticketUpdates: true,
          },
        },
      },
    });

    const userMap = new Map(users.map((u) => [u.id, u]));

    const pushPromises: Promise<any>[] = [];

    for (const p of payloads) {
      // 1. Emit socket
      this.socketService
        .emitToUser(p.userId, SOCKET_EVENTS.NOTIFICATION, {
          id: p.id,
          title: p.title,
          titleAr: p.titleAr,
          body: p.body,
          bodyAr: p.bodyAr,
          type: p.type,
          data: p.data ?? null,
          createdAt: p.createdAt,
        })
        .catch((err) =>
          this.logger.error(
            `Socket emit failed for user ${p.userId}: ${(err as Error).message}`,
          ),
        );

      // 2. Prepare Push
      const user = userMap.get(p.userId);
      if (!user) {
        this.logger.warn(
          `Push skipped for user ${p.userId}: user missing, banned, or deleted`,
        );
        continue;
      }
      if (
        user.notificationSettings &&
        !this.isTypeAllowed(p.type, user.notificationSettings)
      ) {
        this.logger.log(
          `Push suppressed for user ${p.userId}: type ${p.type} disabled in settings`,
        );
        continue;
      }
      const tokens = Array.from(
        new Set(user.devices.map((d) => d.token).filter(Boolean)),
      );
      if (!tokens.length) {
        this.logger.warn(
          `Push skipped for user ${p.userId}: no registered FCM devices (type=${p.type})`,
        );
        continue;
      }

      const isArabic = user.language === Language.AR;
      const pushTitle = isArabic ? (p.titleAr ?? p.title) : p.title;
      const pushBody = (isArabic ? (p.bodyAr ?? p.body) : p.body) || pushTitle;
      const parsedData = this.sanitizePushData(p.data);

      this.logger.log(
        `Push queuing → user ${p.userId} | type=${p.type} | lang=${user.language} | ${tokens.length} device(s)`,
      );

      pushPromises.push(
        this.pushService
          .sendToDevices(tokens, pushTitle, pushBody, parsedData)
          .catch((err) =>
            this.logger.error(
              `Push dispatch failed for user ${p.userId}: ${(err as Error).message}`,
            ),
          ),
      );
    }

    await Promise.all(pushPromises);
    return payloads;
  }

  private async dispatchPush(
    userId: string,
    type: NotificationType,
    title: string,
    titleAr: string | null,
    body: string | null,
    bodyAr: string | null,
    data?: Record<string, any>,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        isBanned: true,
        deletedAt: true,
        language: true,
        devices: { select: { token: true } },
        notificationSettings: {
          select: {
            pushEnabled: true,
            orderUpdates: true,
            chatMessages: true,
            promotions: true,
            system: true,
            ticketUpdates: true,
          },
        },
      },
    });

    if (!user || user.isBanned || user.deletedAt) {
      this.logger.warn(
        `User ${userId} missing/banned/deleted, skipping push (type=${type})`,
      );
      return;
    }

    if (user.notificationSettings) {
      if (!this.isTypeAllowed(type, user.notificationSettings)) {
        this.logger.log(
          `Push suppressed for user ${userId}: type ${type} disabled in settings`,
        );
        return;
      }
    }

    const tokens = Array.from(
      new Set(user.devices.map((d) => d.token).filter(Boolean)),
    );
    if (!tokens.length) {
      this.logger.warn(
        `No registered FCM devices for user ${userId}, skipping push (type=${type})`,
      );
      return;
    }

    const isArabic = user.language === Language.AR;
    const pushTitle = isArabic ? (titleAr ?? title) : title;
    const pushBody = (isArabic ? (bodyAr ?? body) : body) || pushTitle;
    const sanitizedData = this.sanitizePushData(data);

    await this.pushService.sendToDevices(
      tokens,
      pushTitle,
      pushBody,
      sanitizedData,
    );

    this.logger.log(
      `Push queued → user ${userId} | type=${type} | lang=${user.language} | ${tokens.length} device(s)`,
    );
  }

  private sanitizePushData(
    data?: Record<string, any> | null,
  ): Record<string, string> | undefined {
    if (!data || typeof data !== 'object') return undefined;
    const entries = Object.entries(data)
      .filter(([, v]) => v !== undefined && v !== null)
      .map(([k, v]) => [k, typeof v === 'string' ? v : JSON.stringify(v)]);
    return entries.length > 0 ? Object.fromEntries(entries) : undefined;
  }

  private isTypeAllowed(
    type: NotificationType,
    settings: {
      pushEnabled: boolean;
      orderUpdates: boolean;
      chatMessages: boolean;
      promotions: boolean;
      system: boolean;
      ticketUpdates: boolean;
    },
  ): boolean {
    if (!settings.pushEnabled) return false;

    switch (type) {
      case NotificationType.ORDER_UPDATE:
        return settings.orderUpdates;
      case NotificationType.CHAT_MESSAGE:
        return settings.chatMessages;
      case NotificationType.PROMOTION:
        return settings.promotions;
      case NotificationType.SYSTEM:
      case NotificationType.PAYMENT:
        return settings.system;
      case NotificationType.TICKET_UPDATE:
        return settings.ticketUpdates;
      default:
        return true;
    }
  }

  async list(userId: string, dto: QueryNotificationsDto) {
    const { page = 1, limit = 20, unreadOnly, type } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.NotificationWhereInput = { userId };
    if (unreadOnly) where.isRead = false;
    if (type) where.type = type;

    const [notifications, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    return {
      notifications,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      unreadCount,
    };
  }

  async getOne(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification)
      throw new NotFoundException(NotificationErrors.NOT_FOUND);
    if (notification.userId !== userId)
      throw new ForbiddenException(CommonErrors.FORBIDDEN);

    return notification;
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  async markRead(userId: string, dto: MarkNotificationsReadDto) {
    if (dto.ids?.length) {
      const uniqueIds = [...new Set(dto.ids)];
      const owned = await this.prisma.notification.count({
        where: { id: { in: uniqueIds }, userId },
      });
      if (owned !== uniqueIds.length)
        throw new ForbiddenException(CommonErrors.FORBIDDEN);

      const { count } = await this.prisma.notification.updateMany({
        where: { id: { in: uniqueIds }, userId },
        data: { isRead: true },
      });

      return { marked: count };
    }

    const { count } = await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return { marked: count };
  }

  async markOneRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification)
      throw new NotFoundException(NotificationErrors.NOT_FOUND);
    if (notification.userId !== userId)
      throw new ForbiddenException(CommonErrors.FORBIDDEN);

    if (notification.isRead) return notification;

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }

  async deleteOne(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification)
      throw new NotFoundException(NotificationErrors.NOT_FOUND);
    if (notification.userId !== userId)
      throw new ForbiddenException(CommonErrors.FORBIDDEN);

    await this.prisma.notification.delete({ where: { id: notificationId } });
    return { deleted: true };
  }

  async deleteAllRead(userId: string) {
    const { count } = await this.prisma.notification.deleteMany({
      where: { userId, isRead: true },
    });
    return { deleted: count };
  }
  // ─── Mass Announcements ──────────────────────────────────────────────────

  async dispatchAnnouncement(dto: DispatchAnnouncementDto) {
    let topic = '';
    switch (dto.audience) {
      case AnnouncementAudience.CUSTOMERS:
        topic = 'topic_customers';
        break;
      case AnnouncementAudience.DRIVERS:
        topic = 'topic_drivers';
        break;
      case AnnouncementAudience.VENDORS:
        topic = 'topic_vendors';
        break;
      case AnnouncementAudience.ALL:
        topic = 'topic_all';
        break;
    }

    // Prepare FCM data payload
    const dataPayload: Record<string, string> = {
      type: dto.type ?? NotificationType.ANNOUNCEMENT,
      ...(dto.titleAr ? { titleAr: dto.titleAr } : {}),
      ...(dto.bodyAr ? { bodyAr: dto.bodyAr } : {}),
      ...dto.data,
    };

    // Note: We are relying on the mobile apps to subscribe to 'topic_customers',
    // 'topic_drivers', 'topic_vendors', and 'topic_all' during app startup/login.
    await this.pushService.sendToTopic(
      topic,
      dto.title,
      dto.body || dto.title,
      dataPayload,
    );

    this.logger.log(`📢 Dispatched announcement to topic: ${topic}`);
    return { success: true, topic };
  }
}
