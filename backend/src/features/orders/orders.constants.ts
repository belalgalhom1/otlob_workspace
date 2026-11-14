import {
  DeliveryGroupStatus,
  OrderVendorFulfillmentStatus,
} from '@prisma/client';
export { DRIVER_ACTIVE_ORDER_STATUSES } from '../../common/orders/order-status.constants';

// Fulfillment statuses that represent a confirmed, non-cancelled vendor portion
// eligible for settlement and financial ledger accounting.
export const SETTLEABLE_FULFILLMENT_STATUSES: OrderVendorFulfillmentStatus[] = [
  OrderVendorFulfillmentStatus.ACCEPTED,
  OrderVendorFulfillmentStatus.PREPARING,
  OrderVendorFulfillmentStatus.READY_FOR_PICKUP,
  OrderVendorFulfillmentStatus.PICKED_UP,
];

// Terminal delivery group statuses where a driver is no longer actively carrying
// the delivery group.
export const TERMINAL_DELIVERY_GROUP_STATUSES: DeliveryGroupStatus[] = [
  DeliveryGroupStatus.CANCELLED,
  DeliveryGroupStatus.DELIVERED,
];