# openapi.model.VendorStatistic

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**vendorId** | **String** |  | 
**period** | [**StatisticPeriod**](StatisticPeriod.md) |  | 
**startDate** | [**DateTime**](DateTime.md) |  | 
**endDate** | [**DateTime**](DateTime.md) |  | 
**totalOrders** | **num** |  | 
**totalRevenue** | **num** |  | 
**totalCommission** | **num** |  | 
**totalTax** | **num** |  | 
**completedOrders** | **num** |  | 
**cancelledOrders** | **num** |  | 
**avgPrepTimeMins** | **num** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**vendor** | [**Vendor**](Vendor.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


