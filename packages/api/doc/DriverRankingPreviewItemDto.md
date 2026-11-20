# api.model.DriverRankingPreviewItemDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**driverId** | **String** |  | 
**driverName** | **String** |  | 
**previousTier** | [**DriverTier**](DriverTier.md) |  | 
**newTier** | [**DriverTier**](DriverTier.md) |  | 
**changeReason** | [**DriverRankChangeReason**](DriverRankChangeReason.md) |  | 
**outcome** | [**DriverRankingOutcome**](DriverRankingOutcome.md) |  | 
**performancePercentage** | **num** |  | [optional] 
**acceptanceRate** | **num** |  | [optional] 
**completionRate** | **num** |  | [optional] 
**shiftPunctualityRate** | **num** |  | [optional] 
**metricsSnapshot** | [**DriverMetricsSnapshotDto**](DriverMetricsSnapshotDto.md) |  | 
**explanations** | **BuiltList&lt;String&gt;** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


