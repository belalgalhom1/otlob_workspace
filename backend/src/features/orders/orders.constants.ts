import {
  DeliveryGroupStatus,
  OrderStatus,
  OrderVendorFulfillmentStatus,
} from '@prisma/client';

// A driver is considered "carrying a live order" once assigned and until the
// order reaches a terminal state. Acceptance and admin assignment are both
// rejected while the driver has any order in one of these states (up to
// maxActiveOrdersPerDriver).
export const DRIVER_ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.DRIVER_ASSIGNED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.PENDING_PAYMENT,
  OrderStatus.PARTIALLY_PICKED_UP,
  OrderStatus.PICKED_UP,
];

// Fulfillment statuses that represent a confirmed, non-cancelled vendor portion
// eligible for settlement and financial ledger accounting.
export const SETTLEABLE_FULFILLMENT_STATUSES: OrderVendorFulfillmentStatus[] = [
  OrderVendorFulfillmentStatus.ACCEPTED,
  OrderVendorFulfillmentStatus.PREPARING,
  OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
  OrderVendorFulfillmentStatus.PICKED_UP,
  OrderVendorFulfillmentStatus.DELIVERED,
];

// Terminal delivery group statuses where a driver is no longer actively carrying
// the delivery group.
export const TERMINAL_DELIVERY_GROUP_STATUSES: DeliveryGroupStatus[] = [
  DeliveryGroupStatus.CANCELLED,
  DeliveryGroupStatus.DELIVERED,
];