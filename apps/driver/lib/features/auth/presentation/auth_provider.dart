import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:core/core.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AsyncValue<bool> build() {
    Future.microtask(() => _checkInitialAuth());
    return const AsyncValue.loading();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await repository.isLoggedIn();
      if (isLoggedIn) {
        final role = await repository.getUserRole();
        if (role == 'DRIVER') {
          state = const AsyncValue.data(true);
          return;
        } else {
          await repository.logout();
        }
      }
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
      final profile = await driverRepo.getMyProfile();
      if (profile == null || profile['isApproved'] != true) {
        await repository.logout();
        throw Exception('auth.error.pending_approval');
      }

      // Initialize Push Notifications and register FCM token
      Future(() async {
        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          await pushService.subscribeToRoleTopics('DRIVER');
        } catch (_) {}
      });
      
      state = const AsyncValue.data(true);
    } catch (e, st) {
      final errorString = e.toString();
      if (errorString.contains('404') || errorString.contains('PROFILE_NOT_FOUND')) {
        ref.read(sharedAuthRepositoryProvider).logout();
        state = AsyncValue.error(Exception('auth.error.pending_approval'), st);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(sharedAuthRepositoryProvider);
      await repository.logout();
      state = const AsyncValue.data(false);
      ref.invalidate(splashProvider);
      
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.go('/login');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
