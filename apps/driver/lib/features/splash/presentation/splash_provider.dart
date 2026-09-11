import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';

part 'splash_provider.g.dart';

enum AppStartupState {
  loading,
  unauthenticated,
  suspended,
  dashboard,
  activeOrder,
}

@Riverpod(keepAlive: true)
class Splash extends _$Splash {
  @override
  Future<AppStartupState> build() async {
    return _initialize();
  }

  Future<AppStartupState> _initialize() async {
    try {
      final authRepository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await authRepository.isLoggedIn();
      
      if (!isLoggedIn) {
        return AppStartupState.unauthenticated;
      }

      final role = await authRepository.getUserRole();
      if (role != 'DRIVER') {
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }

      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final profile = await driverRepo.getMyProfile();
      if (profile == null || profile['isApproved'] != true) {
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }
      
      if (profile['status'] == 'SUSPENDED') {
        return AppStartupState.suspended;
      }

      // Initialize SocketService but only auto-connect if driver is online
      final bool shouldConnect = profile['status'] != 'OFFLINE' && profile['status'] != 'SUSPENDED';
      await ref.read(coreSocketServiceProvider).init(autoConnect: shouldConnect);

      // Initialize Push Notifications and register FCM token
      Future(() async {
        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.initialize();
          await pushService.subscribeToRoleTopics('DRIVER');
        } catch (e) {
          // Gracefully ignore on platforms/environments without FCM
        }
      });

      // Query for an active order
      final ordersRepo = ref.read(driverOrdersRepositoryProvider);
      final activeOrderResult = await ordersRepo.getActiveDriverOrder();
      
      // The repository resolves to {'data': null} when no order is active,
      // so an empty map must not be treated as an active order.
      if (activeOrderResult != null && activeOrderResult['data'] != null) {
        // We have an active order
        return AppStartupState.activeOrder;
      }

      return AppStartupState.dashboard;
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('PROFILE_NOT_FOUND')) {
        final authRepository = ref.read(sharedAuthRepositoryProvider);
        await authRepository.logout();
        return AppStartupState.unauthenticated;
      }
      
      // If network fails, but we have token, we might want to just go to dashboard and let it show offline
      // For now, if we can't fetch profile, fallback to unauth or dashboard depending on token
      final authRepository = ref.read(sharedAuthRepositoryProvider);
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) return AppStartupState.dashboard;
      return AppStartupState.unauthenticated;
    }
  }
}
