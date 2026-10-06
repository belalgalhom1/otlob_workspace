import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart';
import 'package:core/core.dart';

part 'register_controller.g.dart';

String formatEgyptPhone(String phone) {
  String formattedPhone = phone.trim();
  if (formattedPhone.startsWith('0')) {
    formattedPhone = formattedPhone.substring(1);
  }
  if (!formattedPhone.startsWith('+')) {
    return '+20$formattedPhone';
  }
  return formattedPhone;
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
      state = AsyncError(ApiErrorMapper.fromError(errorMessage), st);
      return false;
    }
  }
}
