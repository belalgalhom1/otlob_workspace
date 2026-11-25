import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { EVENT_JOBS } from '../../infrastructure/queue/queues.constants';
import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrdersRepository } from './orders.repository';
import {
  OrderStatusChangedEvent,
  OrderPaymentStatusChangedEvent,
} from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { DeliveryGroupStatus, OrderStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { StorageService } from '../../infrastructure/storage/storage.service';
import { OrderErrors } from '../../common/constants/response.constants';
import {
  recordOrderStatusEventIdempotent,
  resolveOrderActorSnapshot,
} from './helpers/order-actor.helper';

@Injectable()
export class OrdersPaymentService {
  private readonly logger = new Logger(OrdersPaymentService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly outbox: OutboxService,
  ) {}

  async customerMarkPaid(
    actor: JwtAccessPayload,
    orderId: string,
    file?: Express.Multer.File,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    if (order.customer.user.id !== actor.sub) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    }
    if (
      order.paymentMethod !== 'MOBILE_WALLET' &&
      Number((order as any).upfrontAmount ?? 0) <= 0
    ) {
      throw new BadRequestException(OrderErrors.NOT_MOBILE_WALLET);
    }
    const groups = (
      ((order as any).deliveryGroups ?? []) as Array<{
        id: string;
        sequence: number;
        status: DeliveryGroupStatus;
        isPaymentCollector?: boolean;
        primaryDriverId: string | null;
        primaryDriver?: {
          userId?: string | null;
          user?: { id?: string } | null;
        } | null;
        assistDriver?: {
          userId?: string | null;
          user?: { id?: string } | null;
        } | null;
      }>
    ).filter(Boolean);
    const hasPendingPaymentGroup = groups.some(
      (g) => g.status === DeliveryGroupStatus.PENDING_PAYMENT,
    );
    if (
      order.status !== OrderStatus.PENDING_PAYMENT &&
      !hasPendingPaymentGroup
    ) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }
    if (!file) {
      throw new BadRequestException(OrderErrors.PAYMENT_RECEIPT_REQUIRED);
    }

    // Customer clicks "I paid" with a transfer screenshot. We don't change
    // the main OrderStatus (it remains PENDING_PAYMENT) but we store the
    // receipt and flip paymentStatus so the driver can verify visually.
    const receiptUrl = await this.storage.upload(file, 'payment-receipts');
    try {
      const updated = await this.prisma.order.updateMany({
        where: {
          id: orderId,
          paymentStatus: { not: 'COMPLETED' },
          ...(hasPendingPaymentGroup
            ? {
                status: {
                  notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED],
                },
              }
            : { status: OrderStatus.PENDING_PAYMENT }),
        },
        data: { paymentStatus: 'PAID', paymentReceiptUrl: receiptUrl },
      });

      if (updated.count === 0) {
        throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
      }
    } catch (error) {
      await this.storage.delete(receiptUrl);
      throw error;
    }

    // Replacing an older receipt (repaid after a deny): drop the orphan file.
    const oldUrl = (order as any).paymentReceiptUrl as string | null;
    if (oldUrl && oldUrl !== receiptUrl) {
      await this.storage.delete(oldUrl);
    }

    this.logger.log(
      `Customer marked mobile wallet payment as PAID for order ${order.orderNumber}`,
    );

    const activePaidGroups = groups
      .filter(
        (g) => g.status !== DeliveryGroupStatus.CANCELLED && g.primaryDriverId,
      )
      .sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));
    const collectorGroup =
      activePaidGroups.find((g) => g.isPaymentCollector) ??
      activePaidGroups[0] ??
      null;
    const allDriverUserIds = Array.from(
      new Set(
        activePaidGroups
          .flatMap((g) => [
            g.primaryDriver?.userId ?? g.primaryDriver?.user?.id,
            g.assistDriver?.userId ?? g.assistDriver?.user?.id,
          ])
          .filter((id): id is string => Boolean(id)),
      ),
    );
    const collectorDriverUserId =
      collectorGroup?.primaryDriver?.userId ??
      collectorGroup?.primaryDriver?.user?.id ??
      allDriverUserIds[0] ??
      null;

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
    );
    this.eventEmitter.emit(
      EVENTS.ORDER_PAYMENT_STATUS_CHANGED,
      new OrderPaymentStatusChangedEvent(
        order.id,
        order.orderNumber,
        'PAID',
        order.customer.user.id,
        collectorDriverUserId,
        vendorUserIds,
        'Customer marked order as paid.',
        allDriverUserIds,
      ),
    );

    return this.ordersRepository.findById(orderId);
  }

  async driverConfirmPayment(
    actor: JwtAccessPayload,
    orderId: string,
    received: boolean,
  ) {
    const order = await this.ordersRepository.findById(orderId);

    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true, userId: true },
    });
    if (!driver) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    // A multi-vendor order splits into delivery groups, each with its own
    // primary driver. However, there is only ONE customer charge and ONE payment.
    // The PRIMARY COLLECTOR (isPaymentCollector = true, or the first active
    // delivery group by sequence) is the only driver authorized to confirm or
    // deny the order's payment. Secondary drivers must never confirm or deny
    // payment for the order or alter the primary collector's delivery.
    const groups = (
      ((order as any).deliveryGroups ?? []) as Array<{
        id: string;
        sequence: number;
        status: DeliveryGroupStatus;
        isPaymentCollector?: boolean;
        primaryDriverId: string | null;
        primaryDriver?: {
          userId?: string | null;
          user?: { id?: string } | null;
        } | null;
        assistDriver?: {
          userId?: string | null;
          user?: { id?: string } | null;
        } | null;
        pickedUpAt: Date | null;
        items?: any[];
      }>
    ).filter(Boolean);

    const activeGroups = groups
      .filter(
        (g) => g.status !== DeliveryGroupStatus.CANCELLED && g.primaryDriverId,
      )
      .sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0));

    const collectorGroup =
      activeGroups.find((g) => g.isPaymentCollector) ?? activeGroups[0] ?? null;
    const primaryCollectorId = collectorGroup?.primaryDriverId ?? null;

    if (!primaryCollectorId || driver.id !== primaryCollectorId) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    const allGroupDriverUserIds = Array.from(
      new Set(
        activeGroups
          .flatMap((g) => [
            g.primaryDriver?.userId ?? g.primaryDriver?.user?.id,
            g.assistDriver?.userId ?? g.assistDriver?.user?.id,
          ])
          .filter((id): id is string => Boolean(id)),
      ),
    );
    const distinctVendorIds = Array.from(
      new Set(
        (
          ((order as any).vendorFulfillments ?? []) as Array<{
            vendorId: string;
          }>
        )
          .map((f) => f.vendorId)
          .filter(Boolean),
      ),
    );
    const singleVendorId =
      distinctVendorIds.length === 1 ? distinctVendorIds[0] : null;

    // "Awaiting payment" is per-delivery for a grouped order: the collector's own
    // delivery (or the order itself) must be sitting in PENDING_PAYMENT.
    const awaitingPayment =
      groups.length > 0
        ? groups.some(
            (g) =>
              g.primaryDriverId === driver.id &&
              g.status === DeliveryGroupStatus.PENDING_PAYMENT,
          ) || order.status === OrderStatus.PENDING_PAYMENT
        : order.status === OrderStatus.PENDING_PAYMENT;
    if (!awaitingPayment) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      null,
    );

    if (received) {
      // Payment is per-ORDER (one charge), so the collector confirming receipt
      // pays for the WHOLE order: the collecting delivery and any sibling
      // delivery still waiting on payment all leave PENDING_PAYMENT together.
      // Each group returns to the state of its fulfillments (PICKED_UP,
      // READY_FOR_PICKUP, PREPARING, or DRIVER_ASSIGNED).
      const fulfillments = (order as any).vendorFulfillments ?? [];
      const liveOrderFulfillments = fulfillments.filter(
        (f: any) => f.status !== 'REJECTED' && f.status !== 'CANCELLED',
      );
      const hasAnyPickup =
        groups.some((g) => Boolean(g.pickedUpAt)) ||
        liveOrderFulfillments.some((f: any) => Boolean(f.pickedUpAt));
      const allPickedUp =
        (groups.length > 0 &&
          activeGroups.length > 0 &&
          activeGroups.every((g) => Boolean(g.pickedUpAt))) ||
        (liveOrderFulfillments.length > 0 &&
          liveOrderFulfillments.every((f: any) => Boolean(f.pickedUpAt)));
      const allReady =
        liveOrderFulfillments.length > 0 &&
        liveOrderFulfillments.every(
          (f: any) =>
            f.status === 'READY_FOR_PICKUP' ||
            Boolean(f.readyAt) ||
            Boolean(f.pickedUpAt),
        );
      const anyPreparing = liveOrderFulfillments.some(
        (f: any) => f.status === 'PREPARING' || Boolean(f.preparingAt),
      );

      const nextStatus = allPickedUp
        ? OrderStatus.PICKED_UP
        : hasAnyPickup
          ? OrderStatus.PARTIALLY_PICKED_UP
          : allReady
            ? OrderStatus.READY_FOR_PICKUP
            : anyPreparing
              ? OrderStatus.PREPARING
              : OrderStatus.DRIVER_ASSIGNED;

      // Captured inside the transaction that bumps it, so the event revision is
      // exactly the value this transition wrote (never a later concurrent one).
      let revisionAfter = 0;
      let didAdvanceOrderStatus = false;

      await this.prisma.$transaction(async (tx) => {
        // Guard payment completion against terminal orders FIRST (locking the
        // order row) so a concurrent cancellation cannot be marked COMPLETED.
        const paymentUpdated = await tx.order.updateMany({
          where: {
            id: orderId,
            status: {
              notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED],
            },
          },
          data: { paymentStatus: 'COMPLETED' },
        });
        if (paymentUpdated.count === 0) {
          throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
        }

        for (const g of groups) {
          if (g.status !== DeliveryGroupStatus.PENDING_PAYMENT) continue;
          const groupFulfillmentIds = new Set(
            (g.items ?? []).map((it: any) => it.fulfillmentId),
          );
          const groupFulfillments = liveOrderFulfillments.filter((f: any) =>
            groupFulfillmentIds.has(f.id),
          );
          const groupHasPickup =
            Boolean(g.pickedUpAt) ||
            groupFulfillments.some((f: any) => Boolean(f.pickedUpAt));
          const groupAllPickedUp =
            Boolean(g.pickedUpAt) ||
            (groupFulfillments.length > 0 &&
              groupFulfillments.every((f: any) => Boolean(f.pickedUpAt)));
          const groupAllReady =
            groupFulfillments.length > 0 &&
            groupFulfillments.every(
              (f: any) =>
                f.status === 'READY_FOR_PICKUP' ||
                Boolean(f.readyAt) ||
                Boolean(f.pickedUpAt),
            );
          const groupAnyPreparing = groupFulfillments.some(
            (f: any) => f.status === 'PREPARING' || Boolean(f.preparingAt),
          );

          const groupNextStatus = groupAllPickedUp
            ? DeliveryGroupStatus.PICKED_UP
            : groupHasPickup
              ? DeliveryGroupStatus.PARTIALLY_PICKED_UP
              : groupAllReady
                ? DeliveryGroupStatus.READY_FOR_PICKUP
                : groupAnyPreparing
                  ? DeliveryGroupStatus.PREPARING
                  : DeliveryGroupStatus.DRIVER_ASSIGNED;

          await tx.orderDeliveryGroup.updateMany({
            where: { id: g.id, status: DeliveryGroupStatus.PENDING_PAYMENT },
            data: {
              status: groupNextStatus,
            },
          });
        }

        // Advance the order out of PENDING_PAYMENT when it is still there
        // (single-delivery, or the first grouped delivery to confirm).
        const advanced = await tx.order.updateMany({
          where: { id: orderId, status: OrderStatus.PENDING_PAYMENT },
          data: { status: nextStatus, revision: { increment: 1 } },
        });
        if (groups.length === 0 && advanced.count === 0) {
          throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
        }

        // Read the revision inside the transaction in both cases: when this
        // call advanced the order it is the value just written; when a sibling
        // delivery already advanced it (grouped orders only) it is the current
        // version, so the emitted event never claims a stale revision of 0.
        revisionAfter =
          (
            await tx.order.findUnique({
              where: { id: orderId },
              select: { revision: true },
            })
          )?.revision ?? 0;

        if (advanced.count > 0) {
          didAdvanceOrderStatus = true;
          const paymentActor = await resolveOrderActorSnapshot(
            this.prisma,
            actor.sub,
            { orderId },
          );
          await recordOrderStatusEventIdempotent(tx, {
            orderId,
            deliveryGroupId: collectorGroup?.id ?? null,
            eventKey: `driver_payment_confirmed:${orderId}`,
            status: nextStatus,
            note: 'Driver confirmed payment received.',
            createdBy: actor.sub,
            actor: paymentActor,
          });

          await this.outbox.record(tx, {
            aggregateType: 'ORDER',
            aggregateId: orderId,
            version: revisionAfter,
            eventType: EVENTS.ORDER_STATUS_CHANGED,
            jobName: EVENT_JOBS.ORDER_STATUS_CHANGED,
            dedupeKey: `notify:order_status:${orderId}:${revisionAfter}`,
            payload: {
              orderId,
              orderNumber: order.orderNumber,
              oldStatus: OrderStatus.PENDING_PAYMENT,
              newStatus: nextStatus,
              status: nextStatus,
              customerId: order.customerId,
              customerUserId: order.customer.user.id,
              vendorId: singleVendorId,
              vendorUserIds,
              driverId: primaryCollectorId,
              driverUserId: driver.userId,
              actorUserId: actor.sub,
              note: 'Driver confirmed payment received.',
              revision: revisionAfter,
            },
          });
        }
      });

      this.logger.log(
        `Driver confirmed payment for order ${order.orderNumber}. Order is now ${nextStatus}.`,
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_PAYMENT_STATUS_CHANGED,
        new OrderPaymentStatusChangedEvent(
          order.id,
          order.orderNumber,
          'COMPLETED',
          order.customer.user.id,
          driver.userId,
          vendorUserIds,
          'Driver confirmed payment received.',
          allGroupDriverUserIds,
        ),
      );

      if (didAdvanceOrderStatus) {
        this.eventEmitter.emit(
          EVENTS.ORDER_STATUS_CHANGED,
          new OrderStatusChangedEvent(
            order.id,
            order.orderNumber,
            OrderStatus.PENDING_PAYMENT,
            nextStatus,
            order.customerId,
            order.customer.user.id,
            singleVendorId,
            vendorUserIds,
            primaryCollectorId,
            driver.userId,
            actor.sub,
            'Driver confirmed payment received.',
            revisionAfter,
          ),
        );
      }

      return this.ordersRepository.findById(orderId);
    } else {
      // Driver says they did NOT receive the money. Revert payment status so customer can try again.
      const updated = await this.prisma.order.updateMany({
        where: {
          id: orderId,
          paymentStatus: { not: 'COMPLETED' },
          ...(groups.length > 0
            ? {
                status: {
                  notIn: [OrderStatus.CANCELLED, OrderStatus.DELIVERED],
                },
              }
            : { status: OrderStatus.PENDING_PAYMENT }),
        },
        data: { paymentStatus: 'PENDING' },
      });
      if (updated.count === 0) {
        throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
      }
      this.logger.log(`Driver denied payment for order ${order.orderNumber}.`);

      this.eventEmitter.emit(
        EVENTS.ORDER_PAYMENT_STATUS_CHANGED,
        new OrderPaymentStatusChangedEvent(
          order.id,
          order.orderNumber,
          'PENDING',
          order.customer.user.id,
          driver.userId,
          vendorUserIds,
          'Driver denied payment. Please send again.',
          allGroupDriverUserIds,
        ),
      );

      return this.ordersRepository.findById(orderId);
    }
  }
}
