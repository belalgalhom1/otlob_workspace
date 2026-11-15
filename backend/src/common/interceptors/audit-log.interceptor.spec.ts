import { CallHandler, ExecutionContext } from '@nestjs/common';
import { AuditActionType, Role } from '@prisma/client';
import { firstValueFrom, of } from 'rxjs';
import { AuditLogCreatedEvent } from '../events';
import { EVENTS } from '../events/event-names';
import { AuditLogInterceptor } from './audit-log.interceptor';

describe('AuditLogInterceptor', () => {
  function makeContext(req: {
    method: string;
    url: string;
    body?: unknown;
    params?: Record<string, string>;
    user?: { sub: string; role: Role; sid?: string; vendorId?: string };
  }): { context: ExecutionContext; next: CallHandler } {
    const context = {
      getClass: () => ({ name: 'OrdersController' }),
      switchToHttp: () => ({
        getRequest: () => req,
      }),
    } as unknown as ExecutionContext;
    return {
      context,
      next: { handle: () => of({ id: 'ord-1' }) },
    };
  }

  it('logs customer multi-vendor order creation with enriched _facts and null vendorId (multi-vendor isolation)', async () => {
    const eventEmitter: any = { emit: jest.fn() };
    const prisma: any = {
      order: { findUnique: jest.fn() },
      orderVendorFulfillment: { findUnique: jest.fn() },
    };
    const interceptor = new AuditLogInterceptor(prisma, eventEmitter);

    const responseOrder = {
      id: 'ord-mv-1',
      orderNumber: 'OTL-MV-101',
      status: 'PENDING',
      grandTotal: 340,
      paymentMethod: 'CASH_ON_DELIVERY',
      isMultiVendor: true,
      deliveryGroups: [{ id: 'g1' }, { id: 'g2' }],
      vendorFulfillments: [
        {
          id: 'ff-1',
          vendorId: 'v-1',
          vendor: { storeName: 'Fresh Market', storeNameAr: 'فريش ماركت' },
        },
        {
          id: 'ff-2',
          vendorId: 'v-2',
          vendor: { storeName: 'Bistro', storeNameAr: 'بيسترو' },
        },
      ],
    };

    const { context } = makeContext({
      method: 'POST',
      url: '/api/v1/orders/multi-vendor',
      body: {
        vendorIds: ['v-1', 'v-2'],
        paymentMethod: 'CASH_ON_DELIVERY',
        deliveryAddress: 'Nasr City',
        deliveryLocation: [31.3, 30.05],
      },
      user: { sub: 'u-cust-1', role: Role.CUSTOMER, sid: 'sid-1' },
    });

    await firstValueFrom(
      interceptor.intercept(context, { handle: () => of(responseOrder) }),
    );

    expect(eventEmitter.emit).toHaveBeenCalledTimes(1);
    const [eventName, payload] = eventEmitter.emit.mock.calls[0] as [
      string,
      AuditLogCreatedEvent,
    ];
    expect(eventName).toBe(EVENTS.AUDIT_LOG_CREATED);
    expect(payload.userId).toBe('u-cust-1');
    expect(payload.vendorId).toBeNull();
    expect(payload.actionType).toBe(AuditActionType.CREATE);
    expect(payload.action).toBe('POST /api/v1/orders/multi-vendor');
    expect(payload.entityType).toBe('Orders');
    expect(payload.entityId).toBe('ord-mv-1');
    expect((payload.newValues as any)._facts).toEqual({
      Order: 'OTL-MV-101',
      Status: 'PENDING',
      Total: '340 EGP',
      Payment: 'CASH ON DELIVERY',
      Vendor: { en: 'Fresh Market + Bistro', ar: 'فريش ماركت + بيسترو' },
      Stores: '2',
      Deliveries: '2',
    });
  });

  it('sets vendorId on single-vendor order creation audit so both admin and vendor see it', async () => {
    const eventEmitter: any = { emit: jest.fn() };
    const prisma: any = {
      order: { findUnique: jest.fn() },
      orderVendorFulfillment: { findUnique: jest.fn() },
    };
    const interceptor = new AuditLogInterceptor(prisma, eventEmitter);

    const responseOrder = {
      id: 'ord-sv-1',
      orderNumber: 'OTL-SV-1',
      status: 'PENDING',
      grandTotal: 150,
      paymentMethod: 'MOBILE_WALLET',
      isMultiVendor: false,
      deliveryGroups: [{ id: 'g1' }],
      vendorFulfillments: [
        {
          id: 'ff-1',
          vendorId: 'v-1',
          vendor: { storeName: 'Bakery', storeNameAr: 'مخبز' },
        },
      ],
    };

    const { context } = makeContext({
      method: 'POST',
      url: '/api/v1/orders',
      body: { vendorId: 'v-1', paymentMethod: 'MOBILE_WALLET' },
      user: { sub: 'u-cust-1', role: Role.CUSTOMER },
    });

    await firstValueFrom(
      interceptor.intercept(context, { handle: () => of(responseOrder) }),
    );

    const [, payload] = eventEmitter.emit.mock.calls[0] as [
      string,
      AuditLogCreatedEvent,
    ];
    expect(payload.vendorId).toBe('v-1');
    expect((payload.newValues as any)._facts.Stores).toBeUndefined();
  });

  it('skips read-only POST fee-estimate requests and customer non-Orders routes', async () => {
    const eventEmitter: any = { emit: jest.fn() };
    const prisma: any = {};
    const interceptor = new AuditLogInterceptor(prisma, eventEmitter);

    const estimateCtx = makeContext({
      method: 'POST',
      url: '/api/v1/orders/multi-vendor/fee-estimate',
      body: { vendorIds: ['v-1', 'v-2'] },
      user: { sub: 'u-cust-1', role: Role.CUSTOMER },
    });
    await firstValueFrom(
      interceptor.intercept(estimateCtx.context, estimateCtx.next),
    );

    const cartContext = {
      getClass: () => ({ name: 'CartController' }),
      switchToHttp: () => ({
        getRequest: () => ({
          method: 'POST',
          url: '/api/v1/cart/items',
          body: { productId: 'p1' },
          params: {},
          user: { sub: 'u-cust-1', role: Role.CUSTOMER },
        }),
      }),
    } as unknown as ExecutionContext;
    await firstValueFrom(
      interceptor.intercept(cartContext, { handle: () => of({ ok: true }) }),
    );

    expect(eventEmitter.emit).not.toHaveBeenCalled();
  });

  it('snapshots fulfillment on PATCH /orders/vendor-decisions/:fulfillmentId/accept', async () => {
    const eventEmitter: any = { emit: jest.fn() };
    const fulfillmentId = '11111111-1111-1111-1111-111111111111';
    const prisma: any = {
      orderVendorFulfillment: {
        findUnique: jest.fn().mockResolvedValue({
          id: fulfillmentId,
          vendorId: 'v-1',
          status: 'PENDING',
          subtotal: 200,
          vendor: { storeName: 'Store A', storeNameAr: 'متجر أ' },
          order: {
            orderNumber: 'OTL-88',
            status: 'PENDING',
            grandTotal: 420,
            paymentMethod: 'CASH_ON_DELIVERY',
          },
        }),
      },
      order: { findUnique: jest.fn() },
    };
    const interceptor = new AuditLogInterceptor(prisma, eventEmitter);

    const { context } = makeContext({
      method: 'PATCH',
      url: `/api/v1/orders/vendor-decisions/${fulfillmentId}/accept`,
      params: { fulfillmentId },
      user: { sub: 'u-vendor-1', role: Role.VENDOR_MEMBER },
    });

    await firstValueFrom(
      interceptor.intercept(context, { handle: () => of({ status: 'ACCEPTED' }) }),
    );

    expect(eventEmitter.emit).toHaveBeenCalledTimes(1);
    const [, payload] = eventEmitter.emit.mock.calls[0] as [
      string,
      AuditLogCreatedEvent,
    ];
    expect(payload.vendorId).toBe('v-1');
    expect(payload.actionType).toBe(AuditActionType.UPDATE);
    expect(payload.oldValues).toEqual({
      status: 'PENDING',
      orderStatus: 'PENDING',
    });
    expect((payload.newValues as any)._facts).toEqual({
      Order: 'OTL-88',
      Status: 'PENDING',
      'Order status': 'PENDING',
      Subtotal: '200 EGP',
      Total: '420 EGP',
      Payment: 'CASH ON DELIVERY',
      Vendor: { en: 'Store A', ar: 'متجر أ' },
    });
  });
});
