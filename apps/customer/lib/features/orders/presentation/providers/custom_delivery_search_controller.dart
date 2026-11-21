import 'dart:async';
import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:core/core.dart'
    show
        SocketEvent,
        connectivityServiceProvider,
        dioProvider,
        orderRevisionOf,
        orderRevisionTrackerProvider;
import 'package:data/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/token_service.dart';
import '../utils/order_geo_utils.dart';
import 'orders_provider.dart';

part 'custom_delivery_search_controller.g.dart';

/// Immutable draft passed between Custom Delivery form and the Search screen
/// so the customer never loses entered addresses, locations, or notes.
class CustomDeliveryDraft {
  const CustomDeliveryDraft({
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLocation,
    this.dropoffLocation,
    required this.vehicleType,
    this.itemDetails,
    this.specialRequest,
    this.paymentMethod = 'CASH_ON_DELIVERY',
    this.useCoins = false,
  });

  final String serviceType; // 'delivery' or 'ride'
  final String pickupAddress;
  final String dropoffAddress;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final String
  vehicleType; // lowercase: motorcycle, car, bicycle, van, truck, motor_tricycle
  final String? itemDetails;
  final String? specialRequest;
  final String paymentMethod;
  final bool useCoins;

  static CustomDeliveryDraft? fromOrder(Map<String, dynamic>? order) {
    if (order == null) return null;
    final rawType = order['type']?.toString().toUpperCase();
    final isRide = rawType == 'RIDE';
    final rawVehicle = order['requestedVehicleType']?.toString().toLowerCase();
    final rawPayment = order['paymentMethod']?.toString() ?? 'CASH_ON_DELIVERY';

    return CustomDeliveryDraft(
      serviceType: isRide ? 'ride' : 'delivery',
      pickupAddress: order['pickupAddress']?.toString() ?? '',
      dropoffAddress: order['deliveryAddress']?.toString() ?? '',
      pickupLocation: extractGeoPoint(order['pickupLocation']),
      dropoffLocation: extractGeoPoint(order['deliveryLocation']),
      vehicleType: (rawVehicle != null && rawVehicle.isNotEmpty)
          ? rawVehicle
          : (isRide ? 'car' : 'motorcycle'),
      itemDetails: order['itemDetails']?.toString(),
      specialRequest: order['specialRequest']?.toString(),
      paymentMethod: rawPayment,
      useCoins: ((order['coinsUsed'] as num?)?.toInt() ?? 0) > 0,
    );
  }
}

/// High-frequency live driver marker snapshot stored in a [ValueNotifier] so
/// incoming driver coordinates never rebuild the entire search screen.
@immutable
class DriverLiveMarkerState {
  const DriverLiveMarkerState({
    required this.position,
    required this.heading,
    required this.isMoving,
    this.distanceToPickupKm,
  });

  final LatLng position;
  final double heading;
  final bool isMoving;
  final double? distanceToPickupKm;

  DriverLiveMarkerState copyWith({
    LatLng? position,
    double? heading,
    bool? isMoving,
    double? distanceToPickupKm,
  }) {
    return DriverLiveMarkerState(
      position: position ?? this.position,
      heading: heading ?? this.heading,
      isMoving: isMoving ?? this.isMoving,
      distanceToPickupKm: distanceToPickupKm ?? this.distanceToPickupKm,
    );
  }
}

@immutable
class CustomDeliverySearchState {
  const CustomDeliverySearchState({
    required this.orderId,
    this.order,
    this.searchStatus,
    this.routePoints,
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isCancelling = false,
    this.isRetrying = false,
    this.isOffline = false,
    this.isSocketReconnecting = false,
    this.transientNoticeKey,
    this.errorKey,
  });

  final String orderId;
  final Map<String, dynamic>? order;
  final OrderSearchStatusDto? searchStatus;
  final List<LatLng>? routePoints;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isCancelling;
  final bool isRetrying;
  final bool isOffline;
  final bool isSocketReconnecting;
  final String? transientNoticeKey;
  final String? errorKey;

  LatLng? get pickupPoint => extractGeoPoint(order?['pickupLocation']);
  LatLng? get dropoffPoint => extractGeoPoint(order?['deliveryLocation']);

  String get orderStatus =>
      (order?['status'] ??
              searchStatus?.orderStatus.name ??
              'LOOKING_FOR_DRIVER')
          .toString();

  bool get isDriverAssignedOnOrder {
    final status = orderStatus;
    if (status == 'DRIVER_ASSIGNED' ||
        status == 'PENDING_PAYMENT' ||
        status == 'PREPARING' ||
        status == 'READY_FOR_PICKUP' ||
        status == 'PARTIALLY_PICKED_UP' ||
        status == 'PICKED_UP' ||
        status == 'DELIVERED') {
      return true;
    }
    return driver != null;
  }

  DriverSearchPhase get phase {
    final sPhase = searchStatus?.phase;
    if (isDriverAssignedOnOrder) {
      return DriverSearchPhase.DRIVER_FOUND;
    }
    if (orderStatus == 'CANCELLED') {
      if (sPhase == DriverSearchPhase.NO_DRIVERS_AVAILABLE ||
          sPhase == DriverSearchPhase.SEARCH_TIMEOUT ||
          sPhase == DriverSearchPhase.CANCELLED) {
        return sPhase!;
      }
      final reason = (order?['cancelReason'] ?? '').toString().toLowerCase();
      if (reason.contains('no available drivers')) {
        return DriverSearchPhase.NO_DRIVERS_AVAILABLE;
      }
      if (reason.contains('no drivers accepted') ||
          reason.contains('maximum attempts')) {
        return DriverSearchPhase.SEARCH_TIMEOUT;
      }
      return DriverSearchPhase.CANCELLED;
    }
    return sPhase ?? DriverSearchPhase.QUEUED;
  }

  SearchTerminalReason get terminalReason {
    final r = searchStatus?.terminalReason;
    if (r != null && r != SearchTerminalReason.NONE) {
      return r;
    }
    return switch (phase) {
      DriverSearchPhase.NO_DRIVERS_AVAILABLE =>
        SearchTerminalReason.NO_DRIVERS_AVAILABLE,
      DriverSearchPhase.SEARCH_TIMEOUT => SearchTerminalReason.SEARCH_TIMEOUT,
      DriverSearchPhase.CANCELLED =>
        order?['cancelledByRole']?.toString() == 'CUSTOMER'
            ? SearchTerminalReason.CANCELLED_BY_CUSTOMER
            : SearchTerminalReason.CANCELLED_BY_SYSTEM,
      _ => SearchTerminalReason.NONE,
    };
  }

  bool get isDriverMatched => phase == DriverSearchPhase.DRIVER_FOUND;

  bool get isTerminal =>
      !isDriverMatched &&
      (orderStatus == 'CANCELLED' ||
          phase == DriverSearchPhase.SEARCH_TIMEOUT ||
          phase == DriverSearchPhase.NO_DRIVERS_AVAILABLE ||
          phase == DriverSearchPhase.CANCELLED);

  bool get isSearching => !isDriverMatched && !isTerminal;

  Map<String, dynamic>? get driver {
    final direct = order?['driver'];
    if (direct is Map && direct.isNotEmpty) {
      return Map<String, dynamic>.from(direct);
    }
    final groups = order?['deliveryGroups'];
    if (groups is List) {
      for (final g in groups) {
        if (g is Map &&
            g['status'] != 'CANCELLED' &&
            g['primaryDriver'] is Map) {
          return Map<String, dynamic>.from(g['primaryDriver'] as Map);
        }
      }
    }
    return null;
  }

  bool get canRetry =>
      isTerminal &&
      (searchStatus?.canRetry ??
          (orderStatus == 'CANCELLED' &&
              driver == null &&
              (order?['type'] == 'CUSTOM_DELIVERY' ||
                  order?['type'] == 'RIDE')));

  CustomDeliverySearchState copyWith({
    Map<String, dynamic>? order,
    OrderSearchStatusDto? searchStatus,
    List<LatLng>? routePoints,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isCancelling,
    bool? isRetrying,
    bool? isOffline,
    bool? isSocketReconnecting,
    String? transientNoticeKey,
    bool clearTransientNotice = false,
    String? errorKey,
    bool clearErrorKey = false,
  }) {
    return CustomDeliverySearchState(
      orderId: orderId,
      order: order ?? this.order,
      searchStatus: searchStatus ?? this.searchStatus,
      routePoints: routePoints ?? this.routePoints,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCancelling: isCancelling ?? this.isCancelling,
      isRetrying: isRetrying ?? this.isRetrying,
      isOffline: isOffline ?? this.isOffline,
      isSocketReconnecting: isSocketReconnecting ?? this.isSocketReconnecting,
      transientNoticeKey: clearTransientNotice
          ? null
          : (transientNoticeKey ?? this.transientNoticeKey),
      errorKey: clearErrorKey ? null : (errorKey ?? this.errorKey),
    );
  }
}

@riverpod
class CustomDeliverySearchController extends _$CustomDeliverySearchController {
  /// Isolated high-frequency notifier so driver movement never rebuilds the UI.
  final ValueNotifier<DriverLiveMarkerState?> driverLocationNotifier =
      ValueNotifier<DriverLiveMarkerState?>(null);

  StreamSubscription<dynamic>? _searchProgressSub;
  StreamSubscription<dynamic>? _orderStatusSub;
  StreamSubscription<dynamic>? _orderAssignedSub;
  StreamSubscription<dynamic>? _orderCancelledSub;
  StreamSubscription<dynamic>? _driverLocSub;
  StreamSubscription<void>? _socketConnectSub;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _safetyPollTimer;
  Timer? _routeFetchDebounce;

  bool _disposed = false;
  bool _socketAttached = false;
  int _lastSearchSeq = 0;
  DateTime? _lastLocationAppliedAt;
  String? _loadedRoutePairKey;

  Future<void>? _inflightSync;
  bool _syncQueued = false;

  @override
  CustomDeliverySearchState build(String orderId) {
    _disposed = false;
    final seeded = _lookupCachedOrder(orderId);
    final connectivity = ref.read(connectivityServiceProvider);
    final initialOffline = connectivity.lastKnownStatus == false;

    _connectivitySub = connectivity.onConnectivityChanged.listen((isOnline) {
      if (_disposed) return;
      final wasOffline = state.isOffline;
      state = state.copyWith(isOffline: !isOnline);
      if (isOnline && wasOffline) {
        unawaited(_ensureSocketConnectedAndSync());
      }
    });

    ref.onDispose(() {
      _disposed = true;
      _searchProgressSub?.cancel();
      _orderStatusSub?.cancel();
      _orderAssignedSub?.cancel();
      _orderCancelledSub?.cancel();
      _driverLocSub?.cancel();
      _socketConnectSub?.cancel();
      _connectivitySub?.cancel();
      _safetyPollTimer?.cancel();
      _routeFetchDebounce?.cancel();
      driverLocationNotifier.dispose();
    });

    Future.microtask(() async {
      if (_disposed) return;
      await Future.wait([resync(), _attachSocketListeners()]);
      _ensureSafetyPolling();
    });

    return CustomDeliverySearchState(
      orderId: orderId,
      order: seeded,
      isInitialLoading: seeded == null,
      isOffline: initialOffline,
    );
  }

  Map<String, dynamic>? _lookupCachedOrder(String id) {
    final ordersState = ref.read(ordersProvider);
    for (final o in ordersState.activeOrders) {
      if (o['id']?.toString() == id) return o;
    }
    for (final o in ordersState.pastOrders) {
      if (o['id']?.toString() == id) return o;
    }
    return null;
  }

  /// Seeds initial order snapshot (passed via route `extra`) on first frame.
  void seedOrderSnapshot(Map<String, dynamic>? initialOrder) {
    if (_disposed || initialOrder == null) return;
    if (state.order == null) {
      state = state.copyWith(order: initialOrder, isInitialLoading: false);
      _maybeFetchRoadRoute();
    }
  }

  void clearTransientNotice() {
    if (_disposed || state.transientNoticeKey == null) return;
    state = state.copyWith(clearTransientNotice: true);
  }

  Future<void> onAppResumed() => _ensureSocketConnectedAndSync();

  Future<void> _ensureSocketConnectedAndSync() async {
    if (_disposed) return;
    state = state.copyWith(isSocketReconnecting: true);
    try {
      final socket = ref.read(socketServiceProvider);
      if (!socket.isConnected) {
        final token = await ref.read(tokenServiceProvider).getAccessToken();
        if (token != null && token.isNotEmpty) {
          await socket.initSocket(token);
        }
      }
      await resync();
    } finally {
      if (!_disposed) {
        state = state.copyWith(isSocketReconnecting: false);
      }
    }
  }

  /// Single-flight authoritative sync combining `GET /orders/:id` and
  /// `GET /orders/:id/search-status`.
  Future<void> resync({bool statusOnly = false}) async {
    if (_disposed) return;
    if (_inflightSync != null) {
      _syncQueued = true;
      return _inflightSync;
    }

    final future = _performSync(statusOnly: statusOnly);
    _inflightSync = future;
    try {
      await future;
    } finally {
      _inflightSync = null;
      if (_syncQueued && !_disposed) {
        _syncQueued = false;
        unawaited(resync());
      }
    }
  }

  Future<void> _performSync({required bool statusOnly}) async {
    if (_disposed) return;
    if (state.order != null) {
      state = state.copyWith(isRefreshing: true);
    }

    final repo = ref.read(customerOrderRepositoryProvider);
    final revisions = ref.read(orderRevisionTrackerProvider);

    try {
      Map<String, dynamic>? fetchedOrder;
      OrderSearchStatusDto? fetchedSearch;

      if (statusOnly && state.order != null) {
        fetchedSearch = await repo.getOrderSearchStatus(orderId);
        // If order status transitioned away from what we had locally, fetch full order too.
        if (fetchedSearch.orderStatus.name != state.orderStatus) {
          final full = await repo.getOrderById(orderId);
          if (full is Map) fetchedOrder = Map<String, dynamic>.from(full);
        }
      } else {
        final results = await Future.wait<dynamic>([
          repo.getOrderById(orderId),
          repo.getOrderSearchStatus(orderId),
        ]);
        if (results[0] is Map) {
          fetchedOrder = Map<String, dynamic>.from(results[0] as Map);
        }
        if (results[1] is OrderSearchStatusDto) {
          fetchedSearch = results[1] as OrderSearchStatusDto;
        }
      }

      if (_disposed) return;

      var nextOrder = state.order;
      if (fetchedOrder != null) {
        final rev = orderRevisionOf(fetchedOrder);
        if (rev == null ||
            revisions.accept(orderId, rev) ||
            nextOrder == null) {
          nextOrder = fetchedOrder;
          ref.read(ordersProvider.notifier).upsertOrder(fetchedOrder);
        }
      }

      if (fetchedSearch != null) {
        revisions.accept(orderId, fetchedSearch.revision.toInt());
        _syncDriverMarkerFromSearchStatus(fetchedSearch, nextOrder);
      }

      state = state.copyWith(
        order: nextOrder,
        searchStatus: fetchedSearch ?? state.searchStatus,
        isInitialLoading: false,
        isRefreshing: false,
        clearErrorKey: true,
      );

      _maybeFetchRoadRoute();
      _ensureSafetyPolling();

      if (state.isDriverMatched) {
        _requestDriverLocation();
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('Search resync error: $e');
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorKey: state.order == null ? _errorKeyFromException(e) : null,
      );
    }
  }

  Future<void> cancelSearch({String reason = ''}) async {
    if (_disposed || state.isCancelling || state.isRetrying) return;
    state = state.copyWith(isCancelling: true, clearTransientNotice: true);

    final result = await ref
        .read(ordersProvider.notifier)
        .cancelOrderDetailed(orderId, reason);
    if (_disposed) return;

    if (result.success) {
      await resync();
      if (!_disposed) {
        state = state.copyWith(isCancelling: false);
      }
      return;
    }

    // Resync immediately to resolve race conditions cleanly (e.g., driver
    // accepted milliseconds before cancel OR timeout already finished).
    await resync();
    if (_disposed) return;

    final noticeKey = state.isDriverMatched
        ? 'app.searchRaceAlreadyAssigned'
        : (result.errorKey ?? 'app.searchAlreadyCancelledSync');
    state = state.copyWith(isCancelling: false, transientNoticeKey: noticeKey);
  }

  Future<void> retrySearch() async {
    if (_disposed || state.isRetrying || state.isCancelling) return;
    state = state.copyWith(isRetrying: true, clearTransientNotice: true);

    try {
      final res = await ref
          .read(ordersProvider.notifier)
          .retryCustomSearch(orderId);
      if (_disposed) return;

      _lastSearchSeq = 0;
      ref
          .read(orderRevisionTrackerProvider)
          .accept(orderId, res.searchStatus.revision.toInt());
      _syncDriverMarkerFromSearchStatus(res.searchStatus, res.order);

      state = state.copyWith(
        order: res.order.isNotEmpty ? res.order : state.order,
        searchStatus: res.searchStatus,
        isRetrying: false,
        transientNoticeKey: res.alreadyAssigned
            ? 'app.searchRaceAlreadyAssigned'
            : null,
      );
      _ensureSafetyPolling();
    } catch (e) {
      if (_disposed) return;
      await resync();
      if (!_disposed) {
        state = state.copyWith(
          isRetrying: false,
          transientNoticeKey: state.isDriverMatched
              ? 'app.searchRaceAlreadyAssigned'
              : _errorKeyFromException(e),
        );
      }
    }
  }

  void _syncDriverMarkerFromSearchStatus(
    OrderSearchStatusDto searchStatus,
    Map<String, dynamic>? orderMap,
  ) {
    final loc = searchStatus.driverLocation;
    if (loc == null) return;
    final pickup = extractGeoPoint(
      (orderMap ?? state.order)?['pickupLocation'],
    );
    final point = LatLng(loc.latitude.toDouble(), loc.longitude.toDouble());
    final distKm =
        searchStatus.driverDistanceKm?.toDouble() ??
        (pickup != null ? distanceKmBetween(point, pickup) : null);

    final prev = driverLocationNotifier.value;
    final heading = prev != null
        ? (computeBearingDegrees(prev.position, point) ?? prev.heading)
        : 0.0;
    driverLocationNotifier.value = DriverLiveMarkerState(
      position: point,
      heading: heading,
      isMoving: false,
      distanceToPickupKm: distKm,
    );
  }

  Future<void> _attachSocketListeners() async {
    if (_disposed || _socketAttached) return;
    _socketAttached = true;

    try {
      final socket = ref.read(socketServiceProvider);
      if (!socket.isConnected) {
        final token = await ref.read(tokenServiceProvider).getAccessToken();
        if (_disposed) return;
        if (token != null && token.isNotEmpty) {
          await socket.initSocket(token);
        }
      }
      if (_disposed) return;

      _socketConnectSub = socket.onConnect.listen((_) {
        if (_disposed) return;
        state = state.copyWith(isSocketReconnecting: false);
        unawaited(resync());
      });

      _searchProgressSub = socket
          .onEvent(SocketEvent.orderSearchProgress.eventName)
          .listen((raw) => _handleSearchProgressEvent(raw));

      _orderStatusSub = socket
          .onEvent(SocketEvent.orderStatus.eventName)
          .listen((raw) => _handleOrderStatusEvent(raw));

      _orderAssignedSub = socket
          .onEvent(SocketEvent.orderAssigned.eventName)
          .listen((raw) {
            if (_disposed || raw is! Map || raw['orderId'] != orderId) return;
            unawaited(resync());
          });

      _orderCancelledSub = socket
          .onEvent(SocketEvent.orderCancelled.eventName)
          .listen((raw) {
            if (_disposed || raw is! Map || raw['orderId'] != orderId) return;
            unawaited(resync());
          });

      _driverLocSub = socket
          .onEvent(SocketEvent.driverLocation.eventName)
          .listen((raw) => _handleDriverLocationEvent(raw));

      if (state.isDriverMatched) {
        _requestDriverLocation();
      }
    } catch (e) {
      debugPrint('Socket attach error on search screen: $e');
    }
  }

  void _handleSearchProgressEvent(dynamic raw) {
    if (_disposed || raw is! Map || raw['orderId'] != orderId) return;

    final seq = int.tryParse(raw['sequence']?.toString() ?? '') ?? 0;
    if (seq > 0 && seq <= _lastSearchSeq) return;
    if (seq > 0) _lastSearchSeq = seq;

    final rev = int.tryParse(raw['revision']?.toString() ?? '');
    if (rev != null &&
        !ref.read(orderRevisionTrackerProvider).accept(orderId, rev)) {
      return;
    }

    final parsedPhase = _parsePhase(raw['phase']?.toString());
    final parsedReason = _parseTerminalReason(
      raw['terminalReason']?.toString(),
    );
    final parsedOrderStatus = _parseOrderStatus(raw['orderStatus']?.toString());
    final current = state.searchStatus;

    final updatedSearch = (current ?? _emptySearchStatus(state.order)).rebuild((
      b,
    ) {
      if (parsedPhase != null) b.phase = parsedPhase;
      if (parsedReason != null) b.terminalReason = parsedReason;
      if (parsedOrderStatus != null) b.orderStatus = parsedOrderStatus;
      if (rev != null) b.revision = rev;
      if (raw['attempt'] is num) b.attempt = raw['attempt'] as num;
      if (raw['maxAttempts'] is num) b.maxAttempts = raw['maxAttempts'] as num;
      if (raw['radiusKm'] is num) b.radiusKm = raw['radiusKm'] as num;
      if (raw['maxRadiusKm'] is num) b.maxRadiusKm = raw['maxRadiusKm'] as num;
      if (raw['contactedCount'] is num) {
        b.contactedCount = raw['contactedCount'] as num;
      }
      if (raw['totalContactedCount'] is num) {
        b.totalContactedCount = raw['totalContactedCount'] as num;
      }
      if (raw['rejectedCount'] is num) {
        b.rejectedCount = raw['rejectedCount'] as num;
      }
      if (raw['searchTimeoutSecs'] is num) {
        b.searchTimeoutSecs = raw['searchTimeoutSecs'] as num;
      }
      b.waveExpiresAt = raw['waveExpiresAt']?.toString();
      if (raw['updatedAt'] != null) {
        b.updatedAt = raw['updatedAt'].toString();
      }
      if (parsedPhase == DriverSearchPhase.SEARCH_TIMEOUT ||
          parsedPhase == DriverSearchPhase.NO_DRIVERS_AVAILABLE ||
          parsedPhase == DriverSearchPhase.CANCELLED) {
        b.canRetry = state.driver == null;
      } else if (parsedPhase != DriverSearchPhase.DRIVER_FOUND) {
        b.canRetry = false;
      }
    });

    final prevStatus = state.orderStatus;
    final nextStatus = raw['orderStatus']?.toString() ?? prevStatus;
    Map<String, dynamic>? updatedOrder = state.order;
    if (updatedOrder != null && nextStatus != prevStatus) {
      updatedOrder = Map<String, dynamic>.from(updatedOrder)
        ..['status'] = nextStatus;
    }

    state = state.copyWith(order: updatedOrder, searchStatus: updatedSearch);

    if (parsedPhase == DriverSearchPhase.DRIVER_FOUND ||
        nextStatus != prevStatus) {
      unawaited(resync());
    }
  }

  void _handleOrderStatusEvent(dynamic raw) {
    if (_disposed || raw is! Map || raw['orderId'] != orderId) return;
    if (!ref
        .read(orderRevisionTrackerProvider)
        .accept(orderId, orderRevisionOf(raw))) {
      return;
    }
    unawaited(resync());
  }

  void _handleDriverLocationEvent(dynamic raw) {
    if (_disposed || raw is! Map) return;
    final driverId = state.driver?['id']?.toString();
    final matchesOrder = raw['orderId'] == orderId;
    final matchesDriver = driverId != null && raw['driverId'] == driverId;
    if (!matchesOrder && !matchesDriver) return;

    final point = extractGeoPoint(raw['location'] ?? raw);
    if (point == null) return;

    final now = DateTime.now();
    if (_lastLocationAppliedAt != null &&
        now.difference(_lastLocationAppliedAt!).inMilliseconds < 150) {
      return;
    }
    _lastLocationAppliedAt = now;

    final prev = driverLocationNotifier.value;
    final rawHeading = (raw['heading'] ?? raw['bearing']) as num?;
    final computedHeading = prev != null
        ? (computeBearingDegrees(prev.position, point) ?? prev.heading)
        : 0.0;
    final heading = rawHeading?.toDouble() ?? computedHeading;
    final pickup = state.pickupPoint;
    final distKm = pickup != null ? distanceKmBetween(point, pickup) : null;

    driverLocationNotifier.value = DriverLiveMarkerState(
      position: point,
      heading: heading,
      isMoving:
          prev != null &&
          distanceKmBetween(prev.position, point) * 1000.0 >= 3.0,
      distanceToPickupKm: distKm != null
          ? double.parse(distKm.toStringAsFixed(2))
          : null,
    );
  }

  void _requestDriverLocation() {
    if (_disposed) return;
    final socket = ref.read(socketServiceProvider);
    if (socket.isConnected) {
      socket.emit(SocketEvent.driverLocationRequest.eventName, {
        'orderId': orderId,
      });
    }
  }

  void _maybeFetchRoadRoute() {
    final pickup = state.pickupPoint;
    final dropoff = state.dropoffPoint;
    if (pickup == null || dropoff == null) return;
    final pairKey =
        '${pickup.latitude.toStringAsFixed(4)},${pickup.longitude.toStringAsFixed(4)}'
        '->${dropoff.latitude.toStringAsFixed(4)},${dropoff.longitude.toStringAsFixed(4)}';
    if (_loadedRoutePairKey == pairKey) return;
    _loadedRoutePairKey = pairKey;

    _routeFetchDebounce?.cancel();
    _routeFetchDebounce = Timer(const Duration(milliseconds: 50), () async {
      List<LatLng>? points;
      try {
        final route = await ref
            .read(sharedRoutingRepositoryProvider)
            .computeWaypointsRoute([
              toRoadRoutePoint(pickup),
              toRoadRoutePoint(dropoff),
            ]);
        if (route.isRoadRoute && route.points.length >= 2) {
          points = fromRoadRoutePoints(route.points);
        }
      } catch (_) {
        // Fallback if sharedRoutingRepositoryProvider isn't mounted in isolated tests
      }
      points ??= await fetchRoadRoutePoints(
        ref.read(dioProvider),
        pickup,
        dropoff,
      );
      if (!_disposed && points != null && points.length >= 2) {
        state = state.copyWith(routePoints: points);
      }
    });
  }

  void _ensureSafetyPolling() {
    if (_disposed) return;
    if (!state.isSearching) {
      _safetyPollTimer?.cancel();
      _safetyPollTimer = null;
      return;
    }
    _safetyPollTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      if (_disposed || !state.isSearching) {
        _safetyPollTimer?.cancel();
        _safetyPollTimer = null;
        return;
      }
      if (!state.isOffline) {
        unawaited(resync(statusOnly: true));
      }
    });
  }

  OrderSearchStatusDto _emptySearchStatus(Map<String, dynamic>? orderMap) {
    final nowIso = DateTime.now().toIso8601String();
    return OrderSearchStatusDto(
      (b) => b
        ..orderId = orderId
        ..orderNumber = orderMap?['orderNumber']?.toString() ?? ''
        ..orderType = orderMap?['type']?.toString() == 'RIDE'
            ? OrderType.RIDE
            : OrderType.CUSTOM_DELIVERY
        ..orderStatus =
            _parseOrderStatus(orderMap?['status']?.toString()) ??
            OrderStatus.LOOKING_FOR_DRIVER
        ..revision = (orderMap?['revision'] as num?) ?? 0
        ..phase = DriverSearchPhase.QUEUED
        ..attempt = 1
        ..maxAttempts = 5
        ..radiusKm = 3
        ..maxRadiusKm = 15
        ..contactedCount = 0
        ..totalContactedCount = 0
        ..rejectedCount = 0
        ..nearbyAvailableCount = 0
        ..nearbyDrivers = ListBuilder<NearbyDriverPreviewDto>()
        ..searchTimeoutSecs = 30
        ..searchStartedAt = nowIso
        ..updatedAt = nowIso
        ..terminalReason = SearchTerminalReason.NONE
        ..canRetry = false,
    );
  }

  DriverSearchPhase? _parsePhase(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DriverSearchPhase.valueOf(value);
    } catch (_) {
      return null;
    }
  }

  SearchTerminalReason? _parseTerminalReason(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return SearchTerminalReason.valueOf(value);
    } catch (_) {
      return null;
    }
  }

  OrderStatus? _parseOrderStatus(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return OrderStatus.valueOf(value);
    } catch (_) {
      return null;
    }
  }

  String _errorKeyFromException(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'common.error.network';
      }
    }
    return 'common.error.unknown';
  }
}
