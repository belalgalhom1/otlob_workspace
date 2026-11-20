import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVendorMemberAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'VENDOR_MEMBER';

  @override
  Future<List<String>> getUserPermissions() async => const [];

  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeOrdersNotifier extends OrdersNotifier {
  _FakeOrdersNotifier(this._orders);
  List<dynamic> _orders;

  @override
  AsyncValue<OrdersStateData> build() => AsyncValue.data(
        OrdersStateData(_orders, _orders.length, const {}),
      );

  @override
  Future<void> fetchOrders({Map<String, dynamic> params = const {}}) async {
    state = AsyncValue.data(OrdersStateData(_orders, _orders.length, params));
  }

  void pushUpdatedOrders(List<dynamic> next) {
    _orders = next;
    state = AsyncValue.data(OrdersStateData(_orders, _orders.length, const {}));
  }
}

void main() {
  testWidgets(
    'Vendor OrdersScreen renders vendor logo, assigned driver avatar (updating on driver change), and all product images with fallbacks',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final ordersNotifier = _FakeOrdersNotifier([
        {
          'id': 'ord-v-1',
          'orderNumber': 'ORD-V1',
          'status': 'DRIVER_ASSIGNED',
          'myFulfillmentId': 'ff-mine',
          'myFulfillmentStatus': 'PREPARING',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 180.0,
          'grandTotal': 180.0,
          'deliveryAddress': '10 El Tahrir Sq',
          'createdAt': '2026-11-20T09:00:00Z',
          'customer': {
            'user': {
              'name': 'Salma',
              'phone': '01001112233',
              'avatar': 'https://cdn.otlob-test.invalid/users/salma.png',
            },
          },
          'vendor': {
            'id': 'v-mine',
            'storeName': 'Koshary Corner',
            'storeNameAr': 'كشري كورنر',
            'logo': 'https://cdn.otlob-test.invalid/vendors/koshary.png',
          },
          'vendorBranch': {
            'name': 'Dokki',
            'address': 'Dokki St',
            'phone': '01099998888',
            'isContracted': true,
          },
          'vendorFulfillments': [
            {
              'id': 'ff-mine',
              'vendorId': 'v-mine',
              'status': 'PREPARING',
              'subtotal': 180.0,
              'vendor': {
                'id': 'v-mine',
                'storeName': 'Koshary Corner',
                'logo': 'https://cdn.otlob-test.invalid/vendors/koshary.png',
              },
              'vendorBranch': {'name': 'Dokki', 'isContracted': true},
            },
          ],
          'driver': {
            'id': 'drv-1',
            'name': 'Hassan Captain',
            'avatar': 'https://cdn.otlob-test.invalid/drivers/hassan.png',
            'vehicleType': 'MOTORCYCLE',
            'user': {'phone': '01122334455'},
          },
          'items': [
            {
              'id': 'item-1',
              'fulfillmentId': 'ff-mine',
              'productName': 'Large Koshary',
              'quantity': 2,
              'unitPrice': 60.0,
              'product': {
                'imageUrl': 'https://cdn.otlob-test.invalid/products/koshary-lg.png',
              },
            },
            {
              'id': 'item-2',
              'fulfillmentId': 'ff-mine',
              'productName': 'Rice Pudding',
              'quantity': 1,
              'unitPrice': 60.0,
              'product': {'imageUrl': null},
            },
          ],
        },
      ]);

      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedAuthRepositoryProvider
                .overrideWithValue(_FakeVendorMemberAuthRepo()),
            ordersProvider.overrideWith(() => ordersNotifier),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrdersScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand order card to inspect driver + vendor logo + all items
      await tester.tap(find.text('#ORD-V1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Hassan Captain'), findsOneWidget);
      var urls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(
        urls,
        containsAll([
          'https://cdn.otlob-test.invalid/vendors/koshary.png',
          'https://cdn.otlob-test.invalid/drivers/hassan.png',
          'https://cdn.otlob-test.invalid/products/koshary-lg.png',
          'https://cdn.otlob-test.invalid/users/salma.png',
        ]),
      );
      // Missing product image displays package fallback icon without exception
      expect(find.byIcon(LucideIcons.package), findsWidgets);

      // Reassign driver -> verify new driver's picture replaces old one
      final currentOrder = Map<String, dynamic>.from(
        ordersNotifier.state.value!.orders.first as Map,
      );
      currentOrder['driver'] = {
        'id': 'drv-2',
        'name': 'Mahmoud Driver',
        'avatar': null,
        'user': {
          'phone': '01234567890',
          'avatar': 'https://cdn.otlob-test.invalid/drivers/mahmoud.png',
        },
      };
      ordersNotifier.pushUpdatedOrders([currentOrder]);
      await tester.pump();

      expect(find.textContaining('Mahmoud Driver'), findsOneWidget);
      urls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(
        urls,
        contains('https://cdn.otlob-test.invalid/drivers/mahmoud.png'),
      );
      expect(
        urls,
        isNot(contains('https://cdn.otlob-test.invalid/drivers/hassan.png')),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
