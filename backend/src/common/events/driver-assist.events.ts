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

export class DriverAssistOfferedEvent {
  constructor(
    public readonly requestId: string,
    public readonly orderId: string,
    public readonly targetUserIds: string[],
    public readonly expiresAt: string,
    public readonly orderNumber?: string,
    public readonly reason?: string,
    public readonly proposedAssistFee?: number,
    public readonly deliveryGroupId?: string | null,
  ) {}
}

export class DriverAssistAssignedEvent {
  constructor(
    public readonly requestId: string,
    public readonly orderId: string,
    public readonly orderNumber: string,
    public readonly deliveryGroupId: string | null,
    public readonly assistFee: number,
    public readonly customerUserId: string | null,
    public readonly primaryDriverUserId: string | null,
    public readonly assistDriverUserId: string,
  ) {}
}

export class DriverAssistCustomerDecidedEvent {
  constructor(
    public readonly orderId: string,
    public readonly deliveryGroupId: string | null,
    public readonly approved: boolean,
    public readonly assistFee: number,
    public readonly primaryDriverUserId: string | null,
    public readonly assistDriverUserId: string | null,
  ) {}
}

export class DriverAssistTimedOutEvent {
  constructor(
    public readonly orderId: string,
    public readonly deliveryGroupId: string | null,
    public readonly customerUserId: string | null,
    public readonly primaryDriverUserId: string | null,
    public readonly assistDriverUserId: string | null,
  ) {}
}
