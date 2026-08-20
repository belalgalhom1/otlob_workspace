# openapi.model.Customer

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**userId** | **String** |  | 
**canOrder** | **bool** |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**coinBalance** | **num** |  | 
**addresses** | [**BuiltList&lt;Address&gt;**](Address.md) |  | 
**carts** | [**BuiltList&lt;Cart&gt;**](Cart.md) |  | 
**user** | [**User**](User.md) |  | 
**favoriteProducts** | [**BuiltList&lt;FavoriteProduct&gt;**](FavoriteProduct.md) |  | 
**favoriteVendors** | [**BuiltList&lt;FavoriteVendor&gt;**](FavoriteVendor.md) |  | 
**orders** | [**BuiltList&lt;Order&gt;**](Order.md) |  | 
**coinTransactions** | [**BuiltList&lt;CustomerCoinTransaction&gt;**](CustomerCoinTransaction.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


