import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:driver/core/services/location_service.dart';
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
    } catch (e, st) {
      if (e.toString().contains('404') || e.toString().contains('PROFILE_NOT_FOUND')) {
        // Explicitly set state to null so the UI knows profile is pending creation
        state = const AsyncValue.data(null);
      } else {
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
  }) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      final driverRepo = ref.read(driverProfileRepositoryProvider);
      final dto = UpdateDriverProfileDto((b) {
        if (name != null) b.name = name;
        if (nationalId != null) b.nationalId = nationalId;
        if (licenseNumber != null) b.licenseNumber = licenseNumber;
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
