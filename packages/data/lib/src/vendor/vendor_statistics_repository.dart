import 'package:api/api.dart';
import '../shared/response_parser.dart';

class VendorStatisticsRepository {
  final StatisticsApi _api;
  VendorStatisticsRepository(this._api);

  Future<dynamic> getVendorStats(String vendorId, {String? period}) async {
    final response = await _api.statisticsControllerGetVendorStats(
      vendorId: vendorId,
      period: period,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMostOrderedProduct(String vendorId) async {
    final response = await _api.statisticsControllerGetMostOrderedProduct(
      vendorId: vendorId,
    );
    if (response.data?.data == null) {
      return null;
    }
    return ResponseParser.parse(response);
  }
}
