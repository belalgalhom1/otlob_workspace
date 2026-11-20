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

  Future<dynamic> excuseShift(
    String shiftId, {
    required bool isExcused,
    String? excuseReason,
  }) async {
    final trimmedReason = excuseReason?.trim();
    final dto = ExcuseDriverShiftDto((b) {
      b.isExcused = isExcused;
      if (trimmedReason != null && trimmedReason.isNotEmpty) {
        b.excuseReason = trimmedReason;
      }
    });
    final response = await _api.driverShiftsControllerExcuseShift(
      shiftId: shiftId,
      excuseDriverShiftDto: dto,
    );
    return ResponseParser.parse(response);
  }
}