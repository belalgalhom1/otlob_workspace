import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart';
import 'package:core/core.dart';

part 'register_controller.g.dart';

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
    String? phone,
  }) async {
    state = const AsyncLoading();

    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      final builder = RegisterDtoBuilder()
        ..name = name
        ..email = email
        ..password = password
        ..role = RegisterDtoRoleEnum.CUSTOMER;
      
      if (phone != null && phone.isNotEmpty) {
        String formattedPhone = phone;
        if (formattedPhone.startsWith('0')) {
          formattedPhone = formattedPhone.substring(1);
        }
        if (!formattedPhone.startsWith('+')) {
          builder.phone = '+20$formattedPhone';
        } else {
          builder.phone = formattedPhone;
        }
      }
      
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
