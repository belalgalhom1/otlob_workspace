import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for DriverManagersApi
void main() {
  final instance = Openapi().getDriverManagersApi();

  group(DriverManagersApi, () {
    // [Admin] Assign drivers to a driver manager (all or specific). Each driver can be assigned to only one manager.
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerAssignDrivers(AssignDriversToManagerDto assignDriversToManagerDto) async
    test('test driverManagersControllerAssignDrivers', () async {
      // TODO
    });

    // [Admin] Get driver manager details and assigned drivers
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerGetManagerDetails(String userId) async
    test('test driverManagersControllerGetManagerDetails', () async {
      // TODO
    });

    // [Admin] Get drivers assigned to a driver manager
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerGetManagerDrivers(String userId) async
    test('test driverManagersControllerGetManagerDrivers', () async {
      // TODO
    });

    // Get my driver-manager wallet
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerGetMyWallet() async
    test('test driverManagersControllerGetMyWallet', () async {
      // TODO
    });

    // List my driver-manager wallet transactions
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerGetTransactions(num page, num limit) async
    test('test driverManagersControllerGetTransactions', () async {
      // TODO
    });

    // [Admin] List all driver managers with assigned driver counts
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerListManagers() async
    test('test driverManagersControllerListManagers', () async {
      // TODO
    });

    // [Admin] Unassign specific drivers from a driver manager
    //
    //Future<ApiControllerRoot200Response> driverManagersControllerUnassignDrivers(String userId, UnassignDriversFromManagerDto unassignDriversFromManagerDto) async
    test('test driverManagersControllerUnassignDrivers', () async {
      // TODO
    });

  });
}
