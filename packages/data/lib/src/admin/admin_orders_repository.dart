import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminOrdersRepository {
  final OrdersApi _api;
  AdminOrdersRepository(this._api);

  Future<List<dynamic>> getOrders() async {
    final response = await _api.ordersControllerAdminFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> ordersAdminPlaceDirectOrder({required PlaceDirectOrderDto placeDirectOrderDto}) async {
    final response = await _api.ordersControllerAdminPlaceDirectOrder(placeDirectOrderDto: placeDirectOrderDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> ordersFindAll({String? vendorId, String? status, num? limit = 20, num? page = 1}) async {
    final response = await _api.ordersControllerAdminFindAll(vendorId: vendorId, status: status, limit: limit, page: page);
    return ResponseParser.parse(response);
  }

  Future<dynamic> ordersUpdate({required String orderId, required UpdateOrderStatusDto updateOrderStatusDto}) async {
    // Note: Reusing vendor update status for admin as there's no specific admin update status endpoint
    final response = await _api.ordersControllerVendorUpdateStatus(orderId: orderId, updateOrderStatusDto: updateOrderStatusDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getOrderById(String orderId) async {
    final response = await _api.ordersControllerGetOne(orderId: orderId);
    return ResponseParser.parse(response);
  }
}
