import 'package:api/api.dart';
import '../shared/response_parser.dart';

class VendorMembersRepository {
  final VendorsMembersTeamApi _api;
  VendorMembersRepository(this._api);

  Future<dynamic> getMembers(String vendorId) async {
    final response = await _api.vendorMembersControllerFindAll(vendorId: vendorId);
    return ResponseParser.parseList(response);
  }

  Future<dynamic> addMember(String vendorId, AddVendorMemberDto addVendorMemberDto) async {
    final response = await _api.vendorMembersControllerAddMember(
      vendorId: vendorId,
      addVendorMemberDto: addVendorMemberDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> adminAddMember(String vendorId, AddVendorMemberDto addVendorMemberDto) async {
    final response = await _api.vendorMembersControllerAdminAddMember(
      vendorId: vendorId,
      addVendorMemberDto: addVendorMemberDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateRole(String vendorId, String memberId, UpdateVendorMemberRoleDto updateVendorMemberRoleDto) async {
    final response = await _api.vendorMembersControllerUpdateRole(
      vendorId: vendorId,
      memberId: memberId,
      updateVendorMemberRoleDto: updateVendorMemberRoleDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeMember(String vendorId, String memberId) async {
    final response = await _api.vendorMembersControllerRemoveMember(
      vendorId: vendorId,
      memberId: memberId
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> adminRemoveMember(String vendorId, String memberId) async {
    final response = await _api.vendorMembersControllerAdminRemoveMember(
      vendorId: vendorId,
      memberId: memberId
    );
    return ResponseParser.parse(response);
  }
}
