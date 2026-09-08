import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminOffersRepository {
  final OffersApi _api;
  AdminOffersRepository(this._api);

  Future<List<dynamic>> getOffers({String? vendorId}) async {
    final response = await _api.offersControllerFindAll(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> offersFindAll({String? vendorId}) async {
    final response = await _api.offersControllerFindAll(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> createOffer(dynamic dto) async {
    final response = await _api.offersControllerCreate(createOfferDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> offersUpdate({required String id, required UpdateOfferDto updateOfferDto}) async {
    final response = await _api.offersControllerUpdate(id: id, updateOfferDto: updateOfferDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> offersRemove({required String id}) async {
    final response = await _api.offersControllerRemove(id: id);
    return ResponseParser.parse(response);
  }

}