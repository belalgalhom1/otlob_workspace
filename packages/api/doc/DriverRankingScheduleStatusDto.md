# api.model.DriverRankingScheduleStatusDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**enabled** | **bool** |  | 
**evalTime** | **String** |  | 
**frequency** | **String** |  | 
**evaluationDay** | **String** |  | 
**timezone** | **String** |  | 
**goldThreshold** | **num** |  | 
**silverThreshold** | **num** |  | 
**nextEvaluationAt** | [**DateTime**](DateTime.md) |  | 
**currentWeek** | [**RankingWeekWindowDto**](RankingWeekWindowDto.md) |  | 
**lastCompletedWeek** | [**RankingWeekWindowDto**](RankingWeekWindowDto.md) |  | 
**latestRun** | [**DriverRankingEvaluationRunDto**](DriverRankingEvaluationRunDto.md) |  | [optional] 
**lastCompletedWeekRun** | [**DriverRankingEvaluationRunDto**](DriverRankingEvaluationRunDto.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


