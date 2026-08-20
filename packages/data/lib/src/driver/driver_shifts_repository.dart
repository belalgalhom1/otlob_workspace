import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverShiftsRepository {
  final DriverShiftsApi _shiftsApi;
  final DriversApi _driversApi;
  
  DriverShiftsRepository(this._shiftsApi, this._driversApi);

  Future<dynamic> startShift(String shiftId) async {
    final response = await _driversApi.driversControllerStartShift(shiftId: shiftId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> createShift(CreateDriverShiftDto dto) async {
    final response = await _driversApi.driversControllerCreateShift(createDriverShiftDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> endShift(String shiftId) async {
    final response = await _driversApi.driversControllerEndShift(shiftId: shiftId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMyShifts() async {
    final response = await _driversApi.driversControllerGetMyShifts();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getAvailablePools(String zoneId) async {
    final response = await _shiftsApi.driverShiftsControllerGetAvailablePools(zoneId: zoneId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> bookWeeklyShifts(List<String> poolIds) async {
    final response = await _shiftsApi.driverShiftsControllerBookWeeklyShifts(
      bookWeeklyShiftsDto: BookWeeklyShiftsDto((b) => b..shiftPoolIds.replace(poolIds))
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> bookOvertimeShift(String poolId) async {
    final response = await _shiftsApi.driverShiftsControllerBookOvertimeShift(
      bookOvertimeShiftDto: BookOvertimeShiftDto((b) => b..shiftPoolId = poolId)
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> offerSwap(String shiftId, String reason) async {
    final response = await _shiftsApi.driverShiftsControllerOfferSwap(
      shiftId: shiftId
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getSwapBoard() async {
    final response = await _shiftsApi.driverShiftsControllerGetSwapBoard();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> acceptSwap(String swapId) async {
    final response = await _shiftsApi.driverShiftsControllerAcceptSwap(
      swapId: swapId
    );
    return ResponseParser.parse(response);
  }
}
