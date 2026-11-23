import 'dart:convert';
import 'dart:io';

import 'package:api/api.dart' show OrdersApi, standardSerializers;
import 'package:core/core.dart' show RoadRoutePoint;
import 'package:data/data.dart'
    show ResolvedRoadRoute, SharedRoutingRepository;
import 'package:data/providers.dart' show sharedRoutingRepositoryProvider;
import 'package:dio/dio.dart' show CancelToken, Dio;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:otlob_customer/core/providers/platform_settings_provider.dart';
import 'package:otlob_customer/features/home/presentation/pages/custom_delivery_screen.dart';
import 'package:otlob_customer/features/orders/presentation/providers/custom_delivery_search_controller.dart';
import 'package:otlob_customer/features/orders/presentation/providers/orders_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RealCatalogLoader extends AssetLoader {
  const _RealCatalogLoader();

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

class _TestCoins extends CoinHistory {
  final int balance;
  _TestCoins([this.balance = 0]);
  @override
  CoinHistoryState build() => CoinHistoryState(currentBalance: balance);
}

class _TestEstimateOrders extends Orders {
  @override
  OrdersState build() => OrdersState();

  @override
  Future<Map<String, dynamic>?> estimateCustomOrder({
    required String type,
    required String pickup,
    required List<double> pickupLocation,
    required String dropoff,
    required List<double> deliveryLocation,
    String? details,
    String? specialRequest,
    String paymentMethod = 'CASH_ON_DELIVERY',
    String? vehicleType,
    int? coinsToUse,
  }) async {
    return {
      'distanceKm': 3.8,
      'deliveryFee': 30.0,
      'serviceFee': 5.0,
      'driverBonusFee': 0.0,
      'driverBonusPaidByCustomer': false,
      'tax': 0.0,
      'coinsUsed': 0,
      'discount': 0.0,
      'coinsEarned': 0,
      'grandTotal': 35.0,
      'upfrontAmount': 0.0,
    };
  }
}

Future<void> _pumpSpecialDelivery(
  WidgetTester tester, {
  required Size viewport,
  EdgeInsets safeAreaPadding = const EdgeInsets.only(top: 28, bottom: 16),
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.dark,
  CustomDeliveryDraft? draft,
  int coinBalance = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'translations',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      assetLoader: const _RealCatalogLoader(),
      child: ProviderScope(
        overrides: [
          platformSettingsProvider.overrideWith(
            (ref) async => PlatformSettingsData(),
          ),
          coinHistoryProvider.overrideWith(() => _TestCoins(coinBalance)),
          ordersProvider.overrideWith(_TestEstimateOrders.new),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: viewport,
                padding: safeAreaPadding,
              ),
              child: CustomDeliveryScreen(initialDraft: draft),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final viewports = <String, ({Size size, EdgeInsets padding})>{
    '360x640': (
      size: const Size(360, 640),
      padding: const EdgeInsets.only(top: 24, bottom: 0),
    ),
    '375x667': (
      size: const Size(375, 667),
      padding: const EdgeInsets.only(top: 20, bottom: 0),
    ),
    '360x800': (
      size: const Size(360, 800),
      padding: const EdgeInsets.only(top: 28, bottom: 16),
    ),
    '390x844': (
      size: const Size(390, 844),
      padding: const EdgeInsets.only(top: 47, bottom: 34),
    ),
    '412x915': (
      size: const Size(412, 915),
      padding: const EdgeInsets.only(top: 36, bottom: 24),
    ),
  };

  for (final entry in viewports.entries) {
    testWidgets(
      'CustomDeliveryScreen fits 100% zero-scroll without overflow on ${entry.key} with estimate, coins & expanded info',
      (tester) async {
        await _pumpSpecialDelivery(
          tester,
          viewport: entry.value.size,
          safeAreaPadding: entry.value.padding,
          locale: const Locale('ar'),
          coinBalance: 40,
          draft: const CustomDeliveryDraft(
            serviceType: 'delivery',
            pickupAddress: 'السكه الجديد',
            dropoffAddress: 'وسط البلد',
            pickupLocation: LatLng(30.0444, 31.2357),
            dropoffLocation: LatLng(30.0561, 31.2394),
            vehicleType: 'motorcycle',
          ),
        );

        expect(tester.takeException(), isNull);

        // Zero vertical scrollables on the screen
        final verticalScrollables = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where((s) => s.axis == Axis.vertical);
        expect(verticalScrollables, isEmpty);

        // All sections visible inside viewport including Live Map & bottom CTA
        expect(find.text('توصيل خاص'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('special_delivery_live_map_zone')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('special_delivery_bottom_sheet')),
          findsOneWidget,
        );
        expect(find.text('السكه الجديد'), findsOneWidget);
        expect(find.text('وسط البلد'), findsOneWidget);
        expect(find.text('3.8 كم'), findsOneWidget);
        expect(find.text('35 ج.م'), findsWidgets);
        expect(find.text('الإجمالي شامل الخدمة'), findsOneWidget);
        expect(find.text('طلب مندوب الآن'), findsOneWidget);

        // Live map absorbs remaining vertical height cleanly (zero dead space)
        final mapRect = tester.getRect(
          find.byKey(const ValueKey('special_delivery_live_map_zone')),
        );
        expect(mapRect.height, greaterThan(40));
        if (entry.value.size.height >= 800) {
          expect(mapRect.height, greaterThanOrEqualTo(120));
        }

        final ctaRect = tester.getRect(
          find.byKey(const ValueKey('special_delivery_submit_cta')),
        );
        expect(ctaRect.bottom, lessThanOrEqualTo(entry.value.size.height));

        // Expand info banner and confirm zero overflow & CTA still inside viewport
        final readMore = find.text('اقرأ المزيد...');
        if (readMore.evaluate().isNotEmpty) {
          await tester.tap(readMore);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final expandedCtaRect = tester.getRect(
            find.byKey(const ValueKey('special_delivery_submit_cta')),
          );
          expect(
            expandedCtaRect.bottom,
            lessThanOrEqualTo(entry.value.size.height),
          );
        }
      },
    );
  }

  testWidgets('CustomDeliveryScreen adapts to Dark Mode and Crisp Light Mode', (
    tester,
  ) async {
    await _pumpSpecialDelivery(
      tester,
      viewport: const Size(390, 844),
      themeMode: ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF0F0E0C),
    );
    final darkSheet = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('special_delivery_bottom_sheet')),
    );
    expect(
      (darkSheet.decoration as BoxDecoration?)?.color,
      const Color(0xFF13120F),
    );

    await _pumpSpecialDelivery(
      tester,
      viewport: const Size(390, 844),
      themeMode: ThemeMode.light,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFFF7F6F2),
    );
    final lightSheet = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('special_delivery_bottom_sheet')),
    );
    expect(
      (lightSheet.decoration as BoxDecoration?)?.color,
      const Color(0xFFF9F8F5),
    );
  });

  testWidgets(
    'Mode switcher toggles title, swap button exchanges pickup/dropoff, and clear button removes location',
    (tester) async {
      await _pumpSpecialDelivery(
        tester,
        viewport: const Size(390, 844),
        locale: const Locale('ar'),
        draft: const CustomDeliveryDraft(
          serviceType: 'delivery',
          pickupAddress: 'السكه الجديد',
          dropoffAddress: 'وسط البلد',
          pickupLocation: LatLng(30.0444, 31.2357),
          dropoffLocation: LatLng(30.0561, 31.2394),
          vehicleType: 'motorcycle',
        ),
      );

      // Delivery mode shows item details inputs and distance badge
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('3.8 كم'), findsOneWidget);

      // Verify RTL pickup is to the right of dropoff before swap
      final pickupXBefore = tester.getCenter(find.text('السكه الجديد')).dx;
      final dropoffXBefore = tester.getCenter(find.text('وسط البلد')).dx;
      expect(pickupXBefore, greaterThan(dropoffXBefore));

      // Tap Swap button (⇄) -> exchanges pickup and dropoff positions
      await tester.tap(find.byKey(const ValueKey('swap_locations_btn')));
      await tester.pumpAndSettle();
      final pickupXAfter = tester.getCenter(find.text('السكه الجديد')).dx;
      final dropoffXAfter = tester.getCenter(find.text('وسط البلد')).dx;
      expect(dropoffXAfter, greaterThan(pickupXAfter));

      // Tap clear icon on pickup location (now 'وسط البلد') -> clears address & hides distance pill
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('وسط البلد'), findsNothing);
      expect(find.text('3.8 كم'), findsNothing);
      expect(find.text('حدد المواقع للطلب'), findsOneWidget);

      // Switch to Ride mode -> header updates & item details inputs hidden
      await tester.tap(find.text('رحلة'));
      await tester.pumpAndSettle();
      expect(find.text('طلب رحلة'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('حدد المواقع للرحلة'), findsOneWidget);
    },
  );

  testWidgets(
    'Delivery fare estimate sends non-empty itemDetails when input is empty and never infinite-loops on error',
    (tester) async {
      final capturedDetails = <String?>[];
      var failEstimate = true;

      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('ar'),
          assetLoader: const _RealCatalogLoader(),
          child: ProviderScope(
            overrides: [
              platformSettingsProvider.overrideWith(
                (ref) async => PlatformSettingsData(),
              ),
              coinHistoryProvider.overrideWith(() => _TestCoins(0)),
              ordersProvider.overrideWith(
                () => _RecordingOrders(
                  onEstimate: (details) {
                    capturedDetails.add(details);
                    if (failEstimate) return null;
                    return {
                      'distanceKm': 3.8,
                      'deliveryFee': 30.0,
                      'serviceFee': 5.0,
                      'driverBonusFee': 0.0,
                      'driverBonusPaidByCustomer': false,
                      'tax': 0.0,
                      'coinsUsed': 0,
                      'discount': 0.0,
                      'coinsEarned': 0,
                      'grandTotal': 35.0,
                      'upfrontAmount': 0.0,
                    };
                  },
                ),
              ),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: ThemeMode.dark,
                home: const CustomDeliveryScreen(
                  initialDraft: CustomDeliveryDraft(
                    serviceType: 'delivery',
                    pickupAddress: 'السكه الجديد',
                    dropoffAddress: 'وسط البلد',
                    pickupLocation: LatLng(30.0444, 31.2357),
                    dropoffLocation: LatLng(30.0561, 31.2394),
                    vehicleType: 'motorcycle',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      // Must have sent a non-empty details string to satisfy PlaceCustomOrderDto
      // and must NOT loop endlessly when estimate returns null!
      expect(capturedDetails.length, 1);
      expect(capturedDetails.first, isNotNull);
      expect(capturedDetails.first!.trim(), isNotEmpty);
      expect(find.textContaining('اضغط لإعادة المحاولة'), findsOneWidget);

      // Tapping retry should trigger exactly one fresh request and display fare
      failEstimate = false;
      await tester.tap(find.textContaining('اضغط لإعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(capturedDetails.length, 2);
      expect(find.text('35 ج.م'), findsOneWidget);
    },
  );

  testWidgets(
    'CustomDeliveryScreen renders street-following road route with dual-stroke NavigationRoutePolylines and real ETA',
    (tester) async {
      final recordedWaypoints = <List<RoadRoutePoint>>[];
      final fakeRepo = _FakeRoutingRepository(
        onCompute: (waypoints) {
          recordedWaypoints.add(waypoints);
          return ResolvedRoadRoute(
            points: <RoadRoutePoint>[
              waypoints.first,
              const RoadRoutePoint(30.0472, 31.2361),
              const RoadRoutePoint(30.0504, 31.2389),
              const RoadRoutePoint(30.0536, 31.2378),
              waypoints.last,
            ],
            waypoints: waypoints,
            encodedPolyline: '',
            distanceMeters: 3800,
            durationSeconds: 480,
            isRoadRoute: true,
            source: 'osrm',
          );
        },
      );

      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('ar'),
          assetLoader: const _RealCatalogLoader(),
          child: ProviderScope(
            overrides: [
              platformSettingsProvider.overrideWith(
                (ref) async => PlatformSettingsData(),
              ),
              coinHistoryProvider.overrideWith(() => _TestCoins(0)),
              ordersProvider.overrideWith(_TestEstimateOrders.new),
              sharedRoutingRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: ThemeMode.dark,
                home: const CustomDeliveryScreen(
                  initialDraft: CustomDeliveryDraft(
                    serviceType: 'delivery',
                    pickupAddress: 'السكه الجديد',
                    dropoffAddress: 'وسط البلد',
                    pickupLocation: LatLng(30.0444, 31.2357),
                    dropoffLocation: LatLng(30.0561, 31.2394),
                    vehicleType: 'motorcycle',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must fetch road route once and render dual-stroke NavigationRoutePolylines
      // with all 5 street-following vertices (not a 2-point straight chord).
      expect(recordedWaypoints.length, 1);
      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(polylineLayer.polylines.length, 2);
      expect(polylineLayer.polylines.first.points.length, 5);
      expect(polylineLayer.polylines.last.points.length, 5);

      // Real ETA from road route is displayed in the bottom map status pill
      expect(find.text('3.8 كم • ~8 د'), findsOneWidget);

      // Swapping locations triggers a fresh road route request with reversed waypoints
      await tester.tap(find.byKey(const ValueKey('swap_locations_btn')));
      await tester.pumpAndSettle();
      expect(recordedWaypoints.length, 2);
      expect(recordedWaypoints.last.first.latitude, closeTo(30.0561, 0.0001));
      expect(recordedWaypoints.last.last.latitude, closeTo(30.0444, 0.0001));
    },
  );
}

class _FakeRoutingRepository extends SharedRoutingRepository {
  _FakeRoutingRepository({required this.onCompute})
    : super(OrdersApi(Dio(), standardSerializers));

  final ResolvedRoadRoute Function(List<RoadRoutePoint> waypoints) onCompute;

  @override
  Future<ResolvedRoadRoute> computeWaypointsRoute(
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
  }) async {
    return onCompute(rawWaypoints);
  }
}

class _RecordingOrders extends Orders {
  _RecordingOrders({required this.onEstimate});
  final Map<String, dynamic>? Function(String? details) onEstimate;

  @override
  OrdersState build() => OrdersState();

  @override
  Future<Map<String, dynamic>?> estimateCustomOrder({
    required String type,
    required String pickup,
    required List<double> pickupLocation,
    required String dropoff,
    required List<double> deliveryLocation,
    String? details,
    String? specialRequest,
    String paymentMethod = 'CASH_ON_DELIVERY',
    String? vehicleType,
    int? coinsToUse,
  }) async {
    return onEstimate(details);
  }
}
