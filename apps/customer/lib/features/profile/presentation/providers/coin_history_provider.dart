import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart' show customerLoyaltyRepositoryProvider;
import '../../../auth/presentation/providers/auth_controller.dart';

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
    bool clearError = false,
  }) {
    return CoinHistoryState(
      transactions: transactions ?? this.transactions,
      currentBalance: currentBalance ?? this.currentBalance,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@Riverpod(keepAlive: true)
class CoinHistory extends _$CoinHistory {
  @override
  CoinHistoryState build() {
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.authenticated) {
        _fetchHistory();
      } else if (next == AuthStatus.unauthenticated) {
        state = CoinHistoryState();
      }
    });

    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(() => _fetchHistory());
      return CoinHistoryState(isLoading: true);
    }

    return CoinHistoryState(isLoading: false);
  }

  Future<void> _fetchHistory() async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus != AuthStatus.authenticated) {
      state = CoinHistoryState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(customerLoyaltyRepositoryProvider);
      final data = await repo.getCoinHistory(page: 1, limit: 100);
      if (!ref.mounted) return;

      if (data is Map) {
        final rawTxs = data['transactions'];
        state = state.copyWith(
          transactions: rawTxs is List
              ? rawTxs
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : const [],
          currentBalance: (data['currentBalance'] as num?)?.toInt() ?? 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.authenticated) {
      await _fetchHistory();
    }
  }
}
