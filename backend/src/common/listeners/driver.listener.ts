import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { SocketService } from '../../infrastructure/socket/socket.service';
import { NotificationType, DriverStatus } from '@prisma/client';
import {
  DriverLocationUpdatedEvent,
  DriverStatusChangedEvent,
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
}
