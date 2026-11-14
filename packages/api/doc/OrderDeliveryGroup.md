# api.model.OrderDeliveryGroup

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**sequence** | **num** |  | 
**status** | [**DeliveryGroupStatus**](DeliveryGroupStatus.md) |  | 
**primaryDriverId** | **String** |  | [optional] 
**primaryDriverShiftId** | **String** |  | [optional] 
**assistDriverId** | **String** |  | [optional] 
**assistDriverShiftId** | **String** |  | [optional] 
**assistFee** | **num** |  | [optional] 
**assistCustomerApproved** | **bool** |  | [optional] 
**assistApprovedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**isStacked** | **bool** |  | 
**isPaymentCollector** | **bool** |  | 
**assignedByUserId** | **String** |  | [optional] 
**assignedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**distanceKm** | **num** |  | [optional] 
**deliveryFee** | **num** |  | 
**estimatedPrepTime** | **num** |  | [optional] 
**pickupImageUrl** | **String** |  | [optional] 
**deliveryImageUrl** | **String** |  | [optional] 
**pickedUpAt** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveredAt** | [**DateTime**](DateTime.md) |  | [optional] 
**primaryDriver** | [**Driver**](Driver.md) |  | [optional] 
**assistDriver** | [**Driver**](Driver.md) |  | [optional] 
**items** | [**BuiltList&lt;OrderDeliveryGroupItem&gt;**](OrderDeliveryGroupItem.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


