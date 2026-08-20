import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsMenuCategoriesApi
void main() {
  final instance = Api().getVendorsMenuCategoriesApi();

  group(VendorsMenuCategoriesApi, () {
    // Create a new menu category (Admin Override)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerAdminCreate(String vendorId, CreateMenuCategoryDto createMenuCategoryDto) async
    test('test menuCategoriesControllerAdminCreate', () async {
      // TODO
    });

    // Delete a menu category (Admin Override)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerAdminRemove(String vendorId, String categoryId) async
    test('test menuCategoriesControllerAdminRemove', () async {
      // TODO
    });

    // Update a menu category (Admin Override)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerAdminUpdate(String vendorId, String categoryId, UpdateMenuCategoryDto updateMenuCategoryDto) async
    test('test menuCategoriesControllerAdminUpdate', () async {
      // TODO
    });

    // Upload menu category icon (Admin Override)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerAdminUploadIcon(String vendorId, String categoryId, { MultipartFile file }) async
    test('test menuCategoriesControllerAdminUploadIcon', () async {
      // TODO
    });

    // Create a new menu category (Member)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerCreate(String vendorId, CreateMenuCategoryDto createMenuCategoryDto) async
    test('test menuCategoriesControllerCreate', () async {
      // TODO
    });

    // List all menu categories for a vendor
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerFindAll(String vendorId, { bool activeOnly }) async
    test('test menuCategoriesControllerFindAll', () async {
      // TODO
    });

    // Get a specific menu category by ID
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerFindOne(String vendorId, String categoryId) async
    test('test menuCategoriesControllerFindOne', () async {
      // TODO
    });

    // Delete a menu category (Member)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerRemove(String vendorId, String categoryId) async
    test('test menuCategoriesControllerRemove', () async {
      // TODO
    });

    // Reorder menu categories
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerReorder(String vendorId, ReorderCategoriesDto reorderCategoriesDto) async
    test('test menuCategoriesControllerReorder', () async {
      // TODO
    });

    // Update a menu category (Member)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerUpdate(String vendorId, String categoryId, UpdateMenuCategoryDto updateMenuCategoryDto) async
    test('test menuCategoriesControllerUpdate', () async {
      // TODO
    });

    // Upload menu category icon (Member)
    //
    //Future<AuthControllerRegister200Response> menuCategoriesControllerUploadIcon(String vendorId, String categoryId, { MultipartFile file }) async
    test('test menuCategoriesControllerUploadIcon', () async {
      // TODO
    });

  });
}
