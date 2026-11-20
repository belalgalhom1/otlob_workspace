import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import '../providers/auth_controller.dart';
import 'package:core/core.dart';

part 'verify_otp_controller.g.dart';

@riverpod
class VerifyOtpController extends _$VerifyOtpController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> verify(
    String email,
    String otp, {
    bool isPasswordReset = false,
    String? password,
  }) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      await authRepo.confirmVerification(
        email,
        otp,
        purpose: isPasswordReset ? 'PASSWORD_RESET' : 'VERIFICATION',
      );

      if (!isPasswordReset) {
        if (password != null && password.trim().isNotEmpty) {
          // Fresh registrations have no verified session yet, so complete OTP
          // verification by establishing a genuine authenticated session with
          // the registered credentials before returning success.
          await ref
              .read(authControllerProvider.notifier)
              .login(email, password.trim());
        } else {
          await authRepo.refreshToken();
          await ref.read(authControllerProvider.notifier).checkAuthStatus();
        }
        if (ref.read(authControllerProvider) != AuthStatus.authenticated) {
          throw Exception('auth.error.invalid_credentials');
        }
      }

      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } catch (e, st) {
      if (ref.mounted) {
        state = AsyncError(ApiErrorMapper.fromError(e), st);
      }
      return false;
    }
  }
}
