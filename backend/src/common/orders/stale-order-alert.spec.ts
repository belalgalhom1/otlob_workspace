import { NotificationType, OrderStatus, Role } from '@prisma/client';
import {
  DEFAULT_STALE_ORDER_ALERT_INTERVAL_MINS,
  StaleOrderAlertService,
} from './stale-order-alert.service';
import { OrdersProcessor } from '../../features/orders/orders.processor';
import {
  CRON_JOBS,
  EVENT_JOBS,
} from '../../infrastructure/queue/queues.constants';

describe('StaleOrderAlertService & No-Auto-Cancel Order Policy', () => {
  it('defaults interval to 5 min, throttles per order/reason in Redis, and notifies all active SUPER_ADMINs', async () => {
    const store = new Map<string, string>();
    const redis: any = {
      setNX: jest.fn().mockImplementation(async (key: string, val: string) => {
        if (store.has(key)) return false;
        store.set(key, val);
        return true;
      }),
    };
    const prisma: any = {
      user: {
        findMany: jest
          .fn()
          .mockResolvedValue([{ id: 'super-1' }, { id: 'super-2' }]),
      },
    };
    const eventsQueue: any = {
      add: jest.fn().mockResolvedValue(undefined),
    };

    const service = new StaleOrderAlertService(prisma, redis, eventsQueue);
    expect(service.resolveIntervalMins(undefined)).toBe(
      DEFAULT_STALE_ORDER_ALERT_INTERVAL_MINS,
    );
    expect(service.resolveIntervalMins(10)).toBe(10);

    const first = await service.alertOrderIfDue({
      orderId: 'ord-100',
      orderNumber: 'OTL-100',
      reason: 'PENDING_VENDOR',
      referenceTime: new Date(Date.now() - 8 * 60_000),
      intervalMins: 5,
    });

    expect(first).toEqual({ alerted: true, recipientCount: 2 });
    expect(redis.setNX).toHaveBeenCalledWith(
      'stale_order_alert:ord-100:PENDING_VENDOR',
      expect.any(String),
      300,
    );
    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          role: Role.SUPER_ADMIN,
          isBanned: false,
          deletedAt: null,
        }),
      }),
    );
    expect(eventsQueue.add).toHaveBeenCalledTimes(2);
    expect(eventsQueue.add).toHaveBeenCalledWith(
      EVENT_JOBS.NOTIFY,
      expect.objectContaining({
        dto: expect.objectContaining({
          userId: 'super-1',
          type: NotificationType.ORDER_UPDATE,
          titleAr: 'تنبيه طلب معلق #OTL-100',
          data: expect.objectContaining({
            kind: 'stale_order_alert',
            alertReason: 'PENDING_VENDOR',
            orderId: 'ord-100',
            orderNumber: 'OTL-100',
            intervalMins: '5',
          }),
        }),
      }),
      expect.any(Object),
    );

    // Second run within the 5-minute TTL window is throttled
    const second = await service.alertOrderIfDue({
      orderId: 'ord-100',
      orderNumber: 'OTL-100',
      reason: 'PENDING_VENDOR',
      referenceTime: new Date(Date.now() - 9 * 60_000),
      intervalMins: 5,
    });
    expect(second).toEqual({ alerted: false, recipientCount: 0 });
    expect(eventsQueue.add).toHaveBeenCalledTimes(2);

    // Simulate TTL expiry after 5 minutes -> sends the next recurring reminder
    store.delete('stale_order_alert:ord-100:PENDING_VENDOR');
    const third = await service.alertOrderIfDue({
      orderId: 'ord-100',
      orderNumber: 'OTL-100',
      reason: 'PENDING_VENDOR',
      referenceTime: new Date(Date.now() - 13 * 60_000),
      intervalMins: 5,
    });
    expect(third).toEqual({ alerted: true, recipientCount: 2 });
    expect(eventsQueue.add).toHaveBeenCalledTimes(4);
  });

  it('OrdersProcessor never auto-cancels pending/driverless/unpaid orders and alerts Super Admins instead', async () => {
    const cancelOrder = jest.fn();
    const vendorReject = jest.fn();
    const alertOrderIfDue = jest
      .fn()
      .mockResolvedValue({ alerted: true, recipientCount: 1 });
    const staleOrderAlertService: any = {
      resolveIntervalMins: jest.fn((v: number | undefined) => v ?? 5),
      alertOrderIfDue,
    };

    const staleCreated = new Date(Date.now() - 12 * 60_000);
    const orderFindMany = jest
      .fn()
      // handleAutoCancelPendingOrders: 1) pendingVendorOrders, 2) awaitingDriverOrders
      .mockResolvedValueOnce([
        { id: 'ord-pend', orderNumber: 'OTL-P1', createdAt: staleCreated },
      ])
      .mockResolvedValueOnce([
        {
          id: 'ord-drv',
          orderNumber: 'OTL-D1',
          createdAt: staleCreated,
          updatedAt: staleCreated,
        },
      ])
      // handleStuckOrderMonitor: 1) stuckOrders, 2) stuckPaymentOrders
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([
        {
          id: 'ord-pay',
          orderNumber: 'OTL-M1',
          createdAt: staleCreated,
          updatedAt: staleCreated,
        },
      ]);

    const prisma: any = {
      order: { findMany: orderFindMany },
    };

    const processor = new OrdersProcessor(
      { cancelOrder } as any,
      { reject: vendorReject } as any,
      {} as any,
      {
        getSettings: jest.fn().mockResolvedValue({
          staleOrderAlertIntervalMins: 7,
          mobileWalletTimeoutMins: 15,
          driverSearchMaxAttempts: 5,
        }),
      } as any,
      prisma,
      {} as any,
      { add: jest.fn() } as any,
      { add: jest.fn() } as any,
      { relayPending: jest.fn() } as any,
      staleOrderAlertService,
    );

    await processor.process({ name: CRON_JOBS.AUTO_CANCEL_PENDING } as any);
    await processor.process({ name: CRON_JOBS.STUCK_ORDER_MONITOR } as any);

    expect(cancelOrder).not.toHaveBeenCalled();
    expect(vendorReject).not.toHaveBeenCalled();

    expect(alertOrderIfDue).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'ord-pend',
        reason: 'PENDING_VENDOR',
        intervalMins: 7,
      }),
    );
    expect(alertOrderIfDue).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'ord-drv',
        reason: 'NO_DRIVER_FOUND',
        intervalMins: 7,
      }),
    );
    expect(alertOrderIfDue).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'ord-pay',
        reason: 'PENDING_PAYMENT',
        intervalMins: 7,
      }),
    );
  });
});
