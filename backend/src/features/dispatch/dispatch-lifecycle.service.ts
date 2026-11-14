import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { v4 as uuidv4 } from 'uuid';
import {
  DeliveryGroupStatus,
  DispatchStatus,
  DriverStatus,
  OrderStatus,
} from '@prisma/client';
import {
  EVENT_JOBS,
  ORDER_JOBS,
  QUEUES,
} from '../../infrastructure/queue/queues.constants';
import { EVENTS } from '../../common/events/event-names';
import {
  OrderDispatchCancelledEvent,
  OrderDispatchRespondedEvent,
  OrderStatusChangedEvent,
} from '../../common/events';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { LocationRepository } from '../location/location.repository';
import { OrderWorkflowDispatcher } from '../../common/orders/order-workflow.dispatcher';
import { DriverWorkloadHelper } from '../../common/orders/driver-workload.helper';
import { OrderErrors } from '../../common/constants/response.constants';
import {
  DispatchBroadcastPayload,
  DispatchCandidateOffer,
  DispatchRepository,
} from './dispatch.repository';

const DRIVER_ASSIGNABLE_STATUSES: DriverStatus[] = [
  DriverStatus.ONLINE,
  DriverStatus.BUSY,
];

const DISPATCHABLE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.LOOKING_FOR_DRIVER,
  OrderStatus.ACCEPTED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
];

/**
 * Owns dispatch lifecycle resolution after broadcast:
 * driver acceptance, driver rejection & early retry, offer expiry, and active
 * dispatch cancellation.
 */
@Injectable()
export class DispatchLifecycleService {
  private readonly logger = new Logger(DispatchLifecycleService.name);

  constructor(
    private readonly dispatchRepository: DispatchRepository,
    private readonly platformSettings: PlatformSettingsService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
    private readonly locationRepository: LocationRepository,
    @InjectQueue(QUEUES.DISPATCH) private readonly dispatchQueue: Queue,
    @InjectQueue(QUEUES.EVENTS) private readonly eventsQueue: Queue,
    private readonly outbox: OutboxService,
    private readonly workflowDispatcher: OrderWorkflowDispatcher,
    private readonly driverWorkload: DriverWorkloadHelper,
  ) {}

  // ─── Handle expiry ────────────────────────────────────────────────────────

  async handleExpiry(payload: {
    dispatchId: string;
    orderId: string;
    orderNumber: string;
    attempt: number;
    excludeDriverIds: string[];
    deliveryGroupId?: string | null;
  }): Promise<void> {
    const { dispatchId, orderId, orderNumber, attempt, excludeDriverIds } =
      payload;

    const dispatchData = await this.dispatchRepository.getBroadcast(dispatchId);
    if (!dispatchData) return;

    const groupScope =
      dispatchData.deliveryGroupId ??
      payload.deliveryGroupId ??
      dispatchData.candidates?.[0]?.deliveryGroupId ??
      null;
    const expiryScope = groupScope ?? orderId;

    if (await this.isTargetTerminal(orderId, groupScope)) {
      await this.cleanupTerminatedBroadcast(dispatchId, expiryScope);
      return;
    }

    const stillOwner = await this.dispatchRepository.releaseActiveClaim(
      expiryScope,
      dispatchId,
    );
    await this.dispatchRepository.deleteBroadcast(dispatchId);
    if (stillOwner) {
      await this.dispatchRepository.deleteDispatchState(expiryScope);
    }

    const rejectedBy =
      await this.dispatchRepository.getRejectedDriverIds(dispatchId);
    await this.dispatchRepository.deleteRejectedSet(dispatchId);

    const candidates = dispatchData.candidates || [];
    await this.dispatchRepository.removeDispatchForCandidates(
      candidates,
      dispatchId,
    );

    const unresponded = candidates.filter(
      (c) => !rejectedBy.includes(c.driverId),
    );
    await this.recordExpiredRound(unresponded, dispatchData, orderId, dispatchId);

    if (!stillOwner) {
      this.logger.warn(
        `Dispatch ${dispatchId} expired after another round claimed ${expiryScope}; not re-enqueuing`,
      );
      return;
    }

    this.logger.log(
      `Dispatch ${dispatchId} expired — retrying for order ${orderId} (attempt ${attempt + 1})`,
    );

    const settings = await this.platformSettings.getSettings();
    await this.dispatchRepository.saveDispatchState(
      expiryScope,
      { attempt: attempt + 1, excludeDriverIds },
      (settings.driverAcceptTimeoutSecs ?? 30) * 60,
    );

    await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
      orderId,
      orderNumber,
      attempt: attempt + 1,
      excludeDriverIds,
      deliveryGroupId: groupScope,
    });
  }

  // ─── Handle acceptance ────────────────────────────────────────────────────

  async handleAcceptance(
    dispatchId: string,
    driverId: string,
  ): Promise<boolean> {
    const validated = await this.validateAcceptanceRequest(dispatchId, driverId);
    if (!validated) return false;

    const { dispatchData, candidate, rejectedBy, order, totalDistanceKm } =
      validated;
    const nextStatus = this.resolveAcceptanceOrderStatus(order);
    const losingCandidates = (dispatchData.candidates || []).filter(
      (c) => c.driverId !== driverId && !rejectedBy.includes(c.driverId),
    );
    const vendorUserIds = await this.resolveVendorUserIds(order.id, order.vendorId);
    const acceptScope =
      candidate.deliveryGroupId ?? dispatchData.deliveryGroupId ?? order.id;

    const assignedRevision = await this.commitAcceptanceTransaction({
      dispatchId,
      dispatchData,
      candidate,
      driverId,
      order,
      nextStatus,
      totalDistanceKm,
      vendorUserIds,
      losingCandidates,
      acceptScope,
    });

    await this.cleanupAcceptanceRedis(
      dispatchId,
      acceptScope,
      dispatchData.candidates || [],
    );

    this.logger.log(
      `Driver ${driverId} accepted dispatch ${dispatchId} for order ${order.orderNumber}`,
    );

    for (const c of losingCandidates) {
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_CANCELLED,
        new OrderDispatchCancelledEvent(dispatchId, order.id, c.userId),
      );
    }

    await this.publishAcceptanceTransition({
      order,
      nextStatus,
      vendorUserIds,
      driverId,
      driverUserId: candidate.userId,
      assignedRevision,
    });

    return true;
  }

  // ─── Handle rejection ─────────────────────────────────────────────────────

  async handleRejection(dispatchId: string, driverId: string): Promise<void> {
    const dispatchData = await this.dispatchRepository.getBroadcast(dispatchId);
    if (!dispatchData) return;

    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      this.logger.warn(
        `Driver ${driverId} attempted to reject dispatch ${dispatchId} past expiresAt`,
      );
      return;
    }

    const orderId = dispatchData.orderId;
    const candidate = (dispatchData.candidates || []).find(
      (c) => c.driverId === driverId,
    );
    if (!candidate) return;

    const added = await this.dispatchRepository.markCandidateRejected(
      dispatchId,
      driverId,
    );
    if (added === 0) {
      const existing = await this.prisma.orderDispatch.findFirst({
        where: { orderId, driverId, status: DispatchStatus.REJECTED },
      });
      if (existing) return;
    }

    await this.dispatchRepository.removeDriverPending(driverId, dispatchId);

    const ttl = Math.max(
      1,
      Math.floor(
        (new Date(dispatchData.expiresAt).getTime() - Date.now()) / 1000,
      ) + 60,
    );
    await this.dispatchRepository.refreshRejectedSetTtl(dispatchId, ttl);

    await this.prisma.orderDispatch.create({
      data: {
        id: uuidv4(),
        orderId,
        driverId,
        driverShiftId: candidate.driverShiftId,
        deliveryGroupId: candidate.deliveryGroupId ?? null,
        type: dispatchData.type,
        distanceKm: candidate.distanceKm,
        estimatedEarnings: candidate.estimatedEarnings,
        status: DispatchStatus.REJECTED,
        expiresAt: new Date(dispatchData.expiresAt),
      },
    });

    if (candidate.driverShiftId) {
      await this.prisma.driverShift.update({
        where: { id: candidate.driverShiftId },
        data: { rejectedDispatches: { increment: 1 } },
      });
    }

    this.logger.log(
      `Driver ${driverId} rejected dispatch ${dispatchId} for order ${orderId}`,
    );

    const totalRejected =
      await this.dispatchRepository.getRejectedCount(dispatchId);
    if (totalRejected >= dispatchData.candidates.length) {
      await this.triggerEarlyRetryIfAllRejected(
        dispatchId,
        orderId,
        dispatchData,
        candidate.deliveryGroupId ?? dispatchData.deliveryGroupId ?? null,
      );
    }
  }

  // ─── Cancel active dispatch ───────────────────────────────────────────────

  async cancelActiveDispatch(orderId: string): Promise<void> {
    const [order, groups] = await Promise.all([
      this.prisma.order.findUnique({
        where: { id: orderId },
        select: { status: true, driverId: true },
      }),
      this.prisma.orderDeliveryGroup.findMany({
        where: { orderId },
        select: { id: true, primaryDriverId: true, status: true },
      }),
    ]);

    const isOrderTerminal =
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED;

    const scopes =
      isOrderTerminal || groups.length === 0
        ? [orderId, ...groups.map((g) => g.id)]
        : groups
            .filter(
              (g) =>
                g.primaryDriverId != null ||
                g.status === DeliveryGroupStatus.CANCELLED ||
                g.status === DeliveryGroupStatus.DELIVERED,
            )
            .map((g) => g.id);

    if (scopes.length === 0) return;

    const activeDispatchIds = (
      await Promise.all(
        scopes.map((scope) => this.dispatchRepository.getActiveClaim(scope)),
      )
    ).filter((id): id is string => Boolean(id));

    for (const id of activeDispatchIds) {
      await this.cancelDispatchById(id, orderId);
    }
  }

  // ─── Private lifecycle helpers ────────────────────────────────────────────

  private async isTargetTerminal(
    orderId: string,
    groupScope: string | null,
  ): Promise<boolean> {
    const orderRow = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (orderRow?.status === OrderStatus.CANCELLED) return true;

    if (!groupScope) return false;
    const groupRow = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: groupScope },
      select: { status: true },
    });
    return (
      groupRow?.status === DeliveryGroupStatus.CANCELLED ||
      groupRow?.status === DeliveryGroupStatus.DELIVERED
    );
  }

  private async cleanupTerminatedBroadcast(
    dispatchId: string,
    scope: string,
  ): Promise<void> {
    await this.dispatchRepository.deleteBroadcast(dispatchId);
    const owner = await this.dispatchRepository.releaseActiveClaim(
      scope,
      dispatchId,
    );
    if (owner) await this.dispatchRepository.deleteDispatchState(scope);
  }

  private async recordExpiredRound(
    unresponded: DispatchCandidateOffer[],
    dispatchData: DispatchBroadcastPayload,
    orderId: string,
    dispatchId: string,
  ): Promise<void> {
    if (unresponded.length === 0) return;

    await this.dispatchRepository.createTerminalRecords(this.prisma, {
      orderId,
      type: dispatchData.type,
      expiresAt: new Date(dispatchData.expiresAt),
      candidates: unresponded,
      status: DispatchStatus.EXPIRED,
    });

    const shiftIds = unresponded
      .map((c) => c.driverShiftId)
      .filter((id): id is string => id != null);
    if (shiftIds.length > 0) {
      await this.prisma.driverShift.updateMany({
        where: { id: { in: shiftIds } },
        data: { expiredDispatches: { increment: 1 } },
      });
    }

    for (const candidate of unresponded) {
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_CANCELLED,
        new OrderDispatchCancelledEvent(dispatchId, orderId, candidate.userId),
      );
      this.eventEmitter.emit(
        EVENTS.ORDER_DISPATCH_RESPONDED,
        new OrderDispatchRespondedEvent(
          dispatchId,
          orderId,
          candidate.driverId,
          DispatchStatus.EXPIRED,
        ),
      );
    }
  }

  private async validateAcceptanceRequest(dispatchId: string, driverId: string) {
    const dispatchData = await this.dispatchRepository.getBroadcast(dispatchId);
    if (!dispatchData) {
      this.logger.warn(
        `Driver ${driverId} attempted to accept expired dispatch ${dispatchId}`,
      );
      return null;
    }

    if (Date.now() > new Date(dispatchData.expiresAt).getTime()) {
      this.logger.warn(
        `Driver ${driverId} attempted to accept dispatch ${dispatchId} past expiresAt`,
      );
      return null;
    }

    const candidate = (dispatchData.candidates || []).find(
      (c) => c.driverId === driverId,
    );
    if (!candidate) {
      this.logger.warn(
        `Driver ${driverId} not found in dispatch ${dispatchId}`,
      );
      return null;
    }

    const rejectedBy =
      await this.dispatchRepository.getRejectedDriverIds(dispatchId);
    if (rejectedBy.includes(driverId)) {
      this.logger.warn(
        `Driver ${driverId} already rejected dispatch ${dispatchId} but tried to accept.`,
      );
      throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
    }

    const order = await this.prisma.order.findUnique({
      where: { id: dispatchData.orderId },
      include: {
        customer: { select: { userId: true } },
        vendor: { select: { members: { select: { userId: true } } } },
      },
    });

    const isGroupedAccept = Boolean(
      candidate.deliveryGroupId ?? dispatchData.deliveryGroupId,
    );
    if (
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED ||
      (!isGroupedAccept && !DISPATCHABLE_ORDER_STATUSES.includes(order.status))
    ) {
      return null;
    }

    const dispatchContext =
      await this.locationRepository.getOrderLocationContext(order.id);
    if (!dispatchContext) return null;

    const orderDistanceKm = await this.locationRepository.getDistanceKm(
      dispatchContext.lng,
      dispatchContext.lat,
      dispatchContext.deliveryLng,
      dispatchContext.deliveryLat,
    );

    return {
      dispatchData,
      candidate,
      rejectedBy,
      order,
      totalDistanceKm: Number(candidate.distanceKm) + orderDistanceKm,
    };
  }

  private resolveAcceptanceOrderStatus(order: {
    status: OrderStatus;
    paymentMethod: string;
    paymentStatus: string;
    upfrontAmount: unknown;
  }): OrderStatus {
    if (
      (order.paymentMethod === 'MOBILE_WALLET' ||
        Number(order.upfrontAmount ?? 0) > 0) &&
      order.paymentStatus !== 'COMPLETED'
    ) {
      return OrderStatus.PENDING_PAYMENT;
    }
    if (order.status === OrderStatus.READY_FOR_PICKUP) {
      return OrderStatus.READY_FOR_PICKUP;
    }
    if (order.status === OrderStatus.PREPARING) {
      return OrderStatus.PREPARING;
    }
    return OrderStatus.DRIVER_ASSIGNED;
  }

  private async resolveVendorUserIds(
    orderId: string,
    orderVendorId: string | null,
  ): Promise<string[]> {
    const vendorIds = orderVendorId
      ? [orderVendorId]
      : Array.from(
          new Set(
            (
              await this.prisma.orderVendorFulfillment.findMany({
                where: { orderId },
                select: { vendorId: true },
              })
            ).map((p) => p.vendorId),
          ),
        );
    if (vendorIds.length === 0) return [];
    const members = await this.prisma.vendorMember.findMany({
      where: { vendorId: { in: vendorIds } },
      select: { userId: true },
    });
    return members.map((m) => m.userId);
  }

  private async commitAcceptanceTransaction(params: {
    dispatchId: string;
    dispatchData: DispatchBroadcastPayload;
    candidate: DispatchCandidateOffer;
    driverId: string;
    order: {
      id: string;
      orderNumber: string;
      status: OrderStatus;
      customerId: string;
      vendorId: string | null;
      customer: { userId: string } | null;
    };
    nextStatus: OrderStatus;
    totalDistanceKm: number;
    vendorUserIds: string[];
    losingCandidates: DispatchCandidateOffer[];
    acceptScope: string;
  }): Promise<number> {
    const {
      dispatchId,
      dispatchData,
      candidate,
      driverId,
      order,
      nextStatus,
      totalDistanceKm,
      vendorUserIds,
      losingCandidates,
      acceptScope,
    } = params;

    let assignedRevision = 0;

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.$queryRaw`SELECT id FROM drivers WHERE id = ${driverId} FOR UPDATE`;

        const settings = await this.platformSettings.getSettings();
        const maxActive = settings.maxActiveOrdersPerDriver ?? 1;
        const activeCount = await this.driverWorkload.countActiveUnits(
          tx,
          driverId,
        );
        if (activeCount >= maxActive) {
          throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
        }
        const isStackedOrder = activeCount > 0;

        if (candidate.driverShiftId) {
          const shift = await tx.driverShift.findUnique({
            where: { id: candidate.driverShiftId },
            select: { status: true },
          });
          if (!shift || shift.status !== 'ACTIVE') {
            throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
          }
        }

        await tx.orderDispatch.create({
          data: {
            id: dispatchId,
            orderId: order.id,
            driverId,
            driverShiftId: candidate.driverShiftId,
            deliveryGroupId: candidate.deliveryGroupId ?? null,
            type: dispatchData.type,
            distanceKm: candidate.distanceKm,
            estimatedEarnings: candidate.estimatedEarnings,
            status: DispatchStatus.ACCEPTED,
            expiresAt: new Date(dispatchData.expiresAt),
          },
        });

        const groupId = candidate.deliveryGroupId ?? null;
        if (groupId) {
          const groupClaimed = await tx.orderDeliveryGroup.updateMany({
            where: {
              id: groupId,
              primaryDriverId: null,
              status: {
                notIn: [
                  DeliveryGroupStatus.CANCELLED,
                  DeliveryGroupStatus.DELIVERED,
                ],
              },
            },
            data: {
              primaryDriverId: driverId,
              primaryDriverShiftId: candidate.driverShiftId,
              isStacked: isStackedOrder,
              status:
                nextStatus === OrderStatus.PENDING_PAYMENT
                  ? DeliveryGroupStatus.PENDING_PAYMENT
                  : DeliveryGroupStatus.DRIVER_ASSIGNED,
              assignedByUserId: 'system',
              assignedAt: new Date(),
            },
          });
          if (groupClaimed.count === 0) {
            throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
          }

          await tx.order.updateMany({
            where: { id: order.id, driverId: null },
            data: {
              driverId,
              driverShiftId: candidate.driverShiftId,
              isStacked: isStackedOrder,
              driverAssignedAt: new Date(),
            },
          });

          const aggregateAdvanced = await tx.order.updateMany({
            where: {
              id: order.id,
              status: {
                in: [
                  OrderStatus.PENDING,
                  OrderStatus.ACCEPTED,
                  OrderStatus.LOOKING_FOR_DRIVER,
                ],
              },
            },
            data: { status: nextStatus, revision: { increment: 1 } },
          });

          await tx.orderStatusEvent.create({
            data: {
              orderId: order.id,
              status: nextStatus,
              note: `Driver assigned to a delivery. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
              createdBy: 'system',
            },
          });

          if (aggregateAdvanced.count > 0) {
            const revisionRow = await tx.order.findUnique({
              where: { id: order.id },
              select: { revision: true },
            });
            assignedRevision = revisionRow?.revision ?? 0;
          } else {
            const bumped = await tx.order.update({
              where: { id: order.id },
              data: { revision: { increment: 1 } },
              select: { revision: true },
            });
            assignedRevision = bumped.revision;
          }
        } else {
          const updated = await tx.order.updateMany({
            where: { id: order.id, status: { in: DISPATCHABLE_ORDER_STATUSES } },
            data: {
              driverId,
              driverShiftId: candidate.driverShiftId,
              isStacked: isStackedOrder,
              status: nextStatus,
              revision: { increment: 1 },
              driverAssignedAt: new Date(),
              distanceKm: totalDistanceKm,
            },
          });
          if (updated.count === 0) {
            throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
          }

          assignedRevision =
            (
              await tx.order.findUnique({
                where: { id: order.id },
                select: { revision: true },
              })
            )?.revision ?? 0;

          await tx.orderStatusEvent.create({
            data: {
              orderId: order.id,
              status: nextStatus,
              note: `Driver assigned. ${nextStatus === OrderStatus.PENDING_PAYMENT ? 'Awaiting mobile wallet payment.' : ''}`,
              createdBy: 'system',
            },
          });
        }

        await this.outbox.record(tx, {
          aggregateType: 'ORDER',
          aggregateId: order.id,
          version: assignedRevision,
          eventType: EVENTS.ORDER_STATUS_CHANGED,
          jobName: EVENT_JOBS.ORDER_STATUS_CHANGED,
          dedupeKey: `notify:order_status:${order.id}:${assignedRevision}`,
          payload: {
            orderId: order.id,
            orderNumber: order.orderNumber,
            oldStatus: order.status,
            newStatus: nextStatus,
            status: nextStatus,
            customerId: order.customerId,
            customerUserId: order.customer?.userId || order.customerId,
            vendorId: order.vendorId,
            vendorUserIds,
            driverId,
            driverUserId: candidate.userId,
            actorUserId: 'system',
            note: 'Driver found and auto-assigned.',
            revision: assignedRevision,
          },
        });

        const assignableStatuses: DriverStatus[] = [...DRIVER_ASSIGNABLE_STATUSES];
        if (maxActive > 1) {
          assignableStatuses.push(DriverStatus.ON_DELIVERY);
        }
        const flipped = await tx.driver.updateMany({
          where: { id: driverId, status: { in: assignableStatuses } },
          data: { status: DriverStatus.ON_DELIVERY },
        });
        if (flipped.count === 0) {
          throw new Error(OrderErrors.DRIVER_ALREADY_ON_ORDER);
        }

        await this.dispatchRepository.createTerminalRecords(tx, {
          orderId: order.id,
          type: dispatchData.type,
          expiresAt: new Date(dispatchData.expiresAt),
          candidates: losingCandidates,
          status: DispatchStatus.CANCELLED,
        });
      });
    } catch (err) {
      try {
        await this.dispatchRepository.releaseActiveClaim(acceptScope, dispatchId);
      } catch {
        // best-effort cleanup
      }
      if (
        err &&
        typeof err === 'object' &&
        (err as { code?: string }).code === 'P2002'
      ) {
        throw new Error(OrderErrors.ALREADY_ASSIGNED_OR_CANCELLED);
      }
      throw err;
    }

    return assignedRevision;
  }

  private async cleanupAcceptanceRedis(
    dispatchId: string,
    acceptScope: string,
    candidates: DispatchCandidateOffer[],
  ): Promise<void> {
    await this.dispatchRepository.deleteBroadcast(dispatchId);
    const stillOwner = await this.dispatchRepository.releaseActiveClaim(
      acceptScope,
      dispatchId,
    );
    if (stillOwner) {
      await this.dispatchRepository.deleteDispatchState(acceptScope);
    } else {
      this.logger.warn(
        `Dispatch ${dispatchId} accepted but a newer round now owns ${acceptScope}; leaving its claim intact`,
      );
    }

    await this.dispatchRepository.deleteRejectedSet(dispatchId);
    await this.dispatchRepository.removeDispatchForCandidates(
      candidates,
      dispatchId,
    );
  }

  private async publishAcceptanceTransition(params: {
    order: {
      id: string;
      orderNumber: string;
      status: OrderStatus;
      customerId: string;
      vendorId: string | null;
      customer: { userId: string } | null;
    };
    nextStatus: OrderStatus;
    vendorUserIds: string[];
    driverId: string;
    driverUserId: string;
    assignedRevision: number;
  }): Promise<void> {
    const {
      order,
      nextStatus,
      vendorUserIds,
      driverId,
      driverUserId,
      assignedRevision,
    } = params;

    const statusEvent = new OrderStatusChangedEvent(
      order.id,
      order.orderNumber,
      order.status,
      nextStatus,
      order.customerId,
      order.customer?.userId || order.customerId,
      order.vendorId,
      vendorUserIds,
      driverId,
      driverUserId,
      'system',
      'Driver found and auto-assigned.',
      assignedRevision,
    );

    try {
      await Promise.all([
        this.eventsQueue.add(EVENT_JOBS.ORDER_STATUS_CHANGED, statusEvent, {
          attempts: 3,
          backoff: { type: 'exponential', delay: 2_000 },
        }),
        this.workflowDispatcher.onOrderStatusChanged(statusEvent),
      ]);
      await this.outbox.markProcessed('ORDER', order.id, assignedRevision);
    } catch (error: unknown) {
      // Non-fatal: the Outbox row remains unprocessed so OutboxService relays it.
      this.logger.error(
        `Failed post-accept event/workflow publish for ${order.id}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private async triggerEarlyRetryIfAllRejected(
    dispatchId: string,
    orderId: string,
    dispatchData: DispatchBroadcastPayload,
    groupScope: string | null,
  ): Promise<void> {
    const rejectedList =
      await this.dispatchRepository.getRejectedDriverIds(dispatchId);

    await this.dispatchRepository.deleteBroadcast(dispatchId);
    const rejectScope = groupScope ?? orderId;
    const stillOwner = await this.dispatchRepository.releaseActiveClaim(
      rejectScope,
      dispatchId,
    );
    await this.dispatchRepository.deleteRejectedSet(dispatchId);
    await this.dispatchRepository.removeDispatchForCandidates(
      dispatchData.candidates || [],
      dispatchId,
    );

    const expiryJob = await this.dispatchQueue.getJob(
      `dispatch-expire-${dispatchId}`,
    );

    if (expiryJob) {
      await expiryJob.remove();
      if (!stillOwner) {
        this.logger.warn(
          `Dispatch ${dispatchId} rejected after another round claimed ${rejectScope}; not re-enqueuing`,
        );
        return;
      }

      const settings = await this.platformSettings.getSettings();
      await this.dispatchRepository.saveDispatchState(
        rejectScope,
        {
          attempt: expiryJob.data.attempt + 1,
          excludeDriverIds: expiryJob.data.excludeDriverIds,
        },
        (settings.driverAcceptTimeoutSecs ?? 30) * 60,
      );

      await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
        orderId,
        orderNumber: expiryJob.data.orderNumber,
        attempt: expiryJob.data.attempt + 1,
        excludeDriverIds: expiryJob.data.excludeDriverIds,
        deliveryGroupId: groupScope,
      });
      return;
    }

    if (!stillOwner) {
      this.logger.warn(
        `Dispatch ${dispatchId} rejected after another round claimed ${rejectScope}; not re-enqueuing`,
      );
      return;
    }

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) return;

    const state = await this.dispatchRepository.readDispatchState(rejectScope);
    await this.dispatchQueue.add(ORDER_JOBS.DISPATCH, {
      orderId,
      orderNumber: order.orderNumber,
      attempt: state.attempt + 1,
      excludeDriverIds: Array.from(
        new Set([...state.excludeDriverIds, ...rejectedList]),
      ),
      deliveryGroupId: groupScope,
    });
  }

  private async cancelDispatchById(
    dispatchId: string,
    orderId: string,
  ): Promise<void> {
    const dispatchData = await this.dispatchRepository.getBroadcast(dispatchId);
    if (!dispatchData) return;

    const scope = dispatchData.deliveryGroupId ?? orderId;
    await this.dispatchRepository.deleteBroadcast(dispatchId);

    const stillOwner = await this.dispatchRepository.releaseActiveClaim(
      scope,
      dispatchId,
    );
    if (stillOwner) {
      await this.dispatchRepository.deleteDispatchState(scope);
    } else {
      this.logger.warn(
        `Dispatch ${dispatchId} cancelled but ${scope} now owned by another round`,
      );
    }

    const rejectedBy =
      await this.dispatchRepository.getRejectedDriverIds(dispatchId);
    await this.dispatchRepository.deleteRejectedSet(dispatchId);
    await this.dispatchRepository.removeDispatchForCandidates(
      dispatchData.candidates || [],
      dispatchId,
    );

    const unresponded = (dispatchData.candidates || []).filter(
      (c) => !rejectedBy.includes(c.driverId),
    );
    if (unresponded.length > 0) {
      await this.dispatchRepository.createTerminalRecords(this.prisma, {
        orderId,
        type: dispatchData.type,
        expiresAt: new Date(dispatchData.expiresAt),
        candidates: unresponded,
        status: DispatchStatus.CANCELLED,
      });

      for (const candidate of unresponded) {
        this.eventEmitter.emit(
          EVENTS.ORDER_DISPATCH_CANCELLED,
          new OrderDispatchCancelledEvent(dispatchId, orderId, candidate.userId),
        );
      }
    }

    this.logger.log(
      `Active dispatch ${dispatchId} cancelled for order ${orderId}`,
    );
  }
}
