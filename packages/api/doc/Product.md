# openapi.model.Product

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**version** | **num** |  | 
**vendorId** | **String** |  | 
**categoryId** | **String** |  | [optional] 
**name** | **String** |  | 
**nameAr** | **String** |  | [optional] 
**description** | **String** |  | [optional] 
**descriptionAr** | **String** |  | [optional] 
**imageUrl** | **String** |  | [optional] 
**sellByStrip** | **bool** |  | 
**stripsPerPackage** | **num** |  | [optional] 
**hasVariants** | **bool** |  | 
**basePrice** | **num** |  | [optional] 
**comparePrice** | **num** |  | [optional] 
**sku** | **String** |  | [optional] 
**stock** | **num** |  | [optional] 
**isActive** | **bool** |  | 
**isFeatured** | **bool** |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**cartItems** | [**BuiltList&lt;CartItem&gt;**](CartItem.md) |  | 
**favoritedBy** | [**BuiltList&lt;FavoriteProduct&gt;**](FavoriteProduct.md) |  | 
**orderItems** | [**BuiltList&lt;OrderItem&gt;**](OrderItem.md) |  | 
**optionGroups** | [**BuiltList&lt;ProductOptionGroup&gt;**](ProductOptionGroup.md) |  | 
**variants** | [**BuiltList&lt;ProductVariant&gt;**](ProductVariant.md) |  | 
**promotions** | [**BuiltList&lt;Promotion&gt;**](Promotion.md) |  | 
**offers** | [**BuiltList&lt;Offer&gt;**](Offer.md) |  | 
**category** | [**MenuCategory**](MenuCategory.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


