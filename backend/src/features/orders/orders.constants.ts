import { OrderStatus } from '@prisma/client';

// A driver is considered "carrying a live order" once assigned and until the
// order reaches a terminal state. Acceptance and admin assignment are both
// rejected while the driver has any order in one of these states so one driver
// can never hold two orders.
export const DRIVER_ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
];
