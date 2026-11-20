import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart' hide tokenServiceProvider;
import '../services/socket_service.dart';
import '../services/navigation_service.dart';
import '../services/token_service.dart';
import 'platform_settings_provider.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/orders/presentation/providers/orders_provider.dart';

part 'global_order_listener.g.dart';

class _OrdersLifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _OrdersLifecycleObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

@Riverpod(keepAlive: true)
class GlobalOrderListener extends _$GlobalOrderListener {
  StreamSubscription<dynamic>? _pushSub;
  StreamSubscription<dynamic>? _openedAppSub;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _fulfillmentSub;
  StreamSubscription<dynamic>? _assistProposedSub;
  StreamSubscription<dynamic>? _settingsSub;
  StreamSubscription<dynamic>? _connectivitySub;
  _OrdersLifecycleObserver? _lifecycleObserver;

  @override
  void build() {
    ref.onDispose(() {
      _pushSub?.cancel();
      _openedAppSub?.cancel();
      _statusSub?.cancel();
      _fulfillmentSub?.cancel();
      _assistProposedSub?.cancel();
      _settingsSub?.cancel();
      _connectivitySub?.cancel();
      _lifecycleObserver?.dispose();
    });
    final authStatus = ref.watch(authControllerProvider);

    if (authStatus == AuthStatus.authenticated) {
      _init();
    } else {
      _disconnect();
    }

    return;
  }

  void _disconnect() {
    _pushSub?.cancel();
    _pushSub = null;
    _openedAppSub?.cancel();
    _openedAppSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    _fulfillmentSub?.cancel();
    _fulfillmentSub = null;
    _assistProposedSub?.cancel();
    _assistProposedSub = null;
    _settingsSub?.cancel();
    _settingsSub = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    ref.read(socketServiceProvider).disconnect();
  }

  Future<void> _init() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final accessToken = await tokenService.getAccessToken();

    if (accessToken != null) {
      await socket.initSocket(accessToken);

      // --- Socket (survives re-auth thanks to onEvent controllers) ---
      _statusSub?.cancel();
      _statusSub = socket
          .onEvent(SocketEvent.orderStatus.eventName)
          .listen(_handleOrderStatusUpdate);

      _fulfillmentSub?.cancel();
      _fulfillmentSub = socket
          .onEvent(SocketEvent.orderFulfillmentUpdated.eventName)
          .listen(_handleOrderStatusUpdate);

      _assistProposedSub?.cancel();
      _assistProposedSub = socket
          .onEvent(SocketEvent.orderAssistProposed.eventName)
          .listen(_handleOrderStatusUpdate);

      _settingsSub?.cancel();
      _settingsSub = socket
          .onEvent(SocketEvent.platformSettingsUpdated.eventName)
          .listen((_) {
        ref.invalidate(platformSettingsProvider);
      });
    }

    // --- Foreground FCM ---
    final push = ref.read(pushNotificationServiceProvider);
    _pushSub?.cancel();
    _pushSub = push.onMessage.listen((message) {
      if (message.data['orderId'] != null) {
        _handleOrderStatusUpdate(message.data);
      }
    });

    // --- Tapping a notification while backgrounded / killed ---
    _openedAppSub?.cancel();
    _openedAppSub = push.onMessageOpenedApp.listen(_handlePushOpened);
    push.getInitialMessage().then((message) {
      if (message != null) _handlePushOpened(message);
    });

    // --- Hardware Internet Reconnection Listener ---
    _connectivitySub?.cancel();
    _connectivitySub = ref.read(connectivityServiceProvider).onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('🌐 Customer Global Order Listener: Hardware Internet Reconnected -> Syncing orders');
        _onResume();
      }
    });

    // --- App lifecycle: refresh on resume ---
    _lifecycleObserver?.dispose();
    _lifecycleObserver = _OrdersLifecycleObserver(onResume: _onResume);
  }

  // Called on every app resume.
  Future<void> _onResume() async {
    // Ensure the socket is live so any payment / order-status events that
    // landed while the app was backgrounded are not missed.
    await ref.read(socketServiceProvider).ensureConnected();

    ref.invalidate(platformSettingsProvider);
    final orders = ref.read(ordersProvider.notifier);
    await orders.refresh();
  }

  void _handlePushOpened(dynamic message) {
    final data = message is Map ? message : (message?.data as Map?);
    if (data == null) return;

    final orderId = data['orderId']?.toString().trim();
    if (orderId != null && orderId.isNotEmpty) {
      // Update the list instantly, then navigate to tracking.
      _handleOrderStatusUpdate(data);
      ref.read(navigationServiceProvider).go('/order-tracking/$orderId');
      return;
    }

    final conversationId = data['conversationId']?.toString().trim();
    if (conversationId != null && conversationId.isNotEmpty) {
      final type = (data['chatType'] ?? data['type'] ?? 'support').toString();
      ref.read(navigationServiceProvider).push(
        '/chat/$type/$conversationId',
        extra: <String, dynamic>{
          if (data['title'] != null) 'title': data['title'].toString(),
        },
      );
    }
  }

  DateTime? _lastRefreshAt;

  void _handleOrderStatusUpdate(dynamic rawData) {
    if (rawData == null) return;

    Map<String, dynamic> data;
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      return;
    }

    final orderId = data['orderId']?.toString();
    final status = data['newStatus']?.toString() ?? data['status']?.toString();

    if (orderId == null) return;

    // The backend stamps every status transition with a monotonic order
    // revision. Socket.IO (and the FCM fallback) can deliver an older
    // transition after a newer one, so drop anything below the highest
    // revision already applied for this order.
    final tracker = ref.read(orderRevisionTrackerProvider);
    final revision = orderRevisionOf(data);
    if (!tracker.accept(orderId, revision)) {
      debugPrint(
        'Order listener: dropping stale event for $orderId '
        '(revision $revision < ${tracker.latest(orderId)})',
      );
      return;
    }

    // Instantly reflect any status change in the orders list.
    final orders = ref.read(ordersProvider.notifier);
    if (status != null) {
      orders.updateOrderStatusFast(orderId, status);
    }
    // Coalesce event bursts into at most one refresh per second.
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!).inMilliseconds < 1000) {
      return;
    }
    _lastRefreshAt = now;
    orders.refresh();
  }
}