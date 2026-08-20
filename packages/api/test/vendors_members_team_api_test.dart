import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for VendorsMembersTeamApi
void main() {
  final instance = Api().getVendorsMembersTeamApi();

  group(VendorsMembersTeamApi, () {
    // Add a new member to the vendor
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerAddMember(String vendorId, AddVendorMemberDto addVendorMemberDto) async
    test('test vendorMembersControllerAddMember', () async {
      // TODO
    });

    // Add a new member to a vendor (Admin Override)
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerAdminAddMember(String vendorId, AddVendorMemberDto addVendorMemberDto) async
    test('test vendorMembersControllerAdminAddMember', () async {
      // TODO
    });

    // Remove a member from a vendor (Admin Override)
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerAdminRemoveMember(String vendorId, String memberId) async
    test('test vendorMembersControllerAdminRemoveMember', () async {
      // TODO
    });

    // List all members of a vendor
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerFindAll(String vendorId) async
    test('test vendorMembersControllerFindAll', () async {
      // TODO
    });

    // Remove a member from the vendor
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerRemoveMember(String vendorId, String memberId) async
    test('test vendorMembersControllerRemoveMember', () async {
      // TODO
    });

    // Update a member's role
    //
    //Future<AuthControllerRegister200Response> vendorMembersControllerUpdateRole(String vendorId, String memberId, UpdateVendorMemberRoleDto updateVendorMemberRoleDto) async
    test('test vendorMembersControllerUpdateRole', () async {
      // TODO
    });

  });
}
