import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminUsersRepository {
  final UsersApi _usersApi;

  AdminUsersRepository(this._usersApi);

  Future<dynamic> banUser(String userId, String reason) async {
    final response = await _usersApi.usersControllerAdminBan(
      userId: userId,
      banUserDto: BanUserDto((b) => b..reason = reason),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> unbanUser(String userId) async {
    final response = await _usersApi.usersControllerAdminUnban(userId: userId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateUserRole(String userId, String role) async {
    final response = await _usersApi.usersControllerAdminUpdate(
      userId: userId,
      adminUpdateUserDto: AdminUpdateUserDto(
        (b) => b..role = AdminUpdateUserDtoRoleEnum.valueOf(role.toUpperCase()),
      ),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> revokeAllSessions(String userId) async {
    final response = await _usersApi.usersControllerAdminRevokeAllSessions(
      userId: userId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getSessions(String userId) async {
    final response = await _usersApi.usersControllerAdminGetSessions(
      userId: userId,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getUsers({
    String? role,
    bool? isBanned,
    bool? includeDeleted,
    String? search,
    num? page = 1,
    num? limit = 20,
  }) async {
    final response = await _usersApi.usersControllerAdminFindAll(
      role: role,
      isBanned: isBanned,
      includeDeleted: includeDeleted,
      search: search,
      page: page,
      limit: limit,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getUser(String userId) async {
    final response = await _usersApi.usersControllerAdminFindOne(
      userId: userId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> addUser(RegisterDto registerDto) async {
    final response = await _usersApi.usersControllerAdminCreate(
      registerDto: registerDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateUser(
    String id,
    AdminUpdateUserDto adminUpdateUserDto,
  ) async {
    final response = await _usersApi.usersControllerAdminUpdate(
      userId: id,
      adminUpdateUserDto: adminUpdateUserDto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteUser(String id) async {
    final response = await _usersApi.usersControllerAdminRemove(userId: id);
    return ResponseParser.parse(response);
  }

}
