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
    Future.microtask(fetchAdministrativeUsers);
    return const AsyncValue.loading();
  }

  Future<void> fetchAdministrativeUsers() async {
    if (!ref.mounted) return;
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(adminUsersRepositoryProvider);
      
      // Fetch admins and super admins in parallel
      final results = await Future.wait([
        repository.getUsers(page: 1, limit: 100, role: 'ADMIN'),
        repository.getUsers(page: 1, limit: 100, role: 'SUPER_ADMIN'),
      ]);
      if (!ref.mounted) return;

      final adminResult = results[0];
      final superAdminResult = results[1];

      final admins = adminResult['users'] ?? adminResult['items'] ?? [];
      final superAdmins = superAdminResult['users'] ?? superAdminResult['items'] ?? [];

      state = AsyncValue.data(
        AccessControlStateData(
          adminUsers: admins,
          superAdminUsers: superAdmins,
        ),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
