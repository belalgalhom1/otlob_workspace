import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsRepository(dio);
});

final topDriversProvider = FutureProvider.autoDispose<List<AnalyticsDriver>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTopDrivers(limit: 20);
});

final topCustomersProvider = FutureProvider.autoDispose<List<AnalyticsCustomer>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTopCustomers(limit: 20);
});

final topVendorsProvider = FutureProvider.autoDispose<List<AnalyticsVendor>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTopVendors(limit: 20);
});

final topProductsProvider = FutureProvider.autoDispose<List<AnalyticsTopProduct>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTopProducts(limit: 20);
});
