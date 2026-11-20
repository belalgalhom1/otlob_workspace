# api.model.DriverRankingEvaluationRunDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**periodKey** | **String** |  | 
**status** | [**DriverRankingRunStatus**](DriverRankingRunStatus.md) |  | 
**triggerSource** | [**DriverRankingTriggerSource**](DriverRankingTriggerSource.md) |  | 
**triggeredByUserId** | [**JsonObject**](.md) |  | [optional] 
**scheduledFor** | [**DateTime**](DateTime.md) |  | 
**executedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**periodStart** | [**DateTime**](DateTime.md) |  | 
**periodEnd** | [**DateTime**](DateTime.md) |  | 
**totalDrivers** | **num** |  | 
**promotedCount** | **num** |  | 
**demotedCount** | **num** |  | 
**unchangedCount** | **num** |  | 
**inactiveCount** | **num** |  | 
**errorMessage** | [**JsonObject**](.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


