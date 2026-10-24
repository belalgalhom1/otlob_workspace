import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'profile_controller.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

part 'delivery_address_provider.g.dart';

@Riverpod(keepAlive: true)
class ManualSelectedAddressId extends _$ManualSelectedAddressId {
  @override
  String? build() {
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.unauthenticated) {
        state = null;
      }
    });
    return null;
  }

  void setAddressId(String? id) {
    state = id;
  }
}

@Riverpod(keepAlive: true)
Map<String, dynamic>? activeDeliveryAddress(Ref ref) {
  final profileState = ref.watch(profileProvider);
  final addresses = profileState.addresses;
  
  if (addresses.isEmpty) return null;

  final manualId = ref.watch(manualSelectedAddressIdProvider);
  if (manualId != null) {
    try {
      return addresses.firstWhere((a) => a['id'] == manualId);
    } catch (_) {}
  }

  try {
    return addresses.firstWhere((a) => a['isDefault'] == true);
  } catch (_) {
    return addresses.first;
  }
}
