import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminWalletRepository {
  final WalletFinancialsApi _api;
  AdminWalletRepository(this._api);

  Future<dynamic> walletGetMyTopUpRequests() async {
    final response = await _api.walletControllerGetMyTopUpRequests();
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletCreatePlatformWallet({required CreateMobileWalletDto createMobileWalletDto}) async {
    final response = await _api.walletControllerCreatePlatformWallet(createMobileWalletDto: createMobileWalletDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletProcessVendorTransaction({required String vendorId, required ProcessManualTransactionDto processManualTransactionDto}) async {
    final response = await _api.walletControllerProcessVendorTransaction(vendorId: vendorId, processManualTransactionDto: processManualTransactionDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletUpdatePlatformWallet({required String id}) async {
    final response = await _api.walletControllerUpdatePlatformWallet(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletProcessDriverTransaction({required String driverId, required ProcessManualTransactionDto processManualTransactionDto}) async {
    final response = await _api.walletControllerProcessDriverTransaction(driverId: driverId, processManualTransactionDto: processManualTransactionDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletGetPendingTopUps() async {
    final response = await _api.walletControllerGetPendingTopUps();
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletSubmitTopUpRequest({required CreateWalletTopUpDto createWalletTopUpDto}) async {
    final response = await _api.walletControllerSubmitTopUpRequest(createWalletTopUpDto: createWalletTopUpDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletReviewTopUp({required String id, required ReviewWalletTopUpDto reviewWalletTopUpDto}) async {
    final response = await _api.walletControllerReviewTopUp(id: id, reviewWalletTopUpDto: reviewWalletTopUpDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> walletGetAllPlatformWallets() async {
    final response = await _api.walletControllerGetAllPlatformWallets();
    return ResponseParser.parse(response);
  }

  Future<dynamic> addDriverWallet(CreateMobileWalletDto dto) async {
    final response = await _api.walletControllerAddDriverWallet(createMobileWalletDto: dto);
    return ResponseParser.parse(response);
  }
}
