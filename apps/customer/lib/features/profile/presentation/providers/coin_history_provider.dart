import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';

part 'coin_history_provider.g.dart';

class CoinHistoryState {
  final List<Map<String, dynamic>> transactions;
  final int currentBalance;
  final bool isLoading;
  final String? error;

  CoinHistoryState({
    this.transactions = const [],
    this.currentBalance = 0,
    this.isLoading = false,
    this.error,
  });

  CoinHistoryState copyWith({
    List<Map<String, dynamic>>? transactions,
    int? currentBalance,
    bool? isLoading,
    String? error,
  }) {
    return CoinHistoryState(
      transactions: transactions ?? this.transactions,
      currentBalance: currentBalance ?? this.currentBalance,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class CoinHistory extends _$CoinHistory {
  @override
  CoinHistoryState build() {
    Future.microtask(() => _fetchHistory());
    return CoinHistoryState(isLoading: true);
  }

  Future<void> _fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/customers/me/coins/history?page=1&limit=100');
      
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        state = state.copyWith(
          transactions: List<Map<String, dynamic>>.from(data['transactions'] ?? []),
          currentBalance: data['currentBalance'] ?? 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _fetchHistory();
  }
}
