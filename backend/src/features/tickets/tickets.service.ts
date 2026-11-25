import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { JwtAccessPayload } from 'src/common/interfaces/jwt-payload.interface';
import {
  CreateTicketDto,
  UpdateTicketDto,
  QueryTicketsDto,
} from './dto/ticket.dto';
import {
  ConversationStatus,
  ConversationType,
  Role,
  TicketStatus,
  Permission,
  Prisma,
} from '@prisma/client';
import { TicketErrors } from 'src/common/constants/response.constants';
import {
  ChatConversationClosedEvent,
  TicketStatusUpdatedEvent,
} from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { MessagesService } from '../chat/messages.service';
import { DriverManagersService } from '../drivers/driver-managers.service';

const CREATOR_ROLES = new Set<Role>([
  Role.CUSTOMER,
  Role.DRIVER,
  Role.VENDOR_MEMBER,
]);

@Injectable()
export class TicketsService implements OnModuleInit {
  private readonly logger = new Logger(TicketsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly messagesService: MessagesService,
    private readonly driverManagersService: DriverManagersService,
  ) {}

  async onModuleInit() {
    // Ticket SLA Watchdog is scheduled by TicketsProcessor
  }

  private async canManageTickets(
    actorId: string,
    actorRole: Role,
  ): Promise<boolean> {
    if (actorRole === Role.SUPER_ADMIN) return true;

    const user = await this.prisma.user.findUnique({
      where: { id: actorId },
      select: { permissions: true },
    });

    return !!user?.permissions.includes(Permission.MANAGE_TICKETS);
  }

  async create(actor: JwtAccessPayload, dto: CreateTicketDto) {
    const hasManageAll = await this.canManageTickets(actor.sub, actor.role);
    if (!CREATOR_ROLES.has(actor.role) && !hasManageAll) {
      throw new ForbiddenException(TicketErrors.CANNOT_CREATE);
    }

    if (dto.orderId) {
      const order = await this.prisma.order.findUnique({
        where: { id: dto.orderId },
        select: {
          id: true,
          customer: { select: { userId: true } },
          deliveryGroups: {
            select: {
              primaryDriver: { select: { userId: true } },
              assistDriver: { select: { userId: true } },
            },
          },
          vendorFulfillments: {
            where: { status: { notIn: ['REJECTED', 'CANCELLED'] } },
            orderBy: { createdAt: 'asc' },
            select: {
              vendorId: true,
              vendor: { select: { members: { select: { userId: true } } } },
            },
          },
        },
      });
      if (!order) throw new NotFoundException(TicketErrors.ORDER_NOT_FOUND);

      if (!hasManageAll) {
        const isCustomer = order.customer?.userId === actor.sub;
        const isDriver = order.deliveryGroups.some(
          (g) =>
            g.primaryDriver?.userId === actor.sub ||
            g.assistDriver?.userId === actor.sub,
        );
        const isVendor = order.vendorFulfillments.some((f) =>
          f.vendor?.members?.some((m) => m.userId === actor.sub),
        );
        if (!isCustomer && !isDriver && !isVendor) {
          throw new ForbiddenException(TicketErrors.CANNOT_CREATE);
        }
      }

      if (!dto.vendorId) {
        const firstVendorId = order.vendorFulfillments?.[0]?.vendorId;
        if (firstVendorId) {
          dto.vendorId = firstVendorId;
        }
      }
    }
    if (dto.vendorId) await this.assertVendorExists(dto.vendorId);

    const activeTicket = await this.prisma.supportTicket.findFirst({
      where: {
        creatorId: actor.sub,
        status: { notIn: [TicketStatus.CLOSED, TicketStatus.RESOLVED] },
      },
    });

    if (activeTicket) {
      throw new BadRequestException(TicketErrors.ACTIVE_TICKET_EXISTS);
    }

    // Determine the assignee depending on the category of the ticket
    let assigneeId: string | null = null;

    if (dto.category === 'VENDOR') {
      if (dto.vendorId) {
        const members = await this.prisma.vendorMember.findMany({
          where: { vendorId: dto.vendorId },
          select: { userId: true },
        });
        if (members.length > 0) {
          const randomIndex = Math.floor(Math.random() * members.length);
          assigneeId = members[randomIndex].userId;
        }
      }
    } else if (dto.category === 'DELIVERY') {
      if (dto.orderId) {
        const order = await this.prisma.order.findUnique({
          where: { id: dto.orderId },
          select: {
            deliveryGroups: {
              where: { primaryDriverId: { not: null } },
              orderBy: { sequence: 'asc' },
              take: 1,
              select: { primaryDriverId: true },
            },
          },
        });
        const driverId = order?.deliveryGroups?.[0]?.primaryDriverId;
        if (driverId) {
          const driver = await this.prisma.driver.findUnique({
            where: { id: driverId },
            select: { userId: true, id: true },
          });
          if (driver) {
            // Prefer the manager this driver is actually assigned to. Only fall
            // back to a "manages all drivers" manager when there is no specific
            // assignment, otherwise every ticket would go to that one manager.
            const assignment =
              await this.prisma.driverManagerAssignment.findFirst({
                where: { driverId: driver.id },
                include: { driverManager: { select: { userId: true } } },
              });
            if (assignment?.driverManager?.userId) {
              assigneeId = assignment.driverManager.userId;
            } else {
              const managerWithAll = await this.prisma.driverManager.findFirst({
                where: { manageAllDrivers: true },
                select: { userId: true },
              });
              if (managerWithAll?.userId) {
                assigneeId = managerWithAll.userId;
              }
            }
          }
        }
      }
      if (!assigneeId) {
        const supervisor = await this.prisma.user.findFirst({
          where: { role: Role.ADMIN },
          select: { id: true },
        });
        if (supervisor) {
          assigneeId = supervisor.id;
        }
      }
    } else if (dto.category === 'PAYMENT') {
      const supervisor = await this.prisma.user.findFirst({
        where: { role: Role.SUPER_ADMIN },
        select: { id: true },
      });
      if (supervisor) {
        assigneeId = supervisor.id;
      }
    } else if (dto.category === 'ACCOUNT') {
      const supervisor = await this.prisma.user.findFirst({
        where: { role: Role.SUPER_ADMIN },
        select: { id: true },
      });
      if (supervisor) {
        assigneeId = supervisor.id;
      }
    } else if (dto.category === 'RETURN_COMPLAINT') {
      const supervisor = await this.prisma.user.findFirst({
        where: { role: Role.SUPER_ADMIN },
        select: { id: true },
      });
      if (supervisor) {
        assigneeId = supervisor.id;
      }
    }

    // Fallback: If no specific supervisor was assigned for the category
    if (!assigneeId) {
      const supervisor = await this.prisma.user.findFirst({
        where: { role: Role.SUPER_ADMIN },
        select: { id: true },
      });
      if (supervisor) {
        assigneeId = supervisor.id;
      }
    }

    const ticketNumber = await this.generateTicketNumber();

    const ticket = await this.prisma.$transaction(async (tx) => {
      const created = await tx.supportTicket.create({
        data: {
          ticketNumber,
          subject: dto.subject,
          description: dto.description ?? null,
          category: dto.category,
          subCategory: dto.subCategory,
          priority: dto.priority,
          status: TicketStatus.OPEN,
          creatorId: actor.sub,
          assigneeId: assigneeId,
          orderId: dto.orderId ?? null,
          vendorId: dto.vendorId ?? null,
          metadata: dto.metadata ?? Prisma.DbNull,
          lastStatusUpdateAt: new Date(),
        },
      });

      const conversation = await tx.conversation.create({
        data: {
          type: ConversationType.SUPPORT,
          status: ConversationStatus.OPEN,
          creatorId: actor.sub,
          vendorId: dto.vendorId ?? null,
          participants: {
            create: [
              { userId: actor.sub },
              ...(assigneeId ? [{ userId: assigneeId }] : []),
            ],
          },
        },
      });

      const updated = await tx.supportTicket.update({
        where: { id: created.id },
        data: { conversationId: conversation.id },
        include: this.ticketIncludes(),
      });

      return updated;
    });

    // Send auto-reply welcome message if configured by the assignee
    if (assigneeId && ticket.conversationId) {
      const assigneeUser = await this.prisma.user.findUnique({
        where: { id: assigneeId },
        select: { autoReplyMessage: true },
      });
      if (assigneeUser?.autoReplyMessage) {
        const creatorUser = await this.prisma.user.findUnique({
          where: { id: actor.sub },
          select: { name: true },
        });
        const customerName = creatorUser?.name ?? 'Customer';
        const welcomeMessage = assigneeUser.autoReplyMessage
          .replace(/\[customer name\]/gi, customerName)
          .replace(/\{customerName\}/gi, customerName)
          .replace(/\[customer_name\]/gi, customerName)
          .replace(/\{name\}/gi, customerName)
          .replace(/\[name\]/gi, customerName);

        await this.messagesService.sendAutoReply(
          assigneeId,
          ticket.conversationId,
          welcomeMessage,
        );
      }
    }

    this.logger.log(
      `Ticket created: ${ticket.ticketNumber} by user ${actor.sub} (assigned to ${assigneeId ?? 'none'})`,
    );
    return this.formatTicket(ticket, actor);
  }

  async list(actor: JwtAccessPayload, dto: QueryTicketsDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: Prisma.SupportTicketWhereInput = {};
    const canManageAll = await this.canManageTickets(actor.sub, actor.role);

    if (actor.role === Role.SUPER_ADMIN || canManageAll) {
      if (dto.creatorId) where.creatorId = dto.creatorId;
      if (dto.assigneeId) where.assigneeId = dto.assigneeId;
    } else if (actor.role === Role.ADMIN) {
      where.OR = [{ creatorId: actor.sub }, { assigneeId: actor.sub }];
      if (dto.creatorId) where.creatorId = dto.creatorId;
      if (dto.assigneeId) where.assigneeId = dto.assigneeId;
    } else if (actor.role === Role.VENDOR_MEMBER) {
      const memberships = await this.prisma.vendorMember.findMany({
        where: { userId: actor.sub },
        select: { vendorId: true },
      });
      const vendorIds = memberships.map((m) => m.vendorId);
      where.OR =
        vendorIds.length > 0
          ? [
              { category: 'VENDOR', vendorId: { in: vendorIds } },
              { creatorId: actor.sub },
            ]
          : [{ creatorId: actor.sub }];
    } else {
      where.creatorId = actor.sub;
    }

    if (dto.status) where.status = dto.status;
    if (dto.priority) where.priority = dto.priority;
    if (dto.category) where.category = dto.category;

    const [tickets, total, counts] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: this.ticketIncludes(),
      }),
      this.prisma.supportTicket.count({ where }),
      this.prisma.supportTicket.groupBy({
        by: ['status'],
        _count: { status: true },
        where: where,
      }),
    ]);

    const statusCounts = counts.reduce(
      (acc, curr) => {
        acc[curr.status] = curr._count.status;
        return acc;
      },
      {} as Record<string, number>,
    );

    return {
      tickets: tickets.map((t) => this.formatTicket(t, actor)),
      total,
      counts: statusCounts,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getOne(actor: JwtAccessPayload, ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: this.ticketIncludes(),
    });

    if (!ticket) throw new NotFoundException(TicketErrors.NOT_FOUND);

    await this.assertAccess(actor, ticket);
    return this.formatTicket(ticket, actor);
  }

  async update(
    actor: JwtAccessPayload,
    ticketId: string,
    dto: UpdateTicketDto,
  ) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
    });

    if (!ticket) throw new NotFoundException(TicketErrors.NOT_FOUND);

    await this.assertAccess(actor, ticket);

    const isCreator = ticket.creatorId === actor.sub;
    const hasManageAll = await this.canManageTickets(actor.sub, actor.role);
    let isVendorManager = false;
    if (
      actor.role === Role.VENDOR_MEMBER &&
      ticket.category === 'VENDOR' &&
      ticket.vendorId
    ) {
      const membership = await this.prisma.vendorMember.findFirst({
        where: { userId: actor.sub, vendorId: ticket.vendorId },
        select: { role: true },
      });
      isVendorManager = !!membership && membership.role !== 'STAFF';
    }
    const isManager =
      actor.role === Role.SUPER_ADMIN || hasManageAll || isVendorManager;

    if (!isManager && !isCreator) {
      throw new ForbiddenException(TicketErrors.CANNOT_UPDATE);
    }

    if (!isManager) {
      const allowedKeys = new Set(['status']);
      const attemptedKeys = Object.keys(dto).filter(
        (k) => dto[k as keyof UpdateTicketDto] !== undefined,
      );

      if (attemptedKeys.some((k) => !allowedKeys.has(k))) {
        throw new ForbiddenException(TicketErrors.CANNOT_UPDATE);
      }

      if (dto.status && dto.status !== TicketStatus.CLOSED) {
        throw new ForbiddenException(TicketErrors.CANNOT_UPDATE);
      }
    }

    let targetVendorId = dto.vendorId;
    if (dto.category === 'VENDOR' && !targetVendorId && ticket.orderId) {
      const order = await this.prisma.order.findUnique({
        where: { id: ticket.orderId },
        select: {
          vendorFulfillments: {
            where: { status: { notIn: ['REJECTED', 'CANCELLED'] } },
            orderBy: { createdAt: 'asc' },
            take: 1,
            select: { vendorId: true },
          },
        },
      });
      const firstVendorId = order?.vendorFulfillments?.[0]?.vendorId;
      if (firstVendorId) {
        targetVendorId = firstVendorId;
      }
    }

    if (dto.assigneeId) {
      await this.assertAssigneeCanManage(dto.assigneeId);
    }
    if (targetVendorId) {
      await this.assertVendorExists(targetVendorId);
    } else if (dto.vendorId) {
      await this.assertVendorExists(dto.vendorId);
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const isTransfer =
        dto.category !== undefined && dto.category !== ticket.category;

      const result = await tx.supportTicket.update({
        where: { id: ticketId },
        data: {
          ...(dto.subject !== undefined && { subject: dto.subject }),
          ...(dto.description !== undefined && {
            description: dto.description,
          }),
          ...(dto.status !== undefined && {
            status: dto.status,
            lastStatusUpdateAt: new Date(),
          }),
          ...(dto.priority !== undefined && { priority: dto.priority }),
          ...(dto.category !== undefined && { category: dto.category }),
          ...(dto.category === 'VENDOR'
            ? {
                vendorId: targetVendorId ?? null,
                ...(isTransfer
                  ? { assigneeId: null }
                  : dto.assigneeId !== undefined && {
                      assigneeId: dto.assigneeId,
                    }),
              }
            : {
                ...(dto.category !== undefined
                  ? { vendorId: null }
                  : dto.vendorId !== undefined && { vendorId: dto.vendorId }),
                ...(isTransfer
                  ? { assigneeId: null }
                  : dto.assigneeId !== undefined && {
                      assigneeId: dto.assigneeId,
                    }),
              }),
          ...(dto.subCategory !== undefined && {
            subCategory: dto.subCategory,
          }),
          ...(dto.metadata !== undefined && { metadata: dto.metadata }),
        },
        include: this.ticketIncludes(),
      });

      if (result.conversationId) {
        const resolvedVendorId =
          dto.category === 'VENDOR'
            ? (targetVendorId ?? result.vendorId)
            : dto.category !== undefined
              ? null
              : dto.vendorId !== undefined
                ? dto.vendorId
                : result.vendorId;

        await tx.conversation.update({
          where: { id: result.conversationId },
          data: { vendorId: resolvedVendorId },
        });

        if (isTransfer) {
          await tx.conversationParticipant.deleteMany({
            where: {
              conversationId: result.conversationId,
              userId: actor.sub,
            },
          });
        }
      }

      if (dto.assigneeId && !isTransfer && result.conversationId) {
        const alreadyIn = await tx.conversationParticipant.findUnique({
          where: {
            conversationId_userId: {
              conversationId: result.conversationId,
              userId: dto.assigneeId,
            },
          },
        });

        if (!alreadyIn) {
          await tx.conversationParticipant.create({
            data: {
              conversationId: result.conversationId,
              userId: dto.assigneeId,
            },
          });
        }
      }

      if (
        dto.status === TicketStatus.RESOLVED ||
        dto.status === TicketStatus.CLOSED
      ) {
        if (result.conversationId) {
          // Resolving/closing removes the customer (creator) from the chat
          // participants and closes the conversation so the customer cannot
          // view or re-enter the thread by any means, while preserving the
          // conversation and messages for admins/managers.
          await tx.conversationParticipant.deleteMany({
            where: {
              conversationId: result.conversationId,
              userId: result.creatorId,
            },
          });
          await tx.conversation.updateMany({
            where: { id: result.conversationId },
            data: { status: ConversationStatus.CLOSED },
          });
          if (result.conversation) {
            result.conversation.status = ConversationStatus.CLOSED;
          }
        }
      } else if (
        dto.status !== undefined &&
        result.conversationId &&
        (ticket.status === TicketStatus.RESOLVED ||
          ticket.status === TicketStatus.CLOSED)
      ) {
        await tx.conversationParticipant.createMany({
          data: [
            { conversationId: result.conversationId, userId: result.creatorId },
          ],
          skipDuplicates: true,
        });
        await tx.conversation.updateMany({
          where: { id: result.conversationId },
          data: { status: ConversationStatus.OPEN },
        });
        if (result.conversation) {
          result.conversation.status = ConversationStatus.OPEN;
        }
      }

      return result;
    });

    if (
      (dto.status === TicketStatus.RESOLVED ||
        dto.status === TicketStatus.CLOSED) &&
      updated.conversationId
    ) {
      this.eventEmitter.emit(
        EVENTS.CHAT_CONVERSATION_CLOSED,
        new ChatConversationClosedEvent(
          updated.conversationId,
          [updated.creatorId],
          actor.sub,
        ),
      );
    }

    if (dto.status && dto.status !== ticket.status) {
      this.eventEmitter.emit(
        EVENTS.TICKET_STATUS_UPDATED,
        new TicketStatusUpdatedEvent(
          updated.id,
          updated.ticketNumber,
          updated.status,
          updated.creatorId,
          actor.sub,
        ),
      );
    }

    this.logger.log(
      `Ticket ${ticket.ticketNumber} updated by user ${actor.sub}`,
    );
    return this.formatTicket(updated, actor);
  }

  async remove(actor: JwtAccessPayload, ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
    });

    if (!ticket) throw new NotFoundException(TicketErrors.NOT_FOUND);

    await this.assertAccess(actor, ticket);

    const hasManageAll = await this.canManageTickets(actor.sub, actor.role);
    let isVendorManager = false;
    if (
      actor.role === Role.VENDOR_MEMBER &&
      ticket.category === 'VENDOR' &&
      ticket.vendorId
    ) {
      const membership = await this.prisma.vendorMember.findFirst({
        where: { userId: actor.sub, vendorId: ticket.vendorId },
        select: { role: true },
      });
      isVendorManager = !!membership && membership.role !== 'STAFF';
    }

    const isManager =
      actor.role === Role.SUPER_ADMIN || hasManageAll || isVendorManager;

    if (!isManager) {
      throw new ForbiddenException(TicketErrors.CANNOT_DELETE);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.supportTicket.delete({ where: { id: ticketId } });
      if (ticket.conversationId) {
        await tx.conversation.updateMany({
          where: { id: ticket.conversationId },
          data: { status: ConversationStatus.CLOSED },
        });
      }
    });

    this.logger.log(
      `Ticket ${ticket.ticketNumber} deleted by manager ${actor.sub}`,
    );
    return { deleted: true };
  }

  private async generateTicketNumber(): Promise<string> {
    const result = await this.prisma.$queryRaw<[{ nextval: bigint }]>`
      SELECT nextval('ticket_number_seq')
    `;
    const seq = Number(result[0].nextval);
    return `#A${String(seq).padStart(5, '0')}`;
  }

  private async assertVendorExists(vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      select: { id: true },
    });
    if (!vendor) throw new NotFoundException(TicketErrors.VENDOR_NOT_FOUND);
  }

  private async assertAssigneeCanManage(assigneeId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: assigneeId },
      select: { role: true, permissions: true },
    });

    if (!user)
      throw new BadRequestException(TicketErrors.ASSIGNEE_MUST_BE_ADMIN);

    const canManage =
      user.role === Role.SUPER_ADMIN ||
      user.permissions.includes(Permission.MANAGE_TICKETS);

    if (!canManage)
      throw new BadRequestException(TicketErrors.ASSIGNEE_MUST_BE_ADMIN);
  }

  private async assertAccess(
    actor: JwtAccessPayload,
    ticket: {
      creatorId: string;
      assigneeId: string | null;
      category: string;
      vendorId: string | null;
    },
  ) {
    if (actor.role === Role.SUPER_ADMIN) return;
    if (ticket.creatorId === actor.sub) return;
    if (ticket.assigneeId === actor.sub) return;
    if (await this.canManageTickets(actor.sub, actor.role)) return;

    if (actor.role === Role.VENDOR_MEMBER) {
      if (ticket.category === 'VENDOR' && ticket.vendorId) {
        const membership = await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub, vendorId: ticket.vendorId },
          select: { id: true },
        });
        if (membership) return;
      }
    }

    throw new ForbiddenException(TicketErrors.CANNOT_VIEW);
  }

  private ticketIncludes() {
    return {
      creator: {
        select: { id: true, name: true, avatar: true, role: true },
      },
      assignee: {
        select: { id: true, name: true, avatar: true, role: true },
      },
      order: {
        select: { id: true, orderNumber: true, status: true },
      },
      vendor: {
        select: { id: true, storeName: true, logo: true },
      },
      conversation: {
        select: { id: true, status: true },
      },
    } as const;
  }

  private formatTicket(ticketRaw: unknown, viewer?: JwtAccessPayload) {
    const ticket = ticketRaw as {
      id: string;
      ticketNumber: string;
      subject: string;
      description: string | null;
      status: string;
      category: string;
      subCategory: string | null;
      priority: string;
      creator: {
        id: string;
        name: string;
        avatar: string | null;
        role: string;
      };
      assignee?: {
        id: string;
        name: string;
        avatar: string | null;
        role: string;
      } | null;
      order?: { id: string; orderNumber: string; status: string } | null;
      vendor?: { id: string; storeName: string; logo: string | null } | null;
      conversationId: string | null;
      conversation?: { id: string; status: string } | null;
      metadata: Prisma.JsonValue;
      lastStatusUpdateAt: Date;
      escalatedAt: Date | null;
      createdAt: Date;
      updatedAt: Date;
    };
    const isResolvedOrClosed =
      ticket.status === TicketStatus.RESOLVED ||
      ticket.status === TicketStatus.CLOSED;
    const hideConversationFromViewer =
      isResolvedOrClosed &&
      viewer !== undefined &&
      viewer.sub === ticket.creator.id &&
      viewer.role !== Role.SUPER_ADMIN;

    return {
      id: ticket.id,
      ticketNumber: ticket.ticketNumber,
      subject: ticket.subject,
      description: ticket.description,
      status: ticket.status,
      category: ticket.category,
      subCategory: ticket.subCategory,
      priority: ticket.priority,
      creator: ticket.creator,
      assignee: ticket.assignee ?? null,
      order: ticket.order ?? null,
      vendor: ticket.vendor ?? null,
      conversationId: hideConversationFromViewer
        ? null
        : (ticket.conversationId ?? null),
      conversation: hideConversationFromViewer
        ? null
        : (ticket.conversation ?? null),
      metadata: ticket.metadata,
      lastStatusUpdateAt: ticket.lastStatusUpdateAt,
      escalatedAt: ticket.escalatedAt,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
    };
  }
}
