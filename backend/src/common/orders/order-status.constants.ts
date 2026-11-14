import { OrderStatus } from '@prisma/client';

/**
 * Order statuses where an assigned driver is actively carrying the order.
 * Shared across orders, dispatch, listeners, and geospatial availability queries.
 */
export const DRIVER_ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
];
