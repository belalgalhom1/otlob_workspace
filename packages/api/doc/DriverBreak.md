# api.model.DriverBreak

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**driverId** | **String** |  | 
**shiftId** | **String** |  | [optional] 
**reason** | [**DriverBreakReason**](DriverBreakReason.md) |  | 
**note** | **String** |  | [optional] 
**requestedMinutes** | **num** |  | [optional] 
**status** | [**DriverBreakStatus**](DriverBreakStatus.md) |  | 
**prevStatus** | [**DriverStatus**](DriverStatus.md) |  | [optional] 
**startedAt** | [**DateTime**](DateTime.md) |  | 
**endedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**durationMinutes** | **num** |  | [optional] 
**autoEnded** | **bool** |  | 
**reviewedById** | **String** |  | [optional] 
**reviewedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


