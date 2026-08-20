import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorCategoriesRepository {
  final VendorsMenuCategoriesApi _api;
  VendorCategoriesRepository(this._api);

  Future<dynamic> getCategories({required String vendorId}) async {
    final response = await _api.menuCategoriesControllerFindAll(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }
  
  Future<dynamic> getCategoryById({required String vendorId, required String categoryId}) async {
    final response = await _api.menuCategoriesControllerFindOne(categoryId: categoryId, vendorId: vendorId);
    return ResponseParser.parse(response);
  }
  
  Future<dynamic> createCategory({required String vendorId, required CreateMenuCategoryDto dto}) async {
    final response = await _api.menuCategoriesControllerCreate(createMenuCategoryDto: dto, vendorId: vendorId);
    return ResponseParser.parse(response);
  }
  
  Future<dynamic> updateCategory({required String vendorId, required String categoryId, required UpdateMenuCategoryDto dto}) async {
    final response = await _api.menuCategoriesControllerUpdate(updateMenuCategoryDto: dto, categoryId: categoryId, vendorId: vendorId);
    return ResponseParser.parse(response);
  }
  
  Future<dynamic> removeCategory(String vendorId, String categoryId) async {
    final response = await _api.menuCategoriesControllerRemove(categoryId: categoryId, vendorId: vendorId);
    return ResponseParser.parse(response);
  }
  
  Future<dynamic> reorderCategories(String vendorId, ReorderCategoriesDto dto) async {
    final response = await _api.menuCategoriesControllerReorder(vendorId: vendorId, reorderCategoriesDto: dto);
    return ResponseParser.parse(response);
  }
  
  Future<dynamic> uploadCategoryIcon(String vendorId, String categoryId, MultipartFile? file) async {
    final response = await _api.menuCategoriesControllerUploadIcon(vendorId: vendorId, categoryId: categoryId, file: file);
    return ResponseParser.parse(response);
  }
}
