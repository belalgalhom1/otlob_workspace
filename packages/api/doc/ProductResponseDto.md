# api.model.ProductResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
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
**tracksStock** | **bool** |  | 
**isActive** | **bool** |  | 
**isFeatured** | **bool** |  | 
**branchAvailabilityMode** | **String** |  | [default to 'ALL']
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**cartItems** | [**BuiltList&lt;CartItem&gt;**](CartItem.md) |  | [optional] 
**favoritedBy** | [**BuiltList&lt;FavoriteProduct&gt;**](FavoriteProduct.md) |  | [optional] 
**orderItems** | [**BuiltList&lt;OrderItem&gt;**](OrderItem.md) |  | [optional] 
**optionGroups** | [**BuiltList&lt;ProductOptionGroup&gt;**](ProductOptionGroup.md) |  | [optional] 
**variants** | [**BuiltList&lt;ProductVariant&gt;**](ProductVariant.md) |  | [optional] 
**promotions** | [**BuiltList&lt;Promotion&gt;**](Promotion.md) |  | [optional] 
**offers** | [**BuiltList&lt;Offer&gt;**](Offer.md) |  | [optional] 
**branchAvailability** | [**BuiltList&lt;ProductBranchAvailability&gt;**](ProductBranchAvailability.md) |  | [optional] 
**category** | [**MenuCategory**](MenuCategory.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


