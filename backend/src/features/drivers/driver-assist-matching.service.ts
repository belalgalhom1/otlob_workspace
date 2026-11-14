import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  DeliveryGroupStatus,
  DriverAssistRequestStatus,
  DriverShiftStatus,
  DriverStatus,
  Prisma,
} from '@prisma/client';
import { DriverErrors } from '../../common/constants/response.constants';
import { DriverAssistOfferedEvent } from '../../common/events';
import { EVENTS } from '../../common/events/event-names';
import { haversineKm } from '../../common/geo/geo.utils';
import type { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { LocationRepository } from '../location/location.repository';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

@Injectable()
export class DriverAssistMatchingService {
  private readonly logger = new Logger(DriverAssistMatchingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly platformSettings: PlatformSettingsService,
    private readonly locationRepository: LocationRepository,
    private readonly redis: RedisService,
  ) {}

  async findBestCandidate(request: {
    deliveryGroupId: string;
    orderId: string;
  }): Promise<string> {
    const nearest = await this.findNearestEligibleAssistDrivers(request, 1);
    if (nearest.length === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    return nearest[0];
  }

  async offerAssistToNearest(
    requestId: string,
    actor: JwtAccessPayload,
    limit = 5,
  ) {
    const request = await this.prisma.driverAssistRequest.findUnique({
      where: { id: requestId },
      select: {
        id: true,
        status: true,
        orderId: true,
        deliveryGroupId: true,
        reason: true,
        order: { select: { orderNumber: true } },
        deliveryGroup: { select: { deliveryFee: true, assistFee: true } },
      },
    });
    if (!request) {
      throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }
    if (
      request.status !== DriverAssistRequestStatus.APPROVED &&
      request.status !== DriverAssistRequestStatus.PENDING
    ) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }
    if (request.status === DriverAssistRequestStatus.PENDING) {
      await this.prisma.driverAssistRequest.update({
        where: { id: requestId },
        data: {
          status: DriverAssistRequestStatus.APPROVED,
          reviewedByUserId: actor.sub,
          reviewedAt: new Date(),
        },
      });
    }

    const driverIds = await this.findNearestEligibleAssistDrivers(request, limit);
    if (driverIds.length === 0) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }

    const orderNumber = request.order?.orderNumber ?? '';
    const proposedAssistFee = Number(
      request.deliveryGroup?.assistFee ?? request.deliveryGroup?.deliveryFee ?? 0,
    );

    const ttlSecs = 15;
    const expiresAt = new Date(Date.now() + ttlSecs * 1000);
    const offerKey = `assist:offer:${requestId}`;
    await this.redis.set(
      offerKey,
      JSON.stringify({
        driverIds,
        orderId: request.orderId,
        orderNumber,
        deliveryGroupId: request.deliveryGroupId ?? null,
        reason: request.reason ?? '',
        proposedAssistFee,
        expiresAt: expiresAt.toISOString(),
      }),
      ttlSecs,
    );

    const drivers = await this.prisma.driver.findMany({
      where: { id: { in: driverIds } },
      select: { userId: true },
    });
    const targetUserIds = drivers
      .map((d) => d.userId)
      .filter((id): id is string => Boolean(id));

    if (targetUserIds.length > 0) {
      this.eventEmitter.emit(
        EVENTS.DRIVER_ASSIST_OFFERED,
        new DriverAssistOfferedEvent(
          requestId,
          request.orderId,
          targetUserIds,
          expiresAt.toISOString(),
          orderNumber,
          request.reason ?? '',
          proposedAssistFee,
          request.deliveryGroupId ?? null,
        ),
      );
    }

    return { offered: driverIds, expiresAt: expiresAt.toISOString() };
  }

  /**
   * Driver responds to an assist offer. On decline, updates the Redis offer
   * set and returns `{ declined: true }`; on accept, returns `{ acceptedDriverId }`
   * for `DriverAssistService` to complete CAS assignment.
   */
  async respondToAssistOffer(
    actor: JwtAccessPayload,
    requestId: string,
    accept: boolean,
  ): Promise<{ declined: true } | { acceptedDriverId: string }> {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const request = await this.prisma.driverAssistRequest.findUnique({
      where: { id: requestId },
      select: { id: true, status: true },
    });
    if (!request) {
      throw new NotFoundException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }
    if (request.status !== DriverAssistRequestStatus.APPROVED) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_PENDING);
    }

    const offerKey = `assist:offer:${requestId}`;
    const raw = await this.redis.get(offerKey);
    if (!raw) throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    const offer = JSON.parse(raw) as { driverIds: string[]; expiresAt: string };
    if (!offer.driverIds.includes(driver.id)) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }
    if (Date.now() > new Date(offer.expiresAt).getTime()) {
      throw new BadRequestException(DriverErrors.ASSIST_REQUEST_NOT_FOUND);
    }

    if (!accept) {
      const remaining = offer.driverIds.filter((id) => id !== driver.id);
      if (remaining.length === 0) {
        await this.redis.del(offerKey);
      } else {
        await this.redis.set(
          offerKey,
          JSON.stringify({ ...offer, driverIds: remaining }),
          15,
        );
      }
      return { declined: true };
    }

    return { acceptedDriverId: driver.id };
  }

  async getPendingAssistOffers(actor: JwtAccessPayload) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);

    const keys = await this.redis.scanKeys('assist:offer:*');
    const offers: Array<{
      id: string;
      requestId: string;
      orderId: string;
      orderNumber: string;
      deliveryGroupId: string | null;
      reason: string;
      proposedAssistFee: number;
      expiresAt: string;
      order: { id: string; orderNumber: string };
    }> = [];
    const needsHydration: string[] = [];

    for (const key of keys) {
      const raw = await this.redis.get(key);
      if (!raw) continue;
      try {
        const offer = JSON.parse(raw) as {
          driverIds?: string[];
          orderId: string;
          orderNumber?: string;
          deliveryGroupId?: string | null;
          reason?: string;
          proposedAssistFee?: number;
          expiresAt: string;
        };
        if (!offer.driverIds?.includes(driver.id)) continue;
        if (Date.now() > new Date(offer.expiresAt).getTime()) continue;
        const requestId = key.replace('assist:offer:', '');
        if (
          offer.orderNumber === undefined ||
          offer.proposedAssistFee === undefined
        ) {
          needsHydration.push(requestId);
        }
        const orderNumber = offer.orderNumber ?? '';
        offers.push({
          id: requestId,
          requestId,
          orderId: offer.orderId,
          orderNumber,
          deliveryGroupId: offer.deliveryGroupId ?? null,
          reason: offer.reason ?? '',
          proposedAssistFee: Number(offer.proposedAssistFee ?? 0),
          expiresAt: offer.expiresAt,
          order: { id: offer.orderId, orderNumber },
        });
      } catch {
        // ignore malformed offer
      }
    }

    if (
      needsHydration.length > 0 &&
      typeof this.prisma.driverAssistRequest?.findMany === 'function'
    ) {
      const dbRows = await this.prisma.driverAssistRequest.findMany({
        where: { id: { in: needsHydration } },
        select: {
          id: true,
          deliveryGroupId: true,
          reason: true,
          order: { select: { orderNumber: true } },
          deliveryGroup: { select: { deliveryFee: true, assistFee: true } },
        },
      });
      const byId = new Map(dbRows.map((r) => [r.id, r]));
      for (const offer of offers) {
        const row = byId.get(offer.requestId);
        if (!row) continue;
        const orderNumber = row.order?.orderNumber ?? offer.orderNumber;
        offer.orderNumber = orderNumber;
        offer.order = { id: offer.orderId, orderNumber };
        offer.deliveryGroupId = row.deliveryGroupId ?? offer.deliveryGroupId;
        offer.reason = row.reason ?? offer.reason;
        offer.proposedAssistFee = Number(
          row.deliveryGroup?.assistFee ?? row.deliveryGroup?.deliveryFee ?? 0,
        );
      }
    }

    return offers;
  }

  async clearOffer(requestId: string): Promise<void> {
    try {
      await this.redis.del(`assist:offer:${requestId}`);
    } catch (error) {
      this.logWarn(error);
    }
  }

  private async resolveAssistTargetLocation(request: {
    deliveryGroupId: string;
    orderId: string;
  }): Promise<{ primaryDriverId: string | null; lng: number; lat: number }> {
    const group = await this.prisma.orderDeliveryGroup.findUnique({
      where: { id: request.deliveryGroupId },
      select: { primaryDriverId: true },
    });
    const primaryDriverId = group?.primaryDriverId ?? null;
    let targetLng: number | null = null;
    let targetLat: number | null = null;

    if (group?.primaryDriverId) {
      const loc = await this.fetchDriverLocations([group.primaryDriverId]).then(
        (m) => m.get(group.primaryDriverId!),
      );
      if (loc) {
        targetLng = loc.lng;
        targetLat = loc.lat;
      }
    }
    if (targetLng == null) {
      const pickup =
        await this.locationRepository.getDeliveryGroupPickupLocation(
          request.deliveryGroupId,
        );
      if (pickup) {
        targetLng = pickup.lng;
        targetLat = pickup.lat;
      }
    }
    if (targetLng == null) {
      const ctx = await this.locationRepository.getOrderLocationContext(
        request.orderId,
      );
      if (ctx) {
        targetLng = ctx.lng;
        targetLat = ctx.lat;
      }
    }

    if (targetLng == null || targetLat == null) {
      throw new BadRequestException(DriverErrors.ASSIST_DRIVER_NOT_ELIGIBLE);
    }
    return { primaryDriverId, lng: targetLng, lat: targetLat };
  }

  private async findNearestEligibleAssistDrivers(
    request: { deliveryGroupId: string; orderId: string },
    limit: number,
  ): Promise<string[]> {
    const { primaryDriverId, lng, lat } =
      await this.resolveAssistTargetLocation(request);
    const settings = await this.platformSettings.getSettings();

    const candidates = await this.prisma.driver.findMany({
      where: {
        status: { in: [DriverStatus.ONLINE, DriverStatus.BUSY] },
        isApproved: true,
        deletedAt: null,
        hasUnpaidCommission: false,
        NOT: { id: primaryDriverId ?? undefined },
      },
      select: { id: true },
    });

    const busyGroupDrivers = await this.prisma.orderDeliveryGroup.findMany({
      where: {
        id: { not: request.deliveryGroupId },
        OR: [
          { primaryDriverId: { not: null } },
          { assistDriverId: { not: null } },
        ],
        status: {
          notIn: [DeliveryGroupStatus.DELIVERED, DeliveryGroupStatus.CANCELLED],
        },
      },
      select: { primaryDriverId: true, assistDriverId: true },
    });
    const busyIds = new Set<string>();
    for (const g of busyGroupDrivers) {
      if (g.primaryDriverId) busyIds.add(g.primaryDriverId);
      if (g.assistDriverId) busyIds.add(g.assistDriverId);
    }

    const locations = await this.fetchDriverLocations(
      candidates.map((c) => c.id),
    );
    const eligible: { id: string; distance: number }[] = [];
    for (const c of candidates) {
      if (busyIds.has(c.id)) continue;
      const ll = locations.get(c.id);
      if (!ll) continue;
      const dist = haversineKm({ lng: ll.lng, lat: ll.lat }, { lng, lat });
      if (settings.driverShiftsEnabled) {
        const shift = await this.prisma.driverShift.findFirst({
          where: { driverId: c.id, status: DriverShiftStatus.ACTIVE },
          select: { id: true },
        });
        if (!shift) continue;
      }
      eligible.push({ id: c.id, distance: dist });
    }
    eligible.sort((a, b) => a.distance - b.distance);
    return eligible.slice(0, limit).map((e) => e.id);
  }

  private async fetchDriverLocations(
    driverIds: string[],
  ): Promise<Map<string, { lng: number; lat: number }>> {
    const map = new Map<string, { lng: number; lat: number }>();
    if (driverIds.length === 0) return map;
    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; lng: number; lat: number }>
    >`
      SELECT id, ST_X("lastLocation"::geometry) AS lng, ST_Y("lastLocation"::geometry) AS lat
      FROM drivers WHERE id IN (${Prisma.join(driverIds)})`;
    for (const r of rows) {
      if (r.lng != null && r.lat != null) {
        map.set(r.id, { lng: Number(r.lng), lat: Number(r.lat) });
      }
    }
    return map;
  }

  private logWarn(error: unknown) {
    this.logger.warn(
      `Assist matching side-effect failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}
