import { OrderStatus, OrderType } from '@prisma/client';

/**
 * Real-time driver search lifecycle phases derived exclusively from actual
 * backend dispatch & order state transitions.
 */
export enum DriverSearchPhase {
  QUEUED = 'QUEUED',
  FINDING_DRIVERS = 'FINDING_DRIVERS',
  CONTACTING_DRIVERS = 'CONTACTING_DRIVERS',
  WAITING_DRIVER_RESPONSE = 'WAITING_DRIVER_RESPONSE',
  NO_DRIVERS_IN_WAVE = 'NO_DRIVERS_IN_WAVE',
  DRIVER_FOUND = 'DRIVER_FOUND',
  SEARCH_TIMEOUT = 'SEARCH_TIMEOUT',
  NO_DRIVERS_AVAILABLE = 'NO_DRIVERS_AVAILABLE',
  CANCELLED = 'CANCELLED',
}

/**
 * Reason why an active driver search terminated without an accepted driver.
 */
export enum SearchTerminalReason {
  NONE = 'NONE',
  SEARCH_TIMEOUT = 'SEARCH_TIMEOUT',
  NO_DRIVERS_AVAILABLE = 'NO_DRIVERS_AVAILABLE',
  CANCELLED_BY_CUSTOMER = 'CANCELLED_BY_CUSTOMER',
  CANCELLED_BY_ADMIN = 'CANCELLED_BY_ADMIN',
  CANCELLED_BY_SYSTEM = 'CANCELLED_BY_SYSTEM',
}

/**
 * Internal Redis snapshot capturing the active or recently ended driver search
 * session for an order. Never serialized verbatim to customers because it holds
 * deduplication driver IDs; projected into `OrderSearchStatusDto`.
 */
export interface OrderSearchSnapshotRecord {
  orderId: string;
  orderNumber: string;
  orderType: OrderType;
  customerUserId: string;
  orderStatus: OrderStatus;
  revision: number;
  phase: DriverSearchPhase;
  attempt: number;
  maxAttempts: number;
  radiusKm: number;
  maxRadiusKm: number;
  contactedCount: number;
  totalContactedDriverIds: string[];
  rejectedDriverIds: string[];
  waveExpiresAt: string | null;
  searchTimeoutSecs: number;
  searchStartedAt: string;
  updatedAt: string;
  terminalReason: SearchTerminalReason;
  sequence: number;
}

/**
 * WebSocket payload broadcast on `'order.search_progress'` to `user_<customerUserId>`.
 * Deliberately excludes driver IDs and sensitive internal details.
 */
export interface OrderSearchProgressWsPayload {
  orderId: string;
  orderNumber: string;
  orderStatus: OrderStatus;
  revision: number;
  phase: DriverSearchPhase;
  attempt: number;
  maxAttempts: number;
  radiusKm: number;
  maxRadiusKm: number;
  contactedCount: number;
  totalContactedCount: number;
  rejectedCount: number;
  waveExpiresAt: string | null;
  searchTimeoutSecs: number;
  terminalReason: SearchTerminalReason;
  updatedAt: string;
  sequence: number;
}
