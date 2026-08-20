# api.api.VendorsProductsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**productsControllerAddOption**](VendorsProductsApi.md#productscontrolleraddoption) | **POST** /vendors/{vendorId}/products/{productId}/option-groups/{groupId}/options | Add an option to a group
[**productsControllerAddOptionGroup**](VendorsProductsApi.md#productscontrolleraddoptiongroup) | **POST** /vendors/{vendorId}/products/{productId}/option-groups | Add an option group to a product
[**productsControllerAddVariant**](VendorsProductsApi.md#productscontrolleraddvariant) | **POST** /vendors/{vendorId}/products/{productId}/variants | Add a variant to a product
[**productsControllerAddVariantOptionGroup**](VendorsProductsApi.md#productscontrolleraddvariantoptiongroup) | **POST** /vendors/{vendorId}/products/{productId}/variants/{variantId}/option-groups | Add an option group to a product variant
[**productsControllerAdminCreate**](VendorsProductsApi.md#productscontrolleradmincreate) | **POST** /vendors/{vendorId}/products/admin | Create a new product (Admin Override)
[**productsControllerAdminRemove**](VendorsProductsApi.md#productscontrolleradminremove) | **DELETE** /vendors/{vendorId}/products/admin/{productId} | Delete a product (Admin Override)
[**productsControllerAdminUpdate**](VendorsProductsApi.md#productscontrolleradminupdate) | **PATCH** /vendors/{vendorId}/products/admin/{productId} | Update a product (Admin Override)
[**productsControllerCreate**](VendorsProductsApi.md#productscontrollercreate) | **POST** /vendors/{vendorId}/products | Create a new product (Member)
[**productsControllerFindAll**](VendorsProductsApi.md#productscontrollerfindall) | **GET** /vendors/{vendorId}/products | List all products for a vendor
[**productsControllerFindOne**](VendorsProductsApi.md#productscontrollerfindone) | **GET** /vendors/{vendorId}/products/{productId} | Get a specific product by ID
[**productsControllerRemove**](VendorsProductsApi.md#productscontrollerremove) | **DELETE** /vendors/{vendorId}/products/{productId} | Delete a product (Member)
[**productsControllerRemoveOption**](VendorsProductsApi.md#productscontrollerremoveoption) | **DELETE** /vendors/{vendorId}/products/{productId}/option-groups/{groupId}/options/{optionId} | Delete an option from a group
[**productsControllerRemoveOptionGroup**](VendorsProductsApi.md#productscontrollerremoveoptiongroup) | **DELETE** /vendors/{vendorId}/products/{productId}/option-groups/{groupId} | Delete a product option group
[**productsControllerRemoveVariant**](VendorsProductsApi.md#productscontrollerremovevariant) | **DELETE** /vendors/{vendorId}/products/{productId}/variants/{variantId} | Delete a product variant
[**productsControllerUpdate**](VendorsProductsApi.md#productscontrollerupdate) | **PATCH** /vendors/{vendorId}/products/{productId} | Update a product (Member)
[**productsControllerUpdateOption**](VendorsProductsApi.md#productscontrollerupdateoption) | **PATCH** /vendors/{vendorId}/products/{productId}/option-groups/{groupId}/options/{optionId} | Update an option in a group
[**productsControllerUpdateOptionGroup**](VendorsProductsApi.md#productscontrollerupdateoptiongroup) | **PATCH** /vendors/{vendorId}/products/{productId}/option-groups/{groupId} | Update a product option group
[**productsControllerUpdateVariant**](VendorsProductsApi.md#productscontrollerupdatevariant) | **PATCH** /vendors/{vendorId}/products/{productId}/variants/{variantId} | Update a product variant
[**productsControllerUploadImage**](VendorsProductsApi.md#productscontrolleruploadimage) | **POST** /vendors/{vendorId}/products/{productId}/image | Upload product image


# **productsControllerAddOption**
> AuthControllerRegister200Response productsControllerAddOption(vendorId, productId, groupId, createProductOptionDto)

Add an option to a group

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String groupId = groupId_example; // String | 
final CreateProductOptionDto createProductOptionDto = ; // CreateProductOptionDto | 

try {
    final response = api.productsControllerAddOption(vendorId, productId, groupId, createProductOptionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAddOption: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **groupId** | **String**|  | 
 **createProductOptionDto** | [**CreateProductOptionDto**](CreateProductOptionDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAddOptionGroup**
> AuthControllerRegister200Response productsControllerAddOptionGroup(vendorId, productId, createOptionGroupDto)

Add an option group to a product

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final CreateOptionGroupDto createOptionGroupDto = ; // CreateOptionGroupDto | 

try {
    final response = api.productsControllerAddOptionGroup(vendorId, productId, createOptionGroupDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAddOptionGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **createOptionGroupDto** | [**CreateOptionGroupDto**](CreateOptionGroupDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAddVariant**
> AuthControllerRegister200Response productsControllerAddVariant(vendorId, productId, createProductVariantDto)

Add a variant to a product

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final CreateProductVariantDto createProductVariantDto = ; // CreateProductVariantDto | 

try {
    final response = api.productsControllerAddVariant(vendorId, productId, createProductVariantDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAddVariant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **createProductVariantDto** | [**CreateProductVariantDto**](CreateProductVariantDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAddVariantOptionGroup**
> AuthControllerRegister200Response productsControllerAddVariantOptionGroup(vendorId, productId, variantId, createOptionGroupDto)

Add an option group to a product variant

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String variantId = variantId_example; // String | 
final CreateOptionGroupDto createOptionGroupDto = ; // CreateOptionGroupDto | 

try {
    final response = api.productsControllerAddVariantOptionGroup(vendorId, productId, variantId, createOptionGroupDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAddVariantOptionGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **variantId** | **String**|  | 
 **createOptionGroupDto** | [**CreateOptionGroupDto**](CreateOptionGroupDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAdminCreate**
> AuthControllerRegister200Response productsControllerAdminCreate(vendorId, createProductDto)

Create a new product (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final CreateProductDto createProductDto = ; // CreateProductDto | 

try {
    final response = api.productsControllerAdminCreate(vendorId, createProductDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createProductDto** | [**CreateProductDto**](CreateProductDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAdminRemove**
> AuthControllerRegister200Response productsControllerAdminRemove(vendorId, productId)

Delete a product (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 

try {
    final response = api.productsControllerAdminRemove(vendorId, productId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAdminRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerAdminUpdate**
> AuthControllerRegister200Response productsControllerAdminUpdate(vendorId, productId, updateProductDto)

Update a product (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final UpdateProductDto updateProductDto = ; // UpdateProductDto | 

try {
    final response = api.productsControllerAdminUpdate(vendorId, productId, updateProductDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **updateProductDto** | [**UpdateProductDto**](UpdateProductDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerCreate**
> AuthControllerRegister200Response productsControllerCreate(vendorId, createProductDto)

Create a new product (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final CreateProductDto createProductDto = ; // CreateProductDto | 

try {
    final response = api.productsControllerCreate(vendorId, createProductDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createProductDto** | [**CreateProductDto**](CreateProductDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerFindAll**
> AuthControllerRegister200Response productsControllerFindAll(vendorId, categoryId, isActive, isFeatured, search, page, limit)

List all products for a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String categoryId = 550e8400-e29b-41d4-a716-446655440000; // String | 
final bool isActive = true; // bool | 
final bool isFeatured = false; // bool | 
final String search = burger; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.productsControllerFindAll(vendorId, categoryId, isActive, isFeatured, search, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **categoryId** | **String**|  | [optional] 
 **isActive** | **bool**|  | [optional] 
 **isFeatured** | **bool**|  | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerFindOne**
> AuthControllerRegister200Response productsControllerFindOne(vendorId, productId)

Get a specific product by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 

try {
    final response = api.productsControllerFindOne(vendorId, productId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerRemove**
> AuthControllerRegister200Response productsControllerRemove(vendorId, productId)

Delete a product (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 

try {
    final response = api.productsControllerRemove(vendorId, productId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerRemoveOption**
> AuthControllerRegister200Response productsControllerRemoveOption(vendorId, productId, groupId, optionId)

Delete an option from a group

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String groupId = groupId_example; // String | 
final String optionId = optionId_example; // String | 

try {
    final response = api.productsControllerRemoveOption(vendorId, productId, groupId, optionId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerRemoveOption: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **groupId** | **String**|  | 
 **optionId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerRemoveOptionGroup**
> AuthControllerRegister200Response productsControllerRemoveOptionGroup(vendorId, productId, groupId)

Delete a product option group

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String groupId = groupId_example; // String | 

try {
    final response = api.productsControllerRemoveOptionGroup(vendorId, productId, groupId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerRemoveOptionGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **groupId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerRemoveVariant**
> AuthControllerRegister200Response productsControllerRemoveVariant(vendorId, productId, variantId)

Delete a product variant

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String variantId = variantId_example; // String | 

try {
    final response = api.productsControllerRemoveVariant(vendorId, productId, variantId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerRemoveVariant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **variantId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerUpdate**
> AuthControllerRegister200Response productsControllerUpdate(vendorId, productId, updateProductDto)

Update a product (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final UpdateProductDto updateProductDto = ; // UpdateProductDto | 

try {
    final response = api.productsControllerUpdate(vendorId, productId, updateProductDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **updateProductDto** | [**UpdateProductDto**](UpdateProductDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerUpdateOption**
> AuthControllerRegister200Response productsControllerUpdateOption(vendorId, productId, groupId, optionId, updateProductOptionDto)

Update an option in a group

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String groupId = groupId_example; // String | 
final String optionId = optionId_example; // String | 
final UpdateProductOptionDto updateProductOptionDto = ; // UpdateProductOptionDto | 

try {
    final response = api.productsControllerUpdateOption(vendorId, productId, groupId, optionId, updateProductOptionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerUpdateOption: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **groupId** | **String**|  | 
 **optionId** | **String**|  | 
 **updateProductOptionDto** | [**UpdateProductOptionDto**](UpdateProductOptionDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerUpdateOptionGroup**
> AuthControllerRegister200Response productsControllerUpdateOptionGroup(vendorId, productId, groupId, updateOptionGroupDto)

Update a product option group

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String groupId = groupId_example; // String | 
final UpdateOptionGroupDto updateOptionGroupDto = ; // UpdateOptionGroupDto | 

try {
    final response = api.productsControllerUpdateOptionGroup(vendorId, productId, groupId, updateOptionGroupDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerUpdateOptionGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **groupId** | **String**|  | 
 **updateOptionGroupDto** | [**UpdateOptionGroupDto**](UpdateOptionGroupDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerUpdateVariant**
> AuthControllerRegister200Response productsControllerUpdateVariant(vendorId, productId, variantId, updateProductVariantDto)

Update a product variant

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final String variantId = variantId_example; // String | 
final UpdateProductVariantDto updateProductVariantDto = ; // UpdateProductVariantDto | 

try {
    final response = api.productsControllerUpdateVariant(vendorId, productId, variantId, updateProductVariantDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerUpdateVariant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **variantId** | **String**|  | 
 **updateProductVariantDto** | [**UpdateProductVariantDto**](UpdateProductVariantDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **productsControllerUploadImage**
> AuthControllerRegister200Response productsControllerUploadImage(vendorId, productId, file)

Upload product image

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsProductsApi();
final String vendorId = vendorId_example; // String | 
final String productId = productId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.productsControllerUploadImage(vendorId, productId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsProductsApi->productsControllerUploadImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **productId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

