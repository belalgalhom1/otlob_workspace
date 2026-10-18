import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';

part 'shifts_provider.g.dart';

@riverpod
class DriverShifts extends _$DriverShifts {
  @override
  AsyncValue<List<dynamic>> build() {
    _fetchMyShifts();
    return const AsyncValue.loading();
  }

  Future<void> _fetchMyShifts() async {
    try {
      final repository = ref.read(driverShiftsRepositoryProvider);
      final response = await repository.getMyShifts();
      state = AsyncValue.data(response is List ? response : (response?['data'] as List<dynamic>? ?? []));
    } catch (e, st) {
      try {
        state = AsyncValue.error(e, st);
      } catch (_) {
        // Ignore StateError if provider was disposed
      }
    }
  }

  /// Starts a shift with the mandatory selfie + current coordinates.
  /// On success the backend flips the driver ONLINE and the profile is
  /// refreshed so tracking starts; errors restore the previous list state
  /// and are rethrown for the UI to display.
  Future<void> startShift(
    String shiftId, {
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    final prev = state;
    try {
      final repository = ref.read(driverShiftsRepositoryProvider);
      if (photoPath != null) {
        await repository.startShiftWithPhoto(
          shiftId: shiftId,
          photoPath: photoPath,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await repository.startShift(shiftId);
      }
      await _fetchMyShifts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) state = prev;
      rethrow;
    }
  }

  Future<void> endShift(String shiftId) async {
    final prev = state;
    try {
      final repository = ref.read(driverShiftsRepositoryProvider);
      await repository.endShift(shiftId);
      await _fetchMyShifts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) state = prev;
      rethrow;
    }
  }

  Future<void> deleteShift(String shiftId) async {
    final prev = state;
    try {
      await ref.read(dioProvider).delete('/drivers/me/shifts/$shiftId');
      await _fetchMyShifts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) state = prev;
      rethrow;
    }
  }

  Future<void> offerSwap(String shiftId, String reason) async {
    try {
      final repository = ref.read(driverShiftsRepositoryProvider);
      await repository.offerSwap(shiftId, reason);
      await _fetchMyShifts();
      ref.invalidate(swapBoardProvider);
    } catch (e) {
      // Ignore or log error to avoid unhandled exception crash
    }
  }
}

@riverpod
class AvailablePools extends _$AvailablePools {
  @override
  Future<List<dynamic>> build(String zoneId) async {
    final repository = ref.read(driverShiftsRepositoryProvider);
    final response = await repository.getAvailablePools(zoneId);
    return response is List ? response : (response?['data'] as List<dynamic>? ?? []);
  }

  Future<void> bookWeeklyShifts(List<String> poolIds) async {
    final repository = ref.read(driverShiftsRepositoryProvider);
    await repository.bookWeeklyShifts(poolIds);
    ref.invalidate(driverShiftsProvider);
    ref.invalidateSelf();
  }

  Future<void> bookOvertimeShift(String poolId) async {
    final repository = ref.read(driverShiftsRepositoryProvider);
    await repository.bookOvertimeShift(poolId);
    ref.invalidate(driverShiftsProvider);
    ref.invalidateSelf();
  }
}

@riverpod
class SwapBoard extends _$SwapBoard {
  @override
  Future<List<dynamic>> build() async {
    final repository = ref.read(driverShiftsRepositoryProvider);
    final response = await repository.getSwapBoard();
    return response is List ? response : (response?['data'] as List<dynamic>? ?? []);
  }

  Future<void> acceptSwap(String swapId) async {
    final repository = ref.read(driverShiftsRepositoryProvider);
    await repository.acceptSwap(swapId);
    ref.invalidate(driverShiftsProvider);
    ref.invalidateSelf();
  }
}
