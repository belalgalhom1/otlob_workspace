import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';

part 'driver_orders_history_provider.g.dart';

class DriverOrdersHistoryState {
  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final int page;
  final bool hasMore;
  final int totalCount;
  final String? error;

  const DriverOrdersHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.page = 1,
    this.hasMore = true,
    this.totalCount = 0,
    this.error,
  });

  DriverOrdersHistoryState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    int? page,
    bool? hasMore,
    int? totalCount,
    String? error,
  }) {
    return DriverOrdersHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class DriverOrdersHistory extends _$DriverOrdersHistory {
  static const int _limit = 20;

  @override
  DriverOrdersHistoryState build() {
    Future.microtask(() async {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      if (await authRepo.isLoggedIn()) {
        fetchDeliveries(isRefresh: true);
      }
    });
    return const DriverOrdersHistoryState(isLoading: false);
  }

  void clear() {
    state = const DriverOrdersHistoryState();
  }

  Future<void> fetchDeliveries({bool isRefresh = false}) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    if (!await authRepo.isLoggedIn()) {
      clear();
      return;
    }
    if (state.isLoading && !isRefresh) return;
    state = state.copyWith(
      isLoading: true,
      page: 1,
      error: null,
    );

    try {
      final repo = ref.read(driverOrdersRepositoryProvider);
      final response = await repo.getMyOrders(
        status: 'DELIVERED',
        page: 1,
        limit: _limit,
      );

      final rawList = response is Map
          ? (response['orders'] ?? response['data'] ?? response['items'] ?? [])
          : (response is List ? response : []);

      final totalCount = response is Map && response['total'] is num
          ? (response['total'] as num).toInt()
          : (rawList as List).length;

      final totalPages = response is Map && response['totalPages'] is num
          ? (response['totalPages'] as num).toInt()
          : 1;

      final List<Map<String, dynamic>> orders = (rawList as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        page: 1,
        totalCount: totalCount,
        hasMore: 1 < totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.fromError(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final repo = ref.read(driverOrdersRepositoryProvider);
      final response = await repo.getMyOrders(
        status: 'DELIVERED',
        page: nextPage,
        limit: _limit,
      );

      final rawList = response is Map
          ? (response['orders'] ?? response['data'] ?? response['items'] ?? [])
          : (response is List ? response : []);

      final totalPages = response is Map && response['totalPages'] is num
          ? (response['totalPages'] as num).toInt()
          : 1;

      final List<Map<String, dynamic>> newOrders = (rawList as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      state = state.copyWith(
        orders: [...state.orders, ...newOrders],
        page: nextPage,
        isLoadingMore: false,
        hasMore: nextPage < totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: ApiErrorMapper.fromError(e),
      );
    }
  }
}
