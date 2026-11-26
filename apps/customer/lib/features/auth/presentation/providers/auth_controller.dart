import 'dart:async';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart' hide inboxCountsProvider;
import 'package:data/providers.dart' as data_providers;
import 'package:core/core.dart' hide tokenServiceProvider;
import 'package:ui_kit/ui_kit.dart' show OtlobLoginEntranceCoordinator;
import '../../../../core/services/token_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import '../../../chat/presentation/providers/inbox_counts_provider.dart';
import '../../../chat/presentation/providers/support_ticket_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../home/presentation/providers/favorites_provider.dart';

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

class NeedsTerms extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final needsTermsProvider = NotifierProvider<NeedsTerms, bool>(NeedsTerms.new);

bool _isInvalidSessionError(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    return code == 401 || code == 403;
  }
  return false;
}

/// Returns true when the current user has not accepted the latest published terms of use.
Future<bool> userNeedsTermsAcceptance(Ref ref) async {
  try {
    final status = await ref
        .read(sharedLegalDocumentsRepositoryProvider)
        .getAcceptanceStatus()
        .timeout(const Duration(seconds: 4));
    return status?['needsAcceptance'] == true;
  } catch (e) {
    if (_isInvalidSessionError(e)) rethrow;
    return false;
  }
}

/// Returns true when the current user has no delivery address saved.
Future<bool> userMissingAddress(Ref ref) async {
  try {
    final raw = await ref
        .read(customerAddressesRepositoryProvider)
        .getAddresses()
        .timeout(const Duration(seconds: 4));
    final list = raw is List ? raw : <dynamic>[];
    return list.isEmpty;
  } catch (e) {
    if (_isInvalidSessionError(e)) rethrow;
    return false;
  }
}

/// Returns true when the current user has no phone number on record.
Future<bool> userMissingPhone(Ref ref) async {
  try {
    final raw = await ref
        .read(sharedUserRepositoryProvider)
        .getUser()
        .timeout(const Duration(seconds: 4));
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final user = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    final data = user['data'] is Map
        ? Map<String, dynamic>.from(user['data'] as Map)
        : user;
    final phone = (data['phone'] ?? user['phone'] ?? map['phone'])?.toString().trim() ?? '';
    return phone.isEmpty;
  } catch (e) {
    if (_isInvalidSessionError(e)) rethrow;
    return false;
  }
}

bool _hasValidTokensInPayload(dynamic payload) {
  if (payload is! Map) return false;
  final access = payload['access_token'];
  final refresh = payload['refresh_token'];
  return access is String &&
      access.trim().isNotEmpty &&
      refresh is String &&
      refresh.trim().isNotEmpty;
}

bool? _extractMissingPhoneFromLoginPayload(dynamic payload) {
  if (payload is! Map) return null;
  final user = payload['user'];
  if (user is! Map) return null;
  if (!user.containsKey('phone')) return null;
  final phone = user['phone']?.toString().trim() ?? '';
  return phone.isEmpty;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  StreamSubscription<void>? _unauthSub;
  bool _logoutInProgress = false;
  bool _rememberCredentialsPending = false;

  void setRememberCredentialsPending(bool value) {
    _rememberCredentialsPending = value;
  }

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

  void _clearUserProviders() {
    ref.invalidate(accessTokenProvider);
    ref.invalidate(data_providers.sharedInboxProvider);
    ref.invalidate(data_providers.sharedChatProvider);
    ref.invalidate(data_providers.sharedInboxCountsProvider);
    ref.invalidate(ordersProvider);
    ref.invalidate(cartProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(activeDeliveryAddressProvider);
    ref.invalidate(manualSelectedAddressIdProvider);
    ref.invalidate(inboxCountsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(coinHistoryProvider);
    ref.invalidate(supportTicketProvider);
  }

  Future<void> _applyPostAuthGates({dynamic loginPayload}) async {
    final missingPhoneFromPayload =
        _extractMissingPhoneFromLoginPayload(loginPayload);
    final results = await Future.wait<bool>([
      userNeedsTermsAcceptance(ref),
      missingPhoneFromPayload != null
          ? Future<bool>.value(missingPhoneFromPayload)
          : userMissingPhone(ref),
      userMissingAddress(ref),
    ]);
    if (!ref.mounted) return;
    ref.read(needsTermsProvider.notifier).set(results[0]);
    ref.read(needsPhoneProvider.notifier).set(results[1]);
    ref.read(needsAddressProvider.notifier).set(results[2]);
  }

  void _initPushInBackground() {
    Future<void> run() async {
      try {
        if (!ref.mounted) return;
        final push = ref.read(pushNotificationServiceProvider);
        await push.initialize();
        if (!ref.mounted) return;
        await push.subscribeToRoleTopics('CUSTOMER');
      } catch (_) {}
    }

    unawaited(run());
  }

  Future<void> _abortFailedSessionSetup() async {
    try {
      await ref.read(sharedAuthRepositoryProvider).clearLocalSession();
    } catch (_) {}
    if (!ref.mounted) return;
    ref.read(needsTermsProvider.notifier).set(false);
    ref.read(needsPhoneProvider.notifier).set(false);
    ref.read(needsAddressProvider.notifier).set(false);
    state = AuthStatus.unauthenticated;
  }

  Future<void> checkAuthStatus() async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    final hasSession = await authRepo.isLoggedIn();

    if (!hasSession) {
      await logout();
      return;
    }

    final isExpired = await authRepo.isTokenExpired();
    if (isExpired) {
      bool refreshExpired = false;
      try {
        refreshExpired = await authRepo.isRefreshTokenExpired();
      } catch (_) {
        refreshExpired = false;
      }
      if (refreshExpired) {
        await logout();
        return;
      }

      try {
        await authRepo.refreshToken();
      } catch (e) {
        if (_isInvalidSessionError(e) ||
            e.toString().contains('NO_REFRESH_TOKEN') ||
            e.toString().contains('REFRESH_FAILED')) {
          await logout();
        } else if (ref.mounted) {
          ref.read(needsTermsProvider.notifier).set(false);
          ref.read(needsPhoneProvider.notifier).set(false);
          ref.read(needsAddressProvider.notifier).set(false);
          state = AuthStatus.unauthenticated;
        }
        return;
      }
    }

    try {
      await _applyPostAuthGates();
    } catch (e) {
      if (_isInvalidSessionError(e)) {
        await logout();
        return;
      }
    }
    if (!ref.mounted) return;
    // Set authenticated after gate flags are populated so RouterNotifier
    // evaluates the complete post-auth state in a single transition.
    OtlobLoginEntranceCoordinator.reset();
    state = AuthStatus.authenticated;
    _initPushInBackground();
  }

  Future<void> login(String email, String password) async {
    final remember = _rememberCredentialsPending;
    _rememberCredentialsPending = false;
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    try {
      final payload =
          await authRepo.login(email, password, appType: 'customer');
      if (!_hasValidTokensInPayload(payload)) {
        await _abortFailedSessionSetup();
        throw Exception('auth.error.invalid_credentials');
      }

      if (remember) {
        final user = payload is Map && payload['user'] is Map
            ? Map<String, dynamic>.from(payload['user'] as Map)
            : const <String, dynamic>{};
        final userName = (user['name']?.toString() ?? '').trim();
        final userEmail = (user['email']?.toString() ?? '').trim();
        try {
          await ref.read(tokenServiceProvider).saveSavedProfile(
                email: userEmail.isNotEmpty ? userEmail : email,
                password: password,
                name: userName.isNotEmpty ? userName : email.split('@')[0],
                role: 'CUSTOMER',
              );
        } catch (_) {}
      }

      _clearUserProviders();
      try {
        await _applyPostAuthGates(loginPayload: payload);
      } catch (e) {
        if (_isInvalidSessionError(e)) {
          await _abortFailedSessionSetup();
          rethrow;
        }
      }
      if (!ref.mounted) return;
      OtlobLoginEntranceCoordinator.reset();
      state = AuthStatus.authenticated;
      _initPushInBackground();
    } catch (_) {
      if (ref.mounted && state == AuthStatus.initial) {
        state = AuthStatus.unauthenticated;
      }
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final idToken = await GoogleSignInService.getIdToken();
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      final payload = await authRepo.socialLogin(
        SocialLoginDto((b) => b
          ..provider = SocialLoginDtoProviderEnum.GOOGLE
          ..idToken = idToken
          ..app = SocialLoginDtoAppEnum.customer),
      );
      if (!_hasValidTokensInPayload(payload)) {
        await _abortFailedSessionSetup();
        throw Exception('auth.error.invalid_credentials');
      }
      _clearUserProviders();
      try {
        await _applyPostAuthGates(loginPayload: payload);
      } catch (e) {
        if (_isInvalidSessionError(e)) {
          await _abortFailedSessionSetup();
          rethrow;
        }
      }
      if (!ref.mounted) return true;
      OtlobLoginEntranceCoordinator.reset();
      state = AuthStatus.authenticated;
      _initPushInBackground();
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('google.sign_in.no_token')) {
        // User cancelled — stay on login, no error shown
        if (state != AuthStatus.authenticated) {
          state = AuthStatus.unauthenticated;
        }
        return false;
      }
      if (msg.contains('404') || msg.contains('PROFILE_NOT_FOUND')) {
        try {
          await ref.read(sharedAuthRepositoryProvider).logout();
        } catch (_) {}
        state = AuthStatus.unauthenticated;
        return false;
      }
      if (state == AuthStatus.initial) {
        state = AuthStatus.unauthenticated;
      }
      // Re-throw so the UI can show a snackbar
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    ref.read(needsPhoneProvider.notifier).set(false);
    ref.read(needsAddressProvider.notifier).set(false);
    ref.read(needsTermsProvider.notifier).set(false);
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    try {
      try {
        ref.read(socketServiceProvider).disconnect();
      } catch (_) {}
      try {
        ref.read(coreSocketServiceProvider).disconnect();
      } catch (_) {}

      try {
        await GoogleSignInService.signOut().timeout(const Duration(seconds: 2));
      } catch (_) {}

      bool hasSession = false;
      try {
        hasSession = await authRepo.isLoggedIn();
      } catch (_) {}

      if (hasSession) {
        final push = ref.read(pushNotificationServiceProvider);
        String? fcmToken;
        try {
          // Do not wait for iOS APNs registration loops during logout.
          fcmToken = await push
              .getToken(waitForApns: false)
              .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
        } catch (_) {}

        // Fire-and-forget topic unsubscribe (internally 2s-bounded) so slow or
        // unconfigured FCM on simulators/offline devices never stalls logout.
        unawaited(push.unsubscribeFromRoleTopics('CUSTOMER'));

        try {
          // `/auth/logout` revokes the session and deletes the supplied
          // `fcmToken` from devices; its CancelToken bounds slow networks.
          await authRepo.logout(
            fcmToken: fcmToken,
            timeout: const Duration(seconds: 3),
          );
        } catch (_) {}
      } else {
        try {
          unawaited(
            ref
                .read(pushNotificationServiceProvider)
                .unsubscribeFromRoleTopics('CUSTOMER'),
          );
        } catch (_) {}
      }
    } finally {
      try {
        await ref.read(tokenServiceProvider).clearTokens();
      } catch (_) {}
      try {
        await authRepo.clearLocalSession();
      } catch (_) {}

      // Flip auth status BEFORE invalidating user providers so rebuilt
      // providers observe AuthStatus.unauthenticated and do not fire
      // follow-up authenticated requests with cleared tokens.
      state = AuthStatus.unauthenticated;
      _clearUserProviders();
      _logoutInProgress = false;
    }
  }
}
