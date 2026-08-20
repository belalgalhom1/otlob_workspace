# api.api.StatisticsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**statisticsControllerGetAppStats**](StatisticsApi.md#statisticscontrollergetappstats) | **GET** /statistics/app | [Admin] Get platform-wide statistics
[**statisticsControllerGetDriverStats**](StatisticsApi.md#statisticscontrollergetdriverstats) | **GET** /statistics/drivers/{driverId} | [Admin] Get statistics for a specific driver
[**statisticsControllerGetMostOrderedProduct**](StatisticsApi.md#statisticscontrollergetmostorderedproduct) | **GET** /statistics/vendors/{vendorId}/most-ordered-product | Get the most ordered product for a vendor
[**statisticsControllerGetMyDriverStats**](StatisticsApi.md#statisticscontrollergetmydriverstats) | **GET** /statistics/driver/me | Get my driver statistics
[**statisticsControllerGetTopCustomers**](StatisticsApi.md#statisticscontrollergettopcustomers) | **GET** /statistics/analytics/customers | [Admin] Get top customers leaderboard
[**statisticsControllerGetTopDrivers**](StatisticsApi.md#statisticscontrollergettopdrivers) | **GET** /statistics/analytics/drivers | [Admin] Get top drivers leaderboard
[**statisticsControllerGetTopProducts**](StatisticsApi.md#statisticscontrollergettopproducts) | **GET** /statistics/analytics/products | [Admin] Get top products leaderboard
[**statisticsControllerGetTopVendors**](StatisticsApi.md#statisticscontrollergettopvendors) | **GET** /statistics/analytics/vendors | [Admin] Get top vendors leaderboard
[**statisticsControllerGetVendorStats**](StatisticsApi.md#statisticscontrollergetvendorstats) | **GET** /statistics/vendors/{vendorId} | Get vendor statistics (member or admin)


# **statisticsControllerGetAppStats**
> AuthControllerRegister200Response statisticsControllerGetAppStats()

[Admin] Get platform-wide statistics

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();

try {
    final response = api.statisticsControllerGetAppStats();
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetAppStats: $e\n');
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

# **statisticsControllerGetDriverStats**
> AuthControllerRegister200Response statisticsControllerGetDriverStats(driverId)

[Admin] Get statistics for a specific driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String driverId = driverId_example; // String | 

try {
    final response = api.statisticsControllerGetDriverStats(driverId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetDriverStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetMostOrderedProduct**
> AuthControllerRegister200Response statisticsControllerGetMostOrderedProduct(vendorId)

Get the most ordered product for a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.statisticsControllerGetMostOrderedProduct(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetMostOrderedProduct: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetMyDriverStats**
> AuthControllerRegister200Response statisticsControllerGetMyDriverStats()

Get my driver statistics

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();

try {
    final response = api.statisticsControllerGetMyDriverStats();
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetMyDriverStats: $e\n');
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

# **statisticsControllerGetTopCustomers**
> AuthControllerRegister200Response statisticsControllerGetTopCustomers(limit)

[Admin] Get top customers leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopCustomers(limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **num**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopDrivers**
> AuthControllerRegister200Response statisticsControllerGetTopDrivers(limit)

[Admin] Get top drivers leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopDrivers(limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **num**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopProducts**
> AuthControllerRegister200Response statisticsControllerGetTopProducts(limit)

[Admin] Get top products leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopProducts(limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopProducts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **num**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopVendors**
> AuthControllerRegister200Response statisticsControllerGetTopVendors(limit)

[Admin] Get top vendors leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopVendors(limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopVendors: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **num**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetVendorStats**
> AuthControllerRegister200Response statisticsControllerGetVendorStats(vendorId, period)

Get vendor statistics (member or admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String vendorId = vendorId_example; // String | 
final String period = period_example; // String | 

try {
    final response = api.statisticsControllerGetVendorStats(vendorId, period);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetVendorStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **period** | **String**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

