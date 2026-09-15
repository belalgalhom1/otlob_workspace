# api.api.OffersApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**offersControllerCreate**](OffersApi.md#offerscontrollercreate) | **POST** /offers/admin | Create new product offer
[**offersControllerFindAll**](OffersApi.md#offerscontrollerfindall) | **GET** /offers/admin | Get all offers (Admin)
[**offersControllerFindAllActive**](OffersApi.md#offerscontrollerfindallactive) | **GET** /offers | Get all active product offers
[**offersControllerRemove**](OffersApi.md#offerscontrollerremove) | **DELETE** /offers/admin/{id} | Delete product offer
[**offersControllerUpdate**](OffersApi.md#offerscontrollerupdate) | **PATCH** /offers/admin/{id} | Update product offer


# **offersControllerCreate**
> ApiControllerRoot200Response offersControllerCreate(createOfferDto)

Create new product offer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOffersApi();
final CreateOfferDto createOfferDto = ; // CreateOfferDto | 

try {
    final response = api.offersControllerCreate(createOfferDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OffersApi->offersControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createOfferDto** | [**CreateOfferDto**](CreateOfferDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **offersControllerFindAll**
> ApiControllerRoot200Response offersControllerFindAll(vendorId)

Get all offers (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOffersApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.offersControllerFindAll(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OffersApi->offersControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **offersControllerFindAllActive**
> ApiControllerRoot200Response offersControllerFindAllActive()

Get all active product offers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOffersApi();

try {
    final response = api.offersControllerFindAllActive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling OffersApi->offersControllerFindAllActive: $e\n');
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

# **offersControllerRemove**
> ApiControllerRoot200Response offersControllerRemove(id)

Delete product offer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOffersApi();
final String id = id_example; // String | 

try {
    final response = api.offersControllerRemove(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OffersApi->offersControllerRemove: $e\n');
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

# **offersControllerUpdate**
> ApiControllerRoot200Response offersControllerUpdate(id, updateOfferDto)

Update product offer

### Example
```dart
import 'package:api/api.dart';

final api = Api().getOffersApi();
final String id = id_example; // String | 
final UpdateOfferDto updateOfferDto = ; // UpdateOfferDto | 

try {
    final response = api.offersControllerUpdate(id, updateOfferDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling OffersApi->offersControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateOfferDto** | [**UpdateOfferDto**](UpdateOfferDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

