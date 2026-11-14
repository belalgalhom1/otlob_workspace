import { BadRequestException } from '@nestjs/common';
import { PlatformSetting } from '@prisma/client';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { EVENTS } from '../../common/events/event-names';
import { DeliveryFeeCalculator } from './delivery-fee.calculator';
import { UpdatePlatformSettingsDto } from './dto/platform-settings.dto';
import { PlatformSettingsService } from './platform-settings.service';

function makeSettings(
  overrides: Partial<PlatformSetting> = {},
): PlatformSetting {
  return {
    id: 'default',
    updatedAt: new Date(),
    baseDeliveryFee: 15,
    pricePerKm: 5,
    minOrderKm: 2,
    minDistanceFixedPrice: 18,
    maxDeliveryFee: 100,
    minDeliveryFee: 0,
    driverShiftsEnabled: false,
    goldTierBonusPerKm: 1.5,
    pricePerKmBicycle: 3,
    minDeliveryFeeBicycle: 12,
    maxDeliveryFeeBicycle: 40,
    pricePerKmMotorcycle: 5.5,
    minDeliveryFeeMotorcycle: 20,
    maxDeliveryFeeMotorcycle: 80,
    pricePerKmCar: 8,
    minDeliveryFeeCar: 30,
    maxDeliveryFeeCar: 120,
    pricePerKmVan: 10,
    minDeliveryFeeVan: 40,
    maxDeliveryFeeVan: 150,
    pricePerKmTruck: 14,
    minDeliveryFeeTruck: 60,
    maxDeliveryFeeTruck: 250,
    pricePerKmMotorTricycle: 4.5,
    minDeliveryFeeMotorTricycle: 18,
    maxDeliveryFeeMotorTricycle: 70,
    batchedDeliveryCommissionRate: 40,
    batchedDriverManagerCommissionRate: 10,
    stackedOrderDriverPercentage: 50,
    multiVendorDeliveryCommissionRate: 20,
    multiVendorDriverManagerCommissionRate: 10,
    multiVendorDriverPercentage: 70,
    maxMultiVendorVendors: 5,
    ...overrides,
  } as PlatformSetting;
}

describe('PlatformSettings & DeliveryFeeCalculator', () => {
  describe('DeliveryFeeCalculator', () => {
    const calculator = new DeliveryFeeCalculator();

    it('calculates base + perKm, zone override, and short-trip fixed fee', () => {
      const s = makeSettings();

      expect(
        calculator.calculateDeliveryFee(s, { distanceKm: 5 }),
      ).toBe(40); // 15 + 5*5

      expect(
        calculator.calculateDeliveryFee(s, {
          distanceKm: 5,
          zoneBaseDeliveryFeeOverride: 25,
        }),
      ).toBe(50); // 25 + 5*5

      expect(
        calculator.calculateDeliveryFee(s, { distanceKm: 1.2 }),
      ).toBe(18); // below minOrderKm=2 -> minDistanceFixedPrice=18
    });

    it('adds gold tier bonus only when driverShiftsEnabled and standard order', () => {
      const s = makeSettings({
        driverShiftsEnabled: true,
        goldTierBonusPerKm: 2,
      });

      expect(
        calculator.calculateDeliveryFee(s, {
          distanceKm: 4,
          isStandardOrder: true,
        }),
      ).toBe(43); // 15 + 4*(5+2)

      expect(
        calculator.calculateDeliveryFee(s, {
          distanceKm: 4,
          isStandardOrder: false,
        }),
      ).toBe(35); // 15 + 4*5
    });

    it('applies vehicle min/max clamp and global minDeliveryFee floor last', () => {
      const s = makeSettings({ minDeliveryFee: 22 });

      // Motorcycle min=20 raises short-trip 18 -> 20, then global floor 22 raises -> 22
      expect(
        calculator.calculateDeliveryFee(s, {
          distanceKm: 1,
          vehicleType: 'motorcycle',
        }),
      ).toBe(22);

      // Bicycle max=40 clamps 15 + 10*5 = 65 -> 40
      expect(
        calculator.calculateDeliveryFee(s, {
          distanceKm: 10,
          vehicleType: 'BICYCLE',
        }),
      ).toBe(40);
    });

    it('looks up per-km vehicle rates data-driven and returns null for unknown vehicles', () => {
      const s = makeSettings();
      expect(calculator.getVehiclePerKm(s, 'motor_tricycle')).toBe(4.5);
      expect(calculator.getVehiclePerKm(s, 'TRUCK')).toBe(14);
      expect(calculator.getVehiclePerKm(s, 'helicopter')).toBeNull();
    });
  });

  describe('PlatformSettingsService', () => {
    it('maps scalar fields, balances commission trios, invalidates cache, and emits SETTINGS_UPDATED', async () => {
      const current = makeSettings();
      const upsert = jest.fn(({ update }) =>
        Promise.resolve({
          ...current,
          ...update,
        }),
      );
      const cache = {
        get: jest.fn(),
        set: jest.fn(),
        del: jest.fn().mockResolvedValue(undefined),
      };
      const eventEmitter = { emit: jest.fn() };

      const service = new PlatformSettingsService(
        {
          platformSetting: {
            findUnique: jest.fn().mockResolvedValue(current),
            upsert,
          },
        } as any,
        { upload: jest.fn(), delete: jest.fn() } as any,
        eventEmitter as any,
        cache as any,
        new DeliveryFeeCalculator(),
      );

      await service.updateSettings({
        baseDeliveryFee: 20,
        batchedDeliveryCommissionRate: 30, // + manager 10 => driver auto-set to 60
        multiVendorDriverPercentage: 65, // + manager 10 => platform auto-set to 25
        // Attempted injection of upload-managed field must be ignored
        homeCoverUrl: 'https://evil.example/hijack.png',
      } as any);

      expect(upsert).toHaveBeenCalledWith({
        where: { id: 'default' },
        create: expect.objectContaining({
          id: 'default',
          baseDeliveryFee: 20,
        }),
        update: expect.objectContaining({
          baseDeliveryFee: 20,
          batchedDeliveryCommissionRate: 30,
          stackedOrderDriverPercentage: 60,
          multiVendorDriverPercentage: 65,
          multiVendorDeliveryCommissionRate: 25,
        }),
      });
      const updateArg = upsert.mock.calls[0][0].update;
      expect(updateArg.homeCoverUrl).toBeUndefined();
      expect(cache.del).toHaveBeenCalledWith('platform_settings');
      expect(eventEmitter.emit).toHaveBeenCalledWith(EVENTS.SETTINGS_UPDATED);
    });

    it('throws BadRequestException when uploading an icon for an unknown vehicle type', async () => {
      const storage = { upload: jest.fn(), delete: jest.fn() };
      const service = new PlatformSettingsService(
        { platformSetting: {} } as any,
        storage as any,
        { emit: jest.fn() } as any,
        { del: jest.fn() } as any,
      );

      await expect(
        service.uploadVehicleIcon('spaceship', {} as any),
      ).rejects.toThrow(BadRequestException);
      expect(storage.upload).not.toHaveBeenCalled();
    });

    it('exposes maxMultiVendorVendors in getPublicSettings and validates 1..20 bounds in DTO', async () => {
      const s = makeSettings({ maxMultiVendorVendors: 3 });
      const service = new PlatformSettingsService(
        {
          platformSetting: {
            findUnique: jest.fn().mockResolvedValue(s),
          },
        } as any,
        { upload: jest.fn(), delete: jest.fn() } as any,
        { emit: jest.fn() } as any,
        { get: jest.fn().mockResolvedValue(null), set: jest.fn() } as any,
      );

      const pub = await service.getPublicSettings();
      expect(pub.maxMultiVendorVendors).toBe(3);

      expect(
        await validate(
          plainToInstance(UpdatePlatformSettingsDto, { maxMultiVendorVendors: 3 }),
        ),
      ).toHaveLength(0);
      expect(
        await validate(
          plainToInstance(UpdatePlatformSettingsDto, { maxMultiVendorVendors: 1 }),
        ),
      ).toHaveLength(0);
      expect(
        await validate(
          plainToInstance(UpdatePlatformSettingsDto, { maxMultiVendorVendors: 0 }),
        ),
      ).not.toHaveLength(0);
      expect(
        await validate(
          plainToInstance(UpdatePlatformSettingsDto, { maxMultiVendorVendors: 21 }),
        ),
      ).not.toHaveLength(0);
    });
  });
});
