# api.api.LogisticsZonesApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**zonesControllerCheckLocation**](LogisticsZonesApi.md#zonescontrollerchecklocation) | **POST** /zones/check-location | Find zone by coordinates
[**zonesControllerCreate**](LogisticsZonesApi.md#zonescontrollercreate) | **POST** /zones | Create a new delivery zone
[**zonesControllerFindAll**](LogisticsZonesApi.md#zonescontrollerfindall) | **GET** /zones | List all delivery zones
[**zonesControllerFindOne**](LogisticsZonesApi.md#zonescontrollerfindone) | **GET** /zones/{id} | Get a specific zone by ID
[**zonesControllerRemove**](LogisticsZonesApi.md#zonescontrollerremove) | **DELETE** /zones/{id} | Delete a delivery zone
[**zonesControllerSearchCustomers**](LogisticsZonesApi.md#zonescontrollersearchcustomers) | **POST** /zones/customers/search | Search for customers within a polygon
[**zonesControllerUpdate**](LogisticsZonesApi.md#zonescontrollerupdate) | **PATCH** /zones/{id} | Update a delivery zone


# **zonesControllerCheckLocation**
> ApiControllerRoot200Response zonesControllerCheckLocation(checkLocationDto)

Find zone by coordinates

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final CheckLocationDto checkLocationDto = ; // CheckLocationDto | 

try {
    final response = api.zonesControllerCheckLocation(checkLocationDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerCheckLocation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **checkLocationDto** | [**CheckLocationDto**](CheckLocationDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **zonesControllerCreate**
> ApiControllerRoot200Response zonesControllerCreate(createZoneDto)

Create a new delivery zone

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final CreateZoneDto createZoneDto = ; // CreateZoneDto | 

try {
    final response = api.zonesControllerCreate(createZoneDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createZoneDto** | [**CreateZoneDto**](CreateZoneDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **zonesControllerFindAll**
> ApiControllerRoot200Response zonesControllerFindAll()

List all delivery zones

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();

try {
    final response = api.zonesControllerFindAll();
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerFindAll: $e\n');
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

# **zonesControllerFindOne**
> ApiControllerRoot200Response zonesControllerFindOne(id)

Get a specific zone by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final String id = id_example; // String | 

try {
    final response = api.zonesControllerFindOne(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **zonesControllerRemove**
> ApiControllerRoot200Response zonesControllerRemove(id)

Delete a delivery zone

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final String id = id_example; // String | 

try {
    final response = api.zonesControllerRemove(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **zonesControllerSearchCustomers**
> ApiControllerRoot200Response zonesControllerSearchCustomers(searchCustomersInPolygonDto)

Search for customers within a polygon

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final SearchCustomersInPolygonDto searchCustomersInPolygonDto = ; // SearchCustomersInPolygonDto | 

try {
    final response = api.zonesControllerSearchCustomers(searchCustomersInPolygonDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerSearchCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **searchCustomersInPolygonDto** | [**SearchCustomersInPolygonDto**](SearchCustomersInPolygonDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **zonesControllerUpdate**
> ApiControllerRoot200Response zonesControllerUpdate(id, updateZoneDto)

Update a delivery zone

### Example
```dart
import 'package:api/api.dart';

final api = Api().getLogisticsZonesApi();
final String id = id_example; // String | 
final UpdateZoneDto updateZoneDto = ; // UpdateZoneDto | 

try {
    final response = api.zonesControllerUpdate(id, updateZoneDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LogisticsZonesApi->zonesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateZoneDto** | [**UpdateZoneDto**](UpdateZoneDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

