# api.api.NotificationsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notificationsControllerDeleteAllRead**](NotificationsApi.md#notificationscontrollerdeleteallread) | **DELETE** /notifications/read | Delete all read notifications
[**notificationsControllerDeleteOne**](NotificationsApi.md#notificationscontrollerdeleteone) | **DELETE** /notifications/{id} | Delete a specific notification
[**notificationsControllerDispatchAnnouncement**](NotificationsApi.md#notificationscontrollerdispatchannouncement) | **POST** /notifications/admin/announcements | Dispatch an announcement to a topic
[**notificationsControllerGetOne**](NotificationsApi.md#notificationscontrollergetone) | **GET** /notifications/{id} | Get a specific notification by ID
[**notificationsControllerList**](NotificationsApi.md#notificationscontrollerlist) | **GET** /notifications | List my notifications
[**notificationsControllerMarkOneRead**](NotificationsApi.md#notificationscontrollermarkoneread) | **PATCH** /notifications/{id}/read | Mark a specific notification as read
[**notificationsControllerMarkRead**](NotificationsApi.md#notificationscontrollermarkread) | **PATCH** /notifications/read | Mark multiple notifications as read
[**notificationsControllerUnreadCount**](NotificationsApi.md#notificationscontrollerunreadcount) | **GET** /notifications/unread-count | Get unread notifications count


# **notificationsControllerDeleteAllRead**
> AuthControllerRegister200Response notificationsControllerDeleteAllRead()

Delete all read notifications

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();

try {
    final response = api.notificationsControllerDeleteAllRead();
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerDeleteAllRead: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerDeleteOne**
> NotificationsControllerList200Response notificationsControllerDeleteOne(id)

Delete a specific notification

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final String id = id_example; // String | 

try {
    final response = api.notificationsControllerDeleteOne(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerDeleteOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**NotificationsControllerList200Response**](NotificationsControllerList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerDispatchAnnouncement**
> AuthControllerRegister200Response notificationsControllerDispatchAnnouncement(dispatchAnnouncementDto)

Dispatch an announcement to a topic

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final DispatchAnnouncementDto dispatchAnnouncementDto = ; // DispatchAnnouncementDto | 

try {
    final response = api.notificationsControllerDispatchAnnouncement(dispatchAnnouncementDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerDispatchAnnouncement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchAnnouncementDto** | [**DispatchAnnouncementDto**](DispatchAnnouncementDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerGetOne**
> NotificationsControllerList200Response notificationsControllerGetOne(id)

Get a specific notification by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final String id = id_example; // String | 

try {
    final response = api.notificationsControllerGetOne(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerGetOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**NotificationsControllerList200Response**](NotificationsControllerList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerList**
> NotificationsControllerList200Response notificationsControllerList(unreadOnly, type, page, limit)

List my notifications

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final bool unreadOnly = true; // bool | 
final String type = type_example; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.notificationsControllerList(unreadOnly, type, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **unreadOnly** | **bool**|  | [optional] 
 **type** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**NotificationsControllerList200Response**](NotificationsControllerList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerMarkOneRead**
> NotificationsControllerList200Response notificationsControllerMarkOneRead(id)

Mark a specific notification as read

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final String id = id_example; // String | 

try {
    final response = api.notificationsControllerMarkOneRead(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerMarkOneRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**NotificationsControllerList200Response**](NotificationsControllerList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerMarkRead**
> AuthControllerRegister200Response notificationsControllerMarkRead(markNotificationsReadDto)

Mark multiple notifications as read

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();
final MarkNotificationsReadDto markNotificationsReadDto = ; // MarkNotificationsReadDto | 

try {
    final response = api.notificationsControllerMarkRead(markNotificationsReadDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerMarkRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **markNotificationsReadDto** | [**MarkNotificationsReadDto**](MarkNotificationsReadDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerUnreadCount**
> AuthControllerRegister200Response notificationsControllerUnreadCount()

Get unread notifications count

### Example
```dart
import 'package:api/api.dart';

final api = Api().getNotificationsApi();

try {
    final response = api.notificationsControllerUnreadCount();
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerUnreadCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

