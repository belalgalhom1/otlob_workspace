import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers.dart';
import 'package:data/data.dart';
import 'driver_models.dart';
import 'package:core/core.dart';
part 'driver_providers.g.dart';

class DriversState {
  final List<DriverProfile> drivers;
  final int total;
  final int page;
  final bool isLoading;
  final bool hasMore;

  DriversState({
    this.drivers = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = true,
    this.hasMore = true,
  });

  DriversState copyWith({
    List<DriverProfile>? drivers,
    int? total,
    int? page,
    bool? isLoading,
    bool? hasMore,
  }) {
    return DriversState(
      drivers: drivers ?? this.drivers,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

@riverpod
class DriversNotifier extends _$DriversNotifier {
  String? _search;
  String? _status;
  String? _zoneId;

  @override
  FutureOr<DriversState> build() async {
    return _fetchDrivers(page: 1);
  }

  Future<DriversState> _fetchDrivers({required int page}) async {
    final repo = ref.watch(adminDriversRepositoryProvider);
    final result = await repo.getDrivers(page: page, status: _status, search: _search, zoneId: _zoneId);
    
    List<DriverProfile> items = [];
    int total = 0;
    
    if (result is Map) {
      final rawList = result['drivers'] as List<dynamic>? ?? [];
      items = rawList.map((e) => DriverProfile.fromJson(e)).toList();
      total = result['total'] ?? 0;
    } else if (result is List) {
      items = result.map((e) => DriverProfile.fromJson(e)).toList();
      total = items.length;
    }

    return DriversState(
      drivers: items,
      total: total,
      page: page,
      isLoading: false,
      hasMore: items.length >= 20,
    );
  }

  Future<void> loadMore() async {
    if (state.value == null || state.value!.isLoading == true || state.value!.hasMore == false) return;

    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final nextPage = state.value!.page + 1;
      final newState = await _fetchDrivers(page: nextPage);
      state = AsyncData(
        state.value!.copyWith(
          drivers: [...state.value!.drivers, ...newState.drivers],
          page: newState.page,
          total: newState.total,
          isLoading: false,
          hasMore: newState.hasMore,
        ),
      );
    } catch (e, stack) {
      state = AsyncError(ApiErrorMapper.fromError(e), stack);
    }
  }

  Future<void> filter({String? search, String? status, String? zoneId}) async {
    _search = search;
    _status = status;
    _zoneId = zoneId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDrivers(page: 1));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDrivers(page: 1));
  }

  Future<void> createDriver(Map<String, dynamic> data) async {
    final repo = ref.read(adminDriversRepositoryProvider);
    await repo.driversAdminCreate(data: data);
    await refresh();
  }

  Future<void> updateDriver(String driverId, Map<String, dynamic> data) async {
    final repo = ref.read(adminDriversRepositoryProvider);
    await repo.driversAdminUpdate(driverId: driverId, data: data);
    await refresh();
  }

  Future<void> suspendDriver(String driverId) async {
    final repo = ref.read(adminDriversRepositoryProvider);
    await repo.driversAdminSuspend(driverId: driverId);
    await refresh();
  }

  Future<void> unsuspendDriver(String driverId) async {
    final repo = ref.read(adminDriversRepositoryProvider);
    await repo.driversAdminUnsuspend(driverId: driverId);
    await refresh();
  }
}
