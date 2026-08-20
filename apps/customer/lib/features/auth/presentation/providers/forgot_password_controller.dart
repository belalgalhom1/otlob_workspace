import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:core/core.dart';

part 'forgot_password_controller.g.dart';

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> sendOtp(String email) async {
    state = const AsyncLoading();

    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      await authRepo.forgotPassword(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(ApiErrorMapper.fromError(e), st);
      return false;
    }
  }
}
