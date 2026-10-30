# api.model.Order

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderNumber** | **String** |  | 
**clientOrderKey** | **String** |  | [optional] 
**type** | [**OrderType**](OrderType.md) |  | 
**customerId** | **String** |  | 
**vendorId** | **String** |  | [optional] 
**vendorBranchId** | **String** |  | [optional] 
**driverId** | **String** |  | [optional] 
**zoneId** | **String** |  | [optional] 
**driverShiftId** | **String** |  | [optional] 
**status** | [**OrderStatus**](OrderStatus.md) |  | 
**paymentMethod** | [**PaymentMethod**](PaymentMethod.md) |  | 
**paymentStatus** | [**PaymentStatus**](PaymentStatus.md) |  | 
**deliveryAddress** | **String** |  | 
**pickupAddress** | **String** |  | [optional] 
**itemDetails** | **String** |  | [optional] 
**requestedVehicleType** | [**VehicleType**](VehicleType.md) |  | [optional] 
**subtotal** | **num** |  | 
**deliveryFee** | **num** |  | 
**driverBonusFee** | **num** |  | 
**serviceFee** | **num** |  | 
**tax** | **num** |  | 
**discount** | **num** |  | 
**coinsUsed** | **num** |  | 
**coinsEarned** | **num** |  | 
**grandTotal** | **num** |  | 
**upfrontAmount** | **num** |  | 
**specialRequest** | **String** |  | [optional] 
**estimatedPrepTime** | **num** |  | [optional] 
**distanceKm** | **num** |  | [optional] 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**acceptedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**preparedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**driverAssignedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pickedUpAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pickupImageUrl** | **String** |  | [optional] 
**deliveryImageUrl** | **String** |  | [optional] 
**paymentReceiptUrl** | **String** |  | [optional] 
**actualDeliveryTime** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


