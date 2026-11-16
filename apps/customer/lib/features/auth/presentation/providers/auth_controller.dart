import 'dart:async';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart' hide inboxCountsProvider;
import 'package:data/providers.dart' as data_providers;
import 'package:core/core.dart' hide tokenServiceProvider;
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

/// Returns true when the current user has not accepted the latest published terms of use.
Future<bool> userNeedsTermsAcceptance(Ref ref) async {
  try {
    final status = await ref
        .read(sharedLegalDocumentsRepositoryProvider)
        .getAcceptanceStatus()
        .timeout(const Duration(seconds: 4));
    return status?['needsAcceptance'] == true;
  } catch (_) {
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
  } catch (_) {
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
  } catch (_) {
    return false;
  }
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
    unawaited(
      Future<void>(() async {
        try {
          if (!ref.mounted) return;
          final push = ref.read(pushNotificationServiceProvider);
          await push.initialize();
          if (!ref.mounted) return;
          await push.subscribeToRoleTopics('CUSTOMER');
        } catch (_) {}
      }),
    );
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
      try {
        await authRepo.refreshToken();
      } catch (_) {
        await logout();
        return;
      }
    }

    await _applyPostAuthGates();
    if (!ref.mounted) return;
    // Set authenticated after gate flags are populated so RouterNotifier
    // evaluates the complete post-auth state in a single transition.
    state = AuthStatus.authenticated;
    _initPushInBackground();
  }

  Future<void> login(String email, String password) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    final payload =
        await authRepo.login(email, password, appType: 'customer');
    _clearUserProviders();
    await _applyPostAuthGates(loginPayload: payload);
    if (!ref.mounted) return;
    state = AuthStatus.authenticated;
    _initPushInBackground();
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
      _clearUserProviders();
      await _applyPostAuthGates(loginPayload: payload);
      if (!ref.mounted) return true;
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
