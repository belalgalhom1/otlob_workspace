import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorWalletRepository {
  final VendorsWalletTransactionsApi _api;
  final WalletFinancialsApi _walletApi;
  final Dio? _dio;

  VendorWalletRepository(this._api, this._walletApi, {Dio? dio})
      : _dio = dio;

  Future<dynamic> vendorWalletGetBalance(String vendorId) async {
    final response = await _api.vendorWalletControllerGetBalance(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  /// Paginated transactions. When no filters are given the generated client
  /// is used; with filters/dio available we call the endpoint directly so the
  /// query parameters are explicit.
  Future<dynamic> vendorWalletGetTransactions(
    String vendorId, {
    String? type,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final dio = _dio;
    if (dio != null) {
      final response = await dio.get<dynamic>(
        '/vendors/$vendorId/wallet/transactions',
        queryParameters: {
          'type': ?type,
          'from': ?from,
          'to': ?to,
          'page': page,
          'limit': limit,
        },
      );
      return _unwrap(response.data);
    }
    final response = await _api.vendorWalletControllerListTransactions(
      vendorId: vendorId,
      type: type,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
    return ResponseParser.parseList(response);
  }

  /// Aggregated totals for the active filters. The endpoint is newer than the
  /// generated client, so it is called through Dio.
  Future<dynamic> vendorWalletGetSummary(
    String vendorId, {
    String? type,
    String? from,
    String? to,
  }) async {
    final dio = _dio;
    if (dio == null) return null;
    final response = await dio.get<dynamic>(
      '/vendors/$vendorId/wallet/summary',
      queryParameters: {
        'type': ?type,
        'from': ?from,
        'to': ?to,
      },
    );
    return _unwrap(response.data);
  }

  Future<dynamic> uploadReceipt(MultipartFile file) async {
    final response = await _walletApi.walletControllerUploadReceipt(file: file);
    return ResponseParser.parse(response);
  }

  static dynamic _unwrap(dynamic data) {
    if (data is Map && data['success'] != null && data['data'] != null) {
      return data['data'];
    }
    return data;
  }
}
