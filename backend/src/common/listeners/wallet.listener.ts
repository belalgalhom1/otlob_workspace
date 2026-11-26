import { Injectable, Logger, Optional } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationType, Permission, Role } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  EVENT_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';
import { EVENTS } from '../events/event-names';
import {
  WalletTopUpReviewedEvent,
  WalletTopUpSubmittedEvent,
} from '../events/wallet.events';

function formatWalletLabel(
  type: string | null | undefined,
  number: string | null | undefined,
  lang: 'en' | 'ar',
): string {
  const normalizedType = (type ?? '').trim().toUpperCase();
  const typeLabel = !normalizedType
    ? ''
    : normalizedType.includes('INSTAPAY')
      ? lang === 'ar'
        ? 'إنستا باي'
        : 'InstaPay'
      : lang === 'ar'
        ? 'محفظة إلكترونية'
        : 'Mobile Wallet';
  const cleanNumber = (number ?? '').trim();
  if (typeLabel && cleanNumber) return `${typeLabel} - ${cleanNumber}`;
  return typeLabel || cleanNumber;
}

/**
 * Owns push/in-app/socket notifications for driver wallet top-up / adjustment
 * submissions and Super Admin / Finance Admin approval & rejection reviews.
 */
@Injectable()
export class WalletListener {
  private readonly logger = new Logger(WalletListener.name);

  constructor(
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    @Optional() private readonly prisma?: PrismaService,
  ) {}

  @OnEvent(EVENTS.WALLET_TOPUP_SUBMITTED, { async: true })
  async handleTopUpSubmitted(event: WalletTopUpSubmittedEvent) {
    if (!this.prisma) {
      this.logger.warn(
        `PrismaService unavailable; cannot resolve Super Admin recipients for top-up ${event.requestId}`,
      );
      return;
    }

    try {
      const recipients = await this.prisma.user.findMany({
        where: {
          isBanned: false,
          deletedAt: null,
          id: { not: event.driverUserId },
          OR: [
            { role: Role.SUPER_ADMIN },
            {
              role: Role.ADMIN,
              permissions: { has: Permission.MANAGE_FINANCE },
            },
          ],
        },
        select: { id: true },
      });

      const uniqueRecipientIds = Array.from(
        new Set(recipients.map((r) => r.id).filter(Boolean)),
      );

      if (uniqueRecipientIds.length === 0) {
        this.logger.warn(
          `No eligible Super Admin / MANAGE_FINANCE admin recipients found for driver adjustment ${event.requestId}`,
        );
        return;
      }

      const driverName = event.driverName.trim() || 'Driver';
      const walletEn = formatWalletLabel(
        event.platformWalletType,
        event.platformWalletNumber,
        'en',
      );
      const walletAr = formatWalletLabel(
        event.platformWalletType,
        event.platformWalletNumber,
        'ar',
      );
      const walletSuffixEn = walletEn ? ` (${walletEn})` : '';
      const walletSuffixAr = walletAr ? ` (${walletAr})` : '';

      this.logger.log(
        `Enqueuing driver adjustment ${event.requestId} notification for ${uniqueRecipientIds.length} eligible admin(s)`,
      );

      await Promise.all(
        uniqueRecipientIds.map((adminId) => {
          const dedupeKey = `wallet_topup_submitted:${event.requestId}:${adminId}`;
          const jobId = `wallet_topup_submitted_${event.requestId}_${adminId}`;
          return this.eventsQueue
            .add(
              EVENT_JOBS.NOTIFY,
              {
                dto: {
                  userId: adminId,
                  title: 'New Driver Adjustment Request',
                  titleAr: 'طلب تسوية محفظة جديد من سائق',
                  body: `${driverName} submitted a wallet adjustment of ${event.amount} EGP${walletSuffixEn}.`,
                  bodyAr: `قدّم السائق ${driverName} طلب تسوية محفظة بمبلغ ${event.amount} ج.م${walletSuffixAr}.`,
                  type: NotificationType.PAYMENT,
                  dedupeKey,
                  data: {
                    kind: 'wallet_topup',
                    action: 'submitted',
                    route: 'wallet_topup_details',
                    requestId: event.requestId,
                    topUpId: event.requestId,
                    driverId: event.driverId,
                    driverName,
                    amount: String(event.amount),
                    status: 'PENDING',
                    platformWalletType: event.platformWalletType,
                    platformWalletNumber: event.platformWalletNumber,
                  },
                },
              },
              { jobId },
            )
            .catch((err: unknown) => {
              this.logger.error(
                `Failed to enqueue driver adjustment notification for admin ${adminId}: ${err instanceof Error ? err.message : String(err)}`,
              );
            });
        }),
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to notify Super Admins for driver adjustment ${event.requestId}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  @OnEvent(EVENTS.WALLET_TOPUP_REVIEWED, { async: true })
  async handleTopUpReviewed(event: WalletTopUpReviewedEvent) {
    if (!event.driverUserId) {
      this.logger.warn(
        `Missing driverUserId for reviewed adjustment ${event.requestId}; skipping driver notification`,
      );
      return;
    }

    const isApproved = event.status === 'APPROVED';
    const trimmedNotes = event.notes?.trim() || null;
    const walletEn = formatWalletLabel(
      event.platformWalletType,
      event.platformWalletNumber,
      'en',
    );
    const walletAr = formatWalletLabel(
      event.platformWalletType,
      event.platformWalletNumber,
      'ar',
    );
    const walletSuffixEn = walletEn ? ` (${walletEn})` : '';
    const walletSuffixAr = walletAr ? ` (${walletAr})` : '';

    let title: string;
    let titleAr: string;
    let body: string;
    let bodyAr: string;

    if (isApproved) {
      title = 'Wallet Adjustment Approved';
      titleAr = 'تمت الموافقة على تسوية المحفظة';
      const balanceEn =
        event.newBalance !== null
          ? ` New balance: ${event.newBalance} EGP.`
          : '';
      const balanceAr =
        event.newBalance !== null
          ? ` الرصيد الحالي: ${event.newBalance} ج.م.`
          : '';
      const unsuspendedEn = event.unsuspended
        ? ' Your account is now active and you can receive orders again.'
        : '';
      const unsuspendedAr = event.unsuspended
        ? ' تم فك تعليق حسابك ويمكنك الآن استقبال الطلبات مرة أخرى.'
        : '';
      const notesEn = trimmedNotes ? ` Note: ${trimmedNotes}` : '';
      const notesAr = trimmedNotes ? ` ملاحظة: ${trimmedNotes}` : '';
      body = `Your adjustment request of ${event.amount} EGP${walletSuffixEn} was approved.${balanceEn}${unsuspendedEn}${notesEn}`;
      bodyAr = `تمت الموافقة على طلب تسوية المحفظة بمبلغ ${event.amount} ج.م${walletSuffixAr}.${balanceAr}${unsuspendedAr}${notesAr}`;
    } else {
      title = 'Wallet Adjustment Rejected';
      titleAr = 'تم رفض تسوية المحفظة';
      const reasonEn = trimmedNotes ? ` Reason: ${trimmedNotes}` : '';
      const reasonAr = trimmedNotes ? ` السبب: ${trimmedNotes}` : '';
      body = `Your adjustment request of ${event.amount} EGP${walletSuffixEn} was rejected.${reasonEn}`;
      bodyAr = `تم رفض طلب تسوية المحفظة بمبلغ ${event.amount} ج.م${walletSuffixAr}.${reasonAr}`;
    }

    const dedupeKey = `wallet_topup_reviewed:${event.requestId}:${event.status}:${event.driverUserId}`;
    const jobId = `wallet_topup_reviewed_${event.requestId}_${event.status}_${event.driverUserId}`;

    try {
      await this.eventsQueue.add(
        EVENT_JOBS.NOTIFY,
        {
          dto: {
            userId: event.driverUserId,
            title,
            titleAr,
            body,
            bodyAr,
            type: NotificationType.PAYMENT,
            dedupeKey,
            data: {
              kind: 'wallet_topup',
              action: isApproved ? 'approved' : 'rejected',
              route: '/wallet',
              requestId: event.requestId,
              topUpId: event.requestId,
              driverId: event.driverId,
              amount: String(event.amount),
              status: event.status,
              ...(trimmedNotes ? { notes: trimmedNotes } : {}),
              ...(event.newBalance !== null
                ? { newBalance: String(event.newBalance) }
                : {}),
              ...(event.unsuspended ? { unsuspended: 'true' } : {}),
            },
          },
        },
        { jobId },
      );

      this.logger.log(
        `Enqueued driver adjustment ${event.status} notification for driver user ${event.driverUserId} (request ${event.requestId})`,
      );
    } catch (error: unknown) {
      this.logger.error(
        `Failed to enqueue driver adjustment review notification for request ${event.requestId}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }
}
