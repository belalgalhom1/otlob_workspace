import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DriverStatus, Role, Permission } from '@prisma/client';

@Injectable()
export class SocketAuthService {
  private readonly logger = new Logger(SocketAuthService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Validates if a user is allowed to establish a WebSocket connection.
   */
  async authorize(userId: string, role: string): Promise<boolean> {
    try {
      // Ensure the role is a valid recognized role in the system
      if (!Object.values(Role).includes(role as Role)) {
        this.logger.debug(
          `Rejecting WS for ${userId}: Invalid or unrecognized role '${role}'`,
        );
        return false;
      }

      if (role === Role.DRIVER) {
        return this.authorizeDriver(userId);
      }

      if (role === Role.CUSTOMER) {
        return this.authorizeCustomer();
      }

      // VENDORS, ADMINS, SUPER_ADMIN are allowed by default for operational monitoring
      return true;
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(`Socket auth failed for ${userId}: ${err.message}`);
      }
      return false;
    }
  }

  /**
   * Validates if a user is authorized to track real-time GPS locations of a driver.
   * Only SUPER_ADMIN, ADMINs with MANAGE_DRIVERS, and DRIVER_MANAGERs assigned to this driver
   * are permitted.
   */
  async canTrackDriver(
    userId: string,
    role: string,
    driverId: string,
  ): Promise<boolean> {
    try {
      if (role === Role.SUPER_ADMIN) {
        return true;
      }

      if (role === Role.ADMIN) {
        const user = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { permissions: true },
        });
        return Boolean(user?.permissions?.includes(Permission.MANAGE_DRIVERS));
      }

      if (role === Role.DRIVER_MANAGER) {
        const manager = await this.prisma.driverManager.findUnique({
          where: { userId },
          select: { id: true, manageAllDrivers: true },
        });
        if (!manager) return false;
        if (manager.manageAllDrivers) return true;

        const assignment = await this.prisma.driverManagerAssignment.findUnique({
          where: {
            driverManagerId_driverId: {
              driverManagerId: manager.id,
              driverId,
            },
          },
          select: { id: true },
        });
        return Boolean(assignment);
      }

      return false;
    } catch (err) {
      if (err instanceof Error) {
        this.logger.error(
          `canTrackDriver check failed for user ${userId} on driver ${driverId}: ${err.message}`,
        );
      }
      return false;
    }
  }

  private async authorizeDriver(userId: string): Promise<boolean> {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { status: true },
    });

    if (!driver) return false;

    // Reject suspended drivers only
    if (driver.status === DriverStatus.SUSPENDED) {
      this.logger.debug(
        `Rejecting WS for driver ${userId} (status: ${driver.status})`,
      );
      return false;
    }

    return true;
  }

  private authorizeCustomer(): boolean {
    // We allow all JWT-authenticated customers to connect to the socket.
    // Idle sockets are extremely cheap, and rejecting them costs DB queries + client retries.
    return true;
  }
}
