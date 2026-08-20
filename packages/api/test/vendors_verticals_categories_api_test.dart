import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsVerticalsCategoriesApi
void main() {
  final instance = Api().getVendorsVerticalsCategoriesApi();

  group(VendorsVerticalsCategoriesApi, () {
    // Create a new vendor vertical (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerCreate(CreateVendorVerticalDto createVendorVerticalDto) async
    test('test vendorVerticalsControllerCreate', () async {
      // TODO
    });

    // Get all vendor verticals (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerFindAll() async
    test('test vendorVerticalsControllerFindAll', () async {
      // TODO
    });

    // Get all active vendor verticals
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerFindAllActive() async
    test('test vendorVerticalsControllerFindAllActive', () async {
      // TODO
    });

    // Get a specific vendor vertical by ID
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerFindOne(String id) async
    test('test vendorVerticalsControllerFindOne', () async {
      // TODO
    });

    // Delete a vendor vertical (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerRemove(String id) async
    test('test vendorVerticalsControllerRemove', () async {
      // TODO
    });

    // Update a vendor vertical (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerUpdate(String id, UpdateVendorVerticalDto updateVendorVerticalDto) async
    test('test vendorVerticalsControllerUpdate', () async {
      // TODO
    });

    // Upload vertical icon image
    //
    //Future<AuthControllerRegister200Response> vendorVerticalsControllerUploadIcon(String id, { MultipartFile file }) async
    test('test vendorVerticalsControllerUploadIcon', () async {
      // TODO
    });

  });
}
