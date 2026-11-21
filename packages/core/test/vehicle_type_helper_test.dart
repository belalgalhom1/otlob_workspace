import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleTypeHelper', () {
    test('defines exact Ride, Custom Delivery, and Standard vehicle matrices', () {
      expect(
        VehicleTypeHelper.eligibleForOrderType('RIDE'),
        ['MOTORCYCLE', 'CAR', 'MINIBUS', 'TUK_TUK'],
      );
      expect(
        VehicleTypeHelper.eligibleForOrderType('CUSTOM_DELIVERY'),
        ['MOTORCYCLE', 'MOTOR_TRICYCLE', 'QUARTER_TRUCK', 'HALF_TRUCK'],
      );
      expect(
        VehicleTypeHelper.eligibleForOrderType('delivery'),
        ['MOTORCYCLE', 'MOTOR_TRICYCLE', 'QUARTER_TRUCK', 'HALF_TRUCK'],
      );
      expect(
        VehicleTypeHelper.eligibleForOrderType('STANDARD'),
        ['MOTORCYCLE', 'BICYCLE'],
      );
    });

    test('returns exact English LTR and Arabic RTL display labels', () {
      const expectedEn = {
        'MOTORCYCLE': 'Motorcycle',
        'CAR': 'Private Car',
        'MINIBUS': 'Minibus',
        'TUK_TUK': 'Tuk-tuk',
        'MOTOR_TRICYCLE': 'Tricycle',
        'QUARTER_TRUCK': 'Quarter-ton Pickup Truck',
        'HALF_TRUCK': 'Half-ton Pickup Truck',
        'BICYCLE': 'Bicycle',
      };
      const expectedAr = {
        'MOTORCYCLE': 'موتوسيكل',
        'CAR': 'سيارة خاصة',
        'MINIBUS': 'سيارة ميكروباص',
        'TUK_TUK': 'توكتوك',
        'MOTOR_TRICYCLE': 'تروسيكل',
        'QUARTER_TRUCK': 'شاحنة ربع نقل',
        'HALF_TRUCK': 'شاحنة نص نقل',
        'BICYCLE': 'دراجة هوائية',
      };

      for (final entry in expectedEn.entries) {
        expect(
          VehicleTypeHelper.label(entry.key, isArabic: false),
          entry.value,
        );
        expect(
          VehicleTypeHelper.label(entry.key, isArabic: true),
          expectedAr[entry.key],
        );
      }
    });

    test('rejects removed VAN and TRUCK enum values on normalize', () {
      expect(VehicleTypeHelper.normalize('VAN'), isNull);
      expect(VehicleTypeHelper.normalize('TRUCK'), isNull);
      expect(VehicleTypeHelper.normalize('tuk_tuk'), 'TUK_TUK');
      expect(VehicleTypeHelper.normalize('quarter_truck'), 'QUARTER_TRUCK');
      expect(VehicleTypeHelper.normalize('half_truck'), 'HALF_TRUCK');
    });

    test('enforces exact service and requestedVehicleType eligibility', () {
      // Ride matching
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'RIDE',
          driverVehicleType: 'TUK_TUK',
          requestedVehicleType: 'TUK_TUK',
        ),
        isTrue,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'RIDE',
          driverVehicleType: 'CAR',
          requestedVehicleType: 'TUK_TUK',
        ),
        isFalse,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'RIDE',
          driverVehicleType: 'QUARTER_TRUCK',
          requestedVehicleType: 'QUARTER_TRUCK',
        ),
        isFalse,
      );

      // Custom delivery matching
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'CUSTOM_DELIVERY',
          driverVehicleType: 'HALF_TRUCK',
          requestedVehicleType: 'HALF_TRUCK',
        ),
        isTrue,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'CUSTOM_DELIVERY',
          driverVehicleType: 'CAR',
          requestedVehicleType: 'CAR',
        ),
        isFalse,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'CUSTOM_DELIVERY',
          driverVehicleType: 'BICYCLE',
        ),
        isFalse,
      );

      // Standard matching
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'STANDARD',
          driverVehicleType: 'BICYCLE',
        ),
        isTrue,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'STANDARD',
          driverVehicleType: 'MOTORCYCLE',
        ),
        isTrue,
      );
      expect(
        VehicleTypeHelper.isEligibleForOrder(
          orderType: 'STANDARD',
          driverVehicleType: 'MINIBUS',
        ),
        isFalse,
      );
    });
  });
}
