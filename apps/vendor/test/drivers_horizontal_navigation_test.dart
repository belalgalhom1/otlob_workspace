import 'dart:async';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/drivers/presentation/drivers_screen.dart';
import 'package:vendor/features/drivers/presentation/widgets/driver_map_details_card.dart';
import 'package:vendor/features/drivers/presentation/widgets/horizontal_action_strip.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeSuperAdminAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'SUPER_ADMIN';

  @override
  Future<List<String>> getUserPermissions() async => const ['MANAGE_DRIVERS'];

  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeSocketService extends Fake implements CoreSocketService {
  @override
  Future<void> init({String? forceToken, bool autoConnect = true}) async {}

  @override
  Stream<dynamic> onEvent(SocketEvent event) => const Stream<dynamic>.empty();

  @override
  void emit(SocketEvent event, [dynamic data]) {}
}

class _FakeZoneNotifier extends ZoneNotifier {
  @override
  AsyncValue<ZoneStateData> build() => AsyncValue.data(
        ZoneStateData([
          {'id': 'z-1', 'name': 'Downtown', 'nameAr': 'وسط البلد'},
        ], total: 1),
      );

  @override
  Future<void> fetchZones() async {}
}

class _FakeDriversNotifier extends DriversNotifier {
  _FakeDriversNotifier(this._drivers);
  final List<DriverProfile> _drivers;

  @override
  FutureOr<DriversState> build() => DriversState(
        drivers: _drivers,
        total: _drivers.length,
        page: 1,
        isLoading: false,
        hasMore: false,
      );

  @override
  Future<void> filter({String? search, String? status, String? zoneId}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

DriverProfile _sampleDriver() {
  return DriverProfile(
    id: 'drv-1',
    userId: 'usr-drv-1',
    name: 'test',
    status: 'ONLINE',
    tier: 'GOLD',
    isSuspended: false,
    isApproved: true,
    walletBalance: -26.0,
    vehicleType: 'CAR',
    vehiclePlate: 'CAR hag',
    location: const [31.2357, 30.0444],
    user: const {'phone': '+201102921279'},
    driverManager: const {'userId': 'mgr-1', 'name': 'test2'},
  );
}

Widget _buildDriversHarness({
  required Locale locale,
  required List<DriverProfile> drivers,
  double textScale = 1.0,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return ProviderScope(
    overrides: [
      sharedAuthRepositoryProvider.overrideWithValue(_FakeSuperAdminAuthRepo()),
      coreSocketServiceProvider.overrideWithValue(_FakeSocketService()),
      zoneProvider.overrideWith(_FakeZoneNotifier.new),
      driversProvider.overrideWith(() => _FakeDriversNotifier(drivers)),
    ],
    child: MaterialApp(
      scrollBehavior: const AppScrollBehavior(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
          padding: padding,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: DriversScreen(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'DriversScreen filter bar and driver card action strips scroll horizontally in LTR/RTL and reset scroll offset on language change',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final drivers = [_sampleDriver()];

      await tester.pumpWidget(
        _buildDriversHarness(
          locale: const Locale('en'),
          drivers: drivers,
          textScale: 1.3,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final strips = find.byType(HorizontalActionStrip);
      expect(strips, findsNWidgets(2));

      // Both strips in EN (LTR) scroll from left to right.
      final filterScrollable = tester.state<ScrollableState>(
        find.descendant(
          of: strips.at(0),
          matching: find.byType(Scrollable),
        ),
      );
      final cardActionsScrollable = tester.state<ScrollableState>(
        find.descendant(
          of: strips.at(1),
          matching: find.byType(Scrollable),
        ),
      );

      expect(filterScrollable.axisDirection, AxisDirection.right);
      expect(cardActionsScrollable.axisDirection, AxisDirection.right);
      expect(filterScrollable.position.pixels, 0.0);
      expect(cardActionsScrollable.position.pixels, 0.0);
      expect(filterScrollable.position.maxScrollExtent, greaterThan(0.0));
      expect(cardActionsScrollable.position.maxScrollExtent, greaterThan(0.0));

      // Leading item ('All' / 'Wallet') is anchored at the leading left edge in EN.
      final filterStripBox = tester.getRect(strips.at(0));
      final allChipBox = tester.getRect(
        find.descendant(of: strips.at(0), matching: find.text('All')),
      );
      expect(allChipBox.left, lessThan(filterStripBox.left + 80));

      final cardStripBox = tester.getRect(strips.at(1));
      final walletBtnBox = tester.getRect(
        find.descendant(of: strips.at(1), matching: find.text('Wallet')),
      );
      expect(walletBtnBox.left, lessThan(cardStripBox.left + 80));

      // Horizontal swipe in EN moves both strips forward toward trailing controls.
      await tester.drag(strips.at(0), const Offset(-260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(filterScrollable.position.pixels, greaterThan(50));

      await tester.drag(strips.at(1), const Offset(-260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(cardActionsScrollable.position.pixels, greaterThan(50));

      // Switching live to Arabic (RTL) resets scroll position to 0.0 and flips axisDirection to left.
      await tester.pumpWidget(
        _buildDriversHarness(
          locale: const Locale('ar'),
          drivers: drivers,
          textScale: 1.3,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(filterScrollable.axisDirection, AxisDirection.left);
      expect(cardActionsScrollable.axisDirection, AxisDirection.left);
      expect(filterScrollable.position.pixels, 0.0);
      expect(cardActionsScrollable.position.pixels, 0.0);

      // Leading Arabic item ('الكل') starts anchored on the right edge in RTL.
      final arFilterStripBox = tester.getRect(strips.at(0));
      final arAllBox = tester.getRect(
        find.descendant(of: strips.at(0), matching: find.text('الكل')),
      );
      expect(arAllBox.right, lessThanOrEqualTo(arFilterStripBox.right + 1));
      expect(arAllBox.right, greaterThan(arFilterStripBox.center.dx));

      // Leading Arabic action ('المحفظة') starts anchored on the right edge in RTL.
      final arCardStripBox = tester.getRect(strips.at(1));
      final arWalletBox = tester.getRect(
        find.descendant(of: strips.at(1), matching: find.text('المحفظة')),
      );
      expect(arWalletBox.right, lessThanOrEqualTo(arCardStripBox.right + 1));
      expect(arWalletBox.right, greaterThan(arCardStripBox.center.dx));

      // Horizontal swipe gesture in RTL scrolls toward the left.
      await tester.drag(strips.at(0), const Offset(260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(filterScrollable.position.pixels, greaterThan(50));

      await tester.drag(strips.at(1), const Offset(260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(cardActionsScrollable.position.pixels, greaterThan(50));

      // Switching back to EN resets offsets to 0.0 at the LTR left edge cleanly.
      await tester.pumpWidget(
        _buildDriversHarness(
          locale: const Locale('en'),
          drivers: drivers,
          textScale: 1.3,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(filterScrollable.axisDirection, AxisDirection.right);
      expect(filterScrollable.position.pixels, 0.0);
      expect(cardActionsScrollable.position.pixels, 0.0);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DriverMapDetailsCard action buttons strip scrolls horizontally and follows LTR/RTL directionality',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget buildCard(Locale locale) => MaterialApp(
            scrollBehavior: const AppScrollBehavior(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Scaffold(
              body: SizedBox(
                width: 340,
                child: DriverMapDetailsCard(
                  driver: _sampleDriver(),
                  location: const LatLng(30.0444, 31.2357),
                  isLive: true,
                  activeOrder: const {
                    'id': 'ord-1',
                    'orderNumber': 'ORD-100',
                    'status': 'PICKED_UP',
                    'vendor': {
                      'id': 'v-bk',
                      'storeName': 'Burger King',
                      'coverImage': '/media/vendors/bk-cover.webp',
                    },
                    'customer': {
                      'user': {'name': 'Omar', 'phone': '01001234567'},
                    },
                  },
                  pickupLocation: const LatLng(30.05, 31.24),
                  deliveryLocation: const LatLng(30.06, 31.25),
                  onClose: () {},
                  onCallPhone: (_) {},
                  onOpenMaps: (_, _, {label}) {},
                  onViewOrderDetails: (_) {},
                  onCenterOnPickup: () {},
                  onCenterOnDelivery: () {},
                  onAssignOrder: () {},
                ),
              ),
            ),
          );

      await tester.pumpWidget(buildCard(const Locale('en')));
      await tester.pump();

      final stripFinder = find.byType(HorizontalActionStrip);
      expect(stripFinder, findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: stripFinder, matching: find.byType(Scrollable)),
      );
      expect(scrollable.axisDirection, AxisDirection.right);
      expect(scrollable.position.pixels, 0.0);
      expect(scrollable.position.maxScrollExtent, greaterThan(0.0));

      await tester.drag(stripFinder, const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(scrollable.position.pixels, greaterThan(40));

      await tester.pumpWidget(buildCard(const Locale('ar')));
      await tester.pump();
      await tester.pump();

      expect(scrollable.axisDirection, AxisDirection.left);
      expect(scrollable.position.pixels, 0.0);

      await tester.drag(stripFinder, const Offset(200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(scrollable.position.pixels, greaterThan(40));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DriversScreen renders cleanly on tablet viewport in EN and AR without overflow',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final drivers = [_sampleDriver()];

      await tester.pumpWidget(
        _buildDriversHarness(
          locale: const Locale('en'),
          drivers: drivers,
          textScale: 1.15,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HorizontalActionStrip), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _buildDriversHarness(
          locale: const Locale('ar'),
          drivers: drivers,
          textScale: 1.15,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HorizontalActionStrip), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
