# openapi.model.OrderItem

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**productId** | **String** |  | [optional] 
**variantId** | **String** |  | [optional] 
**productName** | **String** |  | 
**variantName** | **String** |  | [optional] 
**unitPrice** | **num** |  | 
**quantity** | **num** |  | 
**totalPrice** | **num** |  | 
**specialRequest** | **String** |  | [optional] 
**selectedOptions** | [**BuiltList&lt;OrderItemOption&gt;**](OrderItemOption.md) |  | 
**order** | [**Order**](Order.md) |  | 
**product** | [**Product**](Product.md) |  | [optional] 
**variant** | [**ProductVariant**](ProductVariant.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


