export const QUEUES = {
  MAIL: 'mail_queue',
  PUSH: 'push_queue',
  ORDERS: 'orders_queue',
  STATS: 'stats_queue',
  RETENTION: 'retention_queue',
  TICKETS: 'tickets_queue',
  VENDORS: 'vendors_queue',
  DRIVERS: 'drivers_queue',
  PROMOTIONS: 'promotions_queue',
  DISPATCH: 'dispatch_queue',
  AUDIT_LOGS: 'audit_logs_queue',
  REVIEWS: 'reviews_queue',
  EVENTS: 'events_queue',
} as const;

export const MAIL_JOBS = {
  SEND_EMAIL: 'send_email',
} as const;

export const PUSH_JOBS = {
  SEND_TO_DEVICES: 'send_devices',
  SEND_TO_TOPIC: 'send_topic',
  SUBSCRIBE_TO_TOPIC: 'subscribe_topic',
  UNSUBSCRIBE_FROM_TOPIC: 'unsubscribe_topic',
} as const;

export const ORDER_JOBS = {
  DISPATCH: 'order.dispatch',
  DISPATCH_EXPIRE: 'order.dispatch_expire',
  SETTLE: 'order.settle',
  DELIVERY_WATCHDOG: 'order.delivery_watchdog',
} as const;

export const CRON_JOBS = {
  VENDOR_SCHEDULE: 'cron.vendor_schedule',
  AUTO_CANCEL_PENDING: 'cron.auto_cancel_pending',
  TICKET_SLA: 'cron.ticket_sla',
  DATA_RETENTION: 'cron.data_retention',
  PROMOTION_CHECK: 'cron.promotion_check',
  STUCK_ORDER_MONITOR: 'cron.stuck_order_monitor',
  UNSETTLED_ORDER_MONITOR: 'cron.unsettled_order_monitor',
  SHIFT_WARNING: 'cron.shift_warning',
  LATE_CHECK: 'cron.late_check',
  BREAK_WATCHDOG: 'cron.break_watchdog',
  GEO_FRESHNESS_SWEEP: 'cron.geo_freshness_sweep',
} as const;

export const STATS_JOBS = {
  UPDATE_VENDOR: 'stats.update_vendor',
  UPDATE_DRIVER: 'stats.update_driver',
  UPDATE_APP: 'stats.update_app',
} as const;

export const AUDIT_JOBS = {
  CREATE: 'audit_log.create',
} as const;

export const TICKET_JOBS = {
  SLA_WATCHDOG: 'ticket.sla_watchdog',
} as const;

export const REVIEW_JOBS = {
  UPDATE_RATINGS: 'review.update_ratings',
} as const;

export const EVENT_JOBS = {
  ORDER_CREATED: 'event.order_created',
  ORDER_STATUS_CHANGED: 'event.order_status_changed',
  ORDER_CANCELLED: 'event.order_cancelled',
  ORDER_DISPATCH_SENT: 'event.order_dispatch_sent',
  ORDER_DISPATCH_RESPONDED: 'event.order_dispatch_responded',
  DISPATCH_HANDOFF: 'event.dispatch_handoff',
  CANCEL_ACTIVE_DISPATCH: 'event.cancel_active_dispatch',
  CLEAR_CART: 'event.clear_cart',
  NOTIFY: 'event.notify',
  CHAT_NOTIFICATIONS: 'event.chat_notifications',
} as const;
