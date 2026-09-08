import 'package:api/api.dart';
import 'response_parser.dart';

class SharedPlatformSettingsRepository {
  final PlatformSettingsVersioningApi _settingsApi;

  SharedPlatformSettingsRepository(this._settingsApi);

  Future<ApiControllerRoot200Response> getSettings() async {
    final response = await _settingsApi.platformSettingsControllerGetAll();
    return response.data!;
  }

  Future<void> checkAppVersion(AppVersionCheckDto dto) async {
    await _settingsApi.platformSettingsControllerCheckVersion(
      appVersionCheckDto: dto,
    );
  }

  Future<dynamic> getPublicSettings() async {
    final response = await _settingsApi.platformSettingsControllerGetPublic();
    return ResponseParser.parse(response);
  }
}
