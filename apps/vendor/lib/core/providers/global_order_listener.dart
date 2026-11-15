import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/main.dart' show rootScaffoldMessengerKey;

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
///   - socket `order.new`   -> sound/toast alert + fetch the list
///   - socket `order.status`/`order.fulfillment_updated`/`order.cancelled` ->
///     fast local status flip + coalesced fetch
///   - foreground FCM payloads fall back to the same handling when the
///     socket is disconnected
///   - app resume -> refetch so returning from background is always fresh
final globalOrderListenerProvider = Provider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);
  Timer? fetchDebounce;

  void fetchOrders({bool immediate = false}) {
    fetchDebounce?.cancel();
    if (immediate) {
      ref.read(ordersProvider.notifier).fetchOrders();
      return;
    }
    fetchDebounce = Timer(const Duration(milliseconds: 180), () {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
  }

  void showOrderToast({required bool isNew, String? orderNumber}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final ctx = messenger.context;
    final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
    final numSuffix =
        (orderNumber != null && orderNumber.isNotEmpty) ? ' #$orderNumber' : '';
    final message = isNew
        ? (isAr ? 'تم استلام طلب جديد$numSuffix' : 'New order received$numSuffix')
        : (isAr
            ? 'تم تحديث حالة الطلب$numSuffix'
            : 'Order status updated$numSuffix');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
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
      final fulfillmentId = data['fulfillmentId']?.toString();
      final newStatus =
          fulfillmentStatus ??
          data['newStatus'] ??
          data['status'] ??
          data['orderStatus'];
      if (newStatus != null) {
        ref
            .read(ordersProvider.notifier)
            .updateOrderStatusFast(
              orderId,
              newStatus.toString(),
              isFulfillmentDelta: fulfillmentStatus != null || fulfillmentId != null,
              fulfillmentId: fulfillmentId,
            );
      }
      fetchOrders();
    }
  }

  final orderNewSub = socketService
      .onEvent(SocketEvent.orderNew)
      .listen((data) {
    if (data is Map && data['orderId'] != null) {
      ref
          .read(orderRevisionTrackerProvider)
          .observe(data['orderId'].toString(), orderRevisionOf(data));
      IosAlertHelper.playAlert();
      showOrderToast(
        isNew: true,
        orderNumber: data['orderNumber']?.toString(),
      );
    }
    fetchOrders(immediate: true);
  });

  final orderStatusSub = socketService
      .onEvent(SocketEvent.orderStatus)
      .listen(handleOrderEvent);

  final orderFulfillmentSub = socketService
      .onEvent(SocketEvent.orderFulfillmentUpdated)
      .listen(handleOrderEvent);

  final orderCancelledSub = socketService
      .onEvent(SocketEvent.orderCancelled)
      .listen(handleOrderEvent);

  final pushSub = pushService.onMessage.listen((message) {
    if (message.data['orderId'] != null) {
      final eventType = message.data['type']?.toString().toUpperCase();
      if (eventType == 'NEW_ORDER' || eventType == 'ORDER_NEW') {
        IosAlertHelper.playAlert();
        showOrderToast(
          isNew: true,
          orderNumber: message.data['orderNumber']?.toString(),
        );
      }
      handleOrderEvent(message.data);
    }
  });

  final lifecycleObserver = _OrdersLifecycleObserver(
    onResume: () => fetchOrders(immediate: true),
  );

  ref.onDispose(() {
    fetchDebounce?.cancel();
    orderNewSub.cancel();
    orderStatusSub.cancel();
    orderFulfillmentSub.cancel();
    orderCancelledSub.cancel();
    pushSub.cancel();
    lifecycleObserver.dispose();
  });
});
