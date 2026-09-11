import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:core/core.dart';

part 'auth_controller.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, unverified }

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  StreamSubscription<void>? _unauthSub;
  bool _logoutInProgress = false;

  @override
  AuthStatus build() {
    _unauthSub?.cancel();
    _unauthSub = unauthenticatedEventStream.stream.listen((_) {
      _handleUnauthenticated();
    });
    ref.onDispose(() {
      _unauthSub?.cancel();
    });
    return AuthStatus.initial;
  }

  Future<void> _handleUnauthenticated() async {
    if (_logoutInProgress) return;
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    // The event fires after the interceptor already cleared the session; do
    // not re-run logout without a session or we re-enter the 401 loop.
    if (!await authRepo.isLoggedIn()) return;
    logout();
  }

  Future<void> checkAuthStatus() async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    final hasSession = await authRepo.isLoggedIn();

    if (!hasSession) {
      await authRepo.logout();
      state = AuthStatus.unauthenticated;
      return;
    }

    final isExpired = await authRepo.isTokenExpired();
    if (isExpired) {
      try {
        await authRepo.refreshToken();
      } catch (_) {
        await authRepo.logout();
        state = AuthStatus.unauthenticated;
        return;
      }
    }

    // For now, treat all authenticated users as verified
    // If verification state is needed, fetch it from profile
    state = AuthStatus.authenticated;
    try {
      final push = ref.read(pushNotificationServiceProvider);
      await push.initialize();
      await push.subscribeToRoleTopics('CUSTOMER');
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    await authRepo.login(email, password, appType: 'customer');
    state = AuthStatus.authenticated;
    try {
      final push = ref.read(pushNotificationServiceProvider);
      await push.initialize();
      await push.subscribeToRoleTopics('CUSTOMER');
    } catch (_) {}
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);

      // No session: skip push cleanup/revocation. Those calls would fire
      // without a bearer token, 401, and re-enter the logout loop.
      if (!await authRepo.isLoggedIn()) {
        state = AuthStatus.unauthenticated;
        return;
      }

      String? fcmToken;
      try {
        final push = ref.read(pushNotificationServiceProvider);
        fcmToken = await push.getToken();
        await push.unsubscribeFromRoleTopics('CUSTOMER');
        await push.unregisterToken();
      } catch (_) {}
      await authRepo.logout(fcmToken: fcmToken);
      state = AuthStatus.unauthenticated;
    } finally {
      _logoutInProgress = false;
    }
  }
}
