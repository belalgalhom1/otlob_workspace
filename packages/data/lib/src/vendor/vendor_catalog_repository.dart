import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorCatalogRepository {
  final VendorsProductsApi _api;
  VendorCatalogRepository(this._api);

  Future<dynamic> createProduct(String vendorId, CreateProductDto createProductDto) async {
    final response = await _api.productsControllerCreate(
      vendorId: vendorId,
      createProductDto: createProductDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getProducts(String vendorId) async {
    final response = await _api.productsControllerFindAll(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getProduct(String vendorId, String productId) async {
    final response = await _api.productsControllerFindOne(vendorId: vendorId, productId: productId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateProduct(String vendorId, String productId, UpdateProductDto updateProductDto) async {
    final response = await _api.productsControllerUpdate(
      vendorId: vendorId,
      productId: productId,
      updateProductDto: updateProductDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteProduct(String vendorId, String productId) async {
    final response = await _api.productsControllerRemove(vendorId: vendorId, productId: productId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> addVariant(String vendorId, String productId, CreateProductVariantDto dto) async {
    final response = await _api.productsControllerAddVariant(vendorId: vendorId, productId: productId, createProductVariantDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateVariant(String vendorId, String productId, String variantId, UpdateProductVariantDto dto) async {
    final response = await _api.productsControllerUpdateVariant(vendorId: vendorId, productId: productId, variantId: variantId, updateProductVariantDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeVariant(String vendorId, String productId, String variantId) async {
    final response = await _api.productsControllerRemoveVariant(vendorId: vendorId, productId: productId, variantId: variantId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> addOptionGroup(String vendorId, String productId, CreateOptionGroupDto dto) async {
    final response = await _api.productsControllerAddOptionGroup(vendorId: vendorId, productId: productId, createOptionGroupDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateOptionGroup(String vendorId, String productId, String groupId, UpdateOptionGroupDto dto) async {
    final response = await _api.productsControllerUpdateOptionGroup(vendorId: vendorId, productId: productId, groupId: groupId, updateOptionGroupDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeOptionGroup(String vendorId, String productId, String groupId) async {
    final response = await _api.productsControllerRemoveOptionGroup(vendorId: vendorId, productId: productId, groupId: groupId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> addVariantOptionGroup(String vendorId, String productId, String variantId, CreateOptionGroupDto dto) async {
    final response = await _api.productsControllerAddVariantOptionGroup(vendorId: vendorId, productId: productId, variantId: variantId, createOptionGroupDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> addOption(String vendorId, String productId, String groupId, CreateProductOptionDto dto) async {
    final response = await _api.productsControllerAddOption(vendorId: vendorId, productId: productId, groupId: groupId, createProductOptionDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateOption(String vendorId, String productId, String groupId, String optionId, UpdateProductOptionDto dto) async {
    final response = await _api.productsControllerUpdateOption(vendorId: vendorId, productId: productId, groupId: groupId, optionId: optionId, updateProductOptionDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeOption(String vendorId, String productId, String groupId, String optionId) async {
    final response = await _api.productsControllerRemoveOption(vendorId: vendorId, productId: productId, groupId: groupId, optionId: optionId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadProductImage(String vendorId, String productId, MultipartFile? file) async {
    final response = await _api.productsControllerUploadImage(vendorId: vendorId, productId: productId, file: file);
    return ResponseParser.parse(response);
  }
}
