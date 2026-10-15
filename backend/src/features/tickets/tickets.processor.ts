import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  QUEUES,
  TICKET_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { TicketStatus, MessageType } from '@prisma/client';
import { MessagesService } from '../chat/messages.service';

@Processor(QUEUES.TICKETS, { concurrency: 5 })
export class TicketsProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(TicketsProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly messagesService: MessagesService,
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
   * Closes one ticket and deletes its chat (messages/participants cascade),
   * mirroring the manual resolve/close path so auto-closed tickets don't
   * leave dead threads behind either.
   */
  private async closeTicketAndDeleteChat(
    ticketId: string,
    conversationId: string | null,
  ): Promise<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.supportTicket.update({
          where: { id: ticketId },
          data: { status: TicketStatus.CLOSED, lastStatusUpdateAt: new Date() },
        });
        if (conversationId) {
          await tx.supportTicket.update({
            where: { id: ticketId },
            data: { conversationId: null },
          });
          // deleteMany: no-throw when the row is already gone, so a
          // half-finished previous attempt can never wedge the retry loop.
          await tx.conversation.deleteMany({
            where: { id: conversationId },
          });
        }
      });
    } catch (error: unknown) {
      this.logger.error(
        `Failed to auto-close ticket ${ticketId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private async handleSlaWatchdog() {
    this.logger.debug('Running Ticket SLA Watchdog');
    const tickStart = new Date();

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
        select: { id: true, conversationId: true, ticketNumber: true },
      });

      for (const ticket of claimed) {
        if (ticket.conversationId) {
          await this.messagesService.sendSystemMessage(
            ticket.conversationId,
            'تم استلام طلبك، مسؤول اطلب بيتابعه دلوقتي | Your request has been received, an Otlob representative is following up now',
          );
        }
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
        select: { id: true, conversationId: true, ticketNumber: true },
      });

      for (const ticket of claimed) {
        if (ticket.conversationId) {
          await this.messagesService.sendSystemMessage(
            ticket.conversationId,
            'عدى 15 دقيقة ولسه مشكلتك ما اتحلتش. تم تحويل طلبك لمدير التطبيق مباشرة 🔴 | 15 minutes passed and your issue is not resolved. Your request has been escalated to the App Manager 🔴',
          );

          await this.messagesService.sendSystemMessage(
            ticket.conversationId,
            'أنا مدير تطبيق اطلب، هتابع مشكلتك بنفسي دلوقتي. اعتذر عن التأخير، هنحلها خلال لحظات | I am the Otlob App Manager, I will follow up on your issue personally now. Apologies for the delay, we will solve it in moments',
          );
        }
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
      select: { id: true, conversationId: true },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });
    for (const ticket of staleWaiting) {
      await this.closeTicketAndDeleteChat(ticket.id, ticket.conversationId);
    }

    // 4. RESOLVED -> CLOSED after 24 hours
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const staleResolved = await this.prisma.supportTicket.findMany({
      where: {
        status: TicketStatus.RESOLVED,
        lastStatusUpdateAt: { lt: twentyFourHoursAgo },
      },
      select: { id: true, conversationId: true },
      take: 100,
      orderBy: { lastStatusUpdateAt: 'asc' },
    });
    for (const ticket of staleResolved) {
      await this.closeTicketAndDeleteChat(ticket.id, ticket.conversationId);
    }

    return {
      movedToInProgress: staleOpen.length,
      escalated: staleInProgress.length,
      closedFromWaiting: staleWaiting.length,
      closedFromResolved: staleResolved.length,
    };
  }
}
