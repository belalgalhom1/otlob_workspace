# api.model.DriverShiftResponseDto

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
**isExcused** | **bool** |  | 
**excuseReason** | **String** |  | [optional] 
**excusedByUserId** | **String** |  | [optional] 
**excusedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**driver** | [**Driver**](Driver.md) |  | [optional] 
**shiftPool** | [**ShiftPool**](ShiftPool.md) |  | [optional] 
**zone** | [**Zone**](Zone.md) |  | [optional] 
**walletTransactions** | [**BuiltList&lt;DriverWalletTransaction&gt;**](DriverWalletTransaction.md) |  | [optional] 
**dispatches** | [**BuiltList&lt;OrderDispatch&gt;**](OrderDispatch.md) |  | [optional] 
**orders** | [**BuiltList&lt;Order&gt;**](Order.md) |  | [optional] 
**swapRequests** | [**BuiltList&lt;ShiftSwapRequest&gt;**](ShiftSwapRequest.md) |  | [optional] 
**breaks** | [**BuiltList&lt;DriverBreak&gt;**](DriverBreak.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


