import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverStatisticsRepository {
  final StatisticsApi _api;
  DriverStatisticsRepository(this._api);

  Future<dynamic> getMyDriverStats() async {
    final response = await _api.statisticsControllerGetMyDriverStats();
    return ResponseParser.parse(response);
  }
}
