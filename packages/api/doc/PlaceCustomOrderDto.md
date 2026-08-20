# api.model.PlaceCustomOrderDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**type** | **String** |  | 
**paymentMethod** | **String** |  | 
**pickupAddress** | **String** |  | 
**pickupLocation** | **BuiltList&lt;num&gt;** | [longitude, latitude] | 
**deliveryAddress** | **String** |  | 
**deliveryLocation** | **BuiltList&lt;num&gt;** | [longitude, latitude] | 
**vehicleType** | **String** |  | 
**itemDetails** | **String** |  | [optional] 
**specialRequest** | **String** |  | [optional] 
**coinsToUse** | **num** | Number of coins to use for partial or full payment | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


