import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminDriversRepository {
  final DriversApi _api;
  final OrdersApi _ordersApi;
  final DriverShiftsApi _shiftsApi;
  final Dio? _dio;

  AdminDriversRepository(this._api, this._ordersApi, this._shiftsApi, {Dio? dio}) : _dio = dio;

  Future<dynamic> driversAdminCreate({required Map<String, dynamic> data}) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.post('/drivers/admin', data: data);
    return ResponseParser.parse(response);
  }

  Future<dynamic> driversAdminUpdate({required String driverId, required Map<String, dynamic> data}) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.patch('/drivers/$driverId/admin', data: data);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getDrivers({int page = 1, int limit = 20, String? status, String? search}) async {
    final response = await _api.driversControllerAdminFindAll(page: page, limit: limit, status: status, search: search);
    return ResponseParser.parse(response);
  }

  Future<dynamic> driversAdminUnsuspend({required String driverId}) async {
    final response = await _api.driversControllerAdminUnsuspend(driverId: driverId);
    return ResponseParser.parse(response);
  }


  Future<dynamic> driversAdminSuspend({required String driverId}) async {
    final response = await _api.driversControllerAdminSuspend(driverId: driverId);
    return ResponseParser.parse(response);
  }


  Future<dynamic> driverShiftsAdminAssignShift({required AdminAssignShiftDto adminAssignShiftDto}) async {
    final response = await _shiftsApi.driverShiftsControllerAdminAssignShift(adminAssignShiftDto: adminAssignShiftDto);
    return ResponseParser.parse(response);
  }


  Future<dynamic> driversAdminCreateShift({required String driverId, required CreateDriverShiftDto createDriverShiftDto}) async {
    final response = await _api.driversControllerAdminCreateShift(driverId: driverId, createDriverShiftDto: createDriverShiftDto);
    return ResponseParser.parse(response);
  }


  Future<dynamic> driversAdminFindOne({required String driverId}) async {
    final response = await _api.driversControllerAdminFindOne(driverId: driverId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getDriverLocation({required String driverId}) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.get('/drivers/$driverId/location');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) return parsed['data'] ?? parsed;
    return parsed;
  }


  Future<dynamic> driversAdminGetShifts({required String driverId}) async {
    final response = await _api.driversControllerAdminGetShifts(driverId: driverId);
    return ResponseParser.parseList(response);
  }


  Future<dynamic> ordersAdminForceAssignDriver({required String orderId, required AdminAssignDriverDto adminAssignDriverDto}) async {
    final response = await _ordersApi.ordersControllerAdminForceAssignDriver(orderId: orderId, adminAssignDriverDto: adminAssignDriverDto);
    return ResponseParser.parse(response);
  }

}