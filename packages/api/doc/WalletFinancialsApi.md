# api.api.WalletFinancialsApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**walletControllerAddDriverWallet**](WalletFinancialsApi.md#walletcontrolleradddriverwallet) | **POST** /wallet/driver | Add personal driver wallet for receiving money from customers
[**walletControllerCreatePlatformWallet**](WalletFinancialsApi.md#walletcontrollercreateplatformwallet) | **POST** /wallet/platform | Add a new platform receiving wallet
[**walletControllerGetActivePlatformWallets**](WalletFinancialsApi.md#walletcontrollergetactiveplatformwallets) | **GET** /wallet/platform | Get active platform wallets to send money to
[**walletControllerGetAllPlatformWallets**](WalletFinancialsApi.md#walletcontrollergetallplatformwallets) | **GET** /wallet/platform/all | Get all platform wallets (including inactive)
[**walletControllerGetMyDriverTransactions**](WalletFinancialsApi.md#walletcontrollergetmydrivertransactions) | **GET** /wallet/driver/me/transactions | Get my personal driver wallet transactions
[**walletControllerGetMyDriverWallets**](WalletFinancialsApi.md#walletcontrollergetmydriverwallets) | **GET** /wallet/driver | Get my personal driver wallets
[**walletControllerGetMyTopUpRequests**](WalletFinancialsApi.md#walletcontrollergetmytopuprequests) | **GET** /wallet/topups/me | View my top-up requests history
[**walletControllerGetPendingTopUps**](WalletFinancialsApi.md#walletcontrollergetpendingtopups) | **GET** /wallet/topups/pending | View pending driver top-up requests
[**walletControllerGetVendorTransactions**](WalletFinancialsApi.md#walletcontrollergetvendortransactions) | **GET** /wallet/vendors/{vendorId}/transactions | Get vendor wallet transaction history
[**walletControllerProcessDriverTransaction**](WalletFinancialsApi.md#walletcontrollerprocessdrivertransaction) | **POST** /wallet/admin/drivers/{driverId}/transaction | Manually adjust driver wallet (Payout, Penalty, etc.)
[**walletControllerProcessVendorTransaction**](WalletFinancialsApi.md#walletcontrollerprocessvendortransaction) | **POST** /wallet/admin/vendors/{vendorId}/transaction | Manually adjust vendor wallet (Payout, Refund, etc.)
[**walletControllerReviewTopUp**](WalletFinancialsApi.md#walletcontrollerreviewtopup) | **PATCH** /wallet/topups/{id}/review | Approve or reject a driver top-up request
[**walletControllerSubmitTopUpRequest**](WalletFinancialsApi.md#walletcontrollersubmittopuprequest) | **POST** /wallet/topups | Submit a top-up request with screenshot proof
[**walletControllerUpdatePlatformWallet**](WalletFinancialsApi.md#walletcontrollerupdateplatformwallet) | **PATCH** /wallet/platform/{id} | Update or disable a platform wallet
[**walletControllerUploadReceipt**](WalletFinancialsApi.md#walletcontrolleruploadreceipt) | **POST** /wallet/topups/receipt | Upload a receipt image for a wallet top-up


# **walletControllerAddDriverWallet**
> WalletControllerGetActivePlatformWallets200Response walletControllerAddDriverWallet(createMobileWalletDto)

Add personal driver wallet for receiving money from customers

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final CreateMobileWalletDto createMobileWalletDto = ; // CreateMobileWalletDto | 

try {
    final response = api.walletControllerAddDriverWallet(createMobileWalletDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerAddDriverWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createMobileWalletDto** | [**CreateMobileWalletDto**](CreateMobileWalletDto.md)|  | 

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerCreatePlatformWallet**
> WalletControllerGetActivePlatformWallets200Response walletControllerCreatePlatformWallet(createMobileWalletDto)

Add a new platform receiving wallet

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final CreateMobileWalletDto createMobileWalletDto = ; // CreateMobileWalletDto | 

try {
    final response = api.walletControllerCreatePlatformWallet(createMobileWalletDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerCreatePlatformWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createMobileWalletDto** | [**CreateMobileWalletDto**](CreateMobileWalletDto.md)|  | 

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetActivePlatformWallets**
> WalletControllerGetActivePlatformWallets200Response walletControllerGetActivePlatformWallets()

Get active platform wallets to send money to

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetActivePlatformWallets();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetActivePlatformWallets: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetAllPlatformWallets**
> WalletControllerGetActivePlatformWallets200Response walletControllerGetAllPlatformWallets()

Get all platform wallets (including inactive)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetAllPlatformWallets();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetAllPlatformWallets: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetMyDriverTransactions**
> WalletControllerProcessDriverTransaction200Response walletControllerGetMyDriverTransactions()

Get my personal driver wallet transactions

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetMyDriverTransactions();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetMyDriverTransactions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerProcessDriverTransaction200Response**](WalletControllerProcessDriverTransaction200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetMyDriverWallets**
> WalletControllerGetActivePlatformWallets200Response walletControllerGetMyDriverWallets()

Get my personal driver wallets

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetMyDriverWallets();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetMyDriverWallets: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetMyTopUpRequests**
> WalletControllerGetPendingTopUps200Response walletControllerGetMyTopUpRequests()

View my top-up requests history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetMyTopUpRequests();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetMyTopUpRequests: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerGetPendingTopUps200Response**](WalletControllerGetPendingTopUps200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetPendingTopUps**
> WalletControllerGetPendingTopUps200Response walletControllerGetPendingTopUps()

View pending driver top-up requests

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();

try {
    final response = api.walletControllerGetPendingTopUps();
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetPendingTopUps: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WalletControllerGetPendingTopUps200Response**](WalletControllerGetPendingTopUps200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerGetVendorTransactions**
> WalletControllerProcessVendorTransaction200Response walletControllerGetVendorTransactions(vendorId)

Get vendor wallet transaction history

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.walletControllerGetVendorTransactions(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerGetVendorTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**WalletControllerProcessVendorTransaction200Response**](WalletControllerProcessVendorTransaction200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerProcessDriverTransaction**
> WalletControllerProcessDriverTransaction200Response walletControllerProcessDriverTransaction(driverId, processManualTransactionDto)

Manually adjust driver wallet (Payout, Penalty, etc.)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final String driverId = driverId_example; // String | 
final ProcessManualTransactionDto processManualTransactionDto = ; // ProcessManualTransactionDto | 

try {
    final response = api.walletControllerProcessDriverTransaction(driverId, processManualTransactionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerProcessDriverTransaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **String**|  | 
 **processManualTransactionDto** | [**ProcessManualTransactionDto**](ProcessManualTransactionDto.md)|  | 

### Return type

[**WalletControllerProcessDriverTransaction200Response**](WalletControllerProcessDriverTransaction200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerProcessVendorTransaction**
> WalletControllerProcessVendorTransaction200Response walletControllerProcessVendorTransaction(vendorId, processManualTransactionDto)

Manually adjust vendor wallet (Payout, Refund, etc.)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final String vendorId = vendorId_example; // String | 
final ProcessManualTransactionDto processManualTransactionDto = ; // ProcessManualTransactionDto | 

try {
    final response = api.walletControllerProcessVendorTransaction(vendorId, processManualTransactionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerProcessVendorTransaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **processManualTransactionDto** | [**ProcessManualTransactionDto**](ProcessManualTransactionDto.md)|  | 

### Return type

[**WalletControllerProcessVendorTransaction200Response**](WalletControllerProcessVendorTransaction200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerReviewTopUp**
> WalletControllerGetPendingTopUps200Response walletControllerReviewTopUp(id, reviewWalletTopUpDto)

Approve or reject a driver top-up request

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final String id = id_example; // String | 
final ReviewWalletTopUpDto reviewWalletTopUpDto = ; // ReviewWalletTopUpDto | 

try {
    final response = api.walletControllerReviewTopUp(id, reviewWalletTopUpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerReviewTopUp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **reviewWalletTopUpDto** | [**ReviewWalletTopUpDto**](ReviewWalletTopUpDto.md)|  | 

### Return type

[**WalletControllerGetPendingTopUps200Response**](WalletControllerGetPendingTopUps200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerSubmitTopUpRequest**
> WalletControllerGetPendingTopUps200Response walletControllerSubmitTopUpRequest(createWalletTopUpDto)

Submit a top-up request with screenshot proof

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final CreateWalletTopUpDto createWalletTopUpDto = ; // CreateWalletTopUpDto | 

try {
    final response = api.walletControllerSubmitTopUpRequest(createWalletTopUpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerSubmitTopUpRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createWalletTopUpDto** | [**CreateWalletTopUpDto**](CreateWalletTopUpDto.md)|  | 

### Return type

[**WalletControllerGetPendingTopUps200Response**](WalletControllerGetPendingTopUps200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerUpdatePlatformWallet**
> WalletControllerGetActivePlatformWallets200Response walletControllerUpdatePlatformWallet(id)

Update or disable a platform wallet

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final String id = id_example; // String | 

try {
    final response = api.walletControllerUpdatePlatformWallet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerUpdatePlatformWallet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**WalletControllerGetActivePlatformWallets200Response**](WalletControllerGetActivePlatformWallets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **walletControllerUploadReceipt**
> ApiControllerRoot200Response walletControllerUploadReceipt(file)

Upload a receipt image for a wallet top-up

### Example
```dart
import 'package:api/api.dart';

final api = Api().getWalletFinancialsApi();
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.walletControllerUploadReceipt(file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling WalletFinancialsApi->walletControllerUploadReceipt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

