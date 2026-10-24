import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Permission } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PERMISSIONS_KEY, PERMISSIONS_MODE_KEY, PermissionsMode } from '../decorators/permissions.decorator';
import { JwtAccessPayload } from '../interfaces/jwt-payload.interface';
import { Role } from '@prisma/client';
import { CommonErrors } from '../constants/response.constants';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context
      .switchToHttp()
      .getRequest<{ user?: JwtAccessPayload }>();

    const user = request.user;
    if (!user?.sub) throw new UnauthorizedException(CommonErrors.UNAUTHORIZED);

    if (user.role === Role.SUPER_ADMIN) return true;

    if (user.role === Role.ADMIN || user.role === Role.DRIVER_MANAGER) {
      const dbUser = await this.prisma.user.findUnique({
        where: { id: user.sub },
        select: { permissions: true },
      });

      if (!dbUser)
        throw new UnauthorizedException(CommonErrors.UNAUTHORIZED);

      const effectivePermissions = new Set<Permission>(dbUser.permissions);
      if (user.role === Role.DRIVER_MANAGER) {
        effectivePermissions.add(Permission.MANAGE_DRIVERS);
        effectivePermissions.add(Permission.MANAGE_ORDERS);
        effectivePermissions.add(Permission.VIEW_FINANCIALS);
        effectivePermissions.add(Permission.VIEW_STATISTICS);
      }

      const mode = this.reflector.getAllAndOverride<PermissionsMode>(
        PERMISSIONS_MODE_KEY,
        [context.getHandler(), context.getClass()],
      );

      // `all` is the historical behaviour and stays the default so no existing
      // route is weakened. `any` implements explicit disjunctions such as
      // "MANAGE_ORDERS or MANAGE_DRIVERS".
      const satisfied =
        mode === 'any'
          ? requiredPermissions.some((p) => effectivePermissions.has(p))
          : requiredPermissions.every((p) => effectivePermissions.has(p));

      if (!satisfied) throw new ForbiddenException(CommonErrors.FORBIDDEN);

      return true;
    }

    throw new ForbiddenException(CommonErrors.FORBIDDEN);
  }
}
