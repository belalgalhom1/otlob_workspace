import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrderStatus } from '@prisma/client';
import { OrdersRepository } from './orders.repository';
import { DispatchOrderWorkflowPort } from '../../common/orders/order-dispatch.ports';
import { EVENTS } from '../../common/events/event-names';
import { OrderStatusChangedEvent } from '../../common/events';

/**
 * Adapter implementing `DispatchOrderWorkflowPort` so `DispatchProcessor` can
 * transition accepted single-vendor orders into driver search without depending
 * on `OrdersModule` internals.
 */
@Injectable()
export class OrdersDispatchWorkflowAdapter
  implements DispatchOrderWorkflowPort
{
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async transitionAcceptedOrderToSearching(orderId: string): Promise<void> {
    const fullOrder = await this.ordersRepository.updateStatus(
      orderId,
      OrderStatus.LOOKING_FOR_DRIVER,
      'system',
      'Searching for available driver',
      undefined,
      OrderStatus.ACCEPTED,
    );

    const vendorUserIds = fullOrder?.vendorId
      ? await this.ordersRepository.getVendorUserIds(fullOrder.vendorId)
      : [];

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
          fullOrder.vendorId,
          vendorUserIds,
          fullOrder.driverId,
          fullOrder.driver?.userId || null,
          'system',
          'Searching for available driver',
          fullOrder.revision,
        ),
      );
    }
  }
}
