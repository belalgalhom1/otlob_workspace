import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:core/core.dart';

part 'splash_provider.g.dart';

enum AppStartupState {
  loading,
  unauthenticated,
  suspended,
  dashboard,
  activeOrder,
  maintenance,
  forceUpdate,
}

class UpdateStoreUrl extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final updateStoreUrlProvider =
    NotifierProvider<UpdateStoreUrl, String?>(UpdateStoreUrl.new);

class AppUpdateAvailable extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final appUpdateAvailableProvider =
    NotifierProvider<AppUpdateAvailable, bool>(AppUpdateAvailable.new);

@Riverpod(keepAlive: true)
class Splash extends _$Splash {
  @override
  Future<AppStartupState> build() async {
    // Hard ceiling on startup: on a stalled network each step below can
    // otherwise burn its own 15s timeout sequentially and leave the splash
    // spinning for a minute with no feedback. On timeout, fall through to
    // the same session check the generic error path uses.
    try {
      return await _initialize().timeout(const Duration(seconds: 25));
    } on TimeoutException {
      final authRepository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await authRepository.isLoggedIn().timeout(
            const Duration(seconds: 5),
            onTimeout: () => false,
          );
      return isLoggedIn
          ? AppStartupState.dashboard
          : AppStartupState.unauthenticated;
    }
  }

  Future<AppStartupState> _initialize() async {
    try {
      debugPrint('🚀 Splash: gate check start');
      final appStatus = await checkAppStatus(
        ref.read(sharedPlatformSettingsRepositoryProvider),
      );
      debugPrint('🚀 Splash: gate check done: ${appStatus == null ? 'offline-skip' : 'maintenance=${appStatus.maintenance} mustUpdate=${appStatus.mustUpdate}'}');
      if (appStatus != null) {
        if (appStatus.maintenance) return AppStartupState.maintenance;
        if (appStatus.mustUpdate) {
          ref.read(updateStoreUrlProvider.notifier).set(appStatus.storeUrl);
          return AppStartupState.forceUpdate;
        }
        ref.read(appUpdateAvailableProvider.notifier).set(
              appStatus.shouldUpdate,
            );
      }

      final authRepository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await authRepository.isLoggedIn();
      debugPrint('🚀 Splash: session check done: loggedIn=$isLoggedIn');

      if (!isLoggedIn) {
        return AppStartupState.unauthenticated;
      }

      final role = await authRepository.getUserRole();
      if (role != 'DRIVER') {
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }

      final driverRepo = ref.read(driverProfileRepositoryProvider);
      debugPrint('🚀 Splash: profile fetch start');
      final profile = await driverRepo.getMyProfile();
      debugPrint('🚀 Splash: profile fetch done');
      if (profile == null || profile['isApproved'] != true) {
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }
      
      if (profile['status'] == 'SUSPENDED') {
        return AppStartupState.suspended;
      }

      // Initialize SocketService but only auto-connect if driver is online
      final bool shouldConnect = profile['status'] != 'OFFLINE' && profile['status'] != 'SUSPENDED';
      await ref.read(coreSocketServiceProvider).init(autoConnect: shouldConnect);

      // Initialize Push Notifications and register FCM token
      Future(() async {
        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          await pushService.subscribeToRoleTopics('DRIVER');
        } catch (e) {
          // Gracefully ignore on platforms/environments without FCM
        }
      });

      // Query for an active order
      debugPrint('🚀 Splash: active-order fetch start');
      final ordersRepo = ref.read(driverOrdersRepositoryProvider);
      final activeOrderResult = await ordersRepo.getActiveDriverOrder();
      debugPrint('🚀 Splash: active-order fetch done');
      
      // The repository resolves to {'data': null} when no order is active,
      // so an empty map must not be treated as an active order.
      if (activeOrderResult != null && activeOrderResult['data'] != null) {
        // We have an active order
        return AppStartupState.activeOrder;
      }

      return AppStartupState.dashboard;
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('PROFILE_NOT_FOUND')) {
        final authRepository = ref.read(sharedAuthRepositoryProvider);
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }

      // A dead session (guard-level 401/403, revoked/expired session) must
      // never fall through to the dashboard — the profile validation just
      // failed, so force a clean logout back to the login screen.
      if (ErrorUtils.isAuthSessionError(e)) {
        final authRepository = ref.read(sharedAuthRepositoryProvider);
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }

      // If network fails, but we have token, we might want to just go to dashboard and let it show offline
      // For now, if we can't fetch profile, fallback to unauth or dashboard depending on token
      final authRepository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) return AppStartupState.dashboard;
      return AppStartupState.unauthenticated;
    }
  }
}
