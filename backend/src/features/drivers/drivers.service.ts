import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DriversRepository } from './drivers.repository';
import { StorageService } from '../../infrastructure/storage/storage.service';
import {
  RegisterDriverDto,
  UpdateDriverProfileDto,
  UpdateDriverStatusDto,
  QueryDriverWalletDto,
} from './dto/driver.dto';
import { DriverStatusChangedEvent } from 'src/common/events';
import { EVENTS } from 'src/common/events/event-names';
import { DriverErrors } from 'src/common/constants/response.constants';
import { DriverStatus, Role } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { requireDriverByUserId } from './driver-lookup.helper';

@Injectable()
export class DriversService {
  private readonly logger = new Logger(DriversService.name);

  constructor(
    private readonly driversRepository: DriversRepository,
    private readonly storage: StorageService,
    private readonly eventEmitter: EventEmitter2,
    private readonly prisma: PrismaService,
  ) {}

  // ─── Register ─────────────────────────────────────────────────────────────

  async register(userId: string, dto: RegisterDriverDto) {
    const existing = await this.driversRepository.findByUserId(userId);
    if (existing) throw new ConflictException(DriverErrors.PROFILE_EXISTS);

    // Upgrade user role to DRIVER
    await this.driversRepository.updateUserRole(userId, Role.DRIVER);

    const driver = await this.driversRepository.create({
      userId,
      name: dto.name,
      nationalId: dto.nationalId ?? null,
      licenseNumber: dto.licenseNumber ?? null,
      vehicleType: dto.vehicleType ?? 'MOTORCYCLE',
      vehiclePlate: dto.vehiclePlate ?? null,
    });

    this.logger.log(`Driver registered: ${driver.id} for user ${userId}`);
    return driver;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  async getMyProfile(userId: string) {
    const driver = await this.driversRepository.findByUserIdWithUser(userId);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return driver;
  }

  /**
   * Vendors near the driver, with their active in-flight orders and real-time
   * order density in the current time window so drivers know which stores
   * are busiest right now. Only the closest branch per vendor is returned,
   * sorted by active orders descending and distance ascending.
   */
  async getNearbyVendors(
    userId: string,
    lat: number,
    lng: number,
    radiusKm = 5,
    hours = 3,
    days?: number,
  ) {
    await this.assertDriver(userId);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new BadRequestException(DriverErrors.INVALID_LOCATION);
    }

    const safeRadius = Math.min(Math.max(Number(radiusKm) || 5, 0.5), 50);
    const safeHours = Math.min(Math.max(Number(hours) || 3, 1), 72);
    const safeDays =
      days != null ? Math.min(Math.max(Math.round(Number(days)), 1), 90) : null;
    const cutoffMs =
      safeDays != null ? safeDays * 86400000 : safeHours * 3600000;
    const cutoffDate = new Date(Date.now() - cutoffMs);

    type NearbyVendorRow = {
      vendorId: string;
      storeName: string;
      storeNameAr: string | null;
      logo: string | null;
      rating: number | null;
      vendorStatus: string;
      branchName: string | null;
      branchNameAr: string | null;
      branchAddress: string | null;
      branchIsOpen: boolean | null;
      lat: number;
      lng: number;
      distanceKm: number;
      orderCount: number;
      activeOrderCount: number;
    };

    const rows = await this.prisma.$queryRaw<NearbyVendorRow[]>`
      WITH current_orders AS (
        SELECT
          f."vendorId" AS vendor_id,
          f."orderId" AS order_id,
          CASE
            WHEN f.status::text IN (
              'PENDING', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP',
              'PARTIALLY_PICKED_UP'
            ) THEN 1
            ELSE 0
          END AS is_active
        FROM order_vendor_fulfillments f
        JOIN orders o ON o.id = f."orderId"
        WHERE o."deletedAt" IS NULL
          AND o.status::text <> 'CANCELLED'
          AND f.status::text NOT IN ('REJECTED', 'CANCELLED')
          AND (
            f.status::text IN (
              'PENDING', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP',
              'PARTIALLY_PICKED_UP'
            )
            OR f."createdAt" >= ${cutoffDate}
          )
      ),
      order_counts AS (
        SELECT
          vendor_id,
          COUNT(DISTINCT order_id)::int AS order_count,
          COUNT(DISTINCT CASE WHEN is_active = 1 THEN order_id END)::int AS active_order_count
        FROM current_orders
        GROUP BY vendor_id
      ),
      nearest_branch AS (
        SELECT
          vb.id,
          vb."vendorId" AS vendor_id,
          vb.name AS branch_name,
          vb."nameAr" AS branch_name_ar,
          vb.address AS branch_address,
          vb."isOpen" AS branch_is_open,
          ST_Y(vb.location::geometry) AS lat,
          ST_X(vb.location::geometry) AS lng,
          ST_Distance(
            vb.location::geography,
            ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
          ) / 1000.0 AS distance_km,
          ROW_NUMBER() OVER (
            PARTITION BY vb."vendorId"
            ORDER BY ST_Distance(
              vb.location::geography,
              ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
            ) ASC
          ) AS rank
        FROM vendor_branches vb
        JOIN vendors v ON v.id = vb."vendorId"
        WHERE v."deletedAt" IS NULL
      )
      SELECT
        v.id AS "vendorId",
        v."storeName" AS "storeName",
        v."storeNameAr" AS "storeNameAr",
        v.logo AS logo,
        v.rating AS rating,
        v.status::text AS "vendorStatus",
        nb.branch_name AS "branchName",
        nb.branch_name_ar AS "branchNameAr",
        nb.branch_address AS "branchAddress",
        nb.branch_is_open AS "branchIsOpen",
        nb.lat AS lat,
        nb.lng AS lng,
        nb.distance_km AS "distanceKm",
        COALESCE(oc.order_count, 0) AS "orderCount",
        COALESCE(oc.active_order_count, 0) AS "activeOrderCount"
      FROM nearest_branch nb
      JOIN vendors v ON v.id = nb.vendor_id
      LEFT JOIN order_counts oc ON oc.vendor_id = nb.vendor_id
      WHERE nb.rank = 1
        AND nb.distance_km <= ${safeRadius}
      ORDER BY "activeOrderCount" DESC, "orderCount" DESC, nb.distance_km ASC
      LIMIT 200
    `;

    return rows.map((row) => ({
      vendorId: row.vendorId,
      storeName: row.storeName,
      storeNameAr: row.storeNameAr,
      logo: row.logo,
      rating: row.rating == null ? 0 : Number(row.rating),
      vendorStatus: row.vendorStatus,
      branchName: row.branchName,
      branchNameAr: row.branchNameAr,
      branchAddress: row.branchAddress,
      branchIsOpen: row.branchIsOpen ?? false,
      lat: Number(row.lat),
      lng: Number(row.lng),
      distanceKm: Number(Number(row.distanceKm).toFixed(2)),
      orderCount: Number(row.orderCount) || 0,
      activeOrderCount: Number(row.activeOrderCount) || 0,
    }));
  }

  async updateProfile(userId: string, dto: UpdateDriverProfileDto) {
    const driver = await this.assertDriver(userId);
    return this.driversRepository.update(driver.id, {
      ...(dto.name !== undefined && { name: dto.name }),
      ...(dto.nationalId !== undefined && { nationalId: dto.nationalId }),
      ...(dto.licenseNumber !== undefined && {
        licenseNumber: dto.licenseNumber,
      }),
    });
  }

  async uploadAvatar(userId: string, file: Express.Multer.File) {
    const driver = await this.assertDriver(userId);

    if (driver.avatar) {
      await this.storage.delete(driver.avatar);
    }

    const avatarUrl = await this.storage.upload(file, 'drivers/avatars');
    await this.driversRepository.updateAvatar(driver.id, avatarUrl);
    return { avatar: avatarUrl };
  }

  // ─── Status ───────────────────────────────────────────────────────────────

  async updateStatus(userId: string, dto: UpdateDriverStatusDto) {
    const driver = await this.assertDriver(userId);

    if (driver.status === DriverStatus.SUSPENDED) {
      throw new ForbiddenException(DriverErrors.ACCOUNT_SUSPENDED);
    }

    if (!driver.isApproved) {
      throw new ForbiddenException(DriverErrors.NOT_APPROVED);
    }

    const activeStatuses: DriverStatus[] = [
      DriverStatus.ON_DELIVERY,
      DriverStatus.BUSY,
    ];
    if (
      activeStatuses.includes(driver.status) &&
      dto.status === DriverStatus.OFFLINE
    ) {
      throw new BadRequestException(DriverErrors.CANNOT_GO_OFFLINE_ON_DELIVERY);
    }

    // Breaks are tracked sessions, not plain status flips — force the
    // dedicated endpoints so every break is recorded with limits enforced.
    if (dto.status === DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.BREAK_USE_ENDPOINTS);
    }
    if (driver.status === DriverStatus.ON_BREAK) {
      throw new BadRequestException(DriverErrors.BREAK_USE_ENDPOINTS);
    }

    // Online/offline is fully shift-driven: starting a shift flips the
    // driver ONLINE, ending it flips OFFLINE. Manual flips are rejected so
    // drivers can never go online/offline on their own.
    if (
      dto.status === DriverStatus.ONLINE ||
      dto.status === DriverStatus.OFFLINE
    ) {
      throw new BadRequestException(DriverErrors.STATUS_MANAGED_BY_SHIFT);
    }

    const oldStatus = driver.status;
    await this.driversRepository.updateStatus(driver.id, dto.status);

    // NOTE: manual ONLINE/OFFLINE is rejected above, so the old
    // offline-cleanup branches are gone. Shift end paths settle breaks,
    // persist the last location and drop live tracking themselves
    // (see endShift / endShiftBySystem).

    this.eventEmitter.emit(
      EVENTS.DRIVER_STATUS_CHANGED,
      new DriverStatusChangedEvent(driver.id, userId, oldStatus, dto.status),
    );

    this.logger.log(`Driver ${driver.id} status: ${oldStatus} → ${dto.status}`);
    return { status: dto.status };
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  async getWalletBalance(userId: string) {
    const driver = await this.assertDriver(userId);
    return { walletBalance: driver.walletBalance };
  }

  async getWalletTransactions(userId: string, dto: QueryDriverWalletDto) {
    const driver = await this.assertDriver(userId);
    const { page = 1, limit = 20 } = dto;

    const result = await this.driversRepository.getWalletTransactions(
      driver.id,
      page,
      limit,
    );

    return { walletBalance: driver.walletBalance, ...result };
  }

  // ─── Internal helper used by dispatch ────────────────────────────────────

  async getDriverByUserId(userId: string) {
    return requireDriverByUserId(this.driversRepository, userId);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  private async assertDriver(userId: string) {
    return requireDriverByUserId(this.driversRepository, userId);
  }
}
