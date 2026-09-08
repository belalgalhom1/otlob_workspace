# api.api.DevicesPushNotificationsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**devicesControllerRegister**](DevicesPushNotificationsApi.md#devicescontrollerregister) | **POST** /devices | Register a device for push notifications
[**devicesControllerRemove**](DevicesPushNotificationsApi.md#devicescontrollerremove) | **DELETE** /devices/{token} | Remove a device token


# **devicesControllerRegister**
> ApiControllerRoot200Response devicesControllerRegister(registerDeviceDto)

Register a device for push notifications

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDevicesPushNotificationsApi();
final RegisterDeviceDto registerDeviceDto = ; // RegisterDeviceDto | 

try {
    final response = api.devicesControllerRegister(registerDeviceDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DevicesPushNotificationsApi->devicesControllerRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDeviceDto** | [**RegisterDeviceDto**](RegisterDeviceDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **devicesControllerRemove**
> ApiControllerRoot200Response devicesControllerRemove(token)

Remove a device token

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDevicesPushNotificationsApi();
final String token = token_example; // String | 

try {
    final response = api.devicesControllerRemove(token);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DevicesPushNotificationsApi->devicesControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

