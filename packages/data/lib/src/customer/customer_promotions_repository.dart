import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerPromotionsRepository {
  final PromotionsApi _api;
  CustomerPromotionsRepository(this._api);

  Future<dynamic> getPromotions() async {
    final response = await _api.promotionsControllerFindAllActive();
    return ResponseParser.parseList(response);
  }
}
