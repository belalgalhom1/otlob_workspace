import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminVendorBranchesRepository {
  final VendorsBranchesApi _api;
  AdminVendorBranchesRepository(this._api);

  Future<dynamic> createBranch(String vendorId, CreateVendorBranchDto createVendorBranchDto) async {
    final response = await _api.vendorBranchesControllerAdminCreate(
      vendorId: vendorId,
      createVendorBranchDto: createVendorBranchDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateBranch(String vendorId, String branchId, UpdateVendorBranchDto updateVendorBranchDto) async {
    final response = await _api.vendorBranchesControllerAdminUpdate(
      vendorId: vendorId, 
      branchId: branchId, 
      updateVendorBranchDto: updateVendorBranchDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteBranch(String vendorId, String branchId) async {
    final response = await _api.vendorBranchesControllerAdminRemove(vendorId: vendorId, branchId: branchId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getBranches(String vendorId) async {
    final response = await _api.vendorBranchesControllerFindAll(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getBranch(String vendorId, String branchId) async {
    final response = await _api.vendorBranchesControllerFindOne(vendorId: vendorId, branchId: branchId);
    return ResponseParser.parse(response);
  }
}