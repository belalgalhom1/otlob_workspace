# api.api.InboxSummaryCountsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**inboxControllerGetCounts**](InboxSummaryCountsApi.md#inboxcontrollergetcounts) | **GET** /inbox/counts | Get unread counts for chat and notifications


# **inboxControllerGetCounts**
> AuthControllerRegister200Response inboxControllerGetCounts()

Get unread counts for chat and notifications

### Example
```dart
import 'package:api/api.dart';

final api = Api().getInboxSummaryCountsApi();

try {
    final response = api.inboxControllerGetCounts();
    print(response);
} on DioException catch (e) {
    print('Exception when calling InboxSummaryCountsApi->inboxControllerGetCounts: $e\n');
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

