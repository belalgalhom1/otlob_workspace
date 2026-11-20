import { BadRequestException, ConflictException } from '@nestjs/common';
import { DriverErrors } from '../constants/response.constants';

export const SHIFT_EARLY_START_WINDOW_MS = 15 * 60 * 1000;
export const SHIFT_WARNING_WINDOW_MS = 30 * 60 * 1000;

export interface ScheduledShiftRepositoryPort<T = unknown> {
  findOverlappingShift(
    driverId: string,
    startTime: Date,
    endTime: Date,
  ): Promise<unknown>;
  createShift(data: {
    driverId: string;
    zoneId: string | null;
    startTime: Date;
    endTime: Date;
  }): Promise<T>;
}

/**
 * Shared validator and creator for direct scheduled driver shifts, used by
 * both driver self-scheduling and admin manual shift creation.
 */
export async function createScheduledDriverShift<T>(
  repository: ScheduledShiftRepositoryPort<T>,
  driverId: string,
  dto: { startTime: string; endTime: string; zoneId?: string | null },
): Promise<T> {
  const startTime = new Date(dto.startTime);
  const endTime = new Date(dto.endTime);

  if (
    Number.isNaN(startTime.getTime()) ||
    Number.isNaN(endTime.getTime()) ||
    endTime <= startTime
  ) {
    throw new BadRequestException(DriverErrors.END_TIME_BEFORE_START);
  }

  const overlap = await repository.findOverlappingShift(
    driverId,
    startTime,
    endTime,
  );
  if (overlap) {
    throw new ConflictException(DriverErrors.SHIFT_OVERLAPS);
  }

  return repository.createShift({
    driverId,
    zoneId: dto.zoneId ?? null,
    startTime,
    endTime,
  });
}
