# api.model.AdminAssignDriverDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**driverId** | **String** |  | 
**deliveryGroupId** | **String** | Optional delivery group ID when assigning a driver to a specific delivery trip | [optional] 
**previousDriverResponsibility** | [**DeliveryIncidentResponsibility**](DeliveryIncidentResponsibility.md) | Responsibility classification when replacing an already-assigned driver (for weekly ranking) | [optional] 
**reassignmentReason** | **String** | Reason for driver reassignment | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


