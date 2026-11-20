import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverRankingSummaryProvider =
    FutureProvider.autoDispose<DriverMyRankSummaryResponseDto>((ref) async {
      final repository = ref.watch(driverRankingRepositoryProvider);
      return repository.getMyRankSummary();
    });
