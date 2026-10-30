# api.api.VendorsWalletTransactionsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorWalletControllerAdminGetBalance**](VendorsWalletTransactionsApi.md#vendorwalletcontrolleradmingetbalance) | **GET** /vendors/{vendorId}/wallet/admin/balance | Get any vendor&#39;s wallet balance (Admin)
[**vendorWalletControllerAdminGetSummary**](VendorsWalletTransactionsApi.md#vendorwalletcontrolleradmingetsummary) | **GET** /vendors/{vendorId}/wallet/admin/summary | Get any vendor&#39;s wallet summary statistics (Admin)
[**vendorWalletControllerAdminListTransactions**](VendorsWalletTransactionsApi.md#vendorwalletcontrolleradminlisttransactions) | **GET** /vendors/{vendorId}/wallet/admin/transactions | List any vendor&#39;s wallet transactions (Admin)
[**vendorWalletControllerGetBalance**](VendorsWalletTransactionsApi.md#vendorwalletcontrollergetbalance) | **GET** /vendors/{vendorId}/wallet/balance | Get the vendor&#39;s wallet balance (any member)
[**vendorWalletControllerGetSummary**](VendorsWalletTransactionsApi.md#vendorwalletcontrollergetsummary) | **GET** /vendors/{vendorId}/wallet/summary | Get the vendor&#39;s wallet summary (any member)
[**vendorWalletControllerListTransactions**](VendorsWalletTransactionsApi.md#vendorwalletcontrollerlisttransactions) | **GET** /vendors/{vendorId}/wallet/transactions | List the vendor&#39;s wallet transactions (any member)


# **vendorWalletControllerAdminGetBalance**
> ApiControllerRoot200Response vendorWalletControllerAdminGetBalance(vendorId)

Get any vendor's wallet balance (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorWalletControllerAdminGetBalance(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerAdminGetBalance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorWalletControllerAdminGetSummary**
> ApiControllerRoot200Response vendorWalletControllerAdminGetSummary(vendorId, type, branchId, from, to, page, limit)

Get any vendor's wallet summary statistics (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 
final String type = type_example; // String | 
final String branchId = uuid; // String | Filter transactions by vendor branch ID
final String from = 2023-01-01; // String | 
final String to = 2023-12-31; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.vendorWalletControllerAdminGetSummary(vendorId, type, branchId, from, to, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerAdminGetSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **type** | **String**|  | [optional] 
 **branchId** | **String**| Filter transactions by vendor branch ID | [optional] 
 **from** | **String**|  | [optional] 
 **to** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorWalletControllerAdminListTransactions**
> ApiControllerRoot200Response vendorWalletControllerAdminListTransactions(vendorId, type, branchId, from, to, page, limit)

List any vendor's wallet transactions (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 
final String type = type_example; // String | 
final String branchId = uuid; // String | Filter transactions by vendor branch ID
final String from = 2023-01-01; // String | 
final String to = 2023-12-31; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.vendorWalletControllerAdminListTransactions(vendorId, type, branchId, from, to, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerAdminListTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **type** | **String**|  | [optional] 
 **branchId** | **String**| Filter transactions by vendor branch ID | [optional] 
 **from** | **String**|  | [optional] 
 **to** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorWalletControllerGetBalance**
> ApiControllerRoot200Response vendorWalletControllerGetBalance(vendorId)

Get the vendor's wallet balance (any member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorWalletControllerGetBalance(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerGetBalance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorWalletControllerGetSummary**
> ApiControllerRoot200Response vendorWalletControllerGetSummary(vendorId, type, branchId, from, to, page, limit)

Get the vendor's wallet summary (any member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 
final String type = type_example; // String | 
final String branchId = uuid; // String | Filter transactions by vendor branch ID
final String from = 2023-01-01; // String | 
final String to = 2023-12-31; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.vendorWalletControllerGetSummary(vendorId, type, branchId, from, to, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerGetSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **type** | **String**|  | [optional] 
 **branchId** | **String**| Filter transactions by vendor branch ID | [optional] 
 **from** | **String**|  | [optional] 
 **to** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorWalletControllerListTransactions**
> ApiControllerRoot200Response vendorWalletControllerListTransactions(vendorId, type, branchId, from, to, page, limit)

List the vendor's wallet transactions (any member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsWalletTransactionsApi();
final String vendorId = vendorId_example; // String | 
final String type = type_example; // String | 
final String branchId = uuid; // String | Filter transactions by vendor branch ID
final String from = 2023-01-01; // String | 
final String to = 2023-12-31; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 

try {
    final response = api.vendorWalletControllerListTransactions(vendorId, type, branchId, from, to, page, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsWalletTransactionsApi->vendorWalletControllerListTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **type** | **String**|  | [optional] 
 **branchId** | **String**| Filter transactions by vendor branch ID | [optional] 
 **from** | **String**|  | [optional] 
 **to** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

