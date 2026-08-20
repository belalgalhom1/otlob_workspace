import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerLoyaltyRepository {
  final CustomersApi _api;
  CustomerLoyaltyRepository(this._api);

  Future<dynamic> getCoinHistory({num limit = 20, num page = 1}) async {
    final response = await _api.customersControllerGetCoinHistory(
      limit: limit.toString(),
      page: page.toString(),
    );
    return ResponseParser.parseList(response);
  }
}
