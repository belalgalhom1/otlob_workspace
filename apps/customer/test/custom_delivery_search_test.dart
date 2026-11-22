import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:core/core.dart' hide TokenService, tokenServiceProvider;
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:otlob_customer/core/services/socket_service.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/features/orders/presentation/pages/custom_delivery_search_screen.dart';
import 'package:otlob_customer/features/orders/presentation/providers/custom_delivery_search_controller.dart';
import 'package:otlob_customer/features/orders/presentation/utils/order_geo_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart';

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

class _FakeDio extends Fake implements Dio {
  bool shouldFail = false;
  int getCalls = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    getCalls++;
    if (shouldFail) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionTimeout,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data:
          <String, dynamic>{
                'routes': [
                  {
                    'geometry': {
                      'coordinates': [
                        [31.2357, 30.0444],
                        [31.2400, 30.0500],
                        [31.2500, 30.0600],
                      ],
                    },
                  },
                ],
              }
              as T,
    );
  }
}

class _FakeTokenService extends Fake implements TokenService {
  @override
  Future<String?> getAccessToken() async => 'test-access-token';
}

class _FakeConnectivityService extends Fake implements ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _online = true;

  @override
  bool? get lastKnownStatus => _online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void emitOnline(bool isOnline) {
    _online = isOnline;
    if (!_controller.isClosed) {
      _controller.add(isOnline);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _FakeSocketService extends Fake implements SocketService {
  final Map<String, StreamController<dynamic>> _events = {};
  final StreamController<void> _connectController =
      StreamController<void>.broadcast();

  bool connected = true;
  int initCalls = 0;
  final List<(String, dynamic)> emitted = [];

  @override
  bool get isConnected => connected;

  @override
  Stream<void> get onConnect => _connectController.stream;

  @override
  Stream<dynamic> onEvent(String event) => _events
      .putIfAbsent(event, () => StreamController<dynamic>.broadcast())
      .stream;

  @override
  Future<void> initSocket(String userToken) async {
    initCalls++;
    connected = true;
    if (!_connectController.isClosed) {
      _connectController.add(null);
    }
  }

  @override
  void emit(String eventName, dynamic data) {
    emitted.add((eventName, data));
  }

  void fireEvent(String eventName, dynamic payload) {
    _events
        .putIfAbsent(eventName, () => StreamController<dynamic>.broadcast())
        .add(payload);
  }

  void fireReconnect() {
    connected = true;
    if (!_connectController.isClosed) {
      _connectController.add(null);
    }
  }

  void disposeService() {
    _connectController.close();
    for (final c in _events.values) {
      c.close();
    }
  }
}

class _FakeCustomerOrderRepo extends Fake implements CustomerOrderRepository {
  Map<String, dynamic> orderResponse = _makeOrderMap();
  late OrderSearchStatusDto searchStatusResponse = _makeSearchStatus();
  Completer<Map<String, dynamic>>? orderCompleter;
  Completer<CustomerRetrySearchResult>? retryCompleter;

  int getOrderCalls = 0;
  int getSearchStatusCalls = 0;
  int cancelCalls = 0;
  int retryCalls = 0;
  bool failNextCancelWithDriverAssigned = false;

  @override
  Future<dynamic> getMyOrders({
    String? status,
    num limit = 20,
    num page = 1,
  }) async => <dynamic>[];

  @override
  Future<dynamic> getOrderById(String orderId) async {
    getOrderCalls++;
    if (orderCompleter != null) {
      return orderCompleter!.future;
    }
    return Map<String, dynamic>.from(orderResponse);
  }

  @override
  Future<OrderSearchStatusDto> getOrderSearchStatus(String orderId) async {
    getSearchStatusCalls++;
    return searchStatusResponse;
  }

  @override
  Future<dynamic> cancelOrder(String orderId, {String? reason}) async {
    cancelCalls++;
    if (failNextCancelWithDriverAssigned) {
      failNextCancelWithDriverAssigned = false;
      orderResponse = _makeAssignedOrderMap();
      searchStatusResponse = _makeSearchStatus(
        phase: DriverSearchPhase.DRIVER_FOUND,
        orderStatus: OrderStatus.DRIVER_ASSIGNED,
        revision: 4,
      );
      throw DioException(
        requestOptions: RequestOptions(path: '/orders/$orderId/cancel'),
        response: Response(
          requestOptions: RequestOptions(path: '/orders/$orderId/cancel'),
          statusCode: 400,
          data: {'message': 'order.error.already_assigned'},
        ),
      );
    }
    orderResponse = _makeOrderMap(
      status: 'CANCELLED',
      cancelledByRole: 'CUSTOMER',
      cancelReason: reason,
    );
    searchStatusResponse = _makeSearchStatus(
      phase: DriverSearchPhase.CANCELLED,
      orderStatus: OrderStatus.CANCELLED,
      terminalReason: SearchTerminalReason.CANCELLED_BY_CUSTOMER,
      canRetry: true,
      revision: 3,
    );
    return {'status': 'CANCELLED'};
  }

  @override
  Future<CustomerRetrySearchResult> retryCustomSearch(String orderId) async {
    retryCalls++;
    if (retryCompleter != null) {
      return retryCompleter!.future;
    }
    orderResponse = _makeOrderMap(status: 'LOOKING_FOR_DRIVER', revision: 5);
    searchStatusResponse = _makeSearchStatus(
      phase: DriverSearchPhase.QUEUED,
      orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
      canRetry: false,
      revision: 5,
      attempt: 1,
    );
    return CustomerRetrySearchResult(
      retried: true,
      order: Map<String, dynamic>.from(orderResponse),
      searchStatus: searchStatusResponse,
      alreadySearching: false,
      alreadyAssigned: false,
    );
  }
}

class _StubCustomDeliverySearchController
    extends CustomDeliverySearchController {
  _StubCustomDeliverySearchController(
    this._initialState, {
    DriverLiveMarkerState? live,
    List<NearbyVehicleMarkerState>? nearby,
  }) {
    if (live != null) {
      driverLocationNotifier.value = live;
    }
    if (nearby != null) {
      nearbyVehiclesNotifier.value = nearby;
    }
  }

  final CustomDeliverySearchState _initialState;
  int cancelCalls = 0;
  int retryCalls = 0;

  @override
  CustomDeliverySearchState build(String orderId) {
    ref.onDispose(() {
      driverLocationNotifier.dispose();
      nearbyVehiclesNotifier.dispose();
      driverApproachRouteNotifier.dispose();
    });
    return _initialState;
  }

  @override
  void seedOrderSnapshot(Map<String, dynamic>? initialOrder) {}

  @override
  void onAppPaused() {}

  @override
  Future<void> resync({bool statusOnly = false, bool silent = false}) async {}

  @override
  Future<void> cancelSearch({String reason = ''}) async {
    cancelCalls++;
    state = state.copyWith(isCancelling: true);
  }

  @override
  Future<void> retrySearch() async {
    retryCalls++;
    state = state.copyWith(isRetrying: true);
  }

  void setStateForTest(CustomDeliverySearchState next) {
    state = next;
  }
}

Map<String, dynamic> _makeOrderMap({
  String id = 'ord-custom-1',
  String orderNumber = 'OTL-8841',
  String type = 'CUSTOM_DELIVERY',
  String status = 'LOOKING_FOR_DRIVER',
  int revision = 1,
  String? cancelReason,
  String? cancelledByRole,
}) {
  return <String, dynamic>{
    'id': id,
    'orderNumber': orderNumber,
    'type': type,
    'status': status,
    'revision': revision,
    'pickupAddress': '14 Tahrir St, Downtown Cairo, Egypt',
    'deliveryAddress': '22 El-Nasr Rd, Nasr City, Cairo, Egypt',
    'pickupLocation': const {
      'type': 'Point',
      'coordinates': [31.2357, 30.0444],
    },
    'deliveryLocation': const {
      'type': 'Point',
      'coordinates': [31.3357, 30.0644],
    },
    'requestedVehicleType': 'MOTORCYCLE',
    'itemDetails': 'Fragile medical documents & sealed package',
    'specialRequest': 'Call on arrival at gate B',
    'paymentMethod': 'CASH_ON_DELIVERY',
    'distanceKm': 9.4,
    'grandTotal': 85,
    'coinsUsed': 0,
    'cancelReason': ?cancelReason,
    'cancelledByRole': ?cancelledByRole,
  };
}

Map<String, dynamic> _makeAssignedOrderMap({
  String status = 'DRIVER_ASSIGNED',
  num rating = 4.9,
  num ratingCount = 42,
  String vehiclePlate = 'أ ب ج 1245',
}) {
  return <String, dynamic>{
    ..._makeOrderMap(status: status, revision: 4),
    'driver': {
      'id': 'drv-77',
      'fullName': 'Karim Mansour',
      'phone': '+201012345678',
      'avatarUrl': null,
      'vehicleType': 'MOTORCYCLE',
      'vehiclePlate': vehiclePlate,
      'rating': rating,
      'ratingCount': ratingCount,
    },
  };
}

OrderSearchStatusDto _makeSearchStatus({
  String orderId = 'ord-custom-1',
  DriverSearchPhase phase = DriverSearchPhase.FINDING_DRIVERS,
  OrderStatus orderStatus = OrderStatus.LOOKING_FOR_DRIVER,
  SearchTerminalReason terminalReason = SearchTerminalReason.NONE,
  num attempt = 1,
  num maxAttempts = 5,
  num radiusKm = 3,
  num maxRadiusKm = 15,
  num nearbyAvailableCount = 4,
  num contactedCount = 2,
  num totalContactedCount = 2,
  num rejectedCount = 0,
  bool canRetry = false,
  num revision = 1,
  String? waveExpiresAt,
  GeoPointDto? driverLocation,
  num? driverDistanceKm,
  num? driverEtaMinutes,
  List<NearbyDriverPreviewDto> nearbyDrivers = const [],
}) {
  return OrderSearchStatusDto(
    (b) => b
      ..orderId = orderId
      ..orderNumber = 'OTL-8841'
      ..orderType = OrderType.CUSTOM_DELIVERY
      ..orderStatus = orderStatus
      ..revision = revision
      ..phase = phase
      ..attempt = attempt
      ..maxAttempts = maxAttempts
      ..radiusKm = radiusKm
      ..maxRadiusKm = maxRadiusKm
      ..contactedCount = contactedCount
      ..totalContactedCount = totalContactedCount
      ..rejectedCount = rejectedCount
      ..nearbyAvailableCount = nearbyAvailableCount
      ..nearbyDrivers = ListBuilder<NearbyDriverPreviewDto>(nearbyDrivers)
      ..searchTimeoutSecs = 30
      ..searchStartedAt = DateTime(2026, 11, 21, 2, 0).toIso8601String()
      ..updatedAt = DateTime(2026, 11, 21, 2, 1).toIso8601String()
      ..waveExpiresAt = waveExpiresAt
      ..terminalReason = terminalReason
      ..canRetry = canRetry
      ..driverLocation = driverLocation?.toBuilder()
      ..driverDistanceKm = driverDistanceKm
      ..driverEtaMinutes = driverEtaMinutes,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  group('order_geo_utils & CustomDeliveryDraft', () {
    test(
      'extractGeoPoint handles GeoJSON, map variants, and invalid coordinates',
      () {
        expect(
          extractGeoPoint([31.2357, 30.0444]),
          const LatLng(30.0444, 31.2357),
        );
        expect(
          extractGeoPoint({
            'type': 'Point',
            'coordinates': [31.25, 30.06],
          }),
          const LatLng(30.06, 31.25),
        );
        expect(
          extractGeoPoint({'latitude': '30.0444', 'longitude': '31.2357'}),
          const LatLng(30.0444, 31.2357),
        );
        expect(
          extractGeoPoint({'lat': 30.05, 'lng': 31.24}),
          const LatLng(30.05, 31.24),
        );
        expect(extractGeoPoint([0, 0]), isNull);
        expect(extractGeoPoint([200, 95]), isNull);
        expect(extractGeoPoint(null), isNull);
      },
    );

    test(
      'distanceKmBetween and computeBearingDegrees reject stationary jitter',
      () {
        const a = LatLng(30.0444, 31.2357);
        const nearbyJitter = LatLng(30.044405, 31.235705);
        const north = LatLng(30.0544, 31.2357);

        expect(computeBearingDegrees(a, nearbyJitter), isNull);
        final bearingNorth = computeBearingDegrees(a, north);
        expect(bearingNorth, isNotNull);
        expect(bearingNorth!, closeTo(0.0, 2.0));
        expect(distanceKmBetween(a, north), closeTo(1.11, 0.05));
      },
    );

    test(
      'fetchRoadRoutePoints caches OSRM geometry and returns null cleanly on error',
      () async {
        final dio = _FakeDio();
        const from = LatLng(30.0444, 31.2357);
        const to = LatLng(30.0600, 31.2500);

        final pts1 = await fetchRoadRoutePoints(dio, from, to);
        expect(pts1, isNotNull);
        expect(pts1!.length, 3);
        expect(dio.getCalls, 1);

        // Second lookup hits LRU cache instead of network.
        final pts2 = await fetchRoadRoutePoints(dio, from, to);
        expect(pts2, hasLength(3));
        expect(dio.getCalls, 1);

        // Different coordinates with failure return null rather than throwing or faking.
        dio.shouldFail = true;
        final failed = await fetchRoadRoutePoints(
          dio,
          const LatLng(30.1000, 31.3000),
          const LatLng(30.2000, 31.4000),
        );
        expect(failed, isNull);
      },
    );

    test(
      'CustomDeliveryDraft.fromOrder preserves request data across edit/retry',
      () {
        final order = _makeOrderMap(type: 'RIDE', status: 'CANCELLED')
          ..['requestedVehicleType'] = 'CAR'
          ..['paymentMethod'] = 'MOBILE_WALLET'
          ..['coinsUsed'] = 25;

        final draft = CustomDeliveryDraft.fromOrder(order);
        expect(draft, isNotNull);
        expect(draft!.serviceType, 'ride');
        expect(draft.vehicleType, 'car');
        expect(draft.pickupAddress, order['pickupAddress']);
        expect(draft.dropoffAddress, order['deliveryAddress']);
        expect(draft.pickupLocation, const LatLng(30.0444, 31.2357));
        expect(draft.dropoffLocation, const LatLng(30.0644, 31.3357));
        expect(draft.specialRequest, 'Call on arrival at gate B');
        expect(draft.paymentMethod, 'MOBILE_WALLET');
        expect(draft.useCoins, isTrue);
      },
    );
  });

  group('CustomDeliverySearchController real-time & race logic', () {
    late _FakeCustomerOrderRepo repo;
    late _FakeSocketService socket;
    late _FakeConnectivityService connectivity;
    late _FakeDio dio;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeCustomerOrderRepo();
      socket = _FakeSocketService();
      connectivity = _FakeConnectivityService();
      dio = _FakeDio();
      container = ProviderContainer(
        overrides: [
          customerOrderRepositoryProvider.overrideWithValue(repo),
          socketServiceProvider.overrideWithValue(socket),
          tokenServiceProvider.overrideWithValue(_FakeTokenService()),
          connectivityServiceProvider.overrideWithValue(connectivity),
          dioProvider.overrideWithValue(dio),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      connectivity.dispose();
      socket.disposeService();
    });

    test(
      'hydrates state, deduplicates stale search_progress events, and isolates driver.location updates',
      () async {
        final sub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final ctrl = container.read(
          customDeliverySearchControllerProvider('ord-custom-1').notifier,
        );

        var state = container.read(
          customDeliverySearchControllerProvider('ord-custom-1'),
        );
        expect(state.phase, DriverSearchPhase.FINDING_DRIVERS);
        expect(state.pickupPoint, const LatLng(30.0444, 31.2357));

        // Fresh seq=2 revision=1 -> advances phase to CONTACTING_DRIVERS.
        socket.fireEvent(SocketEvent.orderSearchProgress.eventName, {
          'orderId': 'ord-custom-1',
          'sequence': 2,
          'revision': 1,
          'phase': 'CONTACTING_DRIVERS',
          'orderStatus': 'LOOKING_FOR_DRIVER',
          'attempt': 1,
          'maxAttempts': 5,
          'radiusKm': 3,
          'maxRadiusKm': 15,
          'contactedCount': 2,
          'totalContactedCount': 2,
          'rejectedCount': 0,
          'searchTimeoutSecs': 30,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));
        state = container.read(
          customDeliverySearchControllerProvider('ord-custom-1'),
        );
        expect(state.phase, DriverSearchPhase.CONTACTING_DRIVERS);

        // Duplicate/older seq=1 must be ignored (no phase regression).
        socket.fireEvent(SocketEvent.orderSearchProgress.eventName, {
          'orderId': 'ord-custom-1',
          'sequence': 1,
          'revision': 1,
          'phase': 'QUEUED',
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container
              .read(customDeliverySearchControllerProvider('ord-custom-1'))
              .phase,
          DriverSearchPhase.CONTACTING_DRIVERS,
        );

        // Count whole-state rebuilds while emitting driver.location events.
        int stateChangeCount = 0;
        final countSub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) => stateChangeCount++,
        );
        addTearDown(countSub.close);

        int markerUpdates = 0;
        void onMarkerChange() => markerUpdates++;
        ctrl.driverLocationNotifier.addListener(onMarkerChange);
        addTearDown(
          () => ctrl.driverLocationNotifier.removeListener(onMarkerChange),
        );

        socket.fireEvent(SocketEvent.driverLocation.eventName, {
          'orderId': 'ord-custom-1',
          'driverId': 'drv-77',
          'location': {'latitude': 30.0480, 'longitude': 31.2380},
          'heading': 142.0,
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(markerUpdates, 1);
        expect(stateChangeCount, 0);
        expect(
          ctrl.driverLocationNotifier.value?.position,
          const LatLng(30.0480, 31.2380),
        );
        expect(
          ctrl.driverLocationNotifier.value?.distanceToPickupKm,
          isNotNull,
        );
      },
    );

    test(
      'resolves simultaneous cancel vs driver acceptance conflict cleanly',
      () async {
        final sub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final ctrl = container.read(
          customDeliverySearchControllerProvider('ord-custom-1').notifier,
        );

        repo.failNextCancelWithDriverAssigned = true;
        await ctrl.cancelSearch();

        final state = container.read(
          customDeliverySearchControllerProvider('ord-custom-1'),
        );
        expect(state.isDriverMatched, isTrue);
        expect(state.driver?['fullName'], 'Karim Mansour');
        expect(state.transientNoticeKey, 'app.searchRaceAlreadyAssigned');
        expect(state.isCancelling, isFalse);
      },
    );

    test(
      'retrySearch prevents concurrent duplicate requests and resets state',
      () async {
        repo.orderResponse = _makeOrderMap(
          status: 'CANCELLED',
          cancelledByRole: 'SYSTEM',
          cancelReason: 'No drivers accepted within maximum attempts',
        );
        repo.searchStatusResponse = _makeSearchStatus(
          phase: DriverSearchPhase.SEARCH_TIMEOUT,
          orderStatus: OrderStatus.CANCELLED,
          terminalReason: SearchTerminalReason.SEARCH_TIMEOUT,
          canRetry: true,
          revision: 2,
        );

        final sub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final ctrl = container.read(
          customDeliverySearchControllerProvider('ord-custom-1').notifier,
        );

        repo.retryCompleter = Completer<CustomerRetrySearchResult>();
        final f1 = ctrl.retrySearch();
        final f2 = ctrl.retrySearch();
        expect(repo.retryCalls, 1);

        final freshOrder = _makeOrderMap(
          status: 'LOOKING_FOR_DRIVER',
          revision: 3,
        );
        final freshStatus = _makeSearchStatus(
          phase: DriverSearchPhase.QUEUED,
          orderStatus: OrderStatus.LOOKING_FOR_DRIVER,
          canRetry: false,
          revision: 3,
        );
        repo.retryCompleter!.complete(
          CustomerRetrySearchResult(
            retried: true,
            order: freshOrder,
            searchStatus: freshStatus,
            alreadySearching: false,
            alreadyAssigned: false,
          ),
        );
        await Future.wait([f1, f2]);

        final state = container.read(
          customDeliverySearchControllerProvider('ord-custom-1'),
        );
        expect(state.isSearching, isTrue);
        expect(state.phase, DriverSearchPhase.QUEUED);
        expect(state.isRetrying, isFalse);
      },
    );

    test(
      'resyncs when offline->online connectivity or app resume fires',
      () async {
        final sub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final initialCalls = repo.getOrderCalls;

        connectivity.emitOnline(false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container
              .read(customDeliverySearchControllerProvider('ord-custom-1'))
              .isOffline,
          isTrue,
        );

        connectivity.emitOnline(true);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(
          container
              .read(customDeliverySearchControllerProvider('ord-custom-1'))
              .isOffline,
          isFalse,
        );
        expect(repo.getOrderCalls, greaterThan(initialCalls));
      },
    );

    test(
      'tracks real nearby vehicles by anonymized markerKey with real bearing, zero root rebuilds on silent polls, and clears on driver match',
      () async {
        repo.orderResponse = _makeOrderMap(type: 'RIDE')
          ..['requestedVehicleType'] = 'CAR';
        repo.searchStatusResponse = _makeSearchStatus(
          phase: DriverSearchPhase.FINDING_DRIVERS,
          nearbyAvailableCount: 2,
          nearbyDrivers: [
            NearbyDriverPreviewDto(
              (b) => b
                ..markerKey = 'a1b2c3d4e5f6'
                ..latitude = 30.0444
                ..longitude = 31.2357
                ..vehicleType = VehicleType.CAR
                ..distanceKm = 0.8,
            ),
            NearbyDriverPreviewDto(
              (b) => b
                ..markerKey = 'f6e5d4c3b2a1'
                ..latitude = 30.0460
                ..longitude = 31.2390
                ..vehicleType = VehicleType.CAR
                ..distanceKm = 1.2,
            ),
          ],
        );

        final sub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final ctrl = container.read(
          customDeliverySearchControllerProvider('ord-custom-1').notifier,
        );

        expect(ctrl.nearbyVehiclesNotifier.value, hasLength(2));
        expect(
          ctrl.nearbyVehiclesNotifier.value.first.markerKey,
          'a1b2c3d4e5f6',
        );
        expect(ctrl.nearbyVehiclesNotifier.value.first.vehicleType, 'CAR');

        // Listen for whole-screen state changes during silent nearby-vehicle poll.
        int rootStateChanges = 0;
        final stateSub = container.listen(
          customDeliverySearchControllerProvider('ord-custom-1'),
          (_, _) => rootStateChanges++,
        );
        addTearDown(stateSub.close);

        int nearbyUpdates = 0;
        void onNearbyChanged() => nearbyUpdates++;
        ctrl.nearbyVehiclesNotifier.addListener(onNearbyChanged);
        addTearDown(
          () => ctrl.nearbyVehiclesNotifier.removeListener(onNearbyChanged),
        );

        // Real car moves north (~550m); all search metadata stays identical.
        repo.searchStatusResponse = _makeSearchStatus(
          phase: DriverSearchPhase.FINDING_DRIVERS,
          nearbyAvailableCount: 2,
          nearbyDrivers: [
            NearbyDriverPreviewDto(
              (b) => b
                ..markerKey = 'a1b2c3d4e5f6'
                ..latitude = 30.0494
                ..longitude = 31.2357
                ..vehicleType = VehicleType.CAR
                ..distanceKm = 0.5,
            ),
            NearbyDriverPreviewDto(
              (b) => b
                ..markerKey = 'f6e5d4c3b2a1'
                ..latitude = 30.0460
                ..longitude = 31.2390
                ..vehicleType = VehicleType.CAR
                ..distanceKm = 1.2,
            ),
          ],
        );

        await ctrl.resync(statusOnly: true, silent: true);

        expect(nearbyUpdates, 1);
        expect(rootStateChanges, 0);
        final movedCar = ctrl.nearbyVehiclesNotifier.value.firstWhere(
          (v) => v.markerKey == 'a1b2c3d4e5f6',
        );
        expect(movedCar.isMoving, isTrue);
        expect(movedCar.heading, closeTo(0.0, 2.0));

        // Once driver accepts, nearby searching vehicles clear cleanly.
        repo.orderResponse = _makeAssignedOrderMap();
        repo.searchStatusResponse = _makeSearchStatus(
          phase: DriverSearchPhase.DRIVER_FOUND,
          orderStatus: OrderStatus.DRIVER_ASSIGNED,
          revision: 4,
          driverLocation: GeoPointDto(
            (b) => b
              ..latitude = 30.0470
              ..longitude = 31.2370,
          ),
        );
        await ctrl.resync();
        expect(ctrl.nearbyVehiclesNotifier.value, isEmpty);
        expect(
          ctrl.driverLocationNotifier.value?.position,
          const LatLng(30.0470, 31.2370),
        );
      },
    );
  });

  group('CustomDeliverySearchScreen UI, SafeArea, TextScaler & RTL/LTR', () {
    Future<_StubCustomDeliverySearchController> pumpSearchScreen(
      WidgetTester tester, {
      required CustomDeliverySearchState initialState,
      DriverLiveMarkerState? liveDriver,
      Locale locale = const Locale('en'),
      Size viewport = const Size(390, 844),
      double textScale = 1.0,
      EdgeInsets safePadding = const EdgeInsets.only(top: 47, bottom: 34),
    }) async {
      final stub = _StubCustomDeliverySearchController(
        initialState,
        live: liveDriver,
      );

      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(
        top: safePadding.top,
        bottom: safePadding.bottom,
        left: safePadding.left,
        right: safePadding.right,
      );
      tester.view.viewPadding = FakeViewPadding(
        top: safePadding.top,
        bottom: safePadding.bottom,
        left: safePadding.left,
        right: safePadding.right,
      );

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customDeliverySearchControllerProvider(
              initialState.orderId,
            ).overrideWith(() => stub),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'unused',
            fallbackLocale: const Locale('en'),
            startLocale: locale,
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
            child: Builder(
              builder: (locCtx) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locCtx.locale,
                  supportedLocales: locCtx.supportedLocales,
                  localizationsDelegates: locCtx.localizationDelegates,
                  builder: (ctx, child) {
                    final mq = MediaQuery.of(ctx);
                    return MediaQuery(
                      data: mq.copyWith(
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  home: CustomDeliverySearchScreen(
                    orderId: initialState.orderId,
                    initialOrder: initialState.order,
                    mapBuilder: (_, _) => const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));
      return stub;
    }

    testWidgets(
      'shows Searching status, metrics, route, and handles Cancel Search dialog',
      (tester) async {
        final stub = await pumpSearchScreen(
          tester,
          initialState: CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: _makeOrderMap(),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.CONTACTING_DRIVERS,
              attempt: 2,
              maxAttempts: 5,
              radiusKm: 6,
              nearbyAvailableCount: 4,
              totalContactedCount: 3,
              rejectedCount: 1,
              waveExpiresAt: DateTime.now()
                  .add(const Duration(seconds: 22))
                  .toIso8601String(),
            ),
            isInitialLoading: false,
          ),
        );

        expect(find.text('Finding a Driver for You'), findsOneWidget);
        expect(find.text('Contacting nearby drivers...'), findsOneWidget);
        expect(find.text('Wave 2 of 5'), findsOneWidget);
        expect(find.text('Within 6 km'), findsOneWidget);
        expect(find.text('4 nearby online'), findsOneWidget);
        expect(find.text('3 drivers contacted'), findsOneWidget);
        expect(find.text('1 declined'), findsOneWidget);
        expect(find.textContaining('14 Tahrir St'), findsOneWidget);

        final cancelFinder = find.text('Cancel Search');
        expect(cancelFinder, findsOneWidget);
        await tester.ensureVisible(cancelFinder);
        await tester.tap(cancelFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('Cancel Driver Search?'), findsOneWidget);

        // Tapping Keep Searching leaves cancelCalls == 0.
        await tester.tap(find.text('Keep Searching'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(stub.cancelCalls, 0);

        // Re-open dialog and confirm cancellation.
        await tester.ensureVisible(find.text('Cancel Search'));
        await tester.tap(find.text('Cancel Search'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        await tester.tap(find.text('Yes, Cancel Search'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(stub.cancelCalls, 1);

        // While cancelling is in progress, button locks to prevent double-cancel.
        expect(find.text('Cancelling search...'), findsOneWidget);
        await tester.tap(find.text('Cancelling search...'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(stub.cancelCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows Driver Found info without fake rating/ETA and updates distance live',
      (tester) async {
        final orderNoFakeRating = _makeAssignedOrderMap(
          status: 'PENDING_PAYMENT',
          rating: 0,
          ratingCount: 0,
          vehiclePlate: 'س ص 9090',
        );
        final stub = await pumpSearchScreen(
          tester,
          initialState: CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: orderNoFakeRating,
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.PENDING_PAYMENT,
              driverEtaMinutes: null,
            ),
            isInitialLoading: false,
          ),
          liveDriver: const DriverLiveMarkerState(
            position: LatLng(30.0490, 31.2390),
            heading: 90,
            isMoving: true,
            distanceToPickupKm: 1.4,
          ),
        );

        expect(find.text('Driver Found!'), findsOneWidget);
        expect(
          find.text('Driver accepted! Complete your payment to confirm.'),
          findsOneWidget,
        );
        expect(find.text('Karim Mansour'), findsOneWidget);
        expect(find.text('س ص 9090'), findsOneWidget);
        expect(find.text('1.4 km away'), findsOneWidget);
        // No fake rating when ratingCount == 0, and no fabricated ETA when null.
        expect(find.byIcon(Icons.star_rounded), findsNothing);
        expect(find.textContaining('Est.'), findsNothing);
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('inline_pending_payment_card')),
          findsOneWidget,
        );
        expect(find.text('Wallet transfer required'), findsOneWidget);
        expect(
          find.text('Attach transfer screenshot (required)'),
          findsOneWidget,
        );
        expect(find.text('I have transferred the amount'), findsOneWidget);

        // Live driver distance updates via ValueNotifier without recreating state.
        stub.driverLocationNotifier.value = const DriverLiveMarkerState(
          position: LatLng(30.0460, 31.2360),
          heading: 45,
          isMoving: true,
          distanceToPickupKm: 0.6,
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('0.6 km away'), findsOneWidget);

        // When real rating & ETA are returned by backend, render them cleanly.
        stub.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: _makeAssignedOrderMap(
              status: 'DRIVER_ASSIGNED',
              rating: 4.9,
              ratingCount: 42,
              vehiclePlate: 'س ص 9090',
            ),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.DRIVER_ASSIGNED,
              driverEtaMinutes: 7,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('4.9 (42)'), findsOneWidget);
        expect(find.text('Est. 7 min'), findsOneWidget);
        expect(find.text('Complete Wallet Payment'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows Search Timeout state with Retry Search and Edit Request Details',
      (tester) async {
        final stub = await pumpSearchScreen(
          tester,
          initialState: CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: _makeOrderMap(
              status: 'CANCELLED',
              cancelledByRole: 'SYSTEM',
              cancelReason: 'No drivers accepted within maximum attempts',
            ),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.SEARCH_TIMEOUT,
              orderStatus: OrderStatus.CANCELLED,
              terminalReason: SearchTerminalReason.SEARCH_TIMEOUT,
              canRetry: true,
            ),
            isInitialLoading: false,
          ),
        );

        expect(find.text('No Driver Accepted in Time'), findsOneWidget);
        expect(find.text('Retry Search'), findsOneWidget);
        expect(find.text('Edit Request Details'), findsOneWidget);
        expect(find.textContaining('14 Tahrir St'), findsOneWidget);

        await tester.ensureVisible(find.text('Retry Search'));
        await tester.tap(find.text('Retry Search'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(stub.retryCalls, 1);

        // Second tap while retry is in flight is ignored.
        expect(find.text('Starting new search...'), findsOneWidget);
        await tester.tap(find.text('Starting new search...'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(stub.retryCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'respects SafeArea, RTL/LTR, and TextScaler 0.85x..2.0x on 320x568 and 800x1024 without overflow',
      (tester) async {
        final scenarios =
            <
              ({
                String name,
                CustomDeliverySearchState state,
                Locale locale,
                Size size,
                double scale,
              })
            >[
              (
                name: 'Searching EN 320x568 1.6x offline',
                state: CustomDeliverySearchState(
                  orderId: 'ord-custom-1',
                  order: _makeOrderMap(),
                  searchStatus: _makeSearchStatus(
                    phase: DriverSearchPhase.WAITING_DRIVER_RESPONSE,
                    waveExpiresAt: DateTime.now()
                        .add(const Duration(seconds: 15))
                        .toIso8601String(),
                  ),
                  isInitialLoading: false,
                  isOffline: true,
                ),
                locale: const Locale('en'),
                size: const Size(320, 568),
                scale: 1.6,
              ),
              (
                name: 'Driver Found AR RTL 320x568 2.0x',
                state: CustomDeliverySearchState(
                  orderId: 'ord-custom-1',
                  order: _makeAssignedOrderMap(),
                  searchStatus: _makeSearchStatus(
                    phase: DriverSearchPhase.DRIVER_FOUND,
                    orderStatus: OrderStatus.DRIVER_ASSIGNED,
                    driverDistanceKm: 2.3,
                    driverEtaMinutes: 6,
                  ),
                  isInitialLoading: false,
                ),
                locale: const Locale('ar'),
                size: const Size(320, 568),
                scale: 2.0,
              ),
              (
                name: 'No Drivers AR RTL 800x1024 0.85x',
                state: CustomDeliverySearchState(
                  orderId: 'ord-custom-1',
                  order: _makeOrderMap(status: 'CANCELLED'),
                  searchStatus: _makeSearchStatus(
                    phase: DriverSearchPhase.NO_DRIVERS_AVAILABLE,
                    orderStatus: OrderStatus.CANCELLED,
                    terminalReason: SearchTerminalReason.NO_DRIVERS_AVAILABLE,
                    canRetry: true,
                  ),
                  isInitialLoading: false,
                ),
                locale: const Locale('ar'),
                size: const Size(800, 1024),
                scale: 0.85,
              ),
            ];

        for (final sc in scenarios) {
          await pumpSearchScreen(
            tester,
            initialState: sc.state,
            locale: sc.locale,
            viewport: sc.size,
            textScale: sc.scale,
            liveDriver: sc.state.isDriverMatched
                ? const DriverLiveMarkerState(
                    position: LatLng(30.05, 31.24),
                    heading: 0,
                    isMoving: false,
                    distanceToPickupKm: 2.3,
                  )
                : null,
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'Unexpected layout/overflow exception in ${sc.name}',
          );

          // Verify top floating back button stays strictly below notch inset (top >= 47).
          final backBtnRect = tester.getRect(
            find.byIcon(Icons.arrow_back_ios_new_rounded),
          );
          expect(
            backBtnRect.top,
            greaterThanOrEqualTo(47.0),
            reason: 'Back button overlaps SafeArea top inset in ${sc.name}',
          );

          // Unmount before next iteration.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      },
    );

    testWidgets(
      'ui_kit DriverSearchRadarPulse & RouteEndpointsCard render cleanly at 2.0x scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DriverSearchRadarPulse(
                        size: 180,
                        color: Colors.amber,
                        isActive: true,
                      ),
                      SizedBox(height: 16),
                      RouteEndpointsCard(
                        pickupLabel: 'Pickup',
                        pickupAddress:
                            'Very Long Pickup Address in Downtown Cairo, Egypt',
                        dropoffLabel: 'Drop-off',
                        dropoffAddress:
                            'Very Long Destination Address in New Cairo District',
                        pickupColor: Colors.green,
                        dropoffColor: Colors.red,
                        itemDetailsLabel: 'Items',
                        itemDetails:
                            'Two sealed cartons with fragile glassware inside',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows Ride vs Custom Delivery service & vehicle icon cleanly in EN LTR and AR RTL',
      (tester) async {
        final rideOrder = _makeOrderMap(type: 'RIDE')
          ..['requestedVehicleType'] = 'CAR';

        await pumpSearchScreen(
          tester,
          locale: const Locale('en'),
          initialState: CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: rideOrder,
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.FINDING_DRIVERS,
              nearbyAvailableCount: 3,
            ),
            isInitialLoading: false,
          ),
        );

        expect(find.text('Ride · #OTL-8841'), findsOneWidget);
        expect(find.byIcon(VehicleTypeHelper.icon('CAR')), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        final truckOrder = _makeOrderMap(type: 'CUSTOM_DELIVERY')
          ..['requestedVehicleType'] = 'HALF_TRUCK';

        await pumpSearchScreen(
          tester,
          locale: const Locale('ar'),
          initialState: CustomDeliverySearchState(
            orderId: 'ord-custom-1',
            order: truckOrder,
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.CONTACTING_DRIVERS,
              nearbyAvailableCount: 2,
            ),
            isInitialLoading: false,
          ),
        );

        expect(find.text('توصيل · #OTL-8841'), findsOneWidget);
        expect(find.byIcon(VehicleTypeHelper.icon('HALF_TRUCK')), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'InDriveVehicleMarker renders all 8 vehicle types cleanly with zero-ticker mode and showCargoBox variants',
      (tester) async {
        const vehicleTypes = <String>[
          'MOTORCYCLE',
          'CAR',
          'MINIBUS',
          'TUK_TUK',
          'MOTOR_TRICYCLE',
          'QUARTER_TRUCK',
          'HALF_TRUCK',
          'BICYCLE',
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in vehicleTypes)
                    InDriveVehicleMarker(
                      size: 44,
                      vehicleType: v,
                      heading: 45,
                      isMoving: true,
                      showRadarPulse: false,
                      showCargoBox: v != 'MOTORCYCLE',
                    ),
                  const InDriveVehicleMarker(
                    size: 54,
                    vehicleType: 'MOTORCYCLE',
                    heading: 120,
                    isMoving: true,
                    showRadarPulse: true,
                    showCargoBox: true,
                    plateNumber: 'أ ب 123',
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 120));
        expect(find.byType(InDriveVehicleMarker), findsNWidgets(9));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ride full live journey on same screen: live ETA -> driver arrived -> ride started -> ride completed (EN LTR)',
      (tester) async {
        Map<String, dynamic> makeRideOrder(String status) =>
            _makeAssignedOrderMap(
              status: status,
              rating: 4.8,
              ratingCount: 25,
              vehiclePlate: 'أ ب ج 1234',
            )
              ..['type'] = 'RIDE'
              ..['requestedVehicleType'] = 'CAR'
              ..['itemDetails'] = 'Should never render on Ride'
              ..['paymentMethod'] = 'CASH_ON_DELIVERY';

        final stub = await pumpSearchScreen(
          tester,
          locale: const Locale('en'),
          initialState: CustomDeliverySearchState(
            orderId: 'ord-ride-1',
            order: makeRideOrder('DRIVER_ASSIGNED'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.DRIVER_ASSIGNED,
              driverEtaMinutes: 6,
              driverDistanceKm: 1.8,
            ),
            isInitialLoading: false,
          ),
          liveDriver: const DriverLiveMarkerState(
            position: LatLng(30.049, 31.239),
            heading: 90,
            isMoving: true,
            distanceToPickupKm: 1.8,
            etaMinutes: 6,
          ),
        );

        // Stage 1: Assigned & heading to pickup with live ETA
        expect(find.text('Driver Found!'), findsOneWidget);
        expect(find.text('Arriving in 6 min'), findsOneWidget);
        expect(find.text('Est. 6 min'), findsOneWidget);
        // Ride separation checks: no "Package Details", "Cash" instead of "Cash on Delivery"
        expect(find.text('Should never render on Ride'), findsNothing);
        expect(find.text('Cash'), findsOneWidget);
        expect(find.text('Cash on Delivery'), findsNothing);

        // Live ETA updates via ValueNotifier without rebuilding whole screen
        stub.driverLocationNotifier.value = const DriverLiveMarkerState(
          position: LatLng(30.045, 31.236),
          heading: 90,
          isMoving: true,
          distanceToPickupKm: 0.7,
          etaMinutes: 3,
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('Arriving in 3 min'), findsOneWidget);
        expect(find.text('Est. 3 min'), findsOneWidget);

        // Stage 2: Driver arrives at pickup (READY_FOR_PICKUP)
        stub.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-ride-1',
            order: makeRideOrder('READY_FOR_PICKUP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.READY_FOR_PICKUP,
              driverEtaMinutes: 0,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Your driver has arrived!'), findsOneWidget);
        expect(
          find.text('Head to your pickup point to start your ride.'),
          findsOneWidget,
        );
        expect(find.text('Driver accepted your request.'), findsNothing);

        // Stage 3: Driver starts ride (PICKED_UP)
        stub.driverLocationNotifier.value = const DriverLiveMarkerState(
          position: LatLng(30.052, 31.242),
          heading: 45,
          isMoving: true,
          distanceToPickupKm: 4.2,
          etaMinutes: 11,
        );
        stub.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-ride-1',
            order: makeRideOrder('PICKED_UP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.PICKED_UP,
              driverEtaMinutes: 11,
              driverDistanceKm: 4.2,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Your ride has started!'), findsOneWidget);
        expect(find.text('11 min to destination'), findsWidgets);
        expect(find.text('4.2 km to destination'), findsOneWidget);
        expect(find.text('Driver accepted your request.'), findsNothing);
        expect(find.text('Your driver has arrived!'), findsNothing);

        // Stage 4: Ride completed (DELIVERED)
        stub.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-ride-1',
            order: makeRideOrder('DELIVERED'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.DELIVERED,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Your ride is complete!'), findsOneWidget);
        expect(find.text('Rate Ride'), findsOneWidget);
        expect(find.text('Back to Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Custom Delivery full live journey in EN LTR: arrived -> on its way -> completed',
      (tester) async {
        Map<String, dynamic> makeCustomOrder(String status) =>
            _makeAssignedOrderMap(
              status: status,
              rating: 4.9,
              ratingCount: 15,
              vehiclePlate: 'ق ن 5511',
            )..['type'] = 'CUSTOM_DELIVERY';

        final stubEn = await pumpSearchScreen(
          tester,
          locale: const Locale('en'),
          initialState: CustomDeliverySearchState(
            orderId: 'ord-del-en',
            order: makeCustomOrder('READY_FOR_PICKUP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.READY_FOR_PICKUP,
              driverEtaMinutes: 0,
            ),
            isInitialLoading: false,
          ),
        );
        expect(find.text('Your driver has arrived!'), findsOneWidget);
        expect(
          find.text(
            'Meet your driver at the pickup point to hand over your package.',
          ),
          findsOneWidget,
        );

        stubEn.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-del-en',
            order: makeCustomOrder('PICKED_UP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.PICKED_UP,
              driverEtaMinutes: 9,
              driverDistanceKm: 3.1,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Your delivery is on its way!'), findsOneWidget);
        expect(find.text('Driver accepted your request.'), findsNothing);

        stubEn.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-del-en',
            order: makeCustomOrder('DELIVERED'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.DELIVERED,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Your delivery is complete!'), findsOneWidget);
        expect(find.text('Rate Delivery'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Custom Delivery full live journey in AR RTL at 1.4x scale: arrived -> on its way -> completed',
      (tester) async {
        Map<String, dynamic> makeCustomOrder(String status) =>
            _makeAssignedOrderMap(
              status: status,
              rating: 4.9,
              ratingCount: 15,
              vehiclePlate: 'ق ن 5511',
            )..['type'] = 'CUSTOM_DELIVERY';

        final stubAr = await pumpSearchScreen(
          tester,
          locale: const Locale('ar'),
          textScale: 1.4,
          initialState: CustomDeliverySearchState(
            orderId: 'ord-del-ar',
            order: makeCustomOrder('READY_FOR_PICKUP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.READY_FOR_PICKUP,
              driverEtaMinutes: 0,
            ),
            isInitialLoading: false,
          ),
        );
        expect(find.text('وصل السائق!'), findsOneWidget);

        stubAr.setStateForTest(
          CustomDeliverySearchState(
            orderId: 'ord-del-ar',
            order: makeCustomOrder('PICKED_UP'),
            searchStatus: _makeSearchStatus(
              phase: DriverSearchPhase.DRIVER_FOUND,
              orderStatus: OrderStatus.PICKED_UP,
              driverEtaMinutes: 8,
            ),
            isInitialLoading: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('توصيلك في الطريق!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
