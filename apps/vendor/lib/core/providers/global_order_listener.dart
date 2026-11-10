import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';

class _OrdersLifecycleObserver with WidgetsBindingObserver {
  final void Function() onResume;

  _OrdersLifecycleObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('Vendor app resumed: refreshing orders');
      onResume();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Global listener wired at the app root.
///
/// Keeps the orders page in sync regardless of which dashboard tab is open
/// or whether the app was in the background:
///   - socket `order.new`   -> fetch the list (new order appears instantly)
///   - socket `order.status`/`order.cancelled` -> fast local status flip + fetch
///   - foreground FCM payloads fall back to the same handling when the
///     socket is disconnected
///   - app resume -> refetch so returning from background is always fresh
final globalOrderListenerProvider = Provider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);

  void fetchOrders() {
    ref.read(ordersProvider.notifier).fetchOrders();
  }

  void handleOrderEvent(dynamic data) {
    if (data != null && data is Map && data['orderId'] != null) {
      final orderId = data['orderId'].toString();
      // Drop transitions the app has already moved past: Socket.IO and the FCM
      // fallback can replay an older revision after a newer one.
      final revisions = ref.read(orderRevisionTrackerProvider);
      final revision = orderRevisionOf(data);
      if (!revisions.accept(orderId, revision)) {
        debugPrint(
          'Vendor orders: dropping stale event for $orderId '
          '(revision $revision < ${revisions.latest(orderId)})',
        );
        return;
      }
      final fulfillmentStatus = data['fulfillmentStatus'];
      final newStatus = fulfillmentStatus ?? data['newStatus'] ?? data['status'];
      if (newStatus != null) {
        ref
            .read(ordersProvider.notifier)
            .updateOrderStatusFast(
              orderId,
              newStatus.toString(),
              isFulfillmentDelta: fulfillmentStatus != null,
            );
      }
      fetchOrders();
    }
  }

  final orderNewSub = socketService
      .onEvent(SocketEvent.orderNew)
      .listen((data) {
    // order.new carries the revision the order row was created with; record it
    // so the first status event is ordered against a known starting point.
    if (data is Map && data['orderId'] != null) {
      ref
          .read(orderRevisionTrackerProvider)
          .observe(data['orderId'].toString(), orderRevisionOf(data));
    }
    fetchOrders();
  });

  final orderStatusSub = socketService
      .onEvent(SocketEvent.orderStatus)
      .listen(handleOrderEvent);

  final orderFulfillmentSub = socketService
      .onEvent(SocketEvent.orderFulfillmentUpdated)
      .listen((data) {
    fetchOrders();
  });

  final orderCancelledSub = socketService
      .onEvent(SocketEvent.orderCancelled)
      .listen(handleOrderEvent);

  final pushSub = pushService.onMessage.listen((message) {
    if (message.data['orderId'] != null) {
      handleOrderEvent(message.data);
    }
  });

  final lifecycleObserver = _OrdersLifecycleObserver(onResume: fetchOrders);

  ref.onDispose(() {
    orderNewSub.cancel();
    orderStatusSub.cancel();
    orderFulfillmentSub.cancel();
    orderCancelledSub.cancel();
    pushSub.cancel();
    lifecycleObserver.dispose();
  });
});