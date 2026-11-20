import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import {
  CommonErrors,
  DriverErrors,
} from '../constants/response.constants';

export interface DriverManagerRecordSummary {
  id: string;
  walletBalance?: unknown;
  manageAllDrivers: boolean;
}

export async function ensureDriverManagerRecord(
  prisma: {
    driverManager?: {
      findUnique?: (args: any) => Promise<any>;
      create?: (args: any) => Promise<any>;
    };
    user?: {
      findUnique?: (args: any) => Promise<any>;
    };
  },
  userId: string,
): Promise<DriverManagerRecordSummary | null> {
  if (typeof prisma.driverManager?.findUnique !== 'function') {
    return null;
  }

  let manager = await prisma.driverManager.findUnique({
    where: { userId },
    select: { id: true, walletBalance: true, manageAllDrivers: true },
  });

  if (
    !manager &&
    typeof prisma.user?.findUnique === 'function' &&
    typeof prisma.driverManager?.create === 'function'
  ) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });
    if (user?.role === Role.DRIVER_MANAGER) {
      manager = await prisma.driverManager.create({
        data: { userId },
        select: { id: true, walletBalance: true, manageAllDrivers: true },
      });
    }
  }

  return manager ?? null;
}

/**
 * O(1) indexed verification that a DRIVER_MANAGER user manages `driverId`.
 * Avoids scanning the entire `drivers` table when `manageAllDrivers` is true
 * or loading all assignments when checking a single driver.
 */
export async function assertDriverManagerOwnsDriver(
  prisma: {
    driverManager?: {
      findUnique?: (args: any) => Promise<any>;
      create?: (args: any) => Promise<any>;
    };
    driverManagerAssignment?: {
      findUnique?: (args: any) => Promise<any>;
      findFirst?: (args: any) => Promise<any>;
      findMany?: (args: any) => Promise<Array<{ driverId: string }>>;
    };
    user?: {
      findUnique?: (args: any) => Promise<any>;
    };
  },
  userId: string,
  driverId: string,
  options?: { throwNotFoundIfNoManager?: boolean },
): Promise<true> {
  const manager = await ensureDriverManagerRecord(prisma, userId);
  if (!manager) {
    if (options?.throwNotFoundIfNoManager) {
      throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
    }
    throw new ForbiddenException(CommonErrors.FORBIDDEN);
  }

  if (manager.manageAllDrivers) {
    return true;
  }

  const assignmentRepo = prisma.driverManagerAssignment;
  let isAssigned = false;

  if (typeof assignmentRepo?.findUnique === 'function') {
    const assignment = await assignmentRepo.findUnique({
      where: {
        driverManagerId_driverId: {
          driverManagerId: manager.id,
          driverId,
        },
      },
      select: { id: true },
    });
    isAssigned = Boolean(assignment);
  } else if (typeof assignmentRepo?.findFirst === 'function') {
    const assignment = await assignmentRepo.findFirst({
      where: { driverManagerId: manager.id, driverId },
      select: { id: true },
    });
    isAssigned = Boolean(assignment);
  } else if (typeof assignmentRepo?.findMany === 'function') {
    const assignments = await assignmentRepo.findMany({
      where: { driverManagerId: manager.id },
      select: { driverId: true },
    });
    isAssigned = assignments.some((a) => a.driverId === driverId);
  }

  if (!isAssigned) {
    throw new ForbiddenException(CommonErrors.FORBIDDEN);
  }

  return true;
}
