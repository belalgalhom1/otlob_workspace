import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('OrderTypeHelper', () {
    test('distinguishes RIDE, CUSTOM_DELIVERY, and STANDARD explicitly', () {
      expect(OrderTypeHelper.resolve({'type': 'RIDE'}), AppOrderType.ride);
      expect(
        OrderTypeHelper.resolve({'type': 'CUSTOM_DELIVERY'}),
        AppOrderType.customDelivery,
      );
      expect(
        OrderTypeHelper.resolve({'type': 'STANDARD'}),
        AppOrderType.standard,
      );
      expect(OrderTypeHelper.isRide({'type': 'RIDE', 'pickupAddress': 'A'}), isTrue);
      expect(
        OrderTypeHelper.isCustomDelivery({'type': 'RIDE', 'pickupAddress': 'A'}),
        isFalse,
      );
    });

    test('requires proof photos for STANDARD and CUSTOM_DELIVERY, never for RIDE', () {
      expect(OrderTypeHelper.requiresOrderPhotos({'type': 'STANDARD'}), isTrue);
      expect(
        OrderTypeHelper.requiresOrderPhotos({'type': 'CUSTOM_DELIVERY'}),
        isTrue,
      );
      expect(OrderTypeHelper.requiresOrderPhotos({'type': 'RIDE'}), isFalse);
      expect(OrderTypeHelper.requiresOrderPhotos('RIDE'), isFalse);
    });

    test('hides activity log for RIDE and store fulfillment sections for non-standard', () {
      expect(OrderTypeHelper.shouldShowActivityLogOnTracking('RIDE'), isFalse);
      expect(
        OrderTypeHelper.shouldShowActivityLogOnTracking('CUSTOM_DELIVERY'),
        isTrue,
      );
      expect(OrderTypeHelper.shouldShowActivityLogOnTracking('STANDARD'), isTrue);

      expect(OrderTypeHelper.shouldShowStoreFulfillmentSections('RIDE'), isFalse);
      expect(
        OrderTypeHelper.shouldShowStoreFulfillmentSections('CUSTOM_DELIVERY'),
        isFalse,
      );
      expect(
        OrderTypeHelper.shouldShowStoreFulfillmentSections('STANDARD'),
        isTrue,
      );
    });

    test('formats customer card titles and status labels cleanly in EN and AR', () {
      final rideOrder = {'type': 'RIDE', 'status': 'PICKED_UP'};
      expect(
        OrderTypeHelper.customerCardTitle(
          rideOrder,
          isArabic: false,
          vendorFallback: 'Vendor',
        ),
        'Ride',
      );
      expect(
        OrderTypeHelper.customerCardTitle(
          rideOrder,
          isArabic: true,
          vendorFallback: 'البائع',
        ),
        'رحلة',
      );
      expect(
        OrderTypeHelper.customerStatusLabel(
          AppOrderType.ride,
          'PICKED_UP',
          isArabic: false,
        ),
        'Ride in Progress',
      );
      expect(
        OrderTypeHelper.customerStatusLabel(
          AppOrderType.ride,
          'PICKED_UP',
          isArabic: true,
        ),
        'الرحلة قيد التنفيذ',
      );
      expect(
        OrderTypeHelper.customerStatusLabel(
          AppOrderType.customDelivery,
          'PENDING',
          isArabic: true,
        ),
        'تم إرسال الطلب',
      );
    });

    test('OrderActivityHelper translates backend Ride transition notes', () {
      expect(
        OrderActivityHelper.formatEventNote(
          'Ride 1: READY_FOR_PICKUP → PICKED_UP',
          isArabic: true,
        ),
        'بدأت الرحلة',
      );
      expect(
        OrderActivityHelper.formatEventNote(
          'Ride 1: PICKED_UP → DELIVERED',
          isArabic: true,
        ),
        'اكتملت الرحلة',
      );
    });
  });
}
