# api.model.DriverDeliveryIncidentDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**orderNumber** | [**JsonObject**](.md) |  | [optional] 
**deliveryGroupId** | **String** |  | 
**driverId** | **String** |  | 
**driverName** | [**JsonObject**](.md) |  | [optional] 
**incidentType** | [**DeliveryIncidentType**](DeliveryIncidentType.md) |  | 
**responsibility** | [**DeliveryIncidentResponsibility**](DeliveryIncidentResponsibility.md) |  | 
**reason** | [**JsonObject**](.md) |  | [optional] 
**reportedByUserId** | [**JsonObject**](.md) |  | [optional] 
**reviewedByUserId** | [**JsonObject**](.md) |  | [optional] 
**reviewedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**reviewNote** | [**JsonObject**](.md) |  | [optional] 
**occurredAt** | [**DateTime**](DateTime.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


