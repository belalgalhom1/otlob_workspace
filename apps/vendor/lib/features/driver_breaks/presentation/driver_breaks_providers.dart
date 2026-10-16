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
    // Backend envelope can be `{data: [...]}` or paginated
    // `{drivers: [...], items: [...], breaks: [...]}`. Unwrap one level
    // (and a second level for double-wrapped `{data: {data: [...]}}`).
    for (final key in ['breaks', 'items', 'drivers', 'data', 'result']) {
      final value = raw[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (value is Map) {
        final nested = _asList(value);
        if (nested.isNotEmpty) return nested;
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
  final repo = ref.read(adminDriversRepositoryProvider);
  final trimmed = query.trim();
  final result = await repo.getDrivers(
    search: trimmed.isEmpty ? null : trimmed,
    limit: 30,
  );
  if (result is Map) {
    final rawList = result['drivers'] as List<dynamic>? ?? [];
    return rawList
        .whereType<Map>()
        .map((e) => DriverProfile.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList();
  }
  if (result is List) {
    return (result as List)
        .whereType<Map>()
        .map((e) => DriverProfile.fromJson(Map<String, dynamic>.from(e)))
        .where((d) => d.id.isNotEmpty)
        .toList();
  }
  return [];
});
