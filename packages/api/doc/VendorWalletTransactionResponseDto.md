# api.model.VendorWalletTransactionResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**vendorId** | **String** |  | 
**orderId** | **String** |  | [optional] 
**type** | [**VendorTransactionType**](VendorTransactionType.md) |  | 
**amount** | **num** |  | 
**balanceAfter** | **num** |  | 
**description** | **String** |  | [optional] 
**referenceId** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**order** | [**Order**](Order.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


