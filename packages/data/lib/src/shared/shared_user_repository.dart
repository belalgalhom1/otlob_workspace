import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'response_parser.dart';

class SharedUserRepository {
  final UsersApi _api;
  SharedUserRepository(this._api);

  Future<dynamic> getUser() async {
    final response = await _api.usersControllerGetUser();
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateUser(UpdateUserDto updateUserDto) async {
    final response = await _api.usersControllerUpdateUser(
      updateUserDto: updateUserDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> changePassword(String currentPassword, String newPassword) async {
    final response = await _api.usersControllerChangePassword(
      changePasswordDto: ChangePasswordDto((b) => b
        ..currentPassword = currentPassword
        ..newPassword = newPassword
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadAvatar(MultipartFile file) async {
    final response = await _api.usersControllerUploadAvatar(file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteAccount() async {
    final response = await _api.usersControllerDeleteAccount();
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateNotificationSettings(UpdateNotificationSettingsDto dto) async {
    final response = await _api.usersControllerUpdateNotificationSettings(updateNotificationSettingsDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getNotificationSettings() async {
    final response = await _api.usersControllerGetNotificationSettings();
    return ResponseParser.parse(response);
  }
}
