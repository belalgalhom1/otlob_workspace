import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/dashboard/presentation/dashboard_screen.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/dashboard/presentation/widgets/driver_live_map_card.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/ranking/presentation/driver_ranking_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';

final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _FakeTileHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  void close({bool force = false}) {}
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MutableFakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position currentPosition = Position(
    longitude: 31.2357,
    latitude: 30.0444,
    timestamp: DateTime(2026),
    accuracy: 4.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 45.0,
    headingAccuracy: 0.0,
    speed: 6.0,
    speedAccuracy: 0.0,
  );
  final StreamController<Position> _streamController =
      StreamController<Position>.broadcast();

  void emitPosition(Position pos) {
    currentPosition = pos;
    _streamController.add(pos);
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      currentPosition;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      currentPosition;

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) =>
      _streamController.stream;

  Future<void> dispose() => _streamController.close();
}

class _MutableDriverProfile extends DriverProfile {
  Map<String, dynamic> _data;
  _MutableDriverProfile(this._data);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data(_data);

  void updateProfile(Map<String, dynamic> next) {
    _data = next;
    state = AsyncValue.data(next);
  }

  @override
  Future<void> fetchProfile() async {}
}

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  @override
  Future<dynamic> getPendingAssistOffers() async => const <dynamic>[];
}

class _FakeOrderExecution extends OrderExecution {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data(null);

  @override
  Future<void> refresh() async {}
}

DriverMyRankSummaryResponseDto _makeFakeRank() {
  return DriverMyRankSummaryResponseDto(
    (b) => b
      ..driverId = 'drv-1'
      ..currentTier = DriverTier.GOLD
      ..timezone = 'Africa/Cairo'
      ..nextEvaluationAt = DateTime.now().add(const Duration(days: 3))
      ..currentWeek = RankingWeekWindowDto(
        (w) => w
          ..periodKey = '2026-W46'
          ..periodStart = DateTime.now()
          ..periodEnd = DateTime.now().add(const Duration(days: 7)),
      ).toBuilder(),
  );
}

void main() {
  late HttpOverrides? previousHttpOverrides;
  late GeolocatorPlatform originalGeolocator;
  late _MutableFakeGeolocatorPlatform fakeGeolocator;

  setUp(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _FakeTileHttpOverrides();
    originalGeolocator = GeolocatorPlatform.instance;
    fakeGeolocator = _MutableFakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakeGeolocator;
  });

  tearDown(() async {
    GeolocatorPlatform.instance = originalGeolocator;
    HttpOverrides.global = previousHttpOverrides;
    await fakeGeolocator.dispose();
  });

  Widget buildDashboard({
    required _MutableDriverProfile profileNotifier,
    Locale locale = const Locale('en'),
    Key? scopeKey,
  }) {
    return ProviderScope(
      key: scopeKey,
      overrides: [
        baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
        configurationProvider.overrideWith(_FakeConfiguration.new),
        driverProfileProvider.overrideWith(() => profileNotifier),
        driverOrdersRepositoryProvider.overrideWithValue(
          _FakeDriverOrdersRepository(),
        ),
        orderExecutionProvider.overrideWith(_FakeOrderExecution.new),
        breaksOverviewProvider.overrideWith((ref) async => const BreaksOverview()),
        driverRankingSummaryProvider.overrideWith((ref) async => _makeFakeRank()),
        isOnlineStreamProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const DashboardScreen(),
      ),
    );
  }

  testWidgets(
    'displays driver status above live map and updates dynamically across ONLINE, OFFLINE, BUSY, ON_DELIVERY, ON_BREAK, SUSPENDED in EN & AR',
    (tester) async {
      final profileNotifier = _MutableDriverProfile({
        'status': 'ONLINE',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
        'totalOrders': 12,
        'tier': 'GOLD',
      });

      await tester.pumpWidget(buildDashboard(profileNotifier: profileNotifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final statusCardFinder = find.byKey(
        const ValueKey('driver_dashboard_status_card'),
      );
      final mapCardFinder = find.byType(DriverLiveMapCard);
      expect(statusCardFinder, findsOneWidget);
      expect(mapCardFinder, findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(InDriveVehicleMarker), findsOneWidget);

      // Verify Status Card sits above Map Card
      expect(
        tester.getTopLeft(statusCardFinder).dy,
        lessThan(tester.getTopLeft(mapCardFinder).dy),
      );

      // Verify Status Card + Map show ONLINE
      expect(find.text('Online'), findsWidgets);

      // Transition to BUSY
      profileNotifier.updateProfile({
        'status': 'BUSY',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
      });
      await tester.pump();
      expect(find.text('Busy'), findsWidgets);

      // Transition to ON_DELIVERY ("On a Trip")
      profileNotifier.updateProfile({
        'status': 'ON_DELIVERY',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
      });
      await tester.pump();
      expect(find.text('On a Trip'), findsWidgets);

      // Transition to ON_BREAK
      profileNotifier.updateProfile({
        'status': 'ON_BREAK',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
      });
      await tester.pump();
      expect(find.text('On Break'), findsWidgets);

      // Transition to SUSPENDED
      profileNotifier.updateProfile({
        'status': 'SUSPENDED',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
      });
      await tester.pump();
      expect(find.text('Suspended'), findsWidgets);

      // Transition to OFFLINE
      profileNotifier.updateProfile({
        'status': 'OFFLINE',
        'name': 'Captain Kareem',
        'vehicleType': 'CAR',
        'vehiclePlate': 'ABC 123',
      });
      await tester.pump();
      expect(find.text('Offline'), findsWidgets);

      // Verify Arabic RTL status rendering cleanly
      final arProfileNotifier = _MutableDriverProfile({
        'status': 'ON_DELIVERY',
        'name': 'كابتن كريم',
        'vehicleType': 'TUK_TUK',
        'totalOrders': 7,
      });
      await tester.pumpWidget(
        buildDashboard(
          profileNotifier: arProfileNotifier,
          locale: const Locale('ar'),
          scopeKey: UniqueKey(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('في رحلة توصيل'), findsWidgets);
      expect(find.byType(InDriveVehicleMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders registered vehicle markers and smoothly interpolates position on real GPS updates',
    (tester) async {
      const supportedVehicles = [
        'MOTORCYCLE',
        'CAR',
        'MINIBUS',
        'TUK_TUK',
        'MOTOR_TRICYCLE',
        'QUARTER_TRUCK',
        'HALF_TRUCK',
      ];

      final profileNotifier = _MutableDriverProfile({
        'status': 'ONLINE',
        'name': 'Captain Sameh',
        'vehicleType': 'MOTORCYCLE',
      });

      await tester.pumpWidget(buildDashboard(profileNotifier: profileNotifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      for (final vehicle in supportedVehicles) {
        profileNotifier.updateProfile({
          'status': 'ONLINE',
          'name': 'Captain Sameh',
          'vehicleType': vehicle,
        });
        await tester.pump();
        final markerWidget = tester.widget<InDriveVehicleMarker>(
          find.byType(InDriveVehicleMarker),
        );
        expect(markerWidget.vehicleType, equals(vehicle));
      }

      // Emit a new real GPS coordinate and ensure smooth animation updates the Marker point
      fakeGeolocator.emitPosition(
        Position(
          longitude: 31.2420,
          latitude: 30.0520,
          timestamp: DateTime(2026, 1, 1, 0, 1),
          accuracy: 3.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 90.0,
          headingAccuracy: 0.0,
          speed: 8.5,
          speedAccuracy: 0.0,
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 550));

      final MarkerLayer markerLayer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      final LatLng movedPoint = markerLayer.markers.first.point;
      expect(movedPoint.latitude, closeTo(30.0520, 0.002));
      expect(movedPoint.longitude, closeTo(31.2420, 0.002));
      expect(
        find.byKey(const ValueKey('dashboard_live_map_recenter_btn')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'handles GPS disabled and permission denied states gracefully on Dashboard Live Map',
    (tester) async {
      fakeGeolocator.serviceEnabled = false;
      final profileNotifier = _MutableDriverProfile({
        'status': 'OFFLINE',
        'name': 'Captain Ali',
        'vehicleType': 'QUARTER_TRUCK',
      });

      await tester.pumpWidget(buildDashboard(profileNotifier: profileNotifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('GPS is turned off'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);

      // Re-enable GPS but simulate permanent permission denial
      fakeGeolocator.serviceEnabled = true;
      fakeGeolocator.permission = LocationPermission.deniedForever;

      final arProfileNotifier = _MutableDriverProfile({
        'status': 'OFFLINE',
        'name': 'كابتن علي',
        'vehicleType': 'HALF_TRUCK',
      });
      await tester.pumpWidget(
        buildDashboard(
          profileNotifier: arProfileNotifier,
          locale: const Locale('ar'),
          scopeKey: UniqueKey(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('صلاحية الموقع مطلوبة'), findsOneWidget);
      expect(find.text('فتح الإعدادات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
