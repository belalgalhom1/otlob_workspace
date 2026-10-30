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
[**statisticsControllerGetVendorProductSales**](StatisticsApi.md#statisticscontrollergetvendorproductsales) | **GET** /statistics/vendors/{vendorId}/products | Get product-level sales and profit for a vendor (member or admin)
[**statisticsControllerGetVendorStats**](StatisticsApi.md#statisticscontrollergetvendorstats) | **GET** /statistics/vendors/{vendorId} | Get vendor statistics (member or admin)


# **statisticsControllerGetAppStats**
> ApiControllerRoot200Response statisticsControllerGetAppStats(to, from)

[Admin] Get platform-wide statistics

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | 
final JsonObject from = ; // JsonObject | 

try {
    final response = api.statisticsControllerGetAppStats(to, from);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetAppStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)|  | [optional] 
 **from** | [**JsonObject**](.md)|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetDriverStats**
> ApiControllerRoot200Response statisticsControllerGetDriverStats(driverId, to, from)

[Admin] Get statistics for a specific driver

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String driverId = driverId_example; // String | 
final JsonObject to = ; // JsonObject | 
final JsonObject from = ; // JsonObject | 

try {
    final response = api.statisticsControllerGetDriverStats(driverId, to, from);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetDriverStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **to** | [**JsonObject**](.md)|  | [optional] 
 **from** | [**JsonObject**](.md)|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetMostOrderedProduct**
> ApiControllerRoot200Response statisticsControllerGetMostOrderedProduct(vendorId)

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

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetMyDriverStats**
> ApiControllerRoot200Response statisticsControllerGetMyDriverStats(to, from)

Get my driver statistics

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | 
final JsonObject from = ; // JsonObject | 

try {
    final response = api.statisticsControllerGetMyDriverStats(to, from);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetMyDriverStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)|  | [optional] 
 **from** | [**JsonObject**](.md)|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopCustomers**
> ApiControllerRoot200Response statisticsControllerGetTopCustomers(to, from, limit)

[Admin] Get top customers leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | ISO date (inclusive)
final JsonObject from = ; // JsonObject | ISO date (inclusive)
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopCustomers(to, from, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **from** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **limit** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopDrivers**
> ApiControllerRoot200Response statisticsControllerGetTopDrivers(to, from, limit)

[Admin] Get top drivers leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | ISO date (inclusive)
final JsonObject from = ; // JsonObject | ISO date (inclusive)
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopDrivers(to, from, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **from** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **limit** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopProducts**
> ApiControllerRoot200Response statisticsControllerGetTopProducts(to, from, limit)

[Admin] Get top products leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | ISO date (inclusive)
final JsonObject from = ; // JsonObject | ISO date (inclusive)
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopProducts(to, from, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopProducts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **from** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **limit** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetTopVendors**
> ApiControllerRoot200Response statisticsControllerGetTopVendors(to, from, limit)

[Admin] Get top vendors leaderboard

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final JsonObject to = ; // JsonObject | ISO date (inclusive)
final JsonObject from = ; // JsonObject | ISO date (inclusive)
final num limit = 8.14; // num | 

try {
    final response = api.statisticsControllerGetTopVendors(to, from, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetTopVendors: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **to** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **from** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **limit** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetVendorProductSales**
> ApiControllerRoot200Response statisticsControllerGetVendorProductSales(vendorId, sortOrder, sortBy, branchId, search, limit, page, to, from)

Get product-level sales and profit for a vendor (member or admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String vendorId = vendorId_example; // String | 
final String sortOrder = sortOrder_example; // String | 
final String sortBy = sortBy_example; // String | 
final JsonObject branchId = ; // JsonObject | Filter sales by specific branch UUID
final JsonObject search = ; // JsonObject | 
final num limit = 8.14; // num | 
final num page = 8.14; // num | 
final JsonObject to = ; // JsonObject | ISO date (inclusive)
final JsonObject from = ; // JsonObject | ISO date (inclusive)

try {
    final response = api.statisticsControllerGetVendorProductSales(vendorId, sortOrder, sortBy, branchId, search, limit, page, to, from);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetVendorProductSales: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **sortOrder** | **String**|  | [optional] 
 **sortBy** | **String**|  | [optional] 
 **branchId** | [**JsonObject**](.md)| Filter sales by specific branch UUID | [optional] 
 **search** | [**JsonObject**](.md)|  | [optional] 
 **limit** | **num**|  | [optional] 
 **page** | **num**|  | [optional] 
 **to** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 
 **from** | [**JsonObject**](.md)| ISO date (inclusive) | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **statisticsControllerGetVendorStats**
> ApiControllerRoot200Response statisticsControllerGetVendorStats(vendorId, to, from, period)

Get vendor statistics (member or admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getStatisticsApi();
final String vendorId = vendorId_example; // String | 
final JsonObject to = ; // JsonObject | 
final JsonObject from = ; // JsonObject | 
final String period = period_example; // String | 

try {
    final response = api.statisticsControllerGetVendorStats(vendorId, to, from, period);
    print(response);
} on DioException catch (e) {
    print('Exception when calling StatisticsApi->statisticsControllerGetVendorStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **to** | [**JsonObject**](.md)|  | [optional] 
 **from** | [**JsonObject**](.md)|  | [optional] 
 **period** | **String**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

