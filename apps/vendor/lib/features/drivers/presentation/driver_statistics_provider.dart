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