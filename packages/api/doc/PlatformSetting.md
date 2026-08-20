# api.model.PlatformSetting

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**currency** | **String** |  | 
**defaultCommissionRate** | **num** |  | 
**deliveryCommissionRate** | **num** |  | 
**defaultTaxRate** | **num** |  | 
**minOrderAmount** | **num** |  | 
**baseDeliveryFee** | **num** |  | 
**pricePerKm** | **num** |  | 
**pricePerKmBicycle** | **num** |  | 
**pricePerKmMotorcycle** | **num** |  | 
**pricePerKmCar** | **num** |  | 
**pricePerKmVan** | **num** |  | 
**pricePerKmTruck** | **num** |  | 
**pricePerKmMotorTricycle** | **num** |  | 
**maxDeliveryFee** | **num** |  | 
**minDeliveryFeeBicycle** | **num** |  | 
**maxDeliveryFeeBicycle** | **num** |  | 
**minDeliveryFeeMotorcycle** | **num** |  | 
**maxDeliveryFeeMotorcycle** | **num** |  | 
**minDeliveryFeeCar** | **num** |  | 
**requireCustomerApproval** | **bool** |  | 
**customerApprovalTimeoutMins** | **num** |  | 
**maxDeliveryFeeCar** | **num** |  | 
**minDeliveryFeeVan** | **num** |  | 
**maxDeliveryFeeVan** | **num** |  | 
**minDeliveryFeeTruck** | **num** |  | 
**maxDeliveryFeeTruck** | **num** |  | 
**minDeliveryFeeMotorTricycle** | **num** |  | 
**maxDeliveryFeeMotorTricycle** | **num** |  | 
**allowBicycle** | **bool** |  | 
**allowMotorcycle** | **bool** |  | 
**allowCar** | **bool** |  | 
**allowVan** | **bool** |  | 
**allowTruck** | **bool** |  | 
**allowMotorTricycle** | **bool** |  | 
**minOrderKm** | **num** |  | 
**minDistanceFixedPrice** | **num** |  | 
**maxDeliveryRadiusKm** | **num** |  | 
**driverSearchRadiusKm** | **num** |  | 
**driverSearchRadiusStepKm** | **num** |  | 
**driverSearchRadiusMaxKm** | **num** |  | 
**autoCancelPendingMins** | **num** |  | 
**driverAcceptTimeoutSecs** | **num** |  | 
**isMaintenanceMode** | **bool** |  | 
**androidMinVersion** | **String** |  | 
**androidLatestVersion** | **String** |  | 
**androidForceUpdate** | **bool** |  | 
**androidStoreUrl** | **String** |  | [optional] 
**iosMinVersion** | **String** |  | 
**iosLatestVersion** | **String** |  | 
**iosForceUpdate** | **bool** |  | 
**iosStoreUrl** | **String** |  | [optional] 
**supportEmail** | **String** |  | [optional] 
**supportPhone** | **String** |  | [optional] 
**supportWhatsapp** | **String** |  | [optional] 
**termsUrl** | **String** |  | [optional] 
**privacyUrl** | **String** |  | [optional] 
**homeCoverUrl** | **String** |  | [optional] 
**motorcycleIconUrl** | **String** |  | [optional] 
**carIconUrl** | **String** |  | [optional] 
**deliveryBannerIconUrl** | **String** |  | [optional] 
**retentionOrdersDays** | **num** |  | 
**retentionArchivedChatsDays** | **num** |  | 
**retentionNotificationsDays** | **num** |  | 
**retentionExpiredSessionsDays** | **num** |  | 
**retentionAuditLogsDays** | **num** |  | 
**retentionAbandonedCartsDays** | **num** |  | 
**retentionWalletTransactionsDays** | **num** |  | 
**retentionStatisticsDays** | **num** |  | 
**maxKmForBicycle** | **num** |  | 
**driverSearchMaxAttempts** | **num** |  | 
**fallbackOrderDistanceKm** | **num** |  | 
**customOrderPlatformFee** | **num** |  | 
**maxDispatchBatchSize** | **num** |  | 
**coinValue** | **num** |  | 
**amountSpentPerCoin** | **num** |  | 
**minCoinsToUse** | **num** |  | 
**driverBonusActive** | **bool** |  | 
**driverBonusAmount** | **num** |  | 
**driverBonusStartDate** | [**DateTime**](DateTime.md) |  | [optional] 
**driverBonusEndDate** | [**DateTime**](DateTime.md) |  | [optional] 
**driverBonusPaidByCustomer** | **bool** |  | 
**driverShiftsEnabled** | **bool** |  | 
**customerApprovalTimeoutSecs** | **num** |  | 
**maxActiveOrdersPerCustomer** | **num** |  | 
**requirePriorDeliveryForMultipleOrders** | **bool** |  | 
**maxOtpAttempts** | **num** |  | 
**maxNegativeDriverBalance** | **num** |  | 
**otpExpirySeconds** | **num** |  | 
**bronzeTierBonusPerKm** | **num** |  | 
**silverTierBonusPerKm** | **num** |  | 
**goldTierBonusPerKm** | **num** |  | 
**highValueOrderThreshold** | **num** |  | 
**highValueUpfrontRate** | **num** |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


