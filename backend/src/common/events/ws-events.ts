/**
 * Canonical Socket.IO event names emitted to connected clients.
 * Kept separate from internal EventEmitter2 `EVENTS` so wire contracts are
 * defined once and never duplicated across listeners or handlers.
 */
export const WS_EVENTS = {
  // Notifications & Chat
  NOTIFICATION: 'notification.new',
  CHAT_MESSAGE: 'chat.message',
  CHAT_READ: 'chat.read',
  CONVERSATION_CREATED: 'conversation.created',
  CONVERSATION_CLOSED: 'conversation.closed',

  // Orders & Multi-vendor Fulfillment
  ORDER_NEW: 'order.new',
  ORDER_STATUS: 'order.status',
  ORDER_FULFILLMENT_UPDATED: 'order.fulfillment_updated',
  ORDER_SEARCH_PROGRESS: 'order.search_progress',
  ORDER_ASSIGNED: 'order.assigned',

  // Extra-driver Assistance
  ASSIST_OFFER: 'assist.offer',
  ORDER_ASSIST_PROPOSED: 'order.assist.proposed',
  ORDER_ASSIST_DECIDED: 'order.assist.decided',
  ORDER_ASSIST_TIMED_OUT: 'order.assist.timed_out',

  // Dispatch
  DISPATCH_INCOMING: 'dispatch.incoming',
  DISPATCH_CANCELLED: 'dispatch.cancelled',

  // Driver
  DRIVER_LOCATION: 'driver.location',
  DRIVER_RANK_UPDATED: 'driver.rank.updated',

  // Platform Settings
  PLATFORM_SETTINGS_UPDATED: 'platform.settings.updated',
} as const;

export type WsEventName = (typeof WS_EVENTS)[keyof typeof WS_EVENTS];
