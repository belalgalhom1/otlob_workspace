import { TicketStatus } from '@prisma/client';

export class TicketStatusUpdatedEvent {
  constructor(
    public readonly ticketId: string,
    public readonly ticketNumber: string,
    public readonly status: TicketStatus,
    public readonly creatorId: string,
    public readonly actorId: string,
  ) {}
}

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

export class ReviewSubmittedEvent {
  constructor(
    public readonly vendorId: string | null,
    public readonly driverId: string | null,
  ) {}
}
