import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';

part 'access_control_provider.g.dart';

class AccessControlStateData {
  final List<dynamic> adminUsers;
  final List<dynamic> superAdminUsers;

  AccessControlStateData({
    this.adminUsers = const [],
    this.superAdminUsers = const [],
  });
}

@riverpod
class AccessControlNotifier extends _$AccessControlNotifier {
  @override
  AsyncValue<AccessControlStateData> build() {
    fetchAdministrativeUsers();
    return const AsyncValue.loading();
  }

  Future<void> fetchAdministrativeUsers() async {
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(adminUsersRepositoryProvider);
      
      // Fetch admins (limit 100 for matrix display)
      final adminResult = await repository.getUsers(
        page: 1,
        limit: 100,
        role: 'ADMIN',
      );
      
      // Fetch super admins
      final superAdminResult = await repository.getUsers(
        page: 1,
        limit: 100,
        role: 'SUPER_ADMIN',
      );

      final admins = adminResult['users'] ?? adminResult['items'] ?? [];
      final superAdmins = superAdminResult['users'] ?? superAdminResult['items'] ?? [];

      state = AsyncValue.data(
        AccessControlStateData(
          adminUsers: admins,
          superAdminUsers: superAdmins,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
