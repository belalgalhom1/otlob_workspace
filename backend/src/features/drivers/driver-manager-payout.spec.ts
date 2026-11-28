import { BadRequestException } from '@nestjs/common';
import { DriverManagerTransactionType, NotificationType } from '@prisma/client';
import { DriverManagersService } from './driver-managers.service';
import {
  EVENTS,
  DriverManagerPayoutCompletedEvent,
} from '../../common/events';
import { WalletListener } from '../../common/listeners/wallet.listener';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import { DriverManagerErrors } from '../../common/constants/response.constants';

describe('DriverManager Wallet Payout & Receipt Lifecycle', () => {
  it('zeros out full positive balance, persists PAYOUT tx with receiptUrl, and emits DRIVER_MANAGER_PAYOUT_COMPLETED', async () => {
    let balance = 850;
    const createdTxs: any[] = [];
    const emitted: Array<{ event: string; payload: any }> = [];

    const prisma: any = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u-mgr-1',
          name: 'Tarek Manager',
          role: 'DRIVER_MANAGER',
        }),
      },
      driverManager: {
        findUnique: jest.fn().mockImplementation(() =>
          Promise.resolve({
            id: 'dm-1',
            userId: 'u-mgr-1',
            walletBalance: balance,
            manageAllDrivers: false,
          }),
        ),
        updateMany: jest.fn().mockImplementation(({ where, data }: any) => {
          if (balance >= where.walletBalance.gte) {
            balance -= data.walletBalance.decrement;
            return Promise.resolve({ count: 1 });
          }
          return Promise.resolve({ count: 0 });
        }),
      },
      driverManagerWalletTransaction: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }: any) => {
          const tx = {
            id: 'tx-payout-1',
            ...data,
            createdAt: new Date('2026-11-28T00:00:00.000Z'),
            processedBy: { id: 'u-super-1', name: 'Super Admin' },
          };
          createdTxs.push(tx);
          return Promise.resolve(tx);
        }),
      },
      $transaction: jest.fn().mockImplementation(async (cb: any) => cb(prisma)),
    };

    const storage: any = {
      upload: jest.fn().mockResolvedValue('/media/receipts/payout-1.webp'),
    };
    const eventEmitter: any = {
      emit: jest.fn((event: string, payload: any) => {
        emitted.push({ event, payload });
      }),
    };

    const service = new DriverManagersService(prisma, storage, eventEmitter);

    const uploadRes = await service.uploadPayoutReceipt({
      originalname: 'transfer.jpg',
    } as any);
    expect(uploadRes.receiptUrl).toBe('/media/receipts/payout-1.webp');
    expect(storage.upload).toHaveBeenCalledWith(expect.anything(), 'receipts');

    const result = await service.processPayout(
      'u-mgr-1',
      {
        settleFullBalance: true,
        receiptUrl: uploadRes.receiptUrl,
        description: 'InstaPay transfer #9912',
      },
      'u-super-1',
    );

    expect(result.paidAmount).toBe(850);
    expect(result.walletBalance).toBe(0);
    expect(balance).toBe(0);
    expect(createdTxs).toHaveLength(1);
    expect(createdTxs[0]).toMatchObject({
      managerId: 'dm-1',
      type: DriverManagerTransactionType.PAYOUT,
      amount: -850,
      balanceAfter: 0,
      receiptUrl: '/media/receipts/payout-1.webp',
      processedById: 'u-super-1',
      description: 'InstaPay transfer #9912',
    });

    expect(emitted).toHaveLength(1);
    expect(emitted[0].event).toBe(EVENTS.DRIVER_MANAGER_PAYOUT_COMPLETED);
    expect(emitted[0].payload).toBeInstanceOf(
      DriverManagerPayoutCompletedEvent,
    );
    expect(emitted[0].payload).toMatchObject({
      transactionId: 'tx-payout-1',
      managerId: 'dm-1',
      managerUserId: 'u-mgr-1',
      amount: 850,
      newBalance: 0,
      receiptUrl: '/media/receipts/payout-1.webp',
    });
  });

  it('supports partial payout and rejects amounts exceeding current walletBalance or zero balance', async () => {
    let balance = 400;
    const prisma: any = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u-mgr-2',
          name: 'Ali Manager',
          role: 'DRIVER_MANAGER',
        }),
      },
      driverManager: {
        findUnique: jest.fn().mockImplementation(() =>
          Promise.resolve({
            id: 'dm-2',
            userId: 'u-mgr-2',
            walletBalance: balance,
            manageAllDrivers: false,
          }),
        ),
        updateMany: jest.fn().mockImplementation(({ where, data }: any) => {
          if (balance >= where.walletBalance.gte) {
            balance -= data.walletBalance.decrement;
            return Promise.resolve({ count: 1 });
          }
          return Promise.resolve({ count: 0 });
        }),
      },
      driverManagerWalletTransaction: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }: any) =>
          Promise.resolve({ id: 'tx-partial', ...data }),
        ),
      },
      $transaction: jest.fn().mockImplementation(async (cb: any) => cb(prisma)),
    };

    const service = new DriverManagersService(prisma);

    await expect(
      service.processPayout('u-mgr-2', { amount: 500 }, 'u-super-1'),
    ).rejects.toThrow(
      new BadRequestException(DriverManagerErrors.INSUFFICIENT_BALANCE),
    );

    const partial = await service.processPayout(
      'u-mgr-2',
      { amount: 150 },
      'u-super-1',
    );
    expect(partial.paidAmount).toBe(150);
    expect(partial.walletBalance).toBe(250);

    balance = 0;
    await expect(
      service.processPayout('u-mgr-2', { settleFullBalance: true }, 'u-super-1'),
    ).rejects.toThrow(
      new BadRequestException(DriverManagerErrors.NO_BALANCE_TO_SETTLE),
    );
  });

  it('enqueues localized push/in-app notification with receiptUrl via WalletListener', async () => {
    const eventsQueue: any = {
      add: jest.fn().mockResolvedValue(undefined),
    };
    const listener = new WalletListener(eventsQueue);

    await listener.handleDriverManagerPayoutCompleted(
      new DriverManagerPayoutCompletedEvent(
        'tx-99',
        'dm-1',
        'u-mgr-1',
        'Tarek',
        850,
        0,
        '/media/receipts/payout-1.webp',
        'InstaPay Ref 9912',
        'u-super-1',
      ),
    );

    expect(eventsQueue.add).toHaveBeenCalledWith(
      EVENT_JOBS.NOTIFY,
      expect.objectContaining({
        dto: expect.objectContaining({
          userId: 'u-mgr-1',
          type: NotificationType.PAYMENT,
          titleAr: 'تم تحويل مستحقات محفظتك',
          data: expect.objectContaining({
            kind: 'driver_manager_payout',
            route: 'driver_manager_wallet',
            transactionId: 'tx-99',
            amount: '850',
            newBalance: '0',
            receiptUrl: '/media/receipts/payout-1.webp',
          }),
        }),
      }),
      expect.objectContaining({
        jobId: 'driver_manager_payout_tx-99_u-mgr-1',
      }),
    );
  });
});
