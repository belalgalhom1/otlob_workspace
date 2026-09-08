# api.model.WalletTopUpRequestResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**driverId** | **String** |  | 
**platformWalletId** | **String** |  | 
**amount** | **num** |  | 
**receiptUrl** | **String** |  | 
**status** | [**TopUpStatus**](TopUpStatus.md) |  | 
**approvedById** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**driver** | [**Driver**](Driver.md) |  | [optional] 
**platformWallet** | [**MobileWallet**](MobileWallet.md) |  | [optional] 
**approvedBy** | [**User**](User.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


