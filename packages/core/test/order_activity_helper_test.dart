import 'package:core/core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_URL=https://api.otlob.test\nWS_URL=wss://api.otlob.test',
    );
  });

  group('OrderActivityHelper.resolveCancelledBy & headlines', () {
    test('prefers structured cancelledBy payload with actor details and avatar', () {
      final order = <String, dynamic>{
        'id': 'ord-1',
        'status': 'CANCELLED',
        'cancelledBy': {
          'userId': 'u-cust',
          'name': 'Mona Tarek',
          'role': 'CUSTOMER',
          'avatar': '/media/avatars/mona.webp',
          'reason': 'Ordered wrong branch',
          'cancelledAt': '2026-11-20T03:00:00.000Z',
          'isSystem': false,
        },
      };

      final actor = OrderActivityHelper.resolveCancelledBy(order);
      expect(actor, isNotNull);
      expect(actor!.displayName(isArabic: false), 'Mona Tarek');
      expect(actor.role, 'CUSTOMER');
      expect(actor.reason, 'Ordered wrong branch');
      expect(actor.resolvedAvatarUrl, isNotNull);
      expect(
        OrderActivityHelper.formatCanceledByHeadline(actor, isArabic: false),
        'Canceled by Mona Tarek',
      );
      expect(
        OrderActivityHelper.formatCanceledByHeadline(actor, isArabic: true),
        'تم الإلغاء بواسطة Mona Tarek',
      );
    });

    test('falls back to localized role when name is generic user or empty', () {
      final actor = OrderActivityHelper.resolveCancelledBy(<String, dynamic>{
        'status': 'CANCELLED',
        'cancelledByName': 'user',
        'cancelledByRole': 'SUPER_ADMIN',
      });
      expect(actor, isNotNull);
      expect(actor!.displayName(isArabic: false), 'Super Admin');
      expect(actor.displayName(isArabic: true), 'المدير العام');
    });

    test('resolves Arabic vendor store name for vendor cancellations', () {
      final actor = OrderActivityHelper.resolveCancelledBy(<String, dynamic>{
        'status': 'CANCELLED',
        'cancelledBy': {
          'name': 'Al Baik Grill',
          'nameAr': 'مشويات البيك',
          'role': 'VENDOR_MEMBER',
          'avatar': '/media/logos/baik.webp',
        },
      });
      expect(actor, isNotNull);
      expect(
        OrderActivityHelper.formatCanceledByHeadline(actor!, isArabic: true),
        'تم الإلغاء بواسطة مشويات البيك',
      );
    });
  });

  group('OrderActivityHelper.normalizeTimelineEvents', () {
    test('preserves legitimate multiple events with the same status while deduping identical id/eventKey', () {
      final raw = [
        {
          'id': 'ev-1',
          'eventKey': 'preparing:ful-1',
          'status': 'PREPARING',
          'note': 'Delivery 1: Store A portion started preparing',
          'createdAt': '2026-11-20T03:56:00.000Z',
        },
        {
          'id': 'ev-2',
          'eventKey': 'preparing:ful-1',
          'status': 'PREPARING',
          'note': 'Delivery 1: Store A portion started preparing',
          'createdAt': '2026-11-20T03:56:01.000Z',
        },
        {
          'id': 'ev-3',
          'eventKey': 'ready:ful-1',
          'status': 'PREPARING',
          'note': 'Delivery 1: Store A portion ready for pickup',
          'createdAt': '2026-11-20T03:57:00.000Z',
        },
        {
          'id': 'ev-4',
          'eventKey': 'pickup-stop:grp-1:ful-1',
          'status': 'PICKED_UP',
          'note': 'Driver picked up fulfillment stop Store A',
          'createdAt': '2026-11-20T03:58:00.000Z',
        },
        {
          'id': 'ev-5',
          'eventKey': 'all-picked-up:grp-1',
          'status': 'PICKED_UP',
          'note': 'All deliveries picked up',
          'createdAt': '2026-11-20T03:59:00.000Z',
        },
      ];

      final normalized = OrderActivityHelper.normalizeTimelineEvents(
        raw,
        newestFirst: true,
      );

      expect(normalized.length, 4);
      expect(normalized.map((e) => e['id']), ['ev-5', 'ev-4', 'ev-3', 'ev-1']);
    });
  });

  group('OrderActivityHelper.formatEventNote', () {
    test('replaces legacy Cancelled by user when actor is known and translates Arabic notes', () {
      const actor = OrderActorInfo(
        name: 'Tamer Admin',
        role: 'ADMIN',
      );

      expect(
        OrderActivityHelper.formatEventNote(
          'Cancelled by user',
          status: 'CANCELLED',
          actor: actor,
          isArabic: false,
        ),
        'Canceled by Tamer Admin',
      );
      expect(
        OrderActivityHelper.formatEventNote(
          'All vendor portions ready for pickup',
          status: 'READY_FOR_PICKUP',
          isArabic: true,
        ),
        'جميع أجزاء الطلب جاهزة للاستلام',
      );
    });
  });
}
