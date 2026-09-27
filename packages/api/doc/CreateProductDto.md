# api.model.CreateProductDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categoryId** | **String** |  | [optional] 
**name** | **String** |  | 
**nameAr** | **String** |  | [optional] 
**description** | **String** |  | [optional] 
**descriptionAr** | **String** |  | [optional] 
**hasVariants** | **bool** |  | [optional] [default to false]
**basePrice** | **num** |  | [optional] 
**comparePrice** | **num** |  | [optional] 
**sku** | **String** |  | [optional] 
**stock** | **num** |  | [optional] [default to 0]
**tracksStock** | **bool** |  | [optional] [default to true]
**isActive** | **bool** |  | [optional] [default to true]
**isFeatured** | **bool** |  | [optional] [default to false]
**sellByStrip** | **bool** |  | [optional] [default to false]
**stripsPerPackage** | **num** |  | [optional] 
**optionGroups** | [**BuiltList&lt;CreateOptionGroupDto&gt;**](CreateOptionGroupDto.md) |  | [optional] 
**variants** | [**BuiltList&lt;CreateProductVariantDto&gt;**](CreateProductVariantDto.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


