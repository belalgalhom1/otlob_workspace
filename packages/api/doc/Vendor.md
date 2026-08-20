# openapi.model.Vendor

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**storeName** | **String** |  | 
**storeNameAr** | **String** |  | [optional] 
**slug** | **String** |  | 
**description** | **String** |  | [optional] 
**descriptionAr** | **String** |  | [optional] 
**logo** | **String** |  | [optional] 
**coverImage** | **String** |  | [optional] 
**phone** | **String** |  | [optional] 
**taxId** | **String** |  | [optional] 
**commissionRate** | **num** |  | 
**status** | [**VendorStatus**](VendorStatus.md) |  | 
**walletBalance** | **num** |  | 
**isContracted** | **bool** |  | 
**workingHours** | [**JsonObject**](.md) |  | [optional] 
**isScheduleActive** | **bool** |  | 
**verticalId** | **String** |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**auditLogs** | [**BuiltList&lt;AuditLog&gt;**](AuditLog.md) |  | 
**carts** | [**BuiltList&lt;Cart&gt;**](Cart.md) |  | 
**conversations** | [**BuiltList&lt;Conversation&gt;**](Conversation.md) |  | 
**favoritedBy** | [**BuiltList&lt;FavoriteVendor&gt;**](FavoriteVendor.md) |  | 
**categories** | [**BuiltList&lt;MenuCategory&gt;**](MenuCategory.md) |  | 
**orders** | [**BuiltList&lt;Order&gt;**](Order.md) |  | 
**products** | [**BuiltList&lt;Product&gt;**](Product.md) |  | 
**supportTickets** | [**BuiltList&lt;SupportTicket&gt;**](SupportTicket.md) |  | 
**branches** | [**BuiltList&lt;VendorBranch&gt;**](VendorBranch.md) |  | 
**members** | [**BuiltList&lt;VendorMember&gt;**](VendorMember.md) |  | 
**statistics** | [**BuiltList&lt;VendorStatistic&gt;**](VendorStatistic.md) |  | 
**walletTransactions** | [**BuiltList&lt;VendorWalletTransaction&gt;**](VendorWalletTransaction.md) |  | 
**promotions** | [**BuiltList&lt;Promotion&gt;**](Promotion.md) |  | 
**offers** | [**BuiltList&lt;Offer&gt;**](Offer.md) |  | 
**vertical** | [**VendorVertical**](VendorVertical.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


