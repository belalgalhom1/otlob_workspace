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

  Future<bool> verify(String email, String otp, {bool isPasswordReset = false}) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      await authRepo.confirmVerification(
        email,
        otp,
        purpose: isPasswordReset ? 'PASSWORD_RESET' : 'VERIFICATION',
      );
      
      if (!isPasswordReset) {
        try {
          await authRepo.refreshToken();
          await ref.read(authControllerProvider.notifier).checkAuthStatus();
        } catch (e) {
          debugPrint('Refresh token failed after OTP verify: $e');
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
