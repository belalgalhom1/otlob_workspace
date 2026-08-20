import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for PlatformSettingsVersioningApi
void main() {
  final instance = Api().getPlatformSettingsVersioningApi();

  group(PlatformSettingsVersioningApi, () {
    // Check if app version is supported
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerCheckVersion(AppVersionCheckDto appVersionCheckDto) async
    test('test platformSettingsControllerCheckVersion', () async {
      // TODO
    });

    // Get all platform settings (Admin)
    //
    //Future<PlatformSettingsControllerGetAll200Response> platformSettingsControllerGetAll() async
    test('test platformSettingsControllerGetAll', () async {
      // TODO
    });

    // Get public platform settings (maintenance mode, versions)
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerGetPublic() async
    test('test platformSettingsControllerGetPublic', () async {
      // TODO
    });

    // Update platform settings (Admin)
    //
    //Future<PlatformSettingsControllerGetAll200Response> platformSettingsControllerUpdate(UpdatePlatformSettingsDto updatePlatformSettingsDto) async
    test('test platformSettingsControllerUpdate', () async {
      // TODO
    });

    // Upload car icon
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerUploadCarIcon({ MultipartFile file }) async
    test('test platformSettingsControllerUploadCarIcon', () async {
      // TODO
    });

    // Upload delivery banner icon
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerUploadDeliveryBannerIcon({ MultipartFile file }) async
    test('test platformSettingsControllerUploadDeliveryBannerIcon', () async {
      // TODO
    });

    // Upload home cover image
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerUploadHomeCover({ MultipartFile file }) async
    test('test platformSettingsControllerUploadHomeCover', () async {
      // TODO
    });

    // Upload motorcycle icon
    //
    //Future<AuthControllerRegister200Response> platformSettingsControllerUploadMotorcycleIcon({ MultipartFile file }) async
    test('test platformSettingsControllerUploadMotorcycleIcon', () async {
      // TODO
    });

  });
}
