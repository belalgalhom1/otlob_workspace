# api.model.DriverMetricsSnapshotDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**acceptedDispatches** | **num** |  | 
**rejectedDispatches** | **num** |  | 
**expiredDispatches** | **num** |  | 
**eligibleDispatches** | **num** |  | 
**cancelledDispatches** | **num** |  | 
**completedOrders** | **num** |  | 
**driverFaultFailures** | **num** |  | 
**driverResponsibleOrders** | **num** |  | 
**excludedIncidents** | [**ExcludedIncidentsSummaryDto**](ExcludedIncidentsSummaryDto.md) |  | 
**onTimeShifts** | **num** |  | 
**lateShifts** | **num** |  | 
**missedShifts** | **num** |  | 
**eligibleShifts** | **num** |  | 
**cancelledShifts** | **num** |  | 
**excusedShifts** | **num** |  | 
**acceptanceRate** | **num** |  | [optional] 
**completionRate** | **num** |  | [optional] 
**shiftPunctualityRate** | **num** |  | [optional] 
**applicableMetricsCount** | **num** |  | 
**cappedDueToNoOrders** | **bool** |  | 
**explanations** | **BuiltList&lt;String&gt;** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


