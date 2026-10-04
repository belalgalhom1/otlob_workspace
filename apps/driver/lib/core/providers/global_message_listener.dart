import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/core/providers/driver_dispatch_coordinator.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';

class _DispatchLifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _DispatchLifecycleObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 Driver App Resumed: Checking pending dispatches via HTTP fallback');
      onResume();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

final globalMessageListenerProvider = Provider<void>((ref) {
  debugPrint('📦 [DRIVER-DISPATCH-3] globalMessageListenerProvider up');
  final socketService = ref.watch(coreSocketServiceProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);

  // Read location service to initialize it
  ref.read(locationServiceProvider);

  final coordinator = ref.read(driverDispatchCoordinatorProvider);

  // Every subscription hangs off the socket/push services (which are keepAlive),
  // so a disposed provider must cancel them — otherwise events fire against a
  // dead Ref and throw "Cannot use the Ref ... after it has been disposed".
  final subscriptions = <StreamSubscription<dynamic>>[];

  // 1. WebSocket Dispatch Events
  subscriptions.add(socketService.onEvent(SocketEvent.dispatchIncoming).listen((eventData) {
    if (!ref.mounted) return;
    debugPrint('Global listener: Received dispatchIncoming -> $eventData');
    if (eventData is Map) {
      coordinator.showDispatchModal(Map<String, dynamic>.from(eventData));
    }
  }));

  subscriptions.add(socketService.onEvent(SocketEvent.dispatchCancelled).listen((eventData) {
    if (!ref.mounted) return;
    debugPrint('Global listener: Received dispatchCancelled -> $eventData');
    final dispatchId = eventData is Map ? (eventData['dispatchId'] ?? eventData['id'])?.toString() : null;
    coordinator.dismissDispatchModal(dispatchId);
  }));

  // 1b. Platform settings live updates (vendor saved settings -> refresh config)
  subscriptions.add(socketService
      .onEvent(SocketEvent.platformSettingsUpdated)
      .listen((eventData) {
    if (!ref.mounted) return;
    debugPrint('Global listener: platformSettingsUpdated -> refreshing configuration');
    ref.invalidate(configurationProvider);
  }));

  // 2. WebSocket Reconnection Fallback
  subscriptions.add(socketService.onConnect.listen((_) {
    if (!ref.mounted) return;
    debugPrint('Global listener: Socket connected/reconnected -> Checking pending dispatches');
    ref.invalidate(configurationProvider);
    coordinator.checkPendingDispatches(checkOnline: false);
  }));

  // 3. App Lifecycle Resume Fallback
  final lifecycleObserver = _DispatchLifecycleObserver(
    onResume: () async {
      if (!ref.mounted) return;
      debugPrint('📱 Driver App Resumed: Reconnecting + checking pending dispatches');
      ref.invalidate(configurationProvider);
      // Make sure the socket and GPS stream are up again so live dispatch
      // events keep flowing instead of relying only on the HTTP fallback.
      final profileValue = ref.read(driverProfileProvider).value;
      if (profileValue is Map) {
        final data = profileValue['data'] is Map
            ? profileValue['data']
            : profileValue;
        final status = data['status']?.toString();
        if (status == 'ONLINE' || status == 'ON_DELIVERY') {
          ref.read(coreSocketServiceProvider).connect();
          ref.read(locationServiceProvider).startTracking();
        }
      }
      await coordinator.checkPendingDispatches(checkOnline: false);
    },
  );

  // 4. Background Push Notification Clicks & Cold Start Check
  subscriptions.add(pushService.onMessage.listen((message) {
    if (!ref.mounted) return;
    debugPrint('Global listener: FCM foreground message -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  }));

  subscriptions.add(pushService.onMessageOpenedApp.listen((message) {
    if (!ref.mounted) return;
    debugPrint('Global listener: FCM opened app -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  }));

  pushService.getInitialMessage().then((message) {
    if (!ref.mounted) return;
    if (message != null && (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId'))) {
      debugPrint('Global listener: FCM cold start message -> ${message.data}');
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  });

  // 5. Online dispatch sweep: while ONLINE (or idle ON_DELIVERY), poll pending
  // dispatches every 10s. This catches dispatches that arrive while the app is
  // backgrounded or whose socket event was missed — it runs independently of
  // socket/lifecycle state, so switching back to the app surfaces the dispatch
  // within seconds even if every other path failed.
  Timer? dispatchSweepTimer;

  String? profileStatusOf(Object? profileData) {
    if (profileData is! Map) return null;
    final data = profileData['data'];
    return ((data is Map ? data : profileData)['status']?.toString());
  }

  void syncDispatchSweep(Object? profileData) {
    final status = profileStatusOf(profileData);
    final shouldRun = status == 'ONLINE' || status == 'ON_DELIVERY';
    if (shouldRun && dispatchSweepTimer == null) {
      debugPrint('📍 Dispatch sweep started (driver $status)');
      dispatchSweepTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!ref.mounted) return;
        coordinator.checkPendingDispatches(checkOnline: false);
      });
    } else if (!shouldRun && dispatchSweepTimer != null) {
      debugPrint('📍 Dispatch sweep stopped (driver $status)');
      dispatchSweepTimer!.cancel();
      dispatchSweepTimer = null;
    }
  }

  syncDispatchSweep(ref.watch(driverProfileProvider).value);
  final profileSub = ref.listen(driverProfileProvider, (prev, next) => syncDispatchSweep(next.value));

  // 6. Order Status Events
  subscriptions.add(socketService.onEvent(SocketEvent.orderStatus).listen((eventData) {
    if (!ref.mounted) return;
    debugPrint('Global listener: Received orderStatus -> $eventData');
    if (eventData == null) return;

    final newStatus = eventData['newStatus']?.toString() ?? eventData['status']?.toString() ?? '';

    if (newStatus == 'CANCELLED' || newStatus == 'DELIVERED') {
      ref.invalidate(orderExecutionProvider);
      ref.invalidate(driverProfileProvider);
    } else if (newStatus.isNotEmpty) {
      // Refresh the profile on delivery-bound statuses so LocationService can
      // switch to the fast delivery GPS rate as soon as the driver is on the way,
      // even when no other code refreshed the profile for this transition.
      const deliveryStatuses = {
        'DRIVER_ASSIGNED',
        'PENDING_PAYMENT',
        'PREPARING',
        'READY_FOR_PICKUP',
        'PICKED_UP',
      };
      if (deliveryStatuses.contains(newStatus)) {
        ref.invalidate(driverProfileProvider);
      }
      final orderExecution = ref.read(orderExecutionProvider);
      if (orderExecution.hasValue && orderExecution.value != null) {
        final orderId = orderExecution.value['id']?.toString();
        final updatedOrderId = eventData['orderId']?.toString() ?? eventData['id']?.toString();
        if (orderId != null && orderId == updatedOrderId) {
          if (eventData.containsKey('status') || eventData.containsKey('newStatus')) {
            ref.read(orderExecutionProvider.notifier).handleSocketUpdate(
              Map<String, dynamic>.from(eventData),
            );
          } else {
            ref.invalidate(orderExecutionProvider);
          }
        }
      }
    }
  }));

  ref.onDispose(() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    profileSub.close();
    lifecycleObserver.dispose();
    dispatchSweepTimer?.cancel();
  });
});