import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/tickets/presentation/ticket_provider.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';
import 'package:vendor/features/promotions/presentation/promotion_provider.dart';
import 'package:vendor/features/vendors/presentation/vendor_provider.dart';
import 'package:vendor/features/vendors/presentation/vertical_provider.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/features/settings/presentation/bloc/settings_provider.dart';
import 'package:vendor/features/wallet/presentation/vendor_wallet_provider.dart';
import 'package:vendor/features/wallet/data/wallet_providers.dart';

part 'auth_provider.g.dart';

class UpdateStoreUrl extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final updateStoreUrlProvider =
    NotifierProvider<UpdateStoreUrl, String?>(UpdateStoreUrl.new);

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  bool _logoutInProgress = false;

  @override
  AsyncValue<bool> build() {
    final sub = unauthenticatedEventStream.stream.listen((_) {
      _handleUnauthenticated();
    });

    ref.onDispose(() {
      sub.cancel();
    });

    return const AsyncValue.data(false);
  }

  Future<void> _handleUnauthenticated() async {
    if (_logoutInProgress) return;
    if (state.value == false) return;
    // The interceptor fires this once it has concluded the session is unusable
    // (refresh token missing, or refresh 401/403), and may have already cleared
    // the tokens. Always run logout: with no session left it skips the network
    // calls and simply flips state to false so the router bounces to login,
    // instead of stranding the dashboard on an error card.
    logout();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('DEBUG: Calling repository.login...');
      final repository = ref.read(sharedAuthRepositoryProvider);
      final response = await repository.login(email, password, appType: 'vendor');
      debugPrint('DEBUG: repository.login returned: $response');
      if (response != null && response['access_token'] != null) {
        await _finishVendorLogin(repository);
      } else {
        debugPrint('DEBUG: Invalid credentials error');
        state = AsyncValue.error(
          'auth.error.invalid_credentials',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      debugPrint('DEBUG: Exception in login: $e\n$st');
      if (e.toString() == 'ACCESS_DENIED') {
        state = AsyncValue.error('common.error.forbidden', st);
      } else {
        state = AsyncValue.error(ApiErrorMapper.fromError(e), st);
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
          ..provider = 'GOOGLE'
          ..idToken = idToken
          ..app = 'vendor'),
      );
      if (response != null && response['access_token'] != null) {
        await _finishVendorLogin(repository);
      } else {
        state = AsyncValue.error(
          'auth.error.invalid_credentials',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      if (e.toString().contains('google.sign_in.no_token')) {
        state = const AsyncValue.data(false);
        return;
      }
      debugPrint('DEBUG: Exception in loginWithGoogle: $e\n$st');
      state = AsyncValue.error(ApiErrorMapper.fromError(e), st);
    }
  }

  Future<void> _finishVendorLogin(SharedAuthRepository repository) async {
    final role = await repository.getUserRole();
    if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'VENDOR_MEMBER' && role != 'DRIVER_MANAGER') {
      await logout();
      state = AsyncValue.error(
        'auth.error.unauthorized_role',
        StackTrace.current,
      );
      return;
    }

    _clearVendorState();

    // Seed the active vendor for single-membership accounts so they land
    // on the dashboard instead of the vendor-selection screen.
    await _seedActiveVendor(repository, onlySingle: true);

    try {
      final pushService = ref.read(pushNotificationServiceProvider);
      await pushService.initialize();
      await pushService.subscribeToRoleTopics(role ?? 'VENDOR');
    } catch (_) {}

    debugPrint('DEBUG: Setting state to data(true)');
    state = const AsyncValue.data(true);
  }

  Future<void> _seedActiveVendor(
    SharedAuthRepository repository, {
    bool onlySingle = false,
  }) async {
    try {
      final memberships = await repository.getVendorMemberships();
      if (memberships.isEmpty) return;
      if (onlySingle && memberships.length != 1) return;
      final map = memberships.first as Map<String, dynamic>;
      final vendorId = map['vendorId'] as String?;
      if (vendorId != null && vendorId.isNotEmpty) {
        await ref.read(activeVendorProvider.notifier).setActiveVendor(vendorId);
      }
    } catch (_) {}
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final loggedIn = await repository.isLoggedIn();
      if (!loggedIn) {
        await ref.read(activeVendorProvider.notifier).clearActiveVendor();
        state = const AsyncValue.data(false);
        return;
      }

      final role = await repository.getUserRole();
      if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'VENDOR_MEMBER' && role != 'DRIVER_MANAGER') {
        await logout();
        state = const AsyncValue.data(false);
        return;
      }

      // Restore the previously selected vendor from persisted memberships so
      // splash does not bounce single-membership users to /select-vendor.
      // Multi-membership users keep choosing on the selection screen.
      await _seedActiveVendor(repository, onlySingle: true);

      final isExpired = await repository.isTokenExpired();
      if (!isExpired) {
        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          await pushService.subscribeToRoleTopics(role ?? 'VENDOR');
        } catch (_) {}
        state = const AsyncValue.data(true);
      } else {
        try {
          await repository.refreshToken();
          try {
            final pushService = ref.read(pushNotificationServiceProvider);
            await pushService.initialize();
            await pushService.subscribeToRoleTopics(role ?? 'VENDOR');
          } catch (_) {}
          state = const AsyncValue.data(true);
        } catch (e) {
          await logout();
          state = const AsyncValue.data(false);
        }
      }
    } catch (e) {
      debugPrint('checkAuth error: $e');
      state = const AsyncValue.data(false);
    }
  }

  void _clearVendorState() {
    ref.invalidate(ordersProvider);
    ref.invalidate(ordersRefreshErrorProvider);
    ref.invalidate(activeVendorProvider);
    ref.invalidate(data_providers.sharedInboxProvider);
    ref.invalidate(data_providers.sharedChatProvider);
    ref.invalidate(data_providers.sharedInboxCountsProvider);
    ref.invalidate(ticketProvider);
    ref.invalidate(userProvider);
    ref.invalidate(promotionProvider);
    ref.invalidate(vendorProvider);
    ref.invalidate(verticalProvider);
    ref.invalidate(zoneProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(vendorWalletDataProvider);
    ref.invalidate(pendingTopUpsProvider);
    ref.invalidate(platformWalletsProvider);
  }

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      try {
        await GoogleSignInService.signOut();
      } catch (_) {}
      try {
        await ref.read(activeVendorProvider.notifier).clearActiveVendor();
      } catch (_) {}
      try {
        ref.read(coreSocketServiceProvider).disconnect();
      } catch (_) {}

      final repository = ref.read(sharedAuthRepositoryProvider);

      if (await repository.isLoggedIn()) {
        String? fcmToken;
        try {
          final push = ref.read(pushNotificationServiceProvider);
          final role = await repository.getUserRole();
          fcmToken = await push.getToken();
          await push.unsubscribeFromRoleTopics(role ?? 'VENDOR');
          await push.unregisterToken();
        } catch (_) {}

        try {
          await repository.logout(fcmToken: fcmToken);
        } catch (_) {}
      }

      _clearVendorState();
      state = const AsyncValue.data(false);
    } finally {
      _logoutInProgress = false;
    }
  }
}
