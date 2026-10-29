# openapi.api.DriverManagersApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driverManagersControllerAssignDrivers**](DriverManagersApi.md#drivermanagerscontrollerassigndrivers) | **POST** /driver-managers/assign | [Admin] Assign drivers to a driver manager (all or specific). Each driver can be assigned to only one manager.
[**driverManagersControllerGetManagerDetails**](DriverManagersApi.md#drivermanagerscontrollergetmanagerdetails) | **GET** /driver-managers/{userId} | [Admin] Get driver manager details and assigned drivers
[**driverManagersControllerGetManagerDrivers**](DriverManagersApi.md#drivermanagerscontrollergetmanagerdrivers) | **GET** /driver-managers/{userId}/drivers | [Admin] Get drivers assigned to a driver manager
[**driverManagersControllerGetMyWallet**](DriverManagersApi.md#drivermanagerscontrollergetmywallet) | **GET** /driver-managers/me/wallet | Get my driver-manager wallet
[**driverManagersControllerGetTransactions**](DriverManagersApi.md#drivermanagerscontrollergettransactions) | **GET** /driver-managers/me/transactions | List my driver-manager wallet transactions
[**driverManagersControllerListManagers**](DriverManagersApi.md#drivermanagerscontrollerlistmanagers) | **GET** /driver-managers | [Admin] List all driver managers with assigned driver counts
[**driverManagersControllerUnassignDrivers**](DriverManagersApi.md#drivermanagerscontrollerunassigndrivers) | **POST** /driver-managers/{userId}/unassign | [Admin] Unassign specific drivers from a driver manager


# **driverManagersControllerAssignDrivers**
> ApiControllerRoot200Response driverManagersControllerAssignDrivers(assignDriversToManagerDto)

[Admin] Assign drivers to a driver manager (all or specific). Each driver can be assigned to only one manager.

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();
final AssignDriversToManagerDto assignDriversToManagerDto = ; // AssignDriversToManagerDto | 

try {
    final response = api.driverManagersControllerAssignDrivers(assignDriversToManagerDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerAssignDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assignDriversToManagerDto** | [**AssignDriversToManagerDto**](AssignDriversToManagerDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverManagersControllerGetManagerDetails**
> ApiControllerRoot200Response driverManagersControllerGetManagerDetails(userId)

[Admin] Get driver manager details and assigned drivers

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();
final String userId = userId_example; // String | 

try {
    final response = api.driverManagersControllerGetManagerDetails(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerGetManagerDetails: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverManagersControllerGetManagerDrivers**
> ApiControllerRoot200Response driverManagersControllerGetManagerDrivers(userId)

[Admin] Get drivers assigned to a driver manager

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();
final String userId = userId_example; // String | 

try {
    final response = api.driverManagersControllerGetManagerDrivers(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerGetManagerDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverManagersControllerGetMyWallet**
> ApiControllerRoot200Response driverManagersControllerGetMyWallet()

Get my driver-manager wallet

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();

try {
    final response = api.driverManagersControllerGetMyWallet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerGetMyWallet: $e\n');
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

# **driverManagersControllerGetTransactions**
> ApiControllerRoot200Response driverManagersControllerGetTransactions(page, limit)

List my driver-manager wallet transactions

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();
final num page = 8.14; // num | 
final num limit = 8.14; // num | 

try {
    final response = api.driverManagersControllerGetTransactions(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerGetTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | 
 **limit** | **num**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverManagersControllerListManagers**
> ApiControllerRoot200Response driverManagersControllerListManagers()

[Admin] List all driver managers with assigned driver counts

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();

try {
    final response = api.driverManagersControllerListManagers();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerListManagers: $e\n');
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

# **driverManagersControllerUnassignDrivers**
> ApiControllerRoot200Response driverManagersControllerUnassignDrivers(userId, unassignDriversFromManagerDto)

[Admin] Unassign specific drivers from a driver manager

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDriverManagersApi();
final String userId = userId_example; // String | 
final UnassignDriversFromManagerDto unassignDriversFromManagerDto = ; // UnassignDriversFromManagerDto | 

try {
    final response = api.driverManagersControllerUnassignDrivers(userId, unassignDriversFromManagerDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverManagersApi->driverManagersControllerUnassignDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **unassignDriversFromManagerDto** | [**UnassignDriversFromManagerDto**](UnassignDriversFromManagerDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

