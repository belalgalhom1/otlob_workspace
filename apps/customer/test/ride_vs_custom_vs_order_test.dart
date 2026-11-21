import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart' show AppOrderType, OrderTypeHelper, baseUrlProvider;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/services/socket_service.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/orders/presentation/pages/orders_screen.dart';
import 'package:otlob_customer/features/orders/presentation/providers/orders_provider.dart';
import 'package:otlob_customer/features/orders/presentation/widgets/order_tracking_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CatalogAssetLoader extends AssetLoader {
  const _CatalogAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final code = locale.languageCode;
    final p1 = '../../packages/core/assets/translations/$code.json';
    final p2 = 'packages/core/assets/translations/$code.json';
    final file = File(File(p1).existsSync() ? p1 : p2);
    if (!file.existsSync()) return {};
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

class _FakeSocketService extends Fake implements SocketService {
  final _ctrl = StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> onEvent(String event) => _ctrl.stream;
}

class _FakeCart extends Cart {
  @override
  CartState build() => const CartState(vendorBaskets: <String, List<CartItem>>{});
}

class _FakeOrders extends Orders {
  final OrdersState initialState;
  _FakeOrders(this.initialState);

  @override
  OrdersState build() => initialState;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMoreActive() async {}

  @override
  Future<void> loadMorePast() async {}
}

Map<String, dynamic> _rideOrder({
  String status = 'DELIVERED',
  bool cancelled = false,
}) =>
    {
      'id': cancelled ? 'ord-ride-cancel' : 'ord-ride-1',
      'orderNumber': cancelled ? 'OTL-RC1' : 'OTL-R1',
      'type': 'RIDE',
      'status': cancelled ? 'CANCELLED' : status,
      'pickupAddress': 'Pickup Location: Location selected',
      'deliveryAddress': 'Dropoff Location: Location selected',
      'subtotal': 0.0,
      'deliveryFee': 20.0,
      'serviceFee': 10.0,
      'grandTotal': cancelled ? 10.0 : 30.0,
      'driver': {
        'id': 'drv-1',
        'name': 'Captain Kareem',
        'vehiclePlate': 'ABC 123',
      },
      'customer': {
        'id': 'cust-1',
        'name': 'belalgalhom',
      },
      if (cancelled)
        'cancellation': {
          'actorName': 'belalgalhom',
          'actorRole': 'CUSTOMER',
        },
      'statusEvents': [
        {
          'status': 'PENDING',
          'note': 'Order placed',
          'createdAt': '2026-11-21T03:30:00.000Z',
        },
        {
          'status': cancelled ? 'CANCELLED' : status,
          'note': cancelled ? 'Cancelled by customer' : 'Ride 1: READY_FOR_PICKUP → PICKED_UP',
          'createdAt': '2026-11-21T03:34:00.000Z',
        },
      ],
      'vendorFulfillments': const [],
      'items': const [],
    };

Map<String, dynamic> _customOrder({String status = 'PICKED_UP'}) => {
      'id': 'ord-custom-1',
      'orderNumber': 'OTL-C1',
      'type': 'CUSTOM_DELIVERY',
      'status': status,
      'pickupAddress': 'Maadi St 9',
      'deliveryAddress': 'Zamalek',
      'itemDetails': 'Sealed legal envelope',
      'subtotal': 0.0,
      'deliveryFee': 35.0,
      'grandTotal': 35.0,
      'vendorFulfillments': const [],
      'items': const [],
      'statusEvents': [
        {
          'status': 'PENDING',
          'note': 'Request submitted',
          'createdAt': '2026-11-21T03:20:00.000Z',
        },
        {
          'status': 'PICKED_UP',
          'note': 'Picked up package',
          'createdAt': '2026-11-21T03:28:00.000Z',
        },
      ],
    };

Map<String, dynamic> _standardOrder() => {
      'id': 'ord-std-1',
      'orderNumber': 'OTL-S1',
      'type': 'STANDARD',
      'status': 'PREPARING',
      'subtotal': 120.0,
      'deliveryFee': 15.0,
      'grandTotal': 135.0,
      'vendor': {'id': 'v-1', 'storeName': 'Koshary El Tahrir'},
      'vendorFulfillments': [
        {
          'id': 'ff-1',
          'status': 'PREPARING',
          'vendor': {'storeName': 'Koshary El Tahrir'},
        },
      ],
      'items': [
        {'quantity': 1, 'productName': 'Large Koshary', 'price': 120.0},
      ],
      'statusEvents': [
        {
          'status': 'PREPARING',
          'note': 'Order is being prepared',
          'createdAt': '2026-11-21T03:25:00.000Z',
        },
      ],
    };

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
  Size size = const Size(360, 740),
  double textScale = 1.0,
  List<dynamic> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        assetLoader: const _CatalogAssetLoader(),
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        child: Builder(
          builder: (ctx) => MaterialApp(
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: locale,
            builder: (_, appChild) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: appChild!,
            ),
            home: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'OrdersScreen distinguishes RIDE vs CUSTOM_DELIVERY vs STANDARD across Active and Past tabs without Vendor/Custom Delivery mislabeling',
    (tester) async {
      final state = OrdersState(
        isLoading: false,
        activeOrders: [
          _rideOrder(status: 'DRIVER_ASSIGNED'),
          _standardOrder(),
        ],
        pastOrders: [
          _rideOrder(status: 'DELIVERED'),
          _rideOrder(cancelled: true),
          _customOrder(status: 'DELIVERED'),
        ],
      );

      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        size: const Size(360, 780),
        textScale: 1.2,
        overrides: [
          baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
          ordersProvider.overrideWith(() => _FakeOrders(state)),
          cartProvider.overrideWith(_FakeCart.new),
          socketServiceProvider.overrideWithValue(_FakeSocketService()),
        ],
        child: const OrdersScreen(),
      );

      // Active tab checks:
      expect(find.text('Ride'), findsOneWidget);
      expect(find.textContaining('Passenger Ride'), findsOneWidget);
      expect(find.text('Track Ride'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Koshary El Tahrir'),
        120,
        scrollable: find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Koshary El Tahrir'), findsOneWidget);

      // Switch to Past Orders tab:
      await tester.tap(find.text('Past Orders'));
      await tester.pumpAndSettle();

      expect(find.text('Ride'), findsWidgets);
      expect(find.text('Vendor'), findsNothing);
      expect(find.text('Ride Fare'), findsOneWidget);
      expect(find.text('Rate Ride'), findsOneWidget);
      expect(find.textContaining('Current Subtotal (Excl. delivery)'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Custom Delivery'),
        120,
        scrollable: find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom Delivery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OrdersScreen cancel modal for RIDE shows ride reasons and never store reasons',
    (tester) async {
      final state = OrdersState(
        isLoading: false,
        activeOrders: [_rideOrder(status: 'LOOKING_FOR_DRIVER')],
        pastOrders: const [],
      );

      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        overrides: [
          baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
          ordersProvider.overrideWith(() => _FakeOrders(state)),
          cartProvider.overrideWith(_FakeCart.new),
          socketServiceProvider.overrideWithValue(_FakeSocketService()),
        ],
        child: const OrdersScreen(),
      );

      await tester.tap(find.text('Cancel Search'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Ride'), findsOneWidget);
      expect(find.text('Found another ride'), findsOneWidget);
      expect(find.text('Forgot to add item'), findsNothing);
      expect(find.text('Prep time too long'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OrderTrackingSheetOverlay hides Activity Log for RIDE and hides store fulfillment sections for CUSTOM_DELIVERY',
    (tester) async {
      // 1. RIDE tracking sheet: Activity Log MUST NOT be visible
      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        size: const Size(360, 740),
        child: Scaffold(
          key: UniqueKey(),
          body: OrderTrackingSheetOverlay(
            orderStatus: 'PICKED_UP',
            statusLabel: OrderTypeHelper.customerStatusLabel(
              AppOrderType.ride,
              'PICKED_UP',
              isArabic: false,
            ),
            orderDetails: _rideOrder(status: 'PICKED_UP'),
            tripPathLength: 2,
            followDriver: true,
            onRecenterDriver: () {},
            onOpenChat: () {},
            onRateOrder: () {},
          ),
        ),
      );

      // Expand sheet to reveal full body sections
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ride Status'), findsOneWidget);
      expect(find.text('Ride Details'), findsOneWidget);
      expect(find.text('Chat with Driver'), findsOneWidget);
      expect(find.text('Rate Ride'), findsOneWidget);
      // Order Activity Log section & icon MUST be absent on RIDE
      expect(find.text('Order Updates'), findsNothing);
      expect(find.byIcon(Icons.history_rounded), findsNothing);
      expect(find.byIcon(Icons.storefront_rounded), findsNothing);

      // 2. CUSTOM_DELIVERY tracking sheet: Store Fulfillment MUST NOT appear,
      // and PENDING event renders as "Request Submitted" (never "Pending Vendor").
      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        size: const Size(360, 740),
        child: Scaffold(
          key: UniqueKey(),
          body: OrderTrackingSheetOverlay(
            orderStatus: 'PICKED_UP',
            statusLabel: 'Picked Up',
            orderDetails: _customOrder(status: 'PICKED_UP'),
            tripPathLength: 2,
            followDriver: true,
            onRecenterDriver: () {},
            onOpenChat: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Status'), findsOneWidget);
      expect(find.text('Delivery Details'), findsOneWidget);
      expect(find.text('Sealed legal envelope'), findsOneWidget);
      expect(find.text('Order Updates'), findsOneWidget);
      expect(find.text('Request Submitted'), findsOneWidget);
      expect(find.text('Pending Vendor'), findsNothing);
      expect(find.byIcon(Icons.storefront_rounded), findsNothing);
      expect(tester.takeException(), isNull);

      // 3. AR RTL compact viewport (320x640 @ 1.3x) renders RIDE tracking sheet without overflow
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        size: const Size(320, 640),
        textScale: 1.3,
        child: Scaffold(
          key: UniqueKey(),
          body: OrderTrackingSheetOverlay(
            orderStatus: 'PICKED_UP',
            statusLabel: OrderTypeHelper.customerStatusLabel(
              AppOrderType.ride,
              'PICKED_UP',
              isArabic: true,
            ),
            orderDetails: _rideOrder(status: 'PICKED_UP'),
            tripPathLength: 2,
            followDriver: true,
            onRecenterDriver: () {},
            onOpenChat: () {},
            onRateOrder: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(OrderTrackingSheetOverlay))),
        TextDirection.rtl,
      );
      expect(find.byIcon(Icons.history_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
