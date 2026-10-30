# api.model.Driver

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**userId** | **String** |  | 
**name** | **String** |  | 
**avatar** | **String** |  | [optional] 
**nationalId** | **String** |  | [optional] 
**licenseNumber** | **String** |  | [optional] 
**vehicleType** | [**VehicleType**](VehicleType.md) |  | 
**vehiclePlate** | **String** |  | [optional] 
**tier** | [**DriverTier**](DriverTier.md) |  | 
**status** | [**DriverStatus**](DriverStatus.md) |  | 
**lastLocationUpdate** | [**DateTime**](DateTime.md) |  | [optional] 
**rating** | **num** |  | 
**ratingCount** | **num** |  | 
**totalOrders** | **num** |  | 
**ordersSinceSettlement** | **num** |  | 
**walletBalance** | **num** |  | 
**hasUnpaidCommission** | **bool** |  | 
**version** | **num** |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**isApproved** | **bool** |  | 
**approvedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**approvedById** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


