import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import '../providers/auth_controller.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

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
        if (password != null && password.isNotEmpty) {
          // Fresh registrations have no persisted session yet (no refresh
          // token), so after OTP verification we finish the flow by logging in
          // with the just-registered credentials instead of attempting a
          // doomed token refresh.
          try {
            await ref
                .read(authControllerProvider.notifier)
                .login(email, password);
          } catch (e) {
            debugPrint('Auto-login after OTP verify failed: $e');
          }
        } else {
          try {
            await authRepo.refreshToken();
            await ref.read(authControllerProvider.notifier).checkAuthStatus();
          } catch (e) {
            debugPrint('Refresh token failed after OTP verify: $e');
          }
        }
      }

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(ApiErrorMapper.fromError(e), st);
      return false;
    }
  }
}
