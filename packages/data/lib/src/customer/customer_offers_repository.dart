import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerOffersRepository {
  final OffersApi _api;
  CustomerOffersRepository(this._api);

  Future<dynamic> getOffers() async {
    final response = await _api.offersControllerFindAllActive();
    return ResponseParser.parseList(response);
  }
}
