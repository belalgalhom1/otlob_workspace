import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class DriverProfileRepository {
  final DriversApi _api;
  DriverProfileRepository(this._api);

  Future<dynamic> getMyProfile() async {
    final response = await _api.driversControllerGetMyProfile();
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateProfile(UpdateDriverProfileDto updateDriverProfileDto) async {
    final response = await _api.driversControllerUpdateProfile(
      updateDriverProfileDto: updateDriverProfileDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateStatus(String status) async {
    final response = await _api.driversControllerUpdateStatus(
      updateDriverStatusDto: UpdateDriverStatusDto((b) => b
        ..status = UpdateDriverStatusDtoStatusEnum.valueOf(status.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> registerDriver(RegisterDriverDto registerDriverDto) async {
    final response = await _api.driversControllerRegister(
      registerDriverDto: registerDriverDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadAvatar(MultipartFile file) async {
    final response = await _api.driversControllerUploadAvatar(file: file);
    return ResponseParser.parse(response);
  }
}
