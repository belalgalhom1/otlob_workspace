import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class DriverShiftsRepository {
  final DriverShiftsApi _shiftsApi;
  final DriversApi _driversApi;
  final Dio? _dio;

  DriverShiftsRepository(this._shiftsApi, this._driversApi, {Dio? dio})
      : _dio = dio;

  Future<dynamic> startShift(String shiftId) async {
    final response = await _driversApi.driversControllerStartShift(shiftId: shiftId);
    return ResponseParser.parse(response);
  }

  /// Starts a shift with the mandatory start selfie plus the driver's
  /// current coordinates (the backend requires the photo and verifies the
  /// driver is inside the shift zone). Goes through raw dio because the
  /// generated client predates the multipart payload.
  Future<dynamic> startShiftWithPhoto({
    required String shiftId,
    required String photoPath,
    double? latitude,
    double? longitude,
  }) async {
    final client = _dio;
    if (client == null) throw Exception('Dio is required');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photoPath),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final response = await client.post(
      '/drivers/me/shifts/$shiftId/start',
      data: formData,
    );
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
