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
    public readonly replyTo?: Record<string, unknown> | null,
    public readonly senderTitle?: string | null,
    public readonly senderTitleAr?: string | null,
    public readonly orderId?: string | null,
    public readonly senderAvatar?: string | null,
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
