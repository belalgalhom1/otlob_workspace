import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { OrdersRepository } from './orders.repository';
import { QueryOrdersDto } from './dto/order.dto';
import { JwtAccessPayload } from '../../common/interfaces/jwt-payload.interface';
import { Role, Permission } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import {
  OrderErrors,
  DriverErrors,
} from '../../common/constants/response.constants';

@Injectable()
export class OrdersService {
  constructor(
    private readonly ordersRepository: OrdersRepository,
    private readonly prisma: PrismaService,
  ) {}

  async getMyOrdersAsCustomer(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const customer = await this.prisma.customer.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!customer)
      return { orders: [], total: 0, page: 1, limit: 20, totalPages: 0 };
    return this.ordersRepository.findMany({ ...dto, customerId: customer.id });
  }

  async getVendorOrders(
    actor: JwtAccessPayload,
    vendorId: string,
    dto: QueryOrdersDto,
  ) {
    const [isMember, canManage] = await Promise.all([
      this.prisma.vendorMember.findUnique({
        where: { vendorId_userId: { vendorId, userId: actor.sub } },
        select: { id: true },
      }),
      this.canManageOrders(actor.sub, actor.role),
    ]);

    if (!isMember && !canManage) {
      throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VENDOR);
    }

    return this.ordersRepository.findMany({ ...dto, vendorId });
  }

  async getMyOrdersAsDriver(actor: JwtAccessPayload, dto: QueryOrdersDto) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.sub },
      select: { id: true },
    });
    if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    return this.ordersRepository.findMany({ ...dto, driverId: driver.id });
  }

  async getOne(actor: JwtAccessPayload, orderId: string) {
    const order = await this.ordersRepository.findById(orderId);

    if (await this.canManageOrders(actor.sub, actor.role)) return order;

    const [customer, driver, vendorMember] = await Promise.all([
      this.prisma.customer.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      this.prisma.driver.findUnique({
        where: { userId: actor.sub },
        select: { id: true },
      }),
      order.vendorId
        ? this.prisma.vendorMember.findUnique({
            where: {
              vendorId_userId: { vendorId: order.vendorId, userId: actor.sub },
            },
            select: { id: true },
          })
        : Promise.resolve(null),
    ]);

    // A multi-vendor order has vendorId = NULL and only mirrors the FIRST
    // delivery's driver, so resolve access through the portions/groups as well:
    // otherwise every other delivery's driver and every portion vendor is
    // locked out of an order they are actively working.
    const deliveryGroups = ((order as any).deliveryGroups ?? []) as Array<{
      primaryDriverId: string | null;
      assistDriverId: string | null;
    }>;

    const driverOwnsDelivery =
      !!driver &&
      (order.driverId === driver.id ||
        deliveryGroups.some(
          (g) =>
            g.primaryDriverId === driver.id || g.assistDriverId === driver.id,
        ));

    const isCustomerOwner = !!customer && order.customerId === customer.id;

    let isPortionVendorStaff = !!vendorMember;
    if (!isCustomerOwner && !driverOwnsDelivery && !isPortionVendorStaff) {
      const portionVendorIds = Array.from(
        new Set(
          (((order as any).vendorFulfillments ?? []) as Array<{
            vendorId: string;
          }>).map((f) => f.vendorId),
        ),
      );
      if (portionVendorIds.length > 0) {
        isPortionVendorStaff = !!(await this.prisma.vendorMember.findFirst({
          where: { userId: actor.sub, vendorId: { in: portionVendorIds } },
          select: { id: true },
        }));
      }
    }

    const isOwner =
      isCustomerOwner || driverOwnsDelivery || isPortionVendorStaff;

    if (!isOwner) throw new ForbiddenException(OrderErrors.NOT_AUTHORIZED_VIEW);
    return order;
  }

  async adminFindAll(dto: QueryOrdersDto) {
    return this.ordersRepository.findMany(dto);
  }

  private async canManageOrders(userId: string, role: Role): Promise<boolean> {
    if (role === Role.SUPER_ADMIN) return true;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { permissions: true },
    });
    return !!user?.permissions.includes(Permission.MANAGE_ORDERS);
  }
}
