import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/core/providers/driver_dispatch_coordinator.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/dashboard/presentation/dashboard_screen.dart'
    show pendingAssistOffersProvider;
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/ranking/presentation/driver_ranking_provider.dart';
import 'package:driver/features/notifications/presentation/notifications_provider.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/core/providers/notification_router.dart';
import 'package:driver/core/router/app_router.dart';

class _DispatchLifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;
  bool isResumed = true;

  _DispatchLifecycleObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isResumed = state == AppLifecycleState.resumed;
    if (isResumed) {
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
  unawaited(pushService.ensureTapListenersInitialized());

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

  // 1c. Wallet adjustment, Break, and Assist/Order notifications.
  subscriptions.add(socketService.onEvent(SocketEvent.notificationNew).listen((eventData) {
    if (!ref.mounted) return;
    final data = eventData is Map ? eventData['data'] : null;
    if (data is! Map) return;
    if (DriverNotificationRouter.isWalletPayload(data)) {
      debugPrint('Global listener: wallet_topup notification -> refreshing wallet & profile');
      ref.invalidate(driverWalletProvider);
      ref.invalidate(driverProfileProvider);
      return;
    }
    final kind = data['kind']?.toString();
    final action = data['action']?.toString();
    if (kind == 'break') {
      debugPrint('Global listener: break notification -> refreshing breaks overview');
      ref.invalidate(breaksOverviewProvider);
      if (action == 'approved' ||
          action == 'granted' ||
          action == 'auto_ended' ||
          action == 'ended_by_admin') {
        ref.invalidate(driverProfileProvider);
      }
      return;
    }
    if (kind == 'driver_ranking') {
      ref.invalidate(driverProfileProvider);
      ref.invalidate(driverRankingSummaryProvider);
      return;
    }
    if (action == 'assist_offer') {
      ref.invalidate(pendingAssistOffersProvider);
    } else if (data['orderId'] != null) {
      ref.invalidate(pendingAssistOffersProvider);
      ref.read(orderExecutionProvider.notifier).refresh();
    }
  }));

  // 1d. Assist offer & assignment realtime events.
  subscriptions.add(socketService.onEvent(SocketEvent.assistOffer).listen((_) {
    if (!ref.mounted) return;
    ref.invalidate(pendingAssistOffersProvider);
  }));

  subscriptions.add(socketService.onEvent(SocketEvent.orderAssigned).listen((_) {
    if (!ref.mounted) return;
    ref.invalidate(driverProfileProvider);
    ref.invalidate(pendingAssistOffersProvider);
    ref.read(orderExecutionProvider.notifier).refresh();
  }));

  subscriptions.add(socketService.onEvent(SocketEvent.orderAssistDecided).listen((_) {
    if (!ref.mounted) return;
    ref.read(orderExecutionProvider.notifier).refresh();
  }));

  subscriptions.add(socketService.onEvent(SocketEvent.orderAssistTimedOut).listen((_) {
    if (!ref.mounted) return;
    ref.invalidate(pendingAssistOffersProvider);
    ref.read(orderExecutionProvider.notifier).refresh();
  }));

  subscriptions.add(socketService.onEvent(SocketEvent.driverRankUpdated).listen((_) {
    if (!ref.mounted) return;
    debugPrint('Global listener: driverRankUpdated -> refreshing driver profile & ranking summary');
    ref.invalidate(driverProfileProvider);
    ref.invalidate(driverRankingSummaryProvider);
  }));

  bool isAuthenticatedSession() =>
      ref.mounted && ref.read(authProvider).value == true;

  // 2. WebSocket Reconnection Fallback
  subscriptions.add(socketService.onConnect.listen((_) {
    if (!ref.mounted || !isAuthenticatedSession()) return;
    debugPrint('Global listener: Socket connected/reconnected -> Checking pending dispatches & active order');
    ref.invalidate(configurationProvider);
    unawaited(pushService.ensureTokenRegistered(role: 'DRIVER'));
    coordinator.checkPendingDispatches(checkOnline: false);
    ref.read(orderExecutionProvider.notifier).refresh();
  }));

  // 3. App Lifecycle Resume Fallback
  final lifecycleObserver = _DispatchLifecycleObserver(
    onResume: () async {
      if (!ref.mounted) return;
      ref.invalidate(configurationProvider);
      if (!isAuthenticatedSession()) return;
      debugPrint('📱 Driver App Resumed: Reconnecting + checking pending dispatches & active order');
      unawaited(pushService.ensureTokenRegistered(role: 'DRIVER'));
      // Break and adjustment decisions may have landed while backgrounded.
      ref.invalidate(breaksOverviewProvider);
      ref.invalidate(driverRankingSummaryProvider);
      ref.invalidate(driverWalletProvider);
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
      if (ref.mounted && isAuthenticatedSession()) {
        await ref.read(orderExecutionProvider.notifier).refresh();
      }
    },
  );

  void consumePendingNavigation() {
    if (!ref.mounted || !isAuthenticatedSession()) return;
    final router = ref.read(appRouterProvider);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    const blockedPaths = {
      '/',
      '/login',
      '/terms-acceptance',
      '/maintenance',
      '/update-required',
    };
    if (blockedPaths.contains(currentPath)) return;

    final pending = ref.read(driverNotificationRouterProvider);
    if (pending == null) return;
    ref.read(driverNotificationRouterProvider.notifier).clear();

    switch (pending.destination) {
      case DriverNotificationDestination.wallet:
        ref.invalidate(driverWalletProvider);
        ref.invalidate(driverProfileProvider);
        ref.invalidate(driverNotificationsProvider);
        if (currentPath == '/wallet') {
          return;
        }
        if (currentPath == '/dashboard') {
          ref.read(driverDashboardTabProvider.notifier).setTab(1);
        } else {
          router.push('/wallet');
        }
        return;
      case DriverNotificationDestination.chat:
        if (pending.id != null && pending.id!.isNotEmpty) {
          router.push(
            '/chat/${pending.id}',
            extra: <String, dynamic>{
              'type': pending.chatType ?? 'order',
              if (pending.title != null) 'title': pending.title!,
            },
          );
        }
        return;
      case DriverNotificationDestination.order:
        if (pending.id != null && pending.id!.isNotEmpty) {
          ref.read(orderExecutionProvider.notifier).refresh();
          ref.read(orderExecutionProvider.notifier).selectOrder(pending.id!);
          router.go('/order-execution');
        }
        return;
    }
  }

  final router = ref.read(appRouterProvider);
  void onRouteChanged() {
    if (!ref.mounted) return;
    consumePendingNavigation();
  }
  router.routerDelegate.addListener(onRouteChanged);

  void handlePushData(Map<String, dynamic> data, {bool navigate = false}) {
    if (DriverNotificationRouter.isWalletPayload(data)) {
      if (isAuthenticatedSession()) {
        ref.invalidate(driverWalletProvider);
        ref.invalidate(driverProfileProvider);
        ref.invalidate(driverNotificationsProvider);
      }
      if (navigate) {
        ref.read(driverNotificationRouterProvider.notifier).handleTap(data);
        consumePendingNavigation();
      }
      return;
    }
    if (data['type'] == 'DISPATCH' || data.containsKey('dispatchId')) {
      if (isAuthenticatedSession()) {
        coordinator.checkPendingDispatches(checkOnline: false);
      }
      return;
    }
    if (data['action'] == 'assist_offer' || data.containsKey('requestId')) {
      if (isAuthenticatedSession()) {
        ref.invalidate(pendingAssistOffersProvider);
      }
      return;
    }

    if (navigate) {
      final banked =
          ref.read(driverNotificationRouterProvider.notifier).handleTap(data);
      if (banked) {
        consumePendingNavigation();
      }
    } else if ((data['orderId']?.toString().trim() ?? '').isNotEmpty &&
        isAuthenticatedSession()) {
      ref.read(orderExecutionProvider.notifier).refresh();
    }
  }

  // 4. Background Push Notification Clicks & Cold Start Check
  subscriptions.add(pushService.onMessage.listen((message) {
    if (!ref.mounted || !isAuthenticatedSession()) return;
    debugPrint('Global listener: FCM foreground message -> ${message.data}');
    handlePushData(message.data);
  }));

  subscriptions.add(pushService.onMessageOpenedApp.listen((message) {
    if (!ref.mounted) return;
    debugPrint('Global listener: FCM opened app -> ${message.data}');
    handlePushData(message.data, navigate: true);
  }));

  pushService.getInitialMessage().then((message) {
    if (!ref.mounted) return;
    if (message != null) {
      debugPrint('Global listener: FCM cold start message -> ${message.data}');
      handlePushData(message.data, navigate: true);
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
        if (!ref.mounted || !isAuthenticatedSession()) return;
        // No polling while backgrounded: socket push + resume check cover it,
        // and background HTTP polling just burns radio/battery.
        if (!lifecycleObserver.isResumed) return;
        // Skip HTTP sweep when a dispatch modal is already on screen.
        if (coordinator.currentShowingDispatchId != null) return;
        coordinator.checkPendingDispatches(checkOnline: false);
      });
    } else if (!shouldRun && dispatchSweepTimer != null) {
      debugPrint('📍 Dispatch sweep stopped (driver $status)');
      dispatchSweepTimer!.cancel();
      dispatchSweepTimer = null;
    }
  }

  syncDispatchSweep(ref.read(driverProfileProvider).value);
  final profileSub = ref.listen(driverProfileProvider, (prev, next) => syncDispatchSweep(next.value));

  // 5b. Hardware Internet Reconnection Listener:
  // When mobile data / Wi-Fi drops and then reconnects, immediately query
  // pending dispatches and sync order execution without waiting for next sweep tick.
  subscriptions.add(
    ref.read(connectivityServiceProvider).onConnectivityChanged.listen((isOnline) {
      if (!ref.mounted) return;
      if (isOnline) {
        ref.invalidate(configurationProvider);
        if (!isAuthenticatedSession()) return;
        debugPrint('🌐 Driver Global Listener: Hardware Internet Reconnected -> Checking dispatches & syncing state');
        ref.invalidate(breaksOverviewProvider);
        ref.invalidate(driverRankingSummaryProvider);
        coordinator.checkPendingDispatches(checkOnline: false);
        unawaited(ref.read(driverProfileProvider.notifier).fetchProfile());
        unawaited(ref.read(orderExecutionProvider.notifier).refresh());
      }
    }),
  );

  // 6. Order Status Events
  subscriptions.add(socketService.onEvent(SocketEvent.orderStatus).listen((eventData) {
    if (!ref.mounted) return;
    debugPrint('Global listener: Received orderStatus -> $eventData');
    if (eventData is! Map) return;

    // Reject transitions older than the revision already applied for this
    // order. Socket.IO does not guarantee ordering, so without this a delayed
    // event can move the execution screen back to a previous status.
    final eventOrderId = (eventData['orderId'] ?? eventData['id'])?.toString();
    if (eventOrderId != null) {
      final revisions = ref.read(orderRevisionTrackerProvider);
      final revision = orderRevisionOf(eventData);
      if (!revisions.accept(eventOrderId, revision)) {
        debugPrint(
          'Global listener: dropping stale orderStatus for $eventOrderId '
          '(revision $revision < ${revisions.latest(eventOrderId)})',
        );
        return;
      }
    }

    final newStatus = eventData['newStatus']?.toString() ?? eventData['status']?.toString() ?? '';

    if (newStatus == 'CANCELLED' || newStatus == 'DELIVERED') {
      ref.read(orderExecutionProvider.notifier).refresh();
      ref.invalidate(driverProfileProvider);
    } else {
      if (newStatus.isNotEmpty) {
        // Refresh the profile on delivery-bound statuses so LocationService can
        // switch to the fast delivery GPS rate as soon as the driver is on the way,
        // even when no other code refreshed the profile for this transition.
        const deliveryStatuses = {
          'DRIVER_ASSIGNED',
          'PENDING_PAYMENT',
          'PREPARING',
          'READY_FOR_PICKUP',
          'PARTIALLY_PICKED_UP',
          'PICKED_UP',
        };
        if (deliveryStatuses.contains(newStatus)) {
          ref.invalidate(driverProfileProvider);
        }
      }
      final orderExecution = ref.read(orderExecutionProvider);
      if (orderExecution.hasValue && orderExecution.value != null) {
        final orderId = orderExecution.value['id']?.toString();
        final updatedOrderId = eventData['orderId']?.toString() ?? eventData['id']?.toString();
        if (orderId != null && orderId == updatedOrderId) {
          if (eventData.containsKey('status') ||
              eventData.containsKey('newStatus') ||
              eventData.containsKey('paymentStatus')) {
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

  subscriptions.add(
    socketService.onEvent(SocketEvent.orderFulfillmentUpdated).listen((eventData) {
      if (!ref.mounted || eventData is! Map) return;
      ref
          .read(orderExecutionProvider.notifier)
          .handleFulfillmentSocketUpdate(Map<String, dynamic>.from(eventData));
    }),
  );

  ref.onDispose(() {
    router.routerDelegate.removeListener(onRouteChanged);
    for (final sub in subscriptions) {
      sub.cancel();
    }
    profileSub.close();
    lifecycleObserver.dispose();
    dispatchSweepTimer?.cancel();
  });
});