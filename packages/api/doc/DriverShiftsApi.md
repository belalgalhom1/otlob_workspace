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
[**driverShiftsControllerDeleteShiftPool**](DriverShiftsApi.md#drivershiftscontrollerdeleteshiftpool) | **DELETE** /driver-shifts/admin/pools/{poolId} | [Admin] Delete a shift pool
[**driverShiftsControllerGenerateShiftPools**](DriverShiftsApi.md#drivershiftscontrollergenerateshiftpools) | **POST** /driver-shifts/admin/pools | [Admin] Generate shift pools for a date range
[**driverShiftsControllerGetAvailablePools**](DriverShiftsApi.md#drivershiftscontrollergetavailablepools) | **GET** /driver-shifts/available | Get available shift pools for booking
[**driverShiftsControllerGetShiftPools**](DriverShiftsApi.md#drivershiftscontrollergetshiftpools) | **GET** /driver-shifts/admin/pools | [Admin] Get shift pools
[**driverShiftsControllerGetSwapBoard**](DriverShiftsApi.md#drivershiftscontrollergetswapboard) | **GET** /driver-shifts/swap-board | View available swaps from other drivers
[**driverShiftsControllerOfferSwap**](DriverShiftsApi.md#drivershiftscontrollerofferswap) | **POST** /driver-shifts/{shiftId}/swap | Offer a shift to the swap board


# **driverShiftsControllerAcceptSwap**
> AuthControllerRegister200Response driverShiftsControllerAcceptSwap(swapId)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerAdminAssignShift**
> AuthControllerRegister200Response driverShiftsControllerAdminAssignShift(adminAssignShiftDto)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerBookOvertimeShift**
> AuthControllerRegister200Response driverShiftsControllerBookOvertimeShift(bookOvertimeShiftDto)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerBookWeeklyShifts**
> AuthControllerRegister200Response driverShiftsControllerBookWeeklyShifts(bookWeeklyShiftsDto)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerDeleteShiftPool**
> AuthControllerRegister200Response driverShiftsControllerDeleteShiftPool(poolId)

[Admin] Delete a shift pool

### Example
```dart
import 'package:api/api.dart';

final api = Api().getDriverShiftsApi();
final String poolId = poolId_example; // String | 

try {
    final response = api.driverShiftsControllerDeleteShiftPool(poolId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DriverShiftsApi->driverShiftsControllerDeleteShiftPool: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **poolId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGenerateShiftPools**
> AuthControllerRegister200Response driverShiftsControllerGenerateShiftPools(generateShiftPoolsDto)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetAvailablePools**
> AuthControllerRegister200Response driverShiftsControllerGetAvailablePools(zoneId)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetShiftPools**
> AuthControllerRegister200Response driverShiftsControllerGetShiftPools(date, zoneId)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerGetSwapBoard**
> AuthControllerRegister200Response driverShiftsControllerGetSwapBoard()

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverShiftsControllerOfferSwap**
> AuthControllerRegister200Response driverShiftsControllerOfferSwap(shiftId)

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

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

