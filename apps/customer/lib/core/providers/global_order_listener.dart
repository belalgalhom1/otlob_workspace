import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart' hide tokenServiceProvider;
import '../services/socket_service.dart';
import '../services/navigation_service.dart';
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/orders/presentation/widgets/customer_approval_bottom_sheet.dart';
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
  String? _lastShownOrderId;
  StreamSubscription<dynamic>? _pushSub;
  StreamSubscription<dynamic>? _openedAppSub;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _updatedSub;
  _OrdersLifecycleObserver? _lifecycleObserver;

  @override
  void build() {
    final authStatus = ref.watch(authControllerProvider);

    if (authStatus == AuthStatus.authenticated) {
      _init();
    } else {
      _disconnect();
    }

    return;
  }

  void _disconnect() {
    _lastShownOrderId = null;
    _pushSub?.cancel();
    _pushSub = null;
    _openedAppSub?.cancel();
    _openedAppSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    _updatedSub?.cancel();
    _updatedSub = null;
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
      _statusSub = socket.onEvent('order.status').listen(_handleOrderStatusUpdate);

      _updatedSub?.cancel();
      _updatedSub = socket.onEvent('order.updated').listen(_handleOrderStatusUpdate);
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

    // --- App lifecycle: refresh + re-show approval if needed ---
    _lifecycleObserver?.dispose();
    _lifecycleObserver = _OrdersLifecycleObserver(onResume: _onResume);
  }

  // Called on every app resume.
  Future<void> _onResume() async {
    final orders = ref.read(ordersProvider.notifier);
    await orders.refresh();
    _scanForPendingApproval();
  }

  void _scanForPendingApproval() {
    final state = ref.read(ordersProvider);
    for (final o in state.activeOrders) {
      if (o['status'] == 'PENDING_CUSTOMER_APPROVAL') {
        _showApprovalSheet(o['id'].toString());
        return;
      }
    }
  }

  void _handlePushOpened(dynamic message) {
    final data = message is Map ? message : (message?.data as Map?);
    if (data == null || data['orderId'] == null) return;

    // Update the list / maybe show the approval sheet.
    _handleOrderStatusUpdate(data);

    ref.read(navigationServiceProvider).go('/order-tracking/${data['orderId']}');
  }

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

    // Instantly reflect any status change in the orders list.
    final orders = ref.read(ordersProvider.notifier);
    if (status != null) {
      orders.updateOrderStatusFast(orderId, status);
    }
    orders.refresh();

    if (status == 'PENDING_CUSTOMER_APPROVAL') {
      _showApprovalSheet(orderId);
    }
  }

  void _showApprovalSheet(String orderId) {
    if (orderId == _lastShownOrderId) return;
    _lastShownOrderId = orderId;

    final navigation = ref.read(navigationServiceProvider);
    final context = navigation.navigatorKey.currentContext;

    if (context != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => CustomerApprovalBottomSheet(
          orderId: orderId,
        ),
      ).then((_) {
        _lastShownOrderId = null;
      });
    }
  }
}