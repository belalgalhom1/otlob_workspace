import 'package:api/api.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminVendorsRepository {
  final VendorsCoreManagementApi _api;
  final VendorsProductsApi _productsApi;
  final VendorsMenuCategoriesApi _menuApi;
  final VendorsBranchesApi _branchesApi;
  final PromotionsApi _promotionsApi;
  final Dio _dio;

  AdminVendorsRepository(
    this._api,
    this._productsApi,
    this._menuApi,
    this._branchesApi,
    this._promotionsApi,
    this._dio,
  );
  Future<dynamic> getVendors({String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      // Hit the admin endpoint again, assuming the backend routing is fixed now
      final response = await _dio.get('/vendors/admin', queryParameters: queryParams);
      
      if (response.data is Map) {
        final data = response.data as Map;
        if (data.containsKey('data')) {
          return data['data']; // Returns the un-wrapped object containing 'vendors' array
        }
        return data;
      }
      
      return ResponseParser.parse(response);
    } catch (e, st) {
      print('DEBUG getVendors error: $e\n$st');
      return {'vendors': []};
    }
  }

  Future<dynamic> vendorsFindBySlug({required String slug}) async {
    final response = await _api.vendorsControllerFindOne(vendorId: slug);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVendor(String id) async {
    return vendorsFindBySlug(slug: id);
  }

  Future<dynamic> vendorsCreate({
    required CreateVendorDto createVendorDto,
  }) async {
    final response = await _api.vendorsControllerCreate(
      createVendorDto: createVendorDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> vendorsRemove({required String vendorId}) async {
    final response = await _api.vendorsControllerRemove(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> vendorsUpdate({
    required String vendorId,
    required UpdateVendorDto updateVendorDto,
  }) async {
    final response = await _api.vendorsControllerUpdate(
      vendorId: vendorId,
      updateVendorDto: updateVendorDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateVendorStatus({
    required String vendorId,
    required UpdateVendorStatusDto updateVendorStatusDto,
  }) async {
    final response = await _api.vendorsControllerUpdateStatus(
      vendorId: vendorId,
      updateVendorStatusDto: updateVendorStatusDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadVendorCover({
    required String vendorId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final file = MultipartFile.fromBytes(fileBytes, filename: fileName);
    final response = await _api.vendorsControllerUploadCover(
      vendorId: vendorId,
      file: file,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getBranches(String vendorId) async {
    final response = await _branchesApi.vendorBranchesControllerFindAll(
      vendorId: vendorId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createBranch(
    String vendorId,
    CreateVendorBranchDto createVendorBranchDto,
  ) async {
    final response = await _branchesApi.vendorBranchesControllerAdminCreate(
      vendorId: vendorId,
      createVendorBranchDto: createVendorBranchDto,
    );
    return ResponseParser.parse(response);
  }

  /// Creates a branch using raw Dio to ensure location is sent as [num, num].
  Future<dynamic> createBranchRaw(
    String vendorId, {
    required String name,
    String? nameAr,
    required String address,
    String? phone,
    required double lat,
    required double lng,
    String? zoneId,
    bool isOpen = true,
    bool? isContracted,
    int? commissionRate,
  }) async {
    final response = await _dio.post(
      '/vendors/$vendorId/branches/admin',
      data: {
        'name': name,
        if (nameAr != null && nameAr.isNotEmpty) 'nameAr': nameAr,
        'address': address,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'location': [lat, lng],
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
        'isOpen': isOpen,
        if (isContracted != null) 'isContracted': isContracted,
        if (commissionRate != null) 'commissionRate': commissionRate,
      },
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateBranch(
    String vendorId,
    String branchId,
    UpdateVendorBranchDto updateVendorBranchDto,
  ) async {
    final response = await _branchesApi.vendorBranchesControllerAdminUpdate(
      vendorId: vendorId,
      branchId: branchId,
      updateVendorBranchDto: updateVendorBranchDto,
    );
    return ResponseParser.parse(response);
  }

  /// Updates a branch using raw Dio to ensure location is sent as [num, num].
  Future<dynamic> updateBranchRaw(
    String vendorId,
    String branchId, {
    String? name,
    String? nameAr,
    String? address,
    String? phone,
    double? lat,
    double? lng,
    String? zoneId,
    bool? isOpen,
    bool? isContracted,
    int? commissionRate,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (nameAr != null) body['nameAr'] = nameAr;
    if (address != null) body['address'] = address;
    if (phone != null) body['phone'] = phone;
    if (lat != null && lng != null) body['location'] = [lat, lng];
    if (zoneId != null && zoneId.isNotEmpty) body['zoneId'] = zoneId;
    if (isOpen != null) body['isOpen'] = isOpen;
    if (isContracted != null) body['isContracted'] = isContracted;
    if (commissionRate != null) body['commissionRate'] = commissionRate;
    final response = await _dio.patch(
      '/vendors/$vendorId/branches/admin/$branchId',
      data: body,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteBranch(String vendorId, String branchId) async {
    final response = await _branchesApi.vendorBranchesControllerAdminRemove(
      vendorId: vendorId,
      branchId: branchId,
    );
    return ResponseParser.parse(response);
  }

  // --- Categories Proxy ---
  Future<dynamic> getMenuCategories(String vendorId, {String? branchId}) async {
    final response = await _dio.get(
      '/vendors/$vendorId/categories',
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
      },
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createMenuCategoryRaw(
    String vendorId, {
    required String name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    int? sortOrder,
    bool isActive = true,
    String branchAvailabilityMode = 'ALL',
    List<String>? branchIds,
    bool isAdmin = true,
  }) async {
    final endpoint = isAdmin
        ? '/vendors/$vendorId/categories/admin'
        : '/vendors/$vendorId/categories';
    final response = await _dio.post(
      endpoint,
      data: {
        'name': name,
        if (nameAr != null && nameAr.isNotEmpty) 'nameAr': nameAr,
        if (description != null && description.isNotEmpty) 'description': description,
        if (descriptionAr != null && descriptionAr.isNotEmpty) 'descriptionAr': descriptionAr,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'isActive': isActive,
        'branchAvailabilityMode': branchAvailabilityMode,
        if (branchIds != null && branchIds.isNotEmpty) 'branchIds': branchIds,
      },
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateMenuCategoryRaw(
    String vendorId,
    String categoryId, {
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    int? sortOrder,
    bool? isActive,
    String? branchAvailabilityMode,
    List<String>? branchIds,
    bool isAdmin = true,
  }) async {
    final endpoint = isAdmin
        ? '/vendors/$vendorId/categories/admin/$categoryId'
        : '/vendors/$vendorId/categories/$categoryId';
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (nameAr != null) body['nameAr'] = nameAr;
    if (description != null) body['description'] = description;
    if (descriptionAr != null) body['descriptionAr'] = descriptionAr;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (isActive != null) body['isActive'] = isActive;
    if (branchAvailabilityMode != null) body['branchAvailabilityMode'] = branchAvailabilityMode;
    if (branchIds != null) body['branchIds'] = branchIds;
    final response = await _dio.patch(
      endpoint,
      data: body,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createMenuCategory(
    String vendorId,
    CreateMenuCategoryDto createMenuCategoryDto, {
    bool isAdmin = true,
  }) async {
    final response = isAdmin
        ? await _menuApi.menuCategoriesControllerAdminCreate(
            vendorId: vendorId,
            createMenuCategoryDto: createMenuCategoryDto,
          )
        : await _menuApi.menuCategoriesControllerCreate(
            vendorId: vendorId,
            createMenuCategoryDto: createMenuCategoryDto,
          );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateMenuCategory(
    String vendorId,
    String categoryId,
    UpdateMenuCategoryDto updateMenuCategoryDto, {
    bool isAdmin = true,
  }) async {
    final response = isAdmin
        ? await _menuApi.menuCategoriesControllerAdminUpdate(
            vendorId: vendorId,
            categoryId: categoryId,
            updateMenuCategoryDto: updateMenuCategoryDto,
          )
        : await _menuApi.menuCategoriesControllerUpdate(
            vendorId: vendorId,
            categoryId: categoryId,
            updateMenuCategoryDto: updateMenuCategoryDto,
          );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteMenuCategory(String vendorId, String categoryId, {bool isAdmin = true}) async {
    final response = isAdmin
        ? await _menuApi.menuCategoriesControllerAdminRemove(
            vendorId: vendorId,
            categoryId: categoryId,
          )
        : await _menuApi.menuCategoriesControllerRemove(
            vendorId: vendorId,
            categoryId: categoryId,
          );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadMenuCategoryIcon(
    String vendorId,
    String id,
    List<int> fileBytes,
    String fileName, {
    bool isAdmin = true,
  }) async {
    final file = MultipartFile.fromBytes(fileBytes, filename: fileName);
    final response = isAdmin
        ? await _menuApi.menuCategoriesControllerAdminUploadIcon(
            vendorId: vendorId,
            categoryId: id,
            file: file,
          )
        : await _menuApi.menuCategoriesControllerUploadIcon(
            vendorId: vendorId,
            categoryId: id,
            file: file,
          );
    return ResponseParser.parse(response);
  }

  // --- Products Proxy ---
  Future<dynamic> getProducts(String vendorId, {String? search}) async {
    final response = await _productsApi.productsControllerFindAll(
      vendorId: vendorId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVendorProduct(String vendorId, String productId) async {
    final response = await _productsApi.productsControllerFindOne(
      vendorId: vendorId,
      productId: productId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createProduct(
    String vendorId,
    CreateProductDto createProductDto, {
    bool isAdmin = true,
  }) async {
    final response = isAdmin
        ? await _productsApi.productsControllerAdminCreate(
            vendorId: vendorId,
            createProductDto: createProductDto,
          )
        : await _productsApi.productsControllerCreate(
            vendorId: vendorId,
            createProductDto: createProductDto,
          );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateProduct(
    String vendorId,
    String productId,
    UpdateProductDto updateProductDto, {
    bool isAdmin = true,
  }) async {
    final response = isAdmin
        ? await _productsApi.productsControllerAdminUpdate(
            vendorId: vendorId,
            productId: productId,
            updateProductDto: updateProductDto,
          )
        : await _productsApi.productsControllerUpdate(
            vendorId: vendorId,
            productId: productId,
            updateProductDto: updateProductDto,
          );
    return ResponseParser.parse(response);
  }

  /// Creates a product and its branch availability atomically.
  ///
  /// The generated client predates the branch fields. Serializing the existing
  /// DTO keeps every other field wire-compatible, then the two branch fields
  /// are added before the raw request.
  Future<dynamic> createProductWithBranchAvailability(
    String vendorId,
    CreateProductDto createProductDto, {
    required String branchAvailabilityMode,
    required List<String> branchIds,
    bool isAdmin = true,
  }) async {
    final body = _serializeProductDto(
      createProductDto,
      const FullType(CreateProductDto),
    );
    body['branchAvailabilityMode'] = branchAvailabilityMode;
    body['branchIds'] = branchIds;

    final response = await _dio.post(
      isAdmin ? '/vendors/$vendorId/products/admin' : '/vendors/$vendorId/products',
      data: body,
    );
    return ResponseParser.parse(response);
  }

  /// Updates a product and replaces its branch availability atomically.
  Future<dynamic> updateProductWithBranchAvailability(
    String vendorId,
    String productId,
    UpdateProductDto updateProductDto, {
    required String branchAvailabilityMode,
    required List<String> branchIds,
    bool isAdmin = true,
  }) async {
    final body = _serializeProductDto(
      updateProductDto,
      const FullType(UpdateProductDto),
    );
    body['branchAvailabilityMode'] = branchAvailabilityMode;
    body['branchIds'] = branchIds;

    final response = await _dio.patch(
      isAdmin
          ? '/vendors/$vendorId/products/admin/$productId'
          : '/vendors/$vendorId/products/$productId',
      data: body,
    );
    return ResponseParser.parse(response);
  }

  Map<String, dynamic> _serializeProductDto(Object dto, FullType type) {
    final serialized = standardSerializers.serialize(
      dto,
      specifiedType: type,
    );
    if (serialized is! Map) return <String, dynamic>{};
    return serialized.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  Future<dynamic> uploadProductImage(
    String vendorId,
    String productId,
    MultipartFile? file,
  ) async {
    final response = await _productsApi.productsControllerUploadImage(
      vendorId: vendorId,
      productId: productId,
      file: file,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteProduct(String vendorId, String productId, {bool isAdmin = true}) async {
    final response = isAdmin
        ? await _productsApi.productsControllerAdminRemove(
            vendorId: vendorId,
            productId: productId,
          )
        : await _productsApi.productsControllerRemove(
            vendorId: vendorId,
            productId: productId,
          );
    return ResponseParser.parse(response);
  }

  // --- Variants and Options ---
  Future<dynamic> addVariant(
    String vendorId,
    String productId,
    CreateProductVariantDto createProductVariantDto,
  ) async {
    final response = await _productsApi.productsControllerAddVariant(
      vendorId: vendorId,
      productId: productId,
      createProductVariantDto: createProductVariantDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateVariant(
    String vendorId,
    String productId,
    String variantId,
    UpdateProductVariantDto updateProductVariantDto,
  ) async {
    final response = await _productsApi.productsControllerUpdateVariant(
      vendorId: vendorId,
      productId: productId,
      variantId: variantId,
      updateProductVariantDto: updateProductVariantDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteVariant(
    String vendorId,
    String productId,
    String variantId,
  ) async {
    final response = await _productsApi.productsControllerRemoveVariant(
      vendorId: vendorId,
      productId: productId,
      variantId: variantId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> addOptionGroup(
    String vendorId,
    String productId,
    CreateOptionGroupDto createOptionGroupDto,
  ) async {
    final response = await _productsApi.productsControllerAddOptionGroup(
      vendorId: vendorId,
      productId: productId,
      createOptionGroupDto: createOptionGroupDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> addVariantOptionGroup(
    String vendorId,
    String productId,
    String variantId,
    CreateOptionGroupDto createOptionGroupDto,
  ) async {
    final response = await _productsApi.productsControllerAddVariantOptionGroup(
      vendorId: vendorId,
      productId: productId,
      variantId: variantId,
      createOptionGroupDto: createOptionGroupDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateOptionGroup(
    String vendorId,
    String productId,
    String groupId,
    UpdateOptionGroupDto updateOptionGroupDto,
  ) async {
    final response = await _productsApi.productsControllerUpdateOptionGroup(
      vendorId: vendorId,
      productId: productId,
      groupId: groupId,
      updateOptionGroupDto: updateOptionGroupDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteOptionGroup(
    String vendorId,
    String productId,
    String groupId,
  ) async {
    final response = await _productsApi.productsControllerRemoveOptionGroup(
      vendorId: vendorId,
      productId: productId,
      groupId: groupId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createOption(
    String vendorId,
    String productId,
    String groupId,
    CreateProductOptionDto createProductOptionDto,
  ) async {
    final response = await _productsApi.productsControllerAddOption(
      vendorId: vendorId,
      productId: productId,
      groupId: groupId,
      createProductOptionDto: createProductOptionDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> addOption(
    String vendorId,
    String productId,
    String groupId,
    CreateProductOptionDto createProductOptionDto,
  ) async => createOption(vendorId, productId, groupId, createProductOptionDto);

  Future<dynamic> updateOption(
    String vendorId,
    String productId,
    String groupId,
    String optionId,
    UpdateProductOptionDto updateProductOptionDto,
  ) async {
    final response = await _productsApi.productsControllerUpdateOption(
      vendorId: vendorId,
      productId: productId,
      groupId: groupId,
      optionId: optionId,
      updateProductOptionDto: updateProductOptionDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteOption(
    String vendorId,
    String productId,
    String groupId,
    String optionId,
  ) async {
    final response = await _productsApi.productsControllerRemoveOption(
      vendorId: vendorId,
      productId: productId,
      groupId: groupId,
      optionId: optionId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> menuCategoriesAdminUpdate({
    required String vendorId,
    required String categoryId,
    required UpdateMenuCategoryDto updateMenuCategoryDto,
  }) async {
    final response = await _menuApi.menuCategoriesControllerAdminUpdate(
      vendorId: vendorId,
      categoryId: categoryId,
      updateMenuCategoryDto: updateMenuCategoryDto,
    );
    return ResponseParser.parse(response);
  }

  // --- Promotions Proxy ---
  Future<dynamic> createPromotion(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/promotions/admin',
      data: data,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updatePromotion(
    String id,
    UpdatePromotionDto updatePromotionDto,
  ) async {
    final response = await _promotionsApi.promotionsControllerUpdate(
      id: id,
      updatePromotionDto: updatePromotionDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deletePromotion(String id) async {
    final response = await _promotionsApi.promotionsControllerRemove(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadPromotionImage(String id, MultipartFile? file) async {
    final response = await _promotionsApi.promotionsControllerUploadImage(
      id: id,
      file: file,
    );
    return ResponseParser.parse(response);
  }
}
