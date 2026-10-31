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

  Future<void> addMember({
    required String identifier,
    required String role,
    String? branchId,
  }) async {
    try {
      final trimmed = identifier.trim();
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(trimmed);
      final isEmail = trimmed.contains('@');

      String? resolvedUserId = isUuid ? trimmed : null;
      if (resolvedUserId == null) {
        try {
          final usersResult = await ref
              .read(adminUsersRepositoryProvider)
              .getUsers(search: trimmed, limit: 10);
          final List<dynamic> usersList = usersResult is List
              ? usersResult
              : (usersResult is Map && usersResult['items'] is List
                    ? usersResult['items'] as List
                    : (usersResult is Map && usersResult['users'] is List
                          ? usersResult['users'] as List
                          : const []));
          final normalizedPhone = !isEmail ? PhoneUtils.normalize(trimmed) : '';
          for (final u in usersList) {
            if (u is! Map) continue;
            final uEmail = (u['email'] ?? '').toString().toLowerCase();
            final uPhone = (u['phone'] ?? '').toString();
            if (isEmail && uEmail == trimmed.toLowerCase()) {
              resolvedUserId = u['id']?.toString();
              break;
            } else if (!isEmail &&
                (uPhone == trimmed || uPhone == normalizedPhone)) {
              resolvedUserId = u['id']?.toString();
              break;
            }
          }
          if (resolvedUserId == null && usersList.length == 1 && usersList.first is Map) {
            resolvedUserId = (usersList.first as Map)['id']?.toString();
          }
        } catch (_) {
          // Non-admin vendor owners may not have access to /users/admin; backend resolves email/phone directly.
        }
      }

      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        'role': role.toUpperCase(),
        if (resolvedUserId != null && resolvedUserId.isNotEmpty)
          'userId': resolvedUserId,
        if (isEmail) 'email': trimmed,
        if (!isEmail && !isUuid) 'phone': PhoneUtils.normalize(trimmed),
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };

      await dio.post('/vendors/$vendorId/members', data: body);
      await fetchMembers();
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> updateRole(
    String memberId,
    String role, {
    String? branchId,
    bool updateBranch = false,
  }) async {
    try {
      if (updateBranch) {
        final dio = ref.read(dioProvider);
        await dio.patch(
          '/vendors/$vendorId/members/$memberId/role',
          data: <String, dynamic>{
            'role': role.toUpperCase(),
            'branchId': (branchId != null && branchId.isNotEmpty)
                ? branchId
                : null,
          },
        );
      } else {
        final repository = ref.read(vendorMembersRepositoryProvider);
        await repository.updateRole(
          vendorId,
          memberId,
          UpdateVendorMemberRoleDto((b) {
            b.role = UpdateVendorMemberRoleDtoRoleEnum.valueOf(
              role.toUpperCase(),
            );
            if (branchId != null && branchId.isNotEmpty) {
              b.branchId = branchId;
            }
          }),
        );
      }

      await fetchMembers();
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      final repository = ref.read(vendorMembersRepositoryProvider);
      await repository.removeMember(vendorId, memberId);
      await fetchMembers();
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }
}
