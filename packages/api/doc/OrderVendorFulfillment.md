# api.model.OrderVendorFulfillment

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**orderId** | **String** |  | 
**vendorId** | **String** |  | 
**vendorBranchId** | **String** |  | [optional] 
**status** | [**OrderVendorFulfillmentStatus**](OrderVendorFulfillmentStatus.md) |  | 
**stage** | **String** |  | [optional] 
**subtotal** | **num** |  | 
**commissionRate** | **num** |  | 
**rejectionCode** | **String** |  | [optional] 
**rejectionReason** | **String** |  | [optional] 
**rejectionReasonAr** | **String** |  | [optional] 
**preparingAt** | [**DateTime**](DateTime.md) |  | [optional] 
**readyAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pickupImageUrl** | **String** |  | [optional] 
**pickedUpAt** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveredAt** | [**DateTime**](DateTime.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 
**vendorBranch** | [**VendorBranch**](VendorBranch.md) |  | [optional] 
**items** | [**BuiltList&lt;OrderItem&gt;**](OrderItem.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


