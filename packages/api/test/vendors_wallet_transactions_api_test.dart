import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsWalletTransactionsApi
void main() {
  final instance = Api().getVendorsWalletTransactionsApi();

  group(VendorsWalletTransactionsApi, () {
    // Get any vendor's wallet balance (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorWalletControllerAdminGetBalance(String vendorId) async
    test('test vendorWalletControllerAdminGetBalance', () async {
      // TODO
    });

    // List any vendor's wallet transactions (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorWalletControllerAdminListTransactions(String vendorId, { String type, String from, String to, num page, num limit }) async
    test('test vendorWalletControllerAdminListTransactions', () async {
      // TODO
    });

    // Get vendor wallet balance (Member)
    //
    //Future<AuthControllerRegister200Response> vendorWalletControllerGetBalance(String vendorId) async
    test('test vendorWalletControllerGetBalance', () async {
      // TODO
    });

    // List vendor wallet transactions (Member)
    //
    //Future<AuthControllerRegister200Response> vendorWalletControllerListTransactions(String vendorId, { String type, String from, String to, num page, num limit }) async
    test('test vendorWalletControllerListTransactions', () async {
      // TODO
    });

  });
}
