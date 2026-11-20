import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminOrdersRepository {
  final OrdersApi _api;
  AdminOrdersRepository(this._api);

  Future<List<dynamic>> getOrders() async {
    final response = await _api.ordersControllerAdminFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> ordersAdminPlaceDirectOrder(
      {required PlaceDirectOrderDto placeDirectOrderDto, String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'admin_${DateTime.now().microsecondsSinceEpoch}';
    final response = await _api.ordersControllerAdminPlaceDirectOrder(
      idempotencyKey: key,
      placeDirectOrderDto: placeDirectOrderDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> ordersFindAll({String? vendorId, String? driverId, String? status, num? limit = 20, num? page = 1}) async {
    final response = await _api.ordersControllerAdminFindAll(vendorId: vendorId, driverId: driverId, status: status, limit: limit, page: page);
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

  Future<dynamic> acceptFulfillment(String fulfillmentId) async {
    final response = await _api.ordersControllerAcceptFulfillment(fulfillmentId: fulfillmentId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> rejectFulfillment(String fulfillmentId, {required String reason, String code = 'OTHER'}) async {
    final dto = RejectVendorFulfillmentDto((b) => b
      ..reason = reason
      ..code = RejectVendorFulfillmentDtoCodeEnum.valueOf(code));
    final response = await _api.ordersControllerRejectFulfillment(
      fulfillmentId: fulfillmentId,
      rejectVendorFulfillmentDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> cancelOrder(
    String orderId, {
    String? reason,
    DeliveryIncidentResponsibility? responsibility,
    String? responsibleDriverId,
  }) async {
    final trimmedReason = reason?.trim();
    final trimmedDriverId = responsibleDriverId?.trim();
    final response = await _api.ordersControllerCancelOrder(
      orderId: orderId,
      cancelOrderDto: CancelOrderDto((b) {
        if (trimmedReason != null && trimmedReason.isNotEmpty) {
          b.reason = trimmedReason;
        }
        if (responsibility != null) {
          b.responsibility = responsibility;
        }
        if (trimmedDriverId != null && trimmedDriverId.isNotEmpty) {
          b.responsibleDriverId = trimmedDriverId;
        }
      }),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> assignDriver({
    required String orderId,
    required String driverId,
    String? deliveryGroupId,
    DeliveryIncidentResponsibility? previousDriverResponsibility,
    String? reassignmentReason,
  }) async {
    final trimmedReason = reassignmentReason?.trim();
    final dto = AdminAssignDriverDto((b) {
      b.driverId = driverId;
      if (deliveryGroupId != null && deliveryGroupId.isNotEmpty) {
        b.deliveryGroupId = deliveryGroupId;
      }
      if (previousDriverResponsibility != null) {
        b.previousDriverResponsibility = previousDriverResponsibility;
      }
      if (trimmedReason != null && trimmedReason.isNotEmpty) {
        b.reassignmentReason = trimmedReason;
      }
    });
    final response = await _api.ordersControllerAdminForceAssignDriver(
      orderId: orderId,
      adminAssignDriverDto: dto,
    );
    return ResponseParser.parse(response);
  }
}
