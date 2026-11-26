import { NotFoundException } from '@nestjs/common';
import {
  DriverStatus,
  Language,
  NotificationType,
  Permission,
  Role,
} from '@prisma/client';
import { Job } from 'bullmq';
import { WalletService } from './wallet.service';
import { WalletListener } from '../../common/listeners/wallet.listener';
import { DriverListener } from '../../common/listeners/driver.listener';
import { EventsProcessor } from '../events/events.processor';
import { NotificationsService } from '../notifications/notifications.service';
import { PushProcessor } from '../../infrastructure/push/push.processor';
import { EVENTS } from '../../common/events/event-names';
import {
  DriverStatusChangedEvent,
  WalletTopUpReviewedEvent,
  WalletTopUpSubmittedEvent,
} from '../../common/events';
import {
  EVENT_JOBS,
  PUSH_JOBS,
} from '../../infrastructure/queue/queues.constants';

describe('Driver Adjustments (WalletTopUpRequest) Push Notification Lifecycle', () => {
  describe('WalletService events & review notes persistence', () => {
    it('emits WALLET_TOPUP_SUBMITTED with driver name, amount, and platform wallet details', async () => {
      const prisma: any = {
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-1',
            userId: 'u-drv-1',
            name: 'Fallback Driver',
            user: { id: 'u-drv-1', name: 'Ahmed Ali' },
          }),
        },
        mobileWallet: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'pw-1',
            type: 'VODAFONE',
            number: '01012345678',
            isPlatform: true,
            isActive: true,
          }),
        },
        walletTopUpRequest: {
          findFirst: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({
            id: 'req-100',
            driverId: 'drv-1',
            platformWalletId: 'pw-1',
            amount: 350,
            receiptUrl: 'https://cdn.otlob.test/receipt.jpg',
            status: 'PENDING',
          }),
        },
      };
      const eventEmitter: any = { emit: jest.fn() };
      const service = new WalletService(
        prisma,
        eventEmitter,
        {} as any,
        {} as any,
      );

      const created = await service.submitTopUpRequest('u-drv-1', {
        platformWalletId: 'pw-1',
        amount: 350,
        receiptUrl: 'https://cdn.otlob.test/receipt.jpg',
      });

      expect(created.id).toBe('req-100');
      expect(eventEmitter.emit).toHaveBeenCalledTimes(1);
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        EVENTS.WALLET_TOPUP_SUBMITTED,
        expect.objectContaining<Partial<WalletTopUpSubmittedEvent>>({
          requestId: 'req-100',
          driverId: 'drv-1',
          driverUserId: 'u-drv-1',
          driverName: 'Ahmed Ali',
          amount: 350,
          platformWalletType: 'VODAFONE',
          platformWalletNumber: '01012345678',
          receiptUrl: 'https://cdn.otlob.test/receipt.jpg',
        }),
      );
    });

    it('persists review notes on approval, creates transaction with note, and emits WALLET_TOPUP_REVIEWED', async () => {
      const tx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        walletTopUpRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-101',
            status: 'APPROVED',
            notes: 'Verified transfer #8891',
          }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-1',
            userId: 'u-drv-1',
            name: 'Ahmed Ali',
            status: DriverStatus.SUSPENDED,
            hasUnpaidCommission: true,
            user: { name: 'Ahmed Ali' },
          }),
          update: jest.fn().mockResolvedValue({
            walletBalance: 250,
            userId: 'u-drv-1',
            status: DriverStatus.SUSPENDED,
          }),
        },
        platformSetting: {
          findFirst: jest
            .fn()
            .mockResolvedValue({ maxNegativeDriverBalance: 500 }),
        },
        driverWalletTransaction: { create: jest.fn().mockResolvedValue({}) },
      };

      const prisma: any = {
        walletTopUpRequest: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-101',
            driverId: 'drv-1',
            amount: 600,
            status: 'PENDING',
            platformWallet: { type: 'INSTAPAY', number: 'otlob@instapay' },
          }),
        },
        $transaction: jest.fn((cb: any) => cb(tx)),
      };
      const eventEmitter: any = { emit: jest.fn() };
      const service = new WalletService(
        prisma,
        eventEmitter,
        {} as any,
        {} as any,
      );

      await service.reviewTopUpRequest('sa-1', 'req-101', {
        status: 'APPROVED',
        notes: '  Verified transfer #8891  ',
      });

      expect(tx.walletTopUpRequest.updateMany).toHaveBeenCalledWith({
        where: { id: 'req-101', status: 'PENDING' },
        data: expect.objectContaining({
          status: 'APPROVED',
          approvedById: 'sa-1',
          notes: 'Verified transfer #8891',
          reviewedAt: expect.any(Date),
        }),
      });
      expect(tx.driverWalletTransaction.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          driverId: 'drv-1',
          amount: 600,
          note: 'Verified transfer #8891',
          idempotencyKey: 'topup:req-101',
        }),
      });
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        EVENTS.WALLET_TOPUP_REVIEWED,
        expect.objectContaining<Partial<WalletTopUpReviewedEvent>>({
          requestId: 'req-101',
          driverId: 'drv-1',
          driverUserId: 'u-drv-1',
          status: 'APPROVED',
          amount: 600,
          notes: 'Verified transfer #8891',
          newBalance: 250,
          unsuspended: true,
        }),
      );
    });

    it('persists rejection reason on REJECTED without crediting wallet and emits WALLET_TOPUP_REVIEWED', async () => {
      const tx: any = {
        walletTopUpRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-102',
            status: 'REJECTED',
            notes: 'Screenshot is blurry and missing reference',
          }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            userId: 'u-drv-2',
            name: 'Karim',
            walletBalance: -150,
            user: { name: 'Karim Hassan' },
          }),
          update: jest.fn(),
        },
        driverWalletTransaction: { create: jest.fn() },
      };

      const prisma: any = {
        walletTopUpRequest: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-102',
            driverId: 'drv-2',
            amount: 400,
            status: 'PENDING',
            platformWallet: { type: 'ORANGE', number: '01200000000' },
          }),
        },
        $transaction: jest.fn((cb: any) => cb(tx)),
      };
      const eventEmitter: any = { emit: jest.fn() };
      const service = new WalletService(
        prisma,
        eventEmitter,
        {} as any,
        {} as any,
      );

      await service.reviewTopUpRequest('sa-1', 'req-102', {
        status: 'REJECTED',
        notes: 'Screenshot is blurry and missing reference',
      });

      expect(tx.driverWalletTransaction.create).not.toHaveBeenCalled();
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        EVENTS.WALLET_TOPUP_REVIEWED,
        expect.objectContaining<Partial<WalletTopUpReviewedEvent>>({
          requestId: 'req-102',
          driverUserId: 'u-drv-2',
          status: 'REJECTED',
          amount: 400,
          notes: 'Screenshot is blurry and missing reference',
          unsuspended: false,
        }),
      );
      expect(tx.driver.update).not.toHaveBeenCalled();
    });

    it('keeps settlement lock and counter intact after a partial top-up, and resets counter once full debt is cleared', async () => {
      const partialDriverUpdate = jest.fn().mockResolvedValue({
        walletBalance: -150,
        userId: 'u-drv-10',
        status: DriverStatus.ONLINE,
      });
      const partialTx: any = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        walletTopUpRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-partial',
            status: 'APPROVED',
            notes: null,
          }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-10',
            userId: 'u-drv-10',
            name: 'Sami',
            status: DriverStatus.ONLINE,
            hasUnpaidCommission: true,
            ordersSinceSettlement: 10,
            user: { name: 'Sami' },
          }),
          update: partialDriverUpdate,
        },
        platformSetting: {
          findFirst: jest.fn().mockResolvedValue({
            maxNegativeDriverBalance: 500,
            driverSettlementOrderThreshold: 10,
          }),
        },
        driverWalletTransaction: { create: jest.fn().mockResolvedValue({}) },
      };

      const partialService = new WalletService(
        {
          walletTopUpRequest: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'req-partial',
              driverId: 'drv-10',
              amount: 50,
              status: 'PENDING',
              platformWallet: { type: 'INSTAPAY', number: 'otlob@instapay' },
            }),
          },
          $transaction: jest.fn((cb: any) => cb(partialTx)),
        } as any,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
      );

      await partialService.reviewTopUpRequest('sa-1', 'req-partial', {
        status: 'APPROVED',
      });

      const partialStateWrite = partialDriverUpdate.mock.calls[1][0].data;
      expect(partialStateWrite.hasUnpaidCommission).toBe(true);
      expect(partialStateWrite.ordersSinceSettlement).toBeUndefined();

      // Now settle the remaining debt so walletBalance >= 0
      const fullDriverUpdate = jest.fn().mockResolvedValue({
        walletBalance: 0,
        userId: 'u-drv-10',
        status: DriverStatus.ONLINE,
      });
      const fullTx: any = {
        ...partialTx,
        walletTopUpRequest: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'req-full',
            status: 'APPROVED',
            notes: null,
          }),
        },
        driver: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'drv-10',
            userId: 'u-drv-10',
            name: 'Sami',
            status: DriverStatus.ONLINE,
            hasUnpaidCommission: true,
            ordersSinceSettlement: 10,
            user: { name: 'Sami' },
          }),
          update: fullDriverUpdate,
        },
      };
      const fullEventEmit = jest.fn();
      const fullService = new WalletService(
        {
          walletTopUpRequest: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'req-full',
              driverId: 'drv-10',
              amount: 150,
              status: 'PENDING',
              platformWallet: { type: 'INSTAPAY', number: 'otlob@instapay' },
            }),
          },
          $transaction: jest.fn((cb: any) => cb(fullTx)),
        } as any,
        { emit: fullEventEmit } as any,
        {} as any,
        {} as any,
      );

      await fullService.reviewTopUpRequest('sa-1', 'req-full', {
        status: 'APPROVED',
      });

      const fullStateWrite = fullDriverUpdate.mock.calls[1][0].data;
      expect(fullStateWrite.hasUnpaidCommission).toBe(false);
      expect(fullStateWrite.ordersSinceSettlement).toBe(0);
      expect(fullEventEmit).toHaveBeenCalledWith(
        EVENTS.DRIVER_STATUS_CHANGED,
        expect.objectContaining({
          reason: 'UNPAID_COMMISSION_SETTLED',
        }),
      );
    });

    it('getTopUpRequestById returns hydrated record and throws 404 when missing', async () => {
      const prisma: any = {
        walletTopUpRequest: {
          findUnique: jest
            .fn()
            .mockResolvedValueOnce({
              id: 'req-103',
              driverId: 'drv-3',
              amount: 200,
              status: 'PENDING',
              driver: {
                id: 'drv-3',
                avatar: null,
                user: {
                  id: 'u-3',
                  name: 'Nader',
                  phone: '01099999999',
                  avatar: '/media/avatars/u3.png',
                },
              },
              platformWallet: { id: 'pw-1', type: 'VODAFONE', number: '0101' },
              approvedBy: null,
            })
            .mockResolvedValueOnce(null),
        },
      };
      const service = new WalletService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
      );

      const found = await service.getTopUpRequestById('req-103');
      expect(found.driver.avatar).toBe('/media/avatars/u3.png');

      await expect(service.getTopUpRequestById('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('WalletListener recipient targeting, payloads, and deduplication', () => {
    it('notifies all eligible active Super Admins and MANAGE_FINANCE Admins with unique jobIds', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const prisma: any = {
        user: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'super-1' },
            { id: 'super-2' },
            { id: 'fin-admin-1' },
            { id: 'super-1' }, // duplicate check
          ]),
        },
      };

      const listener = new WalletListener(eventsQueue, prisma);
      await listener.handleTopUpSubmitted(
        new WalletTopUpSubmittedEvent(
          'req-200',
          'drv-1',
          'u-drv-1',
          'Ahmed Ali',
          500,
          'VODAFONE',
          '01012345678',
          'https://cdn.otlob.test/r.jpg',
        ),
      );

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: {
          isBanned: false,
          deletedAt: null,
          id: { not: 'u-drv-1' },
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
      expect(eventsQueue.add).toHaveBeenCalledTimes(3);
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'super-1',
            type: NotificationType.PAYMENT,
            dedupeKey: 'wallet_topup_submitted:req-200:super-1',
            body: expect.stringContaining('Ahmed Ali'),
            bodyAr: expect.stringContaining('محفظة إلكترونية - 01012345678'),
            data: expect.objectContaining({
              kind: 'wallet_topup',
              route: 'wallet_topup_details',
              requestId: 'req-200',
              topUpId: 'req-200',
              amount: '500',
              driverName: 'Ahmed Ali',
            }),
          }),
        }),
        { jobId: 'wallet_topup_submitted_req-200_super-1' },
      );
      const firstCallBody = eventsQueue.add.mock.calls[0][1].dto.body as string;
      expect(firstCallBody).toContain('Mobile Wallet - 01012345678');
      expect(firstCallBody).not.toContain('Vodafone Cash');
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.any(Object),
        { jobId: 'wallet_topup_submitted_req-200_super-2' },
      );
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.any(Object),
        { jobId: 'wallet_topup_submitted_req-200_fin-admin-1' },
      );
    });

    it('sends driver approval and rejection notifications targeting /wallet and prevents duplicate unsuspended push', async () => {
      const eventsQueue: any = { add: jest.fn().mockResolvedValue({}) };
      const walletListener = new WalletListener(eventsQueue);
      const driverListener = new DriverListener({} as any, eventsQueue);

      await walletListener.handleTopUpReviewed(
        new WalletTopUpReviewedEvent(
          'req-301',
          'drv-1',
          'u-drv-1',
          'Ahmed Ali',
          'super-1',
          'APPROVED',
          500,
          'Confirmed transfer #8891',
          150,
          'VODAFONE',
          '01012345678',
          true,
        ),
      );

      // DriverListener must NOT send a second duplicate push for UNPAID_COMMISSION_SETTLED
      await driverListener.handleStatusChanged(
        new DriverStatusChangedEvent(
          'drv-1',
          'u-drv-1',
          DriverStatus.SUSPENDED,
          DriverStatus.OFFLINE,
          'UNPAID_COMMISSION_SETTLED',
        ),
      );

      expect(eventsQueue.add).toHaveBeenCalledTimes(1);
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'u-drv-1',
            title: 'Wallet Adjustment Approved',
            titleAr: 'تمت الموافقة على تسوية المحفظة',
            body: expect.stringContaining('Mobile Wallet - 01012345678'),
            bodyAr: expect.stringContaining('Confirmed transfer #8891'),
            type: NotificationType.PAYMENT,
            data: expect.objectContaining({
              kind: 'wallet_topup',
              action: 'approved',
              route: '/wallet',
              status: 'APPROVED',
              notes: 'Confirmed transfer #8891',
              unsuspended: 'true',
            }),
          }),
        }),
        { jobId: 'wallet_topup_reviewed_req-301_APPROVED_u-drv-1' },
      );

      eventsQueue.add.mockClear();

      await walletListener.handleTopUpReviewed(
        new WalletTopUpReviewedEvent(
          'req-302',
          'drv-1',
          'u-drv-1',
          'Ahmed Ali',
          'super-1',
          'REJECTED',
          400,
          'Transfer slip date is invalid',
          -100,
          'INSTAPAY',
          'otlob@instapay',
          false,
        ),
      );

      expect(eventsQueue.add).toHaveBeenCalledTimes(1);
      expect(eventsQueue.add).toHaveBeenCalledWith(
        EVENT_JOBS.NOTIFY,
        expect.objectContaining({
          dto: expect.objectContaining({
            userId: 'u-drv-1',
            title: 'Wallet Adjustment Rejected',
            titleAr: 'تم رفض تسوية المحفظة',
            body: expect.stringContaining('InstaPay - otlob@instapay'),
            bodyAr: expect.stringContaining('إنستا باي - otlob@instapay'),
            data: expect.objectContaining({
              kind: 'wallet_topup',
              action: 'rejected',
              route: '/wallet',
              status: 'REJECTED',
              notes: 'Transfer slip date is invalid',
            }),
          }),
        }),
        { jobId: 'wallet_topup_reviewed_req-302_REJECTED_u-drv-1' },
      );
    });
  });

  describe('EventsProcessor dedupeKey & NotificationsService/PushProcessor multi-platform delivery', () => {
    it('prevents duplicate EVENT_JOBS.NOTIFY execution when dedupeKey is already DONE', async () => {
      const store = new Map<string, string>();
      const redisClient: any = {
        get: jest.fn((key: string) => Promise.resolve(store.get(key) ?? null)),
        set: jest.fn((key: string, val: string) => {
          if (key.endsWith(':lock') && store.has(key)) {
            return Promise.resolve(null);
          }
          store.set(key, val);
          return Promise.resolve('OK');
        }),
        del: jest.fn((key: string) => {
          store.delete(key);
          return Promise.resolve(1);
        }),
      };
      const notificationsService: any = {
        create: jest.fn().mockResolvedValue({ id: 'n-1' }),
      };

      const processor = new EventsProcessor(
        {} as any,
        {} as any,
        notificationsService,
        {} as any,
        { getClient: () => redisClient } as any,
      );

      const job = {
        name: EVENT_JOBS.NOTIFY,
        data: {
          dto: {
            userId: 'super-1',
            title: 'New Driver Adjustment Request',
            type: NotificationType.PAYMENT,
            dedupeKey: 'wallet_topup_submitted:req-400:super-1',
          },
        },
      } as any;

      await processor.process(job);
      const secondRun = await processor.process(job);

      expect(notificationsService.create).toHaveBeenCalledTimes(1);
      expect(secondRun).toEqual({ skipped: true });
    });

    it('delivers push notifications to multiple Android & iOS devices and strips null payload entries', async () => {
      const prisma: any = {
        notification: {
          create: jest.fn().mockResolvedValue({
            id: 'notif-1',
            title: 'New Driver Adjustment Request',
            titleAr: 'طلب تسوية محفظة جديد من سائق',
            body: 'Ahmed submitted 500 EGP',
            bodyAr: 'قدّم السائق أحمد 500 ج.م',
            type: NotificationType.PAYMENT,
            data: { kind: 'wallet_topup', notes: null },
            createdAt: new Date(),
          }),
        },
        user: {
          findUnique: jest.fn().mockResolvedValue({
            isBanned: false,
            deletedAt: null,
            language: Language.AR,
            devices: [
              { token: 'android-fcm-token-1' },
              { token: 'ios-fcm-token-2' },
              { token: 'android-fcm-token-1' },
            ],
            notificationSettings: null,
          }),
        },
      };
      const pushService: any = {
        sendToDevices: jest.fn().mockResolvedValue(undefined),
      };
      const socketService: any = {
        emitToUser: jest.fn().mockResolvedValue(undefined),
      };

      const notifSvc = new NotificationsService(
        prisma,
        pushService,
        socketService,
      );

      await notifSvc.create({
        userId: 'super-1',
        title: 'New Driver Adjustment Request',
        titleAr: 'طلب تسوية محفظة جديد من سائق',
        body: 'Ahmed submitted 500 EGP',
        bodyAr: 'قدّم السائق أحمد 500 ج.م',
        type: NotificationType.PAYMENT,
        data: {
          kind: 'wallet_topup',
          requestId: 'req-500',
          notes: null,
          extra: undefined,
        },
      });

      expect(pushService.sendToDevices).toHaveBeenCalledWith(
        ['android-fcm-token-1', 'ios-fcm-token-2'],
        'طلب تسوية محفظة جديد من سائق',
        'قدّم السائق أحمد 500 ج.م',
        { kind: 'wallet_topup', requestId: 'req-500' },
      );

      const messagingMock: any = {
        sendEachForMulticast: jest.fn().mockResolvedValue({
          successCount: 1,
          failureCount: 1,
          responses: [
            { success: true, messageId: 'msg-android' },
            {
              success: false,
              error: {
                code: 'messaging/third-party-auth-error',
                message: 'APNs auth key invalid',
              },
            },
          ],
        }),
      };
      const pushProc = new PushProcessor(messagingMock, {
        device: { deleteMany: jest.fn() },
      } as any);

      const result = await pushProc.process({
        name: PUSH_JOBS.SEND_TO_DEVICES,
        data: {
          action: 'SEND',
          tokens: ['android-fcm-token-1', 'ios-fcm-token-2'],
          title: 'Test',
          body: 'Body',
          data: { route: '/wallet', notes: null as any },
        },
      } as unknown as Job<any>);

      expect(messagingMock.sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { route: '/wallet' },
          apns: expect.objectContaining({
            headers: {
              'apns-priority': '10',
              'apns-push-type': 'alert',
            },
          }),
        }),
      );
      expect(result).toEqual({ success: 1, failed: 1, removed: 0 });
    });
  });
});
