import 'dart:async';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';

part 'auth_controller.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, unverified }

class NeedsPhone extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final needsPhoneProvider = NotifierProvider<NeedsPhone, bool>(NeedsPhone.new);

class NeedsAddress extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final needsAddressProvider =
    NotifierProvider<NeedsAddress, bool>(NeedsAddress.new);

/// Returns true when the current user has no delivery address saved.
Future<bool> userMissingAddress(Ref ref) async {
  try {
    final raw = await ref.read(customerAddressesRepositoryProvider).getAddresses();
    final list = raw is List ? raw : <dynamic>[];
    return list.isEmpty;
  } catch (_) {
    return false;
  }
}

/// Returns true when the current user has no phone number on record.
Future<bool> userMissingPhone(Ref ref) async {
  try {
    final raw = await ref.read(sharedUserRepositoryProvider).getUser();
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final user = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    final data = user['data'] is Map
        ? Map<String, dynamic>.from(user['data'] as Map)
        : user;
    final phone = (data['phone'] ?? user['phone'] ?? map['phone'])?.toString().trim() ?? '';
    return phone.isEmpty;
  } catch (_) {
    return false;
  }
}

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
    // The interceptor fires this once it has concluded the session is unusable
    // (refresh token missing, or refresh 401/403), and may have already cleared
    // the tokens. Always run logout: with no session left it skips the network
    // calls and flips state to unauthenticated so the router bounces to login,
    // instead of stranding the UI on error cards.
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
    ref.read(needsPhoneProvider.notifier).set(await userMissingPhone(ref));
    ref.read(needsAddressProvider.notifier).set(await userMissingAddress(ref));
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
    ref.read(needsPhoneProvider.notifier).set(await userMissingPhone(ref));
    ref.read(needsAddressProvider.notifier).set(await userMissingAddress(ref));
    try {
      final push = ref.read(pushNotificationServiceProvider);
      await push.initialize();
      await push.subscribeToRoleTopics('CUSTOMER');
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    final idToken = await GoogleSignInService.getIdToken();
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    await authRepo.socialLogin(
      SocialLoginDto((b) => b
        ..provider = 'GOOGLE'
        ..idToken = idToken
        ..app = 'customer'),
    );
    state = AuthStatus.authenticated;
    ref.read(needsPhoneProvider.notifier).set(await userMissingPhone(ref));
    ref.read(needsAddressProvider.notifier).set(await userMissingAddress(ref));
    try {
      final push = ref.read(pushNotificationServiceProvider);
      await push.initialize();
      await push.subscribeToRoleTopics('CUSTOMER');
    } catch (_) {}
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    ref.read(needsPhoneProvider.notifier).set(false);
    ref.read(needsAddressProvider.notifier).set(false);
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);

      // No session: skip push cleanup/revocation. Those calls would fire
      // without a bearer token, 401, and re-enter the logout loop.
      if (!await authRepo.isLoggedIn()) {
        state = AuthStatus.unauthenticated;
        return;
      }

      try {
        await GoogleSignInService.signOut();
      } catch (_) {}

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
