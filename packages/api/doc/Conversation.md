# openapi.model.Conversation

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**type** | [**ConversationType**](ConversationType.md) |  | 
**orderId** | **String** |  | [optional] 
**status** | [**ConversationStatus**](ConversationStatus.md) |  | 
**vendorId** | **String** |  | [optional] 
**creatorId** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**participants** | [**BuiltList&lt;ConversationParticipant&gt;**](ConversationParticipant.md) |  | 
**creator** | [**User**](User.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 
**messages** | [**BuiltList&lt;Message&gt;**](Message.md) |  | 
**supportTicket** | [**SupportTicket**](SupportTicket.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


