import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for DevicesPushNotificationsApi
void main() {
  final instance = Api().getDevicesPushNotificationsApi();

  group(DevicesPushNotificationsApi, () {
    // Register a device for push notifications
    //
    //Future<AuthControllerRegister200Response> devicesControllerRegister(RegisterDeviceDto registerDeviceDto) async
    test('test devicesControllerRegister', () async {
      // TODO
    });

    // Remove a device token
    //
    //Future<AuthControllerRegister200Response> devicesControllerRemove(String token) async
    test('test devicesControllerRemove', () async {
      // TODO
    });

  });
}
