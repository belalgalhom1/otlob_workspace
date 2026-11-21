export class DriverLocationUpdatedEvent {
  constructor(
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly longitude: number,
    public readonly latitude: number,
    public readonly activeOrderId: string | null,
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

export class DriverRankUpdatedEvent {
  constructor(
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly previousTier: string,
    public readonly newTier: string,
    public readonly performancePercentage: number | null,
    public readonly periodKey: string | null,
    public readonly changeReason: string,
    public readonly overrideReason?: string | null,
  ) {}
}

export class DriverRankEvaluationFailedEvent {
  constructor(
    public readonly runId: string,
    public readonly periodKey: string,
    public readonly errorMessage: string,
  ) {}
}

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
    public readonly newTier?: string | null,
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
    public readonly count: number = 1,
  ) {}
}

export class ShiftAssignedEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftId: string,
  ) {}
}

export class ShiftSpotAvailableEvent {
  constructor(
    public readonly driverUserId: string,
    public readonly shiftPoolId: string,
  ) {}
}
