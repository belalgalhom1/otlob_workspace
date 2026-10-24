import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class CustomerVendorsRepository {
  final VendorsCoreManagementApi _api;
  final Dio? _dio;
  CustomerVendorsRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<dynamic> getVendors({
    String? status,
    String? verticalId,
    String? search,
    num limit = 20,
    num page = 1,
    num? lat,
    num? lng,
    String? zoneId,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _api.vendorsControllerFindAll(
      status: status,
      verticalId: verticalId,
      search: search,
      limit: limit,
      page: page,
      lat: lat,
      lng: lng,
      zoneId: zoneId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> searchDiscovery({
    String? status,
    String? verticalId,
    String? search,
    num limit = 20,
    num page = 1,
    num? lat,
    num? lng,
  }) async {
    final response = await _api.vendorsControllerSearchDiscovery(
      status: status,
      verticalId: verticalId,
      search: search,
      limit: limit,
      page: page,
      lat: lat,
      lng: lng,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getVendor(String id, {String? branchId}) async {
    if (_dio != null && branchId != null && branchId.isNotEmpty) {
      final response = await _dio.get('/vendors/$id', queryParameters: {'branchId': branchId});
      return ResponseParser.parse(response);
    }
    final response = await _api.vendorsControllerFindOne(vendorId: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVendorBySlug(String slug, {String? branchId}) async {
    if (_dio != null && branchId != null && branchId.isNotEmpty) {
      final response = await _dio.get('/vendors/slug/$slug', queryParameters: {'branchId': branchId});
      return ResponseParser.parse(response);
    }
    final response = await _api.vendorsControllerFindBySlug(slug: slug);
    return ResponseParser.parse(response);
  }
}
