import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor/core/providers.dart';

final adminDriverStatsProvider = FutureProvider.family<List<dynamic>,
    ({String driverId, String? period, DateTime? from, DateTime? to})>(
    (ref, args) async {
  final repo = ref.watch(adminStatisticsRepositoryProvider);
  final result = await repo.statisticsGetDriverStats(
    driverId: args.driverId,
    period: args.period,
    limit: 365,
    from: args.from,
    to: args.to,
  );
  return result is List ? result : const [];
});

/// Combined statistics + per-driver breakdown for every driver the signed-in
/// manager is responsible for. Super admins receive the whole fleet.
///
/// [limit] is the number of buckets to look back when no explicit range is
/// supplied. Keep it small per period (e.g. 30 days / 12 weeks / 12 months):
/// the backend multiplies it by the bucket length.
final allManagedDriversStatsProvider = FutureProvider.family<Map<String, dynamic>,
    ({String period, int limit, DateTime? from, DateTime? to})>(
  (ref, args) async {
    final repo = ref.watch(adminStatisticsRepositoryProvider);
    final result = await repo.getAllManagedDriverStats(
      period: args.period,
      limit: args.limit,
      from: args.from,
      to: args.to,
    );
    return result is Map
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{};
  },
);