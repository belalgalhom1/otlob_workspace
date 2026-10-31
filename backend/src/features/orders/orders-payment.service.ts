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

@Injectable()
export class OrdersPaymentService {
  private readonly logger = new Logger(OrdersPaymentService.name);

  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
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
    const groups = (((order as any).deliveryGroups ?? []) as Array<{
      id: string;
      status: DeliveryGroupStatus;
      primaryDriverId: string | null;
    }>).filter(Boolean);
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

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      order.vendorId,
    );
    this.eventEmitter.emit(
      EVENTS.ORDER_PAYMENT_STATUS_CHANGED,
      new OrderPaymentStatusChangedEvent(
        order.id,
        order.orderNumber,
        'PAID',
        order.customer.user.id,
        order.driver?.userId ?? null,
        vendorUserIds,
        'Customer marked order as paid.',
      ),
    );

    return {
      success: true,
      message: 'Payment marked as paid. Waiting for driver confirmation.',
    };
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

    // A multi-vendor order splits into delivery groups, each with its OWN
    // primary driver, while order.driverId only mirrors the FIRST group. So
    // authorize the driver who owns any group — otherwise the second
    // delivery's driver could never confirm their customer's payment.
    const groups = (
      (((order as any).deliveryGroups ?? []) as Array<{
        id: string;
        status: DeliveryGroupStatus;
        primaryDriverId: string | null;
        pickedUpAt: Date | null;
        items?: any[];
      }>)
    ).filter(Boolean);

    const ownsGroup = groups.some((g) => g.primaryDriverId === driver.id);
    const authorized =
      groups.length > 0 ? ownsGroup : order.driverId === driver.id;
    if (!authorized) {
      throw new ForbiddenException(OrderErrors.NOT_ASSIGNED_TO_ORDER);
    }

    // "Awaiting payment" is per-delivery for a grouped order: the caller's own
    // delivery must be sitting in PENDING_PAYMENT (the order-level status may
    // already have moved on while a later delivery still waits on payment).
    const awaitingPayment =
      groups.length > 0
        ? groups.some(
            (g) =>
              g.primaryDriverId === driver.id &&
              g.status === DeliveryGroupStatus.PENDING_PAYMENT,
          )
        : order.status === OrderStatus.PENDING_PAYMENT;
    if (!awaitingPayment) {
      throw new BadRequestException(OrderErrors.NOT_AWAITING_PAYMENT);
    }

    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      order.id,
      order.vendorId,
    );

    if (received) {
      // Payment is per-ORDER (one charge), so one driver confirming receipt
      // pays for the WHOLE order: the collecting delivery and any sibling
      // delivery still waiting on payment all leave PENDING_PAYMENT together.
      // Each group returns to the state it held before the payment detour
      // (PICKED_UP if it had already been picked up, else DRIVER_ASSIGNED).
      const fulfillments = (order as any).vendorFulfillments ?? [];
      const hasAnyPickup = Boolean((order as any).pickedUpAt) || fulfillments.some((f: any) => Boolean(f.pickedUpAt));
      const allPickedUp = Boolean((order as any).pickedUpAt) || (fulfillments.length > 0 && fulfillments.every((f: any) => Boolean(f.pickedUpAt) || f.status === 'REJECTED' || f.status === 'CANCELLED'));

      const nextStatus = allPickedUp
        ? OrderStatus.PICKED_UP
        : (hasAnyPickup ? OrderStatus.PARTIALLY_PICKED_UP : OrderStatus.DRIVER_ASSIGNED);

      await this.prisma.$transaction(async (tx) => {
        for (const g of groups) {
          if (g.status !== DeliveryGroupStatus.PENDING_PAYMENT) continue;
          const groupFulfillmentIds = new Set((g.items ?? []).map((it: any) => it.fulfillmentId));
          const groupFulfillments = fulfillments.filter((f: any) => groupFulfillmentIds.has(f.id));
          const groupHasPickup = Boolean(g.pickedUpAt) || groupFulfillments.some((f: any) => Boolean(f.pickedUpAt));
          const groupAllPickedUp = Boolean(g.pickedUpAt) || (groupFulfillments.length > 0 && groupFulfillments.every((f: any) => Boolean(f.pickedUpAt) || f.status === 'REJECTED' || f.status === 'CANCELLED'));

          const groupNextStatus = groupAllPickedUp
            ? DeliveryGroupStatus.PICKED_UP
            : (groupHasPickup ? DeliveryGroupStatus.PARTIALLY_PICKED_UP : DeliveryGroupStatus.DRIVER_ASSIGNED);

          await tx.orderDeliveryGroup.updateMany({
            where: { id: g.id, status: DeliveryGroupStatus.PENDING_PAYMENT },
            data: {
              status: groupNextStatus,
            },
          });
        }

        // Payment is a per-order fact: record it regardless of where the
        // aggregate status currently sits.
        await tx.order.updateMany({
          where: { id: orderId },
          data: { paymentStatus: 'COMPLETED' },
        });

        // Advance the order out of PENDING_PAYMENT when it is still there
        // (single-delivery, or the first grouped delivery to confirm).
        const advanced = await tx.order.updateMany({
          where: { id: orderId, status: OrderStatus.PENDING_PAYMENT },
          data: { status: nextStatus },
        });
        if (groups.length === 0 && advanced.count === 0) {
          throw new BadRequestException(OrderErrors.CONCURRENT_MODIFICATION);
        }
        if (advanced.count > 0) {
          await tx.orderStatusEvent.create({
            data: {
              orderId,
              status: nextStatus,
              note: 'Driver confirmed payment received.',
              createdBy: actor.sub,
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
        ),
      );

      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          order.id,
          order.orderNumber,
          OrderStatus.PENDING_PAYMENT,
          nextStatus,
          order.customerId,
          order.customer.user.id,
          order.vendorId,
          vendorUserIds,
          order.driverId,
          driver.userId,
          actor.sub,
          'Driver confirmed payment received.',
        ),
      );

      return { success: true, status: nextStatus };
    } else {
      // Driver says they did NOT receive the money. Revert payment status so customer can try again,
      // or we could cancel the order. For now, just revert payment status.
      const updated = await this.prisma.order.updateMany({
        where: {
          id: orderId,
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
        ),
      );

      return {
        success: true,
        message: 'Payment denied. Customer must send again.',
      };
    }
  }
}
