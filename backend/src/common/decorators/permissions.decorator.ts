import { SetMetadata, applyDecorators, UseGuards } from '@nestjs/common';
import { Permission } from '@prisma/client';
import { PermissionsGuard } from '../guards/permissions.guard';

export const PERMISSIONS_KEY = 'permissions';
export const PERMISSIONS_MODE_KEY = 'permissionsMode';

/**
 * How multiple required permissions combine.
 *
 * - `all` (default, and unchanged behaviour for every existing route): the user
 *   must hold *every* listed permission.
 * - `any`: the user needs at least one of the listed permissions. Used where the
 *   business rule is an explicit disjunction, e.g. assigning an assisting
 *   driver requires `MANAGE_ORDERS` **or** `MANAGE_DRIVERS`.
 */
export type PermissionsMode = 'all' | 'any';

export interface RequirePermissionsOptions {
  mode?: PermissionsMode;
}

export const RequirePermissions = (
  ...args: Array<Permission | RequirePermissionsOptions>
) => {
  // Support both call styles:
  //   RequirePermissions(A, B)                     -> all
  //   RequirePermissions(A, B, { mode: 'any' })    -> any
  const options = args.find(
    (a): a is RequirePermissionsOptions =>
      typeof a === 'object' && a !== null && !('length' in a),
  );
  const permissions = args.filter((a): a is Permission => typeof a === 'string');

  return applyDecorators(
    SetMetadata(PERMISSIONS_KEY, permissions),
    SetMetadata(PERMISSIONS_MODE_KEY, options?.mode ?? 'all'),
    UseGuards(PermissionsGuard),
  );
};
