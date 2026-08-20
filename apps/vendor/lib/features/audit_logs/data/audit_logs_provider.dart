import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';
part 'audit_logs_provider.g.dart';

class AuditLogsState {
  final List<dynamic> logs;
  final int total;
  final int page;
  final bool isLoading;
  final bool hasMore;

  AuditLogsState({
    this.logs = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = true,
    this.hasMore = true,
  });

  AuditLogsState copyWith({
    List<dynamic>? logs,
    int? total,
    int? page,
    bool? isLoading,
    bool? hasMore,
  }) {
    return AuditLogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

@riverpod
class AuditLogs extends _$AuditLogs {
  String? _actionType;
  String? _entityType;
  String? _userId;

  @override
  FutureOr<AuditLogsState> build() async {
    return _fetchLogs(page: 1);
  }

  Future<AuditLogsState> _fetchLogs({required int page}) async {
    final repo = ref.watch(adminAuditLogsRepositoryProvider);
    final resultMap = await repo.getAuditLogs(page: page);
    final resultList = resultMap['data'] as List<dynamic>? ?? [];
    final meta = resultMap['meta'] as Map<dynamic, dynamic>? ?? {};

    // Simple mapping to adapt to the state
    return AuditLogsState(
      logs: resultList,
      total: meta['total'] as int? ?? resultList.length,
      page: meta['page'] as int? ?? 1,
      isLoading: false,
      hasMore: (meta['page'] as int? ?? 1) < (meta['totalPages'] as int? ?? 1),
    );
  }

  Future<void> loadMore() async {
    if (state.value?.isLoading == true || state.value?.hasMore == false) return;

    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final nextPage = state.value!.page + 1;
      final newState = await _fetchLogs(page: nextPage);
      state = AsyncData(
        state.value!.copyWith(
          logs: [...state.value!.logs, ...newState.logs],
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

  Future<void> filter({
    String? actionType,
    String? entityType,
    String? userId,
  }) async {
    _actionType = actionType;
    _entityType = entityType;
    _userId = userId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLogs(page: 1));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLogs(page: 1));
  }
}


