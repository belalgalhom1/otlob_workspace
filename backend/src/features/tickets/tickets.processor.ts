import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  QUEUES,
  TICKET_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { ConversationStatus, TicketStatus } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  ChatConversationClosedEvent,
  TicketStatusUpdatedEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { MessagesService } from '../chat/messages.service';

@Processor(QUEUES.TICKETS, { concurrency: 5 })
export class TicketsProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(TicketsProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly messagesService: MessagesService,
    private readonly eventEmitter: EventEmitter2,
    @InjectQueue(QUEUES.TICKETS) private readonly queue: Queue,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling Tickets domain cron jobs...');
    await this.queue.add(
      CRON_JOBS.TICKET_SLA,
      {},
      { repeat: { pattern: '*/5 * * * *' }, jobId: CRON_JOBS.TICKET_SLA },
    );
  }

  async process(job: Job): Promise<any> {
    switch (job.name) {
      case TICKET_JOBS.SLA_WATCHDOG:
      case CRON_JOBS.TICKET_SLA:
        return this.handleSlaWatchdog();
      default:
        this.logger.warn(`Unknown ticket job: ${job.name}`);
    }
  }

  /**
   * Closes one ticket and removes the customer from its chat participants
   * (closing the conversation without deleting messages), mirroring the
   * manual resolve/close path.
   */
  private async closeTicketAndRemoveCustomer(
    ticketId: string,
    ticketNumber: string,
    conversationId: string | null,
    creatorId: string,
  ): Promise<boolean> {
    try {
      const updated = await this.prisma.$transaction(async (tx) => {
        const res = await tx.supportTicket.updateMany({
          where: {
            id: ticketId,
            status: {
              in: [TicketStatus.WAITING_ON_USER, TicketStatus.RESOLVED],
            },
          },
          data: { status: TicketStatus.CLOSED, lastStatusUpdateAt: new Date() },
        });
        if (res.count === 0) return false;

        if (conversationId) {
          await tx.conversationParticipant.deleteMany({
            where: {
              conversationId,
              userId: creatorId,
            },
          });
          await tx.conversation.updateMany({
            where: { id: conversationId },
            data: { status: ConversationStatus.CLOSED },
          });
        }
        return true;
      });
      if (!updated) return false;

      if (conversationId) {
        this.eventEmitter.emit(
          EVENTS.CHAT_CONVERSATION_CLOSED,
          new ChatConversationClosedEvent(
            conversationId,
            [creatorId],
            'system',
          ),
        );
      }
      this.eventEmitter.emit(
        EVENTS.TICKET_STATUS_UPDATED,
        new TicketStatusUpdatedEvent(
          ticketId,
          ticketNumber,
          TicketStatus.CLOSED,
          creatorId,
          'system',
        ),
      );
      return true;
    } catch (error: unknown) {
      this.logger.error(
        `Failed to auto-close ticket ${ticketId}: ${error instanceof Error ? error.message : String(error)}`,
      );
      return false;
    }
  }

  private async handleSlaWatchdog() {
    this.logger.debug('Running Ticket SLA Watchdog');
    const tickStart = new Date();
    let movedToInProgress = 0;
    let escalated = 0;
    let closedFromWaiting = 0;
    let closedFromResolved = 0;

    // 1. OPEN -> IN_PROGRESS after 2 minutes
    const twoMinsAgo = new Date(Date.now() - 2 * 60 * 1000);
    const staleOpen = await this.prisma.supportTicket.findMany({
      where: {
        status: TicketStatus.OPEN,
        lastStatusUpdateAt: { lt: twoMinsAgo },
      },
      select: { id: true },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });

    if (staleOpen.length > 0) {
      const ids = staleOpen.map((t) => t.id);
      // CAS on status: overlapping ticks flip disjoint sets. Messages go
      // only to rows this tick actually claimed (re-read below).
      await this.prisma.supportTicket.updateMany({
        where: { id: { in: ids }, status: TicketStatus.OPEN },
        data: {
          status: TicketStatus.IN_PROGRESS,
          lastStatusUpdateAt: new Date(),
        },
      });
      const claimed = await this.prisma.supportTicket.findMany({
        where: {
          id: { in: ids },
          status: TicketStatus.IN_PROGRESS,
          lastStatusUpdateAt: { gte: tickStart },
        },
        select: {
          id: true,
          conversationId: true,
          ticketNumber: true,
          creatorId: true,
        },
      });
      movedToInProgress = claimed.length;

      for (const ticket of claimed) {
        if (ticket.conversationId) {
          try {
            await this.messagesService.sendSystemMessage(
              ticket.conversationId,
              'تم استلام طلبك، مسؤول اطلب بيتابعه دلوقتي | Your request has been received, an Otlob representative is following up now',
            );
          } catch (err) {
            this.logger.warn(
              `Failed SLA message for ticket ${ticket.ticketNumber}: ${err instanceof Error ? err.message : String(err)}`,
            );
          }
        }
        this.eventEmitter.emit(
          EVENTS.TICKET_STATUS_UPDATED,
          new TicketStatusUpdatedEvent(
            ticket.id,
            ticket.ticketNumber,
            TicketStatus.IN_PROGRESS,
            ticket.creatorId,
            'system',
          ),
        );
        this.logger.log(
          `Auto-moved ticket ${ticket.ticketNumber} to IN_PROGRESS`,
        );
      }
    }

    // 2. IN_PROGRESS -> ESCALATED after 15 minutes
    const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000);
    const staleInProgress = await this.prisma.supportTicket.findMany({
      where: {
        status: TicketStatus.IN_PROGRESS,
        lastStatusUpdateAt: { lt: fifteenMinsAgo },
      },
      select: { id: true },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });

    if (staleInProgress.length > 0) {
      const ids = staleInProgress.map((t) => t.id);
      await this.prisma.supportTicket.updateMany({
        where: { id: { in: ids }, status: TicketStatus.IN_PROGRESS },
        data: {
          status: TicketStatus.ESCALATED,
          lastStatusUpdateAt: new Date(),
          escalatedAt: new Date(),
        },
      });
      const claimed = await this.prisma.supportTicket.findMany({
        where: {
          id: { in: ids },
          status: TicketStatus.ESCALATED,
          lastStatusUpdateAt: { gte: tickStart },
        },
        select: {
          id: true,
          conversationId: true,
          ticketNumber: true,
          creatorId: true,
        },
      });
      escalated = claimed.length;

      for (const ticket of claimed) {
        if (ticket.conversationId) {
          try {
            await this.messagesService.sendSystemMessage(
              ticket.conversationId,
              'عدى 15 دقيقة ولسه مشكلتك ما اتحلتش. تم تحويل طلبك لمدير التطبيق مباشرة 🔴 | 15 minutes passed and your issue is not resolved. Your request has been escalated to the App Manager 🔴',
            );

            await this.messagesService.sendSystemMessage(
              ticket.conversationId,
              'أنا مدير تطبيق اطلب، هتابع مشكلتك بنفسي دلوقتي. اعتذر عن التأخير، هنحلها خلال لحظات | I am the Otlob App Manager, I will follow up on your issue personally now. Apologies for the delay, we will solve it in moments',
            );
          } catch (err) {
            this.logger.warn(
              `Failed escalation message for ticket ${ticket.ticketNumber}: ${err instanceof Error ? err.message : String(err)}`,
            );
          }
        }
        this.eventEmitter.emit(
          EVENTS.TICKET_STATUS_UPDATED,
          new TicketStatusUpdatedEvent(
            ticket.id,
            ticket.ticketNumber,
            TicketStatus.ESCALATED,
            ticket.creatorId,
            'system',
          ),
        );
        this.logger.log(
          `Escalated ticket ${ticket.ticketNumber} due to timeout`,
        );
      }
    }

    // 3. WAITING_ON_USER -> CLOSED after 48 hours
    const fortyEightHoursAgo = new Date(Date.now() - 48 * 60 * 60 * 1000);
    const staleWaiting = await this.prisma.supportTicket.findMany({
      where: {
        status: TicketStatus.WAITING_ON_USER,
        lastStatusUpdateAt: { lt: fortyEightHoursAgo },
      },
      select: {
        id: true,
        ticketNumber: true,
        conversationId: true,
        creatorId: true,
      },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });
    for (const ticket of staleWaiting) {
      if (
        await this.closeTicketAndRemoveCustomer(
          ticket.id,
          ticket.ticketNumber,
          ticket.conversationId,
          ticket.creatorId,
        )
      ) {
        closedFromWaiting += 1;
      }
    }

    // 4. RESOLVED -> CLOSED after 24 hours
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const staleResolved = await this.prisma.supportTicket.findMany({
      where: {
        status: TicketStatus.RESOLVED,
        lastStatusUpdateAt: { lt: twentyFourHoursAgo },
      },
      select: {
        id: true,
        ticketNumber: true,
        conversationId: true,
        creatorId: true,
      },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });
    for (const ticket of staleResolved) {
      if (
        await this.closeTicketAndRemoveCustomer(
          ticket.id,
          ticket.ticketNumber,
          ticket.conversationId,
          ticket.creatorId,
        )
      ) {
        closedFromResolved += 1;
      }
    }

    return {
      movedToInProgress,
      escalated,
      closedFromWaiting,
      closedFromResolved,
    };
  }
}
