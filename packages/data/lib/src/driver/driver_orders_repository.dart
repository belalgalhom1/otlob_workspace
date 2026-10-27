import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverOrdersRepository {
  final OrdersApi _api;
  final DriversApi? _driversApi;
  DriverOrdersRepository(this._api, {DriversApi? driversApi}) : _driversApi = driversApi;

  Future<dynamic> getMyOrders({String? status, num? limit = 20, num? page = 1}) async {
    final response = await _api.ordersControllerGetMyOrdersAsDriver(
      status: status,
      limit: limit,
      page: page
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getActiveDriverOrder({String? orderId}) async {
    final response = await _api.ordersControllerGetMyOrdersAsDriver(
      limit: 50,
      page: 1,
    );
    final list = ResponseParser.parseList(response);
    
    final activeStatuses = ['LOOKING_FOR_DRIVER', 'ACCEPTED', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'PREPARING'];
    final dataList = (list['data'] ?? list['orders'] ?? list['items']) as List?;
    if (dataList != null) {
      if (orderId != null) {
        for (var order in dataList) {
          if (order['id']?.toString() == orderId && activeStatuses.contains(order['status'])) {
            return {'data': order};
          }
        }
      }
      for (var order in dataList) {
        if (activeStatuses.contains(order['status'])) {
          return {'data': order};
        }
      }
    }
    return {'data': null};
  }

  Future<List<dynamic>> getActiveDriverOrders() async {
    final response = await _api.ordersControllerGetMyOrdersAsDriver(
      limit: 50,
      page: 1,
    );
    final list = ResponseParser.parseList(response);
    
    final activeStatuses = ['LOOKING_FOR_DRIVER', 'ACCEPTED', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'PREPARING'];
    final dataList = (list['data'] ?? list['orders'] ?? list['items']) as List?;
    final activeOrders = <dynamic>[];
    if (dataList != null) {
      for (var order in dataList) {
        if (activeStatuses.contains(order['status'])) {
          activeOrders.add(order);
        }
      }
    }
    return activeOrders;
  }

  Future<dynamic> confirmPayment(String orderId, {required bool received}) async {
    final response = await _api.ordersControllerDriverConfirmPayment(
      orderId: orderId, 
      confirmPaymentDto: ConfirmPaymentDto((b) => b..received = received)
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateOrderStatus(String orderId, String status) async {
    final response = await _api.ordersControllerDriverUpdateStatus(
      orderId: orderId,
      updateOrderStatusDto: UpdateOrderStatusDto((b) => b
        ..status = UpdateOrderStatusDtoStatusEnum.valueOf(status.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getOrderById(String orderId) async {
    final response = await _api.ordersControllerGetOne(orderId: orderId);
    return ResponseParser.parse(response);
  }

  // --- Driver Assist Methods ---
  Future<dynamic> requestAssistOrder(String orderId, {required String reason, String? note}) async {
    if (_driversApi == null) throw Exception("DriversApi required for assist operations");
    final dto = RequestAssistDriverDto((b) => b
      ..reason = reason
      ..note = note
    );
    final response = await _driversApi.driversControllerRequestAssistOrder(
      orderId: orderId,
      requestAssistDriverDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMyAssistRequests() async {
    if (_driversApi == null) throw Exception("DriversApi required for assist operations");
    final response = await _driversApi.driversControllerMyAssistRequests();
    return ResponseParser.parse(response);
  }

  Future<dynamic> cancelAssistRequest(String requestId) async {
    if (_driversApi == null) throw Exception("DriversApi required for assist operations");
    final response = await _driversApi.driversControllerCancelAssistRequest(requestId: requestId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getPendingAssistOffers() async {
    if (_driversApi == null) throw Exception("DriversApi required for assist operations");
    final response = await _driversApi.driversControllerPendingAssistOffers();
    return ResponseParser.parse(response);
  }

  Future<dynamic> respondToAssistOffer(String requestId, {required bool accept}) async {
    if (_driversApi == null) throw Exception("DriversApi required for assist operations");
    final response = await _driversApi.driversControllerRespondToAssistOffer(
      requestId: requestId,
      accept: accept,
    );
    return ResponseParser.parse(response);
  }
}
