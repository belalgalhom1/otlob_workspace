import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';

part 'wallet_provider.g.dart';

@riverpod
class DriverWallet extends _$DriverWallet {
  @override
  AsyncValue<Map<String, dynamic>> build() {
    _fetchWalletData();
    return const AsyncValue.loading();
  }

  Future<void> _fetchWalletData() async {
    try {
      final repository = ref.read(driverWalletRepositoryProvider);
      final balanceResponse = await repository.getWalletBalance();
      final txResponse = await repository.getWalletTransactions();
      final platformWallets = await repository.getPlatformWallets();
      final driverWallets = await repository.getMyDriverWallets();
      final topUpRequests = await repository.getMyTopUpRequests();

      num parsedBalance = 0.0;
      if (balanceResponse is num) {
        parsedBalance = balanceResponse;
      } else if (balanceResponse is Map) {
        final innerData = balanceResponse['data'];
        if (innerData is num) {
          parsedBalance = innerData;
        } else if (innerData is Map) {
          parsedBalance = innerData['balance'] ?? innerData['walletBalance'] ?? 0.0;
        } else {
          parsedBalance = balanceResponse['balance'] ?? balanceResponse['walletBalance'] ?? 0.0;
        }
      }

      try {
        state = AsyncValue.data({
          'balance': parsedBalance,
          'transactions': txResponse is List ? txResponse : (txResponse?['data'] ?? []),
          'platformWallets': platformWallets is List ? platformWallets : (platformWallets?['data'] ?? []),
          'driverWallets': driverWallets is List ? driverWallets : (driverWallets?['data'] ?? []),
          'topUpRequests': topUpRequests is List ? topUpRequests : (topUpRequests?['data'] ?? []),
        });
      } catch (_) {
        // Provider was disposed, ignore
      }
    } catch (e, st) {
      try {
        state = AsyncValue.error(e, st);
      } catch (_) {
        // Provider was disposed, ignore
      }
    }
  }

  Future<void> requestTopUp({required String platformWalletId, required double amount, required String imagePath}) async {
    final prev = state;
    try {
      final repository = ref.read(driverWalletRepositoryProvider);
      
      // 1. Upload receipt
      final uploadRes = await repository.uploadReceipt(imagePath);
      final receiptUrl = uploadRes['data']['url']; // Assuming backend returns the URL in data.url
      
      // 2. Submit top-up
      await repository.submitTopUpRequest(platformWalletId, amount, receiptUrl);
      
      await _fetchWalletData();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) {
        state = prev;
      }
    }
  }

  Future<void> addDriverWallet(String number, String type) async {
    final prev = state;
    try {
      final repository = ref.read(driverWalletRepositoryProvider);
      await repository.addDriverWallet(number, type);
      await _fetchWalletData();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (prev.hasValue) {
        state = prev;
      }
    }
  }
}
