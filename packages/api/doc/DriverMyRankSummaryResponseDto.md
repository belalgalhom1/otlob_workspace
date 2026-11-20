# api.model.DriverMyRankSummaryResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**driverId** | **String** |  | 
**currentTier** | [**DriverTier**](DriverTier.md) |  | 
**timezone** | **String** |  | 
**nextEvaluationAt** | [**DateTime**](DateTime.md) |  | 
**currentWeek** | [**RankingWeekWindowDto**](RankingWeekWindowDto.md) |  | 
**currentWeekProgress** | [**DriverRankingPreviewItemDto**](DriverRankingPreviewItemDto.md) |  | [optional] 
**latestEvaluation** | [**DriverRankHistoryEntryDto**](DriverRankHistoryEntryDto.md) |  | [optional] 
**recentHistory** | [**BuiltList&lt;DriverRankHistoryEntryDto&gt;**](DriverRankHistoryEntryDto.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


