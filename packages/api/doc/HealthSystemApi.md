# api.api.HealthSystemApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiControllerRoot**](HealthSystemApi.md#apicontrollerroot) | **GET** / | API Health Check


# **apiControllerRoot**
> ApiControllerRoot200Response apiControllerRoot()

API Health Check

### Example
```dart
import 'package:api/api.dart';

final api = Api().getHealthSystemApi();

try {
    final response = api.apiControllerRoot();
    print(response);
} on DioException catch (e) {
    print('Exception when calling HealthSystemApi->apiControllerRoot: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

