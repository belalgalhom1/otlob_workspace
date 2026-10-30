# api.model.DriverShift

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**driverId** | **String** |  | 
**shiftPoolId** | **String** |  | [optional] 
**zoneId** | **String** |  | [optional] 
**shiftDate** | [**DateTime**](DateTime.md) |  | 
**startTime** | [**DateTime**](DateTime.md) |  | 
**endTime** | [**DateTime**](DateTime.md) |  | 
**actualStart** | [**DateTime**](DateTime.md) |  | [optional] 
**actualEnd** | [**DateTime**](DateTime.md) |  | [optional] 
**startPhotoUrl** | **String** |  | [optional] 
**status** | [**DriverShiftStatus**](DriverShiftStatus.md) |  | 
**breakMinutes** | **num** |  | [optional] 
**totalEarnings** | **num** |  | [optional] 
**totalDeliveries** | **num** |  | [optional] 
**expiredDispatches** | **num** |  | 
**rejectedDispatches** | **num** |  | 
**warningSent** | **bool** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


