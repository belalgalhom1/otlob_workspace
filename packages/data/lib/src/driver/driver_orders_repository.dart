import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverOrdersRepository {
  final OrdersApi _api;
  DriverOrdersRepository(this._api);

  Future<dynamic> getMyOrders({String? status, num? limit = 20, num? page = 1}) async {
    final response = await _api.ordersControllerGetMyOrdersAsDriver(
      status: status,
      limit: limit,
      page: page
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getActiveDriverOrder() async {
    // We fetch orders that are in an active state for the driver
    // In Prisma schema: LOOKING_FOR_DRIVER, DRIVER_ASSIGNED, PENDING_PAYMENT, READY_FOR_PICKUP, PICKED_UP
    // We just fetch first page without status and filter, or fetch specific statuses if supported.
    // Assuming backend supports comma-separated status or we can just fetch all and filter in memory since active orders are max 1 usually.
    final response = await _api.ordersControllerGetMyOrdersAsDriver(
      limit: 50,
      page: 1,
    );
    final list = ResponseParser.parseList(response);
    
    // Find the first active order
    final activeStatuses = ['LOOKING_FOR_DRIVER', 'ACCEPTED', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT', 'READY_FOR_PICKUP', 'PICKED_UP', 'PREPARING'];
    final dataList = (list['data'] ?? list['orders'] ?? list['items']) as List?;
    if (dataList != null) {
      for (var order in dataList) {
        if (activeStatuses.contains(order['status'])) {
          return {'data': order};
        }
      }
    }
    return {'data': null};
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
}
