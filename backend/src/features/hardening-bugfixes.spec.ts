import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import {
  ConversationStatus,
  DeliveryGroupStatus,
  LegalDocumentType,
  MessageType,
  NotificationType,
  OrderStatus,
  Role,
} from '@prisma/client';
import { AuthService } from './auth/auth.service';
import { CartService } from './cart/cart.service';
import { MessagesService } from './chat/messages.service';
import { DriverAssistService } from './drivers/driver-assist.service';
import { LegalDocumentsService } from './legal-documents/legal-documents.service';
import { NotificationsService } from './notifications/notifications.service';
import { AnnouncementAudience } from './notifications/dto/dispatch-announcement.dto';
import { OffersService } from './offers/offers.service';
import { PromotionsService } from './promotions/promotions.service';
import { StatisticsAnalyticsRepository } from './statistics/statistics-analytics.repository';
import { StorageService } from '../infrastructure/storage/storage.service';

describe('Backend Hardening Bugfix Regressions', () => {
  describe('AuthService.register & socialLogin', () => {
    it('does not delete an existing unverified account on register', async () => {
      const tx = {
        user: {
          findFirst: jest.fn().mockResolvedValue({ id: 'u-existing' }),
          delete: jest.fn(),
        },
      };
      const prisma: any = {
        $transaction: jest.fn((fn: (t: any) => Promise<any>) => fn(tx)),
      };
      const auth = new AuthService(
        prisma,
        {} as any,
        {} as any,
        {} as any,
        { emit: jest.fn() } as any,
        { get: jest.fn(), getOrThrow: jest.fn() } as any,
        { disconnectUser: jest.fn() } as any,
        { set: jest.fn() } as any,
        {} as any,
      );

      await expect(
        auth.register({
          email: 'User@Example.COM',
          password: 'Password123!',
          name: 'Test',
        } as any),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(tx.user.delete).not.toHaveBeenCalled();
    });

    it('clears unverified pre-hijacked password, revokes sessions, and keeps verified claim accurate on socialLogin', async () => {
      const existingUser = {
        id: 'u-1',
        email: 'victim@example.com',
        role: Role.CUSTOMER,
        isEmailVerified: false,
        isBanned: false,
        deletedAt: null,
        password: 'attacker-password-hash',
        driver: null,
      };
      const tx = {
        account: { create: jest.fn() },
        user: { update: jest.fn() },
        session: { deleteMany: jest.fn() },
      };
      const prisma: any = {
        account: { findUnique: jest.fn().mockResolvedValue(null) },
        user: { findFirst: jest.fn().mockResolvedValue(existingUser) },
        $transaction: jest.fn((fn: (t: any) => Promise<any>) => fn(tx)),
        session: { create: jest.fn() },
      };
      const redisStore = new Map<string, string>();
      const redis = {
        set: jest.fn((key: string, val: string) => {
          redisStore.set(key, val);
          return Promise.resolve();
        }),
        get: jest.fn((key: string) =>
          Promise.resolve(redisStore.get(key) ?? null),
        ),
      };
      const socketService = { disconnectUser: jest.fn() };
      const accessJwt = { signAsync: jest.fn().mockResolvedValue('acc-tok') };
      const refreshJwt = { signAsync: jest.fn().mockResolvedValue('ref-tok') };
      const config = {
        get: jest.fn().mockReturnValue('15m'),
        getOrThrow: jest.fn().mockReturnValue('7d'),
      };
      const auth = new AuthService(
        prisma,
        accessJwt as any,
        refreshJwt as any,
        {} as any,
        { emit: jest.fn() } as any,
        config as any,
        socketService as any,
        redis as any,
        {} as any,
      );
      jest.spyOn(auth as any, 'verifyGoogleToken').mockResolvedValue({
        sub: 'google-sub-1',
        email: 'Victim@Example.com',
        name: 'Victim',
        emailVerified: true,
      });

      await auth.socialLogin({
        provider: 'GOOGLE',
        idToken: 'fake-id-token',
        app: 'customer',
      } as any);

      expect(tx.user.update).toHaveBeenCalledWith({
        where: { id: 'u-1' },
        data: { isEmailVerified: true, password: null },
      });
      expect(tx.session.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'u-1' },
      });
      expect(redis.set).toHaveBeenCalledWith(
        'revoked:user:u-1',
        expect.stringMatching(/^\d{13,}$/),
        900,
      );
      const revokedMarker = Number(redisStore.get('revoked:user:u-1'));
      const signedPayload = accessJwt.signAsync.mock.calls[0][0];
      expect(signedPayload.iatMs).toBeGreaterThan(revokedMarker);
      expect(socketService.disconnectUser).toHaveBeenCalledWith('u-1');
    });
  });

  describe('CartService security & settings', () => {
    it('rejects customer-sent PRODUCT offer messages and mismatched productId spoofing', async () => {
      const prisma: any = {
        customer: {
          findUnique: jest.fn().mockResolvedValue({ id: 'c-1', canOrder: true }),
        },
        message: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'msg-1',
            type: MessageType.PRODUCT,
            deletedAt: null,
            sender: { id: 'u-cust', role: Role.CUSTOMER },
            conversation: {
              vendorId: 'v-1',
              participants: [{ userId: 'u-cust' }],
            },
            metadata: { product: { name: 'Custom', price: 1 } },
          }),
        },
      };
      const service = new CartService(prisma, {
        getSettings: jest.fn().mockResolvedValue({ defaultCommissionRate: 12 }),
      } as any);

      await expect(
        service.addItem('u-cust', 'v-1', {
          offerMessageId: 'msg-1',
          quantity: 1,
        } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects selectedUnit=strip on non-strip products and uses platform defaultCommissionRate', async () => {
      const prisma: any = {
        customer: {
          findUnique: jest.fn().mockResolvedValue({ id: 'c-1', canOrder: true }),
        },
        product: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'p-1',
            vendorId: 'v-1',
            isActive: true,
            hasVariants: false,
            sellByStrip: false,
            stripsPerPackage: null,
            variants: [],
            optionGroups: [],
          }),
        },
      };
      const service = new CartService(prisma, {
        getSettings: jest.fn().mockResolvedValue({ defaultCommissionRate: 15 }),
      } as any);

      await expect(
        service.addItem('u-1', 'v-1', {
          productId: 'p-1',
          selectedUnit: 'strip',
          quantity: 1,
        } as any),
      ).rejects.toBeInstanceOf(BadRequestException);

      const formatted = (service as any).formatCart(
        {
          id: 'cart-1',
          vendorId: 'v-1',
          vendor: { isContracted: false, commissionRate: null },
          items: [
            {
              id: 'ci-1',
              productId: 'p-1',
              variantId: null,
              quantity: 1,
              selectedUnit: 'package',
              specialRequest: null,
              customName: null,
              customPrice: null,
              customImageUrl: null,
              product: {
                id: 'p-1',
                basePrice: 100,
                comparePrice: null,
                name: 'Item',
                isActive: true,
                sellByStrip: false,
                stripsPerPackage: null,
                stock: null,
                tracksStock: false,
                imageUrl: null,
                hasVariants: false,
              },
              variant: null,
              selectedOptions: [],
            },
          ],
        },
        15,
      );
      expect(formatted.serviceFee).toBe(15);
    });
  });

  describe('LegalDocumentsService', () => {
    it('rejects unpublished documents and records server document.version instead of client dto.version', async () => {
      const prisma: any = {
        legalDocument: {
          findFirst: jest.fn().mockResolvedValueOnce(null).mockResolvedValueOnce({
            id: 'doc-1',
            type: LegalDocumentType.TERMS_OF_USE,
            version: '1.0',
            isPublished: true,
          }),
        },
        userLegalAcceptance: {
          upsert: jest.fn().mockResolvedValue({
            version: '1.0',
            acceptedAt: new Date(),
          }),
        },
      };
      const service = new LegalDocumentsService(prisma);

      await expect(
        service.acceptDocument('u-1', {
          documentId: 'doc-unpublished',
          version: '9.9',
        } as any),
      ).rejects.toBeInstanceOf(NotFoundException);

      const res = await service.acceptDocument('u-1', {
        documentId: 'doc-1',
        version: '9.9',
      } as any);
      expect(res.version).toBe('1.0');
      expect(prisma.userLegalAcceptance.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({ version: '1.0' }),
        }),
      );
    });
  });

  describe('NotificationsService', () => {
    it('deduplicates markRead ids and includes titleAr/bodyAr in dispatchAnnouncement', async () => {
      const prisma: any = {
        notification: {
          count: jest.fn().mockResolvedValue(1),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
      };
      const pushService = { sendToTopic: jest.fn().mockResolvedValue(undefined) };
      const service = new NotificationsService(
        prisma,
        pushService as any,
        {} as any,
      );

      const marked = await service.markRead('u-1', { ids: ['n-1', 'n-1'] });
      expect(marked).toEqual({ marked: 1 });

      await service.dispatchAnnouncement({
        audience: AnnouncementAudience.ALL,
        title: 'Promo',
        titleAr: 'عرض',
        body: '',
        bodyAr: 'تفاصيل',
        type: NotificationType.ANNOUNCEMENT,
      } as any);
      expect(pushService.sendToTopic).toHaveBeenCalledWith(
        'topic_all',
        'Promo',
        'Promo',
        expect.objectContaining({
          titleAr: 'عرض',
          bodyAr: 'تفاصيل',
        }),
      );
    });
  });

  describe('MessagesService', () => {
    it('upserts internal system user before sendSystemMessage and rejects customer PRODUCT messages', async () => {
      const prisma: any = {
        user: { upsert: jest.fn().mockResolvedValue({ id: 'system' }) },
        conversation: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'conv-1',
            orderId: null,
            vendorId: 'v-1',
            type: 'SUPPORT',
            status: ConversationStatus.OPEN,
            participants: [{ userId: 'u-cust' }],
          }),
        },
        message: {
          create: jest.fn().mockResolvedValue({
            id: 'm-1',
            conversationId: 'conv-1',
            type: MessageType.SYSTEM,
            text: 'hi',
            mediaUrl: null,
            metadata: null,
            createdAt: new Date(),
            deletedAt: null,
            sender: null,
            replyTo: null,
          }),
          findUnique: jest.fn().mockResolvedValue({
            id: 'm-other',
            conversationId: 'conv-2',
            senderId: 'u-cust',
            deletedAt: null,
            type: MessageType.TEXT,
          }),
        },
      };
      const service = new MessagesService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
      );

      await service.sendSystemMessage('conv-1', 'System note');
      expect(prisma.user.upsert).toHaveBeenCalled();

      await expect(
        service.send(
          { sub: 'u-cust', role: Role.CUSTOMER, sid: 's1', verified: true },
          'conv-1',
          {
            type: MessageType.PRODUCT,
            metadata: { product: { name: 'Free', price: 0 } },
          } as any,
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);

      await expect(
        service.deleteMessage(
          { sub: 'u-cust', role: Role.CUSTOMER, sid: 's1', verified: true },
          'conv-1',
          'm-other',
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('PromotionsService & OffersService', () => {
    it('PromotionsService preserves uploaded imageUrl on create and cleans old file on remove', async () => {
      const prisma: any = {
        promotion: {
          create: jest.fn(({ data }) => Promise.resolve(data)),
          findUnique: jest
            .fn()
            .mockResolvedValue({ id: 'pr-1', imageUrl: '/media/promotions/a.webp' }),
          delete: jest
            .fn()
            .mockResolvedValue({ id: 'pr-1', imageUrl: '/media/promotions/a.webp' }),
        },
      };
      const storage = { delete: jest.fn().mockResolvedValue(100) };
      const svc = new PromotionsService(prisma, storage as any);

      const created = await svc.create({
        title: 'Sale',
        imageUrl: '/media/promotions/uploaded.webp',
      } as any);
      expect(created.imageUrl).toBe('/media/promotions/uploaded.webp');

      await svc.remove('pr-1');
      expect(storage.delete).toHaveBeenCalledWith('/media/promotions/a.webp');
    });

    it('OffersService validates vendor product ownership and invalidates vendor cache', async () => {
      const prisma: any = {
        product: {
          findFirst: jest.fn().mockResolvedValue({ id: 'p-1', vendorId: 'v-1' }),
        },
        offer: {
          create: jest.fn().mockResolvedValue({ id: 'off-1', vendorId: 'v-1' }),
        },
      };
      const vendorCache = { invalidateVendorDetails: jest.fn() };
      const svc = new OffersService(prisma, vendorCache as any);

      await svc.create({
        productId: 'p-1',
        vendorId: 'v-1',
        originalPrice: 100,
        offerPrice: 70,
      } as any);
      expect(vendorCache.invalidateVendorDetails).toHaveBeenCalledWith('v-1');

      await expect(
        svc.create({
          productId: 'p-1',
          vendorId: 'v-WRONG',
          originalPrice: 100,
          offerPrice: 70,
        } as any),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('DriverAssistService.customerDecideAssist', () => {
    it('blocks customer approving assist on an already cancelled or delivered order', async () => {
      const prisma: any = {
        customer: { findUnique: jest.fn().mockResolvedValue({ id: 'c-1', userId: 'u-c' }) },
        order: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ord-1',
            customerId: 'c-1',
            orderNumber: 'OTL-1',
            status: OrderStatus.CANCELLED,
          }),
        },
        orderDeliveryGroup: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'grp-1',
            orderId: 'ord-1',
            status: DeliveryGroupStatus.CANCELLED,
            assistDriverId: 'd-2',
            assistFee: 20,
            assistCustomerApproved: null,
            primaryDriverId: 'd-1',
          }),
        },
      };
      const svc = new DriverAssistService(
        prisma,
        { emit: jest.fn() } as any,
        {} as any,
        {} as any,
        {} as any,
      );

      await expect(
        svc.customerDecideAssist(
          { sub: 'u-c', role: Role.CUSTOMER, sid: 's', verified: true },
          'ord-1',
          'grp-1',
          true,
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('StorageService traversal & magic bytes', () => {
    it('blocks sibling-prefix path traversal on delete and rejects invalid PDF magic bytes', async () => {
      const storage = new StorageService();
      const siblingPath = `${storage.baseDir}-evil/secret.webp`;
      await expect(storage.delete(siblingPath)).resolves.toBe(0);

      await expect(
        storage.upload(
          {
            mimetype: 'application/pdf',
            buffer: Buffer.from('<script>alert(1)</script>'),
            originalname: 'fake.pdf',
          } as any,
          'documents',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('StatisticsAnalyticsRepository', () => {
    it('supports single-bound date filters and includes deletedAt/rejectedAt guards in getTopProducts', async () => {
      const flatten = (val: any, positional: readonly unknown[] = []): string => {
        if (val == null) return '';
        if (typeof val === 'string' || typeof val === 'number') return String(val);
        if (val instanceof Date) return '$DATE';
        if (Array.isArray(val)) {
          return val
            .map(
              (s, i) =>
                String(s) + (i < positional.length ? flatten(positional[i]) : ''),
            )
            .join('');
        }
        if (Array.isArray(val.strings)) {
          return flatten(val.strings, val.values ?? []);
        }
        if (typeof val.sql === 'string') return val.sql;
        return '';
      };
      const calls: string[] = [];
      const prisma: any = {
        $queryRaw: jest.fn((query: unknown, ...values: unknown[]) => {
          calls.push(flatten(query, values));
          return Promise.resolve([]);
        }),
      };
      const repo = new StatisticsAnalyticsRepository(prisma);
      await repo.getTopProducts(10, '2026-11-01', undefined);

      expect(calls[0]).toContain('o."deletedAt" IS NULL');
      expect(calls[0]).toContain('oi."rejectedAt" IS NULL');
      expect(calls[0]).toContain('o."createdAt" >=');
    });
  });
});
