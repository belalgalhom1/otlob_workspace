# api.model.DriverRankHistoryEntryDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**driverId** | **String** |  | 
**driverName** | [**JsonObject**](.md) |  | [optional] 
**runId** | [**JsonObject**](.md) |  | [optional] 
**periodKey** | [**JsonObject**](.md) |  | [optional] 
**evaluatedAt** | [**DateTime**](DateTime.md) |  | 
**periodStart** | [**DateTime**](DateTime.md) |  | [optional] 
**periodEnd** | [**DateTime**](DateTime.md) |  | [optional] 
**performancePercentage** | **num** |  | [optional] 
**metricsSnapshot** | [**DriverMetricsSnapshotDto**](DriverMetricsSnapshotDto.md) |  | [optional] 
**previousTier** | [**DriverTier**](DriverTier.md) |  | 
**newTier** | [**DriverTier**](DriverTier.md) |  | 
**changeReason** | [**DriverRankChangeReason**](DriverRankChangeReason.md) |  | 
**adminUserId** | [**JsonObject**](.md) |  | [optional] 
**overrideReason** | [**JsonObject**](.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


