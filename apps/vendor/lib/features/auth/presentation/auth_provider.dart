import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<bool> build() {
    final sub = unauthenticatedEventStream.stream.listen((_) {
      if (state.value == true) {
        state = const AsyncValue.data(false);
      }
    });
    
    ref.onDispose(() {
      sub.cancel();
    });
    
    return const AsyncValue.data(false);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('DEBUG: Calling repository.login...');
      final repository = ref.read(sharedAuthRepositoryProvider);
      final response = await repository.login(email, password, appType: 'vendor');
      debugPrint('DEBUG: repository.login returned: $response');
      if (response != null && response['access_token'] != null) {
        final role = await repository.getUserRole();
        if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'VENDOR_MEMBER') {
          await repository.logout();
          state = AsyncValue.error(
            'auth.error.unauthorized_role',
            StackTrace.current,
          );
          return;
        }

        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          await pushService.subscribeToRoleTopics(role ?? 'VENDOR');
        } catch (_) {}

        debugPrint('DEBUG: Setting state to data(true)');
        state = const AsyncValue.data(true);
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
        state = AsyncValue.error(e.toString(), st);
      }
    }
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final loggedIn = await repository.isLoggedIn();
      if (!loggedIn) {
        state = const AsyncValue.data(false);
        return;
      }

      final role = await repository.getUserRole();
      if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'VENDOR_MEMBER') {
        await repository.logout();
        state = const AsyncValue.data(false);
        return;
      }

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
          await repository.logout();
          state = const AsyncValue.data(false);
        }
      }
    } catch (e) {
      debugPrint('checkAuth error: $e');
      state = const AsyncValue.data(false);
    }
  }

  Future<void> logout() async {
    String? fcmToken;
    try {
      final push = ref.read(pushNotificationServiceProvider);
      final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
      fcmToken = await push.getToken();
      await push.unsubscribeFromRoleTopics(role ?? 'VENDOR');
      await push.unregisterToken();
    } catch (_) {}

    final repository = ref.read(sharedAuthRepositoryProvider);
    await repository.logout(fcmToken: fcmToken);
    try {
      state = const AsyncValue.data(false);
    } catch (_) {
      // Ignored if provider was auto-disposed
    }
  }
}
