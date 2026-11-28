import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerPromotionsRepository {
  final PromotionsApi _api;
  CustomerPromotionsRepository(this._api);

  Future<dynamic> getPromotions({
    String? verticalId,
    String? verticalSlug,
  }) async {
    final response = await _api.promotionsControllerFindAllActive(
      verticalId: verticalId,
      verticalSlug: verticalSlug,
    );
    return ResponseParser.parseList(response);
  }
}
