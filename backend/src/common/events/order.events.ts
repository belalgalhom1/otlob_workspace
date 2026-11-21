import { OrderStatus, OrderVendorFulfillmentStatus } from '@prisma/client';

export class OrderCreatedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly vendorId: string | null,
    public readonly vendorUserIds: string[],
    public readonly grandTotal: number,
    public readonly paymentMethod: string,
    public readonly orderType: string,
    // Monotonic order revision at the moment the order row was created.
    public readonly revision: number = 0,
    public readonly vendorIds?: string[],
  ) {}
}

export class OrderStatusChangedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly oldStatus: OrderStatus,
    public readonly newStatus: OrderStatus,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly vendorId: string | null,
    public readonly vendorUserIds: string[],
    public readonly driverId: string | null,
    public readonly driverUserId: string | null,
    public readonly actorUserId: string,
    public readonly note: string | null,
    // Revision of the Order row written by this transition.
    public readonly revision: number,
    // Stable discriminator when ONE order revision legitimately emits multiple
    // status events (per-stop pickup, per-delivery completion).
    public readonly dedupeKey?: string,
  ) {}
}

export class OrderPaymentStatusChangedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly paymentStatus: string,
    public readonly customerUserId: string,
    public readonly driverUserId: string | null,
    public readonly vendorUserIds: string[],
    public readonly message: string,
    public readonly driverUserIds: string[] = [],
  ) {}
}

export class OrderCancelledEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly vendorId: string | null,
    public readonly vendorUserIds: string[],
    public readonly driverId: string | null,
    public readonly driverUserId: string | null,
    public readonly reason: string,
    public readonly cancelledByUserId: string | null,
    public readonly driverIds: string[] = [],
    public readonly revision?: number,
    public readonly cancelledByName?: string | null,
    public readonly cancelledByNameAr?: string | null,
    public readonly cancelledByRole?: string | null,
    public readonly cancelledByAvatar?: string | null,
  ) {}
}

export class OrderSettledEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly vendorId: string | null,
    public readonly driverId: string,
    public readonly driverShiftId: string | null,
    public readonly grandTotal: number,
    public readonly deliveryFee: number,
    public readonly commissionRate: number,
    public readonly taxRate: number,
    public readonly customerUserId?: string | null,
  ) {}
}

export class OrderFulfillmentDecidedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly fulfillmentId: string,
    public readonly vendorId: string,
    public readonly vendorUserIds: string[],
    public readonly status: OrderVendorFulfillmentStatus,
    public readonly actorUserId: string,
    public readonly driverUserIds: string[] = [],
    public readonly parentStatus?: OrderStatus,
    public readonly revision?: number,
  ) {}
}

export class OrderVendorRejectedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly fulfillmentId: string,
    public readonly vendorId: string,
    public readonly vendorName: string,
    public readonly vendorNameAr: string | null,
    public readonly rejectionCode: string,
    public readonly rejectionReason: string,
    public readonly rejectionReasonAr: string | null,
    public readonly affectedItemNames: string[],
    public readonly refundAmount: number,
    public readonly allPortionsRejected: boolean,
    public readonly actorUserId: string,
  ) {}
}

export class OrderFulfillmentUpdatedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly fulfillmentId: string,
    public readonly customerUserId: string,
    public readonly vendorUserIds: string[],
    public readonly driverUserIds: string[],
    public readonly status: OrderVendorFulfillmentStatus,
    public readonly pickedUpAt: Date | null,
    public readonly pickupImageUrl: string | null,
    public readonly parentStatus: OrderStatus,
    public readonly fulfillmentSummary: {
      totalStops: number;
      completedStops: number;
      currentStopSequence: number;
      currentStopBranchName: string | null;
      isFullyCollected: boolean;
    },
    public readonly actorUserId: string,
    public readonly revision?: number,
  ) {}
}
