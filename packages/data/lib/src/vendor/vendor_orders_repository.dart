import 'package:api/api.dart';
import '../shared/response_parser.dart';

class VendorOrdersRepository {
  final OrdersApi _ordersApi;
  VendorOrdersRepository(this._ordersApi);

  Future<dynamic> getOrders(String vendorId, {String? status, num limit = 20, num page = 1}) async {
    final response = await _ordersApi.ordersControllerGetVendorOrders(vendorId: vendorId, status: status, limit: limit, page: page);
    return ResponseParser.parseList(response);
  }

  /// Alias kept for backward compatibility — delegates to [getOrders].
  Future<dynamic> ordersFindAll({required String vendorId, String? status, num limit = 20, num page = 1}) async {
    return ResponseParser.parse(
      await _ordersApi.ordersControllerGetVendorOrders(vendorId: vendorId, status: status, limit: limit, page: page),
    );
  }

  Future<dynamic> updateStatus({required String orderId, required UpdateOrderStatusDto dto}) async {
    final response = await _ordersApi.ordersControllerVendorUpdateStatus(orderId: orderId, updateOrderStatusDto: dto);
    return ResponseParser.parse(response);
  }

  /// Alias kept for backward compatibility — delegates to [updateStatus].
  Future<dynamic> ordersUpdate({required String orderId, required UpdateOrderStatusDto updateOrderStatusDto}) async {
    return updateStatus(orderId: orderId, dto: updateOrderStatusDto);
  }

  Future<dynamic> getOrderById(String orderId) async {
    final response = await _ordersApi.ordersControllerGetOne(orderId: orderId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> acceptFulfillment(String fulfillmentId) async {
    final response = await _ordersApi.ordersControllerAcceptFulfillment(fulfillmentId: fulfillmentId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> rejectFulfillment(String fulfillmentId, {required String reason, String code = 'OTHER'}) async {
    final dto = RejectVendorFulfillmentDto((b) => b
      ..reason = reason
      ..code = RejectVendorFulfillmentDtoCodeEnum.valueOf(code));
    final response = await _ordersApi.ordersControllerRejectFulfillment(
      fulfillmentId: fulfillmentId,
      rejectVendorFulfillmentDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> cancelOrder(String orderId, {String? reason}) async {
    final trimmedReason = reason?.trim();
    final response = await _ordersApi.ordersControllerCancelOrder(
      orderId: orderId,
      cancelOrderDto: CancelOrderDto((b) {
        if (trimmedReason != null && trimmedReason.isNotEmpty) {
          b.reason = trimmedReason;
        }
      }),
    );
    return ResponseParser.parse(response);
  }
}
