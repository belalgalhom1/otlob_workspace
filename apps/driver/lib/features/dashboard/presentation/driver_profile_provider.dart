import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:core/core.dart';

part 'driver_profile_provider.g.dart';

@riverpod
class DriverProfile extends _$DriverProfile {
  @override
  AsyncValue<dynamic> build() {
    Future.microtask(() => fetchProfile());
    return const AsyncValue.loading();
  }

  Future<void> fetchProfile() async {
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    // Fresh-login cold starts can hit transient network/HTTP failures that a
    // single retry misses. Loop with backoff so the first-open load self-heals
    // the same way a faster restart would.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final repository = ref.read(driverProfileRepositoryProvider);
        final response = await repository.getMyProfile();

        final data = response is Map && response.containsKey('data') && response['data'] is Map
            ? response['data']
            : (response ?? {});

        final currentStatus = data['status'];
        if (currentStatus == 'ONLINE' || currentStatus == 'ON_DELIVERY') {
          ref.read(locationServiceProvider).startTracking();
          ref.read(coreSocketServiceProvider).connect();
        } else if (currentStatus == 'OFFLINE') {
          ref.read(locationServiceProvider).stopTracking();
          ref.read(coreSocketServiceProvider).disconnect();
        }

        state = AsyncValue.data(response);
        return;
      } catch (e, st) {
        if (e.toString().contains('404') || e.toString().contains('PROFILE_NOT_FOUND')) {
          // Explicitly set state to null so the UI knows profile is pending creation
          state = const AsyncValue.data(null);
          return;
        }

        if (ErrorUtils.isAuthSessionError(e)) {
          // A guard-level 401/403 that survives the interceptor's refresh cycle
          // means the session is genuinely dead — retrying can only re-401.
          // Bounce to login instead of leaving a dead dashboard with an
          // "Unauthorized" error card.
          debugPrint('Profile fetch hit a dead session; forcing re-login: $e');
          if (ref.mounted) {
            try {
              await ref.read(authProvider.notifier).logout();
            } catch (logoutErr) {
              debugPrint('Logout on dead session failed: $logoutErr');
            }
          }
          return;
        }

        debugPrint('Profile fetch attempt $attempt/$maxAttempts failed: $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt));
          if (!ref.mounted) return;
          continue;
        }

        // Exhausted all attempts. Surface the error only when we have no data
        // to show; otherwise keep the stale value and let the user retry.
        if (!state.hasValue) {
          state = AsyncValue.error(e, st);
        }
      }
    }
  }

  Future<void> updateStatus(String status) async {
    final prev = state;
    try {
      final repository = ref.read(driverProfileRepositoryProvider);
      await repository.updateStatus(status);
      await fetchProfile();
      
      if (status == 'ONLINE' || status == 'ON_DELIVERY') {
        ref.read(coreSocketServiceProvider).connect();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) {
        state = prev;
      }
    }
  }

  Future<void> uploadAvatar(String imagePath) async {
    final prev = state;
    try {
      final repository = ref.read(driverProfileRepositoryProvider);
      final file = await MultipartFile.fromFile(imagePath);
      await repository.uploadAvatar(file);
      await fetchProfile();
    } catch (e) {
      if (prev.hasValue) {
        state = prev;
      }
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> registerDriver({
    required String name,
  }) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final dto = RegisterDriverDto((b) {
        b.name = name;
      });
      await driverRepo.registerDriver(dto);
      await fetchProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) {
        state = prev;
      }
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? nationalId,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final dto = UpdateDriverProfileDto((b) {
        if (name != null) b.name = name;
        if (nationalId != null) b.nationalId = nationalId;
        if (licenseNumber != null) b.licenseNumber = licenseNumber;
        if (vehicleType != null) {
          b.vehicleType = UpdateDriverProfileDtoVehicleTypeEnum.valueOf(vehicleType);
        }
        if (vehiclePlate != null) b.vehiclePlate = vehiclePlate;
      });
      await driverRepo.updateProfile(dto);
      await fetchProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) {
        state = prev;
      }
      throw ApiErrorMapper.fromError(e);
    }
  }
}
