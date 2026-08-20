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
**vendorId** | **String** |  | [optional] 
**driverId** | **String** |  | [optional] 
**vendorRating** | **num** | Rating out of 5 | [optional] 
**driverRating** | **num** | Rating out of 5 | [optional] 
**comment** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**customer** | [**ReviewCustomerDto**](ReviewCustomerDto.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


