# api.model.AuditLogResponseDto

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**userId** | **String** |  | 
**vendorId** | **String** |  | [optional] 
**actionType** | [**AuditActionType**](AuditActionType.md) |  | 
**action** | **String** |  | 
**entityType** | **String** |  | 
**entityId** | **String** |  | 
**oldValues** | [**JsonObject**](.md) |  | [optional] 
**newValues** | [**JsonObject**](.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**sessionId** | **String** |  | [optional] 
**user** | [**User**](User.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 
**session** | [**Session**](Session.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


