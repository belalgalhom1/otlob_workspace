import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminVerticalsRepository {
  final VendorsVerticalsCategoriesApi _api;
  AdminVerticalsRepository(this._api);

  Future<List<dynamic>> getVerticals() async {
    final response = await _api.vendorVerticalsControllerFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> verticalsFindAll() async {
    final response = await _api.vendorVerticalsControllerFindAll();
    return ResponseParser.parse(response);
  }

  Future<dynamic> createVertical(dynamic dto) async {
    final response = await _api.vendorVerticalsControllerCreate(createVendorVerticalDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteVertical(String id) async {
    final response = await _api.vendorVerticalsControllerRemove(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateVertical(String id, dynamic dto) async {
    final response = await _api.vendorVerticalsControllerUpdate(id: id, updateVendorVerticalDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadVerticalIcon(String id, MultipartFile? file) async {
    final response = await _api.vendorVerticalsControllerUploadIcon(id: id, file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVerticalById(String id) async {
    final response = await _api.vendorVerticalsControllerFindOne(id: id);
    return ResponseParser.parse(response);
  }
}