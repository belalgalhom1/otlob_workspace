export class WalletTopUpSubmittedEvent {
  constructor(
    public readonly requestId: string,
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly driverName: string,
    public readonly amount: number,
    public readonly platformWalletType: string,
    public readonly platformWalletNumber: string,
    public readonly receiptUrl: string,
  ) {}
}

export class WalletTopUpReviewedEvent {
  constructor(
    public readonly requestId: string,
    public readonly driverId: string,
    public readonly driverUserId: string,
    public readonly driverName: string,
    public readonly reviewerUserId: string,
    public readonly status: 'APPROVED' | 'REJECTED',
    public readonly amount: number,
    public readonly notes: string | null = null,
    public readonly newBalance: number | null = null,
    public readonly platformWalletType: string | null = null,
    public readonly platformWalletNumber: string | null = null,
    public readonly unsuspended: boolean = false,
  ) {}
}

export class DriverManagerPayoutCompletedEvent {
  constructor(
    public readonly transactionId: string,
    public readonly managerId: string,
    public readonly managerUserId: string,
    public readonly managerName: string,
    public readonly amount: number,
    public readonly newBalance: number,
    public readonly receiptUrl: string | null = null,
    public readonly notes: string | null = null,
    public readonly processedByUserId: string | null = null,
  ) {}
}
