# api.model.MobileWalletResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**number** | **String** |  | 
**type** | [**WalletType**](WalletType.md) |  | 
**isActive** | **bool** |  | 
**isPlatform** | **bool** |  | 
**driverId** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**driver** | [**Driver**](Driver.md) |  | [optional] 
**topUps** | [**BuiltList&lt;WalletTopUpRequest&gt;**](WalletTopUpRequest.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


