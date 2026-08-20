# api.api.VendorsBranchesApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorBranchesControllerAdminCreate**](VendorsBranchesApi.md#vendorbranchescontrolleradmincreate) | **POST** /vendors/{vendorId}/branches/admin | Create a new branch (Admin Override)
[**vendorBranchesControllerAdminRemove**](VendorsBranchesApi.md#vendorbranchescontrolleradminremove) | **DELETE** /vendors/{vendorId}/branches/admin/{branchId} | Delete a branch (Admin Override)
[**vendorBranchesControllerAdminUpdate**](VendorsBranchesApi.md#vendorbranchescontrolleradminupdate) | **PATCH** /vendors/{vendorId}/branches/admin/{branchId} | Update a branch (Admin Override)
[**vendorBranchesControllerCreate**](VendorsBranchesApi.md#vendorbranchescontrollercreate) | **POST** /vendors/{vendorId}/branches | Create a new branch (Member)
[**vendorBranchesControllerFindAll**](VendorsBranchesApi.md#vendorbranchescontrollerfindall) | **GET** /vendors/{vendorId}/branches | List all branches for a vendor
[**vendorBranchesControllerFindOne**](VendorsBranchesApi.md#vendorbranchescontrollerfindone) | **GET** /vendors/{vendorId}/branches/{branchId} | Get a specific branch by ID
[**vendorBranchesControllerRemove**](VendorsBranchesApi.md#vendorbranchescontrollerremove) | **DELETE** /vendors/{vendorId}/branches/{branchId} | Delete a branch (Member)
[**vendorBranchesControllerUpdate**](VendorsBranchesApi.md#vendorbranchescontrollerupdate) | **PATCH** /vendors/{vendorId}/branches/{branchId} | Update a branch (Member)


# **vendorBranchesControllerAdminCreate**
> AuthControllerRegister200Response vendorBranchesControllerAdminCreate(vendorId, createVendorBranchDto)

Create a new branch (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final CreateVendorBranchDto createVendorBranchDto = ; // CreateVendorBranchDto | 

try {
    final response = api.vendorBranchesControllerAdminCreate(vendorId, createVendorBranchDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerAdminCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createVendorBranchDto** | [**CreateVendorBranchDto**](CreateVendorBranchDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerAdminRemove**
> AuthControllerRegister200Response vendorBranchesControllerAdminRemove(vendorId, branchId)

Delete a branch (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final String branchId = branchId_example; // String | 

try {
    final response = api.vendorBranchesControllerAdminRemove(vendorId, branchId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerAdminRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **branchId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerAdminUpdate**
> AuthControllerRegister200Response vendorBranchesControllerAdminUpdate(vendorId, branchId, updateVendorBranchDto)

Update a branch (Admin Override)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final String branchId = branchId_example; // String | 
final UpdateVendorBranchDto updateVendorBranchDto = ; // UpdateVendorBranchDto | 

try {
    final response = api.vendorBranchesControllerAdminUpdate(vendorId, branchId, updateVendorBranchDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **branchId** | **String**|  | 
 **updateVendorBranchDto** | [**UpdateVendorBranchDto**](UpdateVendorBranchDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerCreate**
> AuthControllerRegister200Response vendorBranchesControllerCreate(vendorId, createVendorBranchDto)

Create a new branch (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final CreateVendorBranchDto createVendorBranchDto = ; // CreateVendorBranchDto | 

try {
    final response = api.vendorBranchesControllerCreate(vendorId, createVendorBranchDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **createVendorBranchDto** | [**CreateVendorBranchDto**](CreateVendorBranchDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerFindAll**
> AuthControllerRegister200Response vendorBranchesControllerFindAll(vendorId)

List all branches for a vendor

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorBranchesControllerFindAll(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerFindOne**
> AuthControllerRegister200Response vendorBranchesControllerFindOne(vendorId, branchId)

Get a specific branch by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final String branchId = branchId_example; // String | 

try {
    final response = api.vendorBranchesControllerFindOne(vendorId, branchId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **branchId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerRemove**
> AuthControllerRegister200Response vendorBranchesControllerRemove(vendorId, branchId)

Delete a branch (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final String branchId = branchId_example; // String | 

try {
    final response = api.vendorBranchesControllerRemove(vendorId, branchId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **branchId** | **String**|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorBranchesControllerUpdate**
> AuthControllerRegister200Response vendorBranchesControllerUpdate(vendorId, branchId, updateVendorBranchDto)

Update a branch (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsBranchesApi();
final String vendorId = vendorId_example; // String | 
final String branchId = branchId_example; // String | 
final UpdateVendorBranchDto updateVendorBranchDto = ; // UpdateVendorBranchDto | 

try {
    final response = api.vendorBranchesControllerUpdate(vendorId, branchId, updateVendorBranchDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsBranchesApi->vendorBranchesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **branchId** | **String**|  | 
 **updateVendorBranchDto** | [**UpdateVendorBranchDto**](UpdateVendorBranchDto.md)|  | 

### Return type

[**AuthControllerRegister200Response**](AuthControllerRegister200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

