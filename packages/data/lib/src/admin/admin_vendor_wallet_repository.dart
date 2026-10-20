import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminVendorWalletRepository {
  final VendorsWalletTransactionsApi _api;
  final Dio? _dio;

  AdminVendorWalletRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<dynamic> vendorWalletAdminListTransactions(
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
        '/vendors/$vendorId/wallet/admin/transactions',
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
    final response = await _api.vendorWalletControllerAdminListTransactions(
      vendorId: vendorId,
      type: type,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> vendorWalletAdminGetBalance(String vendorId) async {
    final response = await _api.vendorWalletControllerAdminGetBalance(
      vendorId: vendorId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> vendorWalletAdminGetSummary(
    String vendorId, {
    String? type,
    String? from,
    String? to,
  }) async {
    final dio = _dio;
    if (dio == null) return null;
    final response = await dio.get<dynamic>(
      '/vendors/$vendorId/wallet/admin/summary',
      queryParameters: {
        'type': ?type,
        'from': ?from,
        'to': ?to,
      },
    );
    return _unwrap(response.data);
  }

  static dynamic _unwrap(dynamic data) {
    if (data is Map && data['success'] != null && data['data'] != null) {
      return data['data'];
    }
    return data;
  }
}
