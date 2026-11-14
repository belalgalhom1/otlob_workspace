import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { VendorErrors } from '../../../common/constants/response.constants';

/**
 * Shared guard ensuring a non-deleted vendor row exists for nested vendor
 * sub-resources (branches, members, menu categories, products).
 */
export async function assertVendorExists(
  prisma: PrismaService,
  vendorId: string,
): Promise<void> {
  const vendor = await prisma.vendor.findFirst({
    where: { id: vendorId, deletedAt: null },
    select: { id: true },
  });
  if (!vendor) {
    throw new NotFoundException(VendorErrors.NOT_FOUND);
  }
}
