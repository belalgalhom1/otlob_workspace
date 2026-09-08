# api.api.VendorsCoreManagementApi

## Load the API package
```dart
import 'package:api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorsControllerAdminFindAll**](VendorsCoreManagementApi.md#vendorscontrolleradminfindall) | **GET** /vendors/admin | List all vendors (Admin)
[**vendorsControllerCreate**](VendorsCoreManagementApi.md#vendorscontrollercreate) | **POST** /vendors | Create a new vendor (Admin)
[**vendorsControllerFindAll**](VendorsCoreManagementApi.md#vendorscontrollerfindall) | **GET** /vendors | List all vendors with filters
[**vendorsControllerFindBySlug**](VendorsCoreManagementApi.md#vendorscontrollerfindbyslug) | **GET** /vendors/by-slug/{slug} | Find a vendor by its slug
[**vendorsControllerFindOne**](VendorsCoreManagementApi.md#vendorscontrollerfindone) | **GET** /vendors/{vendorId} | Get a specific vendor by ID
[**vendorsControllerGetMyVendor**](VendorsCoreManagementApi.md#vendorscontrollergetmyvendor) | **GET** /vendors/{vendorId}/me | Get my vendor profile (Member)
[**vendorsControllerRemove**](VendorsCoreManagementApi.md#vendorscontrollerremove) | **DELETE** /vendors/{vendorId} | Delete a vendor (Admin)
[**vendorsControllerSearchDiscovery**](VendorsCoreManagementApi.md#vendorscontrollersearchdiscovery) | **GET** /vendors/discovery/search | Global discovery search for vendors and products
[**vendorsControllerUpdate**](VendorsCoreManagementApi.md#vendorscontrollerupdate) | **PATCH** /vendors/{vendorId} | Update vendor information
[**vendorsControllerUpdateStatus**](VendorsCoreManagementApi.md#vendorscontrollerupdatestatus) | **PATCH** /vendors/{vendorId}/status | Update vendor status
[**vendorsControllerUploadCover**](VendorsCoreManagementApi.md#vendorscontrolleruploadcover) | **POST** /vendors/{vendorId}/cover | Upload vendor cover image
[**vendorsControllerUploadLogo**](VendorsCoreManagementApi.md#vendorscontrolleruploadlogo) | **POST** /vendors/{vendorId}/logo | Upload vendor logo image


# **vendorsControllerAdminFindAll**
> ApiControllerRoot200Response vendorsControllerAdminFindAll(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng)

List all vendors (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String status = status_example; // String | 
final String verticalId = vertical-id-123; // String | 
final String search = pizza; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 
final num minRating = 4; // num | Minimum rating (0-5)
final String sortBy = rating; // String | 
final String sortOrder = desc; // String | 
final String zoneId = zone-uuid-123; // String | Filter or prioritize vendors by delivery zone ID
final num lat = 30.0444; // num | 
final num lng = 31.2357; // num | 

try {
    final response = api.vendorsControllerAdminFindAll(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerAdminFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **verticalId** | **String**|  | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]
 **minRating** | **num**| Minimum rating (0-5) | [optional] 
 **sortBy** | **String**|  | [optional] 
 **sortOrder** | **String**|  | [optional] 
 **zoneId** | **String**| Filter or prioritize vendors by delivery zone ID | [optional] 
 **lat** | **num**|  | [optional] 
 **lng** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerCreate**
> ApiControllerRoot200Response vendorsControllerCreate(createVendorDto)

Create a new vendor (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final CreateVendorDto createVendorDto = ; // CreateVendorDto | 

try {
    final response = api.vendorsControllerCreate(createVendorDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createVendorDto** | [**CreateVendorDto**](CreateVendorDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerFindAll**
> ApiControllerRoot200Response vendorsControllerFindAll(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng)

List all vendors with filters

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String status = status_example; // String | 
final String verticalId = vertical-id-123; // String | 
final String search = pizza; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 
final num minRating = 4; // num | Minimum rating (0-5)
final String sortBy = rating; // String | 
final String sortOrder = desc; // String | 
final String zoneId = zone-uuid-123; // String | Filter or prioritize vendors by delivery zone ID
final num lat = 30.0444; // num | 
final num lng = 31.2357; // num | 

try {
    final response = api.vendorsControllerFindAll(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerFindAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **verticalId** | **String**|  | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]
 **minRating** | **num**| Minimum rating (0-5) | [optional] 
 **sortBy** | **String**|  | [optional] 
 **sortOrder** | **String**|  | [optional] 
 **zoneId** | **String**| Filter or prioritize vendors by delivery zone ID | [optional] 
 **lat** | **num**|  | [optional] 
 **lng** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerFindBySlug**
> ApiControllerRoot200Response vendorsControllerFindBySlug(slug)

Find a vendor by its slug

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String slug = slug_example; // String | 

try {
    final response = api.vendorsControllerFindBySlug(slug);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerFindBySlug: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **slug** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerFindOne**
> ApiControllerRoot200Response vendorsControllerFindOne(vendorId)

Get a specific vendor by ID

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorsControllerFindOne(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerFindOne: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerGetMyVendor**
> ApiControllerRoot200Response vendorsControllerGetMyVendor(vendorId)

Get my vendor profile (Member)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorsControllerGetMyVendor(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerGetMyVendor: $e\n');
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

# **vendorsControllerRemove**
> ApiControllerRoot200Response vendorsControllerRemove(vendorId)

Delete a vendor (Admin)

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 

try {
    final response = api.vendorsControllerRemove(vendorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerRemove: $e\n');
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

# **vendorsControllerSearchDiscovery**
> ApiControllerRoot200Response vendorsControllerSearchDiscovery(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng)

Global discovery search for vendors and products

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String status = status_example; // String | 
final String verticalId = vertical-id-123; // String | 
final String search = pizza; // String | 
final num page = 1; // num | 
final num limit = 20; // num | 
final num minRating = 4; // num | Minimum rating (0-5)
final String sortBy = rating; // String | 
final String sortOrder = desc; // String | 
final String zoneId = zone-uuid-123; // String | Filter or prioritize vendors by delivery zone ID
final num lat = 30.0444; // num | 
final num lng = 31.2357; // num | 

try {
    final response = api.vendorsControllerSearchDiscovery(status, verticalId, search, page, limit, minRating, sortBy, sortOrder, zoneId, lat, lng);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerSearchDiscovery: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **verticalId** | **String**|  | [optional] 
 **search** | **String**|  | [optional] 
 **page** | **num**|  | [optional] [default to 1]
 **limit** | **num**|  | [optional] [default to 20]
 **minRating** | **num**| Minimum rating (0-5) | [optional] 
 **sortBy** | **String**|  | [optional] 
 **sortOrder** | **String**|  | [optional] 
 **zoneId** | **String**| Filter or prioritize vendors by delivery zone ID | [optional] 
 **lat** | **num**|  | [optional] 
 **lng** | **num**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerUpdate**
> ApiControllerRoot200Response vendorsControllerUpdate(vendorId, updateVendorDto)

Update vendor information

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 
final UpdateVendorDto updateVendorDto = ; // UpdateVendorDto | 

try {
    final response = api.vendorsControllerUpdate(vendorId, updateVendorDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **updateVendorDto** | [**UpdateVendorDto**](UpdateVendorDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerUpdateStatus**
> ApiControllerRoot200Response vendorsControllerUpdateStatus(vendorId, updateVendorStatusDto)

Update vendor status

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 
final UpdateVendorStatusDto updateVendorStatusDto = ; // UpdateVendorStatusDto | 

try {
    final response = api.vendorsControllerUpdateStatus(vendorId, updateVendorStatusDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **updateVendorStatusDto** | [**UpdateVendorStatusDto**](UpdateVendorStatusDto.md)|  | 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerUploadCover**
> ApiControllerRoot200Response vendorsControllerUploadCover(vendorId, file)

Upload vendor cover image

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.vendorsControllerUploadCover(vendorId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerUploadCover: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerUploadLogo**
> ApiControllerRoot200Response vendorsControllerUploadLogo(vendorId, file)

Upload vendor logo image

### Example
```dart
import 'package:api/api.dart';

final api = Api().getVendorsCoreManagementApi();
final String vendorId = vendorId_example; // String | 
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final response = api.vendorsControllerUploadLogo(vendorId, file);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorsCoreManagementApi->vendorsControllerUploadLogo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorId** | **String**|  | 
 **file** | **MultipartFile**|  | [optional] 

### Return type

[**ApiControllerRoot200Response**](ApiControllerRoot200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

