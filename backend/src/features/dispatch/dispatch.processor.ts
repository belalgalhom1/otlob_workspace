import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Job, Queue, UnrecoverableError } from 'bullmq';
import { Inject, Logger, OnModuleInit } from '@nestjs/common';
import { DispatchService } from './dispatch.service';
import { DispatchRepository } from './dispatch.repository';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { DriverGeoSearchService } from '../location/driver-geo-search.service';
import {
  QUEUES,
  ORDER_JOBS,
  CRON_JOBS,
} from '../../infrastructure/queue/queues.constants';
import { DeliveryGroupStatus, OrderStatus } from '@prisma/client';
import { DISPATCH_ORDER_WORKFLOW_PORT } from '../../common/orders/order-dispatch.ports';
import type { DispatchOrderWorkflowPort } from '../../common/orders/order-dispatch.ports';
import { OrderWorkflowDispatcher } from '../../common/orders/order-workflow.dispatcher';
import { mvDebugTrace } from '../../common/orders/mv-debug-trace.logger';

// Dispatch broadcasts already fan out to dozens of drivers per job; running 50
// of them concurrently just queues more DB/Redis waits behind the shared pool.
// 10 aligns with the worker's default Prisma pool (DB_POOL_SIZE=10).
@Processor(QUEUES.DISPATCH, { concurrency: 10 })
export class DispatchProcessor extends WorkerHost implements OnModuleInit {
  private readonly logger = new Logger(DispatchProcessor.name);

  constructor(
    private readonly dispatchService: DispatchService,
    private readonly dispatchRepository: DispatchRepository,
    @Inject(DISPATCH_ORDER_WORKFLOW_PORT)
    private readonly orderWorkflowPort: DispatchOrderWorkflowPort,
    private readonly workflowDispatcher: OrderWorkflowDispatcher,
    private readonly platformSettings: PlatformSettingsService,
    private readonly prisma: PrismaService,
    private readonly driverGeoSearch: DriverGeoSearchService,
    @InjectQueue(QUEUES.DISPATCH) private readonly queue: Queue,
  ) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Scheduling geo freshness sweep cron...');
    await this.queue.add(
      CRON_JOBS.GEO_FRESHNESS_SWEEP,
      {},
      {
        repeat: { pattern: '*/5 * * * *' },
        jobId: CRON_JOBS.GEO_FRESHNESS_SWEEP,
      },
    );
  }

  async process(job: Job<any, any, string>): Promise<any> {
    this.logger.debug(`Processing dispatch job ${job.name} (id: ${job.id})`);

    switch (job.name) {
      case ORDER_JOBS.DISPATCH_HANDOFF:
        return this.handleDispatchHandoff(job.data);
      case ORDER_JOBS.CANCEL_ACTIVE_DISPATCH:
        return this.handleCancelActiveDispatch(job.data);
      case ORDER_JOBS.DISPATCH_REJECTION:
        return this.handleDispatchRejection(job.data);
      case ORDER_JOBS.DISPATCH_CLEANUP_EXPIRY:
        return this.handleDispatchCleanupExpiry(job.data);
      case ORDER_JOBS.DISPATCH:
        return this.handleDispatch(job);
      case ORDER_JOBS.DISPATCH_EXPIRE:
        return this.handleDispatchExpire(job);
      case CRON_JOBS.GEO_FRESHNESS_SWEEP:
        return this.handleGeoFreshnessSweep();
      default:
        this.logger.warn(`Unknown job name: ${job.name}`);
        return { ignored: true, reason: 'unknown_job_name' };
    }
  }

  // ─── Find nearest driver and dispatch ────────────────────────────────────

  private async handleDispatch(
    job: Job<{
      orderId: string;
      orderNumber: string;
      attempt: number;
      excludeDriverIds?: string[];
      deliveryGroupId?: string | null;
    }>,
  ) {
    const {
      orderId,
      orderNumber,
      attempt,
      excludeDriverIds = [],
      deliveryGroupId = null,
    } = job.data;

    // Read fresh status each time — never use a snapshot before a write
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, status: true },
    });

    if (!order) {
      throw new UnrecoverableError(`Order ${orderNumber} not found`);
    }

    // Valid entry states for dispatch (order can be dispatched while vendor prepares food)
    const dispatchableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.LOOKING_FOR_DRIVER,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];

    // A grouped delivery is gated by its own DeliveryGroup status inside
    // attemptDispatch, so the order-level gate only applies to legacy
    // single-vendor orders (which have no group).
    if (!deliveryGroupId && !dispatchableStatuses.includes(order.status)) {
      this.logger.warn(
        `Dispatch skipped for ${orderNumber}: status is ${order.status}`,
      );
      return { skipped: true, status: order.status };
    }

    // Transition to LOOKING_FOR_DRIVER if still in initial ACCEPTED state.
    // Grouped deliveries move the ORDER here once, before per-group dispatch.
    if (!deliveryGroupId && order.status === OrderStatus.ACCEPTED) {
      await this.orderWorkflowPort.transitionAcceptedOrderToSearching(orderId);
    }

    const settings = await this.platformSettings.getSettings();
    const maxAttempts = settings.driverSearchMaxAttempts ?? 5;

    if (attempt > maxAttempts) {
      if (deliveryGroupId) {
        this.logger.error(
          `Delivery group ${deliveryGroupId} on order ${orderNumber} exhausted ${maxAttempts} dispatch attempts — no drivers accepted`,
        );
        const result =
          await this.orderWorkflowPort.handleUndispatchableDeliveryGroup(
            orderId,
            deliveryGroupId,
            'Auto-cancelled: No drivers accepted this delivery after maximum attempts',
          );
        return {
          noDriversFound: true,
          attempts: attempt,
          groupCancelled: result.groupCancelled,
          autoCancelled: result.orderCancelled,
        };
      }

      this.logger.error(
        `Order ${orderNumber} exhausted ${maxAttempts} dispatch attempts — no drivers accepted`,
      );

      await this.workflowDispatcher.enqueueCancelOrder(
        orderId,
        'Auto-cancelled: No drivers accepted the order after maximum attempts',
      );

      return { noDriversFound: true, attempts: attempt, autoCancelled: true };
    }

    let outcome: Awaited<ReturnType<DispatchService['attemptDispatch']>>;
    try {
      outcome = await this.dispatchService.attemptDispatch({
        orderId,
        orderNumber,
        attempt,
        excludeDriverIds,
        deliveryGroupId,
      });
    } catch (err: any) {
      this.logger.error(
        `CRITICAL DISPATCH ERROR for ${orderNumber}: ${err.message}`,
        err.stack,
      );
      throw err; // Re-throw for BullMQ retry
    }

    if (outcome === 'invalid') {
      this.logger.warn(
        `Dispatch invalid for ${orderNumber} (attempt ${attempt})`,
      );

      if (deliveryGroupId) {
        const result =
          await this.orderWorkflowPort.handleUndispatchableDeliveryGroup(
            orderId,
            deliveryGroupId,
            'Auto-cancelled: no delivery could be dispatched',
          );
        if (result.groupCancelled) {
          this.logger.error(
            `Delivery group ${deliveryGroupId} on order ${orderNumber} is undispatchable — cancelled`,
          );
        }
      }

      return { invalid: true, attempt };
    }

    if (outcome === 'in_flight') {
      this.logger.warn(
        `Dispatch already in flight for ${orderNumber} (attempt ${attempt})`,
      );
      // Another dispatch round is active for this order — do NOT schedule a
      // duplicate broadcast. The active round's expiry watchdog resumes the
      // attempt cycle.
      return { inFlight: true, attempt };
    }

    if (outcome === 'no_drivers') {
      this.logger.warn(
        `No drivers available for ${orderNumber} (attempt ${attempt})`,
      );

      // Enqueue next attempt manually to ensure 'attempt' increments, triggering dynamic radius expansion
      await this.queue.add(
        ORDER_JOBS.DISPATCH,
        {
          orderId,
          orderNumber,
          attempt: attempt + 1,
          excludeDriverIds,
          ...(deliveryGroupId ? { deliveryGroupId } : {}),
        },
        { delay: (settings.driverAcceptTimeoutSecs ?? 30) * 1000 },
      );

      return { noDriversFound: true, retryingNextAttempt: true };
    }

    return { dispatched: true, attempt };
  }

  // ─── Expire a pending dispatch and re-try ─────────────────────────────────

  private async handleDispatchExpire(job: Job) {
    // We delegate the expiry logic to the DispatchService since it requires Redis
    await this.dispatchService.handleExpiry(job.data);
    return { success: true, processedExpiry: true };
  }

  // ─── Workflow orchestration handlers ─────────────────────────────────────

  private async handleDispatchHandoff(data: {
    orderId: string;
    orderNumber: string;
  }) {
    const groups = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        orderId: data.orderId,
        primaryDriverId: null,
        status: {
          notIn: [
            DeliveryGroupStatus.CANCELLED,
            DeliveryGroupStatus.DELIVERED,
          ],
        },
      },
      select: { id: true },
      orderBy: { sequence: 'asc' },
    });

    if (groups.length === 0) {
      return { enqueued: 0, groups: 0 };
    }

    const jobPayloads = groups.map((group) => ({
      orderId: data.orderId,
      orderNumber: data.orderNumber,
      attempt: 1,
      deliveryGroupId: group.id,
    }));

    const configuredHandoffTtl = Number(
      (await this.platformSettings.getSettings().catch(() => null))
        ?.dispatchHandoffDedupeTtlSecs ?? 300,
    );
    const handoffTtl =
      Number.isFinite(configuredHandoffTtl) && configuredHandoffTtl > 0
        ? configuredHandoffTtl
        : 300;

    let enqueued = 0;
    for (const payload of jobPayloads) {
      const scope = payload.deliveryGroupId ?? payload.orderId;
      if (await this.dispatchRepository.isHandoffDeduped(data.orderId, scope)) {
        continue;
      }

      await this.queue.add(ORDER_JOBS.DISPATCH, payload, {
        delay: 500,
        attempts: 5,
        backoff: { type: 'fixed', delay: 60_000 },
      });

      await this.dispatchRepository.markHandoffDeduped(
        data.orderId,
        scope,
        handoffTtl,
      );
      enqueued++;
    }

    mvDebugTrace(
      'STEP_5_DISPATCH_HANDOFF_ENQUEUED',
      `Enqueued ${enqueued}/${groups.length} delivery group dispatch job(s) for ${data.orderNumber}`,
      {
        orderId: data.orderId,
        orderNumber: data.orderNumber,
        enqueued,
        groupIds: groups.map((g) => g.id),
      },
    );

    return { enqueued, groups: groups.length };
  }

  private async handleCancelActiveDispatch(data: { orderId: string }) {
    this.logger.debug(`Cancelling active dispatch for order ${data.orderId}`);
    await this.dispatchService.cancelActiveDispatch(data.orderId);
    return { cancelled: true, orderId: data.orderId };
  }

  private async handleDispatchRejection(data: {
    dispatchId: string;
    driverId: string;
  }) {
    await this.dispatchService.handleRejection(data.dispatchId, data.driverId);
    return { rejected: true, dispatchId: data.dispatchId };
  }

  private async handleDispatchCleanupExpiry(data: { dispatchId: string }) {
    const expiryJob = await this.queue.getJob(
      `dispatch-expire-${data.dispatchId}`,
    );
    if (expiryJob) await expiryJob.remove();
    return { cleaned: Boolean(expiryJob), dispatchId: data.dispatchId };
  }

  // ─── Global geo-pool hygiene ──────────────────────────────────────────────

  private async handleGeoFreshnessSweep() {
    const started = Date.now();
    const result = await this.driverGeoSearch.sweepStaleDriverLocations();
    this.logger.log(
      `Geo freshness sweep done in ${Date.now() - started}ms (scanned ${result.scanned}, pruned ${result.removed})`,
    );
    return result;
  }
}
