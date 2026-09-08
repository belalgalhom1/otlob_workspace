# api.model.User

## Load the model package
```dart
import 'package:api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**email** | **String** |  | [optional] 
**phone** | **String** |  | [optional] 
**password** | **String** |  | [optional] 
**name** | **String** |  | 
**role** | [**Role**](Role.md) |  | 
**title** | **String** |  | [optional] 
**titleAr** | **String** |  | [optional] 
**permissions** | [**BuiltList&lt;Permission&gt;**](Permission.md) |  | 
**avatar** | **String** |  | [optional] 
**language** | [**Language**](Language.md) |  | 
**isEmailVerified** | **bool** |  | 
**isPhoneVerified** | **bool** |  | 
**isBanned** | **bool** |  | 
**banReason** | **String** |  | [optional] 
**autoReplyMessage** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


