# openapi.model.DriverStatistic

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**driverId** | **String** |  | 
**period** | [**StatisticPeriod**](StatisticPeriod.md) |  | 
**startDate** | [**DateTime**](DateTime.md) |  | 
**endDate** | [**DateTime**](DateTime.md) |  | 
**totalOrders** | **num** |  | 
**totalEarnings** | **num** |  | 
**completedOrders** | **num** |  | 
**cancelledOrders** | **num** |  | 
**onlineHours** | **num** |  | [optional] 
**totalDispatchesReceived** | **num** |  | 
**dispatchesAccepted** | **num** |  | 
**dispatchesRejected** | **num** |  | 
**dispatchesExpired** | **num** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**driver** | [**Driver**](Driver.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


