import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:vendor/core/providers.dart';
import 'package:core/core.dart';

part 'vendor_members_provider.g.dart';

@riverpod
class VendorMembersNotifier extends _$VendorMembersNotifier {
  @override
  AsyncValue<List<dynamic>> build(String vendorId) {
    fetchMembers();
    return const AsyncValue.loading();
  }

  Future<void> fetchMembers() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(vendorMembersRepositoryProvider);
      final result = await repository.getMembers(vendorId);
      state = AsyncValue.data(result is List ? result : []);
    } catch (e, st) {
      state = AsyncValue.error(ApiErrorMapper.fromError(e), st);
    }
  }

  Future<void> updateRole(String memberId, String role) async {
    try {
      final repository = ref.read(vendorMembersRepositoryProvider);
      
      await repository.updateRole(
        vendorId, 
        memberId, 
        UpdateVendorMemberRoleDto((b) => b..role = UpdateVendorMemberRoleDtoRoleEnum.valueOf(role.toUpperCase()))
      );
      
      await fetchMembers();
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }
}
