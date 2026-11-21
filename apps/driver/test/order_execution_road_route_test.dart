import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/order_execution/presentation/pages/order_execution_screen.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  final StreamController<Position> _stream =
      StreamController<Position>.broadcast();

  final Position _current = Position(
    longitude: 31.2200,
    latitude: 30.0300,
    timestamp: DateTime(2026),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => _current;

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) => _stream.stream;

  Future<void> dispose() => _stream.close();
}

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FakeDriverProfile extends DriverProfile {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data({
    'id': 'drv-1',
    'name': 'Captain Kareem',
    'status': 'ON_DELIVERY',
    'vehicleType': 'MOTORCYCLE',
  });
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  @override
  Future<List<dynamic>> getActiveDriverOrders() async => const [];

  @override
  Future<dynamic> getPendingAssistOffers() async => const [];
}

class _FakeSocketService extends Fake implements CoreSocketService {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> onEvent(SocketEvent event) => _controller.stream;

  @override
  void dispose() => _controller.close();
}

class _FakeOrderExecution extends OrderExecution {
  final Map<String, dynamic> _order;

  _FakeOrderExecution(this._order);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data(_order);
}

class _RecordingRoutingRepository extends Fake
    implements SharedRoutingRepository {
  int computeCalls = 0;

  @override
  Future<ResolvedRoadRoute> computeWaypointsRoute(
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
  }) async {
    computeCalls++;
    return const ResolvedRoadRoute(
      points: [
        RoadRoutePoint(30.0300, 31.2200),
        RoadRoutePoint(30.0375, 31.2280),
        RoadRoutePoint(30.0444, 31.2357),
        RoadRoutePoint(30.0555, 31.2490),
        RoadRoutePoint(30.0650, 31.2600),
      ],
      waypoints: [
        RoadRoutePoint(30.0300, 31.2200),
        RoadRoutePoint(30.0444, 31.2357),
        RoadRoutePoint(30.0650, 31.2600),
      ],
      encodedPolyline: 'poly-driver',
      distanceMeters: 4200,
      durationSeconds: 480,
      isRoadRoute: true,
      source: 'osrm',
    );
  }
}

void main() {
  HttpOverrides.global = _FakeTileHttpOverrides();

  testWidgets(
    'OrderExecutionScreen fetches multi-waypoint road geometry and renders it via NavigationRoutePolylines',
    (tester) async {
      final prevGeolocator = GeolocatorPlatform.instance;
      final fakeGeolocator = _FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = fakeGeolocator;
      final socket = _FakeSocketService();
      addTearDown(() async {
        GeolocatorPlatform.instance = prevGeolocator;
        await fakeGeolocator.dispose();
        socket.dispose();
      });

      final routingRepo = _RecordingRoutingRepository();
      final order = <String, dynamic>{
        'id': 'ord-drv-1',
        'orderNumber': 'ORD-201',
        'type': 'STANDARD',
        'status': 'DRIVER_ASSIGNED',
        'pickupAddress': 'Burger King Branch',
        'deliveryAddress': '10 El-Nasr St',
        'vendor': const {'id': 'v-1', 'storeName': 'Burger King'},
        'vendorBranch': const {
          'id': 'b-1',
          'name': 'haha',
          'location': {
            'type': 'Point',
            'coordinates': [31.2357, 30.0444],
          },
        },
        'deliveryLocation': const {
          'type': 'Point',
          'coordinates': [31.2600, 30.0650],
        },
        'customer': const {'name': 'Omar'},
        'paymentMethod': 'CASH_ON_DELIVERY',
        'cashToCollect': 120,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
            configurationProvider.overrideWith(_FakeConfiguration.new),
            driverProfileProvider.overrideWith(_FakeDriverProfile.new),
            driverOrdersRepositoryProvider.overrideWithValue(
              _FakeDriverOrdersRepository(),
            ),
            coreSocketServiceProvider.overrideWithValue(socket),
            sharedRoutingRepositoryProvider.overrideWithValue(routingRepo),
            orderExecutionProvider.overrideWith(() => _FakeOrderExecution(order)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: OrderExecutionScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(routingRepo.computeCalls, greaterThanOrEqualTo(1));
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines.last.points, hasLength(5));
      expect(
        layer.polylines.last.points,
        contains(const LatLng(30.0375, 31.2280)),
      );
      expect(
        layer.polylines.last.points,
        contains(const LatLng(30.0555, 31.2490)),
      );
    },
  );
}
