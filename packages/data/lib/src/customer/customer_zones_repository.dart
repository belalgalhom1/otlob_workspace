import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerZonesRepository {
  final LogisticsZonesApi _api;
  CustomerZonesRepository(this._api);

  Future<dynamic> getZones() async {
    final response = await _api.zonesControllerFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> checkLocation(num longitude, num latitude) async {
    final response = await _api.zonesControllerCheckLocation(
      checkLocationDto: CheckLocationDto((b) => b
        ..longitude = longitude
        ..latitude = latitude
      )
    );
    return ResponseParser.parse(response);
  }
}
