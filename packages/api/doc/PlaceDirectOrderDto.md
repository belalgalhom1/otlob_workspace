# api.model.PlaceDirectOrderDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**customerId** | **String** |  | 
**vendorId** | **String** |  | 
**productId** | **String** |  | [optional] 
**productName** | **String** |  | [optional] 
**price** | **num** |  | 
**quantity** | **num** |  | [default to 1]
**paymentMethod** | **String** |  | [default to 'CASH_ON_DELIVERY']
**deliveryAddress** | **String** |  | [optional] 
**deliveryLocation** | **BuiltList&lt;num&gt;** | [longitude, latitude] | [optional] 
**specialRequest** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


