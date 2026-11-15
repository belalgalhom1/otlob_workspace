import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart';
import 'package:core/core.dart';

part 'register_controller.g.dart';

String formatEgyptPhone(String phone) {
  String cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('+200')) {
    cleaned = '+20${cleaned.substring(4)}';
  } else if (cleaned.startsWith('0020')) {
    cleaned = '+20${cleaned.substring(4)}';
  } else if (cleaned.startsWith('+20')) {
    // Already prefixed
  } else if (cleaned.startsWith('20') && cleaned.length >= 12) {
    cleaned = '+$cleaned';
  } else if (cleaned.startsWith('0')) {
    cleaned = '+20${cleaned.substring(1)}';
  } else {
    cleaned = '+20$cleaned';
  }
  return cleaned;
}

@riverpod
class RegisterController extends _$RegisterController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = const AsyncLoading();

    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      final builder = RegisterDtoBuilder()
        ..name = name
        ..email = email
        ..password = password
        ..role = RegisterDtoRoleEnum.CUSTOMER
        ..phone = formatEgyptPhone(phone);

      await authRepo.register(builder.build());
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final errorMessage = ApiErrorMapper.fromError(e);
      state = AsyncError(errorMessage, st);
      return false;
    }
  }
}
