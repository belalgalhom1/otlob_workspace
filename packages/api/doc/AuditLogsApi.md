# api.api.AuditLogsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**auditLogsControllerFindAll**](AuditLogsApi.md#auditlogscontrollerfindall) | **GET** /audit-logs | List audit logs with pagination and filters


# **auditLogsControllerFindAll**
> AuditLogsControllerFindAll200Response auditLogsControllerFindAll(page, limit, userId, vendorId, entityType, entityId, actionType)

List audit logs with pagination and filters

### Example
```dart
import 'package:api/api.dart';

final api = Api().getAuditLogsApi();
final num page = 1; // num | 
final num limit = 20; // num | 
final String userId = userId_example; // String | 
final String vendorId = vendorId_example; // String | 
final String entityType = entityType_example; // String | 
final String entityId = entityId_example; // String | 
final String actionType = actionType_example; // String | 

try {
    final response = api.auditLogsControllerFindAll(page, limit, userId, vendorId, entityType, entityId, actionType);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuditLogsApi->auditLogsControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] 
 **limit** | **num**|  | [optional] 
 **userId** | **String**|  | [optional] 
 **vendorId** | **String**|  | [optional] 
 **entityType** | **String**|  | [optional] 
 **entityId** | **String**|  | [optional] 
 **actionType** | **String**|  | [optional] 

### Return type

[**AuditLogsControllerFindAll200Response**](AuditLogsControllerFindAll200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

