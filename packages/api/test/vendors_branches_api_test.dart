import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsBranchesApi
void main() {
  final instance = Api().getVendorsBranchesApi();

  group(VendorsBranchesApi, () {
    // Create a new branch (Admin Override)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerAdminCreate(String vendorId, CreateVendorBranchDto createVendorBranchDto) async
    test('test vendorBranchesControllerAdminCreate', () async {
      // TODO
    });

    // Delete a branch (Admin Override)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerAdminRemove(String vendorId, String branchId) async
    test('test vendorBranchesControllerAdminRemove', () async {
      // TODO
    });

    // Update a branch (Admin Override)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerAdminUpdate(String vendorId, String branchId, UpdateVendorBranchDto updateVendorBranchDto) async
    test('test vendorBranchesControllerAdminUpdate', () async {
      // TODO
    });

    // Create a new branch (Member)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerCreate(String vendorId, CreateVendorBranchDto createVendorBranchDto) async
    test('test vendorBranchesControllerCreate', () async {
      // TODO
    });

    // List all branches for a vendor
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerFindAll(String vendorId) async
    test('test vendorBranchesControllerFindAll', () async {
      // TODO
    });

    // Get a specific branch by ID
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerFindOne(String vendorId, String branchId) async
    test('test vendorBranchesControllerFindOne', () async {
      // TODO
    });

    // Delete a branch (Member)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerRemove(String vendorId, String branchId) async
    test('test vendorBranchesControllerRemove', () async {
      // TODO
    });

    // Update a branch (Member)
    //
    //Future<AuthControllerRegister200Response> vendorBranchesControllerUpdate(String vendorId, String branchId, UpdateVendorBranchDto updateVendorBranchDto) async
    test('test vendorBranchesControllerUpdate', () async {
      // TODO
    });

  });
}
