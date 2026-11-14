# api.model.ReviewDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**customerId** | **String** |  | 
**targetType** | **String** |  | 
**fulfillmentId** | [**JsonObject**](.md) |  | [optional] 
**deliveryGroupId** | [**JsonObject**](.md) |  | [optional] 
**vendorId** | [**JsonObject**](.md) |  | [optional] 
**driverId** | [**JsonObject**](.md) |  | [optional] 
**rating** | **num** | Rating out of 5 | 
**vendorRating** | **num** | Vendor rating out of 5 | [optional] 
**driverRating** | **num** | Driver rating out of 5 | [optional] 
**comment** | [**JsonObject**](.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**customer** | [**ReviewCustomerDto**](ReviewCustomerDto.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


