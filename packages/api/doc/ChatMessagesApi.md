# api.api.ChatMessagesApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**messagesControllerDelete**](ChatMessagesApi.md#messagescontrollerdelete) | **DELETE** /chat/conversations/{conversationId}/messages/{messageId} | Delete a message
[**messagesControllerList**](ChatMessagesApi.md#messagescontrollerlist) | **GET** /chat/conversations/{conversationId}/messages | List messages in a conversation
[**messagesControllerMarkRead**](ChatMessagesApi.md#messagescontrollermarkread) | **PATCH** /chat/conversations/{conversationId}/messages/read | Mark messages as read
[**messagesControllerSend**](ChatMessagesApi.md#messagescontrollersend) | **POST** /chat/conversations/{conversationId}/messages | Send a message in a conversation
[**messagesControllerUpdate**](ChatMessagesApi.md#messagescontrollerupdate) | **PATCH** /chat/conversations/{conversationId}/messages/{messageId} | Update a message
[**messagesControllerUpload**](ChatMessagesApi.md#messagescontrollerupload) | **POST** /chat/conversations/{conversationId}/messages/upload | Upload a media file for chat


# **messagesControllerDelete**
> ApiControllerRoot200Response messagesControllerDelete(conversationId, messageId)

Delete a message

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final String messageId = messageId_example; // String | The unique identifier of the message

try {
    final response = api.messagesControllerDelete(conversationId, messageId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **messageId** | **String**| The unique identifier of the message | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **messagesControllerList**
> ApiControllerRoot200Response messagesControllerList(conversationId, before, limit)

List messages in a conversation

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final String before = 550e8400-e29b-41d4-a716-446655440000; // String | 
final num limit = 30; // num | 

try {
    final response = api.messagesControllerList(conversationId, before, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **before** | **String**|  | [optional] 
 **limit** | **num**|  | [optional] [default to 30]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **messagesControllerMarkRead**
> ApiControllerRoot200Response messagesControllerMarkRead(conversationId, markReadDto)

Mark messages as read

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final MarkReadDto markReadDto = ; // MarkReadDto | 

try {
    final response = api.messagesControllerMarkRead(conversationId, markReadDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerMarkRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **markReadDto** | [**MarkReadDto**](MarkReadDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **messagesControllerSend**
> ApiControllerRoot200Response messagesControllerSend(conversationId, sendMessageDto)

Send a message in a conversation

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final SendMessageDto sendMessageDto = ; // SendMessageDto | 

try {
    final response = api.messagesControllerSend(conversationId, sendMessageDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerSend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **sendMessageDto** | [**SendMessageDto**](SendMessageDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **messagesControllerUpdate**
> ApiControllerRoot200Response messagesControllerUpdate(conversationId, messageId)

Update a message

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final String messageId = messageId_example; // String | The unique identifier of the message

try {
    final response = api.messagesControllerUpdate(conversationId, messageId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **messageId** | **String**| The unique identifier of the message | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **messagesControllerUpload**
> ApiControllerRoot200Response messagesControllerUpload(conversationId, file)

Upload a media file for chat

### Example
```dart
import 'package:api/api.dart';

final api = Api().getChatMessagesApi();
final String conversationId = 123e4567-e89b-12d3-a456-426614174000; // String | The unique identifier of the conversation
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.messagesControllerUpload(conversationId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChatMessagesApi->messagesControllerUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conversationId** | **String**| The unique identifier of the conversation | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

