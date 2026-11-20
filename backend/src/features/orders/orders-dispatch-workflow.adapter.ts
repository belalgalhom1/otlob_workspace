import { Injectable, Optional } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DeliveryGroupStatus, OrderStatus } from '@prisma/client';
import { OrdersRepository } from './orders.repository';
import { DispatchOrderWorkflowPort } from '../../common/orders/order-dispatch.ports';
import { EVENTS } from '../../common/events/event-names';
import { OrderStatusChangedEvent } from '../../common/events';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DeliveryGroupTransitionService } from './transitions/delivery-group-transition.service';

/**
 * Adapter implementing `DispatchOrderWorkflowPort` so `DispatchProcessor` can
 * transition accepted orders into driver search and handle undispatchable
 * delivery groups without depending on `OrdersModule` internals.
 */
@Injectable()
export class OrdersDispatchWorkflowAdapter implements DispatchOrderWorkflowPort {
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly eventEmitter: EventEmitter2,
    @Optional() private readonly prisma?: PrismaService,
    @Optional()
    private readonly deliveryGroupTransitions?: DeliveryGroupTransitionService,
  ) {}

  async transitionAcceptedOrderToSearching(orderId: string): Promise<void> {
    if (this.prisma) {
      await this.prisma.orderDeliveryGroup.updateMany({
        where: {
          orderId,
          status: DeliveryGroupStatus.ACCEPTED,
          primaryDriverId: null,
        },
        data: { status: DeliveryGroupStatus.LOOKING_FOR_DRIVER },
      });
    }

    const fullOrder = await this.ordersRepository.updateStatus(
      orderId,
      OrderStatus.LOOKING_FOR_DRIVER,
      'system',
      'Searching for available driver',
      undefined,
      OrderStatus.ACCEPTED,
    );

    const uniqueVendorIds = Array.from(
      new Set(
        (
          ((fullOrder as any)?.vendorFulfillments ?? []) as Array<{
            vendorId: string;
          }>
        ).map((f) => f.vendorId),
      ),
    );
    const singleVendorId =
      uniqueVendorIds.length === 1 ? uniqueVendorIds[0] : null;
    const vendorUserIds = await this.ordersRepository.getOrderVendorUserIds(
      orderId,
      null,
    );

    if (fullOrder) {
      this.eventEmitter.emit(
        EVENTS.ORDER_STATUS_CHANGED,
        new OrderStatusChangedEvent(
          fullOrder.id,
          fullOrder.orderNumber,
          OrderStatus.ACCEPTED,
          OrderStatus.LOOKING_FOR_DRIVER,
          fullOrder.customerId,
          fullOrder.customer?.userId || fullOrder.customerId,
          singleVendorId,
          vendorUserIds,
          null,
          null,
          'system',
          'Searching for available driver',
          fullOrder.revision,
        ),
      );
    }
  }

  async handleUndispatchableDeliveryGroup(
    orderId: string,
    deliveryGroupId: string,
    reason: string,
  ): Promise<{ groupCancelled: boolean; orderCancelled: boolean }> {
    if (!this.deliveryGroupTransitions) {
      return { groupCancelled: false, orderCancelled: false };
    }
    return this.deliveryGroupTransitions.cancelDeliveryGroupAndRecompute({
      orderId,
      deliveryGroupId,
      reason,
      requireDriverless: true,
    });
  }
}
