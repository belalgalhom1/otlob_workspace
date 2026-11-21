import { DispatchStatus } from '@prisma/client';

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
    public readonly isStacked: boolean = false,
    public readonly deliveryFee?: number,
    public readonly pickupLocationLogo?: string | null,
    public readonly dropoffCustomerAvatar?: string | null,
    public readonly requestedVehicleType?: string | null,
  ) {}
}

export class OrderDispatchRespondedEvent {
  constructor(
    public readonly dispatchId: string,
    public readonly orderId: string,
    public readonly driverId: string,
    public readonly status: DispatchStatus,
  ) {}
}

export class OrderDispatchCancelledEvent {
  constructor(
    public readonly dispatchId: string,
    public readonly orderId: string,
    public readonly driverUserId: string,
  ) {}
}
