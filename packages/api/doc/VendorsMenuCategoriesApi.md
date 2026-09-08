# api.api.VendorsMenuCategoriesApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**menuCategoriesControllerAdminCreate**](VendorsMenuCategoriesApi.md#menucategoriescontrolleradmincreate) | **POST** /vendors/{vendorId}/categories/admin | Create a new menu category (Admin Override)
[**menuCategoriesControllerAdminRemove**](VendorsMenuCategoriesApi.md#menucategoriescontrolleradminremove) | **DELETE** /vendors/{vendorId}/categories/admin/{categoryId} | Delete a menu category (Admin Override)
[**menuCategoriesControllerAdminUpdate**](VendorsMenuCategoriesApi.md#menucategoriescontrolleradminupdate) | **PATCH** /vendors/{vendorId}/categories/admin/{categoryId} | Update a menu category (Admin Override)
[**menuCategoriesControllerAdminUploadIcon**](VendorsMenuCategoriesApi.md#menucategoriescontrolleradminuploadicon) | **POST** /vendors/{vendorId}/categories/admin/{categoryId}/icon | Upload menu category icon (Admin Override)
[**menuCategoriesControllerCreate**](VendorsMenuCategoriesApi.md#menucategoriescontrollercreate) | **POST** /vendors/{vendorId}/categories | Create a new menu category (Member)
[**menuCategoriesControllerFindAll**](VendorsMenuCategoriesApi.md#menucategoriescontrollerfindall) | **GET** /vendors/{vendorId}/categories | List all menu categories for a vendor
[**menuCategoriesControllerFindOne**](VendorsMenuCategoriesApi.md#menucategoriescontrollerfindone) | **GET** /vendors/{vendorId}/categories/{categoryId} | Get a specific menu category by ID
[**menuCategoriesControllerRemove**](VendorsMenuCategoriesApi.md#menucategoriescontrollerremove) | **DELETE** /vendors/{vendorId}/categories/{categoryId} | Delete a menu category (Member)
[**menuCategoriesControllerReorder**](VendorsMenuCategoriesApi.md#menucategoriescontrollerreorder) | **PATCH** /vendors/{vendorId}/categories/reorder | Reorder menu categories
[**menuCategoriesControllerUpdate**](VendorsMenuCategoriesApi.md#menucategoriescontrollerupdate) | **PATCH** /vendors/{vendorId}/categories/{categoryId} | Update a menu category (Member)
[**menuCategoriesControllerUploadIcon**](VendorsMenuCategoriesApi.md#menucategoriescontrolleruploadicon) | **POST** /vendors/{vendorId}/categories/{categoryId}/icon | Upload menu category icon (Member)


# **menuCategoriesControllerAdminCreate**
> ApiControllerRoot200Response menuCategoriesControllerAdminCreate(vendorId, createMenuCategoryDto)

Create a new menu category (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final CreateMenuCategoryDto createMenuCategoryDto = ; // CreateMenuCategoryDto | 

try {
    final response = api.menuCategoriesControllerAdminCreate(vendorId, createMenuCategoryDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createMenuCategoryDto** | [**CreateMenuCategoryDto**](CreateMenuCategoryDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerAdminRemove**
> ApiControllerRoot200Response menuCategoriesControllerAdminRemove(vendorId, categoryId)

Delete a menu category (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 

try {
    final response = api.menuCategoriesControllerAdminRemove(vendorId, categoryId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerAdminRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerAdminUpdate**
> ApiControllerRoot200Response menuCategoriesControllerAdminUpdate(vendorId, categoryId, updateMenuCategoryDto)

Update a menu category (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 
final UpdateMenuCategoryDto updateMenuCategoryDto = ; // UpdateMenuCategoryDto | 

try {
    final response = api.menuCategoriesControllerAdminUpdate(vendorId, categoryId, updateMenuCategoryDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 
 **updateMenuCategoryDto** | [**UpdateMenuCategoryDto**](UpdateMenuCategoryDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerAdminUploadIcon**
> ApiControllerRoot200Response menuCategoriesControllerAdminUploadIcon(vendorId, categoryId, file)

Upload menu category icon (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.menuCategoriesControllerAdminUploadIcon(vendorId, categoryId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerAdminUploadIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerCreate**
> ApiControllerRoot200Response menuCategoriesControllerCreate(vendorId, createMenuCategoryDto)

Create a new menu category (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final CreateMenuCategoryDto createMenuCategoryDto = ; // CreateMenuCategoryDto | 

try {
    final response = api.menuCategoriesControllerCreate(vendorId, createMenuCategoryDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createMenuCategoryDto** | [**CreateMenuCategoryDto**](CreateMenuCategoryDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerFindAll**
> ApiControllerRoot200Response menuCategoriesControllerFindAll(vendorId, activeOnly)

List all menu categories for a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final bool activeOnly = true; // bool | 

try {
    final response = api.menuCategoriesControllerFindAll(vendorId, activeOnly);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **activeOnly** | **bool**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerFindOne**
> ApiControllerRoot200Response menuCategoriesControllerFindOne(vendorId, categoryId)

Get a specific menu category by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 

try {
    final response = api.menuCategoriesControllerFindOne(vendorId, categoryId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerRemove**
> ApiControllerRoot200Response menuCategoriesControllerRemove(vendorId, categoryId)

Delete a menu category (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 

try {
    final response = api.menuCategoriesControllerRemove(vendorId, categoryId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerReorder**
> ApiControllerRoot200Response menuCategoriesControllerReorder(vendorId, reorderCategoriesDto)

Reorder menu categories

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final ReorderCategoriesDto reorderCategoriesDto = ; // ReorderCategoriesDto | 

try {
    final response = api.menuCategoriesControllerReorder(vendorId, reorderCategoriesDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerReorder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **reorderCategoriesDto** | [**ReorderCategoriesDto**](ReorderCategoriesDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerUpdate**
> ApiControllerRoot200Response menuCategoriesControllerUpdate(vendorId, categoryId, updateMenuCategoryDto)

Update a menu category (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 
final UpdateMenuCategoryDto updateMenuCategoryDto = ; // UpdateMenuCategoryDto | 

try {
    final response = api.menuCategoriesControllerUpdate(vendorId, categoryId, updateMenuCategoryDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 
 **updateMenuCategoryDto** | [**UpdateMenuCategoryDto**](UpdateMenuCategoryDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **menuCategoriesControllerUploadIcon**
> ApiControllerRoot200Response menuCategoriesControllerUploadIcon(vendorId, categoryId, file)

Upload menu category icon (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsMenuCategoriesApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = categoryId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.menuCategoriesControllerUploadIcon(vendorId, categoryId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsMenuCategoriesApi->menuCategoriesControllerUploadIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

