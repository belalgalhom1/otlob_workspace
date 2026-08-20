import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:core/core.dart';

part 'reset_password_controller.g.dart';

@riverpod
class ResetPasswordController extends _$ResetPasswordController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> reset(String email, String otp, String newPassword) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      await authRepo.resetPassword(email, otp, newPassword);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(ApiErrorMapper.fromError(e), st);
      return false;
    }
  }
}
