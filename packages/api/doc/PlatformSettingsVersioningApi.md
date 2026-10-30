# api.api.PlatformSettingsVersioningApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**platformSettingsControllerCheckVersion**](PlatformSettingsVersioningApi.md#platformsettingscontrollercheckversion) | **POST** /platform-settings/app-version-check | Check if app version is supported
[**platformSettingsControllerGetAll**](PlatformSettingsVersioningApi.md#platformsettingscontrollergetall) | **GET** /platform-settings | Get all platform settings (Admin)
[**platformSettingsControllerGetPublic**](PlatformSettingsVersioningApi.md#platformsettingscontrollergetpublic) | **GET** /platform-settings/public | Get public platform settings (maintenance mode, versions)
[**platformSettingsControllerUpdate**](PlatformSettingsVersioningApi.md#platformsettingscontrollerupdate) | **PATCH** /platform-settings | Update platform settings (Admin)
[**platformSettingsControllerUploadCarIcon**](PlatformSettingsVersioningApi.md#platformsettingscontrolleruploadcaricon) | **POST** /platform-settings/car-icon | Upload car icon
[**platformSettingsControllerUploadDeliveryBannerIcon**](PlatformSettingsVersioningApi.md#platformsettingscontrolleruploaddeliverybannericon) | **POST** /platform-settings/delivery-banner-icon | Upload delivery banner icon
[**platformSettingsControllerUploadHomeCover**](PlatformSettingsVersioningApi.md#platformsettingscontrolleruploadhomecover) | **POST** /platform-settings/home-cover | Upload home cover image
[**platformSettingsControllerUploadMotorcycleIcon**](PlatformSettingsVersioningApi.md#platformsettingscontrolleruploadmotorcycleicon) | **POST** /platform-settings/motorcycle-icon | Upload motorcycle icon
[**platformSettingsControllerUploadVehicleIcon**](PlatformSettingsVersioningApi.md#platformsettingscontrolleruploadvehicleicon) | **POST** /platform-settings/vehicle-icon/{vehicleType} | Upload vehicle type icon (bicycle|motorcycle|motor_tricycle|car|van|truck)


# **platformSettingsControllerCheckVersion**
> ApiControllerRoot200Response platformSettingsControllerCheckVersion(appVersionCheckDto)

Check if app version is supported

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final AppVersionCheckDto appVersionCheckDto = ; // AppVersionCheckDto | 

try {
    final response = api.platformSettingsControllerCheckVersion(appVersionCheckDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerCheckVersion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appVersionCheckDto** | [**AppVersionCheckDto**](AppVersionCheckDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerGetAll**
> ApiControllerRoot200Response platformSettingsControllerGetAll()

Get all platform settings (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();

try {
    final response = api.platformSettingsControllerGetAll();
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerGetAll: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerGetPublic**
> ApiControllerRoot200Response platformSettingsControllerGetPublic()

Get public platform settings (maintenance mode, versions)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();

try {
    final response = api.platformSettingsControllerGetPublic();
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerGetPublic: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUpdate**
> ApiControllerRoot200Response platformSettingsControllerUpdate(updatePlatformSettingsDto)

Update platform settings (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final UpdatePlatformSettingsDto updatePlatformSettingsDto = ; // UpdatePlatformSettingsDto | 

try {
    final response = api.platformSettingsControllerUpdate(updatePlatformSettingsDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updatePlatformSettingsDto** | [**UpdatePlatformSettingsDto**](UpdatePlatformSettingsDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUploadCarIcon**
> ApiControllerRoot200Response platformSettingsControllerUploadCarIcon(file)

Upload car icon

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.platformSettingsControllerUploadCarIcon(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUploadCarIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUploadDeliveryBannerIcon**
> ApiControllerRoot200Response platformSettingsControllerUploadDeliveryBannerIcon(file)

Upload delivery banner icon

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.platformSettingsControllerUploadDeliveryBannerIcon(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUploadDeliveryBannerIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUploadHomeCover**
> ApiControllerRoot200Response platformSettingsControllerUploadHomeCover(file)

Upload home cover image

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.platformSettingsControllerUploadHomeCover(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUploadHomeCover: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUploadMotorcycleIcon**
> ApiControllerRoot200Response platformSettingsControllerUploadMotorcycleIcon(file)

Upload motorcycle icon

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.platformSettingsControllerUploadMotorcycleIcon(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUploadMotorcycleIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **platformSettingsControllerUploadVehicleIcon**
> ApiControllerRoot200Response platformSettingsControllerUploadVehicleIcon(vehicleType, file)

Upload vehicle type icon (bicycle|motorcycle|motor_tricycle|car|van|truck)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPlatformSettingsVersioningApi();
final String vehicleType = vehicleType_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.platformSettingsControllerUploadVehicleIcon(vehicleType, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PlatformSettingsVersioningApi->platformSettingsControllerUploadVehicleIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleType** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

