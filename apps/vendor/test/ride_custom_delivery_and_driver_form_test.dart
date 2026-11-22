import 'package:core/core.dart' show VehicleTypeHelper;
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/features/drivers/presentation/widgets/driver_form_dialog.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeSuperAdminAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'SUPER_ADMIN';

  @override
  Future<List<String>> getUserPermissions() async => const [
    'MANAGE_ORDERS',
    'MANAGE_DRIVERS',
  ];

  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeAdminOrdersNotifier extends OrdersNotifier {
  _FakeAdminOrdersNotifier(this._orders);
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

void main() {
  testWidgets(
    'Admin OrdersScreen renders Ride & Custom Delivery with fare breakdown and Cancel action instead of Store Food Subtotal / Start Preparing',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rideOrder = <String, dynamic>{
        'id': 'ord-ride-1',
        'orderNumber': 'ORD-R101',
        'type': 'RIDE',
        'status': 'LOOKING_FOR_DRIVER',
        'requestedVehicleType': 'MOTORCYCLE',
        'paymentMethod': 'CASH_ON_DELIVERY',
        'subtotal': 0.0,
        'deliveryFee': 35.0,
        'serviceFee': 5.0,
        'tax': 0.0,
        'grandTotal': 40.0,
        'distanceKm': 4.2,
        'pickupAddress': 'Maadi Corniche',
        'deliveryAddress': 'Downtown Cairo',
        'createdAt': '2026-11-22T01:00:00Z',
        'customer': {
          'user': {'name': 'Omar Rider', 'phone': '+201132123398'},
        },
        'vendorFulfillments': <dynamic>[],
        'items': <dynamic>[],
        'financials': {
          'viewRole': 'ADMIN',
          'deliveryFee': 35.0,
          'driverEarnings': 32.0,
          'isPrepaid': false,
          'storePayments': <dynamic>[],
        },
      };

      final customDeliveryOrder = <String, dynamic>{
        'id': 'ord-custom-1',
        'orderNumber': 'ORD-C202',
        'type': 'CUSTOM_DELIVERY',
        'status': 'DRIVER_ASSIGNED',
        'requestedVehicleType': 'HALF_TRUCK',
        'paymentMethod': 'MOBILE_WALLET',
        'subtotal': 0.0,
        'deliveryFee': 120.0,
        'serviceFee': 10.0,
        'tax': 0.0,
        'grandTotal': 130.0,
        'distanceKm': 8.5,
        'pickupAddress': 'Nasr City Warehouse',
        'deliveryAddress': 'New Cairo Hub',
        'itemDetails': 'Office furniture boxes',
        'createdAt': '2026-11-22T01:15:00Z',
        'customer': {
          'user': {'name': 'Mona Sender', 'phone': '+201099887766'},
        },
        'vendorFulfillments': <dynamic>[],
        'items': <dynamic>[],
        'financials': {
          'viewRole': 'ADMIN',
          'deliveryFee': 120.0,
          'driverEarnings': 110.0,
          'isPrepaid': true,
          'storePayments': <dynamic>[],
        },
      };

      final notifier = _FakeAdminOrdersNotifier([
        rideOrder,
        customDeliveryOrder,
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedAuthRepositoryProvider.overrideWithValue(
              _FakeSuperAdminAuthRepo(),
            ),
            ordersProvider.overrideWith(() => notifier),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: OrdersScreen()),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand the Ride card
      await tester.tap(find.text('#ORD-R101'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ride Fare Breakdown'), findsOneWidget);
      expect(find.text('Total Ride Fare'), findsOneWidget);
      expect(find.text('Driver collects fare from passenger'), findsOneWidget);
      expect(find.text('Cancel Ride'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Must NEVER render store-order elements for a Ride
      expect(find.text('Start Preparing'), findsNothing);
      expect(find.text('Store Food Subtotal'), findsNothing);
      expect(find.text('Net Store Payout'), findsNothing);
      expect(find.text('Collect cash from driver upon pickup'), findsNothing);
      expect(find.text('Delivery Address'), findsNothing);

      // Collapse Ride and expand Custom Delivery
      await tester.tap(find.text('#ORD-R101'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('#ORD-C202'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Custom Delivery Fare Breakdown'), findsOneWidget);
      expect(find.text('Total Delivery Fare'), findsOneWidget);
      expect(find.text('Paid via Mobile Wallet'), findsOneWidget);
      expect(find.text('Cancel Delivery'), findsOneWidget);
      expect(find.text('Office furniture boxes'), findsOneWidget);

      // Must NEVER render store-order elements for Custom Delivery
      expect(find.text('Start Preparing'), findsNothing);
      expect(find.text('Store Food Subtotal'), findsNothing);
      expect(find.text('Net Store Payout'), findsNothing);
      expect(find.text('Collect cash from driver upon pickup'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DriverFormDialog Vehicle Type dropdown displays only ONE vehicle icon in closed field',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final driver = DriverProfile(
        id: 'drv-1',
        userId: 'user-drv-1',
        name: 'Kareem Driver',
        vehicleType: VehicleTypeHelper.halfTruck,
        vehiclePlate: 'س ص 4412',
        status: 'ONLINE',
        isSuspended: false,
        isApproved: true,
        walletBalance: 0.0,
        user: const {
          'email': 'kareem@otlob.test',
          'phone': '+201001122334',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DriverFormDialog(
                driver: driver,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final vehicleDropdown = find.ancestor(
        of: find.text('Half-ton Pickup Truck'),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(vehicleDropdown, findsOneWidget);

      // Exactly 1 vehicle icon (the prefix icon), NOT 2 duplicate icons!
      final truckIconsInsideDropdown = find.descendant(
        of: vehicleDropdown,
        matching: find.byIcon(VehicleTypeHelper.icon(VehicleTypeHelper.halfTruck)),
      );
      expect(truckIconsInsideDropdown, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
