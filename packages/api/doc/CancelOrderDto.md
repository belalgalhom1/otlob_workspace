# api.model.CancelOrderDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**reason** | **String** | Optional reason for cancelling the order | [optional] 
**responsibility** | [**DeliveryIncidentResponsibility**](DeliveryIncidentResponsibility.md) | Optional admin/support responsibility classification when an order already had an assigned driver | [optional] 
**responsibleDriverId** | **String** | Specific driverId attributed when responsibility is DRIVER_AT_FAULT on multi-group orders | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


