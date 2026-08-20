import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for UsersApi
void main() {
  final instance = Api().getUsersApi();

  group(UsersApi, () {
    // [Admin] Ban a user — immediately revokes all sessions. Cannot ban SUPER_ADMIN.
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminBan(String userId, BanUserDto banUserDto) async
    test('test usersControllerAdminBan', () async {
      // TODO
    });

    // [Admin] Create a new user directly
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminCreate(RegisterDto registerDto) async
    test('test usersControllerAdminCreate', () async {
      // TODO
    });

    // [Admin] List all users — filter by role, isBanned, includeDeleted, search
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminFindAll({ String role, bool isBanned, bool includeDeleted, String search, num page, num limit }) async
    test('test usersControllerAdminFindAll', () async {
      // TODO
    });

    // [Admin] Get a user — includes sessions, devices, vendor memberships, customer/driver snapshots
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminFindOne(String userId) async
    test('test usersControllerAdminFindOne', () async {
      // TODO
    });

    // [Admin] List active sessions for a user
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminGetSessions(String userId) async
    test('test usersControllerAdminGetSessions', () async {
      // TODO
    });

    // [Admin] Soft-delete a user — wipes email/phone PII. Cannot delete SUPER_ADMIN.
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminRemove(String userId) async
    test('test usersControllerAdminRemove', () async {
      // TODO
    });

    // [Admin] Revoke all sessions for a user (force logout)
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminRevokeAllSessions(String userId) async
    test('test usersControllerAdminRevokeAllSessions', () async {
      // TODO
    });

    // [Admin] Unban a user
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminUnban(String userId) async
    test('test usersControllerAdminUnban', () async {
      // TODO
    });

    // [Admin] Update a user — name, email, phone, role, title, permissions, verification flags
    //
    //Future<AuthControllerRegister200Response> usersControllerAdminUpdate(String userId, AdminUpdateUserDto adminUpdateUserDto) async
    test('test usersControllerAdminUpdate', () async {
      // TODO
    });

    // Change my password
    //
    //Future<AuthControllerRegister200Response> usersControllerChangePassword(ChangePasswordDto changePasswordDto) async
    test('test usersControllerChangePassword', () async {
      // TODO
    });

    // Delete my account
    //
    //Future<AuthControllerRegister200Response> usersControllerDeleteAccount() async
    test('test usersControllerDeleteAccount', () async {
      // TODO
    });

    // Get my notification settings
    //
    //Future<AuthControllerRegister200Response> usersControllerGetNotificationSettings() async
    test('test usersControllerGetNotificationSettings', () async {
      // TODO
    });

    // Get my profile
    //
    //Future<AuthControllerRegister200Response> usersControllerGetUser() async
    test('test usersControllerGetUser', () async {
      // TODO
    });

    // Update my notification settings
    //
    //Future<AuthControllerRegister200Response> usersControllerUpdateNotificationSettings(UpdateNotificationSettingsDto updateNotificationSettingsDto) async
    test('test usersControllerUpdateNotificationSettings', () async {
      // TODO
    });

    // Update my profile (name, email, phone, language)
    //
    //Future<AuthControllerRegister200Response> usersControllerUpdateUser(UpdateUserDto updateUserDto) async
    test('test usersControllerUpdateUser', () async {
      // TODO
    });

    // Upload my avatar
    //
    //Future<AuthControllerRegister200Response> usersControllerUploadAvatar({ MultipartFile file }) async
    test('test usersControllerUploadAvatar', () async {
      // TODO
    });

  });
}
