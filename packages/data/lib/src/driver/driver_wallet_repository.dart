import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class DriverWalletRepository {
  final WalletFinancialsApi _api;
  final DriversApi _driversApi;
  DriverWalletRepository(this._api, this._driversApi);

  Future<dynamic> driverWalletGetBalance() async {
    final response = await _api.walletControllerGetMyDriverWallets();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> driverWalletGetTransactions() async {
    final response = await _api.walletControllerGetMyDriverTransactions();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getPlatformWallets() async {
    final response = await _api.walletControllerGetActivePlatformWallets();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getWalletBalance() async {
    final response = await _driversApi.driversControllerGetWalletBalance();
    return ResponseParser.parse(response);
  }

  Future<dynamic> getWalletTransactions() async {
    final response = await _driversApi.driversControllerGetWalletTransactions();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getMyDriverWallets() async {
    final response = await _api.walletControllerGetMyDriverWallets();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> addDriverWallet(String number, String type) async {
    final response = await _api.walletControllerAddDriverWallet(
      createMobileWalletDto: CreateMobileWalletDto((b) => b
        ..number = number
        ..type = CreateMobileWalletDtoTypeEnum.valueOf(type.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadReceipt(String imagePath) async {
    // We need to import dio for MultipartFile
    final file = await MultipartFile.fromFile(imagePath);
    final response = await _api.walletControllerUploadReceipt(file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> submitTopUpRequest(String platformWalletId, num amount, String receiptUrl) async {
    final response = await _api.walletControllerSubmitTopUpRequest(
      createWalletTopUpDto: CreateWalletTopUpDto((b) => b
        ..platformWalletId = platformWalletId
        ..amount = amount
        ..receiptUrl = receiptUrl
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMyTopUpRequests() async {
    final response = await _api.walletControllerGetMyTopUpRequests();
    return ResponseParser.parseList(response);
  }
}
