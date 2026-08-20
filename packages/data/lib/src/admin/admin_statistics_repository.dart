import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminStatisticsRepository {
  final StatisticsApi _api;
  AdminStatisticsRepository(this._api);

  Future<dynamic> getAppStats() async {
    final response = await _api.statisticsControllerGetAppStats();
    return ResponseParser.parse(response);
  }

  Future<dynamic> statisticsGetDriverStats({required String driverId}) async {
    final response = await _api.statisticsControllerGetDriverStats(driverId: driverId);
    return ResponseParser.parse(response);
  }

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
    return ResponseParser.parse(response);
  }

}