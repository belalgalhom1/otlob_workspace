# api.model.CreateReviewDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**fulfillmentRatings** | [**BuiltList&lt;FulfillmentRatingInputDto&gt;**](FulfillmentRatingInputDto.md) | Per-store/branch portion ratings for this order | [optional] 
**deliveryGroupRatings** | [**BuiltList&lt;DeliveryGroupRatingInputDto&gt;**](DeliveryGroupRatingInputDto.md) | Per-driver/delivery-group ratings for this order | [optional] 
**vendorRating** | **num** | Rating out of 5 (single-store shorthand) | [optional] 
**driverRating** | **num** | Rating out of 5 (single-driver shorthand) | [optional] 
**comment** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


