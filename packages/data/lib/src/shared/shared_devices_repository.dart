import 'package:api/api.dart';
import 'response_parser.dart';

class SharedDevicesRepository {
  final DevicesPushNotificationsApi _api;
  SharedDevicesRepository(this._api);

  Future<dynamic> registerDevice(String token, String platform) async {
    final response = await _api.devicesControllerRegister(
      registerDeviceDto: RegisterDeviceDto((b) => b
        ..token = token
        ..platform = RegisterDeviceDtoPlatformEnum.valueOf(platform.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeDevice(String fcmToken) async {
    final response = await _api.devicesControllerRemove(
      token: fcmToken
    );
    return ResponseParser.parse(response);
  }
}
