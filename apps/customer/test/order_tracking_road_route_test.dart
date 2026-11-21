import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart' hide TokenService, tokenServiceProvider;
import 'package:data/data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:otlob_customer/core/services/location_service.dart';
import 'package:otlob_customer/core/services/socket_service.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/features/orders/presentation/pages/order_tracking_screen.dart';
import 'package:otlob_customer/features/orders/presentation/providers/orders_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1x1 transparent PNG so TileLayer / CachedNetworkImage never fail in tests.
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

class _FakeTokenService extends Fake implements TokenService {
  @override
  Future<String?> getAccessToken() async => 'test-access-token';
}

class _FakeLocationService extends Fake implements LocationService {
  @override
  Future<Position> getCurrentLocation() async => Position(
    longitude: 31.26,
    latitude: 30.065,
    timestamp: DateTime(2026),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeSocketService extends Fake implements SocketService {
  final Map<String, StreamController<dynamic>> _events = {};
  final StreamController<void> _connectCtrl = StreamController<void>.broadcast();

  @override
  bool get isConnected => true;

  @override
  Stream<void> get onConnect => _connectCtrl.stream;

  @override
  Stream<dynamic> onEvent(String event) => _events
      .putIfAbsent(event, () => StreamController<dynamic>.broadcast())
      .stream;

  @override
  Future<void> initSocket(String userToken) async {
    if (!_connectCtrl.isClosed) _connectCtrl.add(null);
  }

  @override
  void emit(String eventName, dynamic data) {}

  void fire(String eventName, dynamic payload) {
    _events
        .putIfAbsent(eventName, () => StreamController<dynamic>.broadcast())
        .add(payload);
  }

  void disposeService() {
    _connectCtrl.close();
    for (final c in _events.values) {
      c.close();
    }
  }
}

class _StubOrdersNotifier extends Orders {
  final List<Map<String, dynamic>> initialActive;
  Map<String, dynamic> latestDetails;

  _StubOrdersNotifier({
    required this.initialActive,
    required this.latestDetails,
  });

  @override
  OrdersState build() => OrdersState(
    activeOrders: initialActive,
    pastOrders: const [],
    isLoading: false,
  );

  @override
  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async =>
      Map<String, dynamic>.from(latestDetails);
}

class _RecordingRoutingRepository extends Fake
    implements SharedRoutingRepository {
  int getOrderRouteCalls = 0;
  int computeWaypointsCalls = 0;
  bool? lastIncludeDriver;

  ResolvedRoadRoute Function({
    required String orderId,
    required bool includeDriver,
    required List<RoadRoutePoint> fallbackWaypoints,
  })?
  onGetOrderRoute;

  @override
  Future<ResolvedRoadRoute> getOrderRoute({
    required String orderId,
    bool includeDriver = true,
    List<RoadRoutePoint> fallbackWaypoints = const [],
    CancelToken? cancelToken,
  }) async {
    getOrderRouteCalls++;
    lastIncludeDriver = includeDriver;
    if (onGetOrderRoute != null) {
      return onGetOrderRoute!(
        orderId: orderId,
        includeDriver: includeDriver,
        fallbackWaypoints: fallbackWaypoints,
      );
    }
    return const ResolvedRoadRoute(
      points: [
        RoadRoutePoint(30.0444, 31.2357),
        RoadRoutePoint(30.0470, 31.2420),
        RoadRoutePoint(30.0525, 31.2440),
        RoadRoutePoint(30.0580, 31.2530),
        RoadRoutePoint(30.0650, 31.2600),
      ],
      waypoints: [
        RoadRoutePoint(30.0444, 31.2357),
        RoadRoutePoint(30.0650, 31.2600),
      ],
      encodedPolyline: 'poly',
      distanceMeters: 3800,
      durationSeconds: 480,
      isRoadRoute: true,
      source: 'osrm',
    );
  }

  @override
  Future<ResolvedRoadRoute> computeWaypointsRoute(
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
  }) async {
    computeWaypointsCalls++;
    return ResolvedRoadRoute(
      points: rawWaypoints,
      waypoints: rawWaypoints,
      encodedPolyline: '',
      distanceMeters: 1000,
      durationSeconds: 0,
      isRoadRoute: false,
      source: 'fallback',
    );
  }
}

Map<String, dynamic> _makeStandardStoreOrder({
  String id = 'ord-std-1',
  String status = 'PENDING',
  String fulfillmentStatus = 'PENDING',
  String? driverId,
}) {
  return <String, dynamic>{
    'id': id,
    'orderNumber': 'ORD-000017',
    'type': 'STANDARD',
    'status': status,
    'revision': 1,
    'driverId': ?driverId,
    'deliveryAddress': '10 El-Nasr St, Cairo',
    'deliveryLocation': const {
      'type': 'Point',
      'coordinates': [31.2600, 30.0650],
    },
    'vendor': const {'id': 'v-1', 'storeName': 'Burger King'},
    'vendorBranch': const {
      'id': 'b-1',
      'name': 'haha',
      'location': {
        'type': 'Point',
        'coordinates': [31.2357, 30.0444],
      },
    },
    'vendorFulfillments': [
      {
        'id': 'f-1',
        'status': fulfillmentStatus,
        'vendor': const {'id': 'v-1', 'storeName': 'Burger King'},
        'vendorBranch': const {
          'id': 'b-1',
          'name': 'haha',
          'location': {
            'type': 'Point',
            'coordinates': [31.2357, 30.0444],
          },
        },
      },
    ],
  };
}

void main() {
  HttpOverrides.global = _FakeTileHttpOverrides();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpTrackingScreen(
    WidgetTester tester, {
    required String orderId,
    required _StubOrdersNotifier ordersNotifier,
    required _RecordingRoutingRepository routingRepo,
    required _FakeSocketService socket,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => ordersNotifier),
          sharedRoutingRepositoryProvider.overrideWithValue(routingRepo),
          socketServiceProvider.overrideWithValue(socket),
          tokenServiceProvider.overrideWithValue(_FakeTokenService()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'unused',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          assetLoader: const _CatalogAssetLoader(),
          child: Builder(
            builder: (locCtx) => MaterialApp(
              locale: locCtx.locale,
              supportedLocales: locCtx.supportedLocales,
              localizationsDelegates: locCtx.localizationDelegates,
              home: OrderTrackingScreen(orderId: orderId),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
  }

  group('OrderTrackingScreen Road Route Rendering', () {
    testWidgets(
      'pending regular store order fetches road geometry and renders multi-point street route instead of 2-point straight chord',
      (tester) async {
        final order = _makeStandardStoreOrder(status: 'PENDING');
        final socket = _FakeSocketService();
        addTearDown(socket.disposeService);
        final routingRepo = _RecordingRoutingRepository();
        final ordersNotifier = _StubOrdersNotifier(
          initialActive: [order],
          latestDetails: order,
        );

        await pumpTrackingScreen(
          tester,
          orderId: 'ord-std-1',
          ordersNotifier: ordersNotifier,
          routingRepo: routingRepo,
          socket: socket,
        );

        expect(routingRepo.getOrderRouteCalls, greaterThanOrEqualTo(1));
        expect(routingRepo.lastIncludeDriver, isFalse);

        final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
        // NavigationRoutePolylines.build emits 2 polylines (casing + foreground)
        expect(layer.polylines, hasLength(2));
        final renderedPoints = layer.polylines.last.points;
        expect(renderedPoints, hasLength(5));
        expect(renderedPoints[1], const LatLng(30.0470, 31.2420));
        expect(renderedPoints[2], const LatLng(30.0525, 31.2440));
        expect(renderedPoints.last, const LatLng(30.0650, 31.2600));
      },
    );

    testWidgets(
      'assigned order trims traversed road vertices along live driver updates and refreshes route on PICKED_UP transition',
      (tester) async {
        final assignedOrder = _makeStandardStoreOrder(
          id: 'ord-std-2',
          status: 'DRIVER_ASSIGNED',
          fulfillmentStatus: 'READY_FOR_PICKUP',
          driverId: 'drv-1',
        );
        final socket = _FakeSocketService();
        addTearDown(socket.disposeService);
        final routingRepo = _RecordingRoutingRepository();
        final ordersNotifier = _StubOrdersNotifier(
          initialActive: [assignedOrder],
          latestDetails: assignedOrder,
        );

        var isPickedUp = false;
        routingRepo.onGetOrderRoute = ({
          required orderId,
          required includeDriver,
          required fallbackWaypoints,
        }) {
          if (isPickedUp) {
            return const ResolvedRoadRoute(
              points: [
                RoadRoutePoint(30.0444, 31.2357),
                RoadRoutePoint(30.0510, 31.2450),
                RoadRoutePoint(30.0590, 31.2535),
                RoadRoutePoint(30.0650, 31.2600),
              ],
              waypoints: [
                RoadRoutePoint(30.0444, 31.2357),
                RoadRoutePoint(30.0650, 31.2600),
              ],
              encodedPolyline: 'poly-picked',
              distanceMeters: 2900,
              durationSeconds: 320,
              isRoadRoute: true,
              driverLocation: RoadRoutePoint(30.0444, 31.2357),
              source: 'osrm',
            );
          }
          return const ResolvedRoadRoute(
            points: [
              RoadRoutePoint(30.0300, 31.2200),
              RoadRoutePoint(30.0360, 31.2260),
              RoadRoutePoint(30.0444, 31.2357),
              RoadRoutePoint(30.0550, 31.2480),
              RoadRoutePoint(30.0650, 31.2600),
            ],
            waypoints: [
              RoadRoutePoint(30.0300, 31.2200),
              RoadRoutePoint(30.0444, 31.2357),
              RoadRoutePoint(30.0650, 31.2600),
            ],
            encodedPolyline: 'poly-assigned',
            distanceMeters: 4400,
            durationSeconds: 510,
            isRoadRoute: true,
            driverLocation: RoadRoutePoint(30.0300, 31.2200),
            source: 'osrm',
          );
        };

        await pumpTrackingScreen(
          tester,
          orderId: 'ord-std-2',
          ordersNotifier: ordersNotifier,
          routingRepo: routingRepo,
          socket: socket,
        );

        // Emit first live driver location -> route trims to start cleanly at driver
        socket.fire(SocketEvent.driverLocation.eventName, {
          'orderId': 'ord-std-2',
          'lat': 30.0365,
          'lng': 31.2265,
        });
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 50));

        final afterMoveLayer = tester.widget<PolylineLayer>(
          find.byType(PolylineLayer),
        );
        final afterMovePts = afterMoveLayer.polylines.last.points;
        expect(afterMovePts.first, const LatLng(30.0365, 31.2265));
        expect(afterMovePts, contains(const LatLng(30.0444, 31.2357)));
        expect(afterMovePts, isNot(contains(const LatLng(30.0300, 31.2200))));

        // Simulate store pickup completion -> backend returns post-pickup leg only
        isPickedUp = true;
        final pickedUpOrder = _makeStandardStoreOrder(
          id: 'ord-std-2',
          status: 'PICKED_UP',
          fulfillmentStatus: 'PICKED_UP',
          driverId: 'drv-1',
        );
        ordersNotifier.latestDetails = pickedUpOrder;
        final callsBeforePickup = routingRepo.getOrderRouteCalls;

        socket.fire(SocketEvent.orderStatus.eventName, {
          'orderId': 'ord-std-2',
          'status': 'PICKED_UP',
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(routingRepo.getOrderRouteCalls, greaterThan(callsBeforePickup));
        final postPickupLayer = tester.widget<PolylineLayer>(
          find.byType(PolylineLayer),
        );
        final postPickupPts = postPickupLayer.polylines.last.points;
        expect(postPickupPts, contains(const LatLng(30.0590, 31.2535)));
        expect(postPickupPts.last, const LatLng(30.0650, 31.2600));
      },
    );
  });
}
