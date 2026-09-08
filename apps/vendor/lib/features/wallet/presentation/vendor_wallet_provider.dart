import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';

part 'vendor_wallet_provider.g.dart';

@riverpod
class VendorWalletData extends _$VendorWalletData {
  @override
  Future<Map<String, dynamic>> build() async {
    final activeVendor = ref.watch(activeVendorProvider);
    if (activeVendor == null) return {};

    final vendorId = activeVendor;
    final repo = ref.watch(vendorWalletRepositoryProvider);

    final balanceData = await repo.vendorWalletGetBalance(vendorId);
    final transactionsRes = await repo.vendorWalletGetTransactions(vendorId);

    List<dynamic> txList = [];
    if (transactionsRes is List) {
      txList = transactionsRes;
    } else if (transactionsRes is Map) {
      if (transactionsRes['data'] is List) {
        txList = transactionsRes['data'] as List<dynamic>;
      } else if (transactionsRes['transactions'] is List) {
        txList = transactionsRes['transactions'] as List<dynamic>;
      }
    }

    return {
      'balance': balanceData is Map ? balanceData : {'walletBalance': balanceData},
      'transactions': txList,
    };
  }
}
