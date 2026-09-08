# api.api.PromotionsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**promotionsControllerCreate**](PromotionsApi.md#promotionscontrollercreate) | **POST** /promotions/admin | 
[**promotionsControllerFindAll**](PromotionsApi.md#promotionscontrollerfindall) | **GET** /promotions/admin | Get all promotions (Admin)
[**promotionsControllerFindAllActive**](PromotionsApi.md#promotionscontrollerfindallactive) | **GET** /promotions | Get all active promotions for customer app
[**promotionsControllerFindOne**](PromotionsApi.md#promotionscontrollerfindone) | **GET** /promotions/admin/{id} | 
[**promotionsControllerRemove**](PromotionsApi.md#promotionscontrollerremove) | **DELETE** /promotions/admin/{id} | 
[**promotionsControllerUpdate**](PromotionsApi.md#promotionscontrollerupdate) | **PATCH** /promotions/admin/{id} | 
[**promotionsControllerUploadImage**](PromotionsApi.md#promotionscontrolleruploadimage) | **POST** /promotions/admin/{id}/image | 


# **promotionsControllerCreate**
> ApiControllerRoot200Response promotionsControllerCreate(file)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.promotionsControllerCreate(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **promotionsControllerFindAll**
> ApiControllerRoot200Response promotionsControllerFindAll()

Get all promotions (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();

try {
    final response = api.promotionsControllerFindAll();
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerFindAll: $e\n');
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

# **promotionsControllerFindAllActive**
> ApiControllerRoot200Response promotionsControllerFindAllActive()

Get all active promotions for customer app

### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();

try {
    final response = api.promotionsControllerFindAllActive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerFindAllActive: $e\n');
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

# **promotionsControllerFindOne**
> ApiControllerRoot200Response promotionsControllerFindOne(id)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();
final String id = id_example; // String | 

try {
    final response = api.promotionsControllerFindOne(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerFindOne: $e\n');
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

# **promotionsControllerRemove**
> ApiControllerRoot200Response promotionsControllerRemove(id)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();
final String id = id_example; // String | 

try {
    final response = api.promotionsControllerRemove(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerRemove: $e\n');
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

# **promotionsControllerUpdate**
> ApiControllerRoot200Response promotionsControllerUpdate(id, updatePromotionDto)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();
final String id = id_example; // String | 
final UpdatePromotionDto updatePromotionDto = ; // UpdatePromotionDto | 

try {
    final response = api.promotionsControllerUpdate(id, updatePromotionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updatePromotionDto** | [**UpdatePromotionDto**](UpdatePromotionDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **promotionsControllerUploadImage**
> ApiControllerRoot200Response promotionsControllerUploadImage(id, file)



### Example
```dart
import 'package:api/api.dart';

final api = Api().getPromotionsApi();
final String id = id_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.promotionsControllerUploadImage(id, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PromotionsApi->promotionsControllerUploadImage: $e\n');
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

