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

  Future<dynamic> getDrivers({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? zoneId,
  }) async {
    final response = await _api.driversControllerAdminFindAll(
      page: page,
      limit: limit,
      status: status,
      search: search,
      zoneId: zoneId,
    );
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
    if (parsed is Map) {
      if (parsed.containsKey('success') || parsed.containsKey('data')) {
        return parsed['data'];
      }
      return parsed;
    }
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


  // --- Admin Driver Assist Operations ---
  Future<dynamic> listPendingAssistRequests() async {
    final response = await _api.driversControllerListPendingAssistRequests();
    return ResponseParser.parse(response);
  }

  Future<dynamic> listAssistRequestsForOrder(String orderId) async {
    final response = await _api.driversControllerListAssistRequestsForOrder(orderId: orderId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> decideAssistRequest(String requestId, {required String status}) async {
    final statusEnum = DecideAssistRequestDtoStatusEnum.valueOf(status.toUpperCase());
    final dto = DecideAssistRequestDto((b) => b..status = statusEnum);
    final response = await _api.driversControllerDecideAssistRequest(
      requestId: requestId,
      decideAssistRequestDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> assignAssistDriver(String requestId, {required String driverId}) async {
    final dto = AssignAssistDriverDto((b) => b..driverId = driverId);
    final response = await _api.driversControllerAssignAssistDriver(
      requestId: requestId,
      assignAssistDriverDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> autoAssignAssistDriver(String requestId) async {
    final response = await _api.driversControllerAutoAssignAssistDriver(requestId: requestId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> offerAssistToNearest(String requestId, {String limit = '5'}) async {
    final response = await _api.driversControllerOfferAssistToNearest(requestId: requestId, limit: limit);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getDriverManagerWallet() async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.get('/driver-managers/me/wallet');
    return ResponseParser.parse(response);
  }

  Future<dynamic> getDriverManagerTransactions({int page = 1, int limit = 20}) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.get('/driver-managers/me/transactions', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return ResponseParser.parse(response);
  }

  Future<dynamic> listDriverManagers() async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.get('/driver-managers');
    return ResponseParser.parse(response);
  }

  Future<dynamic> getDriverManagerDetails(String userId) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.get('/driver-managers/$userId');
    return ResponseParser.parse(response);
  }

  Future<dynamic> assignDriversToManager({
    required String driverManagerUserId,
    List<String>? driverIds,
    bool? manageAllDrivers,
  }) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.post('/driver-managers/assign', data: {
      'driverManagerUserId': driverManagerUserId,
      'driverIds': ?driverIds,
      'manageAllDrivers': ?manageAllDrivers,
    });
    return ResponseParser.parse(response);
  }

  Future<dynamic> unassignDriversFromManager({
    required String driverManagerUserId,
    required List<String> driverIds,
  }) async {
    if (_dio == null) throw Exception("Dio is required");
    final response = await _dio.post('/driver-managers/$driverManagerUserId/unassign', data: {
      'driverIds': driverIds,
    });
    return ResponseParser.parse(response);
  }
}
