import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVendorAuthRepository extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'SUPER_ADMIN';

  @override
  Future<List<String>> getUserPermissions() async => const [
        'MANAGE_ORDERS',
        'MANAGE_DRIVERS',
        'MANAGE_VENDORS',
      ];

  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeOrdersNotifier extends OrdersNotifier {
  _FakeOrdersNotifier(this._orders);

  final List<dynamic> _orders;

  @override
  AsyncValue<OrdersStateData> build() => AsyncValue.data(
        OrdersStateData(_orders, _orders.length, const {}),
      );

  @override
  Future<void> fetchOrders({Map<String, dynamic> params = const {}}) async {
    state = AsyncValue.data(OrdersStateData(_orders, _orders.length, params));
  }
}

Map<String, dynamic> _buildSampleCancelledOrder() {
  return <String, dynamic>{
    'id': 'ord-9001',
    'orderNumber': 'ORD-9001',
    'status': 'CANCELLED',
    'paymentMethod': 'CASH',
    'total': 245.5,
    'grandTotal': 245.5,
    'subtotal': 220.0,
    'deliveryFee': 25.5,
    'deliveryAddress': '14 Nile Corniche, Maadi',
    'createdAt': '2026-11-20T01:30:00.000Z',
    'cancellationReason': 'Kitchen equipment failure',
    'cancelledAt': '2026-11-20T01:45:00.000Z',
    'cancelledBy': <String, dynamic>{
      'id': 'usr-vendor-mgr',
      'name': 'Chef Karim',
      'nameAr': 'الشيف كريم',
      'role': 'VENDOR_MEMBER',
      'avatar': '/media/avatars/chef-karim.webp',
      'vendorId': 'vendor-1',
    },
    'customer': <String, dynamic>{
      'id': 'cust-1',
      'name': 'Nour El-Din',
      'phone': '+201001234567',
      'avatar': '/media/avatars/nour.webp',
      'user': <String, dynamic>{
        'id': 'usr-cust-1',
        'name': 'Nour El-Din',
        'phone': '+201001234567',
        'avatar': '/media/avatars/nour.webp',
      },
    },
    'driver': <String, dynamic>{
      'id': 'drv-1',
      'name': 'Tarek Hassan',
      'avatar': '/media/avatars/tarek.webp',
      'user': <String, dynamic>{
        'id': 'usr-drv-1',
        'name': 'Tarek Hassan',
        'phone': '+201112223334',
        'avatar': '/media/avatars/tarek.webp',
      },
    },
    'vendor': <String, dynamic>{
      'id': 'vendor-1',
      'storeName': 'Cairo Grill House',
      'storeNameAr': 'مشويات القاهرة',
      'logo': '/media/logos/cairo-grill.webp',
    },
    'vendorFulfillments': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'ful-1',
        'status': 'CANCELLED',
        'vendor': <String, dynamic>{
          'id': 'vendor-1',
          'storeName': 'Cairo Grill House',
          'storeNameAr': 'مشويات القاهرة',
          'logo': '/media/logos/cairo-grill.webp',
        },
        'vendorBranch': <String, dynamic>{
          'name': 'Maadi Branch',
          'nameAr': 'فرع المعادي',
          'address': 'Maadi',
          'phone': '+201099887766',
        },
        'items': <Map<String, dynamic>>[],
      },
    ],
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'item-1',
        'productName': 'Mixed Grill Platter',
        'productNameAr': 'طبق مشويات مشكل',
        'quantity': 1,
        'price': 220.0,
      },
    ],
    'statusEvents': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'evt-prep-1',
        'status': 'PREPARING',
        'eventKey': 'preparing:ful-1',
        'note': 'Delivery 1: vendor portion started preparing',
        'createdAt': '2026-11-20T01:32:00.000Z',
        'actor': <String, dynamic>{
          'id': 'usr-vendor-1',
          'name': 'Cairo Grill House',
          'nameAr': 'مشويات القاهرة',
          'role': 'VENDOR_MEMBER',
          'avatar': '/media/logos/cairo-grill.webp',
        },
      },
      // Duplicate emission of the exact same eventKey should collapse to 1 row
      <String, dynamic>{
        'id': 'evt-prep-1-dup',
        'status': 'PREPARING',
        'eventKey': 'preparing:ful-1',
        'note': 'Delivery 1: vendor portion started preparing',
        'createdAt': '2026-11-20T01:32:01.000Z',
        'actor': <String, dynamic>{
          'id': 'usr-vendor-1',
          'name': 'Cairo Grill House',
          'nameAr': 'مشويات القاهرة',
          'role': 'VENDOR_MEMBER',
          'avatar': '/media/logos/cairo-grill.webp',
        },
      },
      // Separate legitimate PREPARING event (vendor 2 / different eventKey) MUST remain
      <String, dynamic>{
        'id': 'evt-prep-2',
        'status': 'PREPARING',
        'eventKey': 'preparing:ful-2',
        'note': 'Delivery 2: vendor portion ready for pickup',
        'createdAt': '2026-11-20T01:36:00.000Z',
        'actor': <String, dynamic>{
          'id': 'usr-vendor-2',
          'name': 'Nile Bakery',
          'nameAr': 'مخبز النيل',
          'role': 'VENDOR_MEMBER',
          'avatar': '/media/logos/nile-bakery.webp',
        },
      },
      <String, dynamic>{
        'id': 'evt-cancel',
        'status': 'CANCELLED',
        'eventKey': 'cancelled:ord-9001',
        'note': 'Kitchen equipment failure',
        'createdAt': '2026-11-20T01:45:00.000Z',
        'actor': <String, dynamic>{
          'id': 'usr-vendor-mgr',
          'name': 'Chef Karim',
          'nameAr': 'الشيف كريم',
          'role': 'VENDOR_MEMBER',
          'avatar': '/media/avatars/chef-karim.webp',
        },
      },
    ],
  };
}

Future<void> _pumpOrdersScreen(
  WidgetTester tester, {
  required Locale locale,
  required List<dynamic> orders,
  Size viewport = const Size(360, 760),
  double textScale = 1.3,
}) async {
  FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewPadding();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedAuthRepositoryProvider.overrideWithValue(
          _FakeVendorAuthRepository(),
        ),
        ordersProvider.overrideWith(() => _FakeOrdersNotifier(orders)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const AppWindowConstraintGuard(
            child: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: OrdersScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // OrdersScreen has a repeating _LivePulseDot animation, so pump frames instead of pumpAndSettle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    final isArabic = locale.languageCode == 'ar';

    testWidgets(
      'OrdersScreen (${locale.languageCode}) renders Customer/Driver/Vendor avatars, accurate cancellation attribution, and deduped timeline at 360px / 1.3x',
      (tester) async {
        await _pumpOrdersScreen(
          tester,
          locale: locale,
          orders: [_buildSampleCancelledOrder()],
        );

        expect(tester.takeException(), isNull);

        // Collapsed order card shows Order number, Customer name, Store name, and AppNetworkAvatars.
        expect(find.textContaining('ORD-9001'), findsOneWidget);
        expect(find.text('Nour El-Din'), findsWidgets);
        expect(find.byType(AppNetworkAvatar), findsWidgets);

        // Tap order header to expand details.
        await tester.ensureVisible(find.text('#ORD-9001'));
        await tester.tap(find.text('#ORD-9001'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(tester.takeException(), isNull);

        // Expanded details show Driver name + cancellation attribution + reason.
        expect(find.textContaining('Tarek Hassan'), findsWidgets);
        expect(
          find.text(
            isArabic
                ? 'تم الإلغاء بواسطة الشيف كريم'
                : 'Canceled by Chef Karim',
          ),
          findsWidgets,
        );
        expect(find.textContaining('Kitchen equipment failure'), findsWidgets);

        // Duplicate 'preparing:ful-1' event collapsed to 1 row while separate 'preparing:ful-2' remains.
        expect(
          find.text(
            isArabic
                ? 'التوصيل 1: بدأ vendor في التجهيز'
                : 'Delivery 1: vendor portion started preparing',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            isArabic
                ? 'التوصيل 2: طلب vendor جاهز للاستلام'
                : 'Delivery 2: vendor portion ready for pickup',
          ),
          findsOneWidget,
        );

        // Never falls back to vague "Canceled by user" / "تم الإلغاء بواسطة المستخدم".
        expect(find.textContaining('Canceled by user'), findsNothing);
        expect(find.textContaining('تم الإلغاء بواسطة المستخدم'), findsNothing);
      },
    );
  }
}
