import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminCustomersRepository {
  final CustomersApi _api;
  AdminCustomersRepository(this._api);

  Future<List<dynamic>> getCustomers() async {
    final response = await _api.customersControllerAdminFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getCustomer(String customerId) async {
    final response = await _api.customersControllerAdminFindOne(
      customerId: customerId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getCustomerByUserId(String userId) async {
    final response = await _api.customersControllerAdminFindByUserId(
      userId: userId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> enableCustomerOrdering(String customerId) async {
    final response = await _api.customersControllerAdminEnableOrdering(
      customerId: customerId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> disableCustomerOrdering(String customerId) async {
    final response = await _api
        .customersControllerAdminDisableOrdering(customerId: customerId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getCustomerAddresses(String customerId) async {
    final response = await _api.customersControllerAdminGetAddresses(
      customerId: customerId,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getCustomerOrders(
    String customerId, {
    num? page = 1,
    num? limit = 20,
  }) async {
    final response = await _api.customersControllerAdminGetOrders(
      customerId: customerId,
      page: page,
      limit: limit,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> deleteCustomer(String customerId) async {
    final response = await _api.customersControllerAdminRemove(
      customerId: customerId,
    );
    return ResponseParser.parse(response);
  }
}