# api.model.UpdateOrderStatusDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**status** | **String** |  | 
**note** | **String** |  | [optional] 
**estimatedPrepTime** | **num** | Estimated prep time in minutes (for ACCEPTED) | [optional] 
**pickupImageUrl** | **String** | Pickup proof photo URL (required when status is PICKED_UP) | [optional] 
**deliveryImageUrl** | **String** | Delivery proof photo URL (required when status is DELIVERED) | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


