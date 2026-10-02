import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:core/core.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  StreamSubscription<void>? _unauthSub;
  bool _logoutInProgress = false;

  @override
  AsyncValue<bool> build() {
    _unauthSub?.cancel();
    _unauthSub = unauthenticatedEventStream.stream.listen((_) {
      _handleUnauthenticated();
    });
    ref.onDispose(() {
      _unauthSub?.cancel();
    });

    Future.microtask(() => _checkInitialAuth());
    return const AsyncValue.loading();
  }

  Future<void> _handleUnauthenticated() async {
    if (_logoutInProgress) return;
    final repository = ref.read(sharedAuthRepositoryProvider);
    // The event also fires after the interceptor already cleared the session;
    // re-running logout without a session would only re-enter the 401 loop.
    if (!await repository.isLoggedIn()) return;
    logout();
  }

  Future<void> _checkInitialAuth() async {
    if (state.hasValue && state.value == true) return;
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await repository.isLoggedIn();
      if (isLoggedIn) {
        final role = await repository.getUserRole();
        if (role == 'DRIVER') {
          try {
            final pushService = ref.read(pushNotificationServiceProvider);
            await pushService.initialize();
            await pushService.subscribeToRoleTopics('DRIVER');
          } catch (_) {}
          state = const AsyncValue.data(true);
          return;
        } else {
          await repository.logout();
        }
      }
      state = const AsyncValue.data(false);
    } catch (_) {
      // A storage hiccup should not strand the router on the loading splash.
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      await repository.login(email, password, appType: 'driver');
      
      final role = await repository.getUserRole();
      if (role != 'DRIVER') {
        await repository.logout();
        throw Exception('auth.error.unauthorized_role');
      }

      final driverRepo = ref.read(driverProfileRepositoryProvider);
      Map<String, dynamic>? profile;
      var profileFetchFailed = false;
      try {
        profile = await driverRepo.getMyProfile();
      } catch (e) {
        final message = e.toString();
        if (message.contains('404') || message.contains('PROFILE_NOT_FOUND')) {
          await repository.logout();
          throw Exception('auth.error.pending_approval');
        }
        // Tokens were already persisted by the successful login. A transient
        // network/server failure on this very first authenticated read (cold
        // socket/TLS, momentary 5xx, fresh KeyStore) must not strand the user
        // on an error snackbar that only a force-restart escapes — the
        // dashboard's fetchProfile (retries + error card) handles any lasting
        // problem.
        profileFetchFailed = true;
        debugPrint(
          'Login succeeded; post-login profile fetch failed transiently: $e',
        );

        // A real 401 that survived the refresh cycle means the interceptor
        // already wiped the freshly saved tokens. That is not a transient
        // hiccup — the session is genuinely dead, so marking the app
        // authenticated would strand the user on a dashboard that only 401s.
        // Bounce back to the login screen instead.
        try {
          final stillLoggedIn = await repository.isLoggedIn();
          if (!stillLoggedIn) {
            state = const AsyncValue.data(false);
            return;
          }
        } catch (_) {
          // Storage hiccup mid-check: proceed; the dashboard's retry path
          // (fetchProfile) and the interceptor re-assert the real state.
        }
      }
      if (!profileFetchFailed &&
          (profile == null || profile['isApproved'] != true)) {
        await repository.logout();
        throw Exception('auth.error.pending_approval');
      }

      // Initialize Push Notifications and register FCM token
      try {
        final pushService = ref.read(pushNotificationServiceProvider);
        await pushService.initialize();
        await pushService.subscribeToRoleTopics('DRIVER');
      } catch (_) {}
      
      state = const AsyncValue.data(true);
    } catch (e, st) {
      final errorString = e.toString();
      if (errorString.contains('404') || errorString.contains('PROFILE_NOT_FOUND')) {
        try {
          await ref.read(sharedAuthRepositoryProvider).logout();
        } catch (_) {}
        state = AsyncValue.error(Exception('auth.error.pending_approval'), st);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      // Stop background services before tearing down the session so stale
      // location pings and buffered socket events are not sent under a
      // revoked / expired token. Each is isolated so a failure to stop
      // one never skips the other.
      try {
        await ref.read(locationServiceProvider).stopTracking();
      } catch (e) {
        debugPrint('Failed to stop location tracking on logout: $e');
      }
      ref.read(coreSocketServiceProvider).disconnect();

      final repository = ref.read(sharedAuthRepositoryProvider);

      // No session: nothing to clean up or revoke. Running push cleanup here
      // would fire authenticated calls, 401 (no token), and re-enter the
      // logout/refresh/clear/emit loop.
      if (!await repository.isLoggedIn()) {
        state = const AsyncValue.data(false);
        ref.invalidate(splashProvider);
        _goToLogin();
        return;
      }

      String? fcmToken;
      try {
        final push = ref.read(pushNotificationServiceProvider);
        fcmToken = await push.getToken();
        await push.unsubscribeFromRoleTopics('DRIVER');
        await push.unregisterToken();
      } catch (_) {}

      await repository.logout(fcmToken: fcmToken);
      state = const AsyncValue.data(false);
      ref.invalidate(splashProvider);
      _goToLogin();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _logoutInProgress = false;
    }
  }

  void _goToLogin() {
    if (rootNavigatorKey.currentContext != null) {
      rootNavigatorKey.currentContext!.go('/login');
    }
  }
}
