# api.model.CreateMenuCategoryDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**nameAr** | **String** |  | [optional] 
**description** | **String** |  | [optional] 
**descriptionAr** | **String** |  | [optional] 
**sortOrder** | **num** |  | [optional] [default to 0]
**isActive** | **bool** |  | [optional] [default to true]
**iconUrl** | **String** |  | [optional] 
**branchAvailabilityMode** | **String** | ALL includes every current and future branch. SPECIFIC uses branchIds. | [optional] [default to 'ALL']
**branchIds** | **BuiltList&lt;String&gt;** | Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


