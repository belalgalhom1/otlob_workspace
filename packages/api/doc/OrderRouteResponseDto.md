# api.model.OrderRouteResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**orderId** | [**JsonObject**](.md) |  | [optional] 
**orderStatus** | [**JsonObject**](.md) |  | [optional] 
**encodedPolyline** | **String** | Google Encoded Polyline string (precision 5). | 
**coordinates** | [**BuiltList&lt;RouteCoordinateDto&gt;**](RouteCoordinateDto.md) | Decoded road-following coordinates in traversal order. | 
**waypoints** | [**BuiltList&lt;RouteCoordinateDto&gt;**](RouteCoordinateDto.md) | Ordered waypoints used to compute the route. | 
**distanceMeters** | **num** | Total route distance in meters. | 
**durationSeconds** | **num** | Estimated driving duration in seconds (0 when fallback). | 
**isRoadRoute** | **bool** | True when geometry follows real driving roads; false only when fallback straight chord is returned. | 
**source_** | **String** |  | 
**driverLocation** | [**RouteCoordinateDto**](RouteCoordinateDto.md) | Live assigned driver location included as route origin when available. | [optional] 
**destination** | [**RouteCoordinateDto**](RouteCoordinateDto.md) | Resolved route destination point. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


