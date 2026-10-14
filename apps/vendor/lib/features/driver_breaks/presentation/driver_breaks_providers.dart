import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';

List<Map<String, dynamic>> _asList(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (raw is Map) {
    for (final key in ['breaks', 'items', 'data']) {
      final value = raw[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
  }
  return [];
}

final pendingBreaksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(driverBreaksRepositoryProvider);
  return _asList(await repo.getPendingBreaks());
});

final driverBreaksHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, driverId) async {
  if (driverId.isEmpty) return [];
  final repo = ref.read(driverBreaksRepositoryProvider);
  return _asList(await repo.getDriverBreaks(driverId));
});

final driverBreakSearchProvider =
    FutureProvider.family<List<DriverProfile>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.read(adminDriversRepositoryProvider);
  final result = await repo.getDrivers(search: query.trim());
  if (result is Map) {
    final rawList = result['drivers'] as List<dynamic>? ?? [];
    return rawList
        .whereType<Map>()
        .map((e) => DriverProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  return [];
});
