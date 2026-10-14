import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminPlatformSettingsRepository {
  final PlatformSettingsVersioningApi _api;
  final Dio? _dio;
  AdminPlatformSettingsRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<dynamic> platformSettingsUploadCarIcon({MultipartFile? file}) async {
    final response = await _api.platformSettingsControllerUploadCarIcon(file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsUploadDeliveryBannerIcon({MultipartFile? file}) async {
    final response = await _api.platformSettingsControllerUploadDeliveryBannerIcon(file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsGetPublic() async {
    final response = await _api.platformSettingsControllerGetPublic();
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsGetAll() async {
    final response = await _api.platformSettingsControllerGetAll();
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsUploadMotorcycleIcon({MultipartFile? file}) async {
    final response = await _api.platformSettingsControllerUploadMotorcycleIcon(file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsUploadVehicleIcon({
    required String vehicleType,
    required MultipartFile file,
  }) async {
    if (_dio == null) throw Exception('Dio is required');
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post(
      '/platform-settings/vehicle-icon/$vehicleType',
      data: formData,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsUpdate({required UpdatePlatformSettingsDto updatePlatformSettingsDto}) async {
    final response = await _api.platformSettingsControllerUpdate(updatePlatformSettingsDto: updatePlatformSettingsDto);
    return ResponseParser.parse(response);
  }

  /// Raw PATCH for settings keys the generated UpdatePlatformSettingsDto
  /// predates (driver break quotas). Only whitelisted break keys are sent.
  Future<dynamic> platformSettingsUpdateBreaks(Map<String, dynamic> data) async {
    if (_dio == null) throw Exception('Dio is required');
    const allowed = {
      'breaksEnabled',
      'maxBreakMinutesPerShift',
      'maxBreaksPerShift',
      'maxSingleBreakMinutes',
      'pendingBreakExpiryMins',
    };
    final payload = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => allowed.contains(e.key)),
    );
    if (payload.isEmpty) return null;
    final response = await _dio.patch('/platform-settings', data: payload);
    return ResponseParser.parse(response);
  }

  Future<dynamic> platformSettingsUploadHomeCover({MultipartFile? file}) async {
    final response = await _api.platformSettingsControllerUploadHomeCover(file: file);
    return ResponseParser.parse(response);
  }
}
