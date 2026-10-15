import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

class BreaksOverview {
  final Map<String, dynamic>? active;
  final Map<String, dynamic>? pending;
  final List<Map<String, dynamic>> recent;

  const BreaksOverview({
    this.active,
    this.pending,
    this.recent = const [],
  });
}

List<Map<String, dynamic>> _asBreakList(dynamic raw) {
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

Future<dynamic> _safeBreakCall(Future<dynamic> Function() call) async {
  try {
    return await call();
  } catch (_) {
    return null;
  }
}

final breaksOverviewProvider = FutureProvider<BreaksOverview>((ref) async {
  final repo = ref.read(driverBreaksRepositoryProvider);
  final results = await Future.wait([
    _safeBreakCall(() => repo.getActiveBreak()),
    _safeBreakCall(() => repo.getMyBreaks()),
  ]);

  final activeRaw = results[0];
  final active =
      activeRaw is Map ? Map<String, dynamic>.from(activeRaw) : null;
  final recent = _asBreakList(results[1]);

  Map<String, dynamic>? pending;
  for (final item in recent) {
    if ((item['status']?.toString() ?? '') == 'PENDING') {
      pending = item;
      break;
    }
  }

  return BreaksOverview(active: active, pending: pending, recent: recent);
});

class BreakActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> _refresh() async {
    ref.invalidate(breaksOverviewProvider);
    try {
      await ref.read(breaksOverviewProvider.future);
    } catch (_) {}
  }

  Future<void> start({
    String? reason,
    String? note,
    int? requestedMinutes,
  }) async {
    final repo = ref.read(driverBreaksRepositoryProvider);
    await repo.startBreak(
      reason: reason,
      note: note,
      requestedMinutes: requestedMinutes,
    );
    await _refresh();
  }

  Future<void> end() async {
    final repo = ref.read(driverBreaksRepositoryProvider);
    await repo.endBreak();
    await _refresh();
    try {
      await ref.read(driverProfileProvider.notifier).fetchProfile();
    } catch (_) {}
  }

  Future<void> cancel() async {
    final repo = ref.read(driverBreaksRepositoryProvider);
    await repo.cancelBreakRequest();
    await _refresh();
  }
}

final breakActionsProvider =
    AsyncNotifierProvider<BreakActions, void>(BreakActions.new);
