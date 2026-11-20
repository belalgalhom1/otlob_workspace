# api.model.OrderStatusEvent

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**fulfillmentId** | **String** |  | [optional] 
**deliveryGroupId** | **String** |  | [optional] 
**eventKey** | **String** |  | [optional] 
**status** | [**OrderStatus**](OrderStatus.md) |  | 
**note** | **String** |  | [optional] 
**createdBy** | **String** |  | [optional] 
**actorUserId** | **String** |  | [optional] 
**actorRole** | [**Role**](Role.md) |  | [optional] 
**actorName** | **String** |  | [optional] 
**actorNameAr** | **String** |  | [optional] 
**actorAvatar** | **String** |  | [optional] 
**actorVendorId** | **String** |  | [optional] 
**actor** | [**OrderActorSummaryDto**](OrderActorSummaryDto.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


