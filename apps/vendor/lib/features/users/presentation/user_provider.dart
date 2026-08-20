import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:flutter/foundation.dart';

part 'user_provider.g.dart';

class UsersStateData {
  final List<dynamic> users;
  final int total;
  final int page;
  final int limit;
  UsersStateData({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });
}

@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  @override
  AsyncValue<UsersStateData> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    bool? isBanned,
  }) async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(adminUsersRepositoryProvider);
      final result = await repository.getUsers(
        page: page,
        limit: limit,
        search: search,
        role: role,
        isBanned: isBanned,
      );
      state = AsyncValue.data(
        UsersStateData(
          users: result['users'] ?? result['items'] ?? [],
          total: result['total'] ?? 0,
          page: page,
          limit: limit,
        ),
      );
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error('Failed to fetch users', st);
      }
    }
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? vendorId,
    String? vendorRole,
    String? title,
    String? titleAr,
    List<String>? permissions,
  }) async {
    final repository = ref.read(adminUsersRepositoryProvider);
    final result = await repository.addUser(RegisterDto((b) {
      b.name = name;
      b.email = email;
      b.password = password;
      b.role = RegisterDtoRoleEnum.valueOf(role.toUpperCase());
      if (phone != null) b.phone = phone;
    }));
    if (result == null) throw Exception('Failed to add user');
    
    if (role == 'VENDOR_MEMBER' && vendorId != null && vendorRole != null) {
      final userId = result['id'];
      if (userId != null) {
        try {
          final membersRepo = ref.read(vendorMembersRepositoryProvider);
          await membersRepo.adminAddMember(
            vendorId,
            AddVendorMemberDto((b) => b
              ..userId = userId
              ..role = AddVendorMemberDtoRoleEnum.valueOf(vendorRole.toUpperCase())
            ),
          );
        } catch (e) {
          debugPrint('Failed to assign vendor member: $e');
        }
      }
    }

    final userIdStr = result['id'];
    if (userIdStr != null && (title != null || titleAr != null || permissions != null)) {
      await repository.updateUser(
        userIdStr,
        AdminUpdateUserDto((b) {
          if (title != null) b.title = title;
          if (titleAr != null) b.titleAr = titleAr;
          if (permissions != null) b.permissions.replace(permissions.map((e) => AdminUpdateUserDtoPermissionsEnum.valueOf(e)));
        }),
      );
    }

    await fetchUsers(
      page: state.value?.page ?? 1,
      limit: state.value?.limit ?? 20,
    );
  }

  Future<void> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? vendorId,
    String? oldVendorId,
    String? oldMemberId,
    String? vendorRole,
    String? password,
    String? title,
    String? titleAr,
    List<String>? permissions,
  }) async {
    final repository = ref.read(adminUsersRepositoryProvider);
    final result = await repository.updateUser(
      id,
      AdminUpdateUserDto((b) {
        if (name != null) b.name = name;
        if (email != null) b.email = email;
        if (phone != null) b.phone = phone;
        if (role != null) b.role = AdminUpdateUserDtoRoleEnum.valueOf(role.toUpperCase());
        if (vendorId != null) b.vendorId = vendorId;
        if (vendorRole != null) b.vendorRole = AdminUpdateUserDtoVendorRoleEnum.valueOf(vendorRole.toUpperCase());
        if (password != null) b.password = password;
        if (title != null) b.title = title;
        if (titleAr != null) b.titleAr = titleAr;
        if (permissions != null) b.permissions.replace(permissions.map((e) => AdminUpdateUserDtoPermissionsEnum.valueOf(e)));
      })
    );
    if (result == null) throw Exception('Failed to update user');

    await fetchUsers(
      page: state.value?.page ?? 1,
      limit: state.value?.limit ?? 20,
    );
  }

  Future<void> deleteUser(String id) async {
    final repository = ref.read(adminUsersRepositoryProvider);
    final result = await repository.deleteUser(id);
    if (result == null) throw Exception('Failed to delete user');
    await fetchUsers(
      page: state.value?.page ?? 1,
      limit: state.value?.limit ?? 20,
    );
  }

  Future<void> banUser(String id, {String? reason}) async {
    final repository = ref.read(adminUsersRepositoryProvider);
    await repository.banUser(id, reason ?? 'No reason provided');
    await fetchUsers(
      page: state.value?.page ?? 1,
      limit: state.value?.limit ?? 20,
    );
  }

  Future<void> unbanUser(String id) async {
    final repository = ref.read(adminUsersRepositoryProvider);
    await repository.unbanUser(id);
    await fetchUsers(
      page: state.value?.page ?? 1,
      limit: state.value?.limit ?? 20,
    );
  }
}

