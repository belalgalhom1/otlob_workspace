import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/features/dispatch/presentation/pages/dispatch_modal.dart';
import 'package:driver/core/router/app_router.dart';
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

  String? currentShowingDispatchId;

  void showDispatchModal(Map<String, dynamic> dispatchData) {
    final dispatchId = dispatchData['dispatchId']?.toString() ?? dispatchData['id']?.toString();
    if (dispatchId == null) return;

    // Check if expired
    if (dispatchData['expiresAt'] != null) {
      try {
        final expiresAt = DateTime.parse(dispatchData['expiresAt'].toString());
        if (DateTime.now().isAfter(expiresAt)) return;
      } catch (_) {}
    }

    // Deduplicate: do not show if this dispatch modal is already presented
    if (currentShowingDispatchId == dispatchId) {
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      currentShowingDispatchId = dispatchId;
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      DispatchModal.show(context, dispatchData).whenComplete(() {
        if (currentShowingDispatchId == dispatchId) {
          currentShowingDispatchId = null;
        }
      });
    }
  }

  void dismissDispatchModal(String? dispatchId) {
    if (dispatchId != null &&
        currentShowingDispatchId != null &&
        currentShowingDispatchId != dispatchId) {
      return; // Different dispatch
    }
    currentShowingDispatchId = null;
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).popUntil((route) {
        if (route.settings.name == 'dispatch_modal_route') {
          return false;
        }
        return true;
      });
    }
  }

  Future<void> checkPendingDispatches() async {
    try {
      final profile = ref.read(driverProfileProvider).value;
      final status = profile is Map ? profile['status'] : null;
      if (status != 'ONLINE' && status != 'ON_DELIVERY') {
        return;
      }

      final repo = ref.read(driverDispatchRepositoryProvider);
      final dispatches = await repo.getMyDispatches();
      if (dispatches is List && dispatches.isNotEmpty) {
        for (final item in dispatches) {
          if (item is Map) {
            final data = Map<String, dynamic>.from(item);
            showDispatchModal(data);
            break; // Present first active valid dispatch
          }
        }
      }
    } catch (e) {
      debugPrint('HTTP fallback dispatch check error: $e');
    }
  }

  // 1. WebSocket Dispatch Events
  socketService.onEvent(SocketEvent.dispatchIncoming).listen((eventData) {
    debugPrint('Global listener: Received dispatchIncoming -> $eventData');
    if (eventData is Map) {
      showDispatchModal(Map<String, dynamic>.from(eventData));
    }
  });

  socketService.onEvent(SocketEvent.dispatchCancelled).listen((eventData) {
    debugPrint('Global listener: Received dispatchCancelled -> $eventData');
    final dispatchId = eventData is Map ? (eventData['dispatchId'] ?? eventData['id'])?.toString() : null;
    dismissDispatchModal(dispatchId);
  });

  // 2. WebSocket Reconnection Fallback
  socketService.onConnect.listen((_) {
    debugPrint('Global listener: Socket connected/reconnected -> Checking pending dispatches');
    checkPendingDispatches();
  });

  // 3. App Lifecycle Resume Fallback
  final lifecycleObserver = _DispatchLifecycleObserver(
    onResume: checkPendingDispatches,
  );

  // 4. Background Push Notification Clicks & Cold Start Check
  pushService.onMessage.listen((message) {
    debugPrint('Global listener: FCM foreground message -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      checkPendingDispatches();
    }
  });

  pushService.onMessageOpenedApp.listen((message) {
    debugPrint('Global listener: FCM opened app -> ${message.data}');
    if (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId')) {
      checkPendingDispatches();
    }
  });

  pushService.getInitialMessage().then((message) {
    if (message != null && (message.data['type'] == 'DISPATCH' || message.data.containsKey('dispatchId'))) {
      debugPrint('Global listener: FCM cold start message -> ${message.data}');
      checkPendingDispatches();
    }
  });

  // 5. Conditional Safety Heartbeat Polling (Every 30s, ONLY while ONLINE and socket is disconnected)
  Timer? pollTimer;
  final profileState = ref.watch(driverProfileProvider);
  final profileData = profileState.value;
  final currentStatus = profileData is Map ? profileData['status'] : null;
  final isOnline = currentStatus == 'ONLINE' || currentStatus == 'ON_DELIVERY';

  if (isOnline) {
    pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!socketService.isConnected) {
        debugPrint('⚠️ Driver socket disconnected while ONLINE. Polling dispatches via HTTP fallback (30s)...');
        checkPendingDispatches();
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
    lifecycleObserver.dispose();
    pollTimer?.cancel();
  });
});
