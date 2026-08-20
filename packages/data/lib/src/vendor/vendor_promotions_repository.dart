import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorPromotionsRepository {
  final PromotionsApi _api;
  VendorPromotionsRepository(this._api);

  Future<dynamic> promotionsCreate({MultipartFile? file}) async {
    final response = await _api.promotionsControllerCreate(file: file);
    return ResponseParser.parse(response);
  }


  Future<dynamic> promotionsFindAll() async {
    final response = await _api.promotionsControllerFindAll();
    return ResponseParser.parse(response);
  }


  Future<dynamic> promotionsRemove({required String id}) async {
    final response = await _api.promotionsControllerRemove(id: id);
    return ResponseParser.parse(response);
  }


  Future<dynamic> promotionsUpdate({required String id, required UpdatePromotionDto updatePromotionDto}) async {
    final response = await _api.promotionsControllerUpdate(id: id, updatePromotionDto: updatePromotionDto);
    return ResponseParser.parse(response);
  }


  Future<dynamic> promotionsUploadImage({required String id, MultipartFile? file}) async {
    final response = await _api.promotionsControllerUploadImage(id: id, file: file);
    return ResponseParser.parse(response);
  }


  Future<dynamic> promotionsFindOne({required String id}) async {
    final response = await _api.promotionsControllerFindOne(id: id);
    return ResponseParser.parse(response);
  }

}
