import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor/core/providers.dart';

typedef VendorProductSalesArgs = ({
  String vendorId,
  DateTime? from,
  DateTime? to,
  int page,
  int limit,
  String? search,
  String sortBy,
  String sortOrder,
});

/// Product-level sales and profit for a vendor. Uses the vendor statistics
/// repository (Dio-backed because the endpoint is newer than the generated API
/// client).
final vendorProductSalesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, VendorProductSalesArgs>(
        (ref, args) async {
  final repo = ref.watch(vendorStatisticsRepositoryProvider);
  final result = await repo.getVendorProductSales(
    args.vendorId,
    from: args.from,
    to: args.to,
    page: args.page,
    limit: args.limit,
    search: args.search,
    sortBy: args.sortBy,
    sortOrder: args.sortOrder,
  );

  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }
  return const {};
});
