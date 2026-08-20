import 'package:api/api.dart';
import 'response_parser.dart';

class SharedVerticalsRepository {
  final VendorsVerticalsCategoriesApi _api;
  SharedVerticalsRepository(this._api);

  Future<List<dynamic>> getActiveVerticals() async {
    final response = await _api.vendorVerticalsControllerFindAllActive();
    return ResponseParser.parseList(response);
  }
}