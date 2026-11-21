import { OrderStatus, OrderType } from '@prisma/client';

/**
 * Single source of truth for whether an order type requires proof photos
 * (pickup and delivery photos). Normal passenger rides (OrderType.RIDE)
 * have no store items or parcels to photograph; regular store orders and
 * custom deliveries require proof photos.
 */
export function requiresOrderProofPhotos(orderType?: string | null): boolean {
  return orderType !== OrderType.RIDE;
}

export const VENDOR_ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.ACCEPTED],
  // Vendors may begin preparing or mark ready immediately after accepting,
  // even before a driver accepts dispatch.
  [OrderStatus.ACCEPTED]: [OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP],
  [OrderStatus.LOOKING_FOR_DRIVER]: [
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [OrderStatus.DRIVER_ASSIGNED]: [
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [OrderStatus.PENDING_PAYMENT]: [
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.PICKED_UP],
  [OrderStatus.PICKED_UP]: [],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
  [OrderStatus.CHANGES_REQUESTED]: [],
  [OrderStatus.PARTIALLY_PICKED_UP]: [],
};

export const DRIVER_ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.DRIVER_ASSIGNED]: [
    OrderStatus.PENDING_PAYMENT,
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
  ],
  [OrderStatus.PENDING_PAYMENT]: [
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
  ],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.PICKED_UP],
  [OrderStatus.PICKED_UP]: [OrderStatus.DELIVERED, OrderStatus.PENDING_PAYMENT],
  [OrderStatus.PENDING]: [],
  [OrderStatus.CHANGES_REQUESTED]: [],
  [OrderStatus.ACCEPTED]: [],
  [OrderStatus.PREPARING]: [
    OrderStatus.PENDING_PAYMENT,
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
  ],
  [OrderStatus.LOOKING_FOR_DRIVER]: [],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
  [OrderStatus.PARTIALLY_PICKED_UP]: [OrderStatus.PICKED_UP],
};

export const NON_CANCELLABLE: OrderStatus[] = [
  OrderStatus.DELIVERED,
  OrderStatus.CANCELLED,
  OrderStatus.PICKED_UP,
  OrderStatus.PARTIALLY_PICKED_UP,
];
