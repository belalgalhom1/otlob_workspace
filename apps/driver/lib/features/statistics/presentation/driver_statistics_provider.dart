import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/providers.dart';

final driverStatsProvider = FutureProvider.family<List<dynamic>,
    ({String? period, DateTime? from, DateTime? to})>((ref, args) async {
  final repo = ref.watch(driverStatisticsRepositoryProvider);
  final result = await repo.getMyDriverStats(
    period: args.period,
    limit: 365,
    from: args.from,
    to: args.to,
  );
  return result is List ? result : const [];
});