import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for OrdersApi
void main() {
  final instance = Api().getOrdersApi();

  group(OrdersApi, () {
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerAcceptOrderChanges(String id) async
    test('test ordersControllerAcceptOrderChanges', () async {
      // TODO
    });

    // [Admin] List all orders with filters
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerAdminFindAll({ String status, String vendorId, String driverId, String customerId, num page, num limit }) async
    test('test ordersControllerAdminFindAll', () async {
      // TODO
    });

    // [Admin] Force-assign a driver to an order
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerAdminForceAssignDriver(String orderId, AdminAssignDriverDto adminAssignDriverDto) async
    test('test ordersControllerAdminForceAssignDriver', () async {
      // TODO
    });

    // [Admin/Vendor] Create a pending order directly for a customer
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerAdminPlaceDirectOrder(PlaceDirectOrderDto placeDirectOrderDto) async
    test('test ordersControllerAdminPlaceDirectOrder', () async {
      // TODO
    });

    // Cancel an order (customer or vendor)
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerCancelOrder(String orderId) async
    test('test ordersControllerCancelOrder', () async {
      // TODO
    });

    // Customer marks mobile wallet payment as paid
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerCustomerMarkPaid(String orderId) async
    test('test ordersControllerCustomerMarkPaid', () async {
      // TODO
    });

    // Driver confirms or denies receiving mobile wallet payment
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerDriverConfirmPayment(String orderId) async
    test('test ordersControllerDriverConfirmPayment', () async {
      // TODO
    });

    // Driver updates order status (PICKED_UP / DELIVERED)
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerDriverUpdateStatus(String orderId, UpdateOrderStatusDto updateOrderStatusDto) async
    test('test ordersControllerDriverUpdateStatus', () async {
      // TODO
    });

    //Future<OrdersControllerAdminFindAll200Response> ordersControllerEditOrderItems(String id, EditOrderItemsDto editOrderItemsDto) async
    test('test ordersControllerEditOrderItems', () async {
      // TODO
    });

    // Get my pending dispatch requests
    //
    //Future<OrdersControllerGetMyDispatches200Response> ordersControllerGetMyDispatches() async
    test('test ordersControllerGetMyDispatches', () async {
      // TODO
    });

    // Get my order history (customer)
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerGetMyOrdersAsCustomer({ String status, String vendorId, String driverId, String customerId, num page, num limit }) async
    test('test ordersControllerGetMyOrdersAsCustomer', () async {
      // TODO
    });

    // Get my orders as driver
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerGetMyOrdersAsDriver({ String status, String vendorId, String driverId, String customerId, num page, num limit }) async
    test('test ordersControllerGetMyOrdersAsDriver', () async {
      // TODO
    });

    // Get a single order (customer/driver/vendor/admin)
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerGetOne(String orderId) async
    test('test ordersControllerGetOne', () async {
      // TODO
    });

    // Get orders for a vendor (vendor member or admin)
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerGetVendorOrders(String vendorId, { String status, String vendorId2, String driverId, String customerId, num page, num limit }) async
    test('test ordersControllerGetVendorOrders', () async {
      // TODO
    });

    // Place a custom delivery or ride order
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerPlaceCustomOrder(PlaceCustomOrderDto placeCustomOrderDto) async
    test('test ordersControllerPlaceCustomOrder', () async {
      // TODO
    });

    // Place a new order from active cart
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerPlaceOrder(PlaceOrderDto placeOrderDto) async
    test('test ordersControllerPlaceOrder', () async {
      // TODO
    });

    //Future<OrdersControllerAdminFindAll200Response> ordersControllerRejectOrderChanges(String id) async
    test('test ordersControllerRejectOrderChanges', () async {
      // TODO
    });

    // Accept or reject a dispatch request
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerRespondToDispatch(String dispatchId, RespondToDispatchDto respondToDispatchDto) async
    test('test ordersControllerRespondToDispatch', () async {
      // TODO
    });

    // Vendor updates order status
    //
    //Future<OrdersControllerAdminFindAll200Response> ordersControllerVendorUpdateStatus(String orderId, UpdateOrderStatusDto updateOrderStatusDto) async
    test('test ordersControllerVendorUpdateStatus', () async {
      // TODO
    });

  });
}
