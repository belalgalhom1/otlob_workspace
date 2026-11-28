# api.model.ProcessDriverManagerPayoutDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**amount** | **num** | Amount in EGP to deduct and transfer to the driver manager. Omit when settleFullBalance is true to zero out the full positive balance. | [optional] 
**settleFullBalance** | **bool** | When true, transfers the full current positive walletBalance and resets it to 0. | [optional] 
**receiptUrl** | **String** | Uploaded transfer screenshot URL | [optional] 
**description** | **String** | Optional payout description or transfer reference note | [optional] 
**idempotencyKey** | **String** | Optional idempotency key to prevent duplicate payouts | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


