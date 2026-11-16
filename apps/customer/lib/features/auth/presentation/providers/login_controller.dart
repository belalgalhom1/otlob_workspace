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
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } catch (e, st) {
      if (ref.mounted) {
        final errorMessage = ApiErrorMapper.fromError(e);
        state = AsyncError(errorMessage, st);
      }
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final success =
          await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return success;
    } catch (e, st) {
      if (e.toString().contains('google.sign_in.no_token')) {
        if (ref.mounted) {
          state = const AsyncData(null);
        }
        return false;
      }
      if (ref.mounted) {
        final errorMessage = ApiErrorMapper.fromError(e);
        state = AsyncError(errorMessage, st);
      }
      return false;
    }
  }
}
