import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';

part 'auth_controller.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, unverified }

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthStatus build() {
    return AuthStatus.initial;
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
  }

  Future<void> login(String email, String password) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    await authRepo.login(email, password);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    await authRepo.logout();
    state = AuthStatus.unauthenticated;
  }
}
