# api.api.DriversApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driversControllerAdminCreate**](DriversApi.md#driverscontrolleradmincreate) | **POST** /drivers/admin | [Admin] Create a new driver directly
[**driversControllerAdminCreateShift**](DriversApi.md#driverscontrolleradmincreateshift) | **POST** /drivers/{driverId}/shifts | [Admin] Create a shift for a driver
[**driversControllerAdminFindAll**](DriversApi.md#driverscontrolleradminfindall) | **GET** /drivers | [Admin] List all drivers
[**driversControllerAdminFindOne**](DriversApi.md#driverscontrolleradminfindone) | **GET** /drivers/{driverId} | [Admin] Get a driver by ID
[**driversControllerAdminGetShifts**](DriversApi.md#driverscontrolleradmingetshifts) | **GET** /drivers/{driverId}/shifts | [Admin] Get shifts for a driver
[**driversControllerAdminSuspend**](DriversApi.md#driverscontrolleradminsuspend) | **POST** /drivers/{driverId}/suspend | [Admin] Suspend a driver
[**driversControllerAdminUnsuspend**](DriversApi.md#driverscontrolleradminunsuspend) | **POST** /drivers/{driverId}/unsuspend | [Admin] Unsuspend a driver
[**driversControllerAdminUpdate**](DriversApi.md#driverscontrolleradminupdate) | **PATCH** /drivers/{driverId}/admin | [Admin] Update driver profile and sensitive fields
[**driversControllerCreateShift**](DriversApi.md#driverscontrollercreateshift) | **POST** /drivers/me/shifts | Create a shift
[**driversControllerEndShift**](DriversApi.md#driverscontrollerendshift) | **POST** /drivers/me/shifts/{shiftId}/end | End a shift
[**driversControllerGetMyProfile**](DriversApi.md#driverscontrollergetmyprofile) | **GET** /drivers/me | Get my driver profile
[**driversControllerGetMyShifts**](DriversApi.md#driverscontrollergetmyshifts) | **GET** /drivers/me/shifts | Get my shifts
[**driversControllerGetWalletBalance**](DriversApi.md#driverscontrollergetwalletbalance) | **GET** /drivers/me/wallet | Get wallet balance
[**driversControllerGetWalletTransactions**](DriversApi.md#driverscontrollergetwallettransactions) | **GET** /drivers/me/wallet/transactions | Get wallet transaction history
[**driversControllerRegister**](DriversApi.md#driverscontrollerregister) | **POST** /drivers/register | Register as a driver (creates driver profile, upgrades role)
[**driversControllerStartShift**](DriversApi.md#driverscontrollerstartshift) | **POST** /drivers/me/shifts/{shiftId}/start | Start a shift
[**driversControllerUpdateProfile**](DriversApi.md#driverscontrollerupdateprofile) | **PATCH** /drivers/me | Update my driver profile
[**driversControllerUpdateStatus**](DriversApi.md#driverscontrollerupdatestatus) | **PATCH** /drivers/me/status | Update driver status (ONLINE / OFFLINE / ON_BREAK)
[**driversControllerUploadAvatar**](DriversApi.md#driverscontrolleruploadavatar) | **POST** /drivers/me/avatar | Upload driver avatar


# **driversControllerAdminCreate**
> DriversControllerRegister200Response driversControllerAdminCreate(adminCreateDriverDto)

[Admin] Create a new driver directly

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final AdminCreateDriverDto adminCreateDriverDto = ; // AdminCreateDriverDto | 

try {
    final response = api.driversControllerAdminCreate(adminCreateDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminCreateDriverDto** | [**AdminCreateDriverDto**](AdminCreateDriverDto.md)|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminCreateShift**
> DriversControllerGetMyShifts200Response driversControllerAdminCreateShift(driverId, createDriverShiftDto)

[Admin] Create a shift for a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 
final CreateDriverShiftDto createDriverShiftDto = ; // CreateDriverShiftDto | 

try {
    final response = api.driversControllerAdminCreateShift(driverId, createDriverShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminCreateShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **createDriverShiftDto** | [**CreateDriverShiftDto**](CreateDriverShiftDto.md)|  | 

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminFindAll**
> DriversControllerRegister200Response driversControllerAdminFindAll(status, search, page, limit)

[Admin] List all drivers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String status = status_example; // String | 
final String search = ahmed; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.driversControllerAdminFindAll(status, search, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminFindOne**
> DriversControllerRegister200Response driversControllerAdminFindOne(driverId)

[Admin] Get a driver by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminFindOne(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminGetShifts**
> DriversControllerGetMyShifts200Response driversControllerAdminGetShifts(driverId)

[Admin] Get shifts for a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminGetShifts(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminGetShifts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminSuspend**
> DriversControllerRegister200Response driversControllerAdminSuspend(driverId)

[Admin] Suspend a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminSuspend(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminSuspend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminUnsuspend**
> DriversControllerRegister200Response driversControllerAdminUnsuspend(driverId)

[Admin] Unsuspend a driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.driversControllerAdminUnsuspend(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminUnsuspend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerAdminUpdate**
> DriversControllerRegister200Response driversControllerAdminUpdate(driverId, adminUpdateDriverDto)

[Admin] Update driver profile and sensitive fields

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String driverId = driverId_example; // String | 
final AdminUpdateDriverDto adminUpdateDriverDto = ; // AdminUpdateDriverDto | 

try {
    final response = api.driversControllerAdminUpdate(driverId, adminUpdateDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **adminUpdateDriverDto** | [**AdminUpdateDriverDto**](AdminUpdateDriverDto.md)|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerCreateShift**
> DriversControllerGetMyShifts200Response driversControllerCreateShift(createDriverShiftDto)

Create a shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final CreateDriverShiftDto createDriverShiftDto = ; // CreateDriverShiftDto | 

try {
    final response = api.driversControllerCreateShift(createDriverShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerCreateShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createDriverShiftDto** | [**CreateDriverShiftDto**](CreateDriverShiftDto.md)|  | 

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerEndShift**
> DriversControllerGetMyShifts200Response driversControllerEndShift(shiftId)

End a shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String shiftId = shiftId_example; // String | 

try {
    final response = api.driversControllerEndShift(shiftId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerEndShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetMyProfile**
> DriversControllerRegister200Response driversControllerGetMyProfile()

Get my driver profile

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetMyProfile();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetMyProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetMyShifts**
> DriversControllerGetMyShifts200Response driversControllerGetMyShifts()

Get my shifts

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetMyShifts();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetMyShifts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetWalletBalance**
> AuthControllerRegister200Response driversControllerGetWalletBalance()

Get wallet balance

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();

try {
    final response = api.driversControllerGetWalletBalance();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetWalletBalance: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerGetWalletTransactions**
> DriversControllerGetWalletTransactions200Response driversControllerGetWalletTransactions(page, limit)

Get wallet transaction history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.driversControllerGetWalletTransactions(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerGetWalletTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**DriversControllerGetWalletTransactions200Response**](DriversControllerGetWalletTransactions200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerRegister**
> DriversControllerRegister200Response driversControllerRegister(registerDriverDto)

Register as a driver (creates driver profile, upgrades role)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final RegisterDriverDto registerDriverDto = ; // RegisterDriverDto | 

try {
    final response = api.driversControllerRegister(registerDriverDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDriverDto** | [**RegisterDriverDto**](RegisterDriverDto.md)|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerStartShift**
> DriversControllerGetMyShifts200Response driversControllerStartShift(shiftId)

Start a shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final String shiftId = shiftId_example; // String | 

try {
    final response = api.driversControllerStartShift(shiftId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerStartShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 

### Return type

[**DriversControllerGetMyShifts200Response**](DriversControllerGetMyShifts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUpdateProfile**
> DriversControllerRegister200Response driversControllerUpdateProfile(updateDriverProfileDto)

Update my driver profile

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final UpdateDriverProfileDto updateDriverProfileDto = ; // UpdateDriverProfileDto | 

try {
    final response = api.driversControllerUpdateProfile(updateDriverProfileDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUpdateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDriverProfileDto** | [**UpdateDriverProfileDto**](UpdateDriverProfileDto.md)|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUpdateStatus**
> DriversControllerRegister200Response driversControllerUpdateStatus(updateDriverStatusDto)

Update driver status (ONLINE / OFFLINE / ON_BREAK)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final UpdateDriverStatusDto updateDriverStatusDto = ; // UpdateDriverStatusDto | 

try {
    final response = api.driversControllerUpdateStatus(updateDriverStatusDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDriverStatusDto** | [**UpdateDriverStatusDto**](UpdateDriverStatusDto.md)|  | 

### Return type

[**DriversControllerRegister200Response**](DriversControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversControllerUploadAvatar**
> AuthControllerRegister200Response driversControllerUploadAvatar(file)

Upload driver avatar

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriversApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.driversControllerUploadAvatar(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriversApi->driversControllerUploadAvatar: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

