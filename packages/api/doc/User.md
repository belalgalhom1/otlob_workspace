# openapi.model.User

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**email** | **String** |  | [optional] 
**phone** | **String** |  | [optional] 
**password** | **String** |  | 
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
**auditLogs** | [**BuiltList&lt;AuditLog&gt;**](AuditLog.md) |  | 
**conversations** | [**BuiltList&lt;ConversationParticipant&gt;**](ConversationParticipant.md) |  | 
**customer** | [**Customer**](Customer.md) |  | [optional] 
**devices** | [**BuiltList&lt;Device&gt;**](Device.md) |  | 
**driver** | [**Driver**](Driver.md) |  | [optional] 
**messages** | [**BuiltList&lt;Message&gt;**](Message.md) |  | 
**notificationSettings** | [**NotificationSetting**](NotificationSetting.md) |  | [optional] 
**notifications** | [**BuiltList&lt;Notification&gt;**](Notification.md) |  | 
**sessions** | [**BuiltList&lt;Session&gt;**](Session.md) |  | 
**assignedTickets** | [**BuiltList&lt;SupportTicket&gt;**](SupportTicket.md) |  | 
**createdTickets** | [**BuiltList&lt;SupportTicket&gt;**](SupportTicket.md) |  | 
**vendorMemberships** | [**BuiltList&lt;VendorMember&gt;**](VendorMember.md) |  | 
**createdConversations** | [**BuiltList&lt;Conversation&gt;**](Conversation.md) |  | 
**approvedTopUps** | [**BuiltList&lt;WalletTopUpRequest&gt;**](WalletTopUpRequest.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


