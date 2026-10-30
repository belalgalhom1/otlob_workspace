# api.model.PlaceMultiVendorOrderDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**vendorIds** | **BuiltList&lt;String&gt;** | Vendors being checked out together. Requires 2 or more — use the single-vendor endpoint for one. | 
**paymentMethod** | **String** |  | 
**deliveryAddress** | **String** |  | 
**deliveryLocation** | **BuiltList&lt;String&gt;** | [longitude, latitude] | 
**specialRequest** | **String** |  | [optional] 
**coinsToUse** | **num** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


