# api.api.VendorsVerticalsCategoriesApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorVerticalsControllerCreate**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollercreate) | **POST** /vendor-verticals | Create a new vendor vertical (Admin)
[**vendorVerticalsControllerFindAll**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollerfindall) | **GET** /vendor-verticals/admin | Get all vendor verticals (Admin)
[**vendorVerticalsControllerFindAllActive**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollerfindallactive) | **GET** /vendor-verticals | Get all active vendor verticals
[**vendorVerticalsControllerFindOne**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollerfindone) | **GET** /vendor-verticals/{id} | Get a specific vendor vertical by ID
[**vendorVerticalsControllerRemove**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollerremove) | **DELETE** /vendor-verticals/{id} | Delete a vendor vertical (Admin)
[**vendorVerticalsControllerUpdate**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrollerupdate) | **PATCH** /vendor-verticals/{id} | Update a vendor vertical (Admin)
[**vendorVerticalsControllerUploadIcon**](VendorsVerticalsCategoriesApi.md#vendorverticalscontrolleruploadicon) | **POST** /vendor-verticals/admin/{id}/icon | Upload vertical icon image


# **vendorVerticalsControllerCreate**
> ApiControllerRoot200Response vendorVerticalsControllerCreate(createVendorVerticalDto)

Create a new vendor vertical (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();
final CreateVendorVerticalDto createVendorVerticalDto = ; // CreateVendorVerticalDto | 

try {
    final response = api.vendorVerticalsControllerCreate(createVendorVerticalDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createVendorVerticalDto** | [**CreateVendorVerticalDto**](CreateVendorVerticalDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorVerticalsControllerFindAll**
> ApiControllerRoot200Response vendorVerticalsControllerFindAll()

Get all vendor verticals (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();

try {
    final response = api.vendorVerticalsControllerFindAll();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerFindAll: $e\n');
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

# **vendorVerticalsControllerFindAllActive**
> ApiControllerRoot200Response vendorVerticalsControllerFindAllActive()

Get all active vendor verticals

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();

try {
    final response = api.vendorVerticalsControllerFindAllActive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerFindAllActive: $e\n');
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

# **vendorVerticalsControllerFindOne**
> ApiControllerRoot200Response vendorVerticalsControllerFindOne(id)

Get a specific vendor vertical by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();
final String id = id_example; // String | 

try {
    final response = api.vendorVerticalsControllerFindOne(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorVerticalsControllerRemove**
> ApiControllerRoot200Response vendorVerticalsControllerRemove(id)

Delete a vendor vertical (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();
final String id = id_example; // String | 

try {
    final response = api.vendorVerticalsControllerRemove(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerRemove: $e\n');
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

# **vendorVerticalsControllerUpdate**
> ApiControllerRoot200Response vendorVerticalsControllerUpdate(id, updateVendorVerticalDto)

Update a vendor vertical (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();
final String id = id_example; // String | 
final UpdateVendorVerticalDto updateVendorVerticalDto = ; // UpdateVendorVerticalDto | 

try {
    final response = api.vendorVerticalsControllerUpdate(id, updateVendorVerticalDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateVendorVerticalDto** | [**UpdateVendorVerticalDto**](UpdateVendorVerticalDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorVerticalsControllerUploadIcon**
> ApiControllerRoot200Response vendorVerticalsControllerUploadIcon(id, file)

Upload vertical icon image

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsVerticalsCategoriesApi();
final String id = id_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.vendorVerticalsControllerUploadIcon(id, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsVerticalsCategoriesApi->vendorVerticalsControllerUploadIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

