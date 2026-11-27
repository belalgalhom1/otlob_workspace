import { BadRequestException, NotFoundException } from '@nestjs/common';
import {
  VendorErrors,
  ZoneErrors,
} from '../../common/constants/response.constants';
import { VendorCacheService } from './helpers/vendor-cache.service';
import { assertVendorExists } from './helpers/vendor-lookup.helper';
import {
  evaluateBranchEffectiveOpen,
  isVendorScheduleOpen,
} from './helpers/vendor-schedule.helper';
import { VendorsProcessor } from './vendors.processor';
import { VendorBranchesService } from './branches/vendor-branches.service';
import { VendorsService } from './vendors.service';
import { VendorVerticalsService } from './verticals/vendor-verticals.service';

describe('Vendors Architecture & Shared Helpers', () => {
  describe('isVendorScheduleOpen', () => {
    // 2026-01-15 is Thursday (day 4); Cairo is UTC+2 in January (no DST)
    const thu1200Cairo = new Date('2026-01-15T10:00:00Z');
    const thu2130Cairo = new Date('2026-01-15T19:30:00Z');
    const fri0100Cairo = new Date('2026-01-15T23:00:00Z'); // Fri day 5, 01:00 Cairo
    const fri0300Cairo = new Date('2026-01-16T01:00:00Z'); // Fri day 5, 03:00 Cairo

    it('defaults to open when schedule is empty or missing', () => {
      expect(isVendorScheduleOpen(null, thu1200Cairo)).toBe(true);
      expect(isVendorScheduleOpen([], thu1200Cairo)).toBe(true);
    });

    it('evaluates regular daytime schedule in Africa/Cairo', () => {
      const schedule = [
        { day: 4, isClosed: false, openTime: '09:00', closeTime: '18:00' },
      ];
      expect(isVendorScheduleOpen(schedule, thu1200Cairo)).toBe(true);
      expect(isVendorScheduleOpen(schedule, thu2130Cairo)).toBe(false);
    });

    it('handles overnight shift cleanly without morning false positives', () => {
      const overnightThursdayOnly = [
        { day: 4, isClosed: false, openTime: '20:00', closeTime: '02:00' },
        { day: 5, isClosed: true },
      ];
      // Thursday 12:00 Cairo: before 20:00 open time -> closed
      expect(isVendorScheduleOpen(overnightThursdayOnly, thu1200Cairo)).toBe(
        false,
      );
      // Thursday 21:30 Cairo: inside overnight open window -> open
      expect(isVendorScheduleOpen(overnightThursdayOnly, thu2130Cairo)).toBe(
        true,
      );
      // Friday 01:00 Cairo: yesterday (Thu) overnight shift still open -> true even though Fri isClosed
      expect(isVendorScheduleOpen(overnightThursdayOnly, fri0100Cairo)).toBe(
        true,
      );
      // Friday 03:00 Cairo: past Thu 02:00 close and Fri is closed -> false
      expect(isVendorScheduleOpen(overnightThursdayOnly, fri0300Cairo)).toBe(
        false,
      );
    });

    it('treats identical openTime and closeTime as 24-hour open for that day', () => {
      const alwaysOpenThu = [
        { day: 4, isClosed: false, openTime: '00:00', closeTime: '00:00' },
      ];
      expect(isVendorScheduleOpen(alwaysOpenThu, thu1200Cairo)).toBe(true);
      expect(isVendorScheduleOpen(alwaysOpenThu, thu2130Cairo)).toBe(true);
    });

    it('fails closed on corrupted workingHours runtime exceptions', () => {
      const badEntry = {
        get day(): number {
          throw new Error('corrupted');
        },
      };
      expect(isVendorScheduleOpen([badEntry], thu1200Cairo)).toBe(false);
    });
  });

  describe('evaluateBranchEffectiveOpen', () => {
    const thu1200Cairo = new Date('2026-01-15T10:00:00Z');
    const thu2130Cairo = new Date('2026-01-15T19:30:00Z');
    const daytimeSchedule = [
      { day: 4, isClosed: false, openTime: '09:00', closeTime: '18:00' },
    ];

    it('keeps branch closed when manual isOpen is false', () => {
      expect(
        evaluateBranchEffectiveOpen(
          {
            isOpen: false,
            is24Hours: true,
            isScheduleActive: true,
            workingHours: daytimeSchedule,
          },
          thu1200Cairo,
        ),
      ).toEqual({ isOpen: false, isClosedBySchedule: false });
    });

    it('treats 24-hour branch as open regardless of schedule window', () => {
      expect(
        evaluateBranchEffectiveOpen(
          {
            isOpen: true,
            is24Hours: true,
            isScheduleActive: true,
            workingHours: daytimeSchedule,
          },
          thu2130Cairo,
        ),
      ).toEqual({ isOpen: true, isClosedBySchedule: false });
    });

    it('marks branch closed by schedule outside workingHours when isScheduleActive is true', () => {
      expect(
        evaluateBranchEffectiveOpen(
          {
            isOpen: true,
            is24Hours: false,
            isScheduleActive: true,
            workingHours: daytimeSchedule,
          },
          thu2130Cairo,
        ),
      ).toEqual({ isOpen: false, isClosedBySchedule: true });
    });

    it('ignores schedule when isScheduleActive is false', () => {
      expect(
        evaluateBranchEffectiveOpen(
          {
            isOpen: true,
            is24Hours: false,
            isScheduleActive: false,
            workingHours: daytimeSchedule,
          },
          thu2130Cairo,
        ),
      ).toEqual({ isOpen: true, isClosedBySchedule: false });
    });
  });

  describe('VendorCacheService', () => {
    it('reads cached vendor details and populates on miss via single key builder', async () => {
      const cachedPayload = { id: 'v1', cached: true };
      const freshPayload = { id: 'v2', cached: false };
      const cache = {
        get: jest
          .fn()
          .mockResolvedValueOnce(cachedPayload)
          .mockResolvedValueOnce(undefined),
        set: jest.fn().mockResolvedValue(undefined),
      };
      const svc = new VendorCacheService({} as any, cache as any);

      const hitLoader = jest.fn();
      await expect(
        svc.getOrSetVendorDetailsById('v1', hitLoader),
      ).resolves.toEqual(cachedPayload);
      expect(hitLoader).not.toHaveBeenCalled();

      const missLoader = jest.fn().mockResolvedValue(freshPayload);
      await expect(
        svc.getOrSetVendorDetailsBySlug('store-2', missLoader),
      ).resolves.toEqual(freshPayload);
      expect(cache.set).toHaveBeenCalledWith(
        'vendor_slug_details_store-2',
        freshPayload,
        300000,
      );
    });

    it('uses known slug directly without hitting Prisma', async () => {
      const cache = { del: jest.fn().mockResolvedValue(undefined) };
      const prisma = { vendor: { findUnique: jest.fn() } };
      const svc = new VendorCacheService(prisma as any, cache as any);

      await svc.invalidateVendorDetails('v1', 'my-store');

      expect(prisma.vendor.findUnique).not.toHaveBeenCalled();
      expect(cache.del).toHaveBeenCalledWith('vendor_details_v1');
      expect(cache.del).toHaveBeenCalledWith('vendor_slug_details_my-store');
    });

    it('batch-invalidates flipped vendor IDs and slugs with one findMany query', async () => {
      const cache = { del: jest.fn().mockResolvedValue(undefined) };
      const findMany = jest.fn().mockResolvedValue([
        { id: 'v1', slug: 'slug-1' },
        { id: 'v2', slug: null },
      ]);
      const svc = new VendorCacheService(
        { vendor: { findMany } } as any,
        cache as any,
      );

      await svc.invalidateManyVendorDetails(['v1', 'v2', 'v1']);

      expect(findMany).toHaveBeenCalledTimes(1);
      expect(findMany).toHaveBeenCalledWith({
        where: { id: { in: ['v1', 'v2'] } },
        select: { id: true, slug: true },
      });
      expect(cache.del).toHaveBeenCalledWith('vendor_details_v1');
      expect(cache.del).toHaveBeenCalledWith('vendor_slug_details_slug-1');
      expect(cache.del).toHaveBeenCalledWith('vendor_details_v2');
      expect(cache.del).toHaveBeenCalledTimes(3);
    });
  });

  describe('VendorsProcessor', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      // Thursday 2026-01-15 12:00 Cairo
      jest.setSystemTime(new Date('2026-01-15T10:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('syncs branch isOpen state from per-branch schedules and invalidates affected vendor caches', async () => {
      const updateMany = jest.fn().mockResolvedValue({ count: 1 });
      const prisma = {
        vendorBranch: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'b-open',
              vendorId: 'v-1',
              isOpen: false,
              is24Hours: false,
              workingHours: [
                {
                  day: 4,
                  isClosed: false,
                  openTime: '09:00',
                  closeTime: '18:00',
                },
              ],
            },
            {
              id: 'b-24h',
              vendorId: 'v-1',
              isOpen: false,
              is24Hours: true,
              workingHours: null,
            },
            {
              id: 'b-close',
              vendorId: 'v-2',
              isOpen: true,
              is24Hours: false,
              workingHours: [
                {
                  day: 4,
                  isClosed: false,
                  openTime: '20:00',
                  closeTime: '02:00',
                },
              ],
            },
          ]),
          updateMany,
        },
      };
      const vendorCache = {
        invalidateManyVendorDetails: jest.fn().mockResolvedValue(undefined),
      };

      const processor = new VendorsProcessor(
        prisma as any,
        { add: jest.fn() } as any,
        vendorCache as any,
      );

      await (processor as any).handleVendorWorkingHours();

      expect(updateMany).toHaveBeenCalledWith({
        where: { id: { in: ['b-open', 'b-24h'] } },
        data: { isOpen: true },
      });
      expect(updateMany).toHaveBeenCalledWith({
        where: { id: { in: ['b-close'] } },
        data: { isOpen: false },
      });
      expect(vendorCache.invalidateManyVendorDetails).toHaveBeenCalledWith([
        'v-1',
        'v-2',
      ]);
    });
  });

  describe('assertVendorExists', () => {
    it('throws VendorErrors.NOT_FOUND when vendor does not exist or is soft-deleted', async () => {
      const prisma = {
        vendor: {
          findFirst: jest
            .fn()
            .mockResolvedValueOnce({ id: 'v1' })
            .mockResolvedValueOnce(null),
        },
      };

      await expect(
        assertVendorExists(prisma as any, 'v1'),
      ).resolves.toBeUndefined();
      await expect(assertVendorExists(prisma as any, 'v2')).rejects.toThrow(
        new NotFoundException(VendorErrors.NOT_FOUND),
      );
    });
  });

  describe('VendorBranchesService zone resolution, schedule sync & cache delegation', () => {
    it('delegates requested & auto-detected zone validation to LocationRepository and invalidates via VendorCacheService', async () => {
      const prisma = {
        vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'v1' }) },
        $executeRaw: jest.fn().mockResolvedValue(1),
        $queryRaw: jest
          .fn()
          .mockResolvedValue([
            {
              id: 'b1',
              vendorId: 'v1',
              zoneId: 'z-auto',
              isOpen: true,
              isScheduleActive: true,
              is24Hours: false,
              workingHours: null,
            },
          ]),
      };
      const vendorCache = {
        invalidateVendorDetails: jest.fn().mockResolvedValue(undefined),
      };
      const locationRepository = {
        isPointInZone: jest.fn().mockResolvedValue(false),
        findContainingActiveZone: jest.fn().mockResolvedValue({ id: 'z-auto' }),
      };

      const service = new VendorBranchesService(
        prisma as any,
        { del: jest.fn() } as any,
        vendorCache as any,
        locationRepository as any,
      );

      const branch = await service.create('v1', {
        name: 'Maadi',
        address: 'Road 9',
        location: [29.96, 31.25],
        zoneId: 'z-wrong',
      } as any);

      expect(branch.zoneId).toBe('z-auto');
      expect(branch.effectiveIsOpen).toBe(true);
      expect(locationRepository.isPointInZone).toHaveBeenCalledWith(
        'z-wrong',
        31.25,
        29.96,
        { activeOnly: true },
      );
      expect(locationRepository.findContainingActiveZone).toHaveBeenCalledWith(
        31.25,
        29.96,
      );
      expect(vendorCache.invalidateVendorDetails).toHaveBeenCalledWith('v1');
    });

    it('immediately syncs isOpen when updating branch workingHours or is24Hours', async () => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-01-15T10:00:00Z')); // Thu 12:00 Cairo

      try {
        const update = jest.fn().mockResolvedValue({});
        const prisma = {
          vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'v1' }) },
          vendorBranch: { update },
          $queryRaw: jest.fn().mockResolvedValue([
            {
              id: 'b1',
              vendorId: 'v1',
              zoneId: 'z1',
              isOpen: false,
              isScheduleActive: true,
              is24Hours: false,
              workingHours: null,
              location: { type: 'Point', coordinates: [31.25, 29.96] },
            },
          ]),
        };
        const vendorCache = {
          invalidateVendorDetails: jest.fn().mockResolvedValue(undefined),
        };
        const service = new VendorBranchesService(
          prisma as any,
          { del: jest.fn() } as any,
          vendorCache as any,
          {} as any,
        );

        await service.update('v1', 'b1', {
          workingHours: [
            { day: 4, isClosed: false, openTime: '09:00', closeTime: '18:00' },
          ],
        } as any);

        expect(update).toHaveBeenCalledWith({
          where: { id: 'b1' },
          data: expect.objectContaining({
            isOpen: true,
            isScheduleActive: true,
          }),
        });
      } finally {
        jest.useRealTimers();
      }
    });

    it('rejects branch location outside every active zone', async () => {
      const locationRepository = {
        isPointInZone: jest.fn(),
        findContainingActiveZone: jest.fn().mockResolvedValue(null),
      };

      const service = new VendorBranchesService(
        {
          vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'v1' }) },
        } as any,
        { del: jest.fn() } as any,
        undefined,
        locationRepository as any,
      );

      await expect(
        service.create('v1', {
          name: 'Remote',
          address: 'Middle of nowhere',
          location: [10, 10],
        } as any),
      ).rejects.toThrow(
        new BadRequestException(ZoneErrors.INVALID_LOCATION_FOR_ZONE),
      );
    });
  });

  describe('VendorsService.mapVendorForApp per-branch working hours', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      // Thursday 2026-01-15 12:00 Cairo
      jest.setSystemTime(new Date('2026-01-15T10:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('evaluates each branch independently and keeps vendor OPEN when at least one branch is open', () => {
      const service = new VendorsService(
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      const mapped = (service as any).mapVendorForApp({
        id: 'v1',
        status: 'OPEN',
        storeName: 'Store',
        storeNameAr: null,
        slug: 'store',
        description: null,
        descriptionAr: null,
        coverImage: null,
        logo: null,
        branches: [
          {
            id: 'b-open',
            name: 'Day Branch',
            nameAr: null,
            address: 'Addr 1',
            phone: null,
            isOpen: true,
            is24Hours: false,
            isScheduleActive: true,
            workingHours: [
              {
                day: 4,
                isClosed: false,
                openTime: '09:00',
                closeTime: '18:00',
              },
            ],
          },
          {
            id: 'b-closed',
            name: 'Night Branch',
            nameAr: null,
            address: 'Addr 2',
            phone: null,
            isOpen: true,
            is24Hours: false,
            isScheduleActive: true,
            workingHours: [
              {
                day: 4,
                isClosed: false,
                openTime: '20:00',
                closeTime: '02:00',
              },
            ],
          },
        ],
      });

      expect(mapped.status).toBe('OPEN');
      expect(mapped.isClosedBySchedule).toBe(false);
      expect(mapped.branches[0].isOpen).toBe(true);
      expect(mapped.branches[0].isClosedBySchedule).toBe(false);
      expect(mapped.branches[1].isOpen).toBe(false);
      expect(mapped.branches[1].isClosedBySchedule).toBe(true);
    });

    it('marks vendor CLOSED by schedule when all branches are closed by schedule', () => {
      const service = new VendorsService(
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
        {} as any,
      );

      const mapped = (service as any).mapVendorForApp({
        id: 'v1',
        status: 'OPEN',
        storeName: 'Store',
        storeNameAr: null,
        slug: 'store',
        description: null,
        descriptionAr: null,
        coverImage: null,
        logo: null,
        branches: [
          {
            id: 'b-closed',
            name: 'Night Branch',
            nameAr: null,
            address: 'Addr 2',
            phone: null,
            isOpen: true,
            is24Hours: false,
            isScheduleActive: true,
            workingHours: [
              {
                day: 4,
                isClosed: false,
                openTime: '20:00',
                closeTime: '02:00',
              },
            ],
          },
        ],
      });

      expect(mapped.status).toBe('CLOSED');
      expect(mapped.isClosedBySchedule).toBe(true);
      expect(mapped.branches[0].isOpen).toBe(false);
    });
  });

  describe('VendorVerticalsService.findAll', () => {
    it('includes active non-deleted vendors and counts for each business type', async () => {
      const findMany = jest.fn().mockResolvedValue([
        {
          id: 'vert-1',
          name: 'Restaurants',
          nameAr: 'مطاعم',
          isActive: true,
          vendors: [
            {
              id: 'v1',
              storeName: 'Koshary El Tahrir',
              storeNameAr: 'كشري التحرير',
              slug: 'koshary',
              logo: null,
              status: 'OPEN',
              isContracted: true,
              _count: { branches: 2 },
            },
          ],
          _count: { vendors: 1 },
        },
      ]);

      const service = new VendorVerticalsService(
        { vendorVertical: { findMany } } as any,
        {} as any,
      );

      const verticals = await service.findAll();

      expect(verticals).toHaveLength(1);
      expect(verticals[0].vendors).toHaveLength(1);
      expect(findMany).toHaveBeenCalledWith({
        orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
        include: {
          vendors: {
            where: { deletedAt: null },
            orderBy: { storeName: 'asc' },
            select: {
              id: true,
              storeName: true,
              storeNameAr: true,
              slug: true,
              logo: true,
              status: true,
              isContracted: true,
              _count: {
                select: {
                  branches: true,
                },
              },
            },
          },
          _count: {
            select: {
              vendors: {
                where: { deletedAt: null },
              },
            },
          },
        },
      });
    });
  });
});
