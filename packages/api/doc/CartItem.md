# openapi.model.CartItem

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**cartId** | **String** |  | 
**productId** | **String** |  | [optional] 
**variantId** | **String** |  | [optional] 
**customName** | **String** |  | [optional] 
**customPrice** | **num** |  | [optional] 
**customImageUrl** | **String** |  | [optional] 
**quantity** | **num** |  | 
**specialRequest** | **String** |  | [optional] 
**optionHash** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**selectedOptions** | [**BuiltList&lt;CartItemOption&gt;**](CartItemOption.md) |  | 
**cart** | [**Cart**](Cart.md) |  | 
**product** | [**Product**](Product.md) |  | [optional] 
**variant** | [**ProductVariant**](ProductVariant.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


