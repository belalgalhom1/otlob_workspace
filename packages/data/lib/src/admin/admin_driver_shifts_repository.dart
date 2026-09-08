import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminDriverShiftsRepository {
  final DriverShiftsApi _api;
  AdminDriverShiftsRepository(this._api);

  Future<dynamic> generateShiftPools(GenerateShiftPoolsDto generateShiftPoolsDto) async {
    final response = await _api.driverShiftsControllerGenerateShiftPools(
      generateShiftPoolsDto: generateShiftPoolsDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getShiftPools({String? zoneId}) async {
    final response = await _api.driverShiftsControllerGetShiftPools(zoneId: zoneId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> deleteShiftPool(String id) async {
    final response = await _api.driverShiftsControllerTerminateShiftPool(poolId: id);
    return ResponseParser.parse(response);
  }
}