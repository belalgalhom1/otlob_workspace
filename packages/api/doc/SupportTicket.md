# openapi.model.SupportTicket

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**ticketNumber** | **String** |  | 
**subject** | **String** |  | 
**description** | **String** |  | [optional] 
**status** | [**TicketStatus**](TicketStatus.md) |  | 
**category** | [**TicketCategory**](TicketCategory.md) |  | 
**subCategory** | **String** |  | [optional] 
**priority** | [**TicketPriority**](TicketPriority.md) |  | 
**creatorId** | **String** |  | 
**assigneeId** | **String** |  | [optional] 
**orderId** | **String** |  | [optional] 
**vendorId** | **String** |  | [optional] 
**conversationId** | **String** |  | [optional] 
**lastStatusUpdateAt** | [**DateTime**](DateTime.md) |  | 
**escalatedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**metadata** | [**JsonObject**](.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**assignee** | [**User**](User.md) |  | [optional] 
**conversation** | [**Conversation**](Conversation.md) |  | [optional] 
**creator** | [**User**](User.md) |  | 
**order** | [**Order**](Order.md) |  | [optional] 
**vendor** | [**Vendor**](Vendor.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


