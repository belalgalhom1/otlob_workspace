import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for CustomersApi
void main() {
  final instance = Api().getCustomersApi();

  group(CustomersApi, () {
    // [Admin] Prevent customer from placing orders (canOrder → false)
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminDisableOrdering(String customerId) async
    test('test customersControllerAdminDisableOrdering', () async {
      // TODO
    });

    // [Admin] Allow customer to place orders (canOrder → true)
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminEnableOrdering(String customerId) async
    test('test customersControllerAdminEnableOrdering', () async {
      // TODO
    });

    // [Admin] List all customers — filter by canOrder, includeDeleted, search
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminFindAll({ bool canOrder, bool includeDeleted, String search, num page, num limit }) async
    test('test customersControllerAdminFindAll', () async {
      // TODO
    });

    // [Admin] Get a customer by their userId
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminFindByUserId(String userId) async
    test('test customersControllerAdminFindByUserId', () async {
      // TODO
    });

    // [Admin] Get a customer — includes counts + last 5 orders
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminFindOne(String customerId) async
    test('test customersControllerAdminFindOne', () async {
      // TODO
    });

    // [Admin] List a customer's saved addresses
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminGetAddresses(String customerId) async
    test('test customersControllerAdminGetAddresses', () async {
      // TODO
    });

    // [Admin] List a customer's full order history (paginated)
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminGetOrders(String customerId, { num page, num limit }) async
    test('test customersControllerAdminGetOrders', () async {
      // TODO
    });

    // [Admin] Hard-delete a customer (cascades to addresses, carts, favorites). Parent User is untouched.
    //
    //Future<AuthControllerRegister200Response> customersControllerAdminRemove(String customerId) async
    test('test customersControllerAdminRemove', () async {
      // TODO
    });

    // Add a new address
    //
    //Future<AuthControllerRegister200Response> customersControllerCreateAddress(CreateAddressDto createAddressDto) async
    test('test customersControllerCreateAddress', () async {
      // TODO
    });

    // Delete an address
    //
    //Future<AuthControllerRegister200Response> customersControllerDeleteAddress(String id) async
    test('test customersControllerDeleteAddress', () async {
      // TODO
    });

    // Get my addresses
    //
    //Future<AuthControllerRegister200Response> customersControllerGetAddresses() async
    test('test customersControllerGetAddresses', () async {
      // TODO
    });

    // Get coin transaction history
    //
    //Future<AuthControllerRegister200Response> customersControllerGetCoinHistory(String page, String limit) async
    test('test customersControllerGetCoinHistory', () async {
      // TODO
    });

    // Get my favorites (vendors + products)
    //
    //Future<AuthControllerRegister200Response> customersControllerGetFavorites() async
    test('test customersControllerGetFavorites', () async {
      // TODO
    });

    // Toggle product favorite
    //
    //Future<AuthControllerRegister200Response> customersControllerToggleFavoriteProduct(String productId) async
    test('test customersControllerToggleFavoriteProduct', () async {
      // TODO
    });

    // Toggle vendor favorite
    //
    //Future<AuthControllerRegister200Response> customersControllerToggleFavoriteVendor(String vendorId) async
    test('test customersControllerToggleFavoriteVendor', () async {
      // TODO
    });

    // Update an address
    //
    //Future<AuthControllerRegister200Response> customersControllerUpdateAddress(String id, UpdateAddressDto updateAddressDto) async
    test('test customersControllerUpdateAddress', () async {
      // TODO
    });

  });
}
