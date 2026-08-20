import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminVendorWalletRepository {
  final VendorsWalletTransactionsApi _api;
  AdminVendorWalletRepository(this._api);

  Future<dynamic> vendorWalletAdminListTransactions(String vendorId) async {
    final response = await _api.vendorWalletControllerAdminListTransactions(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> vendorWalletAdminGetBalance(String vendorId) async {
    final response = await _api.vendorWalletControllerAdminGetBalance(vendorId: vendorId);
    return ResponseParser.parse(response);
  }
}
