# api.model.OrderDeliveryGroup

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**sequence** | **num** |  | 
**status** | [**DeliveryGroupStatus**](DeliveryGroupStatus.md) |  | 
**primaryDriverId** | **String** |  | [optional] 
**assistDriverId** | **String** |  | [optional] 
**distanceKm** | **num** |  | [optional] 
**deliveryFee** | **num** |  | 
**pickupImageUrl** | **String** |  | [optional] 
**deliveryImageUrl** | **String** |  | [optional] 
**pickedUpAt** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveredAt** | [**DateTime**](DateTime.md) |  | [optional] 
**primaryDriver** | [**Driver**](Driver.md) |  | [optional] 
**assistDriver** | [**Driver**](Driver.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


