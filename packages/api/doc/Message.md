# openapi.model.Message

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**conversationId** | **String** |  | 
**senderId** | **String** |  | 
**type** | [**MessageType**](MessageType.md) |  | 
**text** | **String** |  | [optional] 
**mediaUrl** | **String** |  | [optional] 
**metadata** | [**JsonObject**](.md) |  | [optional] 
**replyToId** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**deletedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**conversation** | [**Conversation**](Conversation.md) |  | 
**replyTo** | [**Message**](Message.md) |  | [optional] 
**replies** | [**BuiltList&lt;Message&gt;**](Message.md) |  | 
**sender** | [**User**](User.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


