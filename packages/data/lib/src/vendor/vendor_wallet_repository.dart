import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorWalletRepository {
  final VendorsWalletTransactionsApi _api;
  final WalletFinancialsApi _walletApi;
  VendorWalletRepository(this._api, this._walletApi);

  Future<dynamic> vendorWalletGetBalance(String vendorId) async {
    final response = await _api.vendorWalletControllerGetBalance(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> vendorWalletGetTransactions(String vendorId) async {
    final response = await _api.vendorWalletControllerListTransactions(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> uploadReceipt(MultipartFile file) async {
    final response = await _walletApi.walletControllerUploadReceipt(file: file);
    return ResponseParser.parse(response);
  }
}
