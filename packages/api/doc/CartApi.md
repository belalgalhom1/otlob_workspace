# api.api.CartApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cartControllerAddItem**](CartApi.md#cartcontrolleradditem) | **POST** /cart/{vendorId}/items | Add item to cart
[**cartControllerClearCart**](CartApi.md#cartcontrollerclearcart) | **DELETE** /cart/{vendorId} | Clear entire cart for a vendor
[**cartControllerGetCart**](CartApi.md#cartcontrollergetcart) | **GET** /cart/{vendorId} | Get cart for a specific vendor
[**cartControllerGetMyCarts**](CartApi.md#cartcontrollergetmycarts) | **GET** /cart | Get all my carts (one per vendor)
[**cartControllerRemoveItem**](CartApi.md#cartcontrollerremoveitem) | **DELETE** /cart/{vendorId}/items/{itemId} | Remove item from cart
[**cartControllerUpdateItem**](CartApi.md#cartcontrollerupdateitem) | **PATCH** /cart/{vendorId}/items/{itemId} | Update cart item (quantity / options)


# **cartControllerAddItem**
> AuthControllerRegister200Response cartControllerAddItem(vendorId, addCartItemDto)

Add item to cart

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();
final String vendorId = vendorId_example; // String | 
final AddCartItemDto addCartItemDto = ; // AddCartItemDto | 

try {
    final response = api.cartControllerAddItem(vendorId, addCartItemDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerAddItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **addCartItemDto** | [**AddCartItemDto**](AddCartItemDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cartControllerClearCart**
> AuthControllerRegister200Response cartControllerClearCart(vendorId)

Clear entire cart for a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.cartControllerClearCart(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerClearCart: $e\n');
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

# **cartControllerGetCart**
> AuthControllerRegister200Response cartControllerGetCart(vendorId)

Get cart for a specific vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.cartControllerGetCart(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerGetCart: $e\n');
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

# **cartControllerGetMyCarts**
> AuthControllerRegister200Response cartControllerGetMyCarts()

Get all my carts (one per vendor)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();

try {
    final response = api.cartControllerGetMyCarts();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerGetMyCarts: $e\n');
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

# **cartControllerRemoveItem**
> AuthControllerRegister200Response cartControllerRemoveItem(vendorId, itemId)

Remove item from cart

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();
final String vendorId = vendorId_example; // String | 
final String itemId = itemId_example; // String | 

try {
    final response = api.cartControllerRemoveItem(vendorId, itemId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerRemoveItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **itemId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cartControllerUpdateItem**
> AuthControllerRegister200Response cartControllerUpdateItem(vendorId, itemId, updateCartItemDto)

Update cart item (quantity / options)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getCartApi();
final String vendorId = vendorId_example; // String | 
final String itemId = itemId_example; // String | 
final UpdateCartItemDto updateCartItemDto = ; // UpdateCartItemDto | 

try {
    final response = api.cartControllerUpdateItem(vendorId, itemId, updateCartItemDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CartApi->cartControllerUpdateItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **itemId** | **String**|  | 
 **updateCartItemDto** | [**UpdateCartItemDto**](UpdateCartItemDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

