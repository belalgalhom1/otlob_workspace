import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { OrdersRepository } from './orders.repository';
import { QueryOrdersDto } from './dto/order.dto';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { Role } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import {
  OrderErrors,
  DriverErrors,
} from '../../common/constants/response.constants';
import { OrderAuthorizationHelper } from './helpers/order-authorization.helper';
import { OrderEarningsCalculator } from '../../common/orders/order-earnings.calculator';
import {
  OrderRoleProjector,
  RoleProjectionContext,
} from './projections/order-role.projector';

@Injectable()
export class OrdersService {
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly prisma: PrismaService,
    private readonly platformSettings: PlatformSettingsService,
    @Optional() private readonly authHelper?: OrderAuthorizationHelper,
    @Optional() private readonly earningsCalculator?: OrderEarningsCalculator,
    @Optional() private readonly roleProjector?: OrderRoleProjector,
  ) {}

  private get auth(): OrderAuthorizationHelper {
    return this.authHelper ?? new OrderAuthorizationHelper(this.prisma);
  }

  private get earnings(): OrderEarningsCalculator {
    return (
      this.earningsCalculator ??
      new OrderEarningsCalculator(this.platformSettings)
    );
  }

  private get projector(): OrderRoleProjector {
    return (
      this.roleProjector ??
      new OrderRoleProjector(
        this.prisma,
        this.platformSettings,
        this.auth,
        this.earnings,
      )
    );
  }

  async getMyOrdersAsCustomer(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const [customer, canManage] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      this.auth.canManageOrders(actor.sub, actor.role),
    ]);
    if (!customer)
      return { orders: [], total: 0, page: 1, limit: 20, totalPages: 0 };
    const result = await this.ordersRepository.findMany({ ...dto, customerId: customer.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, undefined, { canManage }),
      ),
    );
    return result;
  }

  async getVendorOrders(
    actor: JwtAccessPayload,
    vendorId: string,
    dto: QueryOrdersDto,
  ) {
    let targetVendorId = vendorId?.trim();
    const canManage = await this.auth.canManageOrders(actor.sub, actor.role);
    let isMember: {
      id: string;
      vendorId: string;
      branchId: string | null;
      role: string;
    } | null = null;

    if (!targetVendorId || targetVendorId === 'my') {
      isMember = await this.prisma.vendorMember.findFirst({
        where: { userId: actor.sub },
        select: { id: true, vendorId: true, branchId: true, role: true },
      });
      if (isMember) {
        targetVendorId = isMember.vendorId;
      }
    } else {
      isMember = await this.prisma.vendorMember.findUnique({
        where: {
          vendorId_userId: { vendorId: targetVendorId, userId: actor.sub },
        },
        select: { id: true, vendorId: true, branchId: true, role: true },
      });
    }

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
    }

    if (!targetVendorId) {
      return { orders: [], total: 0, page: dto.page ?? 1, limit: dto.limit ?? 20, totalPages: 0 };
    }

    const effectiveBranchId =
      !canManage && isMember && isMember.role !== 'OWNER' && isMember.branchId
        ? isMember.branchId
        : undefined;

    const result = await this.ordersRepository.findMany({
      ...dto,
      vendorId: targetVendorId,
      ...(effectiveBranchId ? { branchId: effectiveBranchId } : {}),
    });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, targetVendorId, {
          canManage,
          vendorId: targetVendorId,
          memberBranchId: effectiveBranchId ?? null,
        }),
      ),
    );
    return result;
  }

  async getMyOrdersAsDriver(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const [driver, canManage, settings] = await Promise.all([
      this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true, tier: true },
      }),
      this.auth.canManageOrders(actor.sub, actor.role),
      this.platformSettings.getSettings(),
    ]);
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    const result = await this.ordersRepository.findMany({ ...dto, driverId: driver.id });
    result.orders = await Promise.all(
      result.orders.map((o: any) =>
        this.projectOrderForRole(o, actor, undefined, {
          canManage,
          driverId: driver.id,
          driverTier: driver.tier,
          settings,
        }),
      ),
    );
    return result;
  }

  async getOne(actor: JwtAccessPayload, orderId: string) {
    const order = await this.ordersRepository.findById(orderId);

    if (actor.role === Role.DRIVER_MANAGER) {
      const managed = await this.getManagedDriverIdsForUser(actor.sub);
      if (!this.isOrderAssignedToDrivers(order, managed)) {
        throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
      }
      return this.enrichWithAdminHelpers(order);
    }

    if (await this.auth.canManageOrders(actor.sub, actor.role)) {
      return this.enrichWithAdminHelpers(order);
    }

    const [customer, driver] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true, tier: true },
      }),
    ]);

    const deliveryGroups = ((order as any).deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>;

    const driverOwnsDelivery =
      !!driver &&
      deliveryGroups.some(
        (g) =>
          g.primaryDriverId === driver.id || g.assistDriverId === driver.id,
      );

    const isCustomerOwner = !!customer && order.customerId === customer.id;

    let isPortionVendorStaff = false;
    let matchingVendorId: string | undefined;
    let memberBranchId: string | null = null;

    if (!isCustomerOwner && !driverOwnsDelivery) {
      const fulfillments = ((order as any).vendorFulfillments ?? []) as Array<{
        vendorId: string;
        vendorBranchId?: string | null;
      }>;
      const portionVendorIds = Array.from(
        new Set(fulfillments.map((f) => f.vendorId)),
      );
      if (portionVendorIds.length > 0) {
        const memberships = await this.prisma.vendorMember.findMany({
          where: { userId: actor.sub, vendorId: { in: portionVendorIds } },
          select: { vendorId: true, branchId: true, role: true },
        });
        const found = memberships.find((m) => {
          const effBranch = m.role === 'OWNER' ? null : (m.branchId ?? null);
          return fulfillments.some(
            (f) =>
              f.vendorId === m.vendorId &&
              (!effBranch ||
                !f.vendorBranchId ||
                f.vendorBranchId === effBranch),
          );
        });
        if (found) {
          isPortionVendorStaff = true;
          matchingVendorId = found.vendorId;
          memberBranchId =
            found.role === 'OWNER' ? null : (found.branchId ?? null);
        }
      }
    }

    const isOwner =
      isCustomerOwner || driverOwnsDelivery || isPortionVendorStaff;

    if (!isOwner) throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    return this.projectOrderForRole(order, actor, matchingVendorId, {
      driverId: driver?.id,
      driverTier: driver?.tier,
      memberBranchId,
    });
  }

  async adminFindAll(dto: QueryOrdersDto, actor?: JwtAccessPayload) {
    if (actor?.role === Role.DRIVER_MANAGER) {
      const managedDriverIds = await this.getManagedDriverIdsForUser(actor.sub);
      if (managedDriverIds.length === 0) {
        return {
          orders: [],
          total: 0,
          page: dto.page ?? 1,
          limit: dto.limit ?? 20,
          totalPages: 0,
        };
      }
      if (dto.driverId && !managedDriverIds.includes(dto.driverId)) {
        return {
          orders: [],
          total: 0,
          page: dto.page ?? 1,
          limit: dto.limit ?? 20,
          totalPages: 0,
        };
      }
      const [result, settings] = await Promise.all([
        this.ordersRepository.findMany({
          ...dto,
          driverIds: dto.driverId ? undefined : managedDriverIds,
        }),
        this.platformSettings.getSettings(),
      ]);
      result.orders = await Promise.all(
        result.orders.map((o: any) => this.enrichWithAdminHelpers(o, settings)),
      );
      return result;
    }

    const [result, settings] = await Promise.all([
      this.ordersRepository.findMany(dto),
      this.platformSettings.getSettings(),
    ]);
    result.orders = await Promise.all(
      result.orders.map((o: any) => this.enrichWithAdminHelpers(o, settings)),
    );
    return result;
  }

  async getManagedDriverIdsForUser(userId: string): Promise<string[]> {
    const manager = await this.prisma.driverManager.findUnique({
      where: { userId },
      select: { id: true, manageAllDrivers: true },
    });
    if (!manager) return [];
    if (manager.manageAllDrivers) {
      const drivers = await this.prisma.driver.findMany({
        where: { deletedAt: null },
        select: { id: true },
      });
      return drivers.map((d) => d.id);
    }
    const assignments = await this.prisma.driverManagerAssignment.findMany({
      where: { driverManagerId: manager.id },
      select: { driverId: true },
    });
    return assignments.map((a) => a.driverId);
  }

  isOrderAssignedToDrivers(order: any, driverIds: string[]): boolean {
    if (!order || driverIds.length === 0) return false;
    const driverSet = new Set(driverIds);
    const deliveryGroups = (order.deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>;
    return deliveryGroups.some(
      (g) =>
        (g.primaryDriverId && driverSet.has(g.primaryDriverId)) ||
        (g.assistDriverId && driverSet.has(g.assistDriverId)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE PROJECTIONS (High-throughput in-memory data masking)
  // ═══════════════════════════════════════════════════════════════════════════

  projectOrderForRole(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: RoleProjectionContext,
  ): Promise<any> {
    return this.projector.projectOrderForRole(order, actor, vendorIdScope, ctx);
  }

  private projectForDriver(
    order: any,
    actor: JwtAccessPayload,
    ctx?: { driverId?: string | null; driverTier?: string | null; settings?: any },
  ): Promise<any> {
    return this.projector.projectForDriver(order, actor, ctx);
  }

  private projectForVendor(
    order: any,
    actor: JwtAccessPayload,
    vendorIdScope?: string,
    ctx?: { vendorId?: string; memberBranchId?: string | null },
  ): Promise<any> {
    return this.projector.projectForVendor(order, actor, vendorIdScope, ctx);
  }

  private projectForCustomer(order: any): any {
    return this.projector.projectForCustomer(order);
  }

  private enrichWithAdminHelpers(order: any, settings?: any): Promise<any> {
    return this.projector.enrichWithAdminHelpers(order, settings);
  }
}
