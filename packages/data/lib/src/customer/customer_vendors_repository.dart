import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerVendorsRepository {
  final VendorsCoreManagementApi _api;
  CustomerVendorsRepository(this._api);

  Future<dynamic> getVendors({
    String? status,
    String? verticalId,
    String? search,
    num limit = 20,
    num page = 1,
    num? lat,
    num? lng,
  }) async {
    final response = await _api.vendorsControllerFindAll(
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

  Future<dynamic> getVendor(String id) async {
    final response = await _api.vendorsControllerFindOne(vendorId: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVendorBySlug(String slug) async {
    final response = await _api.vendorsControllerFindBySlug(slug: slug);
    return ResponseParser.parse(response);
  }
}
