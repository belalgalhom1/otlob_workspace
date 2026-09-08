# api.api.CustomersApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customersControllerAdminDisableOrdering**](CustomersApi.md#customerscontrolleradmindisableordering) | **POST** /customers/{customerId}/disable-ordering | [Admin] Prevent customer from placing orders (canOrder → false)
[**customersControllerAdminEnableOrdering**](CustomersApi.md#customerscontrolleradminenableordering) | **POST** /customers/{customerId}/enable-ordering | [Admin] Allow customer to place orders (canOrder → true)
[**customersControllerAdminFindAll**](CustomersApi.md#customerscontrolleradminfindall) | **GET** /customers | [Admin] List all customers — filter by canOrder, includeDeleted, search
[**customersControllerAdminFindByUserId**](CustomersApi.md#customerscontrolleradminfindbyuserid) | **GET** /customers/by-user/{userId} | [Admin] Get a customer by their userId
[**customersControllerAdminFindOne**](CustomersApi.md#customerscontrolleradminfindone) | **GET** /customers/{customerId} | [Admin] Get a customer — includes counts + last 5 orders
[**customersControllerAdminGetAddresses**](CustomersApi.md#customerscontrolleradmingetaddresses) | **GET** /customers/{customerId}/addresses | [Admin] List a customer&#39;s saved addresses
[**customersControllerAdminGetOrders**](CustomersApi.md#customerscontrolleradmingetorders) | **GET** /customers/{customerId}/orders | [Admin] List a customer&#39;s full order history (paginated)
[**customersControllerAdminRemove**](CustomersApi.md#customerscontrolleradminremove) | **DELETE** /customers/{customerId} | [Admin] Hard-delete a customer (cascades to addresses, carts, favorites). Parent User is untouched.
[**customersControllerCreateAddress**](CustomersApi.md#customerscontrollercreateaddress) | **POST** /customers/me/addresses | Add a new address
[**customersControllerDeleteAddress**](CustomersApi.md#customerscontrollerdeleteaddress) | **DELETE** /customers/me/addresses/{id} | Delete an address
[**customersControllerGetAddresses**](CustomersApi.md#customerscontrollergetaddresses) | **GET** /customers/me/addresses | Get my addresses
[**customersControllerGetCoinHistory**](CustomersApi.md#customerscontrollergetcoinhistory) | **GET** /customers/me/coins/history | Get coin transaction history
[**customersControllerGetFavorites**](CustomersApi.md#customerscontrollergetfavorites) | **GET** /customers/me/favorites | Get my favorites (vendors + products)
[**customersControllerToggleFavoriteProduct**](CustomersApi.md#customerscontrollertogglefavoriteproduct) | **POST** /customers/me/favorites/products/{productId} | Toggle product favorite
[**customersControllerToggleFavoriteVendor**](CustomersApi.md#customerscontrollertogglefavoritevendor) | **POST** /customers/me/favorites/vendors/{vendorId} | Toggle vendor favorite
[**customersControllerUpdateAddress**](CustomersApi.md#customerscontrollerupdateaddress) | **PATCH** /customers/me/addresses/{id} | Update an address


# **customersControllerAdminDisableOrdering**
> ApiControllerRoot200Response customersControllerAdminDisableOrdering(customerId)

[Admin] Prevent customer from placing orders (canOrder → false)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 

try {
    final response = api.customersControllerAdminDisableOrdering(customerId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminDisableOrdering: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminEnableOrdering**
> ApiControllerRoot200Response customersControllerAdminEnableOrdering(customerId)

[Admin] Allow customer to place orders (canOrder → true)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 

try {
    final response = api.customersControllerAdminEnableOrdering(customerId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminEnableOrdering: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminFindAll**
> ApiControllerRoot200Response customersControllerAdminFindAll(canOrder, includeDeleted, search, page, limit)

[Admin] List all customers — filter by canOrder, includeDeleted, search

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final bool canOrder = true; // bool | Filter by canOrder flag
final bool includeDeleted = false; // bool | Include soft-deleted customer records
final String search = ahmed; // String | Search by user name, email, or phone
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.customersControllerAdminFindAll(canOrder, includeDeleted, search, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **canOrder** | **bool**| Filter by canOrder flag | [optional] 
 **includeDeleted** | **bool**| Include soft-deleted customer records | [optional] 
 **search** | **String**| Search by user name, email, or phone | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminFindByUserId**
> ApiControllerRoot200Response customersControllerAdminFindByUserId(userId)

[Admin] Get a customer by their userId

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String userId = userId_example; // String | 

try {
    final response = api.customersControllerAdminFindByUserId(userId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminFindByUserId: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminFindOne**
> ApiControllerRoot200Response customersControllerAdminFindOne(customerId)

[Admin] Get a customer — includes counts + last 5 orders

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 

try {
    final response = api.customersControllerAdminFindOne(customerId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminGetAddresses**
> ApiControllerRoot200Response customersControllerAdminGetAddresses(customerId)

[Admin] List a customer's saved addresses

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 

try {
    final response = api.customersControllerAdminGetAddresses(customerId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminGetAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminGetOrders**
> ApiControllerRoot200Response customersControllerAdminGetOrders(customerId, page, limit)

[Admin] List a customer's full order history (paginated)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.customersControllerAdminGetOrders(customerId, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminGetOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerAdminRemove**
> ApiControllerRoot200Response customersControllerAdminRemove(customerId)

[Admin] Hard-delete a customer (cascades to addresses, carts, favorites). Parent User is untouched.

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String customerId = customerId_example; // String | 

try {
    final response = api.customersControllerAdminRemove(customerId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerAdminRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerCreateAddress**
> ApiControllerRoot200Response customersControllerCreateAddress(createAddressDto)

Add a new address

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final CreateAddressDto createAddressDto = ; // CreateAddressDto | 

try {
    final response = api.customersControllerCreateAddress(createAddressDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerCreateAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createAddressDto** | [**CreateAddressDto**](CreateAddressDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerDeleteAddress**
> ApiControllerRoot200Response customersControllerDeleteAddress(id)

Delete an address

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String id = id_example; // String | 

try {
    final response = api.customersControllerDeleteAddress(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerDeleteAddress: $e\n');
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

# **customersControllerGetAddresses**
> ApiControllerRoot200Response customersControllerGetAddresses()

Get my addresses

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();

try {
    final response = api.customersControllerGetAddresses();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerGetAddresses: $e\n');
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

# **customersControllerGetCoinHistory**
> ApiControllerRoot200Response customersControllerGetCoinHistory(page, limit)

Get coin transaction history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String page = page_example; // String | 
final String limit = limit_example; // String | 

try {
    final response = api.customersControllerGetCoinHistory(page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerGetCoinHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **String**|  | 
 **limit** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerGetFavorites**
> ApiControllerRoot200Response customersControllerGetFavorites()

Get my favorites (vendors + products)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();

try {
    final response = api.customersControllerGetFavorites();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerGetFavorites: $e\n');
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

# **customersControllerToggleFavoriteProduct**
> ApiControllerRoot200Response customersControllerToggleFavoriteProduct(productId)

Toggle product favorite

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String productId = productId_example; // String | 

try {
    final response = api.customersControllerToggleFavoriteProduct(productId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerToggleFavoriteProduct: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **productId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerToggleFavoriteVendor**
> ApiControllerRoot200Response customersControllerToggleFavoriteVendor(vendorId)

Toggle vendor favorite

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.customersControllerToggleFavoriteVendor(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerToggleFavoriteVendor: $e\n');
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

# **customersControllerUpdateAddress**
> ApiControllerRoot200Response customersControllerUpdateAddress(id, updateAddressDto)

Update an address

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCustomersApi();
final String id = id_example; // String | 
final UpdateAddressDto updateAddressDto = ; // UpdateAddressDto | 

try {
    final response = api.customersControllerUpdateAddress(id, updateAddressDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomersApi->customersControllerUpdateAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateAddressDto** | [**UpdateAddressDto**](UpdateAddressDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

