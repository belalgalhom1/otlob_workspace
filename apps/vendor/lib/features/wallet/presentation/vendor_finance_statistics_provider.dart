import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor/core/providers.dart';

final vendorFinanceStatsProvider = FutureProvider.family<List<dynamic>,
    ({String? vendorId, String? period, DateTime? from, DateTime? to})>(
    (ref, args) async {
  final vendorId = args.vendorId ?? ref.watch(activeVendorProvider);
  if (vendorId == null) return const [];

  final repo = ref.watch(vendorStatisticsRepositoryProvider);
  final result = await repo.getVendorStats(
    vendorId,
    period: args.period,
    limit: 365,
    from: args.from,
    to: args.to,
  );
  return result is List ? result : const [];
});