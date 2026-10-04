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
  final socketService = ref.watch(coreSocketServiceProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);

  // Read location service to initialize it
  ref.read(locationServiceProvider);

  final coordinator = ref.read(driverDispatchCoordinatorProvider);

  // 1. WebSocket Dispatch Events
  socketService.onEvent(SocketEvent.dispatchIncoming).listen((eventData) {
    debugPrint('Global listener: Received dispatchIncoming -> $eventData');
    if (eventData is Map) {
      coordinator.showDispatchModal(Map<String, dynamic>.from(eventData));
    }
  });

  socketService.onEvent(SocketEvent.dispatchCancelled).listen((eventData) {
    debugPrint('Global listener: Received dispatchCancelled -> $eventData');
    final dispatchId = eventData is Map ? (eventData['dispatchId'] ?? eventData['id'])?.toString() : null;
    coordinator.dismissDispatchModal(dispatchId);
  });

  // 1b. Platform settings live updates (vendor saved settings -> refresh config)
  final settingsSub = socketService
      .onEvent(SocketEvent.platformSettingsUpdated)
      .listen((eventData) {
    debugPrint('Global listener: platformSettingsUpdated -> refreshing configuration');
    ref.invalidate(configurationProvider);
  });

  // 2. WebSocket Reconnection Fallback
  socketService.onConnect.listen((_) {
    debugPrint('Global listener: Socket connected/reconnected -> Checking pending dispatches');
    ref.invalidate(configurationProvider);
    coordinator.checkPendingDispatches(checkOnline: false);
  });

  // 3. App Lifecycle Resume Fallback
  final lifecycleObserver = _DispatchLifecycleObserver(
    onResume: () async {
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
  pushService.onMessage.listen((message) {
    debugPrint('Global listener: FCM foreground message -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  });

  pushService.onMessageOpenedApp.listen((message) {
    debugPrint('Global listener: FCM opened app -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  });

  pushService.getInitialMessage().then((message) {
    if (message != null && (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId'))) {
      debugPrint('Global listener: FCM cold start message -> ${message.data}');
      coordinator.checkPendingDispatches(checkOnline: false);
    }
  });

  // 5. Conditional Safety Heartbeat Polling (Every 30s, ONLY while ONLINE and socket is disconnected)
  Timer? pollTimer;
  final profileState = ref.watch(driverProfileProvider);
  final profileData = profileState.value;
  final profileStatus = profileData is Map
      ? ((profileData['data'] is Map ? profileData['data'] : profileData)['status']?.toString())
      : null;
  final isOnline = profileStatus == 'ONLINE' || profileStatus == 'ON_DELIVERY';

  if (isOnline) {
    pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!socketService.isConnected) {
        debugPrint('⚠️ Driver socket disconnected while ONLINE. Polling dispatches via HTTP fallback (30s)...');
        coordinator.checkPendingDispatches(checkOnline: false);
      }
    });
  }

  // 6. Order Status Events
  socketService.onEvent(SocketEvent.orderStatus).listen((eventData) {
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
  });

  ref.onDispose(() {
    settingsSub.cancel();
    lifecycleObserver.dispose();
    pollTimer?.cancel();
  });
});
