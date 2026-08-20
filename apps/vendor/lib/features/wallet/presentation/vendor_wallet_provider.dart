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
    final transactions = await repo.vendorWalletGetTransactions(vendorId);
    
    return {
      'balance': balanceData,
      'transactions': transactions is List ? transactions : [],
    };
  }
}
