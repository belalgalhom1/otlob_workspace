# api.model.ProductVariantResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**productId** | **String** |  | 
**name** | **String** |  | 
**nameAr** | **String** |  | [optional] 
**sku** | **String** |  | [optional] 
**basePrice** | **num** |  | 
**comparePrice** | **num** |  | [optional] 
**stock** | **num** |  | [optional] 
**tracksStock** | **bool** |  | 
**isActive** | **bool** |  | 
**version** | **num** |  | 
**cartItems** | [**BuiltList&lt;CartItem&gt;**](CartItem.md) |  | [optional] 
**orderItems** | [**BuiltList&lt;OrderItem&gt;**](OrderItem.md) |  | [optional] 
**optionGroups** | [**BuiltList&lt;ProductOptionGroup&gt;**](ProductOptionGroup.md) |  | [optional] 
**offers** | [**BuiltList&lt;Offer&gt;**](Offer.md) |  | [optional] 
**product** | [**Product**](Product.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


