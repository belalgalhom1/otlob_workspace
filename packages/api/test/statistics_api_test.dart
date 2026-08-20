import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for StatisticsApi
void main() {
  final instance = Api().getStatisticsApi();

  group(StatisticsApi, () {
    // [Admin] Get platform-wide statistics
    //
    //Future<AuthControllerRegister200Response> statisticsControllerGetAppStats() async
    test('test statisticsControllerGetAppStats', () async {
      // TODO
    });

    // [Admin] Get statistics for a specific driver
    //
    //Future<AuthControllerRegister200Response> statisticsControllerGetDriverStats(String driverId) async
    test('test statisticsControllerGetDriverStats', () async {
      // TODO
    });

    // Get my driver statistics
    //
    //Future<AuthControllerRegister200Response> statisticsControllerGetMyDriverStats() async
    test('test statisticsControllerGetMyDriverStats', () async {
      // TODO
    });

    // Get vendor statistics (member or admin)
    //
    //Future<AuthControllerRegister200Response> statisticsControllerGetVendorStats(String vendorId, { String period }) async
    test('test statisticsControllerGetVendorStats', () async {
      // TODO
    });

  });
}
