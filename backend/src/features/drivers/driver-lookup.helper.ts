import { NotFoundException } from '@nestjs/common';
import { DriverErrors } from 'src/common/constants/response.constants';
import { DriversRepository } from './drivers.repository';

export async function requireDriverByUserId(
  repo: DriversRepository,
  userId: string,
) {
  const driver = await repo.findByUserId(userId);
  if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
  return driver;
}

export async function requireDriverById(
  repo: DriversRepository,
  driverId: string,
) {
  const driver = await repo.findById(driverId);
  if (!driver) throw new NotFoundException(DriverErrors.PROFILE_NOT_FOUND);
  return driver;
}
