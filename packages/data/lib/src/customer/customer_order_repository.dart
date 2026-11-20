import 'package:api/api.dart';
import '../shared/response_parser.dart';

import 'package:dio/dio.dart';

class CustomerOrderRepository {
  final OrdersApi _api;
  final ReviewsApi _reviewsApi;
  final Dio? dio;
  CustomerOrderRepository(this._api, this._reviewsApi, {this.dio});

  Future<dynamic> getMyOrders({String? status, num limit = 20, num page = 1}) async {
    final response = await _api.ordersControllerGetMyOrdersAsCustomer(
      status: status,
      limit: limit,
      page: page
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> markPaid(String orderId, {MultipartFile? receipt}) async {
    final client = dio;
    if (client != null && receipt != null) {
      final formData = FormData.fromMap({'file': receipt});
      final response = await client.post(
        '/orders/customer/$orderId/payment/mark-paid',
        data: formData,
      );
      return ResponseParser.parse(response);
    }
    final response = await _api.ordersControllerCustomerMarkPaid(orderId: orderId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> placeCustomOrder(PlaceCustomOrderDto placeCustomOrderDto,
      {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'order_${DateTime.now().microsecondsSinceEpoch}';
    final response = await _api.ordersControllerPlaceCustomOrder(
      idempotencyKey: key,
      placeCustomOrderDto: placeCustomOrderDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> estimateCustomOrder(PlaceCustomOrderDto placeCustomOrderDto) async {
    final response = await _api.ordersControllerEstimateCustomOrder(
      placeCustomOrderDto: placeCustomOrderDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> placeOrder(PlaceOrderDto dto, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'order_${DateTime.now().microsecondsSinceEpoch}';
    final response = await _api.ordersControllerPlaceOrder(
      idempotencyKey: key,
      placeOrderDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> estimateOrder(PlaceOrderDto dto) async {
    final response = await _api.ordersControllerEstimateOrder(placeOrderDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> cancelOrder(String orderId, {String? reason}) async {
    final trimmedReason = reason?.trim();
    final response = await _api.ordersControllerCancelOrder(
      orderId: orderId,
      cancelOrderDto: CancelOrderDto((b) {
        if (trimmedReason != null && trimmedReason.isNotEmpty) {
          b.reason = trimmedReason;
        }
      }),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getOrderById(String orderId) async {
    final response = await _api.ordersControllerGetOne(orderId: orderId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> rateOrder(String orderId, CreateReviewDto dto) async {
    final response = await _reviewsApi.reviewsControllerSubmitReview(
      orderId: orderId,
      createReviewDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> placeMultiVendorOrder(PlaceMultiVendorOrderDto dto, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'mvo_${DateTime.now().microsecondsSinceEpoch}';
    final response = await _api.ordersControllerPlaceMultiVendorOrder(
      idempotencyKey: key,
      placeMultiVendorOrderDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> estimateMultiVendor(PlaceMultiVendorOrderDto dto) async {
    final response = await _api.ordersControllerEstimateMultiVendor(
      placeMultiVendorOrderDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> decideAssistOrder(String orderId, {required bool approved, String? deliveryGroupId}) async {
    final dto = CustomerDecideAssistDto((b) => b..approved = approved);
    final response = deliveryGroupId != null && deliveryGroupId.isNotEmpty
        ? await _api.orderAssistDecisionControllerDecideAssist(
            orderId: orderId,
            deliveryGroupId: deliveryGroupId,
            customerDecideAssistDto: dto,
          )
        : await _api.orderAssistDecisionControllerDecideAssistOrder(
            orderId: orderId,
            customerDecideAssistDto: dto,
          );
    return ResponseParser.parse(response);
  }
}
