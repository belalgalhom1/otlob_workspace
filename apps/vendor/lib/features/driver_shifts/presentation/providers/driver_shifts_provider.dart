import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';

part 'driver_shifts_provider.g.dart';

@riverpod
class ShiftPools extends _$ShiftPools {
  String? _startDate;
  String? _endDate;
  String? _zoneId;

  @override
  Future<List<ShiftPool>> build() async {
    return _fetch();
  }

  Future<List<ShiftPool>> _fetch() async {
    final dio = ref.read(dioProvider);
    final queryParams = <String, dynamic>{};
    if (_startDate != null) queryParams['startDate'] = _startDate;
    if (_endDate != null) queryParams['endDate'] = _endDate;
    if (_zoneId != null) queryParams['zoneId'] = _zoneId;

    final response = await dio.get('/driver-shifts/admin/pools', queryParameters: queryParams);
    final raw = response.data is Map ? response.data['data'] : response.data;
    final list = raw is List
        ? raw
        : (raw is Map && raw['items'] is List ? raw['items'] as List : null);
    if (list != null) {
      return list.map((e) => ShiftPool.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> filter({String? startDate, String? endDate, String? zoneId}) async {
    _startDate = startDate;
    _endDate = endDate;
    _zoneId = zoneId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> generateShiftPools(GenerateShiftPoolsRequest request) async {
    final dio = ref.read(dioProvider);
    await dio.post('/driver-shifts/admin/pools', data: request.toJson());
    await refresh();
  }

  Future<bool> deleteShiftPool(String poolId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.delete('/driver-shifts/admin/pools/$poolId');
    final data = response.data is Map ? response.data as Map : null;
    final deleted = data?['deleted'] as bool? ?? true;
    await refresh();
    return deleted;
  }

  Future<void> removeDriverFromShift(String shiftId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/driver-shifts/admin/shifts/$shiftId');
    await refresh();
  }

  Future<void> removeAllDriversFromPool(String poolId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/driver-shifts/admin/pools/$poolId/drivers');
    await refresh();
  }

  Future<void> assignDriver(AdminAssignShiftRequest request) async {
    final dio = ref.read(dioProvider);
    await dio.post('/driver-shifts/admin/assign', data: request.toJson());
    await refresh();
  }

  Future<void> bookWeeklyShiftsForDriver(String driverId, List<String> poolIds) async {
    final dio = ref.read(dioProvider);
    await dio.post('/driver-shifts/admin/book-week', data: {
      'driverId': driverId,
      'shiftPoolIds': poolIds,
    });
    await refresh();
  }
}
