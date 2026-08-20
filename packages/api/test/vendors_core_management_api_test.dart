import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsCoreManagementApi
void main() {
  final instance = Api().getVendorsCoreManagementApi();

  group(VendorsCoreManagementApi, () {
    // Create a new vendor (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorsControllerCreate(CreateVendorDto createVendorDto) async
    test('test vendorsControllerCreate', () async {
      // TODO
    });

    // List all vendors with filters
    //
    //Future<AuthControllerRegister200Response> vendorsControllerFindAll({ String status, String verticalId, String search, num page, num limit }) async
    test('test vendorsControllerFindAll', () async {
      // TODO
    });

    // Find a vendor by its slug
    //
    //Future<AuthControllerRegister200Response> vendorsControllerFindBySlug(String slug) async
    test('test vendorsControllerFindBySlug', () async {
      // TODO
    });

    // Get a specific vendor by ID
    //
    //Future<AuthControllerRegister200Response> vendorsControllerFindOne(String vendorId) async
    test('test vendorsControllerFindOne', () async {
      // TODO
    });

    // Get my vendor profile (Member)
    //
    //Future<AuthControllerRegister200Response> vendorsControllerGetMyVendor(String vendorId) async
    test('test vendorsControllerGetMyVendor', () async {
      // TODO
    });

    // Delete a vendor (Admin)
    //
    //Future<AuthControllerRegister200Response> vendorsControllerRemove(String vendorId) async
    test('test vendorsControllerRemove', () async {
      // TODO
    });

    // Global discovery search for vendors and products
    //
    //Future<AuthControllerRegister200Response> vendorsControllerSearchDiscovery({ String status, String verticalId, String search, num page, num limit }) async
    test('test vendorsControllerSearchDiscovery', () async {
      // TODO
    });

    // Update vendor information
    //
    //Future<AuthControllerRegister200Response> vendorsControllerUpdate(String vendorId, UpdateVendorDto updateVendorDto) async
    test('test vendorsControllerUpdate', () async {
      // TODO
    });

    // Update vendor status
    //
    //Future<AuthControllerRegister200Response> vendorsControllerUpdateStatus(String vendorId, UpdateVendorStatusDto updateVendorStatusDto) async
    test('test vendorsControllerUpdateStatus', () async {
      // TODO
    });

    // Upload vendor cover image
    //
    //Future<AuthControllerRegister200Response> vendorsControllerUploadCover(String vendorId, { MultipartFile file }) async
    test('test vendorsControllerUploadCover', () async {
      // TODO
    });

    // Upload vendor logo image
    //
    //Future<AuthControllerRegister200Response> vendorsControllerUploadLogo(String vendorId, { MultipartFile file }) async
    test('test vendorsControllerUploadLogo', () async {
      // TODO
    });

  });
}
