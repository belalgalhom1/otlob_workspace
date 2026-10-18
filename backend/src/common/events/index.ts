import {
  DispatchStatus,
  OrderStatus,
  TicketStatus,
  OrderVendorFulfillmentStatus,
} from '@prisma/client';

// ─── Auth ─────────────────────────────────────────────────────────────────────

export class OtpRequestedEvent {
  constructor(
    public readonly contact: string,
    public readonly code: string,
    public readonly method: 'EMAIL' | 'SMS',
    public readonly purpose: 'VERIFICATION' | 'PASSWORD_RESET' = 'VERIFICATION',
  ) {}
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

export class ChatMessageSentEvent {
  constructor(
    public readonly messageId: string,
    public readonly conversationId: string,
    public readonly senderId: string,
    public readonly senderName: string,
    public readonly senderRole: string,
    public readonly participantIds: string[],
    public readonly text: string | null,
    public readonly type: string,
    public readonly mediaUrl: string | null,
    public readonly metadata: Record<string, unknown> | null,
    public readonly createdAt: Date,
    public readonly conversationType?: string,
  ) {}
}

export class ChatMessageReadEvent {
  constructor(
    public readonly conversationId: string,
    public readonly userId: string,
    public readonly participantIds: string[],
    public readonly lastReadAt: Date,
    public readonly lastReadMessageId: string | null,
  ) {}
}

export class ChatConversationCreatedEvent {
  constructor(
    public readonly conversationId: string,
    public readonly participantIds: string[],
    public readonly type: string,
    public readonly orderId: string | null,
  ) {}
}

export class ChatConversationClosedEvent {
  constructor(
    public readonly conversationId: string,
    public readonly participantIds: string[],
    public readonly closedBy: string,
  ) {}
}

// ─── Tickets ──────────────────────────────────────────────────────────────────

export class TicketStatusUpdatedEvent {
  constructor(
    public readonly ticketId: string,
    public readonly ticketNumber: string,
    public readonly status: TicketStatus,
    public readonly creatorId: string,
    public readonly actorId: string,
  ) {}
}

// ─── Orders ───────────────────────────────────────────────────────────────────

export class OrderCreatedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly customerId: string,
    public readonly customerUserId: string,
    public readonly vendorId: string | null,
    public readonly vendorUserIds: string[], // all vendor member userIds
    public readonly grandTotal: number,
    public readonly paymentMethod: string,
    public readonly orderType: string,
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
  ) {}
}

export class OrderPaymentStatusChangedEvent {
  constructor(
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly paymentStatus: string, // PENDING, PAID, COMPLETED
    public readonly customerUserId: string,
    public readonly driverUserId: string | null,
    public readonly vendorUserIds: string[],
    public readonly message: string,
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
    public readonly cancelledByUserId: string | null, // null = system cancel
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
  ) {}
}

// ─── Dispatch ─────────────────────────────────────────────────────────────────

export class OrderDispatchSentEvent {
  constructor(
    public readonly dispatchId: string,
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly type: string,
    public readonly estimatedEarnings: number,
    public readonly distanceKm: number,
    public readonly expiresAt: Date,
    public readonly pickupLocationName?: string,
    public readonly dropoffLocationName?: string,
  ) {}
}

export class OrderDispatchRespondedEvent {
  constructor(
    public readonly dispatchId: string,
    public readonly orderId: string,
    public readonly driverId: string,
    public readonly status: DispatchStatus, // ACCEPTED | REJECTED | EXPIRED
  ) {}
}

export class OrderDispatchCancelledEvent {
  constructor(
    public readonly dispatchId: string,
    public readonly orderId: string,
    public readonly driverUserId: string,
  ) {}
}

// ─── Driver ───────────────────────────────────────────────────────────────────

export class DriverLocationUpdatedEvent {
  constructor(
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly longitude: number,
    public readonly latitude: number,
    public readonly activeOrderId: string | null, // broadcast to customer if on delivery
    public readonly customerUserId: string | null,
  ) {}
}

export class DriverStatusChangedEvent {
  constructor(
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly oldStatus: string,
    public readonly newStatus: string,
    public readonly reason: string | null = null,
  ) {}
}

export type DriverBreakDecision =
  | 'approved'
  | 'rejected'
  | 'granted'
  | 'ended_by_admin'
  | 'auto_ended'
  | 'request_expired';

export class DriverBreakDecidedEvent {
  constructor(
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly breakId: string,
    public readonly action: DriverBreakDecision,
  ) {}
}

// ─── Audit ────────────────────────────────────────────────────────────────────

export class AuditLogCreatedEvent {
  constructor(
    public readonly userId: string,
    public readonly vendorId: string | null,
    public readonly sessionId: string | null,
    public readonly actionType: any,
    public readonly action: string,
    public readonly entityType: string,
    public readonly entityId: string,
    public readonly newValues: any,
    public readonly oldValues?: any,
  ) {}
}

// --- Driver Shifts ---

export class ShiftReminderEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
    public readonly zoneId: string | null,
  ) {}
}

export class ShiftMissedEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
    public readonly newTier: string,
  ) {}
}

export class ShiftSwapCancelledEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
  ) {}
}

export class ShiftDisabledEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
    public readonly reason: 'admin' | 'self' = 'admin',
  ) {}
}

export class ShiftAssignedEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
  ) {}
}

export class ShiftSwapAcceptedEvent {
  constructor(
    public readonly offererUserId: string,
    public readonly accepterUserId: string,
    public readonly shiftId: string,
  ) {}
}

export class ShiftSpotAvailableEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftPoolId: string,
  ) {}
}

export type DriverAssistDecision =
  | 'approved'
  | 'rejected'
  | 'fulfilled'
  | 'cancelled';

export class DriverAssistRequestedEvent {
  constructor(
    public readonly requestId: string,
    public readonly driverUserId: string,
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly deliveryGroupId: string | null,
    public readonly reason: string,
    public readonly note: string | null,
  ) {}
}

export class DriverAssistDecidedEvent {
  constructor(
    public readonly requestId: string,
    public readonly driverUserId: string,
    public readonly orderId: string,
    public readonly decision: DriverAssistDecision,
    public readonly actorUserId: string,
    public readonly assignedDriverUserId: string | null,
  ) {}
}

export class DriverAssistAssignedEvent {
  constructor(
    public readonly requestId: string,
    public readonly orderId: string,
    public readonly deliveryGroupId: string,
    public readonly primaryDriverUserId: string,
    public readonly assistDriverUserId: string,
    public readonly actorUserId: string,
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