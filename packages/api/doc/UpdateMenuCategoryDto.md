# api.model.UpdateMenuCategoryDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | [optional] 
**nameAr** | **String** |  | [optional] 
**description** | **String** |  | [optional] 
**descriptionAr** | **String** |  | [optional] 
**sortOrder** | **num** |  | [optional] 
**isActive** | **bool** |  | [optional] 
**iconUrl** | **String** |  | [optional] 
**branchAvailabilityMode** | **String** | ALL includes every current and future branch. SPECIFIC uses branchIds. | [optional] 
**branchIds** | **BuiltList&lt;String&gt;** | Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


