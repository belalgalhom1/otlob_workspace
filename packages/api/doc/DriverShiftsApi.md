# api.api.DriverShiftsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driverShiftsControllerAcceptSwap**](DriverShiftsApi.md#drivershiftscontrolleracceptswap) | **POST** /driver-shifts/swap/{swapId}/accept | Claim someone else&#39;s shift from the swap board
[**driverShiftsControllerAdminAssignShift**](DriverShiftsApi.md#drivershiftscontrolleradminassignshift) | **POST** /driver-shifts/admin/assign | [Admin] Force-assign a driver to a shift pool
[**driverShiftsControllerBookOvertimeShift**](DriverShiftsApi.md#drivershiftscontrollerbookovertimeshift) | **POST** /driver-shifts/book-overtime | Book a single extra shift
[**driverShiftsControllerBookWeeklyShifts**](DriverShiftsApi.md#drivershiftscontrollerbookweeklyshifts) | **POST** /driver-shifts/book-week | Book 6 shifts for the week
[**driverShiftsControllerGenerateShiftPools**](DriverShiftsApi.md#drivershiftscontrollergenerateshiftpools) | **POST** /driver-shifts/admin/pools | [Admin] Generate shift pools for a date range
[**driverShiftsControllerGetAvailablePools**](DriverShiftsApi.md#drivershiftscontrollergetavailablepools) | **GET** /driver-shifts/available | Get available shift pools for booking
[**driverShiftsControllerGetShiftPools**](DriverShiftsApi.md#drivershiftscontrollergetshiftpools) | **GET** /driver-shifts/admin/pools | [Admin] Get shift pools
[**driverShiftsControllerGetSwapBoard**](DriverShiftsApi.md#drivershiftscontrollergetswapboard) | **GET** /driver-shifts/swap-board | View available swaps from other drivers
[**driverShiftsControllerOfferSwap**](DriverShiftsApi.md#drivershiftscontrollerofferswap) | **POST** /driver-shifts/{shiftId}/swap | Offer a shift to the swap board
[**driverShiftsControllerTerminateShiftPool**](DriverShiftsApi.md#drivershiftscontrollerterminateshiftpool) | **DELETE** /driver-shifts/admin/pools/{poolId} | [Admin] Terminate/Delete a shift pool


# **driverShiftsControllerAcceptSwap**
> ApiControllerRoot200Response driverShiftsControllerAcceptSwap(swapId)

Claim someone else's shift from the swap board

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String swapId = swapId_example; // String | 

try {
    final response = api.driverShiftsControllerAcceptSwap(swapId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerAcceptSwap: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **swapId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerAdminAssignShift**
> ApiControllerRoot200Response driverShiftsControllerAdminAssignShift(adminAssignShiftDto)

[Admin] Force-assign a driver to a shift pool

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final AdminAssignShiftDto adminAssignShiftDto = ; // AdminAssignShiftDto | 

try {
    final response = api.driverShiftsControllerAdminAssignShift(adminAssignShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerAdminAssignShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminAssignShiftDto** | [**AdminAssignShiftDto**](AdminAssignShiftDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerBookOvertimeShift**
> ApiControllerRoot200Response driverShiftsControllerBookOvertimeShift(bookOvertimeShiftDto)

Book a single extra shift

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final BookOvertimeShiftDto bookOvertimeShiftDto = ; // BookOvertimeShiftDto | 

try {
    final response = api.driverShiftsControllerBookOvertimeShift(bookOvertimeShiftDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerBookOvertimeShift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bookOvertimeShiftDto** | [**BookOvertimeShiftDto**](BookOvertimeShiftDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerBookWeeklyShifts**
> ApiControllerRoot200Response driverShiftsControllerBookWeeklyShifts(bookWeeklyShiftsDto)

Book 6 shifts for the week

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final BookWeeklyShiftsDto bookWeeklyShiftsDto = ; // BookWeeklyShiftsDto | 

try {
    final response = api.driverShiftsControllerBookWeeklyShifts(bookWeeklyShiftsDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerBookWeeklyShifts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bookWeeklyShiftsDto** | [**BookWeeklyShiftsDto**](BookWeeklyShiftsDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGenerateShiftPools**
> ApiControllerRoot200Response driverShiftsControllerGenerateShiftPools(generateShiftPoolsDto)

[Admin] Generate shift pools for a date range

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final GenerateShiftPoolsDto generateShiftPoolsDto = ; // GenerateShiftPoolsDto | 

try {
    final response = api.driverShiftsControllerGenerateShiftPools(generateShiftPoolsDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerGenerateShiftPools: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **generateShiftPoolsDto** | [**GenerateShiftPoolsDto**](GenerateShiftPoolsDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetAvailablePools**
> ApiControllerRoot200Response driverShiftsControllerGetAvailablePools(zoneId)

Get available shift pools for booking

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String zoneId = zoneId_example; // String | 

try {
    final response = api.driverShiftsControllerGetAvailablePools(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerGetAvailablePools: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetShiftPools**
> ApiControllerRoot200Response driverShiftsControllerGetShiftPools(date, zoneId)

[Admin] Get shift pools

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String date = 2026-05-10; // String | 
final String zoneId = zone-uuid; // String | 

try {
    final response = api.driverShiftsControllerGetShiftPools(date, zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerGetShiftPools: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **String**|  | [optional] 
 **zoneId** | **String**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetSwapBoard**
> ApiControllerRoot200Response driverShiftsControllerGetSwapBoard()

View available swaps from other drivers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();

try {
    final response = api.driverShiftsControllerGetSwapBoard();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerGetSwapBoard: $e\n');
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

# **driverShiftsControllerOfferSwap**
> ApiControllerRoot200Response driverShiftsControllerOfferSwap(shiftId)

Offer a shift to the swap board

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String shiftId = shiftId_example; // String | 

try {
    final response = api.driverShiftsControllerOfferSwap(shiftId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerOfferSwap: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shiftId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerTerminateShiftPool**
> ApiControllerRoot200Response driverShiftsControllerTerminateShiftPool(poolId)

[Admin] Terminate/Delete a shift pool

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String poolId = poolId_example; // String | 

try {
    final response = api.driverShiftsControllerTerminateShiftPool(poolId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerTerminateShiftPool: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **poolId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

