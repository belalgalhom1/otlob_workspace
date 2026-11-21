import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/features/orders/presentation/widgets/assign_driver_sheet.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  _FakeAuthRepo(this._role, [this._permissions = const []]);
  final String _role;
  final List<String> _permissions;

  @override
  Future<String?> getUserRole() async => _role;

  @override
  Future<List<String>> getUserPermissions() async => _permissions;

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

class _FakeAdminDriversRepo extends Fake implements AdminDriversRepository {
  _FakeAdminDriversRepo(this._drivers);
  final List<Map<String, dynamic>> _drivers;

  @override
  Future<dynamic> getDrivers({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? zoneId,
  }) async =>
      {'drivers': _drivers, 'total': _drivers.length};
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_URL=https://api.otlob.test\nWS_URL=wss://api.otlob.test',
    );
  });

  testWidgets(
    'OrdersScreen renders assigned driver avatar (collapsed & expanded), assisting driver avatar, and default user avatar fallback when missing',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
      tester.view.physicalSize = const Size(412, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ordersNotifier = _FakeOrdersNotifier([
        // Order 1: Driver has avatar on nested user (driver.avatar is whitespace) + assistDriver with avatar
        {
          'id': 'ord-drv-1',
          'orderNumber': 'ORD-DRV-1',
          'type': 'STANDARD',
          'status': 'DRIVER_ASSIGNED',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 120.0,
          'grandTotal': 140.0,
          'deliveryAddress': 'Maadi',
          'createdAt': '2026-11-21T10:00:00Z',
          'customer': {
            'user': {'name': 'Salma', 'phone': '01001112233'},
          },
          'vendor': {
            'id': 'v-1',
            'storeName': 'Burger King',
            'logo': '/media/vendors/bk.webp',
          },
          'driver': {
            'id': 'drv-1',
            'name': 'Karim Captain',
            'avatar': '   ',
            'vehicleType': 'MOTORCYCLE',
            'vehiclePlate': 'ABC 123',
            'user': {
              'phone': '01112223344',
              'avatar': '/media/drivers/avatars/karim.webp',
            },
          },
          'assistDriver': {
            'id': 'drv-assist',
            'name': 'Youssef Helper',
            'avatar': '/media/drivers/avatars/youssef.webp',
            'vehicleType': 'BICYCLE',
            'user': {'phone': '01223334455'},
          },
          'items': const [],
        },
        // Order 2: Driver assigned with NO avatar -> must show default LucideIcons.user avatar
        {
          'id': 'ord-drv-2',
          'orderNumber': 'ORD-DRV-2',
          'type': 'STANDARD',
          'status': 'DRIVER_ASSIGNED',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 80.0,
          'grandTotal': 100.0,
          'deliveryAddress': 'Dokki',
          'createdAt': '2026-11-21T10:05:00Z',
          'customer': {
            'user': {'name': 'Mona', 'phone': '01009998877'},
          },
          'vendor': {
            'id': 'v-2',
            'storeName': 'Koshary Corner',
            'logo': '/media/vendors/kc.webp',
          },
          'driver': {
            'id': 'drv-no-pic',
            'name': 'Tarek NoPhoto',
            'avatar': null,
            'vehicleType': 'BICYCLE',
            'user': {'phone': '01555666777', 'avatar': 'null'},
          },
          'items': const [],
        },
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedAuthRepositoryProvider.overrideWithValue(
              _FakeAuthRepo('SUPER_ADMIN', ['MANAGE_ORDERS', 'MANAGE_DRIVERS']),
            ),
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

      const karimUrl = 'https://api.otlob.test/media/drivers/avatars/karim.webp';
      const youssefUrl =
          'https://api.otlob.test/media/drivers/avatars/youssef.webp';

      // Collapsed order card immediately shows assigned driver avatar & default avatar
      final collapsedDrv1 = tester.widget<AppNetworkAvatar>(
        find.byKey(const ValueKey('ord_collapsed_drv_ord-drv-1_drv-1_$karimUrl')),
      );
      expect(collapsedDrv1.imageUrl, karimUrl);
      expect(collapsedDrv1.fallbackIcon, LucideIcons.user);

      final collapsedDrv2 = tester.widget<AppNetworkAvatar>(
        find.byKey(const ValueKey('ord_collapsed_drv_ord-drv-2_drv-no-pic_')),
      );
      expect(collapsedDrv2.imageUrl, '');
      expect(collapsedDrv2.fallbackIcon, LucideIcons.user);

      // Expand Order 1 -> primary driver & assisting driver avatars render next to driver details
      await tester.ensureVisible(find.text('#ORD-DRV-1'));
      await tester.tap(find.text('#ORD-DRV-1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final expandedDrv1 = tester.widget<AppNetworkAvatar>(
        find.byKey(const ValueKey('ord_driver_avatar_ord-drv-1_drv-1_$karimUrl')),
      );
      expect(expandedDrv1.imageUrl, karimUrl);
      expect(expandedDrv1.fallbackIcon, LucideIcons.user);

      final expandedAssist = tester.widget<AppNetworkAvatar>(
        find.byKey(
          const ValueKey(
            'ord_assist_driver_avatar_ord-drv-1_drv-assist_$youssefUrl',
          ),
        ),
      );
      expect(expandedAssist.imageUrl, youssefUrl);
      expect(expandedAssist.fallbackIcon, LucideIcons.user);

      final urls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(urls, containsAll([karimUrl, youssefUrl]));

      // Expand Order 2 -> shows default LucideIcons.user avatar when no profile picture exists
      await tester.ensureVisible(find.text('#ORD-DRV-2'));
      await tester.tap(find.text('#ORD-DRV-2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final expandedDrv2 = tester.widget<AppNetworkAvatar>(
        find.byKey(const ValueKey('ord_driver_avatar_ord-drv-2_drv-no-pic_')),
      );
      expect(expandedDrv2.imageUrl, '');
      expect(expandedDrv2.fallbackIcon, LucideIcons.user);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AssignDriverSheet enforces service-specific & requested vehicle eligibility for STANDARD, RIDE, and CUSTOM_DELIVERY orders',
    (tester) async {
      final drivers = [
        {
          'id': 'd-moto',
          'name': 'Moto Rider',
          'vehicleType': 'MOTORCYCLE',
          'phone': '0101',
          'avatar': '/media/drivers/moto.webp',
        },
        {
          'id': 'd-bike',
          'name': 'Bike Rider',
          'vehicleType': 'BICYCLE',
          'phone': '0102',
          'avatar': null,
        },
        {
          'id': 'd-car',
          'name': 'Private Car Driver',
          'vehicleType': 'CAR',
          'phone': '0103',
        },
        {
          'id': 'd-minibus',
          'name': 'Minibus Driver',
          'vehicleType': 'MINIBUS',
          'phone': '0104',
        },
        {
          'id': 'd-tuktuk',
          'name': 'Tuk-tuk Driver',
          'vehicleType': 'TUK_TUK',
          'phone': '0105',
        },
        {
          'id': 'd-tri',
          'name': 'Tricycle Driver',
          'vehicleType': 'MOTOR_TRICYCLE',
          'phone': '0106',
        },
        {
          'id': 'd-quarter',
          'name': 'Quarter Pickup Driver',
          'vehicleType': 'QUARTER_TRUCK',
          'phone': '0107',
        },
        {
          'id': 'd-half',
          'name': 'Half Pickup Driver',
          'vehicleType': 'HALF_TRUCK',
          'phone': '0108',
        },
      ];

      // 1) STANDARD -> ONLY Motorcycle & Bicycle
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('std_assign_sheet'),
          overrides: [
            adminDriversRepositoryProvider
                .overrideWithValue(_FakeAdminDriversRepo(drivers)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: AssignDriverSheet(
                orderId: 'ord-std',
                orderCode: 'STD-100',
                orderType: 'STANDARD',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Moto Rider'), findsOneWidget);
      expect(find.text('Bike Rider'), findsOneWidget);
      expect(find.text('Private Car Driver'), findsNothing);
      expect(find.text('Minibus Driver'), findsNothing);
      expect(find.text('Tuk-tuk Driver'), findsNothing);
      expect(find.text('Quarter Pickup Driver'), findsNothing);
      expect(find.text('Half Pickup Driver'), findsNothing);

      // 2) RIDE with TUK_TUK -> ONLY Tuk-tuk driver
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('ride_tuktuk_assign_sheet'),
          overrides: [
            adminDriversRepositoryProvider
                .overrideWithValue(_FakeAdminDriversRepo(drivers)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: AssignDriverSheet(
                orderId: 'ord-ride',
                orderCode: 'RIDE-100',
                orderType: 'RIDE',
                requestedVehicleType: 'TUK_TUK',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tuk-tuk Driver'), findsOneWidget);
      expect(find.text('Private Car Driver'), findsNothing);
      expect(find.text('Moto Rider'), findsNothing);
      expect(find.text('Quarter Pickup Driver'), findsNothing);

      // 3) CUSTOM_DELIVERY with QUARTER_TRUCK -> ONLY Quarter-ton Pickup Truck driver
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('custom_quarter_assign_sheet'),
          overrides: [
            adminDriversRepositoryProvider
                .overrideWithValue(_FakeAdminDriversRepo(drivers)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: AssignDriverSheet(
                orderId: 'ord-cd',
                orderCode: 'CD-200',
                orderType: 'CUSTOM_DELIVERY',
                requestedVehicleType: 'QUARTER_TRUCK',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quarter Pickup Driver'), findsOneWidget);
      expect(find.text('Half Pickup Driver'), findsNothing);
      expect(find.text('Tricycle Driver'), findsNothing);
      expect(find.text('Private Car Driver'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
