import 'package:api/api.dart';
import 'response_parser.dart';

class SharedWalletRepository {
  final WalletFinancialsApi _api;
  SharedWalletRepository(this._api);

  Future<dynamic> getActivePlatformWallets() async {
    final response = await _api.walletControllerGetActivePlatformWallets();
    return ResponseParser.parseList(response);
  }
}
