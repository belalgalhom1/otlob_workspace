import { WS_EVENTS } from './ws-events';

export const EVENTS = {
  // Auth
  AUTH_OTP_REQUESTED: 'auth.otp.requested',

  // Chat
  CHAT_MESSAGE_SENT: 'chat.message.sent',
  CHAT_MESSAGE_READ: 'chat.message.read',
  CHAT_CONVERSATION_CREATED: 'chat.conversation.created',
  CHAT_CONVERSATION_CLOSED: 'chat.conversation.closed',

  // Tickets
  TICKET_STATUS_UPDATED: 'ticket.status.updated',

  // Orders
  ORDER_CREATED: 'order.created',
  ORDER_STATUS_CHANGED: 'order.status.changed',
  ORDER_PAYMENT_STATUS_CHANGED: 'order.payment_status.changed',
  ORDER_CANCELLED: 'order.cancelled',
  ORDER_SETTLED: 'order.settled',

  // Dispatch
  ORDER_DISPATCH_SENT: 'order.dispatch.sent',
  ORDER_DISPATCH_RESPONDED: 'order.dispatch.responded',
  ORDER_DISPATCH_CANCELLED: 'order.dispatch.cancelled',
  /** @deprecated Prefer `WS_EVENTS.ORDER_SEARCH_PROGRESS` for socket emits. */
  ORDER_SEARCH_PROGRESS: WS_EVENTS.ORDER_SEARCH_PROGRESS,

  // Driver & Shifts
  DRIVER_LOCATION_UPDATED: 'driver.location.updated',
  DRIVER_STATUS_CHANGED: 'driver.status.changed',
  DRIVER_BREAK_DECIDED: 'driver.break.decided',
  DRIVER_RANK_UPDATED: 'driver.rank.updated',
  DRIVER_RANK_EVALUATION_FAILED: 'driver.rank.evaluation.failed',
  SHIFT_REMINDER: 'shift.reminder',
  SHIFT_MISSED: 'shift.missed',
  SHIFT_SWAP_CANCELLED: 'shift.swap.cancelled',
  SHIFT_DISABLED: 'shift.disabled',
  SHIFT_ASSIGNED: 'shift.assigned',
  SHIFT_SPOT_AVAILABLE: 'shift.spot.available',

  // Audit
  AUDIT_LOG_CREATED: 'audit.log.created',

  // Reviews
  REVIEW_SUBMITTED: 'review.submitted',

  // Extra-driver assistance
  DRIVER_ASSIST_REQUESTED: 'driver.assist.requested',
  DRIVER_ASSIST_DECIDED: 'driver.assist.decided',
  DRIVER_ASSIST_OFFERED: 'driver.assist.offered',
  DRIVER_ASSIST_ASSIGNED: 'driver.assist.assigned',
  DRIVER_ASSIST_CUSTOMER_DECIDED: 'driver.assist.customer.decided',
  DRIVER_ASSIST_TIMED_OUT: 'driver.assist.timed_out',

  // WebSocket -> Listener internal commands
  WS_DRIVER_LOCATION_UPDATE: 'ws.driver.location.update',
  WS_DRIVER_LOCATION_REQUEST: 'ws.driver.location.request',
  WS_DRIVER_DISCONNECTED: 'ws.driver.disconnected',

  // Multi-vendor orders
  ORDER_FULFILLMENT_DECIDED: 'order.fulfillment.decided',
  ORDER_FULFILLMENT_UPDATED: 'order.fulfillment.updated',
  ORDER_VENDOR_REJECTED: 'order.vendor.rejected',

  // Platform settings
  SETTINGS_UPDATED: 'platform.settings.updated',
} as const;

export type EventName = (typeof EVENTS)[keyof typeof EVENTS];
