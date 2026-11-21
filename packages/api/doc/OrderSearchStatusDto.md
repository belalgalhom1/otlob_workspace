# api.model.OrderSearchStatusDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**orderId** | **String** |  | 
**orderNumber** | **String** |  | 
**orderType** | [**OrderType**](OrderType.md) |  | 
**orderStatus** | [**OrderStatus**](OrderStatus.md) |  | 
**revision** | **num** |  | 
**phase** | [**DriverSearchPhase**](DriverSearchPhase.md) |  | 
**attempt** | **num** |  | 
**maxAttempts** | **num** |  | 
**radiusKm** | **num** |  | 
**maxRadiusKm** | **num** |  | 
**contactedCount** | **num** |  | 
**totalContactedCount** | **num** |  | 
**rejectedCount** | **num** |  | 
**nearbyAvailableCount** | **num** |  | 
**nearbyDrivers** | [**BuiltList&lt;NearbyDriverPreviewDto&gt;**](NearbyDriverPreviewDto.md) |  | 
**waveExpiresAt** | **String** |  | [optional] 
**searchTimeoutSecs** | **num** |  | 
**searchStartedAt** | **String** |  | 
**updatedAt** | **String** |  | 
**terminalReason** | [**SearchTerminalReason**](SearchTerminalReason.md) |  | 
**canRetry** | **bool** |  | 
**driverLocation** | [**GeoPointDto**](GeoPointDto.md) |  | [optional] 
**driverDistanceKm** | **num** |  | [optional] 
**driverEtaMinutes** | **num** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


