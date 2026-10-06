import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'auth_controller.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      await ref.read(authControllerProvider.notifier).login(email, password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final errorMessage = ApiErrorMapper.fromError(e);
      state = AsyncError(ApiErrorMapper.fromError(errorMessage), st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      if (e.toString().contains('google.sign_in.no_token')) {
        state = const AsyncData(null);
        return false;
      }
      final errorMessage = ApiErrorMapper.fromError(e);
      state = AsyncError(ApiErrorMapper.fromError(errorMessage), st);
      return false;
    }
  }
}
