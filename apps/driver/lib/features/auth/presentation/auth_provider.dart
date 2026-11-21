import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/features/orders/presentation/driver_orders_history_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/notifications/presentation/notifications_provider.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/profile/presentation/settings_provider.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:core/core.dart';

part 'auth_provider.g.dart';

class DriverPostLoginState extends Notifier<AppStartupState> {
  @override
  AppStartupState build() => AppStartupState.dashboard;

  void set(AppStartupState value) => state = value;
}

final driverPostLoginStateProvider =
    NotifierProvider<DriverPostLoginState, AppStartupState>(
      DriverPostLoginState.new,
    );

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
    if (state.value != true) {
      // Only force logout/redirect when an active authenticated session expires.
      // Cold-start / SplashScreen token checks transition to /login via SplashScreen
      // so the logo spin and welcome celebration overlay run uninterrupted.
      return;
    }
    // The interceptor fires this event when it has concluded the session is
    // unusable (refresh token missing, or refresh 401/403). Whether or not it
    // already cleared the tokens, always return to the login screen: skipping
    // logout while `state` stays `true` strands the dashboard on an
    // "Unauthorized" error card that only a force-restart escapes. `logout()`
    // is safe with no session left (it skips the network call entirely).
    await logout();
  }

  void _initPushInBackground() {
    unawaited(
      Future<void>(() async {
        try {
          if (!ref.mounted) return;
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          if (!ref.mounted) return;
          await pushService.subscribeToRoleTopics('DRIVER');
        } catch (_) {}
      }),
    );
  }

  Future<void> _checkInitialAuth() async {
    if (state.hasValue && state.value == true) return;
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await repository.isLoggedIn();
      if (isLoggedIn) {
        final role = await repository.getUserRole();
        if (role == 'DRIVER') {
          _initPushInBackground();
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

  /// Synchronizes [Auth] to unauthenticated when [Splash] already cleared
  /// a stale/expired session before navigating to `/login`.
  void markUnauthenticated() {
    if (state.value != false || state.isLoading || state.hasError) {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final response =
          await repository.login(email, password, appType: 'driver');
      await _finishDriverLogin(repository, loginPayload: response);
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

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final idToken = await GoogleSignInService.getIdToken();
      final repository = ref.read(sharedAuthRepositoryProvider);
      final response = await repository.socialLogin(
        SocialLoginDto((b) => b
          ..provider = SocialLoginDtoProviderEnum.GOOGLE
          ..idToken = idToken
          ..app = SocialLoginDtoAppEnum.driver),
      );
      await _finishDriverLogin(repository, loginPayload: response);
    } catch (e, st) {
      if (e.toString().contains('google.sign_in.no_token')) {
        state = const AsyncValue.data(false);
        return;
      }
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

  Map<String, dynamic>? _extractDriverFromLoginPayload(dynamic payload) {
    if (payload is! Map) return null;
    final user = payload['user'];
    if (user is! Map) return null;
    final driver = user['driver'];
    if (driver is! Map) return null;
    return Map<String, dynamic>.from(driver);
  }

  Future<void> _finishDriverLogin(
    SharedAuthRepository repository, {
    dynamic loginPayload,
  }) async {
    final role = await repository.getUserRole();
    if (role != 'DRIVER') {
      await repository.logout();
      throw Exception('auth.error.unauthorized_role');
    }

    final legalRepo = ref.read(sharedLegalDocumentsRepositoryProvider);
    final ordersRepo = ref.read(driverOrdersRepositoryProvider);
    final termsFuture = legalRepo
        .getAcceptanceStatus()
        .timeout(const Duration(seconds: 4))
        .catchError((_) => null);
    final activeOrderFuture = ordersRepo
        .getActiveDriverOrder()
        .timeout(const Duration(seconds: 4))
        .catchError((_) => null);

    Map<String, dynamic>? profile =
        _extractDriverFromLoginPayload(loginPayload);
    var profileFetchFailed = false;

    // Only fetch `/drivers/me` on login if the login payload did not already
    // include both `isApproved` and `status` (e.g. social login or test mocks).
    if (profile == null ||
        !profile.containsKey('isApproved') ||
        !profile.containsKey('status')) {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      try {
        profile = await driverRepo
            .getMyProfile()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        final message = e.toString();
        if (message.contains('404') || message.contains('PROFILE_NOT_FOUND')) {
          await repository.logout();
          throw Exception('auth.error.pending_approval');
        }
        profileFetchFailed = true;
        debugPrint(
          'Login succeeded; post-login profile fetch failed transiently: $e',
        );

        try {
          final stillLoggedIn = await repository.isLoggedIn();
          if (!stillLoggedIn) {
            state = const AsyncValue.data(false);
            return;
          }
        } catch (_) {}
      }
    }

    if (!profileFetchFailed &&
        (profile == null || profile['isApproved'] != true)) {
      await repository.logout();
      throw Exception('auth.error.pending_approval');
    }

    var nextStartupState = AppStartupState.dashboard;
    if (profile?['status'] == 'SUSPENDED') {
      nextStartupState = AppStartupState.suspended;
    } else {
      final results = await Future.wait<dynamic>([
        termsFuture,
        activeOrderFuture,
      ]);
      final termsStatus = results[0] as Map<String, dynamic>?;
      final activeOrderResult = results[1] as Map<String, dynamic>?;
      if (termsStatus != null && termsStatus['needsAcceptance'] == true) {
        nextStartupState = AppStartupState.needsTerms;
      } else if (activeOrderResult != null &&
          activeOrderResult['data'] != null) {
        nextStartupState = AppStartupState.activeOrder;
      }
    }

    // Connect socket and initialize push notifications in the background
    // so they never stall the login button.
    unawaited(
      ref
          .read(coreSocketServiceProvider)
          .init(autoConnect: true)
          .catchError((_) {}),
    );
    _initPushInBackground();

    _clearDriverState(postLoginState: nextStartupState);
    state = const AsyncValue.data(true);
  }

  void _clearDriverState({AppStartupState? postLoginState}) {
    if (postLoginState != null) {
      ref.read(driverPostLoginStateProvider.notifier).set(
            postLoginState == AppStartupState.unauthenticated
                ? AppStartupState.dashboard
                : postLoginState,
          );
      if (ref.exists(splashProvider)) {
        ref.read(splashProvider.notifier).setPostLoginState(postLoginState);
      }
    } else {
      ref
          .read(driverPostLoginStateProvider.notifier)
          .set(AppStartupState.dashboard);
      if (ref.exists(splashProvider)) {
        ref.invalidate(splashProvider);
      }
    }
    ref.invalidate(driverProfileProvider);
    ref.invalidate(driverOrdersHistoryProvider);
    ref.invalidate(data_providers.sharedInboxProvider);
    ref.invalidate(data_providers.sharedChatProvider);
    ref.invalidate(data_providers.sharedInboxCountsProvider);
    ref.invalidate(orderExecutionProvider);
    ref.invalidate(driverNotificationsProvider);
    ref.invalidate(driverShiftsProvider);
    ref.invalidate(breaksOverviewProvider);
    ref.invalidate(settingsProvider);
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
      try {
        ref.read(coreSocketServiceProvider).disconnect();
      } catch (_) {}
      try {
        await GoogleSignInService.signOut().timeout(const Duration(seconds: 2));
      } catch (_) {}

      final repository = ref.read(sharedAuthRepositoryProvider);

      if (await repository.isLoggedIn()) {
        final push = ref.read(pushNotificationServiceProvider);
        String? fcmToken;
        try {
          fcmToken = await push
              .getToken(waitForApns: false)
              .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
        } catch (_) {}

        unawaited(push.unsubscribeFromRoleTopics('DRIVER'));
        unawaited(push.unregisterToken(token: fcmToken, waitForApns: false));

        try {
          await repository.logout(
            fcmToken: fcmToken,
            timeout: const Duration(seconds: 3),
          );
        } catch (_) {}
      }

      _clearDriverState(postLoginState: AppStartupState.unauthenticated);
      state = const AsyncValue.data(false);
      _goToLogin();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _logoutInProgress = false;
    }
  }

  void _goToLogin() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final router = GoRouter.of(ctx);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/') {
      debugPrint('Driver Auth: deferring /login navigation while SplashScreen is active');
      return;
    }
    router.go('/login');
  }
}
